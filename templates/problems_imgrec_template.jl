# problems_imgrec.jl — Image restoration problem constructors
#
# Problem domain: recover image x* from blurred noisy observation b = A*x* + noise
# where A is a convolution (blur) operator. Reformulated as an NCP:
#   F(z) = min{z, H*z + c},  z >= 0
# with variable splitting z = (u; v), x = u - v (GPSR framework).
#
# Interface:
#   image_restoration_problem(x_true; blur_sigma, bsnr, tau_factor)
#       -> (prob::TestProblem, x_true, b_observed, metrics_fn)
#   image_restoration_problem(; imgsize, blur_sigma, bsnr, seed, pattern)
#       -> (prob, x_true, b_observed, metrics_fn)
#   imgrec_metrics(x_rec, x_true) -> (psnr, mse)

# ============================================================================
# Blur Operator
# ============================================================================

"""
    gaussian_kernel(sigma; ksize=nothing) -> Matrix{Float64}

2D Gaussian blur kernel. `ksize` defaults to ceil(6*sigma) | 1 (odd).
"""
function gaussian_kernel(sigma::Float64; ksize::Union{Nothing,Int}=nothing)
    k = ksize === nothing ? (2 * ceil(Int, 3 * sigma) + 1) : ksize
    half = div(k, 2)
    kernel = [exp(-(i^2 + j^2) / (2 * sigma^2)) for i in -half:half, j in -half:half]
    return kernel ./ sum(kernel)
end

"""
    apply_blur(img, kernel) -> Matrix{Float64}

Apply 2D convolution with periodic boundary conditions (via FFT).
"""
function apply_blur(img::Matrix{Float64}, kernel::Matrix{Float64})
    M, N = size(img)
    # Embed kernel in image-sized array
    K = zeros(M, N)
    kh = div(size(kernel, 1), 2)
    for di in -kh:kh, dj in -kh:kh
        K[mod(di, M) + 1, mod(dj, N) + 1] = kernel[di + kh + 1, dj + kh + 1]
    end
    # Convolution via FFT (periodic BC)
    return real.(ifft(fft(img) .* fft(K)))
end

# ============================================================================
# Synthetic Test Images
# ============================================================================

"""
    synthetic_test_image(k::Int; seed=42, pattern=:blocks) -> Matrix{Float64}

Generate a k x k test image in [0, 1]. Patterns: :blocks, :checkerboard, :gradient.
"""
function synthetic_test_image(k::Int; seed::Int=42, pattern::Symbol=:blocks)
    rng = Random.Xoshiro(seed)
    if pattern == :blocks
        img = zeros(k, k)
        n_blocks = 5 + rand(rng, 1:5)
        for _ in 1:n_blocks
            r, c = rand(rng, 1:k-k÷4), rand(rng, 1:k-k÷4)
            bh, bw = rand(rng, k÷8:k÷4), rand(rng, k÷8:k÷4)
            val = 0.3 + 0.7 * rand(rng)
            img[r:min(r+bh, k), c:min(c+bw, k)] .= val
        end
        return img
    elseif pattern == :checkerboard
        bs = max(k ÷ 8, 1)
        return Float64[((div(i-1, bs) + div(j-1, bs)) % 2 == 0) ? 0.8 : 0.2
                       for i in 1:k, j in 1:k]
    elseif pattern == :gradient
        return [Float64(i + j) / (2k) for i in 1:k, j in 1:k]
    else
        error("Unknown pattern: $pattern")
    end
end

# ============================================================================
# Problem Constructor (from image matrix)
# ============================================================================

"""
    image_restoration_problem(x_true; blur_sigma=3.0, bsnr=40.0, tau_factor=0.001)
    -> (prob, x_true_vec, b_observed, metrics_fn)

Build an image restoration problem from a ground truth image matrix.

# BSNR (blurred signal-to-noise ratio)
  BSNR = 10 * log10( var(A*x_true) / sigma_noise^2 )
  => sigma_noise = sqrt( var(A*x_true) / 10^(bsnr/10) )

# NCP reformulation (GPSR, Figueiredo et al. 2007)
  z = (u; v), x = u - v
  H*z + c where H = [A^T A, -A^T A; -A^T A, A^T A], c = tau*e ± A^T b
  F(z) = min.(z, H*z + c)
"""
function image_restoration_problem(x_true::Matrix{Float64};
                                   blur_sigma::Float64=3.0,
                                   bsnr::Float64=40.0,
                                   tau_factor::Float64=0.001,
                                   seed::Int=42)
    rng = Random.Xoshiro(seed)
    M, N = size(x_true)
    n = M * N

    # ── Blur ─────────────────────────────────────────────────────────────
    kernel = gaussian_kernel(blur_sigma)
    Ax = apply_blur(x_true, kernel)

    # ── BSNR-controlled noise ────────────────────────────────────────────
    sigma_noise = sqrt(var(vec(Ax)) / 10^(bsnr / 10))
    noise = sigma_noise * randn(rng, M, N)
    b_observed = Ax + noise

    # ── NCP setup (vectorized) ───────────────────────────────────────────
    # Operators work on vectors; blur applied via FFT internally
    b_vec = vec(b_observed)

    # A^T b (transpose blur = blur with flipped kernel, same for symmetric kernel)
    Atb = vec(apply_blur(b_observed, kernel))
    tau = tau_factor * norm(Atb, Inf)

    _c_u = tau .- Atb
    _c_v = tau .+ Atb
    _Hz = zeros(2n)

    function F_ncp(z)
        u = @view z[1:n]
        v = @view z[n+1:2n]
        x_diff = reshape(u - v, M, N)
        Ax_diff = vec(apply_blur(x_diff, kernel))
        AtAx = vec(apply_blur(reshape(Ax_diff, M, N), kernel))

        _Hz[1:n]     .= AtAx .+ _c_u
        _Hz[n+1:2n]  .= .-AtAx .+ _c_v
        return min.(z, _Hz)
    end

    proj_nn(z) = max.(z, 0.0)

    # Starting point: z0 from observation
    z0 = vcat(max.(Atb, 0.0), max.(.-Atb, 0.0))

    prob_name = "ImgRec_$(M)x$(N)"
    prob = TestProblem(0, prob_name, F_ncp, proj_nn, "Image restoration NCP")

    function metrics_fn(z)
        x_rec = reshape(z[1:n] - z[n+1:2n], M, N)
        return imgrec_metrics(x_rec, x_true)
    end

    return (prob, vec(x_true), b_observed, metrics_fn)
end

# ── Convenience: generate synthetic image + problem ──────────────────────────

function image_restoration_problem(; imgsize::Int=64,
                                     blur_sigma::Float64=3.0,
                                     bsnr::Float64=40.0,
                                     tau_factor::Float64=0.001,
                                     seed::Int=42,
                                     pattern::Symbol=:blocks)
    x_true = synthetic_test_image(imgsize; seed=seed, pattern=pattern)
    return image_restoration_problem(x_true; blur_sigma=blur_sigma, bsnr=bsnr,
                                     tau_factor=tau_factor, seed=seed)
end

# ============================================================================
# Quality Metrics
# ============================================================================

"""
    imgrec_metrics(x_rec, x_true) -> (psnr, mse)

Image reconstruction quality metrics.
- `psnr`: peak signal-to-noise ratio (dB), assuming pixel range [0, 1]
- `mse`:  mean squared error
"""
function imgrec_metrics(x_rec::Matrix{Float64}, x_true::Matrix{Float64})
    err = x_rec - x_true
    mse = sum(err .^ 2) / length(err)
    psnr = mse > 0 ? 10 * log10(1.0 / mse) : Inf
    return (psnr=psnr, mse=mse)
end

function imgrec_metrics(x_rec::Vector{Float64}, x_true::Vector{Float64}, imgsize::Int)
    return imgrec_metrics(reshape(x_rec, imgsize, imgsize),
                          reshape(x_true, imgsize, imgsize))
end
