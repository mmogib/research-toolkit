# sweep_helpers.jl — Shared sweep infrastructure for benchmark scripts.
#
# Used by:
#   - scripts/s30_benchmark.jl (primary sweep)
#   - scripts/s40_recovery.jl  (§4.2 recovery sweep with relaxed criteria)
#   - any future sweep script
#
# Provides:
#   - LS palette constants (LS_LABELS, LS_IMPLEMENTED) and `WorkItem` struct
#   - CLI sub-parsers (--ls / --dims / --problems / --display) and the
#     `_fmt` hash-canonicalization helper
#   - `resolve_ls(label, cli)` — label → algorithm struct
#   - `build_params(label, ls, cli)` — hash-canonical params NamedTuple
#     (time_limit_s joins the tuple ONLY when set, preserving backwards-
#     compat with config hashes from runs that pre-date `--time-limit`)
#   - `build_alg(ls, cli; callbacks)` — DFProjection with stopping rule
#     `AnyOf(AbsResidualTol, MaxIters)` or `AnyOf(..., MaxTime)` if a
#     time-limit is in `cli[:time_limit]`
#   - `register_palette(db, cli)` — build palette + ensure_config! per LS
#   - `existing_set(db, worklist, force)` — batched is_done query → Set
#   - `threads_warn(cli)` — warn if --threads > Threads.nthreads()
#   - `run_sweep(db, palette, worklist, cli, tee, n_total, existing)` —
#     the serial + threaded solve loop; returns (counters, elapsed)
#
# What stays in each script:
#   - `parse_cli(args)` — script-specific (s30 vs s40 have different flag sets)
#   - The worklist-building loop — different across scripts (s30 enumerates
#     `palette × problems × dims × inits`; s40 reads a failure-list from the DB)
#   - The workload banner — different formats per script
#   - `main()` — script-specific orchestration

# ============================================================================
# LS palette constants
# ============================================================================

const LS_LABELS      = ["LSI", "LSII", "LSIII", "LSIV", "LSV", "LSVI", "LSVII"]  # all 7
const LS_IMPLEMENTED = ["LSI", "LSII", "LSIII", "LSIV", "LSV", "LSVI", "LSVII"]  # all 7 as of T.4

# ============================================================================
# WorkItem — one task in a sweep
# ============================================================================

struct WorkItem
    ls_label::String
    config_hash::String
    alg::Any            # DFProjection instance (per-LS, shared across tasks in serial mode)
    prob_name::String   # Symbol→String for DB
    prob::Any           # TestProblem
    n::Int
    init_name::String   # Symbol→String for DB
    x0::Vector{Float64}
end

# ============================================================================
# CLI sub-parsers
# ============================================================================

const _DISPLAY_MODES = (:silent, :progress, :table)

function _parse_display(s::AbstractString)
    sym = Symbol(strip(s))
    sym in _DISPLAY_MODES ||
        error("Unknown --display value '$s'. Available: " * join(string.(_DISPLAY_MODES), ", "))
    return sym
end

function _parse_ls_list(s::AbstractString)
    tokens = strip.(split(s, ","))
    out = String[]
    for t in tokens
        isempty(t) && continue
        t in LS_LABELS || error("Unknown LS label '$t'. Available: " * join(LS_LABELS, ", "))
        push!(out, String(t))
    end
    isempty(out) && error("--ls received no valid tokens")
    return out
end

function _parse_int_list(s::AbstractString)
    out = Int[]
    for raw in split(s, ",")
        t = strip(raw)
        isempty(t) && continue
        n = parse(Int, t)
        n > 0 || error("--dims expects positive integers; got $n")
        push!(out, n)
    end
    isempty(out) && error("--dims received no valid tokens")
    return out
end

function _parse_problem_list(s::AbstractString)
    # Mixed grammar: range "1-10" / "p1-p10"; id "10" / "p10"; name "ExponentialI" (case-insens)
    n_problems = length(PROBLEM_ORDER)
    out = Int[]
    for raw in split(s, ",")
        t = strip(raw)
        isempty(t) && continue
        if occursin(r"^p?\d+-p?\d+$"i, t)
            parts = split(t, "-")
            a = parse(Int, replace(parts[1], r"^p"i => ""))
            b = parse(Int, replace(parts[2], r"^p"i => ""))
            a <= b || error("--problems range '$t' has a > b")
            (1 <= a <= n_problems && 1 <= b <= n_problems) ||
                error("--problems range '$t' out of bounds 1:$n_problems")
            append!(out, a:b)
        elseif occursin(r"^p?\d+$"i, t)
            id = parse(Int, replace(t, r"^p"i => ""))
            (1 <= id <= n_problems) ||
                error("--problems id '$t' out of bounds 1:$n_problems")
            push!(out, id)
        else
            target = lowercase(String(t))
            matched = findfirst(sym -> lowercase(string(sym)) == target, PROBLEM_ORDER)
            matched === nothing &&
                error("Unknown problem name '$t'. Available: " * join(string.(PROBLEM_ORDER), ", "))
            push!(out, matched)
        end
    end
    isempty(out) && error("--problems received no valid tokens")
    return unique(out)
end

# ============================================================================
# Hash canonicalization (uniform %.12g for floats)
# ============================================================================

_fmt(x::AbstractFloat) = @sprintf("%.12g", x)
_fmt(x::Integer)       = string(x)
_fmt(x)                = string(x)

# ============================================================================
# LS palette: label → algorithm struct
# ============================================================================
#
# σ, ρ are user-tunable (paper: 0.01, 0.6). All other LS-internal knobs are
# pinned to paper-default values (or library defaults; same here) so the hash
# captures the exact configuration. To sweep over those, expose new flags.

function resolve_ls(label::String, cli::Dict)
    σ = cli[:sigma]; ρ = cli[:rho]
    if     label == "LSI";   return ConstantBacktrack(; σ = σ, ρ = ρ)
    elseif label == "LSII";  return ResidualNormBacktrack(; σ = σ, ρ = ρ)
    elseif label == "LSIII"; return SaturatedResidualBacktrack(; σ = σ, ρ = ρ)
    elseif label == "LSIV";  return AffineResidualBacktrack(; σ = σ, ρ = ρ,
                                                              max_iters = cli[:maxiter])
    elseif label == "LSV";   return CappedResidualBacktrack(; σ = σ, ρ = ρ)
    elseif label == "LSVI";  return FixedClampedBacktrack(; σ = σ, ρ = ρ)
    elseif label == "LSVII"; return AdaptiveClampedBacktrack(; σ = σ, ρ = ρ)
    else
        error("Unknown LS label '$label'.")
    end
end

# ============================================================================
# Params + alg construction
# ============================================================================
#
# IMPORTANT: `time_limit_s` joins the params NamedTuple ONLY when set. This
# preserves byte-identical config hashes for pre-existing runs that didn't
# have --time-limit (so the DB rows from T.3/T.4/T.5a/T.5b remain valid).

function build_params(label::String, ls, cli::Dict)
    ls_extra = if ls isa AdaptiveClampedBacktrack
        "lo=$(_fmt(ls.lo)),Delta_init=$(_fmt(ls.Δ_init)),maxbt=$(ls.maxbt)"
    elseif ls isa FixedClampedBacktrack
        "lo=$(_fmt(ls.lo)),hi=$(_fmt(ls.hi)),maxbt=$(ls.maxbt)"
    elseif ls isa AffineResidualBacktrack
        "max_iters=$(ls.max_iters),maxbt=$(ls.maxbt)"
    else
        "maxbt=$(ls.maxbt)"
    end
    base = (
        direction         = "SpectralThreeTerm",
        direction_r       = _fmt(cli[:r]),
        direction_abar    = _fmt(1.0),
        linesearch        = label,
        linesearch_sigma  = _fmt(cli[:sigma]),
        linesearch_rho    = _fmt(cli[:rho]),
        linesearch_extra  = ls_extra,
        inertial          = "Inertial",
        inertial_theta    = _fmt(cli[:theta]),
        iterate_update    = "SolodovSvaiterProjection",
        zeta              = _fmt(cli[:zeta]),
        inner_maxiter     = "500",
        julia_version     = string(VERSION),
        dfmethods_version = "0.3.0",
    )
    return get(cli, :time_limit, nothing) === nothing ?
        base :
        merge(base, (time_limit_s = _fmt(cli[:time_limit]),))
end

# Build the DFProjection alg. The stopping rule is constructed inline based
# on cli[:time_limit]: AnyOf(AbsResidualTol, MaxIters) by default, with
# MaxTime appended when --time-limit is set.
function build_alg(ls, cli::Dict;
                   callbacks::Vector{<:DFMethods.AbstractCallback} =
                       DFMethods.AbstractCallback[])
    tl = get(cli, :time_limit, nothing)
    stop = if tl === nothing
        AnyOf(AbsResidualTol(Float64(cli[:eps])), MaxIters(cli[:maxiter]))
    else
        AnyOf(AbsResidualTol(Float64(cli[:eps])),
              MaxIters(cli[:maxiter]),
              MaxTime(Float64(tl)))
    end
    return DFProjection(;
        direction  = SpectralThreeTerm(; r = cli[:r]),
        linesearch = ls,
        inertial   = Inertial(cli[:theta]),
        ζ          = cli[:zeta],
        abstol     = cli[:eps],
        maxiters   = cli[:maxiter],
        stopping   = stop,
        callbacks  = callbacks,
    )
end

# ============================================================================
# Palette registration
# ============================================================================

"""
    register_palette(db, cli) -> Vector of NamedTuple{label, ls, alg, config_hash}

For each LS label in cli[:ls], resolves the LS struct, builds the alg,
computes the canonical config_hash, and registers the config row in the
DB. Returns the palette ready for worklist construction.
"""
function register_palette(db, cli::Dict)
    palette = Any[]
    for label in cli[:ls]
        ls   = resolve_ls(label, cli)
        alg  = build_alg(ls, cli)
        params = build_params(label, ls, cli)
        method  = "DFProjection_$(label)"
        version = "0.3.0"
        (hash, hash_input) = make_config_hash(method, version, params, cli[:eps], cli[:maxiter])
        ensure_config!(db, hash, method, version, params, cli[:eps], cli[:maxiter], hash_input)
        push!(palette, (; label = label, ls = ls, alg = alg, config_hash = hash))
    end
    return palette
end

# ============================================================================
# Existing-set lookup (batched is_done query)
# ============================================================================

function existing_set(db, worklist::Vector{WorkItem}, force::Bool)
    existing = Set{Tuple{String,String,Int,String}}()
    (force || isempty(worklist)) && return existing
    unique_hashes = unique(w.config_hash for w in worklist)
    placeholders  = join(fill("?", length(unique_hashes)), ",")
    rows = DBInterface.execute(db,
        "SELECT config_hash, problem, dimension, init_point FROM results " *
        "WHERE config_hash IN ($placeholders)",
        Tuple(unique_hashes)) |> DataFrame
    for r in eachrow(rows)
        push!(existing, (String(r.config_hash), String(r.problem),
                         Int(r.dimension),   String(r.init_point)))
    end
    return existing
end

# ============================================================================
# Threads sanity warning
# ============================================================================

function threads_warn(cli::Dict)
    if cli[:threads] >= 2 && Threads.nthreads() < cli[:threads]
        @warn "--threads=$(cli[:threads]) requested but Julia was launched with $(Threads.nthreads()) thread(s). Launch with `julia -t N` (or `JULIA_NUM_THREADS=N`) to use $(cli[:threads]) workers."
    end
end

# ============================================================================
# run_sweep — serial + threaded solve loop
# ============================================================================
#
# Dispatches on cli[:threads]:
#   - threads == 1: serial loop with optional shared ProgressUpdateCallback
#                   attached to each alg.callbacks for live mid-solve display
#   - threads >= 2: producer/consumer with Channel{WorkItem} + N
#                   Threads.@spawn workers + 1 writer task owning its own DB
#                   handle. No callback under threading (multi-threaded bar
#                   mutation is unsafe); writer drives the bar instead.
#
# Inserts results into `db` (serial) or a per-writer DB handle (threaded).
# Returns (counters::NamedTuple, elapsed::Float64).

function run_sweep(db, palette, worklist::Vector{WorkItem}, cli::Dict, tee,
                   n_total::Int, existing::Set)
    counters = (conv = Threads.Atomic{Int}(0),
                fail = Threads.Atomic{Int}(0))

    n_todo = count(w -> !(((w.config_hash, w.prob_name, w.n, w.init_name) in existing)
                          && !cli[:force]), worklist)

    prog = (cli[:display] === :progress) ? ProgressMeter.Progress(n_todo;
        desc      = "Sweep: ",
        dt        = 0.1,
        barglyphs = ProgressMeter.BarGlyphs("[=> ]"),
        output    = stdout,
        color     = :cyan,
    ) : nothing

    t_sweep = time()

    if cli[:threads] >= 2
        _run_threaded(db, palette, worklist, cli, tee, n_total, existing, counters, prog)
    else
        _run_serial(db, palette, worklist, cli, tee, n_total, existing, counters, prog)
    end

    cli[:display] === :progress && ProgressMeter.finish!(prog)

    elapsed = time() - t_sweep
    n_done  = counters.conv[] + counters.fail[]
    println(tee, "-" ^ 76)
    @printf(tee, "Sweep complete: %d solved (%d converged, %d failed/errored) in %.1f s\n",
            n_done, counters.conv[], counters.fail[], elapsed)
    println(tee, "-" ^ 76)

    return (counters, elapsed)
end

function _run_serial(db, palette, worklist, cli, tee, n_total, existing, counters, prog)
    # Snapshot-and-restore so a re-run in the same Julia session doesn't
    # accumulate stale ProgressUpdateCallback instances on `p.alg.callbacks`.
    # (Each push! adds one; without restore, an interactive `include` of the
    # script twice would leave 2 callbacks holding refs to dead Progress
    # objects.) The save Dict is keyed on `p.alg` rather than `p` because
    # `p` itself is a NamedTuple — unique-per-palette-entry either way.
    saved_callbacks = Dict{Any, Vector}()
    shared_cb = nothing
    if cli[:display] === :progress
        shared_cb = ProgressUpdateCallback(prog, cli[:maxiter], counters)
        for p in palette
            saved_callbacks[p.alg] = copy(p.alg.callbacks)
            push!(p.alg.callbacks, shared_cb)
        end
    end

    try
        for (i, w) in enumerate(worklist)
            if !cli[:force] && (w.config_hash, w.prob_name, w.n, w.init_name) in existing
                continue
            end
            if cli[:display] === :progress
                shared_cb.ls_label  = w.ls_label
                shared_cb.prob_name = w.prob_name
                shared_cb.n         = w.n
                shared_cb.init_name = w.init_name
            end

            run_id = Dates.format(now(), "yyyymmdd_HHMMSS_sss") * @sprintf("_%05d", i)
            result = try
                set = w.prob.set_factory(w.n)
                solve_with_alg(w.prob.F, set, w.x0, w.alg;
                               eps     = cli[:eps],
                               maxiter = cli[:maxiter])
            catch err
                @error "Solve failed" task=i ls=w.ls_label problem=w.prob_name n=w.n init=w.init_name exception=(err, catch_backtrace())
                nothing
            end

            if result !== nothing
                insert_result!(db, w.config_hash, w.prob_name, w.n, w.init_name, run_id, result)
            end

            if result !== nothing && result.converged
                Threads.atomic_add!(counters.conv, 1)
            else
                Threads.atomic_add!(counters.fail, 1)
            end

            norm_F = if result === nothing
                NaN
            else
                try; norm(w.prob.F(result.x)); catch; NaN; end
            end

            if cli[:display] === :progress
                ProgressMeter.next!(prog;
                    showvalues = [
                        ("LS",        w.ls_label),
                        ("Problem",   w.prob_name),
                        ("n",         w.n),
                        ("Init",      w.init_name),
                        ("Iter",      result === nothing ? "ERR" : "$(result.iterations)/$(cli[:maxiter])"),
                        ("‖F‖",       result === nothing ? "ERR" : @sprintf("%.2e", norm_F)),
                        ("Converged", counters.conv[]),
                        ("Failed",    counters.fail[]),
                    ])
            elseif cli[:display] === :table
                if result === nothing
                    @printf(tee, "  [%4d/%4d] %-6s %-25s n=%-6d %-15s  ✗ ERROR (see @error above)\n",
                            i, n_total, w.ls_label, w.prob_name, w.n, w.init_name)
                else
                    @printf(tee, "  [%4d/%4d] %-6s %-25s n=%-6d %-15s  %s  it=%-4d fe=%-5d cpu=%7.3fs  ‖F(x*)‖=%9.2e\n",
                            i, n_total, w.ls_label, w.prob_name, w.n, w.init_name,
                            result.converged ? "✓" : "✗",
                            result.iterations, result.f_evals, result.cpu_time,
                            norm_F)
                end
            end
        end
    finally
        # Restore each alg.callbacks to its pre-sweep state — defensive
        # cleanup so re-runs in the same session don't accumulate stale cbs.
        for (alg, original) in saved_callbacks
            resize!(alg.callbacks, length(original))
            copyto!(alg.callbacks, original)
        end
    end
end

function _run_threaded(db, palette, worklist, cli, tee, n_total, existing, counters, prog)
    # Pre-filter worklist to just the to-solve items
    todo = WorkItem[]
    for w in worklist
        if cli[:force] || !((w.config_hash, w.prob_name, w.n, w.init_name) in existing)
            push!(todo, w)
        end
    end

    work_ch    = Channel{WorkItem}(length(todo))
    result_ch  = Channel{Any}(2 * cli[:threads])
    run_id_ctr = Threads.Atomic{Int}(0)

    foreach(w -> put!(work_ch, w), todo)
    close(work_ch)

    # Writer task: owns DB handle + drives the bar
    writer = Threads.@spawn begin
        db_writer = open_db()
        try
            for rec in result_ch
                if rec.result !== nothing
                    insert_result!(db_writer, rec.config_hash, rec.prob_name,
                                   rec.n, rec.init_name, rec.run_id, rec.result)
                end
                if prog !== nothing
                    ProgressMeter.next!(prog;
                        showvalues = [
                            ("LS",        rec.ls_label),
                            ("Problem",   rec.prob_name),
                            ("n",         rec.n),
                            ("Init",      rec.init_name),
                            ("Iter",      rec.result === nothing ? "ERR" :
                                          "$(rec.result.iterations)/$(cli[:maxiter])"),
                            ("‖F‖",       rec.result === nothing ? "ERR" :
                                          @sprintf("%.2e", rec.norm_F)),
                            ("Converged", counters.conv[]),
                            ("Failed",    counters.fail[]),
                        ])
                end
                if cli[:display] === :table
                    if rec.result === nothing
                        @printf(tee, "  [thr%02d] %-6s %-25s n=%-6d %-15s  ✗ ERROR\n",
                                rec.thread_id, rec.ls_label, rec.prob_name, rec.n, rec.init_name)
                    else
                        @printf(tee, "  [thr%02d] %-6s %-25s n=%-6d %-15s  %s  it=%-4d fe=%-5d cpu=%7.3fs  ‖F‖=%9.2e\n",
                                rec.thread_id, rec.ls_label, rec.prob_name, rec.n, rec.init_name,
                                rec.result.converged ? "✓" : "✗",
                                rec.result.iterations, rec.result.f_evals, rec.result.cpu_time,
                                rec.norm_F)
                    end
                end
            end
        finally
            close(db_writer)
        end
    end

    # N worker tasks
    workers = [Threads.@spawn begin
        for w in work_ch
            # Per-task alg rebuild — no callbacks under threading
            local_ls  = resolve_ls(w.ls_label, cli)
            local_alg = build_alg(local_ls, cli)

            idx = Threads.atomic_add!(run_id_ctr, 1) + 1
            run_id = Dates.format(now(), "yyyymmdd_HHMMSS_sss") *
                     @sprintf("_t%02d_%06d", Threads.threadid(), idx)

            result = try
                set = w.prob.set_factory(w.n)
                solve_with_alg(w.prob.F, set, w.x0, local_alg;
                               eps     = cli[:eps],
                               maxiter = cli[:maxiter])
            catch err
                @error "Solve failed" thread=Threads.threadid() ls=w.ls_label problem=w.prob_name n=w.n init=w.init_name exception=(err, catch_backtrace())
                nothing
            end

            if result !== nothing && result.converged
                Threads.atomic_add!(counters.conv, 1)
            else
                Threads.atomic_add!(counters.fail, 1)
            end

            # Guarded residual: NaN/Inf in result.x must not crash the worker
            # (would deadlock result_ch). See post-impl review notes T.5a.
            norm_F = if result === nothing
                NaN
            else
                try; norm(w.prob.F(result.x)); catch; NaN; end
            end

            put!(result_ch, (
                config_hash = w.config_hash,
                prob_name   = w.prob_name,
                n           = w.n,
                init_name   = w.init_name,
                ls_label    = w.ls_label,
                run_id      = run_id,
                result      = result,
                norm_F      = norm_F,
                thread_id   = Threads.threadid(),
            ))
        end
    end for _ in 1:cli[:threads]]

    foreach(wait, workers)
    close(result_ch)
    wait(writer)
end
