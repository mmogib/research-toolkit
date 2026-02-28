# Experiment Script Patterns

Reusable patterns for experiment scripts. All patterns are extracted from working code.

## Script Naming Convention
Scripts are prefixed `s{NN}_` in increments of 10, allowing insertion without renaming:
```
s10_check_gradients.jl      # Verification
s20_run_algorithm.jl         # Single-algorithm runner
s30_run_alternative.jl       # Alternative algorithm runner
s35_oat_screening.jl         # OAT parameter screening
s40_lhs_search.jl            # LHS parameter search
s45_multistart.jl            # Multi-start benchmark
s50_ablation.jl              # Ablation study
s60_application.jl           # Application experiments
s65_extension.jl             # Extension experiments (e.g., general cones)
s70_fig_convergence.jl       # Figure: convergence histories
s75_fig_pareto.jl            # Figure: Pareto fronts
```

## Standard Script Header
```julia
# ============================================================================
# s45: Multi-Start Robustness Test for AlgorithmName
# ============================================================================
#
# Goal:   Run algorithm on N problems × M starting points
# Output: results/experiment_name/raw.csv, summary.csv
# Usage:
#   julia --project=. scripts/s45_multistart.jl --all           # all problems
#   julia --project=. scripts/s45_multistart.jl 3-11 --resume   # range, resume
#   julia --project=. scripts/s45_multistart.jl --summary        # post-process
# ============================================================================

push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))
using ModuleName
using Printf, Random, Dates
```

## ARGS Parsing Pattern
```julia
flags = filter(a -> startswith(a, "-"), ARGS)
ids   = filter(a -> !startswith(a, "-"), ARGS)

verbose    = "--verbose" in flags
do_resume  = "--resume" in flags
do_summary = "--summary" in flags

if "--all" in flags
    prob_ids = collect(1:N_PROBLEMS)
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
    prob_ids = DEFAULT_SUBSET  # Representative subset for quick testing
end

# Keyword overrides
for f in flags
    if startswith(f, "--eps=")
        global FIXED_ε = parse(Float64, split(f, "=")[2])
    elseif startswith(f, "--maxiter=")
        global FIXED_MAXITER = parse(Int, split(f, "=")[2])
    end
end
```

## Two-Mode Pattern (Solve vs. Summary)
```julia
if do_summary
    # === POST-PROCESS MODE ===
    # Read raw CSV → aggregate statistics → write summary CSV
    summarize_results(raw_csv_path, summary_csv_path, tee)
    teardown_logging(tee, logpath)
    exit(0)
end

# === MAIN SOLVE MODE ===
# (reached only if not do_summary)
```

## Resume Pattern
```julia
completed = Set{Int}()   # or Set{Tuple{Int,Float64}} for multi-parameter

if do_resume && isfile(raw_csv_path)
    for line in eachline(raw_csv_path)
        startswith(line, "prob_id") && continue   # Skip header
        parts = split(line, ","; limit=2)
        pid = parse(Int, parts[1])
        # Track completed items
    end

    # Count completions per problem
    for (pid, lines) in prob_lines
        if length(lines) >= expected_count
            push!(completed, pid)
        else
            # Partial: rewrite CSV without incomplete rows
        end
    end

    n_skip = length(completed)
    @printf(tee, "Resume: %d problems already done, %d remaining\n",
            n_skip, length(prob_ids) - n_skip)
end
```

## CSV I/O Pattern

### Constants
```julia
const RAW_HEADER = "prob_id,prob_name,n,m,start_idx,start_type,status,iters,f_evals,g_evals,v_final,time_s,F_values"
const SUMMARY_HEADER = "prob_id,prob_name,n,m,n_starts,n_optimal,success_rate,median_iters,median_fevals,median_time,median_v"
```

### Writing with Immediate Flush
```julia
raw_io = open(raw_csv_path, do_resume ? "a" : "w")
if !do_resume
    println(raw_io, RAW_HEADER)
end

# Inside solve loop:
@printf(raw_io, "%d,%s,%d,%d,%d,%s,%s,%d,%d,%d,%.10e,%.6f,%s\n",
        prob_id, name, n, m, start_idx, start_type,
        result.status, result.iterations, result.f_evals, result.g_evals,
        result.stationarity, result.time_seconds, F_str)
flush(raw_io)   # CRITICAL: flush after every row (resume-safe)
```

### Summary Aggregation
```julia
function summarize_results(raw_path, summary_path, tee)
    # Group rows by problem ID
    prob_lines = Dict{Int, Vector{String}}()
    for line in eachline(raw_path)
        startswith(line, "prob_id") && continue
        parts = split(line, ",")
        pid = parse(Int, parts[1])
        push!(get!(prob_lines, pid, String[]), line)
    end

    # Compute per-problem statistics
    for pid in sort(collect(keys(prob_lines)))
        lines = prob_lines[pid]
        statuses = [Symbol(split(l, ",")[7]) for l in lines]
        n_optimal = count(==(":optimal"), statuses)
        # ... compute median, IQR, etc. ...
    end
end
```

## TeeIO Logging Pattern
```julia
# Setup at script start
logpath, tee, logfile = setup_logging("experiment_name")

# All output goes to both console AND log file
println(tee, "Starting experiment...")
@printf(tee, "Problem %d: %s (n=%d, m=%d)\n", id, name, n, m)

# Detailed errors go to log file only
@printf(logfile, "  [ERROR] prob %d: %s\n", id, sprint(showerror, ex))

# Teardown at script end
teardown_logging(tee, logpath)
```

## Progress Bar Pattern
```julia
using ProgressMeter

prog = Progress(n_total;
    desc  = @sprintf("  Prob %2d %-14s ", prob_id, name),
    barlen = 30,
    showspeed = true,
    enabled = !verbose)   # Disable when verbose (avoids conflict with per-iter output)

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

## Output Formatting
```julia
# Printf-based column alignment
@printf(tee, "%-5s %-14s %4s %4s  %8s  %10s  %10s  %10s\n",
        "ID", "Name", "n", "m", "success", "med_iters", "med_v", "time")
println(tee, "-" ^ 80)

for row in results
    @printf(tee, "%-5d %-14s %4d %4d  %3d/%3d   %10.0f  %10.2e  %10.3f\n",
            row.id, row.name, row.n, row.m,
            row.n_ok, row.n_total, row.med_iters, row.med_v, row.med_time)
end
println(tee, "=" ^ 80)
```

## Elapsed Time Formatting
```julia
elapsed_str = if elapsed < 60
    @sprintf("%.0fs", elapsed)
elseif elapsed < 3600
    @sprintf("%.1fm", elapsed / 60)
else
    @sprintf("%.1fh", elapsed / 3600)
end
```

## Main Loop Structure
```julia
t_script_start = time()
n_done = 0

for prob_id in prob_ids
    if prob_id in completed
        @printf(tee, "  [SKIP] prob %d (already done)\n", prob_id)
        continue
    end

    prob, F, JF = get_problem(prob_id)
    t_prob = time()

    # Configure
    cfg = AlgorithmConfig(
        ε = get_ε(prob.n),
        maxiter = get_maxiter(prob.n),
        verbose = verbose,
    )

    # Generate starting points
    starts = generate_starts(prob, N_STARTS, RNG_SEED)

    # Solve loop
    for (start_idx, (x0, start_type)) in enumerate(starts)
        try
            result = solve(F, JF, x0; cfg=cfg)
            # Write CSV row + flush
        catch ex
            # Log error + write error row + flush
        end
    end

    n_done += 1
    @printf(tee, "  Done (%s)\n", elapsed_str)
end

total_elapsed = time() - t_script_start
@printf(tee, "\nComplete: %d problems in %s\n", n_done, format_elapsed(total_elapsed))

close(raw_io)
teardown_logging(tee, logpath)
```

## Adaptive Parameters
```julia
# Tolerance and iteration limits based on problem dimension
get_ε(n)       = n >= 50 ? 1e-2 : 1e-4
get_maxiter(n) = n >= 50 ? 10000 : 5000
```

## Multi-Parameter Experiments (Ablation Pattern)
```julia
const PARAM_VALUES = [0.0, 0.25, 0.50, 0.75]

for id in prob_ids
    for param_val in PARAM_VALUES
        if (id, param_val) in completed
            continue  # Resume: skip done pairs
        end

        cfg = AlgorithmConfig(param = param_val, ε = get_ε(prob.n))
        result = solve(F, JF, x0; cfg=cfg)

        # Write CSV: include param_val as column
        @printf(raw_io, "%d,%s,%.6f,%s,%d,...\n", id, name, param_val, result.status, ...)
        flush(raw_io)

        # Optional: write per-iteration history
        if !isempty(result.history)
            param_str = replace(@sprintf("%.2f", param_val), "." => "p")
            hfile = joinpath(hist_dir, "hist_$(id)_param$(param_str).csv")
            open(hfile, "w") do io
                println(io, "iter,stationarity,step_size,F_values")
                for h in result.history
                    @printf(io, "%d,%.10e,%.10e,%s\n", h.iter, h.v, h.τ, join(h.Fx, ";"))
                end
            end
        end
    end
end
```

## Figure Generation Pattern
```julia
using Plots; pgfplotsx()  # or gr() for quick preview

function make_convergence_figure(hist_dir, output_path)
    problems = [("Problem A", 1), ("Problem B", 2), ("Problem C", 3)]
    params = [0.0, 0.25, 0.50, 0.75]
    styles = [:solid, :dash, :dot, :dashdot]

    plots = []
    for (name, id) in problems
        p = plot(; xlabel="Iteration", ylabel="|v(x_k)|",
                 yscale=:log10, legend=:topright, title=name)

        for (j, param) in enumerate(params)
            param_str = replace(@sprintf("%.2f", param), "." => "p")
            hfile = joinpath(hist_dir, "hist_$(id)_param$(param_str).csv")
            isfile(hfile) || continue

            data = readdlm(hfile, ','; header=true)[1]
            iters = Int.(data[:, 1])
            vals  = abs.(data[:, 2])

            plot!(p, iters, vals; label="param=$param", ls=styles[j], lw=1.5)
        end
        push!(plots, p)
    end

    fig = plot(plots...; layout=(1, length(plots)), size=(400*length(plots), 300))
    savefig(fig, output_path)
    println("Saved: $output_path")
end
```
