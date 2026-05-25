#!/usr/bin/env julia
# s70_figures.jl — Dolan-Moré performance profiles for Ibrahim 2026 Figs 1/2/3.
#
# Reads from results/experiments.db (populated by s30_benchmark.jl through T.5b)
# and produces three performance profile figures:
#   Fig 1: cost = iterations  (results.iterations)
#   Fig 2: cost = F-evaluations (results.f_evals)
#   Fig 3: cost = CPU time (s)  (results.cpu_time)
#
# Policy (paper-faithful reproduction of Ibrahim 2026 Figs 1/2/3):
#   - **Paper-dim subset only.** SQL filter `WHERE dimension != 1000` drops
#     the n=1000 validation rows.
#   - **Fixed-n problems triple-counted.** Paper's outer loop is
#     `for n in [15k, 50k, 150k]` calling `paper_problems(n)` which returns
#     the fixed-dim variant of p3/p4/p5 regardless of `n`. The reference
#     does NOT deduplicate — p3/p4/p5 contribute 4 inits × 3 sweep-dim
#     slots = 12 rows each (identical values across the 3 slots, but
#     three logical entries in the cost matrix). Total entries per LS:
#     28 × 3 × 4 = 336.
#   - **Failed solves → Inf.** Dolan-Moré convention: a failed solver gets
#     no credit at any τ. We treat both `converged=0` AND missing rows as
#     Inf entries in the cost matrix. (Reference uses NaN; equivalent to
#     BenchmarkProfiles which treats both identically.)
#   - **Methods**: DFProjection_LSI..LSVII (7 columns).
#   - **Aesthetics match paper**: log2 x-axis labeled "Performance ratio"
#     with integer tick labels (the exponents themselves — paper convention
#     per text page 15: "x-ticks at 2⁰…2¹¹ but written as 0…11"); y-axis
#     0..1 ("Solved problems (%)" by paper's convention, fractional values);
#     per-LS distinct color + marker + linestyle drawn via
#     `performance_profile_data` + manual `plot!` loop (BenchmarkProfiles'
#     `performance_profile` only honors `linestyles` as per-series; all
#     other per-series kwargs get collapsed to scalars).
#   - **Figure numbering** matches paper text (page 15-16): Fig 1 = f-evals,
#     Fig 2 = iterations, Fig 3 = CPU time.
#
# CLI:
#   --metrics=iters,fevals,cpu  (default: all 3)    Subset of figures to build
#   --ext=png,pdf               (default: both)     Output formats
#   --tau-max=N                 (default: data-driven)   Override x-axis upper bound in LOG2 SPACE (i.e. the displayed exponent)
#   --dry-run                                       List what would be written, exit
#   --verbose                                       Per-metric matrix stats

include(joinpath(@__DIR__, "..", "src", "includes.jl"))
using DFMethods
using BenchmarkProfiles
using Plots

const METRICS         = (:iters, :fevals, :cpu)
const METRIC_LABELS   = Dict(:iters => "Iterations",
                              :fevals => "Function evaluations",
                              :cpu    => "CPU time (s)")
const METRIC_COLUMNS  = Dict(:iters => :iterations,
                              :fevals => :f_evals,
                              :cpu    => :cpu_time)
# Paper-text figure numbering (page 15-16): Fig 1 = f-evals, Fig 2 = iters, Fig 3 = CPU
const METRIC_FILES    = Dict(:fevals => "fig1_fevals",
                              :iters  => "fig2_iters",
                              :cpu    => "fig3_cpu")

const LS_ORDER        = ["LSI", "LSII", "LSIII", "LSIV", "LSV", "LSVI", "LSVII"]
const METHOD_ORDER    = ["DFProjection_$(ls)" for ls in LS_ORDER]

# Paper-style per-LS legend labels (with spaces, matching paper Figs 1/2/3)
const LS_LEGEND       = ["LS I", "LS II", "LS III", "LS IV", "LS V", "LS VI", "LS VII"]

# Paper-style per-LS visual encoding (matches the paper image's palette):
#   LS I   = red,      circle marker,  dashed
#   LS II  = green,    square,         dashed
#   LS III = black,    diamond,        dash-dot
#   LS IV  = cyan,     ▲ (utriangle),  dotted
#   LS V   = magenta,  ▼ (dtriangle),  solid
#   LS VI  = gold,     ▶ (rtriangle),  dotted   (gold > pure yellow for visibility on white)
#   LS VII = blue,     ◀ (ltriangle),  solid
# Vectors of length 7 indexed by series via [s] inside the manual plot
# loop. (Per-series styling via `linecolor=[…]` matrix in BenchmarkProfiles'
# `performance_profile(...)` does NOT work — the library's PlotsBackend
# loop in `requires.jl` only honors `linestyles=[…]` per-series and
# forwards everything else as a scalar. To get per-series markers we MUST
# roll our own via `performance_profile_data` + a `plot!` loop.)
const LS_COLORS    = [:red, :green, :black, :cyan, :magenta, :gold, :blue]
const LS_MARKERS   = [:circle, :rect, :diamond, :utriangle, :dtriangle, :rtriangle, :ltriangle]
const LS_LINESTYLE = [:dash, :dash, :dashdot, :dot, :solid, :dot, :solid]

# Paper sweep-dim outer loop — fixed-n problems are triple-counted across these.
const PAPER_VARIABLE_DIMS = (15_000, 50_000, 150_000)

# ============================================================================
# CLI
# ============================================================================

function parse_cli(args)
    cli = Dict{Symbol,Any}(
        :metrics => collect(METRICS),
        :ext     => ["png", "pdf"],
        :tau_max => nothing,    # default: data-driven max (paper/reference convention); user override is in log2-space (i.e. the displayed exponent)
        :dry_run => false,
        :verbose => false,
    )
    for a in args
        if     a == "--dry-run";   cli[:dry_run] = true
        elseif a == "--verbose";   cli[:verbose] = true
        elseif startswith(a, "--metrics=");  cli[:metrics] = _parse_metrics(a[length("--metrics=")+1:end])
        elseif startswith(a, "--ext=");      cli[:ext]     = _parse_exts(a[length("--ext=")+1:end])
        elseif startswith(a, "--tau-max=");  cli[:tau_max] = parse(Float64, a[length("--tau-max=")+1:end])
        else
            error("Unknown CLI flag: '$a'. See script header for usage.")
        end
    end
    return cli
end

function _parse_metrics(s::AbstractString)
    out = Symbol[]
    for raw in split(s, ",")
        t = Symbol(strip(raw))
        t in METRICS || error("Unknown metric '$t'. Available: " * join(string.(METRICS), ", "))
        push!(out, t)
    end
    isempty(out) && error("--metrics received no valid tokens")
    return out
end

function _parse_exts(s::AbstractString)
    allowed = ("png", "pdf", "svg")
    out = String[]
    for raw in split(s, ",")
        t = strip(String(raw))
        t in allowed || error("Unknown extension '$t'. Allowed: " * join(allowed, ", "))
        push!(out, t)
    end
    isempty(out) && error("--ext received no valid tokens")
    return out
end

# ============================================================================
# Data extraction: paper-dim cost matrix
# ============================================================================
#
# Returns a (n_entries × 7) Matrix{Float64} where n_entries = 28 × 3 × 4 = 336
# per the paper's enumeration:
#   for sweep_dim in (15_000, 50_000, 150_000):
#       for problem in PROBLEM_ORDER:                  # all 28
#           for init in problem.init_names:            # 4
#               lookup_dim = problem.fixed_n ?? sweep_dim
#               cost = solve(...) value or Inf if failed
#
# Note: fixed-n problems (p3/p4/p5) get triple-counted (3 identical rows
# per init across the sweep slots) — matches the paper's outer-loop
# convention. Variable-n problems get one row per sweep dim naturally.
#
# Inf is used for failures (converged=0) AND for any (entry, method) cell
# missing from the DB (defensive: ensures no silent zero entries).

function fetch_paper_dim_matrix(db, metric_col::Symbol; verbose::Bool = false)
    placeholders = join(fill("?", length(METHOD_ORDER)), ",")
    sql = """
        SELECT c.method, r.problem, r.dimension, r.init_point,
               r.converged, r.$(metric_col) AS metric
        FROM results r
        JOIN configs c ON r.config_hash = c.config_hash
        WHERE r.dimension != 1000
          AND c.method IN ($placeholders)
    """
    df = DBInterface.execute(db, sql, Tuple(METHOD_ORDER)) |> DataFrame

    # Pre-index df for O(1) lookup keyed by (problem, dim, init, method)
    row_idx = Dict{Tuple{String,Int,String,String}, Tuple{Int,Float64}}()
    for row in eachrow(df)
        k = (String(row.problem), Int(row.dimension),
             String(row.init_point), String(row.method))
        conv = row.converged isa Number ? Int(row.converged) : 0
        m    = row.metric === missing ? NaN : Float64(row.metric)
        row_idx[k] = (conv, m)
    end

    # Build paper-faithful entry list using PROBLEM_REGISTRY as canonical
    # source. Each (sweep_dim, problem, init) triple = one row in M.
    # Fixed-n problems use prob.fixed_n for DB lookup; variable-n use sweep_dim.
    keys_list = NTuple{4, Any}[]   # (problem_name, lookup_dim, init_name, sweep_dim)
    for sweep_dim in PAPER_VARIABLE_DIMS
        for prob_sym in PROBLEM_ORDER
            prob_obj   = PROBLEM_REGISTRY[prob_sym]
            prob_name  = String(prob_sym)
            lookup_dim = prob_obj.fixed_n === nothing ? sweep_dim : prob_obj.fixed_n
            for init_sym in prob_obj.init_names
                push!(keys_list, (prob_name, lookup_dim, String(init_sym), sweep_dim))
            end
        end
    end

    n_entries = length(keys_list)
    n_methods = length(METHOD_ORDER)
    M = fill(Inf, n_entries, n_methods)

    n_filled  = 0
    n_failed  = 0
    n_missing = 0
    for (i, (prob, lookup_dim, init, _sweep)) in enumerate(keys_list)
        for (j, method) in enumerate(METHOD_ORDER)
            entry = get(row_idx, (prob, lookup_dim, init, method), nothing)
            if entry === nothing
                n_missing += 1
            elseif entry[1] == 1
                M[i, j] = entry[2]
                n_filled += 1
            else
                n_failed += 1
            end
        end
    end

    if verbose
        total_cells = n_entries * n_methods
        @printf("  matrix:    %d entries × %d methods = %d cells\n",
                n_entries, n_methods, total_cells)
        @printf("  finite:    %d  (%.1f%%)\n", n_filled, 100 * n_filled / total_cells)
        @printf("  failed:    %d  (%.1f%%) — converged=0 in DB\n",
                n_failed, 100 * n_failed / total_cells)
        @printf("  missing:   %d  (%.1f%%) — no DB row at all (Inf by default)\n",
                n_missing, 100 * n_missing / total_cells)
    end

    return M, keys_list
end

# ============================================================================
# Main
# ============================================================================

function main()
    cli = parse_cli(ARGS)

    (logpath, tee, logfile) = setup_logging("s70_figures")
    println(tee, "=" ^ 76)
    println(tee, "s70_figures — Dolan-Moré performance profiles (Ibrahim 2026 Figs 1/2/3)")
    println(tee, "=" ^ 76)

    db = open_db()
    out_dir = joinpath(BENCHROOT, "results", "figures")
    mkpath(out_dir)

    println(tee, "DB:         ", DB_PATH)
    println(tee, "Output dir: ", out_dir)
    println(tee, "Methods:    ", join(METHOD_ORDER, ", "))
    println(tee, "Metrics:    ", join(string.(cli[:metrics]), ", "))
    println(tee, "Extensions: ", join(cli[:ext], ", "))
    println(tee, "τ_max:      ", cli[:tau_max])
    if cli[:dry_run]
        println(tee, ">> DRY RUN — no figures will be written")
    end
    println(tee, "-" ^ 76)

    for metric in cli[:metrics]
        col      = METRIC_COLUMNS[metric]
        label    = METRIC_LABELS[metric]
        filebase = METRIC_FILES[metric]

        println(tee, "Building profile: ", label, "  (column = ", col, ")")
        M, keys = fetch_paper_dim_matrix(db, col; verbose = cli[:verbose])

        if cli[:dry_run]
            println(tee, "  dry-run: would write $(filebase).{$(join(cli[:ext], ","))}")
            continue
        end

        # Get raw step-function data per solver. logscale=true ⇒ x_data
        # values are log2(τ), so x ∈ [0, ~15]. Paper convention: x-axis
        # labels are the exponents themselves (paper text page 15: "x-ticks
        # are set at 2⁰, 2¹, 2², … 2¹¹ but written as 0, 1, 2, … 11 for
        # convenience"). This also keeps all 3 metrics on comparable
        # x-ranges (linear scale would squish CPU's max_ratio ≈ 32000 into
        # the leftmost 0.1% of the plot).
        x_data, y_data, max_ratio =
            performance_profile_data(M; logscale = true)

        # x-axis upper bound: data-driven (matches reference convention
        # `xs = 1:ceil(max_ratio + 0.5)`), with CLI override via --tau-max.
        xmax = if cli[:tau_max] !== nothing
            # User-supplied --tau-max is in log2 space too (i.e. the
            # exponent), matching what the x-axis labels show.
            Float64(cli[:tau_max])
        else
            ceil(max_ratio + 0.5)
        end
        xtick_vals = collect(0.0:ceil(xmax/8):xmax)   # ~8 evenly-spaced ticks
        xtick_labs = [string(Int(round(t))) for t in xtick_vals]

        plt = plot(;
            title           = label,
            xlabel          = "Performance ratio",
            ylabel          = "Solved problems (%)",
            legend          = :bottomright,
            grid            = true,
            framestyle      = :box,
            size            = (1000, 700),
            xlims           = (0.0, xmax),
            ylims           = (0.0, 1.05),
            xticks          = (xtick_vals, xtick_labs),
            titlefontsize   = 14,
            guidefontsize   = 12,        # axis labels (xlabel/ylabel)
            tickfontsize    = 10,
            legendfontsize  = 10,
            bottom_margin   = 8Plots.mm, # extra space for xlabel
            left_margin     = 6Plots.mm,
            right_margin    = 4Plots.mm,
            top_margin      = 4Plots.mm,
        )
        for s in eachindex(LS_LEGEND)
            xs = x_data[s]
            ys = y_data[s]

            # GR backend quirk: `seriestype=:steppost` legend swatches show
            # only the line, NOT the marker, even when `marker=...` is set.
            # Standard workaround: add an empty proxy series with default
            # `:line` seriestype (which DOES render marker in legend) and
            # carry the legend label there; the actual data series uses
            # `label=""` so it doesn't double-list.
            plot!(plt, Float64[], Float64[];
                label             = LS_LEGEND[s],     # legend entry lives here
                linecolor         = LS_COLORS[s],
                linestyle         = LS_LINESTYLE[s],
                linewidth         = 2.5,
                marker            = LS_MARKERS[s],
                markercolor       = LS_COLORS[s],
                markersize        = 6,
                markerstrokewidth = 0,
            )
            plot!(plt, xs, ys;
                seriestype        = :steppost,
                label             = "",                # silenced — proxy above handles legend
                linecolor         = LS_COLORS[s],
                linestyle         = LS_LINESTYLE[s],
                linewidth         = 2.5,
                marker            = LS_MARKERS[s],
                markercolor       = LS_COLORS[s],
                markersize        = 4,
                markerstrokewidth = 0,
            )
        end

        for ext in cli[:ext]
            path = joinpath(out_dir, "$(filebase).$(ext)")
            savefig(plt, path)
            println(tee, "  → ", path)
        end
    end

    println(tee, "-" ^ 76)
    println(tee, "Done.")
    teardown_logging(tee, logpath)
end

main()
