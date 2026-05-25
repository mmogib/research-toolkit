#!/usr/bin/env julia
# s30_benchmark.jl — Ibrahim 2026 Experiment 4.1 sweep (DFMethods v0.3.0)
#
# Primary sweep driver: (line search × problem × dimension × initial point).
# Shared helpers (palette resolution, alg construction, solve loop with
# serial+threaded dispatch) live in `src/sweep_helpers.jl`; this script
# handles CLI parsing, problem selection, workload construction, and the
# script-specific workload-banner formatting.
#
# Policy notes:
#   1. **No per-iteration history.** Summary rows only. Per-iter tracking
#      requires wiring a HistoryCallback() and calling insert_history!.
#   2. **Fixed-n problems (p3/p4/p5) ignore --dims.** prob.fixed_n wins; the
#      DB's `dimension` column separates them naturally.
#   3. **One config_hash per LS.** Algorithm params + ε + maxiter + julia/
#      dfmethods version all in the hash. --time-limit also enters the hash
#      WHEN SET (omitted otherwise → backwards-compat with pre-T.5c hashes).
#
# CLI flags:
#   --ls=LSI,LSII,...         (default: all 7)               Subset of LSI..LSVII
#   --dims=15000,50000,150000 (default: paper)               Dims for variable-n
#   --problems=1-10,p15,DiscreteBV (default: 1-28)           Mixed grammar
#   --eps=1e-6  --maxiter=2000                               Stopping tolerance / cap
#   --rho=0.6 --sigma=0.01 --theta=0.25 --zeta=0.5           Paper algorithm params
#   --r=0.1                                                   SpectralThreeTerm direction
#   --time-limit=SECONDS      (default: none)                Wall-clock cap per solve; adds MaxTime to stopping criterion. Joins config_hash when set.
#   --threads=N               (default: 1, serial)           Threaded via Channel + Threads.@spawn workers + 1 writer task. Launch Julia with `-t (N+1)`.
#   --force                                                   Override resume
#   --display=silent|progress|table  (default: progress)    --verbose aliases :table
#   --verbose                                                Alias for --display=table
#   --summary                                                Print aggregate stats + exit
#   --export[=path]                                          Dump DB→CSV + exit
#
# Examples:
#   julia --project=. scripts/s30_benchmark.jl --ls=LSI,LSII,LSVII --dims=1000
#   julia -t 9 --project=. scripts/s30_benchmark.jl --threads=8
#   julia --project=. scripts/s30_benchmark.jl --summary

include(joinpath(@__DIR__, "..", "src", "includes.jl"))
using DFMethods

# ============================================================================
# CLI parsing (script-specific)
# ============================================================================

function parse_cli(args)
    cli = Dict{Symbol,Any}(
        :ls          => copy(LS_IMPLEMENTED),
        :dims        => [15_000, 50_000, 150_000],
        :problems    => collect(1:length(PROBLEM_ORDER)),
        :eps         => 1e-6,
        :maxiter     => 2000,
        :rho         => 0.6,
        :sigma       => 0.01,
        :theta       => 0.25,
        :zeta        => 0.5,
        :r           => 0.1,
        :time_limit  => nothing,         # Float64 seconds when set; omitted from hash when nothing
        :threads     => 1,
        :force       => false,
        :display     => :progress,
        :summary     => false,
        :do_export   => false,
        :export_path => joinpath(BENCHROOT, "results", "export.csv"),
    )
    for a in args
        if     a == "--force";   cli[:force]     = true
        elseif a == "--verbose"; cli[:display]   = :table
        elseif a == "--summary"; cli[:summary]   = true
        elseif a == "--export";  cli[:do_export] = true
        elseif startswith(a, "--export=");      cli[:do_export]    = true
                                                 cli[:export_path]  = String(a[length("--export=")+1:end])
        elseif startswith(a, "--display=");     cli[:display]      = _parse_display(a[length("--display=")+1:end])
        elseif startswith(a, "--ls=");          cli[:ls]           = _parse_ls_list(a[length("--ls=")+1:end])
        elseif startswith(a, "--dims=");        cli[:dims]         = _parse_int_list(a[length("--dims=")+1:end])
        elseif startswith(a, "--problems=");    cli[:problems]     = _parse_problem_list(a[length("--problems=")+1:end])
        elseif startswith(a, "--eps=");         cli[:eps]          = parse(Float64, a[length("--eps=")+1:end])
        elseif startswith(a, "--maxiter=");     cli[:maxiter]      = parse(Int,     a[length("--maxiter=")+1:end])
        elseif startswith(a, "--rho=");         cli[:rho]          = parse(Float64, a[length("--rho=")+1:end])
        elseif startswith(a, "--sigma=");       cli[:sigma]        = parse(Float64, a[length("--sigma=")+1:end])
        elseif startswith(a, "--theta=");       cli[:theta]        = parse(Float64, a[length("--theta=")+1:end])
        elseif startswith(a, "--zeta=");        cli[:zeta]         = parse(Float64, a[length("--zeta=")+1:end])
        elseif startswith(a, "--r=");           cli[:r]            = parse(Float64, a[length("--r=")+1:end])
        elseif startswith(a, "--time-limit=");  cli[:time_limit]   = parse(Float64, a[length("--time-limit=")+1:end])
        elseif startswith(a, "--threads=");     cli[:threads]      = parse(Int,     a[length("--threads=")+1:end])
        else
            error("Unknown CLI flag: '$a'. See script header for usage.")
        end
    end
    return cli
end

# ============================================================================
# Worklist construction (script-specific)
# ============================================================================
# s30's worklist = palette × selected_problems × dims × inits, with
# prob.fixed_n overriding cli[:dims] for p3/p4/p5.

function build_worklist(palette, selected_problems, cli)
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
# Workload banner (script-specific format)
# ============================================================================

function print_workload_banner(tee, palette, worklist, selected_problems, cli, existing)
    n_total      = length(worklist)
    n_skip       = count(w -> (w.config_hash, w.prob_name, w.n, w.init_name) in existing, worklist)
    n_todo       = n_total - n_skip
    n_variable_n = count(p -> p.fixed_n === nothing, selected_problems)
    n_fixed_n    = count(p -> p.fixed_n !== nothing, selected_problems)

    println(tee, "-" ^ 76)
    println(tee, "Workload:")
    println(tee, "  LS:        ", join(cli[:ls], ", "), "  (", length(cli[:ls]), ")")
    println(tee, "  Problems:  ", length(selected_problems),
                  " (", n_variable_n, " variable-n + ", n_fixed_n, " fixed-n)")
    if n_fixed_n > 0
        for p in selected_problems
            if p.fixed_n !== nothing
                println(tee, "             ", rpad("p$(p.id) $(p.name):", 32), " n=$(p.fixed_n) (fixed)")
            end
        end
    end
    println(tee, "  Dims:      ", cli[:dims], " (for variable-n problems)")
    println(tee, "  Inits:     4 per problem")
    println(tee, "  ε / max:   ", cli[:eps], " / ", cli[:maxiter])
    println(tee, "  Params:    ρ=$(cli[:rho]) σ=$(cli[:sigma]) θ=$(cli[:theta]) ζ=$(cli[:zeta]) r=$(cli[:r])")
    if cli[:time_limit] !== nothing
        println(tee, "  Time cap:  ", cli[:time_limit], " s per solve (MaxTime in stopping rule)")
    end
    println(tee, "  Total:     ", n_total)
    println(tee, "  In DB:     ", n_skip, cli[:force] ? "  (will be overwritten via --force)" : "  (will be skipped)")
    println(tee, "  To solve:  ", n_todo)
    println(tee, "-" ^ 76)
    println(tee, "Configs registered (config_hash → method):")
    for p in palette
        println(tee, "  ", p.config_hash, "  ", "DFProjection_$(p.label)")
    end
    println(tee, "-" ^ 76)

    return n_total, n_todo
end

# ============================================================================
# Main
# ============================================================================

function main()
    cli = parse_cli(ARGS)
    threads_warn(cli)

    (logpath, tee, logfile) = setup_logging("s30_benchmark")
    println(tee, "=" ^ 76)
    println(tee, "s30_benchmark — Ibrahim 2026 Experiment 4.1 sweep (DFMethods v0.3.0)")
    println(tee, "=" ^ 76)

    db = open_db()
    println(tee, "DB:          ", DB_PATH)

    # ── Early-exit modes ─────────────────────────────────────────────────
    if cli[:summary]
        df_methods = DBInterface.execute(db, "SELECT DISTINCT method FROM configs ORDER BY method") |> DataFrame
        if nrow(df_methods) == 0
            println(tee, "(no configs registered yet — run a sweep first)")
        else
            method_list = String.(df_methods.method)
            print_summary(db, tee, method_list)
        end
        teardown_logging(tee, logpath)
        return
    end
    if cli[:do_export]
        mkpath(dirname(cli[:export_path]))
        n = export_results_csv(db, cli[:export_path])
        println(tee, "Exported $n rows → $(cli[:export_path])")
        teardown_logging(tee, logpath)
        return
    end

    # ── Palette + worklist ────────────────────────────────────────────────
    selected_problems = [get_problem(id) for id in cli[:problems]]
    palette  = register_palette(db, cli)
    worklist = build_worklist(palette, selected_problems, cli)

    # PK uniqueness (defensive — catches fixed-n / dims interaction bugs)
    pks = [(w.config_hash, w.prob_name, w.n, w.init_name) for w in worklist]
    @assert allunique(pks) "Work-list contains duplicate (config_hash, problem, dim, init) keys"

    existing = existing_set(db, worklist, cli[:force])
    n_total, n_todo = print_workload_banner(tee, palette, worklist,
                                              selected_problems, cli, existing)

    if n_todo == 0
        println(tee, "Nothing to solve. Use --force to re-run, --summary for stats.")
        teardown_logging(tee, logpath)
        return
    end

    println(tee, "Display mode: ", cli[:display])
    if cli[:threads] >= 2
        println(tee, "Threading:    $(cli[:threads]) worker tasks + 1 writer task (julia -t $(Threads.nthreads()))")
    end
    println(tee, "Solving…")

    run_sweep(db, palette, worklist, cli, tee, n_total, existing)

    # ── Final aggregate summary (explicit method ordering) ───────────────
    method_order = ["DFProjection_$(p.label)" for p in palette]
    print_summary(db, tee, method_order)

    teardown_logging(tee, logpath)
end

main()
