# ============================================================================
# s{NN}: Main Benchmark — all algorithms × problems × dims × inits
# ============================================================================
#
# SQLite-backed, content-addressable, with selective history tracking.
# Skip-by-default: completed (config_hash, problem, dim, init) combos are
# skipped automatically. Use --force to override.
#
# Usage:
#   julia --project=. scripts/s{NN}_benchmark.jl --all                # full run
#   julia --project=. scripts/s{NN}_benchmark.jl --all --force        # re-run all
#   julia --project=. scripts/s{NN}_benchmark.jl --all --verbose      # progress bar
#   julia --project=. scripts/s{NN}_benchmark.jl --quick              # dev subset
#   julia --project=. scripts/s{NN}_benchmark.jl --problems=P1,P5     # subset
#   julia --project=. scripts/s{NN}_benchmark.jl --dims=10000         # one dim
#   julia --project=. scripts/s{NN}_benchmark.jl --methods={Algo1},{Algo2}
#   julia --project=. scripts/s{NN}_benchmark.jl --summary            # print stats
#   julia --project=. scripts/s{NN}_benchmark.jl --export             # CSV export
#
# Results: results/experiments.db
# Log:     results/logs/benchmark_<timestamp>.log
# ============================================================================

# --- Load project code ---
# Style A: push!(LOAD_PATH, joinpath(@__DIR__, "..", "src")); using {ModuleName}
# Style B:
include(joinpath(@__DIR__, "..", "src", "includes.jl"))
using ProgressMeter

# ── WorkItem (must be at top level — Julia requires struct outside function) ─
struct WorkItem
    method::String
    config_hash::String
    prob_id::Int
    prob_str::String
    dim::Int
    init_label::String
    x0::Vector{Float64}
    track::Bool
end

function main()
    # ══════════════════════════════════════════════════════════════════════
    # EXPERIMENT CONFIGURATION — single source of truth
    # ══════════════════════════════════════════════════════════════════════

    const_eps = 1e-9
    const_maxiter = 1000

    # Solver configs: name => (fn, version, params)
    # The SAME NamedTuple `params` is hashed AND splatted to the solver.
    # ── Adapt to your project's solvers ──────────────────────────────────
    solvers = Dict(
        # "AlgoName" => (
        #     fn      = solve_algo,
        #     version = ALGO_VERSION,
        #     params  = ALGO_DEFAULTS,   # or tuned: (param1=0.5, param2=0.1)
        # ),
    )

    all_problems = ["P$id" for id in PROBLEM_IDS]
    all_methods = collect(keys(solvers))

    # Dimension tiers
    dims_small = [1_000, 5_000, 10_000]
    dims_mid   = [20_000, 50_000]
    dims_large = [80_000, 100_000]
    all_dims   = vcat(dims_small, dims_mid, dims_large)

    # Selective history tracking: record per-iteration data for a subset
    track_filter = (
        problems = ["P1", "P5"],          # representative subset
        dims     = [10_000, 100_000],     # one per tier
        inits    = ["v1", "v3", "v7"],    # zero, unit, ramp
        methods  = all_methods,
    )

    function should_track(method, prob, dim, init)
        return prob in track_filter.problems &&
               dim in track_filter.dims &&
               init in track_filter.inits &&
               method in track_filter.methods
    end

    # ══════════════════════════════════════════════════════════════════════
    # CLI PARSING
    # ══════════════════════════════════════════════════════════════════════

    flags = Set{String}()
    kv = Dict{String,String}()
    for a in ARGS
        if startswith(a, "--") && contains(a, "=")
            k, v = split(a[3:end], "="; limit=2)
            kv[k] = v
        elseif startswith(a, "--")
            push!(flags, a[3:end])
        end
    end

    do_all     = "all" in flags
    do_force   = "force" in flags
    do_summary = "summary" in flags
    do_export  = "export" in flags
    do_verbose = "verbose" in flags
    do_quick   = "quick" in flags

    # Selection (--quick overrides to a small subset)
    sel_problems = haskey(kv, "problems") ? String.(split(kv["problems"], ",")) : all_problems
    sel_methods  = haskey(kv, "methods") ? String.(split(kv["methods"], ",")) : all_methods

    if do_quick
        sel_dims = dims_small[1:1]
        sel_problems = all_problems[1:min(3, length(all_problems))]
    elseif haskey(kv, "dims")
        sel_dims = [parse(Int, s) for s in split(kv["dims"], ",")]
    elseif do_all
        sel_dims = all_dims
    else
        sel_dims = Int[]
    end

    # ══════════════════════════════════════════════════════════════════════
    # SETUP
    # ══════════════════════════════════════════════════════════════════════

    logpath, tee, logfile = setup_logging("benchmark")
    db = open_db()
    run_id = Dates.format(now(), "yyyyMMdd_HHMMss")

    # ── Summary mode (early exit) ────────────────────────────────────────
    if do_summary
        print_summary(db, tee, all_methods)
        teardown_logging(tee, logpath)
        return
    end

    # ── Export mode (early exit) ─────────────────────────────────────────
    if do_export
        export_path = joinpath(JCODE_ROOT, "results", "benchmark_export.csv")
        n = export_results_csv(db, export_path)
        println(tee, "Exported $n rows to: $export_path")
        teardown_logging(tee, logpath)
        return
    end

    # ── Validate selection ───────────────────────────────────────────────
    if isempty(sel_problems) || isempty(sel_dims) || isempty(sel_methods)
        println(tee, "Nothing selected. Use --all or specify --problems=, --dims=, --methods=")
        teardown_logging(tee, logpath)
        return
    end

    if isempty(solvers)
        println(tee, "NO SOLVERS CONFIGURED — add entries to the `solvers` dict")
        teardown_logging(tee, logpath)
        return
    end

    # ══════════════════════════════════════════════════════════════════════
    # COMPUTE CONFIG HASHES + ENSURE IN DB
    # ══════════════════════════════════════════════════════════════════════

    solver_hashes = Dict{String,String}()
    for (name, cfg) in solvers
        name in sel_methods || continue
        hash, hash_input = make_config_hash(name, cfg.version, cfg.params,
                                            const_eps, const_maxiter)
        solver_hashes[name] = hash
        ensure_config!(db, hash, name, cfg.version, cfg.params,
                      const_eps, const_maxiter, hash_input)
    end

    # ══════════════════════════════════════════════════════════════════════
    # BUILD WORK LIST
    # ══════════════════════════════════════════════════════════════════════

    work = WorkItem[]
    for dim in sel_dims
        for pid in PROBLEM_IDS
            prob_str = "P$pid"
            prob_str in sel_problems || continue
            for method in sel_methods
                haskey(solver_hashes, method) || continue
                hash = solver_hashes[method]
                inits = get_initial_points(dim, pid)

                for (init_label, x0) in inits
                    track = should_track(method, prob_str, dim, init_label)

                    # Skip-by-default logic (D14):
                    # 1. --force → always run
                    # 2. result exists, no tracking needed → skip
                    # 3. result exists, tracking needed, history exists → skip
                    # 4. result exists, tracking needed, no history → re-run
                    # 5. no result → run
                    if !do_force && is_done(db, hash, prob_str, dim, init_label)
                        if track
                            hist_check = DBInterface.execute(db,
                                "SELECT 1 FROM history WHERE config_hash=? AND problem=? AND dimension=? AND init_point=? LIMIT 1",
                                (hash, prob_str, dim, init_label)) |> DataFrame
                            nrow(hist_check) > 0 && continue
                        else
                            continue
                        end
                    end
                    push!(work, WorkItem(method, hash, pid, prob_str, dim,
                                        init_label, x0, track))
                end
            end
        end
    end

    # ══════════════════════════════════════════════════════════════════════
    # PRINT CONFIG
    # ══════════════════════════════════════════════════════════════════════

    println(tee, "=" ^ 75)
    println(tee, "  Benchmark — $(Dates.now())")
    println(tee, "=" ^ 75)
    println(tee, "  Methods:  $(join(sel_methods, ", "))")
    println(tee, "  Problems: $(length(sel_problems))")
    println(tee, "  Dims:     $(join(sel_dims, ", "))")
    println(tee, "  Total:    $(length(work)) runs")
    n_track = count(w -> w.track, work)
    println(tee, "  Tracked:  $n_track (with convergence history)")
    println(tee, "  Force:    $do_force")
    println(tee, "  Quick:    $do_quick")
    println(tee, "  DB:       $(DB_PATH)")
    println(tee)
    for (name, cfg) in solvers
        name in sel_methods || continue
        println(tee, "  $name v$(cfg.version) [$(solver_hashes[name])]")
    end
    println(tee, "=" ^ 75)

    if isempty(work)
        println(tee, "Nothing to do — all runs already complete.")
        teardown_logging(tee, logpath)
        return
    end

    # ══════════════════════════════════════════════════════════════════════
    # MAIN LOOP
    # ══════════════════════════════════════════════════════════════════════

    t_total = time()
    n_done = 0; n_conv = 0; n_fail = 0

    prog = do_verbose ?
        Progress(length(work); barlen=40, showspeed=true, desc="  Running: ") :
        nothing

    for w in work
        prob = get_problem(w.prob_id)
        cfg = solvers[w.method]

        # Build solver callback for progress bar
        cb = nothing
        if do_verbose && prog !== nothing
            cb = (k::Int, metric::Float64, mi::Int) -> begin
                ProgressMeter.update!(prog, n_done;
                    showvalues=[
                        (:done,    "$n_done/$(length(work))"),
                        (:conv,    "$n_conv / $n_fail"),
                        (:current, "$(w.method) $(w.prob_str) m=$(w.dim) $(w.init_label)"),
                        (:iter,    @sprintf("k=%d/%d  metric=%.2e", k, mi, metric)),
                    ])
            end
        end

        # ── Run solver ───────────────────────────────────────────────────
        result = try
            cfg.fn(prob.F, prob.proj, copy(w.x0);
                   cfg.params..., eps=const_eps, maxiter=const_maxiter,
                   track=w.track, callback=cb)
        catch e
            make_result(converged=false, iterations=const_maxiter,
                       f_evals=0, cpu_time=0.0, x=copy(w.x0), flag=:error)
        end

        # ── Update counters ──────────────────────────────────────────────
        n_done += 1
        result.converged ? (n_conv += 1) : (n_fail += 1)

        # ── Save to DB ───────────────────────────────────────────────────
        insert_result!(db, w.config_hash, w.prob_str, w.dim,
                      w.init_label, run_id, result)
        if w.track && !isempty(result.history)
            insert_history!(db, w.config_hash, w.prob_str, w.dim,
                           w.init_label, result.history)
        end

        # ── Progress / output ────────────────────────────────────────────
        if prog !== nothing
            ProgressMeter.update!(prog, n_done;
                showvalues=[
                    (:done,    "$n_done/$(length(work))"),
                    (:conv,    "$n_conv / $n_fail"),
                    (:current, "$(w.method) $(w.prob_str) m=$(w.dim) $(w.init_label)"),
                    (:iter,    result.converged ? "CONVERGED" : string(result.flag)),
                ])
        end

        if !do_verbose
            status = result.converged ? "OK" : "FAIL"
            @printf(tee, "  %-8s %-4s m=%-6d %-4s  %4s  IT=%-5d FE=%-5d  %.3fs\n",
                    w.method, w.prob_str, w.dim, w.init_label,
                    status, result.iterations, result.f_evals, result.cpu_time)
        end
    end

    prog !== nothing && finish!(prog)

    # ══════════════════════════════════════════════════════════════════════
    # FINAL SUMMARY
    # ══════════════════════════════════════════════════════════════════════

    elapsed = time() - t_total
    println(tee)
    println(tee, "-" ^ 75)
    @printf(tee, "Done: %d runs in %.1fs (%.1f min)\n", length(work), elapsed, elapsed/60)
    @printf(tee, "  Converged: %d   Failed: %d   Rate: %.1f%%\n",
            n_conv, n_fail, 100 * n_conv / max(n_done, 1))
    println(tee, "  DB: $(DB_PATH)")
    println(tee, "-" ^ 75)
    println(tee, "Run with --summary for aggregate statistics.")
    println(tee, "Run with --export for CSV export.")

    teardown_logging(tee, logpath)
end

main()
