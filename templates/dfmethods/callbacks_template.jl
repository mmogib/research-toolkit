# callbacks.jl — Display callbacks for benchmark scripts.
#
# Bridges DFMethods.jl's `AbstractCallback` extension point to UX helpers that
# benchmark scripts want — currently a live-progress-bar updater.
#
# Contents:
#   - ProgressUpdateCallback : refreshes a ProgressMeter.Progress bar's
#                              `showvalues` from inside each solve's
#                              iteration loop.

# ============================================================================
# ProgressUpdateCallback
# ============================================================================
#
# Pattern: ONE shared callback instance is constructed alongside the
# `Progress` bar, attached to every per-LS `DFProjection.callbacks` vector.
# Before each solve, the outer driver mutates the callback's task-specific
# fields (`ls_label`, `prob_name`, `n`, `init_name`). During the solve,
# DFMethods fires `on_event!(cb, :initialize | :post_iter, cache)` and the
# callback reads `cache.k` / `cache.resid` to refresh the bar's display
# without advancing its position (the outer loop does that via
# `ProgressMeter.next!` after each solve).
#
# `counters` is a NamedTuple of `Ref{Int}` for `(conv, fail)` — written by
# the outer driver after each solve, read here for live display.
#
# `prog::P` is held by reference (mutating it from here is fine — Progress
# is a mutable struct internally).

"""
    ProgressUpdateCallback(prog, maxiter, counters)

Live-updates a `ProgressMeter.Progress` bar's `showvalues` from inside the
DFMethods iteration loop. See module-level comment for the pattern.
"""
mutable struct ProgressUpdateCallback{P, C} <: DFMethods.AbstractCallback
    prog::P                 # ProgressMeter.Progress — by reference
    maxiter::Int
    counters::C             # NamedTuple of Refs: (conv = Ref{Int}, fail = Ref{Int})

    # Task-specific fields — mutated by outer driver before each solve
    ls_label::String
    prob_name::String
    n::Int
    init_name::String
end

function ProgressUpdateCallback(prog, maxiter::Int, counters)
    return ProgressUpdateCallback(prog, maxiter, counters, "", "", 0, "")
end

# Hook the library's callback dispatch. We refresh on :initialize (so the
# bar populates with task info as soon as the solve starts, before iter 1)
# AND on :post_iter (so the iter counter / residual update live).
# ProgressMeter's internal `dt` throttling means most calls are no-ops at
# draw time — only ~2 actual screen redraws per second regardless of how
# often the algorithm iterates.
# Library contract is `on_event!(cb, cache, event)` — cache is the 2nd arg,
# event is the 3rd. (See `DFMethods.jl/src/types.jl:107`.)
#
# Live-residual source:
#   - `cache.resid` is DOCUMENTED as NaN until termination — useless for live display
#   - The only fresh F-value during a solve is `cache.Fz` at `:post_linesearch`
#     (per `DFMethods.jl/src/types.jl:85`) and `cache.Fw` at `:initialize`
#   - We compute `sqrt(sum(abs2, ...))` inline (no LinearAlgebra dependency)
function DFMethods.on_event!(cb::ProgressUpdateCallback, cache, event::Symbol)
    if event === :post_linesearch
        norm_F = sqrt(sum(abs2, cache.Fz))
        # k hasn't been incremented yet at this event; show k+1 for 1-based human display
        _update_progress(cb, cache.k + 1, norm_F)
    elseif event === :initialize
        norm_F = sqrt(sum(abs2, cache.Fw))
        _update_progress(cb, cache.k, norm_F)   # k=0 at init
    end
    return nothing
end

@inline function _update_progress(cb::ProgressUpdateCallback, iter::Int, norm_F::Real)
    ProgressMeter.update!(cb.prog, cb.prog.counter;
        showvalues = [
            ("LS",        cb.ls_label),
            ("Problem",   cb.prob_name),
            ("n",         cb.n),
            ("Init",      cb.init_name),
            ("Iter",      "$(iter)/$(cb.maxiter)"),
            ("‖F‖",       @sprintf("%.2e", norm_F)),
            ("Converged", cb.counters.conv[]),
            ("Failed",    cb.counters.fail[]),
        ])
end
