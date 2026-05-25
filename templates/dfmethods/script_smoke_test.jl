#!/usr/bin/env julia
# s01_bootstrap.jl — Smoke test for the DFMethods v0.3.0 API.
#
# Goal: prove the end-to-end workflow on the existing DFMethods-starter
# infrastructure with a SINGLE solver call:
#   problem  →  solve_with_alg  →  SolverResult  →  SQLite row  →  printed summary.
#
# Scope:
#   - 1 problem (PROBLEM_IDS[1] = placeholder; replaced by Ibrahim 2026's
#     28 problems in T.2)
#   - n = 100
#   - 1 initial point (first from get_initial_points)
#   - default DFProjection() (no component overrides)
#
# Run:
#   cd DFMethods-starter/
#   julia --project=. scripts/s01_bootstrap.jl
#   julia --project=. scripts/s01_bootstrap.jl --verbose
#   julia --project=. scripts/s01_bootstrap.jl --force      # re-run if already in DB

include(joinpath(@__DIR__, "..", "src", "includes.jl"))
using DFMethods

function main()
    # ── 1. CLI flags ─────────────────────────────────────────────────────
    verbose = "--verbose" in ARGS
    force   = "--force"   in ARGS

    # ── 2. Logging ───────────────────────────────────────────────────────
    (logpath, tee, logfile) = setup_logging("s01_bootstrap")

    println(tee, "=" ^ 72)
    println(tee, "s01_bootstrap — DFMethods v0.3.0 API smoke test")
    println(tee, "=" ^ 72)

    # ── 3. Open DB ───────────────────────────────────────────────────────
    db = open_db()
    println(tee, "DB:         ", DB_PATH)

    # ── 4. Algorithm + config ────────────────────────────────────────────
    alg     = DFProjection()
    eps     = 1e-6
    maxiter = 2000
    params  = (
        direction      = "SpectralThreeTerm",
        linesearch     = "ResidualNormBacktrack",
        iterate_update = "SolodovSvaiterProjection",
        inertial       = "Inertial(0.25)",
        zeta           = 0.5,
    )

    method  = "DFProjection_default"
    version = "0.3.0"

    (hash, hash_input) = make_config_hash(method, version, params, eps, maxiter)
    ensure_config!(db, hash, method, version, params, eps, maxiter, hash_input)

    println(tee, "method:     ", method)
    println(tee, "version:    v", version)
    println(tee, "config_h:   ", hash)
    println(tee, "eps:        ", eps)
    println(tee, "maxiter:    ", maxiter)

    # ── 5. Problem + initial point ───────────────────────────────────────
    n         = 100
    prob      = get_problem(first(PROBLEM_IDS))   # :ExponentialI (Ibrahim 2026 p1)
    prob_name = String(prob.name)                  # Symbol → String for DB
    set       = prob.set_factory(n)
    inits     = get_initial_points(n, prob.id)
    (init_name, x0) = first(inits)

    println(tee, "-" ^ 72)
    println(tee, "problem:    ", prob.label, "  (", prob_name, ")")
    println(tee, "source:     ", first(prob.sources))
    println(tee, "set:        ", typeof(set))
    println(tee, "dim:        ", n)
    println(tee, "init:       ", init_name, "   ‖x0‖=", round(norm(x0); digits = 4))

    # ── 6. Resume guard ──────────────────────────────────────────────────
    if is_done(db, hash, prob_name, n, init_name) && !force
        println(tee, ">> already in DB. Re-run with --force to override.")
        teardown_logging(tee, logpath)
        return
    end

    # ── 7. Solve ─────────────────────────────────────────────────────────
    println(tee, "-" ^ 72)
    println(tee, "Solving…")
    run_id = Dates.format(now(), "yyyymmdd_HHMMSS")   # timestamp = solve start
    result = solve_with_alg(prob.F, set, x0, alg;
                            eps     = eps,
                            maxiter = maxiter)

    # ── 8. Persist ───────────────────────────────────────────────────────
    insert_result!(db, hash, prob_name, n, init_name, run_id, result)

    # ── 9. Summary ───────────────────────────────────────────────────────
    println(tee, "-" ^ 72)
    println(tee, "Result:")
    println(tee, "  converged:   ", result.converged)
    println(tee, "  flag:        ", result.flag)
    println(tee, "  iterations:  ", result.iterations)
    println(tee, "  f_evals:     ", result.f_evals)
    println(tee, "  cpu_time:    ", round(result.cpu_time; digits = 4), " s")
    println(tee, "  ‖x*‖:        ", round(norm(result.x);            digits = 8))
    println(tee, "  ‖F(x*)‖:     ", round(norm(prob.F(result.x));    digits = 12))

    if verbose
        println(tee, "-" ^ 72)
        println(tee, "Run ID:     ", run_id)
        println(tee, "Hash input: ", hash_input)
    end

    println(tee, "=" ^ 72)
    println(tee, "✓ Smoke test complete. Row inserted at config_hash=", hash, ".")

    teardown_logging(tee, logpath)
end

main()
