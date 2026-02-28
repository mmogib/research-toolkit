# ============================================================================
# s70: [Figure Type] Figure Generation
# ============================================================================
#
# Goal:   Generate [figure type] from experiment data
# Input:  results/[experiment]/[data files]
# Output: results/figures/fig_[name].pdf
#
# Usage:
#   julia --project=. scripts/s70_fig_name.jl
# ============================================================================

push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))
using ModuleName
using Printf, DelimitedFiles
using Plots; pgfplotsx()   # LaTeX-quality output
using LaTeXStrings

# ── Configuration ───────────────────────────────────────────────────────────
const INPUT_DIR  = joinpath(@__DIR__, "..", "results", "histories")
const OUTPUT_DIR = joinpath(@__DIR__, "..", "results", "figures")
mkpath(OUTPUT_DIR)

# Problems to include in figure
const PROBLEMS = [
    (id=15, name="MOP1"),
    (id=24, name="MOP2"),
    (id=46, name="NS_AbsVal"),
]

# Parameter levels (for convergence comparison)
const PARAM_VALUES = [0.0, 0.25, 0.50, 0.75]
const PARAM_LABELS = [L"\eta=0", L"\eta=0.25", L"\eta=0.50", L"\eta=0.75"]
const LINE_STYLES  = [:solid, :dash, :dot, :dashdot]
const LINE_COLORS  = [:blue, :red, :green, :purple]

# ── Figure Generation ──────────────────────────────────────────────────────

plots_list = []

for prob in PROBLEMS
    p = plot(;
        xlabel  = "Iteration",
        ylabel  = L"|v(x_k)|",
        yscale  = :log10,
        legend  = :topright,
        title   = prob.name,
        titlefontsize = 10,
        guidefontsize = 9,
        tickfontsize  = 8,
        legendfontsize = 7,
    )

    for (j, param) in enumerate(PARAM_VALUES)
        param_str = replace(@sprintf("%.2f", param), "." => "p")
        hfile = joinpath(INPUT_DIR, "hist_$(prob.id)_param$(param_str).csv")

        if !isfile(hfile)
            @printf("  SKIP: %s (file not found)\n", hfile)
            continue
        end

        data = readdlm(hfile, ','; header=true)[1]
        iters = Int.(data[:, 1])
        vals  = abs.(data[:, 2])

        # Filter out zero/negative values for log scale
        mask = vals .> 0
        plot!(p, iters[mask], vals[mask];
            label = PARAM_LABELS[j],
            ls    = LINE_STYLES[j],
            lc    = LINE_COLORS[j],
            lw    = 1.5,
        )
    end

    push!(plots_list, p)
end

# Combine into single figure
fig = plot(plots_list...;
    layout = (1, length(plots_list)),
    size   = (350 * length(plots_list), 280),
    margin = 5Plots.mm,
)

output_path = joinpath(OUTPUT_DIR, "fig_convergence.pdf")
savefig(fig, output_path)
println("Saved: $output_path")
println("Copy to paper/imgs/ when ready.")
