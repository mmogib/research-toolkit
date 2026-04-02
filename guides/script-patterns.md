# Script Patterns — Composable Code Blocks

Each section below is a self-contained code block. Compose them in order to build a complete script. Replace `{placeholders}` with project-specific values.

**Storage backends**: Blocks marked **(DB)** use SQLite via `benchmark.jl`. Blocks marked **(CSV)** use manual CSV I/O. Blocks marked **(Both)** work with either. SQLite is the default for new projects.

**All scripts must be wrapped in `main()`** — see Block 1b.

---

## 1. Header Comment Block

Always included. Describes what the script does, where output goes, and how to run it. Include the flags the script supports.

```julia
# ============================================================================
# s{NN}: {Title}
# ============================================================================
#
# Goal:   {One-line description of what this script does}
# Output: {Where results go, e.g., results/experiments.db, results/figures/}
#
# Usage:
#   julia --project=. scripts/s{NN}_{name}.jl --all              # all problems
#   julia --project=. scripts/s{NN}_{name}.jl --all --force      # re-run all
#   julia --project=. scripts/s{NN}_{name}.jl --quick             # dev subset
#   julia --project=. scripts/s{NN}_{name}.jl --summary           # print stats
#   julia --project=. scripts/s{NN}_{name}.jl --export            # CSV export
#   julia --project=. scripts/s{NN}_{name}.jl --problems=P1,P5    # subset
#   julia --project=. scripts/s{NN}_{name}.jl --dims=10000        # one dim
# ============================================================================
```

## 1b. `main()` Function Wrapping

**Always included.** Every script wraps its body in `function main() ... end` to avoid Julia scoped-variable issues in newer versions. Place `main()` call at the very end.

```julia
function main()
    # ... entire script body goes here ...
end

main()
```

---

## 2. Load Path / Imports

**Style A (Module Package):**
```julia
push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))
using {ModuleName}
using Printf, Statistics
```

**Style B (Flat Include):**
```julia
include(joinpath(@__DIR__, "..", "src", "includes.jl"))
using Printf, Statistics
```

Both styles make `JCODE_ROOT` available (defined in `includes.jl` or the module as `dirname(@__DIR__)`). Use `JCODE_ROOT` for all paths to `results/`, `src/`, etc.

Add script-specific packages after the module/include line (e.g., `using ProgressMeter`, `using Plots`). Heavy packages (`Plots`, `BenchmarkProfiles`) go in scripts, not in `deps.jl`.

---

## 3. ARGS Parsing

Standard pattern for boolean flags and key-value arguments.

### 3a. Boolean + Key-Value Parsing (recommended)

```julia
# --- Parse arguments ---
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
do_force   = "force" in flags       # override skip-if-done
do_summary = "summary" in flags     # print stats, then exit
do_export  = "export" in flags      # CSV export, then exit
do_verbose = "verbose" in flags     # progress bar with live info
do_quick   = "quick" in flags       # reduced sweep for development
```

### 3b. Selection from Key-Value Args

```julia
# Defaults: all problems/methods. Dims requires --all or --dims=.
sel_problems = haskey(kv, "problems") ? String.(split(kv["problems"], ",")) : all_problems
sel_dims     = haskey(kv, "dims") ? [parse(Int, s) for s in split(kv["dims"], ",")] :
               (do_all ? all_dims : Int[])
sel_methods  = haskey(kv, "methods") ? String.(split(kv["methods"], ",")) : all_methods
```

### 3c. `--quick` Mode Override

```julia
if do_quick
    sel_dims = dims_small[1:1]
    sel_problems = all_problems[1:min(3, length(all_problems))]
end
```

### 3d. Legacy: Problem ID Range Parsing (for simple scripts)

```julia
ids = filter(a -> !startswith(a, "-"), ARGS)
if "--all" in flags
    prob_ids = collect(1:{N_PROBLEMS})
elseif !isempty(ids)
    prob_ids = Int[]
    for s in ids
        if contains(s, "-")
            parts = split(s, "-")
            append!(prob_ids, parse(Int, parts[1]):parse(Int, parts[2]))
        else
            push!(prob_ids, parse(Int, s))
        end
    end
else
    prob_ids = {DEFAULT_SUBSET}
end
```

---

## 4. TeeIO Logging Setup

Requires `io_utils.jl` to be available (see infrastructure-patterns.md).

```julia
# --- Setup logging ---
logpath, tee, logfile = setup_logging("{script_name}")
```

---

## 5. Results Directory

Create the output directory for this script.

```julia
results_dir = joinpath(@__DIR__, "..", "results", "{experiment_name}")
mkpath(results_dir)
```

---

## 6. Configuration Constants

Project-specific constants. Adapt names and values to the project.

```julia
# ============================================================================
# Configuration
# ============================================================================

# Algorithm parameters (tuned values or defaults)
const PARAM_A = {value}
const PARAM_B = {value}

# Experiment settings
const N_STARTS   = {50}              # for multi-start scripts
const RNG_SEED   = {42}              # for reproducibility
const FIXED_ε    = {1e-4}
const FIXED_MAXITER = {5000}
```

---

## 7. Adaptive Parameters

Tolerance and iteration limits that depend on problem dimension.

```julia
# Adaptive parameters based on problem dimension
get_ε(n)       = n >= {threshold} ? {relaxed_ε} : {tight_ε}
get_maxiter(n) = n >= {threshold} ? {large_maxiter} : {small_maxiter}
```

---

## 8. CSV Constants and Paths

Define CSV headers as constants. Column names use snake_case.

```julia
raw_csv_path = joinpath(results_dir, "{prefix}_raw.csv")
const RAW_HEADER = "{col1},{col2},{col3},..."
const SUMMARY_HEADER = "{col1},{col2},{col3},..."
```

---

## 9. Summary Mode Block

Two-mode pattern: `--summary` queries existing results, prints stats, then exits. Place BEFORE the main solve loop.

### 9a. DB Summary Mode (recommended)

```julia
if do_summary
    print_summary(db, tee, all_methods)   # from benchmark.jl
    teardown_logging(tee, logpath)
    return   # (inside main(), use return instead of exit)
end
```

### 9b. `--export` Mode (DB → CSV)

```julia
if do_export
    export_path = joinpath(JCODE_ROOT, "results", "{experiment}_export.csv")
    n = export_results_csv(db, export_path)
    println(tee, "Exported $n rows to: $export_path")
    teardown_logging(tee, logpath)
    return
end
```

### 9c. CSV Summary Mode (legacy)

```julia
if do_summary
    if !isfile(raw_csv_path)
        println(tee, "ERROR: No raw CSV found at $raw_csv_path")
        teardown_logging(tee, logpath)
        return
    end

    # Group raw lines by {grouping_key}
    grouped = Dict{Int, Vector{String}}()
    for line in eachline(raw_csv_path)
        startswith(line, "{first_col_name}") && continue
        parts = split(line, ","; limit=2)
        isempty(parts) && continue
        key = tryparse(Int, parts[1])
        key === nothing && continue
        push!(get!(grouped, key, String[]), line)
    end

    # --- Aggregate + print ---
    # ... project-specific aggregation logic ...

    teardown_logging(tee, logpath)
    return
end
```

---

## 10. Skip-by-Default + `--force` Override

Scripts skip completed runs automatically. Use `--force` to re-run everything.

### 10a. DB Skip Logic (recommended)

Used during work list construction. Each work item is checked against the DB.

```julia
# Inside work list loop:
if !do_force && is_done(db, config_hash, prob_str, dim, init_label)
    continue   # already done, skip
end
push!(work, WorkItem(...))
```

For runs with selective history tracking, check whether history exists too:

```julia
if !do_force && is_done(db, hash, prob_str, dim, init_label)
    if track
        # Result exists but history might be missing
        hist_check = DBInterface.execute(db,
            "SELECT 1 FROM history WHERE config_hash=? AND problem=? AND dimension=? AND init_point=? LIMIT 1",
            (hash, prob_str, dim, init_label)) |> DataFrame
        nrow(hist_check) > 0 && continue   # both exist, skip
    else
        continue   # result exists, no tracking needed
    end
end
```

### 10b. CSV Skip Logic

Read existing CSV rows into a Set, skip matching keys.

```julia
completed = Set{Tuple{String, Int, String}}()  # (method, dim, init_label)

if !do_force && isfile(raw_csv_path)
    for line in eachline(raw_csv_path)
        startswith(line, "{first_col}") && continue   # skip header
        fields = split(line, ",")
        length(fields) >= {min_fields} || continue
        key = (fields[1], parse(Int, fields[3]), fields[4])
        push!(completed, key)
    end
    if !isempty(completed)
        println(tee, "Skipping $(length(completed)) completed runs (use --force to re-run)")
    end
end
```

### 10c. CSV Backup (before overwrite)

When using CSV and about to overwrite, back up first.

```julia
if isfile(raw_csv_path)
    backup_dir = joinpath(results_dir, "backup")
    mkpath(backup_dir)
    ts = Dates.format(now(), "yyyymmdd_HHMMss")
    cp(raw_csv_path, joinpath(backup_dir, "raw_$(ts).csv"))
    println(tee, "Backed up existing CSV → backup/raw_$(ts).csv")
end
```

---

## 11. Main Loop Banner

Print experiment configuration before the solve loop.

```julia
println(tee, "=" ^ {width})
println(tee, "{Experiment Title}")
println(tee, "=" ^ {width})
println(tee, "Parameters: {param_summary}")
println(tee, "Problems: $(prob_ids)")
println(tee, "Resume: $(do_resume ? "enabled ($(length(completed)) done)" : "disabled")")
println(tee)
```

---

## 12. CSV File Opening

Open raw CSV in append mode (resume) or write mode (fresh).

```julia
if do_resume && !isempty(completed)
    raw_io = open(raw_csv_path, "a")
else
    raw_io = open(raw_csv_path, "w")
    println(raw_io, RAW_HEADER)
end
```

---

## 13. Formatted Output Table Header

Aligned column headers for console output.

```julia
println(tee, "-" ^ {width})
@printf(tee, "%-5s %-14s %4s %4s  %8s  %10s  %10s  %8s\n",
        "ID", "Name", "n", "m", "success", "med_iters", "med_v", "elapsed")
println(tee, "-" ^ {width})
```

---

## 14. ProgressMeter

Progress bar for inner loops (e.g., multiple starts per problem).

```julia
using ProgressMeter

prog = Progress(n_total;
    desc  = @sprintf("  Prob %2d %-14s ", prob_id, name),
    barlen = 30,
    showspeed = true,
    enabled = !verbose)   # disable when verbose (avoids conflict)

for (idx, item) in enumerate(items)
    # ... solve ...
    ProgressMeter.update!(prog, idx;
        showvalues = [
            (:optimal, "$n_ok / $idx"),
            (:errors,  n_error),
        ])
end
finish!(prog)
```

---

## 15. Random Feasible Starting Points

Generate random points inside the feasible set.

```julia
"""
    random_feasible_point(K, n, rng)

Generate a uniformly random point in the feasible set K.
"""
function random_feasible_point(K, n::Int, rng::AbstractRNG)
    if K isa LazySets.Hyperrectangle
        lb = LazySets.low(K)
        ub = LazySets.high(K)
        return lb .+ (ub .- lb) .* rand(rng, n)
    elseif K isa LazySets.HPolytope
        # Simplex: Dirichlet(1,...,1) via exponential variates
        raw = -log.(rand(rng, n))
        return raw ./ sum(raw)
    else
        # Fallback: bounding box
        box = LazySets.overapproximate(K, LazySets.Hyperrectangle)
        lb = LazySets.low(box)
        ub = LazySets.high(box)
        return lb .+ (ub .- lb) .* rand(rng, n)
    end
end
```

Adapt the function signature and set types to the project. If not using LazySets, use the project's feasible set representation.

---

## 16. Try-Catch Per Solve

Wrap each solve in try-catch. Write error rows to CSV.

```julia
try
    result = {solve_function}(...)

    # Process result by status
    if result.status == :optimal
        n_ok += 1
    elseif result.status == :maxiter
        n_maxiter += 1
    elseif result.status == :linesearch_failed
        n_lsfail += 1
    end

    # Write raw CSV row and flush
    @printf(raw_io, "{format}\n", {fields}...)
    flush(raw_io)
catch ex
    n_error += 1
    @printf(raw_io, "{error_format}\n", {error_fields}...)
    flush(raw_io)
    @printf(logfile, "  [ERROR] prob %d: %s\n", id, sprint(showerror, ex))
end
```

---

## 17. Per-Iteration History Recording

Save convergence data for later figure generation.

```julia
# In the solve call, enable history recording:
result = {solve_function}(...; record_history=true)

# After solve, write history CSV:
if !isempty(result.history)
    param_str = replace(@sprintf("%.2f", param_val), "." => "p")
    hfile = joinpath(hist_dir, "hist_$(id)_param$(param_str).csv")
    open(hfile, "w") do io
        println(io, "iter,{metric_name},{other_metric}")
        for h in result.history
            @printf(io, "%d,%.10e,%.10e\n", h.iter, h.metric, h.other)
        end
    end
end
```

---

## 18. Elapsed Time Formatting

Human-readable elapsed time string.

```julia
function format_elapsed(elapsed)
    if elapsed < 60
        return @sprintf("%.0fs", elapsed)
    elseif elapsed < 3600
        return @sprintf("%.1fm", elapsed / 60)
    else
        return @sprintf("%.1fh", elapsed / 3600)
    end
end
```

---

## 19. Main Loop Structure

The overall loop pattern. Compose with the blocks above.

```julia
t_script_start = time()
n_done = 0

for prob_id in prob_ids
    # Resume: skip completed
    if prob_id in completed
        @printf(tee, "%-5d (SKIPPED)\n", prob_id)
        continue
    end

    # Load problem
    {prob, F, JF = get_problem(prob_id)}
    t_prob = time()

    # Configure
    cfg = {ConfigType}(
        ε = get_ε(prob.n),
        maxiter = get_maxiter(prob.n),
    )

    # Inner loop (starts, parameter values, etc.)
    n_ok = 0; n_error = 0
    for (idx, item) in enumerate(items)
        # ... try-catch solve block ...
    end

    # Per-problem summary line
    prob_elapsed = time() - t_prob
    n_done += 1
    @printf(tee, "%-5d %-14s %4d %4d  %3d/%3d   %8s\n",
            prob_id, name, n, m, n_ok, n_total, format_elapsed(prob_elapsed))
end

close(raw_io)
println(tee, "-" ^ {width})
total_elapsed = time() - t_script_start
@printf(tee, "\nDone. %d problems in %s\n", n_done, format_elapsed(total_elapsed))
```

---

## 20. Teardown

Always at the end of the script.

```julia
println(tee, "Raw results: $raw_csv_path")
println(tee, "\nRun with --summary to generate aggregated report.")
println(tee, "=" ^ {width})
teardown_logging(tee, logpath)
```

---

## 21. Figure Script Pattern (Legacy)

Minimal structure for simple figure scripts. For the full DB-backed figures+tables pattern, see `templates/script_figures_tables.jl`.

```julia
using Plots
using Printf
using LaTeXStrings

# Backend selection
gr()          # or: pgfplotsx() for LaTeX-native PDF

# ============================================================================
# Configuration
# ============================================================================

const DATA_DIR = joinpath(@__DIR__, "..", "results", "{data_source}")
const FIGS_DIR = joinpath(@__DIR__, "..", "results", "figures")
mkpath(FIGS_DIR)
const OUTPUT_PATH = joinpath(FIGS_DIR, "{figure_name}.pdf")

# Plot styling
const STYLES = [:solid, :dash, :dashdot, :dot]
const COLORS = [:royalblue, :firebrick, :forestgreen, :darkorange]

# ============================================================================
# Read data
# ============================================================================

function read_data(path)
    # Read CSV, return arrays for plotting
end

# ============================================================================
# Build figure
# ============================================================================

subplots = []
for (id, name) in PROBLEMS
    p = plot(;
        xlabel = "{x_label}",
        ylabel = "{y_label}",
        title = name,
        yscale = :log10,          # if appropriate
        legend = :topright,
        legendfontsize = 7,
        titlefontsize = 10,
        guidefontsize = 9,
        tickfontsize = 8,
        grid = true,
        framestyle = :box,
    )

    for (i, variant) in enumerate(variants)
        # Read and plot data
        plot!(p, xs, ys;
            label = labels[i],
            color = COLORS[i],
            linestyle = STYLES[i],
            linewidth = 1.5,
        )
    end
    push!(subplots, p)
end

fig = plot(subplots...;
    layout = (1, length(subplots)),
    size = (400 * length(subplots), 350),
    left_margin = 5Plots.mm,
    bottom_margin = 5Plots.mm,
)

savefig(fig, OUTPUT_PATH)
println("Saved: $OUTPUT_PATH")
```

---

## 22. Shifted Geometric Mean

Aggregation metric that reduces influence of very small values. Used in OAT/LHS scripts.

```julia
"""
    shifted_geom_mean(vals, shift)

SGM(x; s) = (∏(xᵢ + s))^{1/n} - s
"""
function shifted_geom_mean(vals::Vector{Float64}, shift::Float64)
    isempty(vals) && return NaN
    n = length(vals)
    log_sum = sum(log(v + shift) for v in vals)
    return exp(log_sum / n) - shift
end
```

---

## 23. Config Hashing (DB)

Content-addressable experiment IDs. The SAME NamedTuple is hashed AND splatted to the solver — zero divergence.

```julia
# In the script's EXPERIMENT CONFIGURATION section:
solvers = Dict(
    "AlgoName" => (
        fn      = solve_algo,
        version = ALGO_VERSION,
        params  = (param1=0.5, param2=0.1, param3=1.8),
    ),
)

# Compute hashes and register in DB:
solver_hashes = Dict{String,String}()
for (name, cfg) in solvers
    hash, hash_input = make_config_hash(name, cfg.version, cfg.params,
                                        const_eps, const_maxiter)
    solver_hashes[name] = hash
    ensure_config!(db, hash, name, cfg.version, cfg.params,
                  const_eps, const_maxiter, hash_input)
end
```

The `make_config_hash` and `ensure_config!` functions live in `src/benchmark.jl` (see `templates/benchmark_db_template.jl`).

---

## 24. WorkItem Struct

Flat work list for the main loop. Struct must be defined at top level (outside `main()`).

```julia
struct WorkItem
    method::String
    config_hash::String
    prob_id::Int
    prob_str::String
    dim::Int
    init_label::String
    x0::Vector{Float64}
    track::Bool              # selective history tracking
end
```

Build the work list inside `main()`:

```julia
work = WorkItem[]
for dim in sel_dims
    for pid in PROBLEM_IDS
        prob_str = "P$pid"
        prob_str in sel_problems || continue
        for method in sel_methods
            hash = solver_hashes[method]
            inits = get_initial_points(dim, pid)
            for (init_label, x0) in inits
                track = should_track(method, prob_str, dim, init_label)
                # Skip-by-default logic (see Block 10a)
                if !do_force && is_done(db, hash, prob_str, dim, init_label)
                    continue
                end
                push!(work, WorkItem(method, hash, pid, prob_str, dim,
                                    init_label, x0, track))
            end
        end
    end
end
```

---

## 25. Solver Callback for Progress

Live iteration info inside the progress bar. The callback is passed to the solver and called once per iteration.

```julia
# Build callback for this work item:
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

# Pass to solver:
result = solver_fn(prob.F, prob.proj, x0; params...,
                   eps=const_eps, maxiter=const_maxiter,
                   track=w.track, callback=cb)
```

The solver must accept `callback=nothing` and call it inside its main loop:
```julia
callback !== nothing && callback(k, norm_Fk, maxiter)
```

---

## 26. Performance Profiles (DB)

Build and plot Dolan-More performance profiles from DB results.

```julia
using BenchmarkProfiles

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

# Usage:
T = build_profile_matrix(df, :iterations)
performance_profile(PlotsBackend(), T, METHOD_ORDER; logscale=true, ...)
```

---

## 27. LaTeX Table Generation

Write LaTeX tables from aggregated DB results. Bold best values per row.

```julia
# Find best values across methods for a (problem, dim) row:
best_iter = Inf; best_feval = Inf; best_cpu = Inf
for m in METHOD_ORDER
    sub = filter(r -> r.method == m && r.problem == prob && r.dimension == dim, agg)
    if nrow(sub) > 0 && sub.n_conv[1] > 0
        best_iter  = min(best_iter,  sub.avg_iter[1])
        best_feval = min(best_feval, sub.avg_feval[1])
        best_cpu   = min(best_cpu,   sub.avg_cpu[1])
    end
end

# Format cell: bold if best
it_str = it ≈ best_iter ? "\\textbf{$it}" : "$it"
```

See `templates/script_figures_tables.jl` for complete table generators (per-tier, overall summary, tier-averaged).

---

## 28. Starting Points with Feasibility

Labeled starting points for benchmark scripts. Labels become DB `init_point` values.

```julia
function get_initial_points(n::Int, prob_id::Int)
    points = Tuple{String, Vector{Float64}}[]
    push!(points, ("v1", zeros(n)))
    push!(points, ("v2", fill(0.5, n)))
    push!(points, ("v3", ones(n)))
    push!(points, ("v4", fill(2.0, n)))
    push!(points, ("v5", fill(1/n, n)))
    push!(points, ("v6", [1.0/k for k in 1:n]))
    push!(points, ("v7", [(k-1)/(n-1) for k in 1:n]))
    push!(points, ("v8", [k/n for k in 1:n]))
    push!(points, ("v9", [1.0/3.0^k for k in 1:n]))
    push!(points, ("v10", fill(1.1, n)))

    # Project into feasible set
    prob = get_problem(prob_id)
    for i in eachindex(points)
        label, x0 = points[i]
        x0_feas = ensure_feasible(prob.proj, x0)
        x0_feas !== x0 && (points[i] = (label, x0_feas))
    end
    return points
end

function ensure_feasible(proj::Function, x0::Vector{Float64})
    x_proj = proj(x0)
    norm(x_proj - x0) > 1e-12 ? x_proj : x0
end
```
