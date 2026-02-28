# includes.jl — Single entry point for all source files
# Usage: include("src/includes.jl") from scripts or REPL at jcode/ directory
#
# Include order matters: each file may depend on files included before it.

include("deps.jl")
include("problems.jl")
include("direction.jl")
include("linesearch.jl")
# include("projection.jl")
include("algorithm.jl")
include("benchmark.jl")
# include("reference_algo.jl")   # Comparison algorithms
