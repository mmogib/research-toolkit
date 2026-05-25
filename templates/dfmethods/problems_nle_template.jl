# problems_nle.jl — Test problems for Experiment 4.1
#
# 28 constrained nonlinear monotone equations + 18 named initial points
# (the 17 in the paper's Table 2 plus :onestimes8 used by p19). Faithful
# port of the operator definitions from refs/Ibrahim2026code/problems.jl
# and refs/Ibrahim2026code/olderproblems/oldproblems.jl.
#
# Constraint sets follow the CODE — which diverges from the paper's
# Table 1 summary for some problems. Notable code/paper divergences are
# captured in each TestProblem's `sources` field. Two latent bugs in the
# original code were necessarily fixed during the port:
#
#   - p3 (ArcTan) and p4 (ArcTan2) regenerated random M, q on every F call
#     (stochastic operator). Fixed via fixed-seed closure at module load
#     so F is deterministic per problem instance.
#
#   - p14 (DiscreteBV) had inconsistent label/data init points
#     (`x0_p16 = copy(x0_p14)` but `p16_x0_names = copy(p4_x0_names)`).
#     Following the data labels (matches p12).
#
# Interface contract:
#   get_problem(id::Int)                  -> TestProblem
#   get_problem(name::Symbol)             -> TestProblem
#   get_initial_points(n::Int, id_or_name) -> Vector{Tuple{String, Vector{Float64}}}
#   PROBLEM_ORDER, PROBLEM_REGISTRY, PROBLEM_IDS, INITIAL_POINTS

# ============================================================================
# Section 1: TestProblem container
# ============================================================================

"""
    TestProblem(id, name, label, F, set_factory, sources, fixed_n, init_names)

Per-problem record.

- `id::Int` — stable numeric ID (matches index in `PROBLEM_ORDER`; never renumber)
- `name::Symbol` — canonical machine-name key (e.g. `:ExponentialI`)
- `label::String` — display string for plots/tables (e.g. `"Exponential I"`)
- `F::Function` — operator F: ℝⁿ → ℝⁿ (out-of-place, vectorized)
- `set_factory::Function` — `n::Int -> AbstractConstraintSet`
- `sources::Vector{String}` — citations and notes (including code divergences)
- `fixed_n::Union{Nothing,Int}` — `nothing` if dimension scales freely; `Int` if locked
- `init_names::Vector{Symbol}` — the 4 named initial points usable for this problem
"""
struct TestProblem
    id::Int
    name::Symbol
    label::String
    F::Function
    set_factory::Function
    sources::Vector{String}
    fixed_n::Union{Nothing,Int}
    init_names::Vector{Symbol}
end

# ============================================================================
# Section 2: Initial points — 18 named functions
# (17 from Table 2 + :onestimes8 used by p19)
# ============================================================================

const INITIAL_POINTS = Dict{Symbol, Function}(
    :tenth         => n -> 0.1 .* ones(n),
    :negativetenth => n -> -0.1 .* ones(n),
    :allones       => n -> ones(n),
    :negativeones  => n -> -ones(n),
    :ntenthn       => n -> begin
        i = Float64(n - 1) / Float64(n)
        vcat(i, 0.1 .* ones(n - 2), i)
    end,
    :allzeros      => n -> zeros(n),
    :tenzeros      => n -> vcat(10.0, zeros(n - 1)),
    :ninezeros     => n -> vcat(9.0, zeros(n - 1)),
    :threezeros    => n -> vcat(3.0, zeros(n - 1)),
    :threeszeros   => n -> [iseven(i) ? 0.0 : 3.0 for i in 1:n],
    :zerotwos      => n -> vcat(0.0, 2.0 .* ones(n - 1)),
    :zeroones      => n -> vcat(0.0, ones(n - 1)),
    :oneszero      => n -> vcat(ones(n - 1), 0.0),
    :halfn         => n -> [1.0 / 2.0^i for i in 1:n],
    :negativehalfn => n -> -[1.0 / 2.0^i for i in 1:n],
    :nth           => n -> [1.0 / i for i in 1:n],
    :negativenth   => n -> -[1.0 / i for i in 1:n],
    :onestimes8    => n -> 8.0 .* ones(n),  # used by p19 only
)

# ============================================================================
# Section 3: Constraint set factories — see constraints_nle.jl
# ============================================================================
#
# The _omega / _box / _box_and_halfspace helpers used by the
# TestProblem.set_factory closures below live in constraints_nle.jl.
# That file must be included BEFORE this one (see src/includes.jl
# ordering).

# ============================================================================
# Section 4: Operator function definitions (one per problem)
# ============================================================================

# ── p1: Exponential I.  F_i(x) = exp(x_i) - 1
_F_p01(x) = exp.(x) .- 1

# ── p2: Modified Nonsmooth Sine.  F_i(x) = x_i - sin(|x_i - 1|)
_F_p02(x) = x .- sin.(abs.(x .- 1))

# ── p3: ArcTan (fixed n=5).
#    Original code regenerates M, q on every F call (stochastic operator).
#    Fixed M, q once at module load via a fixed seed (123) so F is a
#    deterministic monotone operator per problem instance.
function _make_arctan_p03(n::Int)
    rng   = Random.MersenneTwister(123)
    M_raw = randn(rng, n, n) .* Float64(n)
    M     = 0.5 .* (M_raw .- M_raw')         # antisymmetric
    q     = randn(rng, n) .* Float64(n)
    ρ     = 100.0
    q0    = 1.5 .* ones(n)
    F_inner(y) = ρ .* atan.(y .- 2) .+ M * y .+ q
    F_q0 = F_inner(q0)
    return x -> F_inner(x) .- F_q0
end
const _F_p03 = _make_arctan_p03(5)

# ── p4: ArcTan2 (fixed n=10).  Same closure pattern as p3.
function _make_arctan2_p04(n::Int)
    rng   = Random.MersenneTwister(456)
    A     = randn(rng, n, n) .* 0.5
    B_raw = randn(rng, n, n) .* 0.5
    B     = 0.5 .* (B_raw .- B_raw')
    M     = A * A' .+ B
    q     = randn(rng, n) .* 250.0
    a     = rand(rng, 1:100, n)
    q02   = 0.9 .* ones(n)
    F_inner(y) = a .* atan.(y) .+ M * y .+ q
    F_q02 = F_inner(q02)
    return x -> F_inner(x) .- F_q02
end
const _F_p04 = _make_arctan2_p04(10)

# ── p5: Strictly Monotone (fixed n=4).
function _F_p05(x)
    A = [
        1.0  0.0  0.0  0.0;
        0.0  1.0 -1.0  0.0;
        0.0  1.0  1.0  0.0;
        0.0  0.0  0.0  0.0
    ]
    b = [-10.0; 1.0; -3.0; 0.0]
    return A * x .+ [x[1]^3; x[2]^3; 2.0 * x[3]^3; 2.0 * x[4]^3] .+ b
end

# ── p6: Exponential II Modified.
function _F_p06(x)
    vcat(exp(x[1]) - 1, exp.(x[2:end]) .+ x[2:end] .- 1)
end

# ── p7: Logarithmic.  F_i(x) = log(x_i + 1) - x_i / n
_F_p07(x) = log.(x .+ 1) .- (x ./ length(x))

# ── p8: Nonsmooth Sine.  F_i(x) = 2 x_i - sin(|x_i|)
_F_p08(x) = 2 .* x .- sin.(abs.(x))

# ── p9: Exponential IV.  F_i(x) = (i exp(x_i) / n) - 1
function _F_p09(x)
    n = length(x)
    a = collect(1:n)
    return (a .* exp.(x) ./ n) .- 1
end

# ── p10: Tridiagonal.  F_i = x_i - exp(cos(h (x_{i-1} + x_i + x_{i+1})))
function _F_p10(x)
    x0 = vcat(0.0, x)
    x1 = vcat(x, 0.0)
    h  = 1 / (1 + length(x))
    return x .- exp.(cos.(h .* (x0[1:end-1] .+ x .+ x1[2:end])))
end

# ── p11: Linear System Matrix.  F(x) = A x - 1  with A tridiag(5/2, 1, 1)
# Tridiagonal matvec is computed inline; materializing A as a dense n×n
# matrix (e.g. via `diagm`) would allocate ~180 GB at n = 150_000 and
# OOM. O(n) time, one O(n) result allocation per call.
function _F_p11(x)
    n = length(x)
    F = Vector{Float64}(undef, n)
    @inbounds for i in eachindex(x)
        s = 2.5 * x[i] - 1.0
        i > 1 && (s += x[i-1])
        i < n && (s += x[i+1])
        F[i] = s
    end
    return F
end

# ── p12: Cubic Polynomial.
function _F_p12(x)
    n = length(x)
    F = zeros(n)
    F[1] = (1/3) * x[1]^3 + (1/2) * x[2]^2
    for i in 2:n-1
        F[i] = -(1/2) * x[i]^2 + (i/3) * x[i]^3 + (1/2) * x[i+1]^2
    end
    F[n] = -(1/2) * x[n]^2 + (n/3) * x[n]^3
    return F
end

# ── p13: Quadratic Sum Function.  F_i(x) = x_i + (Σx - x_i²)/n + i
function _F_p13(x)
    n   = length(x)
    smx = sum(x)
    return [x[i] + ((smx - x[i]^2) / n) + i for i in 1:n]
end

# ── p14: Discrete Boundary Value Problem.
function _F_p14(x)
    n = length(x)
    h = 1 / (n + 1)
    F = zeros(n)
    F[1] = 2 * x[1] + 0.5 * h^2 * (x[1] + h)^3 - x[2]
    for i in 2:n-1
        F[i] = 2 * x[i] + 0.5 * h^2 * (x[i] + i * h)^3 - x[i-1] + x[i+1]
    end
    F[n] = 2 * x[n] + 0.5 * h^2 * (x[n] + n * h)^3 - x[n-1]
    return F
end

# ── p15: Tri-Exponential.
function _F_p15(x)
    n = length(x)
    F = zeros(n)
    F[1] = 3 * x[1]^3 + 2 * x[2] - 5 + sin(x[1] - x[2]) * sin(x[1] + x[2])
    for i in 2:n-1
        F[i] = -x[i-1] * exp(x[i-1] - x[i]) + x[i] * (4 + 3 * x[i]^2) +
               2 * x[i+1] + sin(x[i] - x[i+1]) * sin(x[i] + x[i-1]) - 8
    end
    F[n] = -x[n-1] * exp(x[n-1] - x[n]) + 4 * x[n] - 3
    return F
end

# ── p16: Polynomial Modified.  Pentadiag {1, 2.5, 1} x - 1
function _F_p16(x)
    n = length(x)
    F = zeros(n)
    F[1] = 2.5 * x[1] + x[2] - 1
    for i in 2:n-1
        F[i] = x[i-1] + 2.5 * x[i] + x[i+1] - 1
    end
    F[n] = x[n-1] + 2.5 * x[n] - 1
    return F
end

# ── p17: OPolynomialI (from oldproblems.jl).
function _F_p17(x)
    return vcat(
        4 .* x[1:end-1] .+ (x[2:end] .- 2 .* x[1:end-1]) .- ((x[2:end] .^ 2) / 3),
        4 * x[end] + (x[end-1] - 2 * x[end]) - x[end-1]^2 / 3,
    )
end

# ── p18: OSmoothSine.  F_i(x) = 2 x_i - sin(x_i)
_F_p18(x) = 2 .* x .- sin.(x)

# ── p19: OPolynomialSineCosine.
function _F_p19(x)
    N = 1 / length(x)
    s = N * sum(x)
    return x .* cos.(x .- N) .* (sin.(x) .- 1 .- (x .- 1) .^ 2 .- s)
end

# ── p20: OExponetialI.  Identical scalar to p1.
_F_p20(x) = exp.(x) .- 1

# ── p21: ONonsmoothSine.  Identical scalar to p8.
_F_p21(x) = 2 .* x .- sin.(abs.(x))

# ── p22: OModifiedNonsmoothSine.  Identical scalar to p2.
_F_p22(x) = x .- sin.(abs.(x .- 1))

# ── p23: OModifiedNonsmoothSine2.
_F_p23(x) = x .- sin.(abs.(x) .- 1)

# ── p24: OExponetialSineCosine.
_F_p24(x) = exp.(2 .* x) .+ 3 .* sin.(x) .* cos.(x) .- 1

# ── p25: OModifiedTrigI.
function _F_p25(x)
    return vcat(
        x[1] + sin(x[1]) - 1,
        -x[1:end-2] .+ 2 .* x[2:end-1] .+ sin.(x[2:end-1]) .- 1,
        x[end] + sin(x[end]) - 1,
    )
end

# ── p26: OLogarithmic.  Identical scalar to p7.
_F_p26(x) = log.(x .+ 1) .- (x ./ length(x))

# ── p27: ONonmoothLogarithmic.
_F_p27(x) = log.(abs.(x) .+ 1) .- (x ./ length(x))

# ── p28: OENGVAL1Grad.  Unconstrained gradient of ENGVAL1.
function _F_p28(x)
    X2 = x .^ 2
    return vcat(
        4 * (x[1] * (X2[1] + X2[2]) - 1),
        4 .* (x[2:end-1] .* (X2[1:end-2] .+ 2 .* X2[2:end-1] .+ X2[3:end]) .- 1),
        4 * x[end] * (X2[end-1] + X2[end]),
    )
end

# ============================================================================
# Section 5: Problem registry
# ============================================================================

const PROBLEM_REGISTRY = Dict{Symbol, TestProblem}(
    :ExponentialI => TestProblem(
        1, :ExponentialI, "Exponential I", _F_p01,
        n -> _omega(-1, n, n),
        ["Wang, Wang, Xu (2007). Math. Meth. Oper. Res. 66(1):33-46",
         "Gonçalves & Menezes (2023). Comp. Appl. Math. 42(7):306"],
        nothing,
        [:tenth, :allones, :ntenthn, :negativeones],
    ),
    :ModifiedNonsmoothSine => TestProblem(
        2, :ModifiedNonsmoothSine, "Modified Nonsmooth Sine", _F_p02,
        n -> _omega(-1, n, n),
        ["Yu, Lin, Sun, Xiao, Liu, Li (2009). Appl. Num. Math. 59(10):2416-2423",
         "Gonçalves & Menezes (2023). Comp. Appl. Math. 42(7):306"],
        nothing,
        [:tenth, :allones, :allzeros, :negativeones],
    ),
    :ArcTan => TestProblem(
        3, :ArcTan, "Arc Tangent", _F_p03,
        n -> _omega(0, n, n),
        ["Wang, Wang, Xu (2007). Math. Meth. Oper. Res. 66(1):33-46 (Pb 2)",
         "Gonçalves & Menezes (2023). Comp. Appl. Math. 42(7):306",
         "DEVIATION FROM ORIGINAL CODE: original regenerated M, q on every F " *
         "call (stochastic); fixed via closure with seed=123 at module load"],
        5,
        [:tenzeros, :ninezeros, :threeszeros, :zerotwos],
    ),
    :ArcTan2 => TestProblem(
        4, :ArcTan2, "Arc Tangent 2", _F_p04,
        n -> _omega(0, n, n),
        ["Wang, Wang, Xu (2007). Math. Meth. Oper. Res. 66(1):33-46 (Pb 3)",
         "Gonçalves & Menezes (2023). Comp. Appl. Math. 42(7):306",
         "DEVIATION FROM ORIGINAL CODE: original regenerated M, q on every F " *
         "call (stochastic); fixed via closure with seed=456 at module load"],
        10,
        [:allones, :tenth, :halfn, :nth],
    ),
    :StrictlyMonotone => TestProblem(
        5, :StrictlyMonotone, "Strictly Monotone", _F_p05,
        n -> _omega(-1, n, 4),
        ["Wang, Wang, Xu (2007). Math. Meth. Oper. Res. 66(1):33-46 (Pb 4)",
         "Gonçalves & Menezes (2023). Comp. Appl. Math. 42(7):306"],
        4,
        [:allzeros, :threezeros, :oneszero, :zeroones],
    ),
    :ExponentialIIModified => TestProblem(
        6, :ExponentialIIModified, "Exponential II Modified", _F_p06,
        n -> _omega(-1, 2, n),
        ["La Cruz & Raydan (2003). Optim. Methods Softw. 18(5):583-599 (Pb 2 mod)",
         "Abubakar, Kumam, Mohammad (2020). Comp. Appl. Math. 39(2):129 (Pb 1)",
         "Gonçalves & Menezes (2023). Comp. Appl. Math. 42(7):306"],
        nothing,
        [:allones, :tenth, :ntenthn, :nth],
    ),
    :Logarithmic => TestProblem(
        7, :Logarithmic, "Logarithmic", _F_p07,
        n -> _omega(-1, 2, n),
        ["La Cruz & Raydan (2003). Optim. Methods Softw. 18(5):583-599 (Pb 10)",
         "Zheng, Yang, Liang (2020). J. Comp. Appl. Math. 375:112781 (Pb 4.5)",
         "Gonçalves & Menezes (2023). Comp. Appl. Math. 42(7):306"],
        nothing,
        [:allones, :tenth, :halfn, :nth],
    ),
    :NonsmoothSine => TestProblem(
        8, :NonsmoothSine, "Nonsmooth Sine", _F_p08,
        n -> _omega(0, n, n),
        ["Zhou & Li (2007). J. Comp. Math. 25(1):89-96 (Pb 1)",
         "Gonçalves & Menezes (2023). Comp. Appl. Math. 42(7):306"],
        nothing,
        [:allones, :tenth, :ntenthn, :nth],
    ),
    :ExponentialIV => TestProblem(
        9, :ExponentialIV, "Exponential IV", _F_p09,
        n -> _omega(-1, 7, 1.1 * n),
        ["La Cruz & Raydan (2003). Optim. Methods Softw. 18(5):583-599 (Pb 17 mod)",
         "Gonçalves & Menezes (2023). Comp. Appl. Math. 42(7):306"],
        nothing,
        [:allones, :tenth, :ntenthn, :nth],
    ),
    :Tridiagonal => TestProblem(
        10, :Tridiagonal, "Tridiagonal", _F_p10,
        n -> _omega(0, exp(1), exp(1) * n),
        ["Bing & Lin (1991). SIAM J. Optim. 1(2):206-221 (Pb 10)",
         "Gonçalves & Menezes (2023). Comp. Appl. Math. 42(7):306"],
        nothing,
        [:allones, :tenth, :ntenthn, :nth],
    ),
    :LinearSystemMatrix => TestProblem(
        11, :LinearSystemMatrix, "Linear System Matrix", _F_p11,
        n -> _omega(-1, n, n),
        ["Cruz (2017). Num. Alg. 76(4):1109-1130 (Pb 7)",
         "Gonçalves & Menezes (2023). Comp. Appl. Math. 42(7):306"],
        nothing,
        [:allones, :tenth, :ntenthn, :nth],
    ),
    :CubicPolynomial => TestProblem(
        12, :CubicPolynomial, "Cubic Polynomial", _F_p12,
        n -> _omega(-n, 1, n),
        ["Cruz (2017). Num. Alg. 76(4):1109-1130 (Pb 8)",
         "Gonçalves & Menezes (2023). Comp. Appl. Math. 42(7):306"],
        nothing,
        [:negativeones, :negativetenth, :negativehalfn, :negativenth],
    ),
    :QuadraticSumFunction => TestProblem(
        13, :QuadraticSumFunction, "Quadratic Sum Function", _F_p13,
        n -> _omega(-n, n, n),
        ["Cruz (2017). Num. Alg. 76(4):1109-1130 (Pb 9)",
         "Gonçalves & Menezes (2023). Comp. Appl. Math. 42(7):306"],
        nothing,
        [:allones, :tenth, :ntenthn, :nth],
    ),
    :DiscreteBV => TestProblem(
        14, :DiscreteBV, "Discrete Boundary Value", _F_p14,
        n -> _omega(-n, 1, 1),
        ["Liu & Feng (2019). Num. Alg. 82(1):245-262 (Pb 4.2)",
         "Gonçalves & Menezes (2023). Comp. Appl. Math. 42(7):306",
         "DEVIATION FROM ORIGINAL CODE LABELS: paper.problems.jl had " *
         "x0_p16 = copy(x0_p14) (data from p12 names) but " *
         "p16_x0_names = copy(p4_x0_names) (labels from p4). Following " *
         "the DATA (same labels as p12)."],
        nothing,
        [:negativeones, :negativetenth, :negativehalfn, :negativenth],
    ),
    :TriExponential => TestProblem(
        15, :TriExponential, "Tri-Exponential", _F_p15,
        n -> _omega(-1, n, n),
        ["Liu & Feng (2019). Num. Alg. 82(1):245-262 (Pb 4.3)",
         "Gonçalves & Menezes (2023). Comp. Appl. Math. 42(7):306"],
        nothing,
        [:ntenthn, :tenth, :halfn, :nth],
    ),
    :PolynomialModified => TestProblem(
        16, :PolynomialModified, "Polynomial Modified", _F_p16,
        n -> _omega(-1, n, n),
        ["Liu & Feng (2019). Num. Alg. 82(1):245-262 (Pb 4.7)",
         "Gonçalves & Menezes (2023). Comp. Appl. Math. 42(7):306"],
        nothing,
        [:allones, :tenth, :ntenthn, :nth],
    ),

    # ── CO* problems (p17–p28): older code. The Table 1 column simplifies
    #    these to Ω(-1, n, n), but the actual code uses very different
    #    constraint sets (BoxSet variants, Intersection, RealSpace). Following
    #    the CODE.

    :OPolynomialI => TestProblem(
        17, :OPolynomialI, "OPolynomialI", _F_p17,
        n -> _box(0, Inf, n),
        ["Sabi'u, Shah, Waziri, Dauda (2020). J. Math. Fund. Sci. 52:17-26 (Pb 9)",
         "Code uses BoxSet(0, +Inf) (paper Table 1 column oversimplifies to Ω(-1,n,n))"],
        nothing,
        [:allones, :tenth, :ntenthn, :nth],
    ),
    :OSmoothSine => TestProblem(
        18, :OSmoothSine, "Smooth Sine (CO)", _F_p18,
        n -> _box(0, Inf, n),
        ["Zhou & Li (2008). Math. Comp. 77(264):2231-2240 (Pb 1 mod)",
         "Code uses BoxSet(0, +Inf) (paper Table 1 column oversimplifies to Ω(-1,n,n))"],
        nothing,
        [:allones, :tenth, :ntenthn, :nth],
    ),
    :OPolynomialSineCosine => TestProblem(
        19, :OPolynomialSineCosine, "Polynomial Sine Cosine (CO)", _F_p19,
        n -> _box(0, Inf, n),
        ["Sabi'u et al. (2023). Appl. Num. Math. 184:431-445 (Pb 4.6)",
         "Code uses BoxSet(0, +Inf) (paper Table 1 column oversimplifies to Ω(-1,n,n))"],
        nothing,
        [:allones, :onestimes8, :threeszeros, :halfn],
    ),
    :OExponetialI => TestProblem(
        20, :OExponetialI, "Exponential I (CO)", _F_p20,
        n -> _box(0, Inf, n),
        ["Wang, Wang, Xu (2007). Math. Meth. Oper. Res. 66(1):33-46 (Pb 4.1)",
         "Code uses BoxSet(0, +Inf) (paper Table 1 column oversimplifies to Ω(-1,n,n))"],
        nothing,
        [:allones, :tenth, :ntenthn, :nth],
    ),
    :ONonsmoothSine => TestProblem(
        21, :ONonsmoothSine, "Nonsmooth Sine (CO)", _F_p21,
        n -> _box_and_halfspace(0, n, n),
        ["Zhou & Li (2007). J. Comp. Math. 25(1):89-96 (Pb 1)",
         "Code uses Intersection(BoxSet(0,+Inf), HalfSpace(ones,n)) (paper Table 1 column oversimplifies to Ω(-1,n,n))"],
        nothing,
        [:allones, :tenth, :ntenthn, :nth],
    ),
    :OModifiedNonsmoothSine => TestProblem(
        22, :OModifiedNonsmoothSine, "Modified Nonsmooth Sine (CO)", _F_p22,
        n -> _box_and_halfspace(-1, n, n),
        ["Yu et al. (2009). Appl. Num. Math. 59(10):2416-2423 (Pb 2)",
         "Code uses Intersection(BoxSet(-1,+Inf), HalfSpace(ones,n)) (paper Table 1 column oversimplifies to Ω(-1,n,n))"],
        nothing,
        [:allones, :tenth, :ntenthn, :nth],
    ),
    :OModifiedNonsmoothSine2 => TestProblem(
        23, :OModifiedNonsmoothSine2, "Modified Nonsmooth Sine 2 (CO)", _F_p23,
        n -> _box_and_halfspace(-1, n, n),
        ["Gao & He (2018). Calcolo 55:53 (Pb 2)",
         "Code uses Intersection(BoxSet(-1,+Inf), HalfSpace(ones,n)) (paper Table 1 column oversimplifies to Ω(-1,n,n))"],
        nothing,
        [:allones, :tenth, :ntenthn, :nth],
    ),
    :OExponetialSineCosine => TestProblem(
        24, :OExponetialSineCosine, "Exponential Sine Cosine (CO)", _F_p24,
        n -> _box_and_halfspace(-1, n, n),
        ["Gao & He (2018). Calcolo 55:53 (Pb 1)",
         "Code uses Intersection(BoxSet(-1,+Inf), HalfSpace(ones,n)) (paper Table 1 column oversimplifies to Ω(-1,n,n))"],
        nothing,
        [:allones, :tenth, :ntenthn, :nth],
    ),
    :OModifiedTrigI => TestProblem(
        25, :OModifiedTrigI, "Modified Trig I (CO)", _F_p25,
        n -> _box(-3, Inf, n),
        ["Zheng, Yang, Liang (2020). J. Comp. Appl. Math. 375:112781 (Pb 4.2)",
         "Code uses BoxSet(-3, +Inf) (paper Table 1 column oversimplifies to Ω(-1,n,n))"],
        nothing,
        [:allones, :tenth, :ntenthn, :nth],
    ),
    :OLogarithmic => TestProblem(
        26, :OLogarithmic, "Logarithmic (CO)", _F_p26,
        n -> _box(-1, Inf, n),
        ["La Cruz & Raydan (2003). Optim. Methods Softw. 18(5):583-599 (Pb 10)",
         "Zheng, Yang, Liang (2020). J. Comp. Appl. Math. 375:112781 (Pb 4.5)",
         "Code uses BoxSet(-1, +Inf) (paper Table 1 column oversimplifies to Ω(-1,n,n))"],
        nothing,
        [:allones, :tenth, :halfn, :nth],
    ),
    :ONonmoothLogarithmic => TestProblem(
        27, :ONonmoothLogarithmic, "Nonsmooth Logarithmic (CO)", _F_p27,
        n -> _box(0, Inf, n),
        ["La Cruz & Raydan (2003). Optim. Methods Softw. 18(5):583-599 (Pb 10 mod)",
         "Sabi'u et al. (2023). Appl. Num. Math. 184:431-445 (Pb 4.2)",
         "Code uses BoxSet(0, +Inf) (paper Table 1 column oversimplifies to Ω(-1,n,n))"],
        nothing,
        [:allones, :tenth, :ntenthn, :nth],
    ),
    :OENGVAL1Grad => TestProblem(
        28, :OENGVAL1Grad, "ENGVAL1 Gradient (CO)", _F_p28,
        n -> RealSpace(),
        ["Gould, Orban, Toint — ENGVAL1 (CUTEr/CUTEst)",
         "Code is UNCONSTRAINED (RealSpace); paper Table 1 column oversimplifies to Ω(-1,n,n)"],
        nothing,
        [:allones, :tenth, :ntenthn, :nth],
    ),
)

# Stable ordering: array index = id. NEVER reorder after first use.
const PROBLEM_ORDER = Symbol[
    :ExponentialI,             # 1
    :ModifiedNonsmoothSine,    # 2
    :ArcTan,                   # 3   (fixed n=5)
    :ArcTan2,                  # 4   (fixed n=10)
    :StrictlyMonotone,         # 5   (fixed n=4)
    :ExponentialIIModified,    # 6
    :Logarithmic,              # 7
    :NonsmoothSine,            # 8
    :ExponentialIV,            # 9
    :Tridiagonal,              # 10
    :LinearSystemMatrix,       # 11
    :CubicPolynomial,          # 12
    :QuadraticSumFunction,     # 13
    :DiscreteBV,               # 14
    :TriExponential,           # 15
    :PolynomialModified,       # 16
    :OPolynomialI,             # 17
    :OSmoothSine,              # 18
    :OPolynomialSineCosine,    # 19
    :OExponetialI,             # 20
    :ONonsmoothSine,           # 21
    :OModifiedNonsmoothSine,   # 22
    :OModifiedNonsmoothSine2,  # 23
    :OExponetialSineCosine,    # 24
    :OModifiedTrigI,           # 25
    :OLogarithmic,             # 26
    :ONonmoothLogarithmic,     # 27
    :OENGVAL1Grad,             # 28  (unconstrained)
]

const PROBLEM_IDS = collect(1:length(PROBLEM_ORDER))

# ============================================================================
# Section 6: Public API
# ============================================================================

"""
    get_problem(name::Symbol) -> TestProblem
    get_problem(id::Int)      -> TestProblem

Look up a problem by its canonical Symbol name or its stable numeric ID.
"""
get_problem(name::Symbol) = PROBLEM_REGISTRY[name]
get_problem(id::Int)      = get_problem(PROBLEM_ORDER[id])

"""
    get_initial_points(n::Int, id_or_name) -> Vector{Tuple{String, Vector{Float64}}}

Return the 4 named initial points for problem `id_or_name` at dimension `n`.
For fixed-dim problems (p3, p4, p5), the requested `n` is silently overridden
to `prob.fixed_n` and a warning is emitted.

Init names are stringified (`String(::Symbol)`) at the boundary to match the
SQLite `init_point::TEXT` column.
"""
function get_initial_points(n::Int, id_or_name)
    prob = get_problem(id_or_name)
    use_n = if prob.fixed_n !== nothing
        if n != prob.fixed_n
            @warn "Problem $(prob.name) requires n=$(prob.fixed_n); overriding requested n=$n"
        end
        prob.fixed_n
    else
        n
    end
    return [(String(name), INITIAL_POINTS[name](use_n)) for name in prob.init_names]
end
