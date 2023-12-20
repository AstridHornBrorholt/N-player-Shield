### Authored December 2023 by Christian Schilling ###

using ReachabilityAnalysis

## grid definition and helper functions

struct Grid{N}
    acts::Array{Vector{Bool}, N}
    lower_bounds::Vector{Float64}
    step::Vector{Float64}
end

function get_cell(idx::CartesianIndex, grid::Grid)
    acts = grid.acts[idx]
    lo = grid.lower_bounds + [grid.step[j] * (idx[j] - 1) for j in eachindex(grid.step)]
    hi = lo .+ grid.step
    box = Hyperrectangle(low=lo, high=hi)
    return box, acts
end

function get_idx(p::Vector{Float64}, grid::Grid)
    q = p .- grid.lower_bounds
    return CartesianIndex((Int.(div.(q, grid.step)) + ones(Int, length(q)))...)
end

## successor computation for linear systems

# this work only has to be done once per dynamics
function successor_preprocess(A::AbstractMatrix, period::Float64)
    return exp(A * period)
end

function successor_preprocess(As::Dict, period::Float64)
    Φs = Dict(k => exp(A * period) for (k, A) in As)
    return Φs
end

function successor(X::LazySet, Φ::AbstractMatrix)
    return linear_map(Φ, X)
end

## check closure under successors

function _indices_of_box(X::LazySet, grid::Grid)
    l, h = extrema(X)
    il = get_idx(l, grid)
    ih = get_idx(h, grid)
    ranges = []
    for i in eachindex(l)
        push!(ranges, il[i]:ih[i])
    end
    return CartesianIndices(Tuple(ranges))
end

function check_cells_approximate(X::LazySet, grid::Grid)
    for idx in _indices_of_box(X, grid)
        _, acts = get_cell(idx, grid)
        if !any(acts)  # unsafe cell
            return false
        end
    end
    return true
end

function _isextreme(idx, indices)
    for i in 1:length(idx)
        if 1 < idx[i] < length(indices[i])
            return false
        end
    end
    return true
end

function check_cells_exact(X::Zonotope, grid::Grid)
    indices = _indices_of_box(X, grid)
    for idx in indices
        B, acts = get_cell(idx, grid)
        # idea: double-check, but since X is convex, it is sufficient to check
        # the corners
        if !any(acts) && _isextreme(idx, indices) && !isdisjoint(X, B)
            return false
        end
    end
    return true
end

# returns `nothing` if closed under successors
# otherwise returns the index of the first counterexample
function check_all_cells(grid::Grid; alg)
    for idx in CartesianIndices(grid.acts)
        box, acts = get_cell(idx, grid)
        for (i, act_i) in enumerate(acts)
            if !act_i  # skip deactivated actions
                continue
            end
            Φ = Φs[i]
            if !alg(successor(box, Φ), grid)
                return idx
            end
        end
    end
    return nothing
end

### example ###

using Plots

tt = [true, true]
tf = [true, false]
ft = [false, true]
ff = [false, false]
mat = reshape([tt, tt, tt, ff,
               ff, tt, tt, tf,
               ft, ft, ft, ft,
               ff, ff, ff, ff], (4, 4))
grid = Grid(mat,
            [-0.1, -0.1],
            [0.05, 0.05])

A1 = [ 0.0 1;
      -1   0]
A2 = [-1  1;
      -1 -1]
As = Dict(1 => A1, 2 => A2)

period = 0.3

Φs = successor_preprocess(As, period)

grid_box = Hyperrectangle(low=grid.lower_bounds,
                          high=grid.lower_bounds .+ grid.step .* [size(grid.acts)...])
plot()
plot!(grid_box, c=:white)
for idx in CartesianIndices(grid.acts)
    local box, acts = get_cell(idx, grid)
    c = acts == tt ? :white : acts == tf ? :yellow : acts == ft ? :pink : :black
    closed = true
    for (i, act_i) in enumerate(acts)
        if !act_i  # skip deactivated actions
            continue
        end
        Φ = Φs[i]
        if !(successor(box, Φ) ⊆ grid_box)
            closed = false
            break
        end
    end
    alpha = closed ? 0.8 : 0.1  # low alpha if successors leave grid
    plot!(box, c=c, alpha=alpha)
end
plot!()

## pick one of the following cases (1-3)

case = 1

if case == 1
    ### 1. case: pick the counterexample cell from closure check

    # approximate check is probably sufficient for this example and much cheaper
    @time cell = check_all_cells(grid; alg=check_cells_approximate)

    # exact check (more expensive)
    @time cell = check_all_cells(grid; alg=check_cells_exact)
elseif case == 2
    ### 2. case: pick a more interesting negative cell
    cell = CartesianIndex(2, 2)
elseif case == 3
    ### 3. case: pick a positive cell
    cell = CartesianIndex(3, 2)
else
    error("undefined case")
end

## plot the successors

@show cell
box, acts = get_cell(cell, grid)

succs = Zonotope[]
for (i, act_i) in enumerate(acts)
    if !act_i  # skip deactivated actions
        continue
    end
    Φ = Φs[i]
    push!(succs, successor(box, Φ))
end

plot!(box, c=:blue)

# in this case the successors are not even contained in the grid; they are
# filtered out above and do not contribute to the negative result; the real
# counterexample is shown in the subsequent block
S = succs[1]
@show check_cells_approximate(S, grid)
@show check_cells_exact(S, grid)
plot!(box_approximation(S), c=:red)
plot!(S, c=:red, alpha=0.4)

S = succs[2]
@show check_cells_approximate(S, grid)
@show check_cells_exact(S, grid)
plot!(box_approximation(S), c=:green)
plot!(S, c=:green, alpha=0.4)
