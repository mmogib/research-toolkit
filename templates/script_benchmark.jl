# ============================================================================
# s45: Multi-Start Benchmark for [AlgorithmName]
# ============================================================================
#
# Goal:   Run [algorithm] on N problems × M starting points
# Output: results/[experiment]/raw.csv, summary.csv
#
# Usage:
#   julia --project=. scripts/s45_benchmark.jl --all              # all problems
#   julia --project=. scripts/s45_benchmark.jl 3-11 --resume      # range, resume
#   julia --project=. scripts/s45_benchmark.jl --summary           # post-process
#   julia --project=. scripts/s45_benchmark.jl --all --verbose     # verbose output
# ============================================================================

# --- Load project code (adapt to your coding style) ---
# Style A (Module):  push!(LOAD_PATH, joinpath(@__DIR__, "..", "src")); using ModuleName
# Style B (Flat):    include(joinpath(@__DIR__, "..", "src", "includes.jl"))
push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))
using ModuleName
using Printf, Random, Dates
using ProgressMeter

# ── Constants ───────────────────────────────────────────────────────────────
const N_STARTS   = 50       # Random starting points per problem
const RNG_SEED   = 42       # Reproducibility
const TUNED_PARAM1 = 1e-4   # Tuned parameter (from OAT/LHS)
const TUNED_PARAM2 = 0.5    # Tuned parameter

const RAW_HEADER = "prob_id,prob_name,n,m,start_idx,start_type,status,iters,f_evals,g_evals,v_final,time_s,F_values"
const SUMMARY_HEADER = "prob_id,prob_name,n,m,n_starts,n_optimal,success_rate,median_iters,median_fevals,median_time,median_v"

# Adaptive tolerance
get_ε(n)       = n >= 50 ? 1e-2 : 1e-4
get_maxiter(n) = n >= 50 ? 10000 : 5000

# Excluded problems (document reasons)
const EXCLUDED = Set{Int}()  # e.g., Set([1, 12, 14])

# ── ARGS Parsing ────────────────────────────────────────────────────────────
flags = filter(a -> startswith(a, "-"), ARGS)
ids   = filter(a -> !startswith(a, "-"), ARGS)

verbose    = "--verbose" in flags
do_resume  = "--resume" in flags
do_summary = "--summary" in flags

if "--all" in flags
    prob_ids = collect(1:54)  # Adjust range
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
    # Default: representative subset
    prob_ids = [1, 5, 15, 24]
end

# Remove excluded problems
filter!(id -> id ∉ EXCLUDED, prob_ids)

# ── Output Setup ────────────────────────────────────────────────────────────
results_dir = joinpath(@__DIR__, "..", "results", "benchmark")
mkpath(results_dir)

raw_csv_path     = joinpath(results_dir, "raw.csv")
summary_csv_path = joinpath(results_dir, "summary.csv")

logpath, tee, logfile = setup_logging("benchmark")

println(tee, "=" ^ 90)
println(tee, "Multi-Start Benchmark")
println(tee, "Problems: $(length(prob_ids)), Starts: $(N_STARTS + 1) (1 default + $N_STARTS random)")
println(tee, "=" ^ 90)

# ── Summary Mode ────────────────────────────────────────────────────────────
if do_summary
    # Read raw CSV → aggregate → write summary CSV
    if !isfile(raw_csv_path)
        println(tee, "ERROR: raw CSV not found: $raw_csv_path")
        teardown_logging(tee, logpath)
        exit(1)
    end

    # Group rows by problem ID
    prob_lines = Dict{Int, Vector{String}}()
    for line in eachline(raw_csv_path)
        startswith(line, "prob_id") && continue
        parts = split(line, ","; limit=2)
        pid = parse(Int, parts[1])
        push!(get!(prob_lines, pid, String[]), line)
    end

    # Print header
    @printf(tee, "\n%-5s %-14s %4s %4s  %8s  %10s  %10s  %10s  %10s\n",
            "ID", "Name", "n", "m", "success", "med_iters", "med_fevals", "med_time", "med_v")
    println(tee, "-" ^ 90)

    # Compute per-problem statistics
    summary_io = open(summary_csv_path, "w")
    println(summary_io, SUMMARY_HEADER)

    for pid in sort(collect(keys(prob_lines)))
        lines = prob_lines[pid]
        # Parse fields, compute statistics...
        # @printf(tee, ...) for console output
        # @printf(summary_io, ...) for CSV
    end

    close(summary_io)
    println(tee, "\nSummary saved to: $summary_csv_path")
    teardown_logging(tee, logpath)
    exit(0)
end

# ── Resume Detection ────────────────────────────────────────────────────────
completed = Set{Int}()

if do_resume && isfile(raw_csv_path)
    prob_counts = Dict{Int, Int}()
    for line in eachline(raw_csv_path)
        startswith(line, "prob_id") && continue
        pid = parse(Int, split(line, ",")[1])
        prob_counts[pid] = get(prob_counts, pid, 0) + 1
    end

    expected = N_STARTS + 1
    for (pid, count) in prob_counts
        if count >= expected
            push!(completed, pid)
        end
    end

    @printf(tee, "Resume: %d/%d problems already done\n",
            length(completed), length(prob_ids))
end

# ── Main Solve Loop ─────────────────────────────────────────────────────────
raw_io = open(raw_csv_path, do_resume ? "a" : "w")
if !do_resume
    println(raw_io, RAW_HEADER)
end

t_script = time()
n_done = 0

for prob_id in prob_ids
    if prob_id in completed
        @printf(tee, "  [SKIP] prob %d (resume)\n", prob_id)
        continue
    end

    prob, F, JF = get_problem(prob_id)
    t_prob = time()

    # Configure
    cfg = AlgorithmConfig(
        # param1 = TUNED_PARAM1,
        # param2 = TUNED_PARAM2,
        ε = get_ε(prob.n),
        maxiter = get_maxiter(prob.n),
        verbose = verbose,
    )

    # Generate starting points
    rng = Random.MersenneTwister(RNG_SEED)
    n_starts_total = N_STARTS + 1
    starts = [(prob.x0, "default")]
    for i in 1:N_STARTS
        x0_rand = rand(rng, prob.n)  # Adjust for feasible set
        push!(starts, (x0_rand, "random"))
    end

    # Counters
    n_ok = 0; n_maxiter = 0; n_lsfail = 0; n_error = 0
    iters_ok = Float64[]

    prog = Progress(n_starts_total;
        desc = @sprintf("  Prob %2d %-14s ", prob_id, prob.name),
        barlen = 30, showspeed = true, enabled = !verbose)

    for (start_idx, (x0, start_type)) in enumerate(starts)
        try
            result = solve(F, JF, x0; cfg=cfg)

            if result.status == :optimal
                n_ok += 1
                push!(iters_ok, result.iterations)
            elseif result.status == :maxiter
                n_maxiter += 1
            else
                n_lsfail += 1
            end

            F_str = join([@sprintf("%.10e", fi) for fi in result.Fx], ";")
            @printf(raw_io, "%d,%s,%d,%d,%d,%s,%s,%d,%d,%d,%.10e,%.6f,%s\n",
                    prob_id, prob.name, prob.n, prob.m,
                    start_idx, start_type, result.status,
                    result.iterations, result.f_evals, result.g_evals,
                    result.stationarity, result.time_seconds, F_str)
            flush(raw_io)

        catch ex
            n_error += 1
            @printf(raw_io, "%d,%s,%d,%d,%d,%s,error,0,0,0,NaN,0.0,\n",
                    prob_id, prob.name, prob.n, prob.m, start_idx, start_type)
            flush(raw_io)
            @printf(logfile, "  [ERROR] prob %d, start %d: %s\n",
                    prob_id, start_idx, sprint(showerror, ex))
        end

        ProgressMeter.update!(prog, start_idx;
            showvalues = [(:optimal, "$n_ok/$start_idx"), (:errors, n_error)])
    end
    finish!(prog)

    prob_elapsed = time() - t_prob
    elapsed_str = prob_elapsed < 60 ? @sprintf("%.0fs", prob_elapsed) :
                  prob_elapsed < 3600 ? @sprintf("%.1fm", prob_elapsed/60) :
                  @sprintf("%.1fh", prob_elapsed/3600)

    @printf(tee, "  → %d/%d optimal, %d maxiter, %d lsfail, %d error  [%s]\n",
            n_ok, n_starts_total, n_maxiter, n_lsfail, n_error, elapsed_str)

    n_done += 1
end

close(raw_io)

total_elapsed = time() - t_script
@printf(tee, "\nComplete: %d problems in %.0fs (%.1f min)\n",
        n_done, total_elapsed, total_elapsed / 60)

teardown_logging(tee, logpath)
