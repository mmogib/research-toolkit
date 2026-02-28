# Experiment Workflow

End-to-end pipeline for numerical experiments in optimization research. Each phase has a clear input, output, and decision gate.

## Pipeline Overview

```
Phase 1: Problem Suite        → problems.jl, get_problem()
Phase 2: Gradient Verification → s10_check_gradients.jl
Phase 3: Single-Run Testing   → s20_run_algorithm.jl
Phase 4: Parameter Screening  → s35_oat_screening.jl (OAT)
Phase 5: Parameter Tuning     → s40_lhs_search.jl (LHS)
Phase 6: Full Benchmark       → s45_multistart.jl
Phase 7: Ablation Study       → s50_ablation.jl
Phase 8: Applications         → s60_app_multistart.jl
Phase 9: Extensions           → s65_extension.jl
Phase 10: Figures             → s70_fig_*.jl, s75_fig_*.jl
Phase 11: Paper Integration   → Copy CSV data → LaTeX tables
Phase 12: Reproducibility     → Seeds, resume flags, raw data archived
```

## Phase 1: Problem Suite

### Design Principles
- Store F and JF as closures returned by `get_problem(id)`
- Each problem has: id, name, n (dimension), m (objectives), x0 (starting point), K (feasible set)
- Group problems by type: smooth, nonsmooth, application
- Maintain a fixed ID mapping (never renumber) — document in `notes/problem_id_mapping.md`
- Exclude problematic problems from experiments but keep in codebase (document exclusion reasons)
- Reproducible starting points via Schrage RNG (or any deterministic RNG with fixed seed)

### Problem Definition Pattern
```julia
function get_problem(id::Int; kwargs...)
    if id == 1
        n, m = 2, 2
        F(x) = [f1(x), f2(x)]
        JF(x) = [∇f1(x)'; ∇f2(x)']   # m×n Jacobian
        K = Hyperrectangle(center, radius)
        x0 = starting_point(seed)
        return Problem(id, "ProblemName", n, m, x0, K), F, JF
    end
end
```

## Phase 2: Gradient Verification

Before any experiments, verify every gradient/subgradient against finite differences.

```
For each problem:
    x0 = get starting point
    JF_analytic = JF(x0)
    JF_fd = centered_finite_differences(F, x0, h=1e-7)
    Check: max|JF_analytic - JF_fd| < tolerance
    Report: PASS/FAIL with max error
```

Tolerance: `1e-5` relative error is typical. Nonsmooth problems will fail at kinks — this is expected and should be documented.

## Phase 3: Single-Run Testing

Run the algorithm on a few representative problems to verify it works end-to-end.
- Check: convergence (status = :optimal)
- Check: reasonable iteration counts
- Check: stationarity measure near zero
- Check: F(x*) values are reasonable

## Phase 4: Parameter Screening (OAT)

**One-At-a-Time** screening to identify which parameters matter.

### Design
- Fix all parameters at baseline values
- Vary one parameter at a time across 3-5 levels
- Measure: success rate, median iterations, median stationarity
- Use a small representative problem subset (10-15 problems)

### Output
- Table: parameter × level → performance metric
- Decision: which parameters to tune (those with significant effect)

## Phase 5: Parameter Tuning (LHS)

**Latin Hypercube Sampling** for systematic parameter search.

### Design
- Sample N parameter combinations (e.g., 100-500) via LHS
- Run each combination on the representative subset
- Score each combination (e.g., by success rate, then median iterations)
- Select the best combination

### Output
- Raw CSV: all combinations + scores
- Best parameters: to be used in all subsequent experiments

## Phase 6: Full Benchmark (Multi-Start)

The main experiment. Run tuned algorithm on all problems × multiple starting points.

### Design
- N problems × M starts (e.g., 48 × 51: 1 deterministic + 50 random)
- Fixed seed for reproducibility
- Adaptive tolerance: relaxed ε for high-dimensional problems
- Resume-safe: CSV flushed after every solve, `--resume` skips completed problems

### Output
- `raw.csv`: one row per (problem, start) — all details
- `summary.csv`: one row per problem — aggregated statistics (success rate, medians, IQR)
- Console + log: formatted table with aligned columns

### Key Metrics
- Success rate: n_optimal / n_starts
- Median iterations (over successful runs)
- Median function evaluations
- Median stationarity at termination
- F-spread: range of objective values across successful runs

## Phase 7: Ablation Study

Test the effect of a specific design choice (e.g., nonmonotone vs. monotone).

### Design
- Select representative problems (mix of easy/hard, smooth/nonsmooth)
- Vary the ablation parameter across levels (e.g., η_max ∈ {0.0, 0.25, 0.50, 0.75})
- Fix all other parameters at tuned values
- Use deterministic starting point only (isolate the effect)
- Record per-iteration history for convergence plots

### Output
- `raw.csv`: one row per (problem, parameter_level)
- `histories/hist_{id}_param{val}.csv`: per-iteration data for figures
- Console: wide table showing all parameter levels side-by-side

## Phase 8: Application Problems

Run on real-world application problems with many starting points.

### Design
- More starting points (e.g., 200) for richer Pareto approximation
- May have different feasible sets (simplex, box with specific bounds)
- Report Pareto front quality, not just convergence

## Phase 9: Extensions

Test algorithm extensions (e.g., general ordering cones, different scalarizations).

### Design
- Compare standard vs. extended on the same problems
- Report: success rate, computational cost ratio, Pareto front differences

## Phase 10: Figures

Generate publication-quality figures.

### Types
1. **Convergence history**: |v(x_k)| vs. iteration (log scale), multiple parameter levels
2. **Pareto front**: F₁ vs. F₂ scatter, comparing methods/settings
3. **Parameter sensitivity**: heatmap or line plot of metric vs. parameter

### Technical Requirements
- PGFPlotsX backend for LaTeX-native output (PDF)
- Consistent styling: line widths, colors, markers
- Figures saved to `results/figures/` first, then copied to `paper/imgs/`

## Phase 11: Paper Integration

### Tables
- Read summary CSV → format as LaTeX table
- Use `\num{}` for scientific notation (siunitx package)
- Bold best values per row
- Include footnotes for special cases

### Discussion Points to Cover
1. Overall success rate and what it means
2. Failure analysis: which problems fail and why
3. Effect of key parameters (from ablation)
4. Comparison with baseline (if applicable)
5. Computational cost
6. Limitations (honest assessment)

## Phase 12: Reproducibility

### Checklist
- [ ] Fixed seeds for all random operations
- [ ] Raw CSV data archived (with backup copies)
- [ ] Scripts can reproduce results with `--all --resume`
- [ ] Problem IDs documented and stable
- [ ] Parameter values documented (tuned values recorded)
- [ ] Julia version and package versions recorded in Project.toml
- [ ] Excluded problems documented with reasons

## Directory Structure for Results
```
results/
├── logs/                  # Auto-generated log files (timestamped)
├── oat/                   # Phase 4: OAT screening data
├── lhs/                   # Phase 5: LHS parameter search data
├── multistart/            # Phase 6: multi-start benchmark
│   ├── raw.csv            # One row per (problem, start)
│   ├── summary.csv        # One row per problem
│   └── raw_backup_*.csv   # Backups before modifications
├── ablation/              # Phase 7: ablation study
├── histories/             # Per-iteration convergence data
├── applications/          # Phase 8: application experiments
├── extensions/            # Phase 9: extension experiments
└── figures/               # Phase 10: generated figures (PDF, PNG)
```
