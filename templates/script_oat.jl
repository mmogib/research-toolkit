# ============================================================================
# s{NN}: OAT Parameter Sensitivity Analysis for {AlgorithmName}
# ============================================================================
#
# One-At-a-Time (OAT) sweeps: vary each parameter while fixing others at
# baseline defaults. Measures success rate + shifted geometric mean of
# iterations across problems, dimensions, and starting points.
#
# Usage:
#   julia --project=. scripts/s{NN}_sensitivity_oat.jl              # run + summary
#   julia --project=. scripts/s{NN}_sensitivity_oat.jl --summary    # summary from DB
#   julia --project=. scripts/s{NN}_sensitivity_oat.jl --force      # re-run all
#   julia --project=. scripts/s{NN}_sensitivity_oat.jl --quick      # reduced sweep
#   julia --project=. scripts/s{NN}_sensitivity_oat.jl --export     # CSV export
#
# Results: results/experiments.db (oat_results table or configs/results tables)
# Log:     results/logs/sensitivity_oat_<timestamp>.log
# ============================================================================

# --- Load project code ---
# Style A: push!(LOAD_PATH, joinpath(@__DIR__, "..", "src")); using {ModuleName}
# Style B:
include(joinpath(@__DIR__, "..", "src", "includes.jl"))

function main()
    # ── CLI Parsing ──────────────────────────────────────────────────────
    flags = Set{String}()
    for a in ARGS
        startswith(a, "--") && push!(flags, a[3:end])
    end

    do_force   = "force" in flags
    do_summary = "summary" in flags
    do_export  = "export" in flags
    do_quick   = "quick" in flags

    # ── Logging ──────────────────────────────────────────────────────────
    logpath, tee, logfile = setup_logging("sensitivity_oat")
    db = open_db()
    run_id = Dates.format(now(), "yyyyMMdd_HHMMss")

    println(tee, "=" ^ 70)
    println(tee, "  OAT Parameter Sensitivity — $(Dates.now())")
    println(tee, "=" ^ 70)

    # ══════════════════════════════════════════════════════════════════════
    # CONFIGURATION
    # ══════════════════════════════════════════════════════════════════════

    const_eps = 1e-9
    const_maxiter = 1000
    method_name = "{AlgorithmName}"     # must match solver name
    method_version = "{ALGO}_VERSION"   # e.g., SFTDFPM_VERSION

    # Dimensions to test (--quick reduces this)
    dims = do_quick ? [100, 1000] : [100, 1000, 10_000]

    # Baseline parameters (paper defaults)
    # ── Adapt to your algorithm ──────────────────────────────────────────
    baseline = (
        # param1 = 0.5,
        # param2 = 0.1,
        # param3 = 1.8,
    )

    # OAT sweeps: (label, kwarg_symbol, values_to_sweep)
    # ── Adapt ranges to your algorithm's theory ─────────────────────────
    param_sweeps = [
        # ("param1", :param1, [0.1, 0.3, 0.5, 0.7, 0.9]),
        # ("param2", :param2, [1e-4, 1e-3, 1e-2, 0.05, 0.1]),
        # ("param3", :param3, [0.5, 1.0, 1.5, 1.8, 1.99]),
    ]

    # Starting points: use a stratified subset (not all 10)
    init_subset = [1, 3, 6, 8]   # indices into get_initial_points result

    # ── Summary mode (early exit) ────────────────────────────────────────
    if do_summary && !do_force
        _print_oat_summary(db, tee, method_name)
        teardown_logging(tee, logpath)
        return
    end

    # ── Export mode (early exit) ─────────────────────────────────────────
    if do_export
        export_path = joinpath(JCODE_ROOT, "results", "oat_export.csv")
        n = export_results_csv(db, export_path)
        println(tee, "Exported $n rows to: $export_path")
        teardown_logging(tee, logpath)
        return
    end

    # ══════════════════════════════════════════════════════════════════════
    # HELPERS
    # ══════════════════════════════════════════════════════════════════════

    function shifted_geomean(vals; shift=1.0)
        filtered = filter(isfinite, vals)
        isempty(filtered) && return NaN
        return exp(mean(log.(filtered .+ shift))) - shift
    end

    # ══════════════════════════════════════════════════════════════════════
    # SWEEP
    # ══════════════════════════════════════════════════════════════════════

    println(tee, "\n--- Running OAT sweeps ---")
    println(tee, "  Dimensions: $dims")
    println(tee, "  Problems: $(length(PROBLEM_IDS))")
    println(tee, "  Baseline: $baseline")
    println(tee, "  Quick: $do_quick")
    println(tee)

    for (label, kwsym, values) in param_sweeps
        println(tee, "\n  Sweeping $label over $(length(values)) values...")

        for val in values
            override = NamedTuple{(kwsym,)}((val,))
            params = merge(baseline, override)

            # Config hash for this parameter setting
            hash, hash_input = make_config_hash(
                "$(method_name)_OAT", method_version, params, const_eps, const_maxiter)
            ensure_config!(db, hash, "$(method_name)_OAT", method_version,
                          params, const_eps, const_maxiter, hash_input)

            n_conv = 0
            n_total = 0
            iters_list = Float64[]

            for dim in dims
                for prob_id in PROBLEM_IDS
                    prob = get_problem(prob_id)
                    all_inits = get_initial_points(dim, prob_id)
                    inits = all_inits[init_subset]

                    for (init_label, x0) in inits
                        n_total += 1

                        # Skip if done (unless --force)
                        prob_str = "P$prob_id"
                        if !do_force && is_done(db, hash, prob_str, dim, init_label)
                            # Load existing result for aggregate stats
                            r = DBInterface.execute(db,
                                "SELECT converged, iterations FROM results WHERE config_hash=? AND problem=? AND dimension=? AND init_point=?",
                                (hash, prob_str, dim, init_label)) |> DataFrame
                            if nrow(r) > 0 && r.converged[1] == 1
                                n_conv += 1
                                push!(iters_list, Float64(r.iterations[1]))
                            end
                            continue
                        end

                        # Run solver
                        result = try
                            # ── Adapt solver call to your project ────────
                            # solver_fn(prob.F, prob.proj, copy(x0);
                            #           params..., eps=const_eps, maxiter=const_maxiter)
                            make_result(converged=false, iterations=0, f_evals=0,
                                       cpu_time=0.0, x=copy(x0), flag=:not_implemented)
                        catch
                            make_result(converged=false, iterations=const_maxiter,
                                       f_evals=0, cpu_time=0.0, x=copy(x0), flag=:error)
                        end

                        insert_result!(db, hash, prob_str, dim, init_label, run_id, result)

                        if result.converged
                            n_conv += 1
                            push!(iters_list, Float64(result.iterations))
                        end
                    end
                end
            end

            success_rate = n_total > 0 ? n_conv / n_total : 0.0
            gm_iter = shifted_geomean(iters_list)
            @printf(tee, "    %s=%-10s  success=%.1f%%  gm_iter=%.1f  (%d/%d)\n",
                    label, string(val), 100*success_rate, gm_iter, n_conv, n_total)
        end
    end

    # ── Print summary ────────────────────────────────────────────────────
    _print_oat_summary(db, tee, method_name)

    println(tee, "\n" * "=" ^ 70)
    teardown_logging(tee, logpath)
end

# ============================================================================
# Summary Helper
# ============================================================================

function _print_oat_summary(db, tee, method_name)
    println(tee, "\n--- OAT Summary ---")

    configs_df = DBInterface.execute(db, """
        SELECT c.config_hash, c.params_json,
               COUNT(*) as n_total,
               SUM(r.converged) as n_conv,
               AVG(CASE WHEN r.converged=1 THEN r.iterations END) as avg_iter
        FROM results r
        JOIN configs c ON r.config_hash = c.config_hash
        WHERE c.method = ?
        GROUP BY c.config_hash
        ORDER BY CAST(n_conv AS REAL)/n_total DESC, avg_iter ASC
    """, ("$(method_name)_OAT",)) |> DataFrame

    if nrow(configs_df) == 0
        println(tee, "  No OAT results found.")
        return
    end

    println(tee, "  $(nrow(configs_df)) configurations tested")
    @printf(tee, "\n  %-14s  %6s  %7s  %8s\n", "Hash", "Total", "Succ%", "Avg_IT")
    println(tee, "  " * "-" ^ 42)

    for row in eachrow(configs_df)
        succ = row.n_total > 0 ? 100.0 * row.n_conv / row.n_total : 0.0
        @printf(tee, "  %-14s  %6d  %6.1f%%  %8.1f\n",
                row.config_hash, row.n_total, succ,
                ismissing(row.avg_iter) ? NaN : row.avg_iter)
    end
end

main()
