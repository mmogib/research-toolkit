# algorithm.jl — Main algorithm definition (Style B: struct + iterator protocol)

# ── Counters & Trackers ─────────────────────────────────────────────────────

struct Iterationcounter
    count::Base.RefValue{Int}
end
Iterationcounter() = Iterationcounter(Ref(0))
increment(c::Iterationcounter) = (c.count[] += 1)
value(c::Iterationcounter) = c.count[]
reset!(c::Iterationcounter) = (c.count[] = 0)

mutable struct LSTracker
    backtracking_counts::Vector{Int}
    step_sizes::Vector{Float64}
end
LSTracker() = LSTracker(Int[], Float64[])

# ── Presets ──────────────────────────────────────────────────────────────────

const ALGORITHM_PRESETS = Dict{Symbol,NamedTuple}(
    :default    => (;),                                    # Best from tuning
    :paper      => (; ε=1e-6, maxiter=5000),               # Conservative
    :aggressive => (; ε=1e-8, maxiter=10000),              # Tight tolerance
    # :no_feature => (; feature_param=0.0),                # Ablation variant
    # :scale_small => (; ε=1e-6, maxiter=5000),            # n ≤ 10k
    # :scale_large => (; ε=1e-4, maxiter=20000),           # n ≥ 50k
)

# ── Algorithm Struct ─────────────────────────────────────────────────────────

struct MyAlgorithm{TF,TC,TX}
    F::TF                       # Problem function (evaluation-counted)
    C::TC                       # Constraint set (LazySets subtype)
    x0::TX                      # Initial point
    # Parameters
    ε::Float64                  # Convergence tolerance
    maxiter::Int                # Maximum iterations
    # ... add algorithm-specific parameters ...
    # Mutable state (embedded at construction)
    iter_count::Iterationcounter
    f_evals::Iterationcounter
    ls_tracker::LSTracker
end

# ── Outer Constructor (Preset Merging) ───────────────────────────────────────

function MyAlgorithm(F, C; preset=:default, x0=nothing, kwargs...)
    merged = merge(ALGORITHM_PRESETS[preset], NamedTuple(kwargs))
    _build_algorithm(F, C; x0=x0, merged...)
end

function _build_algorithm(F, C;
        x0=nothing,
        ε=1e-6,
        maxiter=5000,
        # ... add all parameters with defaults ...
    )
    # Default initial point
    if x0 === nothing
        x0 = an_element(C)
    end
    n = length(x0)

    # Validation
    @assert ε > 0 "Tolerance must be positive"
    @assert maxiter > 0 "Max iterations must be positive"

    # Wrap F with evaluation counter
    f_counter = Iterationcounter()
    F_counted = x -> (increment(f_counter); F(x))

    return MyAlgorithm(
        F_counted, C, copy(x0),
        ε, maxiter,
        Iterationcounter(), f_counter, LSTracker(),
    )
end

# ── Iterator Protocol ────────────────────────────────────────────────────────

# State tuple: (x_prev, x, d_prev, Fx_prev, k)

function Base.iterate(m::MyAlgorithm)
    x = copy(m.x0)
    Fx = m.F(x)

    # Check if already converged
    residual = norm(Fx)
    if residual < m.ε
        return nothing
    end

    # First direction (e.g., steepest descent)
    d = -Fx  # placeholder

    # First state
    state = (copy(x), x, d, Fx, 1)
    return (x, state)
end

function Base.iterate(m::MyAlgorithm, state)
    x_prev, x, d_prev, Fx_prev, k = state
    increment(m.iter_count)

    if k >= m.maxiter
        return nothing
    end

    # ── Compute direction ──
    Fx = m.F(x)
    d = -Fx  # placeholder: replace with actual direction computation

    # ── Line search ──
    τ = 1.0  # placeholder: replace with actual line search
    # push!(m.ls_tracker.step_sizes, τ)

    # ── Update ──
    x_next = x + τ * d

    # ── Convergence check ──
    residual = norm(m.F(x_next))
    if residual < m.ε
        return nothing
    end

    new_state = (copy(x), x_next, d, Fx, k + 1)
    return (x_next, new_state)
end

Base.IteratorSize(::Type{<:MyAlgorithm}) = Base.SizeUnknown()

# ── Convenience Solve Function ───────────────────────────────────────────────

function solve(m::MyAlgorithm; verbose=false, history=false)
    t0 = time()
    x_final = copy(m.x0)
    converged = false
    k = 0

    hist = history ? Vector{NamedTuple}() : nothing

    for (i, x) in enumerate(m)
        k = i
        x_final = x
        Fx = m.F(x)
        residual = norm(Fx)

        if verbose && (k % 100 == 0 || k <= 5)
            @printf("  k=%5d: ‖F(x)‖=%.6e\n", k, residual)
        end

        if history
            push!(hist, (iter=k, residual=residual))
        end
    end

    # Check final state
    Fx_final = m.F(x_final)
    residual = norm(Fx_final)
    converged = residual < m.ε
    elapsed = time() - t0

    if verbose
        status_str = converged ? "CONVERGED" : "MAX_ITER"
        @printf("  %s: k=%d, ‖F(x)‖=%.6e, f_evals=%d, time=%.3fs\n",
                status_str, k, residual, value(m.f_evals), elapsed)
    end

    return (
        x = x_final,
        Fx = Fx_final,
        iterations = k,
        converged = converged,
        residual = residual,
        f_evals = value(m.f_evals),
        time_seconds = elapsed,
        history = hist,
    )
end
