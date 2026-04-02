# ============================================================================
# s01: Smoke Test — verify all solvers run on a simple problem
# ============================================================================
#
# Quick sanity check before long experiments. Tests:
#   Part 1: All solvers converge on a simple problem
#   Part 2: Config hash uniqueness (no collisions across solvers/params)
#
# Usage:  cd jcode && julia --project=. scripts/s01_smoke_test.jl
#
# Output: console + results/logs/smoke_test_<timestamp>.log
# ============================================================================

# --- Load project code (adapt to your coding style) ---
# Style A (Module):  push!(LOAD_PATH, joinpath(@__DIR__, "..", "src")); using {ModuleName}
# Style B (Flat):    include(joinpath(@__DIR__, "..", "src", "includes.jl"))
include(joinpath(@__DIR__, "..", "src", "includes.jl"))

function main()
    # ── Logging ──────────────────────────────────────────────────────────
    logpath, tee, logfile = setup_logging("smoke_test")

    println(tee, "=" ^ 70)
    println(tee, "  Smoke Test — $(Dates.now())")
    println(tee, "=" ^ 70)

    all_pass = true

    # ══════════════════════════════════════════════════════════════════════
    # PART 1: Solver convergence
    # ══════════════════════════════════════════════════════════════════════

    println(tee, "\n--- Part 1: Solver Convergence ---")

    # Setup: pick one easy problem at small dimension
    prob = get_problem(1)
    n = 100
    x0 = fill(0.5, n)        # adjust to a feasible starting point
    eps_test = 1e-9
    maxiter_test = 1000

    # Solvers to test: (name, function, version, defaults)
    # ── Adapt this list to your project's solvers ────────────────────────
    solvers = [
        # ("AlgoName",  solve_algo, ALGO_VERSION, ALGO_DEFAULTS),
    ]

    println(tee)
    @printf(tee, "  %-12s  %5s  %5s  %6s  %12s  %8s  %s\n",
            "Algorithm", "Conv", "Iter", "FEval", "Residual", "Time(s)", "Flag")
    println(tee, "  " * "-" ^ 65)

    for (name, solver_fn, version, defaults) in solvers
        try
            result = solver_fn(prob.F, prob.proj, copy(x0);
                               defaults..., eps=eps_test, maxiter=maxiter_test)

            @printf(tee, "  %-12s  %5s  %5d  %6d  %12.2e  %8.4f  %s\n",
                    name,
                    result.converged ? "  yes" : "   NO",
                    result.iterations,
                    result.f_evals,
                    norm(prob.F(result.x)),
                    result.cpu_time,
                    result.flag)

            if !result.converged
                all_pass = false
                println(tee, "    WARNING: $name did not converge!")
            end
        catch e
            all_pass = false
            msg = sprint(showerror, e, catch_backtrace())
            println(tee, "  %-12s  ERROR: $(first(msg, 120))")
        end
    end

    println(tee, "  " * "-" ^ 65)
    println(tee, isempty(solvers) ?
            "  NO SOLVERS CONFIGURED — add entries to the `solvers` list" :
            (all_pass ? "  ALL SOLVERS PASSED" : "  SOME SOLVERS FAILED"))

    # ══════════════════════════════════════════════════════════════════════
    # PART 2: Config hash uniqueness
    # ══════════════════════════════════════════════════════════════════════

    if !isempty(solvers)
        println(tee, "\n--- Part 2: Config Hash Uniqueness ---")

        # Cross-solver: all hashes must be distinct
        hashes = Dict{String,String}()
        hash_ok = true
        for (name, _, version, defaults) in solvers
            h, _ = make_config_hash(name, version, defaults, eps_test, maxiter_test)
            println(tee, "  $name v$version → $h")
            if haskey(hashes, h)
                println(tee, "  COLLISION: $name collides with $(hashes[h])!")
                hash_ok = false
                all_pass = false
            end
            hashes[h] = name
        end
        println(tee, "  Cross-solver: $(hash_ok ? "PASS ($(length(hashes)) distinct)" : "FAIL")")

        # Parameter sensitivity: perturbing one param must change the hash
        name, _, version, defaults = solvers[1]
        base_h, _ = make_config_hash(name, version, defaults, eps_test, maxiter_test)
        println(tee, "\n  Parameter sensitivity ($name):")
        param_ok = true
        for (k, v) in pairs(defaults)
            perturbed = merge(defaults, NamedTuple{(k,)}((v * 1.01,)))
            h2, _ = make_config_hash(name, version, perturbed, eps_test, maxiter_test)
            if h2 == base_h
                println(tee, "    $k: FAIL — hash unchanged!")
                param_ok = false
                all_pass = false
            end
        end
        println(tee, "  Param sensitivity: $(param_ok ? "PASS (all $(length(defaults)) params)" : "FAIL")")

        # Version sensitivity
        h_v2, _ = make_config_hash(name, "99.99.99", defaults, eps_test, maxiter_test)
        ver_ok = h_v2 != base_h
        println(tee, "  Version sensitivity: $(ver_ok ? "PASS" : "FAIL")")
        if !ver_ok; all_pass = false; end
    end

    # ══════════════════════════════════════════════════════════════════════
    # FINAL
    # ══════════════════════════════════════════════════════════════════════

    println(tee, "\n" * "=" ^ 70)
    println(tee, all_pass ? "  ALL CHECKS PASSED" : "  SOME CHECKS FAILED")
    println(tee, "=" ^ 70)

    teardown_logging(tee, logpath)
    return all_pass
end

main()
