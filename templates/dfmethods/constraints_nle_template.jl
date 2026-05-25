# constraints_nle.jl — Constraint set constructors for NLE problem registry
#
# DFMethods.jl built-in constraint set types used here:
#   - BoxSet(lb, ub)                : componentwise a ≤ x_i ≤ b
#   - HalfSpace(a, c)               : single linear  a' x ≤ c
#   - CappedBox(a, b, c)            : box ∩ single linear (built-in fast path)
#   - Intersection(X1, X2; ...)     : X1 ∩ X2 via Dykstra (any two convex sets)
#   - RealSpace()                   : unconstrained
#   - UserSet(proj!)                : anything else; user supplies in-place project!
#
# All constructors below are lazy: they accept the problem dimension n and
# return a freshly-built AbstractConstraintSet. Used by problems_nle.jl's
# TestProblem.set_factory closures.
#
# Add new constraint factories to this file as your project grows.

# Ω(a, b, c) = {x : a ≤ x_i ≤ b, Σ x_i ≤ c}  — direct CappedBox built-in
_omega(a::Real, b::Real, c::Real) = CappedBox(Float64(a), Float64(b), Float64(c))

# {x : a ≤ x_i ≤ b}  — BoxSet with possibly-Inf bounds (element-type generic since DFMethods v0.3.0)
_box(a::Real, b::Real, n::Int) =
    BoxSet(fill(Float64(a), n), fill(Float64(b), n))

# {x : x_i ≥ a, Σ x_i ≤ c}  — BoxSet(a, +Inf) ∩ HalfSpace(ones, c) via Dykstra
_box_and_halfspace(a::Real, c::Real, n::Int) =
    Intersection(_box(a, Inf, n), HalfSpace(ones(n), Float64(c));
                 maxiter = 500, tol = 1e-12)
