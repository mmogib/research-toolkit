# includes.jl — Single entry point for all source files
# Usage: include("src/includes.jl") from scripts or REPL at jcode/ directory
#
# Include order matters: each file may depend on files included before it.

# Project root (used by all scripts for results/, logs/, etc.)
const JCODE_ROOT = dirname(@__DIR__)

include("deps.jl")             # 1. Dependencies
include("types.jl")            # 2. SolverResult, IterRecord, make_result
include("io_utils.jl")         # 3. TeeIO, setup_logging, teardown_logging

# Problem domains (include the ones your project uses)
include("problems_nle.jl")     # 4a. Nonlinear equations
# include("problems_cs.jl")    # 4b. Compressed sensing (uncomment if needed)
# include("problems_imgrec.jl")# 4c. Image restoration (uncomment if needed)

# Algorithm components
# include("direction.jl")
# include("linesearch.jl")
include("algorithm.jl")        # 5. Main algorithm(s)
# include("reference_algo.jl") # 6. Comparison algorithms

# Infrastructure
include("benchmark.jl")        # 7. DB layer (open_db, config hash, CRUD)

# ─── DFMethods.jl integration (uncomment if /init-project opted in) ─────────
# Files scaffolded into src/ when DFMethods.jl is selected; loaded after
# benchmark.jl. See ../guides/dfmethods-integration.md for the patterns.
# include("constraints_nle.jl")  # constraint constructors
# include("problems_nle.jl")     # TestProblem registry + 28 problems (if canonical library)
# include("adapter.jl")          # solve_with_alg + retcode mapping
# include("callbacks.jl")        # ProgressUpdateCallback
# include("extras.jl")           # custom DFMethods extensions (directions / line searches / …)
# include("sweep_helpers.jl")    # WorkItem, register_palette, run_sweep
