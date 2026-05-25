# problems_logreg.jl — Regularized logistic regression as a constrained
# monotone equation, for benchmarking derivative-free projection methods.
#
# Formulation:
#   min_{x ∈ Γ}  f(x) = (1/N) Σ_i log(1 + exp(-b_i · a_i^T x)) + (μ/2) ||x||^2
#   ψ(x) = ∇f(x) = -(1/N) Σ_i b_i a_i / (1 + exp(b_i · a_i^T x)) + μ x
#   Γ = [-C, C]^n   (box constraint)
#
# ψ = ∇f is monotone (f is μ-strongly convex), so ψ(x) = 0 on Γ has a unique
# solution.
#
# Reference: ELSCAM-S-26-01242 (section 7 — Application to regularized
# logistic regression). PDF available in ../refs/.
#
# Adapted from MS_TwoGeneralizedDFM/jcode/src/logreg.jl.

# ============================================================================
# CSV loader (LIBSVM-style data pre-converted to CSV)
# ============================================================================

"""
    load_libsvm_csv(path::String) -> (A::Matrix{Float64}, b::Vector{Float64})

Load a CSV produced from a LIBSVM-format dataset. Expected format:
first column `label` ∈ {-1, +1}, remaining columns are features.
"""
function load_libsvm_csv(path::String)
    df = CSV.read(path, DataFrame)
    b = Float64.(df.label)
    A = Matrix{Float64}(df[:, 2:end])
    return A, b
end

# ============================================================================
# Feature normalization (in place)
# ============================================================================

"""
    normalize_features!(A) -> A

Standardize each column of `A` to zero mean and unit (uncorrected) variance.
Columns with near-zero variance are zeroed out.
"""
function normalize_features!(A::Matrix{Float64})
    _N, n = size(A)
    for j in 1:n
        col = @view A[:, j]
        μ = mean(col)
        σ = std(col; corrected=false)
        if σ > 1e-12
            col .= (col .- μ) ./ σ
        else
            col .= 0.0
        end
    end
    return A
end

# ============================================================================
# Numerically stable 1/(1 + exp(t)) for vectors
# ============================================================================

function _inv_logistic!(s::Vector{Float64}, t::Vector{Float64})
    @inbounds for i in eachindex(t)
        ti = t[i]
        if ti >= 0
            e = exp(-ti)
            s[i] = e / (1.0 + e)
        else
            e = exp(ti)
            s[i] = 1.0 / (1.0 + e)
        end
    end
    return s
end

# ============================================================================
# Problem Builder
# ============================================================================

"""
    make_logreg_problem(A, b; mu=0.1, C=10.0) -> (TestProblem, n)

Build a regularized-logistic-regression problem in monotone-equation form.

# Arguments
- `A::Matrix{Float64}`: N × n feature matrix (rows = samples).
- `b::Vector{Float64}`: N-vector of labels in {-1, +1}.
- `mu::Float64=0.1`:    ℓ²-regularization strength (must be positive for monotonicity).
- `C::Float64=10.0`:    box bound for the constraint set Γ = [-C, C]^n.

# Returns
- `TestProblem` with `F = ψ` (gradient mapping) and `proj` (box projection).
- `n::Int`: parameter dimension (number of features).
"""
function make_logreg_problem(A::Matrix{Float64}, b::Vector{Float64};
                              mu::Float64=0.1, C::Float64=10.0)
    N, n = size(A)
    inv_N = 1.0 / N

    bA = b .* A                          # N × n: rows are b_i a_i^T

    _bAx = Vector{Float64}(undef, N)
    _s   = Vector{Float64}(undef, N)

    function ψ(x::Vector{Float64})
        mul!(_bAx, bA, x)                # _bAx[i] = b_i a_i^T x
        _inv_logistic!(_s, _bAx)         # _s[i]   = 1/(1 + exp(b_i a_i^T x))
        return -inv_N .* (bA' * _s) + mu .* x
    end

    proj(x::Vector{Float64}) = clamp.(x, -C, C)

    prob = TestProblem(0, "LogReg_N$(N)_n$(n)", ψ, proj,
                       "Regularized logistic regression (ELSCAM-S-26-01242 §7)")
    return prob, n
end
