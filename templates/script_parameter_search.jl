# ============================================================================
# s{NN}: Latin Hypercube Parameter Search for {AlgorithmName}
# ============================================================================
#
# Uses LHS sampling to find optimal parameters across scale tiers.
# Results saved to SQLite DB (experiments.db). Skips completed configs
# by default.
#
# Usage:
#   julia --project=. scripts/s{NN}_parameter_search.jl              # run (skips done)
#   julia --project=. scripts/s{NN}_parameter_search.jl --force      # re-run all
#   julia --project=. scripts/s{NN}_parameter_search.jl --summary    # from DB
#   julia --project=. scripts/s{NN}_parameter_search.jl --quick      # reduced sweep
#   julia --project=. scripts/s{NN}_parameter_search.jl --export     # CSV export
#
# Results: results/experiments.db
# Log:     results/logs/parameter_search_<timestamp>.log
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
    logpath, tee, logfile = setup_logging("parameter_search")
    db = open_db()
    run_id = Dates.format(now(), "yyyyMMdd_HHMMss")

    println(tee, "=" ^ 70)
    println(tee, "  LHS Parameter Search — $(Dates.now())")
    println(tee, "=" ^ 70)

    # ══════════════════════════════════════════════════════════════════════
    # CONFIGURATION
    # ══════════════════════════════════════════════════════════════════════

    const_eps = 1e-9
    const_maxiter = 1000
    method_name = "{AlgorithmName}"
    method_version = "{ALGO}_VERSION"

    n_samples = do_quick ? 10 : 50
    top_n = 5

    # Scale tiers
    tiers = do_quick ?
        [(name="Quick", dims=[1_000])] :
        [
            (name="Small", dims=[1_000, 5_000, 10_000]),
            (name="Large", dims=[50_000, 100_000]),
        ]

    # Search space: (label, kwarg_symbol, lo, hi, scale)
    # ── Adapt to your algorithm (refine ranges from OAT results) ────────
    search_params = [
        # ("param1", :param1, 0.01,  1.0,   :linear),
        # ("param2", :param2, 1e-5,  0.1,   :log),
        # ("param3", :param3, 1.0,   1.999, :linear),
    ]
    n_params = length(search_params)

    # Starting points subset
    init_subset = [1, 3, 6, 8]

    # ── Early exit modes ─────────────────────────────────────────────────
    if do_summary
        _print_lhs_summary(db, tee, method_name, top_n)
        teardown_logging(tee, logpath)
        return
    end

    if do_export
        export_path = joinpath(JCODE_ROOT, "results", "lhs_export.csv")
        n = export_results_csv(db, export_path)
        println(tee, "Exported $n rows to: $export_path")
        teardown_logging(tee, logpath)
        return
    end

    # ══════════════════════════════════════════════════════════════════════
    # HELPERS
    # ══════════════════════════════════════════════════════════════════════

    function latin_hypercube(n_samples, n_params; seed=42)
        rng = Random.Xoshiro(seed)
        result = zeros(n_samples, n_params)
        for j in 1:n_params
            perm = randperm(rng, n_samples)
            for i in 1:n_samples
                result[i, j] = (perm[i] - 1 + rand(rng)) / n_samples
            end
        end
        return result
    end

    function sample_to_params(unit_sample, search_params)
        kw_pairs = Pair{Symbol,Any}[]
        for (idx, (_, sym, lo, hi, scale)) in enumerate(search_params)
            u = unit_sample[idx]
            val = scale == :log ?
                  exp(log(lo) + u * (log(hi) - log(lo))) :
                  lo + u * (hi - lo)
            push!(kw_pairs, sym => val)
        end
        return NamedTuple(kw_pairs)
    end

    function shifted_geomean(vals; shift=1.0)
        filtered = filter(isfinite, vals)
        isempty(filtered) && return NaN
        return exp(mean(log.(filtered .+ shift))) - shift
    end

    function evaluate_config(params, dims, config_hash)
        n_conv = 0; n_total = 0
        iters_list = Float64[]

        for dim in dims
            for prob_id in PROBLEM_IDS
                prob = get_problem(prob_id)
                prob_str = "P$prob_id"
                all_inits = get_initial_points(dim, prob_id)
                inits = all_inits[init_subset]

                for (init_label, x0) in inits
                    n_total += 1

                    if !do_force && is_done(db, config_hash, prob_str, dim, init_label)
                        r = DBInterface.execute(db,
                            "SELECT converged, iterations FROM results WHERE config_hash=? AND problem=? AND dimension=? AND init_point=?",
                            (config_hash, prob_str, dim, init_label)) |> DataFrame
                        if nrow(r) > 0 && r.converged[1] == 1
                            n_conv += 1
                            push!(iters_list, Float64(r.iterations[1]))
                        end
                        continue
                    end

                    result = try
                        # ── Adapt solver call ────────────────────────────
                        # solver_fn(prob.F, prob.proj, copy(x0);
                        #           params..., eps=const_eps, maxiter=const_maxiter)
                        make_result(converged=false, iterations=0, f_evals=0,
                                   cpu_time=0.0, x=copy(x0), flag=:not_implemented)
                    catch
                        make_result(converged=false, iterations=const_maxiter,
                                   f_evals=0, cpu_time=0.0, x=copy(x0), flag=:error)
                    end

                    insert_result!(db, config_hash, prob_str, dim, init_label, run_id, result)

                    if result.converged
                        n_conv += 1
                        push!(iters_list, Float64(result.iterations))
                    end
                end
            end
        end

        success_rate = n_total > 0 ? n_conv / n_total : 0.0
        gm_iter = shifted_geomean(iters_list)
        return (success_rate=success_rate, gm_iter=gm_iter, n_conv=n_conv, n_total=n_total)
    end

    # ══════════════════════════════════════════════════════════════════════
    # SEARCH
    # ══════════════════════════════════════════════════════════════════════

    println(tee, "\n--- LHS Parameter Search ---")
    println(tee, "  Samples: $n_samples")
    println(tee, "  Parameters: $n_params")
    println(tee, "  Tiers: $(length(tiers))")
    println(tee, "  Force: $do_force")
    println(tee, "  Quick: $do_quick")
    println(tee)

    if n_params == 0
        println(tee, "  NO PARAMETERS CONFIGURED — add entries to search_params")
        teardown_logging(tee, logpath)
        return
    end

    unit_samples = latin_hypercube(n_samples, n_params)

    for tier in tiers
        println(tee, "\n  === Tier: $(tier.name) (dims=$(tier.dims)) ===")

        for i in 1:n_samples
            params = sample_to_params(unit_samples[i, :], search_params)

            hash, hash_input = make_config_hash(
                "$(method_name)_LHS", method_version, params, const_eps, const_maxiter)
            ensure_config!(db, hash, "$(method_name)_LHS", method_version,
                          params, const_eps, const_maxiter, hash_input)

            stats = evaluate_config(params, tier.dims, hash)

            if i % 10 == 0 || i == n_samples
                @printf(tee, "    Sample %d/%d: success=%.1f%% gm_iter=%.1f [%s]\n",
                        i, n_samples, 100 * stats.success_rate, stats.gm_iter, hash)
            end
        end
    end

    # ── Summary ──────────────────────────────────────────────────────────
    _print_lhs_summary(db, tee, method_name, top_n)

    println(tee, "\n" * "=" ^ 70)
    teardown_logging(tee, logpath)
end

# ============================================================================
# Summary Helper
# ============================================================================

function _print_lhs_summary(db, tee, method_name, top_n)
    println(tee, "\n--- LHS Summary ---")

    configs_df = DBInterface.execute(db, """
        SELECT c.config_hash, c.params_json,
               COUNT(*) as n_total,
               SUM(r.converged) as n_conv,
               AVG(CASE WHEN r.converged=1 THEN r.iterations END) as avg_iter,
               AVG(CASE WHEN r.converged=1 THEN r.f_evals END) as avg_feval
        FROM results r
        JOIN configs c ON r.config_hash = c.config_hash
        WHERE c.method = ?
        GROUP BY c.config_hash
        ORDER BY CAST(n_conv AS REAL)/n_total DESC, avg_feval ASC
    """, ("$(method_name)_LHS",)) |> DataFrame

    if nrow(configs_df) == 0
        println(tee, "  No LHS results found.")
        return
    end

    println(tee, "  Total configs: $(nrow(configs_df))")
    n_show = min(top_n, nrow(configs_df))
    println(tee, "\n  Top $n_show configs:")
    @printf(tee, "  %3s  %-14s  %6s  %7s  %8s  %8s\n",
            "#", "Hash", "Total", "Succ%", "Avg_IT", "Avg_FE")
    println(tee, "  " * "-" ^ 55)

    for j in 1:n_show
        row = configs_df[j, :]
        succ = row.n_total > 0 ? 100.0 * row.n_conv / row.n_total : 0.0
        @printf(tee, "  %3d  %-14s  %6d  %6.1f%%  %8.1f  %8.1f\n",
                j, row.config_hash, row.n_total, succ,
                ismissing(row.avg_iter) ? NaN : row.avg_iter,
                ismissing(row.avg_feval) ? NaN : row.avg_feval)
        println(tee, "       Params: $(row.params_json)")
    end
end

main()
