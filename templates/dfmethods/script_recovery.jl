#!/usr/bin/env julia
# s40_recovery.jl — Ibrahim 2026 §4.2 recovery sweep (DFMethods v0.3.0)
#
# Re-runs problems that failed in a prior (typically T.5b) primary sweep
# under RELAXED stopping criteria: paper §4.2 defaults are
# `maxiter = 100_000, time_limit = 300 s` (whichever comes first), keeping
# `eps = 1e-6` from the primary sweep.
#
# Reuses `src/sweep_helpers.jl` for the palette / alg construction / solve
# loop — same threaded/serial dispatch as `s30_benchmark.jl`. Differences:
#   - Different default --maxiter and a non-nothing --time-limit (which
#     adds MaxTime to the AnyOf stopping rule).
#   - Worklist comes from a DB query for previously-failed tasks (under
#     --target=failures), not from palette × problems × dims × inits.
#   - A recovery-summary table at the end shows per-LS {prev-failed,
#     recovered, still-failed} — mirrors paper Table 4.
#
# How "previously failed" is identified:
#   The reference sweep is the set of `results` rows where
#     - `dimension != 1000` (excludes n=1000 validation rows)
#     - `configs.eps == --ref-eps`           (default: 1e-6)
#     - `configs.maxiter == --ref-maxiter`   (default: 2000 — i.e. T.5b)
#     - `configs.method` ∈ cli[:ls]
#     - `results.converged = 0`
#   Each such row is re-attempted with the new (relaxed) config_hash. The
#   new and old hashes differ because (eps, maxiter, time_limit_s) differ,
#   so the new rows don't overwrite the reference.
#
# CLI flags:
#   --ls=LSI,LSII,...         (default: all 7)               Subset of LS to recover
#   --problems=1-10,p15,...   (default: 1-28)                Subset of problems
#   --dims=15000,50000,150000 (default: paper)               Restrict variable-n
#                                                             scope. Fixed-n
#                                                             problems (p3/p4/p5)
#                                                             always run at their
#                                                             native dim regardless.
#   --target=failures|all     (default: failures)            failures = only tasks
#                                                             that failed in the
#                                                             reference sweep; all =
#                                                             full T.5b-equivalent scope
#   --eps=1e-6                                                Convergence tolerance
#   --maxiter=100000          (paper §4.2 default)            Max iters per solve
#   --time-limit=300          (paper §4.2 default, seconds)   Wall-clock cap per solve
#   --ref-eps=1e-6                                            Reference sweep's eps
#   --ref-maxiter=2000                                        Reference sweep's maxiter
#   --rho=0.6 --sigma=0.01 --theta=0.25 --zeta=0.5            Paper algorithm params
#   --r=0.1                                                   SpectralThreeTerm direction
#   --threads=N (default: 1, serial)                          Threaded sweep
#   --force                                                    Override resume
#   --display=silent|progress|table  (default: progress)
#   --verbose                                                 Alias for --display=table
#   --summary                                                 Print recovery table + exit
#
# Examples:
#   # Default §4.2 recovery: only failures, paper-grade relaxed criteria, 8 threads
#   julia -t 9 --project=. scripts/s40_recovery.jl --threads=8
#
#   # Just LS VII recovery on problem 28 (paper Table 3 lists this as a failure)
#   julia --project=. scripts/s40_recovery.jl --ls=LSVII --problems=p28
#
#   # Print recovery summary table from previously-completed sweep
#   julia --project=. scripts/s40_recovery.jl --summary

include(joinpath(@__DIR__, "..", "src", "includes.jl"))
using DFMethods

# ============================================================================
# CLI parsing
# ============================================================================

function _parse_target(s::AbstractString)
    sym = Symbol(strip(s))
    sym in (:failures, :all) ||
        error("Unknown --target value '$s'. Available: failures, all")
    return sym
end

function parse_cli(args)
    cli = Dict{Symbol,Any}(
        :ls           => copy(LS_IMPLEMENTED),
        :problems     => collect(1:length(PROBLEM_ORDER)),
        :dims         => [15_000, 50_000, 150_000],   # restrict variable-n scope; fixed-n always at native dim
        :eps          => 1e-6,
        :maxiter      => 100_000,         # paper §4.2 default
        :time_limit   => 300.0,           # paper §4.2 default (seconds)
        :rho          => 0.6,
        :sigma        => 0.01,
        :theta        => 0.25,
        :zeta         => 0.5,
        :r            => 0.1,
        :threads      => 1,
        :force        => false,
        :display      => :progress,
        :summary      => false,
        :target       => :failures,
        :ref_eps      => 1e-6,            # which prior sweep is the failure source
        :ref_maxiter  => 2000,
    )
    for a in args
        if     a == "--force";   cli[:force]     = true
        elseif a == "--verbose"; cli[:display]   = :table
        elseif a == "--summary"; cli[:summary]   = true
        elseif startswith(a, "--display=");     cli[:display]     = _parse_display(a[length("--display=")+1:end])
        elseif startswith(a, "--ls=");          cli[:ls]          = _parse_ls_list(a[length("--ls=")+1:end])
        elseif startswith(a, "--problems=");    cli[:problems]    = _parse_problem_list(a[length("--problems=")+1:end])
        elseif startswith(a, "--dims=");        cli[:dims]        = _parse_int_list(a[length("--dims=")+1:end])
        elseif startswith(a, "--eps=");         cli[:eps]         = parse(Float64, a[length("--eps=")+1:end])
        elseif startswith(a, "--maxiter=");     cli[:maxiter]     = parse(Int,     a[length("--maxiter=")+1:end])
        elseif startswith(a, "--time-limit=");  cli[:time_limit]  = parse(Float64, a[length("--time-limit=")+1:end])
        elseif startswith(a, "--rho=");         cli[:rho]         = parse(Float64, a[length("--rho=")+1:end])
        elseif startswith(a, "--sigma=");       cli[:sigma]       = parse(Float64, a[length("--sigma=")+1:end])
        elseif startswith(a, "--theta=");       cli[:theta]       = parse(Float64, a[length("--theta=")+1:end])
        elseif startswith(a, "--zeta=");        cli[:zeta]        = parse(Float64, a[length("--zeta=")+1:end])
        elseif startswith(a, "--r=");           cli[:r]           = parse(Float64, a[length("--r=")+1:end])
        elseif startswith(a, "--threads=");     cli[:threads]     = parse(Int,     a[length("--threads=")+1:end])
        elseif startswith(a, "--target=");      cli[:target]      = _parse_target(a[length("--target=")+1:end])
        elseif startswith(a, "--ref-eps=");     cli[:ref_eps]     = parse(Float64, a[length("--ref-eps=")+1:end])
        elseif startswith(a, "--ref-maxiter="); cli[:ref_maxiter] = parse(Int,     a[length("--ref-maxiter=")+1:end])
        else
            error("Unknown CLI flag: '$a'. See script header for usage.")
        end
    end
    return cli
end

# ============================================================================
# DB query: failures from the reference sweep
# ============================================================================

const _FIXED_N_PROBLEM_NAMES = ("ArcTan", "ArcTan2", "StrictlyMonotone")

function fetch_failures(db, cli::Dict)
    method_set = ["DFProjection_$(l)" for l in cli[:ls]]
    placeholders_methods = join(fill("?", length(method_set)), ",")
    placeholders_dims    = join(fill("?", length(cli[:dims])), ",")
    placeholders_fixed   = join(fill("?", length(_FIXED_N_PROBLEM_NAMES)), ",")
    # --dims restricts the VARIABLE-n scope; fixed-n problems (p3/p4/p5)
    # always run at their native dim regardless of --dims, so we OR them in.
    sql = """
        SELECT c.method, r.problem, r.dimension, r.init_point
        FROM results r
        JOIN configs c ON r.config_hash = c.config_hash
        WHERE r.converged = 0
          AND (r.dimension IN ($placeholders_dims)
               OR r.problem IN ($placeholders_fixed))
          AND c.eps = ?
          AND c.maxiter = ?
          AND c.method IN ($placeholders_methods)
        ORDER BY c.method, r.problem, r.dimension, r.init_point
    """
    binds = (cli[:dims]..., _FIXED_N_PROBLEM_NAMES...,
             cli[:ref_eps], cli[:ref_maxiter], method_set...)
    return DBInterface.execute(db, sql, binds) |> DataFrame
end

# ============================================================================
# Worklist construction — two flavors
# ============================================================================

# Failure-targeted: one WorkItem per row returned by fetch_failures.
function build_worklist_from_failures(palette, failures, problem_lookup, cli)
    palette_by_method = Dict("DFProjection_$(p.label)" => p for p in palette)
    worklist = WorkItem[]
    for row in eachrow(failures)
        method    = String(row.method)
        haskey(palette_by_method, method) || continue
        p         = palette_by_method[method]
        prob_name = String(row.problem)
        prob_sym  = Symbol(prob_name)
        haskey(problem_lookup, prob_sym) || continue
        prob      = problem_lookup[prob_sym]
        n         = Int(row.dimension)
        init_name = String(row.init_point)

        # Resolve x0 from get_initial_points(n, prob.id)
        inits = get_initial_points(n, prob.id)
        idx = findfirst(t -> t[1] == init_name, inits)
        if idx === nothing
            @warn "Init point '$init_name' not found for problem '$prob_name' at n=$n; skipping"
            continue
        end
        x0 = inits[idx][2]
        push!(worklist, WorkItem(p.label, p.config_hash, p.alg,
                                  prob_name, prob, n, init_name, x0))
    end
    return worklist
end

# Full T.5b-equivalent scope (for --target=all): mirrors s30's build_worklist
# using cli[:dims] for variable-n and prob.fixed_n for p3/p4/p5.
function build_worklist_all(palette, selected_problems, cli)
    worklist = WorkItem[]
    for p in palette, prob in selected_problems
        prob_dims = prob.fixed_n === nothing ? cli[:dims] : [prob.fixed_n]
        for n in prob_dims
            for (init_name, x0) in get_initial_points(n, prob.id)
                push!(worklist, WorkItem(p.label, p.config_hash, p.alg,
                                         String(prob.name), prob, n,
                                         init_name, x0))
            end
        end
    end
    return worklist
end

# ============================================================================
# Recovery summary table — per-LS {prev-failed, recovered, still-failed}
# ============================================================================

function print_recovery_summary(db, tee, palette, cli)
    println(tee, "")
    println(tee, "=" ^ 78)
    println(tee, "  Recovery summary — re-run of (eps=$(cli[:ref_eps]), maxiter=$(cli[:ref_maxiter])) failures")
    println(tee, "                     with relaxed criteria (eps=$(cli[:eps]), maxiter=$(cli[:maxiter]), time-limit=$(cli[:time_limit])s)")
    println(tee, "=" ^ 78)
    @printf(tee, "\n  %-22s  %12s  %10s  %12s  %8s\n",
            "Method", "Prev failed", "Recovered", "Still failed", "Recov %")
    println(tee, "  " * "-" ^ 72)

    palette_by_method = Dict("DFProjection_$(p.label)" => p for p in palette)

    placeholders_dims  = join(fill("?", length(cli[:dims])), ",")
    placeholders_fixed = join(fill("?", length(_FIXED_N_PROBLEM_NAMES)), ",")
    dim_or_fixed_clause = "(r.dimension IN ($placeholders_dims) OR r.problem IN ($placeholders_fixed))"
    old_dim_or_fixed_clause = "(old_r.dimension IN ($placeholders_dims) OR old_r.problem IN ($placeholders_fixed))"

    for label in cli[:ls]
        method = "DFProjection_$(label)"
        # Previously failed under reference sweep (within --dims scope)
        sql_prev = """
            SELECT COUNT(*) AS cnt
            FROM results r
            JOIN configs c ON r.config_hash = c.config_hash
            WHERE r.converged = 0
              AND $dim_or_fixed_clause
              AND c.eps = ?
              AND c.maxiter = ?
              AND c.method = ?
        """
        prev_binds = (cli[:dims]..., _FIXED_N_PROBLEM_NAMES...,
                      cli[:ref_eps], cli[:ref_maxiter], method)
        prev_df = DBInterface.execute(db, sql_prev, prev_binds) |> DataFrame
        prev = Int(prev_df.cnt[1])

        # Recovered: rows that failed in old AND converged in new (palette hash)
        if haskey(palette_by_method, method)
            new_hash = palette_by_method[method].config_hash
            sql_rec = """
                SELECT COUNT(*) AS cnt
                FROM results new_r
                JOIN results old_r
                  ON old_r.problem    = new_r.problem
                 AND old_r.dimension  = new_r.dimension
                 AND old_r.init_point = new_r.init_point
                JOIN configs old_c ON old_r.config_hash = old_c.config_hash
                WHERE new_r.config_hash = ?
                  AND new_r.converged = 1
                  AND old_r.converged = 0
                  AND $old_dim_or_fixed_clause
                  AND old_c.eps = ?
                  AND old_c.maxiter = ?
                  AND old_c.method = ?
            """
            rec_binds = (new_hash, cli[:dims]..., _FIXED_N_PROBLEM_NAMES...,
                         cli[:ref_eps], cli[:ref_maxiter], method)
            rec_df = DBInterface.execute(db, sql_rec, rec_binds) |> DataFrame
            recovered = Int(rec_df.cnt[1])
        else
            recovered = 0
        end

        still   = prev - recovered
        pct     = prev > 0 ? 100.0 * recovered / prev : 0.0
        @printf(tee, "  %-22s  %12d  %10d  %12d  %7.1f%%\n",
                method, prev, recovered, still, pct)
    end
    println(tee, "  " * "-" ^ 72)
end

# ============================================================================
# Main
# ============================================================================

function main()
    cli = parse_cli(ARGS)
    threads_warn(cli)

    (logpath, tee, logfile) = setup_logging("s40_recovery")
    println(tee, "=" ^ 76)
    println(tee, "s40_recovery — Ibrahim 2026 §4.2 recovery sweep (DFMethods v0.3.0)")
    println(tee, "=" ^ 76)

    db = open_db()
    println(tee, "DB:          ", DB_PATH)

    # Register palette FIRST so --summary mode can use its new config_hashes
    palette = register_palette(db, cli)

    if cli[:summary]
        print_recovery_summary(db, tee, palette, cli)
        teardown_logging(tee, logpath)
        return
    end

    selected_problems = [get_problem(id) for id in cli[:problems]]
    problem_lookup    = Dict(p.name => p for p in selected_problems)

    worklist = if cli[:target] === :failures
        failures = fetch_failures(db, cli)
        if nrow(failures) == 0
            println(tee, "No failed rows found under reference sweep (eps=$(cli[:ref_eps]), maxiter=$(cli[:ref_maxiter])).")
            println(tee, "Nothing to recover. Either the reference sweep is missing or all tasks succeeded.")
            teardown_logging(tee, logpath)
            return
        end
        build_worklist_from_failures(palette, failures, problem_lookup, cli)
    else
        build_worklist_all(palette, selected_problems, cli)
    end

    pks = [(w.config_hash, w.prob_name, w.n, w.init_name) for w in worklist]
    @assert allunique(pks) "Worklist contains duplicate (config_hash, problem, dim, init) keys"

    existing = existing_set(db, worklist, cli[:force])

    # Banner
    n_total = length(worklist)
    n_skip  = count(w -> (w.config_hash, w.prob_name, w.n, w.init_name) in existing, worklist)
    n_todo  = n_total - n_skip

    println(tee, "-" ^ 76)
    println(tee, "Recovery sweep:")
    println(tee, "  Target:        ", cli[:target])
    if cli[:target] === :failures
        println(tee, "  Reference:     eps=$(cli[:ref_eps]), maxiter=$(cli[:ref_maxiter]) (failures sourced from these configs)")
    end
    println(tee, "  Relaxed crit:  eps=$(cli[:eps]), maxiter=$(cli[:maxiter]), time-limit=$(cli[:time_limit])s")
    println(tee, "  LS scope:      ", join(cli[:ls], ", "), "  (", length(cli[:ls]), ")")
    println(tee, "  Problems:      ", length(selected_problems), " selected")
    println(tee, "  Dims:          ", cli[:dims], " (variable-n; fixed-n at native)")
    println(tee, "  Total tasks:   ", n_total)
    println(tee, "  In DB:         ", n_skip, cli[:force] ? "  (will be overwritten)" : "  (will be skipped)")
    println(tee, "  To solve:      ", n_todo)
    println(tee, "-" ^ 76)
    println(tee, "Configs registered (config_hash → method):")
    for p in palette
        println(tee, "  ", p.config_hash, "  ", "DFProjection_$(p.label)")
    end
    println(tee, "-" ^ 76)

    if n_todo == 0
        println(tee, "Nothing to solve. Use --force to re-run, --summary for recovery table.")
        teardown_logging(tee, logpath)
        return
    end

    println(tee, "Display mode: ", cli[:display])
    if cli[:threads] >= 2
        println(tee, "Threading:    $(cli[:threads]) worker tasks + 1 writer task (julia -t $(Threads.nthreads()))")
    end
    println(tee, "Solving…")

    run_sweep(db, palette, worklist, cli, tee, n_total, existing)

    # Always show recovery summary at end
    print_recovery_summary(db, tee, palette, cli)

    teardown_logging(tee, logpath)
end

main()
