# problems_nle.jl — Nonlinear equations test problems, projections, starting points
#
# Problem domain: find x* such that F(x*) = 0 and x* in C
# where F: R^n -> R^n is a (monotone) mapping and C is a closed convex set.
#
# Interface contract (used by benchmark.jl, scripts, and DB layer):
#   get_problem(id)           -> TestProblem
#   get_initial_points(n, id) -> Vector{Tuple{String, Vector{Float64}}}
#   PROBLEM_IDS               = [1, 2, ...]
#
# Add your own problems below the examples. Keep projections with problems.

# ============================================================================
# Problem Struct
# ============================================================================

"""
    TestProblem

Container for a test problem. Every problem must provide:
  - `F`:    the mapping F: R^n -> R^n
  - `proj`: projection onto constraint set C
  - `name`: human-readable label (used in DB `problem` column)
"""
struct TestProblem
    id::Int
    name::String
    F::Function              # x::Vector{Float64} -> Vector{Float64}
    proj::Function           # x::Vector{Float64} -> Vector{Float64}
    source::String           # citation or "custom"
end

# ============================================================================
# Projection Operators
# ============================================================================

"""Project onto R^n_+ = {x : x >= 0}."""
proj_nonneg(x) = max.(x, 0.0)

"""Project onto box [a, b]^n."""
proj_box(x, a::Real, b::Real) = clamp.(x, a, b)

"""Project onto unit box [0, 1]^n."""
proj_unit_box(x) = clamp.(x, 0.0, 1.0)

"""Project onto box [lower, upper] (element-wise bounds)."""
function proj_bounds(x, lower::Vector{Float64}, upper::Vector{Float64})
    return clamp.(x, lower, upper)
end

# --- Add project-specific projections below (simplices, balls, etc.) --------
# """Project onto l2 ball of radius r centered at c."""
# function proj_ball(x, c::Vector{Float64}, r::Real)
#     d = x - c
#     nd = norm(d)
#     return nd <= r ? x : c + r * d / nd
# end

# ============================================================================
# Test Problems
# ============================================================================
#
# Each problem is a function: (n::Int) -> TestProblem
# The dimension `n` is an argument so the same problem works at any scale.
#
# Naming: P1, P2, ... — matches the DB `problem` column as "P1", "P2", etc.

# ── Example: F(x) = 2x - sin(x), C = R^n_+ ────────────────────────────────
function _F1(x)
    return 2.0 .* x .- sin.(x)
end

# ── Example: F(x) = exp(x) - 1, C = R^n_+ ─────────────────────────────────
function _F2(x)
    return exp.(x) .- 1.0
end

# --- Add your problems here ------------------------------------------------
# function _F3(x)
#     ...
# end

# ============================================================================
# Problem Registry
# ============================================================================

"""All problem IDs. Update when adding/removing problems."""
const PROBLEM_IDS = [1, 2]  # extend as needed

"""
    get_problem(id::Int) -> TestProblem

Look up a test problem by ID. Add entries as you define new problems.
"""
function get_problem(id::Int)
    if id == 1
        return TestProblem(1, "ExpSin", _F1, proj_nonneg,
                           "Adapted from La Cruz & Raydan (2003)")
    elseif id == 2
        return TestProblem(2, "Exponential", _F2, proj_nonneg,
                           "Standard exponential test")
    # elseif id == 3
    #     return TestProblem(3, "YourProblem", _F3, proj_nonneg, "source")
    else
        error("Unknown problem ID: $id")
    end
end

# ============================================================================
# Initial / Starting Points
# ============================================================================

"""
    get_initial_points(n::Int, prob_id::Int) -> Vector{Tuple{String, Vector{Float64}}}

Generate labeled starting points for problem `prob_id` at dimension `n`.
Returns vector of (label, x0) pairs. Labels are used in the DB `init_point` column.

Default: 10 stratified points covering zero, constant, scaled, decaying, ramp.
Override per-problem if specific points are needed.
"""
function get_initial_points(n::Int, prob_id::Int)
    points = Tuple{String, Vector{Float64}}[]

    push!(points, ("v1",  zeros(n)))                              # zero
    push!(points, ("v2",  fill(0.5, n)))                          # moderate
    push!(points, ("v3",  ones(n)))                               # unit
    push!(points, ("v4",  fill(2.0, n)))                          # far
    push!(points, ("v5",  fill(1/n, n)))                          # small constant
    push!(points, ("v6",  [1.0/k for k in 1:n]))                 # harmonic decay
    push!(points, ("v7",  [(k-1)/(n-1) for k in 1:n]))           # ramp 0 to 1
    push!(points, ("v8",  [k/n for k in 1:n]))                   # ramp 1/n to 1
    push!(points, ("v9",  [1.0/3.0^k for k in 1:n]))             # exponential decay
    push!(points, ("v10", fill(1.1, n)))                          # above unit

    # ── Project into feasible set if needed ──────────────────────────────
    prob = get_problem(prob_id)
    for i in eachindex(points)
        label, x0 = points[i]
        x0_feas = ensure_feasible(prob.proj, x0)
        if x0_feas !== x0
            points[i] = (label, x0_feas)
        end
    end

    return points
end

"""
    ensure_feasible(proj, x0) -> Vector{Float64}

Project x0 into the feasible set if it is not already feasible.
"""
function ensure_feasible(proj::Function, x0::Vector{Float64})
    x_proj = proj(x0)
    # Check if projection changed the point (simple heuristic)
    if norm(x_proj - x0) > 1e-12
        return x_proj
    end
    return x0
end
