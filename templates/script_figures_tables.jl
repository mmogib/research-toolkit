# ============================================================================
# s{NN}: Performance Profiles, Convergence Plots, LaTeX Tables
# ============================================================================
#
# Reads from experiments.db and generates publication-quality figures + tables.
#
# Usage:
#   julia --project=. scripts/s{NN}_figures_tables.jl --all           # everything
#   julia --project=. scripts/s{NN}_figures_tables.jl --profiles      # profiles only
#   julia --project=. scripts/s{NN}_figures_tables.jl --convergence   # convergence
#   julia --project=. scripts/s{NN}_figures_tables.jl --tables        # LaTeX tables
#   julia --project=. scripts/s{NN}_figures_tables.jl --tier=small    # specific tier
#
# Output: results/figures/{profiles,convergence}/  results/figures/tables/
# Log:    results/logs/figures_<timestamp>.log
# ============================================================================

# --- Load project code ---
# Style A: push!(LOAD_PATH, joinpath(@__DIR__, "..", "src")); using {ModuleName}
# Style B:
include(joinpath(@__DIR__, "..", "src", "includes.jl"))
using Plots, LaTeXStrings, BenchmarkProfiles, Colors

# ══════════════════════════════════════════════════════════════════════════════
# CONSTANTS — adapt to your project
# ══════════════════════════════════════════════════════════════════════════════

# Method display order (determines legend order and column order in tables)
const METHOD_ORDER = [
    # "YourAlgo",
    # "Baseline1",
    # "Baseline2",
]

# Consistent visual styling across all figures
const METHOD_COLORS = [
    RGB(0/255, 114/255, 178/255),     # blue
    RGB(230/255, 159/255, 0/255),     # orange
    RGB(0/255, 158/255, 115/255),     # green
    RGB(204/255, 121/255, 167/255),   # pink
    RGB(213/255, 94/255, 0/255),      # vermillion
]

const METHOD_WIDTHS = [2.5, 1.5, 1.5, 1.5, 1.5]  # your algo thicker
const METHOD_STYLES = [:solid, :solid, :solid, :solid, :solid]

# Dimension tiers
const TIERS = Dict(
    "small" => [1_000, 5_000, 10_000],
    "mid"   => [20_000, 50_000],
    "large" => [80_000, 100_000],
    "all"   => [1_000, 5_000, 10_000, 20_000, 50_000, 80_000, 100_000],
)

const PENALTY = 1e10  # value for failed solvers in profile matrix

# ══════════════════════════════════════════════════════════════════════════════
# DATA LOADING HELPERS
# ══════════════════════════════════════════════════════════════════════════════

function load_results(db, dims::Vector{Int})
    dim_list = join(dims, ",")
    method_list = join(["'$m'" for m in METHOD_ORDER], ",")
    sql = """
        SELECT c.method, r.problem, r.dimension, r.init_point,
               r.converged, r.iterations, r.f_evals, r.cpu_time
        FROM results r
        JOIN configs c ON r.config_hash = c.config_hash
        WHERE c.method IN ($method_list)
          AND r.dimension IN ($dim_list)
        ORDER BY r.problem, r.dimension, r.init_point, c.method
    """
    return DBInterface.execute(db, sql) |> DataFrame
end

function load_history(db, method::String, problem::String, dim::Int, init::String)
    sql = """
        SELECT h.k, h.f_evals, h.elapsed
        FROM history h
        JOIN configs c ON h.config_hash = c.config_hash
        WHERE c.method = ? AND h.problem = ? AND h.dimension = ? AND h.init_point = ?
        ORDER BY h.k
    """
    # ── Add project-specific columns to SELECT (e.g., h.norm_Fk) ────────
    return DBInterface.execute(db, sql, (method, problem, dim, init)) |> DataFrame
end

# ══════════════════════════════════════════════════════════════════════════════
# PERFORMANCE PROFILES
# ══════════════════════════════════════════════════════════════════════════════

"""
    build_profile_matrix(df, metric) -> Matrix{Float64}

Build T matrix for BenchmarkProfiles: n_instances × n_solvers.
Failed runs get PENALTY value.
"""
function build_profile_matrix(df, metric::Symbol)
    instances = unique(df[:, [:problem, :dimension, :init_point]])
    n_inst = nrow(instances)
    n_meth = length(METHOD_ORDER)
    T = fill(PENALTY, n_inst, n_meth)

    method_idx = Dict(m => i for (i, m) in enumerate(METHOD_ORDER))

    for (row_idx, inst) in enumerate(eachrow(instances))
        for r in eachrow(df)
            if r.problem == inst.problem && r.dimension == inst.dimension &&
               r.init_point == inst.init_point && haskey(method_idx, r.method)
                col = method_idx[r.method]
                if r.converged == 1
                    T[row_idx, col] = max(Float64(getproperty(r, metric)), 1e-10)
                end
            end
        end
    end

    return T
end

function plot_profile(T, metric_name::String, tier_name::String, outpath::String; tee=stdout)
    p = performance_profile(
        PlotsBackend(), T, METHOD_ORDER;
        logscale=true,
        title="Performance profile — $metric_name ($tier_name)",
        legend=:bottomright,
        linewidth=METHOD_WIDTHS[1:size(T, 2)],
        palette=METHOD_COLORS[1:size(T, 2)],
        linestyle=METHOD_STYLES[1:size(T, 2)],
        xlabel=L"\tau",
        ylabel=L"\rho_s(\tau)",
        size=(600, 400),
        dpi=300,
    )
    savefig(p, outpath)
    println(tee, "  Saved: $outpath ($(size(T,1)) instances)")
end

# ══════════════════════════════════════════════════════════════════════════════
# CONVERGENCE PLOTS
# ══════════════════════════════════════════════════════════════════════════════

function plot_convergence(db, problem::String, dim::Int, init::String,
                          outpath::String; tee=stdout)
    p = plot(;
        xlabel=L"k",
        ylabel=L"\|F(x_k)\|",  # ── adapt metric label ──
        yscale=:log10,
        title="$problem, m=$dim, $init",
        legend=:topright,
        size=(600, 400), dpi=300,
    )

    n_curves = 0
    for (i, method) in enumerate(METHOD_ORDER)
        df = load_history(db, method, problem, dim, init)
        nrow(df) == 0 && continue
        n_curves += 1
        # ── Adapt: use the project-specific metric column ────────────────
        # plot!(p, df.k, df.norm_Fk; ...)
        plot!(p, df.k, df.f_evals;   # placeholder — replace with metric
            label=method,
            color=METHOD_COLORS[i],
            linewidth=METHOD_WIDTHS[i],
            linestyle=METHOD_STYLES[i],
        )
    end

    savefig(p, outpath)
    println(tee, "  Saved: $outpath ($n_curves curves)")
end

# ══════════════════════════════════════════════════════════════════════════════
# LATEX TABLES
# ══════════════════════════════════════════════════════════════════════════════

"""
    generate_summary_table(db, dims, tier_name, outpath; tee=stdout)

LaTeX table: per (problem, dim), show NI/NF/CPU for each method. Best in bold.
"""
function generate_summary_table(db, dims::Vector{Int}, tier_name::String,
                                outpath::String; tee=stdout)
    df = load_results(db, dims)
    nrow(df) == 0 && (println(tee, "  No data for $tier_name"); return)

    # Aggregate: mean over init points
    agg = combine(groupby(df, [:method, :problem, :dimension]),
        :converged => (x -> sum(x .== 1)) => :n_conv,
        :converged => length => :n_total,
        :iterations => (x -> round(mean(x), digits=1)) => :avg_iter,
        :f_evals    => (x -> round(mean(x), digits=1)) => :avg_feval,
        :cpu_time   => (x -> round(mean(x), digits=4)) => :avg_cpu,
    )

    n_meth = length(METHOD_ORDER)

    open(outpath, "w") do io
        println(io, "% Auto-generated — $tier_name tier")
        println(io, "\\begin{table}[!ht]")
        println(io, "\\centering\\scriptsize")
        println(io, "\\setlength{\\tabcolsep}{3pt}")
        println(io, "\\resizebox{\\textwidth}{!}{")

        col_spec = "c|" * join(["ccc" for _ in 1:n_meth], "|")
        println(io, "\\begin{tabular}{$col_spec}")
        println(io, "\\hline")

        # Method headers
        hdrs = join([" & \\multicolumn{3}{c" * (i < n_meth ? "|" : "") *
                     "}{$m}" for (i, m) in enumerate(METHOD_ORDER)])
        println(io, " $hdrs \\\\")
        println(io, "\\hline")

        sub = join([" & NI & NF & CPU" for _ in 1:n_meth])
        println(io, " $sub \\\\")
        println(io, "\\hline")

        problems = sort(unique(df.problem))
        for prob in problems
            for dim in dims
                row_parts = ["$prob"]
                # Find best for bolding
                best = Dict(:it => Inf, :fe => Inf, :cpu => Inf)
                for m in METHOD_ORDER
                    s = filter(r -> r.method == m && r.problem == prob && r.dimension == dim, agg)
                    if nrow(s) > 0 && s.n_conv[1] > 0
                        best[:it]  = min(best[:it],  s.avg_iter[1])
                        best[:fe]  = min(best[:fe],  s.avg_feval[1])
                        best[:cpu] = min(best[:cpu], s.avg_cpu[1])
                    end
                end

                for m in METHOD_ORDER
                    s = filter(r -> r.method == m && r.problem == prob && r.dimension == dim, agg)
                    if nrow(s) > 0 && s.n_conv[1] > 0
                        it, fe, cp = s.avg_iter[1], s.avg_feval[1], s.avg_cpu[1]
                        it_s = it ≈ best[:it] ? "\\textbf{$it}" : "$it"
                        fe_s = fe ≈ best[:fe] ? "\\textbf{$fe}" : "$fe"
                        cp_s = cp ≈ best[:cpu] ? "\\textbf{$cp}" : "$cp"
                        push!(row_parts, "$it_s & $fe_s & $cp_s")
                    else
                        push!(row_parts, "--- & --- & ---")
                    end
                end
                println(io, join(row_parts, " & ") * " \\\\")
            end
        end

        println(io, "\\hline")
        println(io, "\\end{tabular}}")
        println(io, "\\caption{Comparison — $tier_name tier. Best values in bold.}")
        println(io, "\\end{table}")
    end
    println(tee, "  Saved: $outpath")
end

"""
    generate_overall_summary(db, outpath; tee=stdout)

Single-row-per-method summary table.
"""
function generate_overall_summary(db, outpath::String; tee=stdout)
    open(outpath, "w") do io
        println(io, "% Auto-generated — Overall summary")
        println(io, "\\begin{table}[!ht]")
        println(io, "\\centering")
        println(io, "\\begin{tabular}{lrrrrr}")
        println(io, "\\toprule")
        println(io, "Method & Total & Converged & Rate (\\%) & Med.\\ Iter & Med.\\ FEval \\\\")
        println(io, "\\midrule")

        for m in METHOD_ORDER
            df = DBInterface.execute(db, """
                SELECT r.converged, r.iterations, r.f_evals
                FROM results r JOIN configs c ON r.config_hash = c.config_hash
                WHERE c.method = ?
            """, (m,)) |> DataFrame
            nrow(df) == 0 && continue
            conv = filter(r -> r.converged == 1, df)
            n_t = nrow(df); n_c = nrow(conv)
            rate = round(100 * n_c / n_t, digits=1)
            med_it = n_c > 0 ? Int(round(median(conv.iterations))) : "---"
            med_fe = n_c > 0 ? Int(round(median(conv.f_evals))) : "---"
            println(io, "$m & $n_t & $n_c & $rate & $med_it & $med_fe \\\\")
        end

        println(io, "\\bottomrule")
        println(io, "\\end{tabular}")
        println(io, "\\caption{Overall comparison across all problems and dimensions.}")
        println(io, "\\end{table}")
    end
    println(tee, "  Saved: $outpath")
end

# ══════════════════════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════════════════════

function main()
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

    do_all    = "all" in flags || isempty(flags)
    do_prof   = do_all || "profiles" in flags
    do_conv   = do_all || "convergence" in flags
    do_tables = do_all || "tables" in flags
    sel_tier  = get(kv, "tier", nothing)

    logpath, tee, logfile = setup_logging("figures")
    db = open_db()

    println(tee, "=" ^ 70)
    println(tee, "  Figures & Tables — $(Dates.now())")
    println(tee, "=" ^ 70)

    if isempty(METHOD_ORDER)
        println(tee, "NO METHODS CONFIGURED — add entries to METHOD_ORDER")
        teardown_logging(tee, logpath)
        return
    end

    # Output dirs
    fig_dir  = joinpath(JCODE_ROOT, "results", "figures")
    prof_dir = joinpath(fig_dir, "profiles")
    conv_dir = joinpath(fig_dir, "convergence")
    tab_dir  = joinpath(fig_dir, "tables")
    mkpath(prof_dir); mkpath(conv_dir); mkpath(tab_dir)

    tier_names = sel_tier !== nothing ? [sel_tier] : collect(keys(TIERS))

    # ── Performance Profiles ─────────────────────────────────────────────
    if do_prof
        println(tee, "\n--- Performance Profiles ---")
        for tier in tier_names
            haskey(TIERS, tier) || continue
            dims = TIERS[tier]
            df = load_results(db, dims)
            nrow(df) == 0 && (println(tee, "  $tier: no data"); continue)

            for (metric, label) in [
                (:iterations, "Iterations"),
                (:f_evals, "Function evaluations"),
                (:cpu_time, "CPU time"),
            ]
                T = build_profile_matrix(df, metric)
                outpath = joinpath(prof_dir, "profile_$(metric)_$(tier).pdf")
                plot_profile(T, label, tier, outpath; tee=tee)
            end
        end
    end

    # ── Convergence Plots ────────────────────────────────────────────────
    if do_conv
        println(tee, "\n--- Convergence Plots ---")
        hist_combos = DBInterface.execute(db, """
            SELECT DISTINCT h.problem, h.dimension, h.init_point
            FROM history h ORDER BY h.problem, h.dimension, h.init_point
        """) |> DataFrame

        if nrow(hist_combos) == 0
            println(tee, "  No history data found")
        else
            println(tee, "  Found $(nrow(hist_combos)) tracked combos")
            for row in eachrow(hist_combos)
                outpath = joinpath(conv_dir,
                    "conv_$(row.problem)_$(row.dimension)_$(row.init_point).pdf")
                plot_convergence(db, String(row.problem), row.dimension,
                               String(row.init_point), outpath; tee=tee)
            end
        end
    end

    # ── LaTeX Tables ─────────────────────────────────────────────────────
    if do_tables
        println(tee, "\n--- LaTeX Tables ---")
        for tier in filter(t -> t != "all", tier_names)
            haskey(TIERS, tier) || continue
            outpath = joinpath(tab_dir, "table_$(tier).tex")
            generate_summary_table(db, TIERS[tier], tier, outpath; tee=tee)
        end

        outpath = joinpath(tab_dir, "table_summary.tex")
        generate_overall_summary(db, outpath; tee=tee)
    end

    println(tee, "\n" * "=" ^ 70)
    println(tee, "  Output: $fig_dir")
    teardown_logging(tee, logpath)
end

main()
