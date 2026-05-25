# extras.jl — Shared direction and line-search types used by benchmark scripts.
#
# These are NOT part of the registered `DFMethods.jl` library — they are
# additional types defined here for cross-script reuse (s05, s10, s30, …).
# Each direction subtypes `AbstractSearchDirection` and adds a method on
# `DFMethods.direction!`; each line search subtypes
# `LineSearch.AbstractLineSearchAlgorithm` and implements the
# `CommonSolve.init` / `CommonSolve.solve!` contract.
#
# Contents:
#   - `MPRPL_Direction`              (Dai, Chen, Wen — AMC 2015, eq. 4.1)
#   - `GCGPM_Direction`              (Hamiss, Alshahrani, Syed — eqs. 18–21)
#   - `GMOPCGM_Direction`            (Hamiss, Alshahrani, Syed — eqs. 11–14)
#   - `SaturatedResidualBacktrack`   (was LSIII;  γ = ‖F‖ / (1 + ‖F‖))
#   - `CappedResidualBacktrack`      (was LSV;    γ = min(1, ‖F‖))
#   - `FixedClampedBacktrack`        (was LSVI;   γ = clamp(‖F‖, lo, hi))

# ============================================================================
# MPRPL — Modified PRP-Liu CG direction (Dai 2015, eq. 4.1)
# ============================================================================
#
# Formula (k ≥ 1):
#   y_{k-1}  = F_k - F_{k-1}
#   β_k^PRP = F_k' y_{k-1} / ‖F_{k-1}‖²
#   d_k     = -(1 + β_k^PRP · F_k' d_{k-1} / ‖F_k‖²) F_k + β_k^PRP d_{k-1}

struct MPRPL_Direction <: AbstractSearchDirection end

function DFMethods.direction!(d, ::MPRPL_Direction, ctx)
    Fw, Fw_prev, d_prev, k = ctx.Fw, ctx.Fw_prev, ctx.d_prev, ctx.k
    if k == 0
        @. d = -Fw
        return d
    end
    Fw_y   = 0.0
    Fwm_sq = 0.0
    Fw_d   = 0.0
    Fw_sq  = 0.0
    @inbounds for i in eachindex(Fw)
        yi      = Fw[i] - Fw_prev[i]
        Fw_y   += Fw[i] * yi
        Fwm_sq += Fw_prev[i]^2
        Fw_d   += Fw[i] * d_prev[i]
        Fw_sq  += Fw[i]^2
    end
    β_PRP   = Fw_y / max(Fwm_sq, eps())
    coeff_F = -(1.0 + β_PRP * Fw_d / max(Fw_sq, eps()))
    @inbounds @simd for i in eachindex(Fw)
        d[i] = coeff_F * Fw[i] + β_PRP * d_prev[i]
    end
    return d
end

# ============================================================================
# GCGPM — Generalized Conjugate Gradient Projection Method
# (Hamiss, Alshahrani, Syed — ELSCAM-S-26-01242, eqs. 18–21)
# ============================================================================
#
# Formula (k ≥ 1):
#   y_{k-1}  = F_k - F_{k-1}
#   r_k      = 1 + max(0, -F_k' p_{k-1} / (y_{k-1}' p_{k-1}))
#   w_{k-1}  = y_{k-1} + r_k · p_{k-1}
#   a_k      = F_k' p_{k-1} / (p_{k-1}' w_{k-1})
#   λ_k      = clamp(max{‖w‖²/(p'w), (p'w)/‖p‖²}, α_min, α_max)
#   θ̂_k     = F_k' w_{k-1} / (p_{k-1}' w_{k-1})
#               - λ_k · ‖w_{k-1}‖² · F_k' p_{k-1} / (p_{k-1}' w_{k-1})²
#   d_k      = -λ_k F_k + θ̂_k p_{k-1} + τ · a_k · w_{k-1}

Base.@kwdef struct GCGPM_Direction <: AbstractSearchDirection
    α_min::Float64 = 0.55      # spectral lower bound (source default)
    α_max::Float64 = 4.9       # spectral upper bound
    τ::Float64     = 0.001     # Dai–Liao parameter
end

function DFMethods.direction!(d, rule::GCGPM_Direction, ctx)
    Fw, Fw_prev, d_prev, k = ctx.Fw, ctx.Fw_prev, ctx.d_prev, ctx.k
    if k == 0
        @. d = -Fw
        return d
    end

    # Pass 1: dot products depending only on (Fw, Fw_prev, d_prev)
    G_p = 0.0    # F_k' p_{k-1}
    pp  = 0.0    # ‖p_{k-1}‖²
    y_p = 0.0    # y_{k-1}' p_{k-1}
    @inbounds for i in eachindex(Fw)
        yi   = Fw[i] - Fw_prev[i]
        G_p += Fw[i] * d_prev[i]
        pp  += d_prev[i] * d_prev[i]
        y_p += yi * d_prev[i]
    end

    r_k = 1.0 + max(0.0, -G_p / (abs(y_p) < eps() ? eps() : y_p))

    # Pass 2: dot products involving w_{k-1} = y_{k-1} + r_k · p_{k-1}
    wp = 0.0
    ww = 0.0
    Gw = 0.0
    @inbounds for i in eachindex(Fw)
        yi = Fw[i] - Fw_prev[i]
        wi = yi + r_k * d_prev[i]
        wp += wi * d_prev[i]
        ww += wi * wi
        Gw += Fw[i] * wi
    end

    wp_safe = abs(wp) < eps() ? sign(wp) * eps() : wp
    pp_safe = max(pp, eps())

    # Barzilai–Borwein spectral λ_k
    spec1 = ww / wp_safe
    spec2 = wp_safe / pp_safe
    λ_k   = clamp(max(spec1, spec2), rule.α_min, rule.α_max)

    θ_hat = (Gw / wp_safe) - λ_k * (ww / wp_safe) * (G_p / wp_safe)
    a_k   = G_p / wp_safe

    τ_r = rule.τ
    @inbounds @simd for i in eachindex(Fw)
        yi = Fw[i] - Fw_prev[i]
        wi = yi + r_k * d_prev[i]
        d[i] = -λ_k * Fw[i] + θ_hat * d_prev[i] + τ_r * a_k * wi
    end
    return d
end

# ============================================================================
# GMOPCGM — Generalized Modified Optimal Perry CG Method
# (Hamiss, Alshahrani, Syed — ELSCAM-S-26-01242, eqs. 11–14)
# ============================================================================
#
# Uses the previous step displacement s_{k-1} = α_{k-1} · d_{k-1}; reads
# `α_prev` from the v0.2 `ctx` namedtuple.
#
# Formula (k ≥ 1):
#   s_{k-1}  = α_prev · d_{k-1}
#   y_{k-1}  = F_k - F_{k-1}
#   v_{k-1}  = y_{k-1} + τ · s_{k-1}
#   λ_k      = clamp(max{‖s‖²/(s'v), (s'v)/‖v‖²}, α_min, α_max)
#   t_k^*    = λ_k · (s'v) / ‖s‖²
#   θ_k^G   = (v - t_k^* · s)' F_k / (p_{k-1}' v)
#   M_k      = λ_k + θ_k^G · (F_k' p_{k-1}) / ‖F_k‖²
#   d_k      = -M_k · F_k + θ_k^G · p_{k-1}
#
# Restarts to `d_k = -F_k` if any denominator is numerically degenerate
# (standard CG-projection safety fallback).

Base.@kwdef struct GMOPCGM_Direction <: AbstractSearchDirection
    α_min::Float64 = 0.1      # source default
    α_max::Float64 = 2.0      # source default
    τ::Float64     = 1.0      # source default
end

function DFMethods.direction!(d, rule::GMOPCGM_Direction, ctx)
    Fw, Fw_prev, d_prev, k, α_prev =
        ctx.Fw, ctx.Fw_prev, ctx.d_prev, ctx.k, ctx.α_prev
    if k == 0 || α_prev <= 0
        @. d = -Fw
        return d
    end

    G_p   = 0.0   # F_k' p_{k-1}
    pp    = 0.0   # ‖p_{k-1}‖²
    y_p   = 0.0   # y_{k-1}' p_{k-1}
    Fw_y  = 0.0   # F_k' y_{k-1}
    yy    = 0.0   # ‖y_{k-1}‖²
    Fw_sq = 0.0   # ‖F_k‖²
    @inbounds for i in eachindex(Fw)
        yi      = Fw[i] - Fw_prev[i]
        G_p    += Fw[i] * d_prev[i]
        pp     += d_prev[i] * d_prev[i]
        y_p    += yi * d_prev[i]
        Fw_y   += Fw[i] * yi
        yy     += yi * yi
        Fw_sq  += Fw[i] * Fw[i]
    end

    τ = rule.τ
    α = α_prev

    ss = α * α * pp                              # ‖s‖²
    sv = α * y_p + τ * ss                        # s'v
    pv = y_p + τ * α * pp                        # p'v
    vv = yy + 2.0 * τ * α * y_p + τ * τ * ss     # ‖v‖²

    # Safety: restart to steepest descent if any denominator vanishes.
    if ss < eps() || abs(sv) < eps() || abs(pv) < eps() || vv < eps()
        @. d = -Fw
        return d
    end

    # Spectral λ_k via Barzilai–Borwein bracket
    spec1 = ss / sv
    spec2 = sv / vv
    λ_k   = clamp(max(spec1, spec2), rule.α_min, rule.α_max)

    # t_k^*, θ_k^G, M_k
    t_star = λ_k * sv / ss
    Fw_v   = Fw_y + τ * α * G_p                  # F_k' v
    Fw_s   = α * G_p                             # F_k' s
    θ_G    = (Fw_v - t_star * Fw_s) / pv

    Fw_sq_safe = max(Fw_sq, eps())
    M_k = λ_k + θ_G * G_p / Fw_sq_safe

    # d_k = -M_k F_k + θ_G p_{k-1}
    @inbounds @simd for i in eachindex(Fw)
        d[i] = -M_k * Fw[i] + θ_G * d_prev[i]
    end
    return d
end

# ============================================================================
# User line searches (v0.2-port of v0.1 LSIII / LSV / LSVI)
# ============================================================================
#
# DFMethods.jl v0.2 ships only three built-in backtracking variants
# (`ConstantBacktrack`, `ResidualNormBacktrack`, `AdaptiveClampedBacktrack`).
# The s30 benchmark sweep was designed around five — adding `LSIII`, `LSV`,
# `LSVI` from the v0.1 family. The three are recovered here as user line
# searches following the SciML `LineSearch.AbstractLineSearchAlgorithm`
# contract, so the s30 4 × 5 = 20 method matrix can re-run on the v0.2 API.
#
# γ_k formulas (Ibrahim 2026 §2.1, v0.1 family):
#   SaturatedResidualBacktrack  γ = ‖F(z)‖ / (1 + ‖F(z)‖)   bounded in (0, 1)
#   CappedResidualBacktrack     γ = min(1, ‖F(z)‖)          caps at 1
#   FixedClampedBacktrack       γ = clamp(‖F(z)‖, lo, hi)   fixed bracket
#
# (`AdaptiveClampedBacktrack` in the library is the LSVII analogue — same
# clamp form but with an adaptive upper bound `Δ`.)

"""
    SaturatedResidualBacktrack(; σ=0.01, ρ=0.6, maxbt=50)

Was `LSIII` in v0.1. `γ_k = ‖F(z_k)‖ / (1 + ‖F(z_k)‖)`.
"""
Base.@kwdef struct SaturatedResidualBacktrack <: LineSearch.AbstractLineSearchAlgorithm
    σ::Float64 = 0.01
    ρ::Float64 = 0.6
    maxbt::Int = 50
end

"""
    CappedResidualBacktrack(; σ=0.01, ρ=0.6, maxbt=50)

Was `LSV` in v0.1. `γ_k = min(1, ‖F(z_k)‖)`.
"""
Base.@kwdef struct CappedResidualBacktrack <: LineSearch.AbstractLineSearchAlgorithm
    σ::Float64 = 0.01
    ρ::Float64 = 0.6
    maxbt::Int = 50
end

"""
    FixedClampedBacktrack(; σ=0.01, ρ=0.6, lo=0.001, hi=0.6, maxbt=50)

Was `LSVI` in v0.1. `γ_k = clamp(‖F(z_k)‖, lo, hi)` with **fixed** bracket
(contrast: the library's `AdaptiveClampedBacktrack` has an adaptive upper
bound `Δ` and was the v0.1 `LSVII`).

Bracket defaults `(lo=0.001, hi=0.6)` match the reference implementation
(`mmogib/UIDFPA.jl/src/linesearchs.jl::LSVI`, η=0.001, ξ=0.6) used for the
Ibrahim 2026 paper sweep. The paper itself (eq. 6) only constrains
`0 ≤ η̄ ≪ η` and pins no concrete values.
"""
Base.@kwdef struct FixedClampedBacktrack <: LineSearch.AbstractLineSearchAlgorithm
    σ::Float64 = 0.01
    ρ::Float64 = 0.6
    lo::Float64 = 0.001
    hi::Float64 = 0.6
    maxbt::Int = 50
end

"""
    LSPower(; σ=0.01, ρ=0.6, p=0.5, maxbt=50)

Fractional-power demo line search: `γ_k = ‖F(z_k)‖^p`. Interpolates
between [`ConstantBacktrack`](@ref) (`p = 0`) and
[`ResidualNormBacktrack`](@ref) (`p = 1`). Used by `s05_extending.jl` as
a "custom line search" example for benchmarking. Not shipped in the
library.
"""
Base.@kwdef struct LSPower <: LineSearch.AbstractLineSearchAlgorithm
    σ::Float64 = 0.01
    ρ::Float64 = 0.6
    p::Float64 = 0.5
    maxbt::Int = 50
end

const _ExtrasBacktrackAlg = Union{SaturatedResidualBacktrack,
                                   CappedResidualBacktrack,
                                   FixedClampedBacktrack,
                                   LSPower}

mutable struct _ExtrasBacktrackCache{F, Alg<:_ExtrasBacktrackAlg} <: LineSearch.AbstractLineSearchCache
    F::F
    alg::Alg
    z_cache::Vector{Float64}
    fu_cache::Vector{Float64}
    n_evals::Int
end

# γ_k dispatched per algorithm type
_γ_extras(::SaturatedResidualBacktrack, fu) = (n = sqrt(sum(abs2, fu)); n / (1.0 + n))
_γ_extras(::CappedResidualBacktrack,    fu) = min(1.0, sqrt(sum(abs2, fu)))
_γ_extras(alg::FixedClampedBacktrack,   fu) = clamp(sqrt(sum(abs2, fu)), alg.lo, alg.hi)
_γ_extras(alg::LSPower,                 fu) = sqrt(sum(abs2, fu))^alg.p

function _wrap_F_extras(prob::SciMLBase.NonlinearProblem)
    f, p = prob.f, prob.p
    if SciMLBase.isinplace(f)
        return (out, x) -> (f(out, x, p); nothing)
    else
        return (out, x) -> (val = f(x, p); copyto!(out, val); nothing)
    end
end

function CommonSolve.init(prob::SciMLBase.NonlinearProblem,
                          alg::_ExtrasBacktrackAlg, fu, u;
                          stats = nothing, kwargs...)
    F = _wrap_F_extras(prob)
    n = length(u)
    return _ExtrasBacktrackCache(F, alg,
                                  Vector{Float64}(undef, n),
                                  Vector{Float64}(undef, n),
                                  0)
end

function CommonSolve.solve!(cache::_ExtrasBacktrackCache,
                             u::AbstractVector, du::AbstractVector)
    σ, ρ, maxbt = cache.alg.σ, cache.alg.ρ, cache.alg.maxbt
    cache.n_evals = 0

    d_norm_sq = 0.0
    @inbounds for j in eachindex(du)
        d_norm_sq += du[j] * du[j]
    end

    α = 1.0
    for _ in 0:maxbt
        @inbounds @simd for j in eachindex(u)
            cache.z_cache[j] = u[j] + α * du[j]
        end
        cache.F(cache.fu_cache, cache.z_cache)
        cache.n_evals += 1

        lhs = 0.0
        @inbounds for j in eachindex(du)
            lhs -= cache.fu_cache[j] * du[j]
        end

        γ   = _γ_extras(cache.alg, cache.fu_cache)
        rhs = σ * α * γ * d_norm_sq

        if lhs >= rhs
            return LineSearch.LineSearchSolution(α, SciMLBase.ReturnCode.Success)
        end
        α *= ρ
    end
    return LineSearch.LineSearchSolution(α, SciMLBase.ReturnCode.Failure)
end

# ============================================================================
# AffineResidualBacktrack — LSIV from Ibrahim 2026 (Remark 2.1 (iv), eq. 8)
# ============================================================================
#
# γ_k = τ_k + (1 − τ_k) · ‖F(z_k)‖,  with τ_k from a deterministic
# damped-Fibonacci-mean sequence (NOT a tunable scalar):
#
#     b[1] = 1.0
#     b[2] = 0.5
#     b[i] = 0.5 · (b[i-2] + b[i-1])     for i ≥ 3
#     τ_k  = b[k+1]                      (reference shifts: λ = b[2:end])
#
# The sequence is bounded in [0.5, 1.0] and converges to 2/3, satisfying
# the paper's `τ_k ∈ [τ_min, τ_max] ⊂ (0,1]` requirement (Lemma 3.4 (ii)).
#
# Because τ_k depends on the *outer-solver iteration index* and the
# LineSearch.solve! API doesn't surface k, we maintain our own per-solve
# counter in the cache and pre-compute the τ_table on init.
#
# Reference: mmogib/UIDFPA.jl src/linesearchs.jl::LSIV.

"""
    AffineResidualBacktrack(; σ=0.01, ρ=0.6, maxbt=50, max_iters=2000)

Was `LSIV` in Ibrahim 2026. Convex-combination
`γ_k = τ_k + (1 − τ_k) · ‖F(z_k)‖` where `τ_k` is the damped Fibonacci-mean
sequence (bounded in [0.5, 1.0], → 2/3). `max_iters` sizes the precomputed
τ_table and should equal (or exceed) the outer-solver `maxiters`; beyond
the table length the last computed τ is reused (defensive clamp).
"""
Base.@kwdef struct AffineResidualBacktrack <: LineSearch.AbstractLineSearchAlgorithm
    σ::Float64       = 0.01
    ρ::Float64       = 0.6
    maxbt::Int       = 50
    max_iters::Int   = 2000
end

# Precompute the damped-Fibonacci-mean sequence b[1..n+1] and return the
# tail b[2:end] (paper's λ-indexing, so τ_k = result[k] for k = 1, 2, ...).
function _build_tau_table(max_iters::Int)
    n = max_iters + 1
    b = Vector{Float64}(undef, n)
    b[1] = 1.0
    n >= 2 && (b[2] = 0.5)
    for i in 3:n
        b[i] = 0.5 * (b[i-2] + b[i-1])
    end
    return b[2:end]   # length == max_iters
end

mutable struct AffineResidualBacktrackCache{F} <: LineSearch.AbstractLineSearchCache
    F::F
    alg::AffineResidualBacktrack
    z_cache::Vector{Float64}
    fu_cache::Vector{Float64}
    τ_table::Vector{Float64}
    k::Int            # 1-based outer-iter counter; incremented on each solve! call
    n_evals::Int
end

function CommonSolve.init(prob::SciMLBase.NonlinearProblem,
                          alg::AffineResidualBacktrack, fu, u;
                          stats = nothing, kwargs...)
    F = _wrap_F_extras(prob)
    n = length(u)
    return AffineResidualBacktrackCache(F, alg,
        Vector{Float64}(undef, n),
        Vector{Float64}(undef, n),
        _build_tau_table(alg.max_iters),
        0,
        0,
    )
end

function CommonSolve.solve!(cache::AffineResidualBacktrackCache,
                             u::AbstractVector, du::AbstractVector)
    σ, ρ, maxbt = cache.alg.σ, cache.alg.ρ, cache.alg.maxbt
    cache.n_evals = 0
    cache.k += 1
    # Defensive clamp: if the outer solver exceeds max_iters, reuse the last τ.
    k_idx = min(cache.k, length(cache.τ_table))
    τ_k = cache.τ_table[k_idx]

    d_norm_sq = 0.0
    @inbounds for j in eachindex(du)
        d_norm_sq += du[j] * du[j]
    end

    α = 1.0
    for _ in 0:maxbt
        @inbounds @simd for j in eachindex(u)
            cache.z_cache[j] = u[j] + α * du[j]
        end
        cache.F(cache.fu_cache, cache.z_cache)
        cache.n_evals += 1

        lhs = 0.0
        @inbounds for j in eachindex(du)
            lhs -= cache.fu_cache[j] * du[j]
        end

        # γ_k = τ_k + (1 - τ_k) · ‖F(z)‖
        norm_F = sqrt(sum(abs2, cache.fu_cache))
        γ   = τ_k + (1.0 - τ_k) * norm_F
        rhs = σ * α * γ * d_norm_sq

        if lhs >= rhs
            return LineSearch.LineSearchSolution(α, SciMLBase.ReturnCode.Success)
        end
        α *= ρ
    end
    return LineSearch.LineSearchSolution(α, SciMLBase.ReturnCode.Failure)
end
