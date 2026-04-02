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
