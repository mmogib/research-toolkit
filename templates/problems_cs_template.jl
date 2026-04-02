# problems_cs.jl — Compressed sensing problem constructors
#
# Problem domain: recover a sparse signal x* from measurements b = A*x* + noise
# Reformulated as a monotone nonlinear complementarity problem (NCP):
#   F(z) = min{z, H*z + c},  z >= 0
# where z = (u; v), x = u - v (variable splitting), and H = A^T * A.
#
# Interface:
#   make_cs_problem(; n, k, m, sigma, seed) -> (prob::TestProblem, x_true, metrics_fn)
#   cs_metrics(x_recovered, x_true)         -> (mse, snr_db)

# ============================================================================
# Problem Constructor
# ============================================================================

"""
    make_cs_problem(; n, k, m, sigma, seed) -> (prob, x_true, metrics_fn)

Build a compressed sensing problem with NCP reformulation.

# Arguments
- `n`:     signal length
- `k`:     sparsity (number of nonzero entries)
- `m`:     number of measurements (m < n for underdetermined)
- `sigma`: noise standard deviation (0 for noiseless)
- `seed`:  RNG seed for reproducibility

# Returns
- `prob`:       TestProblem with F (NCP mapping) and proj (R^{2n}_+)
- `x_true`:     ground truth sparse signal
- `metrics_fn`: function (z -> NamedTuple) to compute recovery quality

# NCP reformulation (Figueiredo et al. 2007)
Variable splitting: x = u - v, z = (u; v) >= 0
  H = [A^T A,  -A^T A; -A^T A,  A^T A]  (2n x 2n)
  c = tau*e + [-A^T b; A^T b]
  F(z) = min.(z, H*z + c)  (element-wise min)
"""
function make_cs_problem(; n::Int=256, k::Int=20, m::Int=128,
                           sigma::Float64=0.01, seed::Int=42,
                           tau_factor::Float64=0.001)
    rng = Random.Xoshiro(seed)

    # ── Generate sparse signal ───────────────────────────────────────────
    x_true = zeros(n)
    support = randperm(rng, n)[1:k]
    x_true[support] = randn(rng, k)

    # ── Sensing matrix ───────────────────────────────────────────────────
    A = randn(rng, m, n) / sqrt(m)

    # ── Measurements ─────────────────────────────────────────────────────
    b = A * x_true + sigma * randn(rng, m)

    # ── NCP setup ────────────────────────────────────────────────────────
    AtA = A' * A
    Atb = A' * b
    tau = tau_factor * norm(Atb, Inf)

    # Precompute for F evaluation (avoid reallocation)
    _Hz = zeros(2n)
    _c = vcat(tau .- Atb, tau .+ Atb)

    function F_ncp(z)
        u = @view z[1:n]
        v = @view z[n+1:2n]
        x_diff = u - v
        Ax = AtA * x_diff

        _Hz[1:n]     .= Ax .+ _c[1:n]
        _Hz[n+1:2n]  .= .-Ax .+ _c[n+1:2n]
        return min.(z, _Hz)
    end

    proj_nn(z) = max.(z, 0.0)

    # Starting point: z0 = (max(A^T b, 0); max(-A^T b, 0))
    z0 = vcat(max.(Atb, 0.0), max.(.-Atb, 0.0))

    prob = TestProblem(0, "CS_n$(n)_k$(k)_m$(m)", F_ncp, proj_nn,
                       "Compressed sensing NCP")

    # ── Metrics function ─────────────────────────────────────────────────
    function metrics_fn(z)
        x_rec = z[1:n] - z[n+1:2n]
        return cs_metrics(x_rec, x_true)
    end

    return (prob, x_true, metrics_fn)
end

# ============================================================================
# Recovery Metrics
# ============================================================================

"""
    cs_metrics(x_recovered, x_true) -> (mse, snr_db)

Compute recovery quality metrics.
- `mse`:    mean squared error
- `snr_db`: signal-to-noise ratio in dB
"""
function cs_metrics(x_rec::Vector{Float64}, x_true::Vector{Float64})
    err = x_rec - x_true
    mse = dot(err, err) / length(err)
    sig_power = dot(x_true, x_true)
    snr_db = sig_power > 0 ? 10 * log10(sig_power / dot(err, err)) : -Inf
    return (mse=mse, snr_db=snr_db)
end
