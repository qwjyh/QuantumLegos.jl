macro todo()
    error("TODO: Unimplemented")
end
macro todo(msg)
    error("TODO: Unimplemented: $msg")
end

"""
Quantum lego with `N` legs.

# Fields
- `nlegs::Int64`: number of legs, equals `N`
- `stabgens::SVector{N, PauliOp{N}}`: stabilizer generators. vector of [`PauliOp`](@ref)

# Constructor
    Lego([nlegs::Integer], stabgens::AbstractVector{PauliOp{N}})

Constructor for [`Lego`](@ref).
`nlegs` is optional (default is length of the first stabilizer generator).

# Example
```jldoctest
julia> stabgens = pauliop.(["II", "XX"])
2-element Vector{StaticArraysCore.SVector{2, QuantumLegos.PauliOps.SinglePauliOp}}:
 pauliop("II")
 pauliop("XX")

julia> Lego(stabgens)
Lego{2}(2, StaticArraysCore.SVector{2, QuantumLegos.PauliOps.SinglePauliOp}[pauliop("II"), pauliop("XX")])
```
"""
struct Lego{N}
    nlegs::Int64
    stabgens::SVector{N, PauliOp{N}} # There two Ns must be the same?
    function Lego(nlegs::Integer, stabgens::AbstractVector{PauliOp{N}}) where {N}
        all(length(stabgens[1]) .== length.(stabgens)) ||
            throw(ArgumentError("All stabgens have the same length"))
        nlegs == length(stabgens[1]) ||
            throw(ArgumentError("`nlegs` must equal to length of stabilizer"))
        new{N}(nlegs, stabgens)
    end
end

Lego(stabgens::AbstractVector{PauliOp{N}}) where {N} = Lego(length(stabgens[1]), stabgens)

function nlegs(lego::Lego)::Integer
    lego.nlegs
end

"""
    mutable struct State

To be used in [`State`](@ref).

# Fields
- `lego_id::Int64`: index in `legos` in `State`
- `edge_id::Int64`: index in `Lego` in `legos` in `State`. No validation check included in `LegoLeg`.

# Example
```jldoctest
julia> x = LegoLeg.([(2, 1), (1, 1), (1, 0)])
3-element Vector{LegoLeg}:
 LegoLeg(2, 1)
 LegoLeg(1, 1)
 LegoLeg(1, 0)

julia> sort(x)
3-element Vector{LegoLeg}:
 LegoLeg(1, 0)
 LegoLeg(1, 1)
 LegoLeg(2, 1)
```
"""
struct LegoLeg
    lego_id::Int64
    leg_id::Int64
end

LegoLeg(t::Tuple{Integer, Integer}) = LegoLeg(t...)

"""
Helper function to create `Tuple{LegoLeg, LegoLeg}` to represent edge.
"""
function edge end

"""
    edge(t::Tuple{T, T}) where {T <: Tuple{Integer, Integer}}
"""
function edge(t::Tuple{T, T}) where {T <: Tuple{Integer, Integer}}
    (LegoLeg(t[1]), LegoLeg(t[2]))
end

"""
    edge(t::Tuple{T, T, T, T}) where {T <: Integer}
"""
function edge(t::Tuple{T, T, T, T}) where {T <: Integer}
    edge(((t[1], t[2]), (t[3], t[4])))
end

"""
    edge(x::T, y::T, z::T, w::T) where {T <: Integer}
"""
function edge(x::T, y::T, z::T, w::T) where {T <: Integer}
    edge(((x, y), (z, w)))
end

function Base.isless(x::T, y::T) where {T <: LegoLeg}
    if x.lego_id != y.lego_id
        return x.lego_id < y.lego_id
    else
        return x.leg_id < y.leg_id
    end
end

"""
    mutable struct State

State (in p.4)

# Fields
- `legos`: `Vector{Lego}`
- `edges`: Vector of ((`lego_i, leg_n`), (`lego_j, leg_m`)).
    Each element is sorted (i.e. `lego_i < lego_j` or `lego_i == lego_j && leg_n < leg_m`).
    This feature is used in [`is_connected_to_firstlego`](@ref).
- `cmat::CheckMatrix`: CheckMatrix

# Constructor
    State(legos::Vector{Lego{N}}, edges::Vector{Tuple{LegoLeg, LegoLeg}})

# Methods with
- [`add_lego!`](@ref)
- [`add_edge!`](@ref)

# Example
TODO
"""
mutable struct State
    legos::Vector{Lego}
    edges::Vector{Tuple{LegoLeg, LegoLeg}}
    cmat::CheckMatrix
    function State(legos::Vector{Lego{N}}, edges::Vector{Tuple{LegoLeg, LegoLeg}}) where {N}
        if length(edges) == 0
            if length(legos) == 0
                throw(ArgumentError("Need at least one lego"))
            elseif length(legos) == 1
                cmat = checkmatrix(legos[1].stabgens)
                return new(legos, edges, cmat)
            else
                # just iterate instead of recursion?
                return add_lego!(State(legos[1:(end - 1)], edges), legos[end])
            end
        else
            new_edge = pop!(edges)
            if new_edge[1] == new_edge[2]
                throw(ArgumentError("Can't make edges between the same leg."))
            end
            # sort
            if new_edge[1] > new_edge[2]
                new_edge = (new_edge[2], new_edge[1])
            end
            state = State(legos, edges)
            return add_edge!(state, new_edge)
        end
    end
end

function Base.:(==)(x::T, y::T) where {T <: State}
    x.legos == y.legos && x.edges == y.edges && x.cmat == y.cmat
end

"""
    add_lego!(state::State, lego::Lego) -> State

Add a new lego, updating `state`.
"""
function add_lego!(state::State, lego::Lego)::State
    push!(state.legos, lego)
    # direct sum
    state.cmat = direct_sum(state.cmat, checkmatrix(lego.stabgens))
    return state
end

"""
    cmat_index(state::State, leg::LegoLeg)::Int64

Get column index corresponds to `leg` in check matrix of `state`.
If given `leg` is already connected, it throws `ArgumentError`.
If given `lego_id` of `leg` is out of `state.legos`, throws `ArgumentError`.
"""
function cmat_index(state::State, leg::LegoLeg)::Int64
    connected_legs = if isempty(state.edges)
        LegoLeg[]
    else
        mapreduce(x -> [x...], vcat, state.edges)
    end
    if leg in connected_legs
        throw(ArgumentError("The specified leg:$(leg) is already connected."))
    end
    if leg.lego_id > length(state.legos)
        throw(ArgumentError("state doesn't have lego:$(leg.lego_id)"))
    end
    sort!(connected_legs)
    filter!(<(leg), connected_legs)
    n_connected_edges = length(connected_legs)
    n_lego_legs = state.legos[1:(leg.lego_id - 1)] .|> nlegs |> sum
    return n_lego_legs + leg.leg_id - n_connected_edges
end

"""
    add_edge!(state::State, leg_1::LegoLeg, leg_2::LegoLeg)::State

Add a new edge between `leg_1` and `leg_2`, updating `state`.
"""
function add_edge!(state::State, leg_1::LegoLeg, leg_2::LegoLeg)::State
    # sort
    if leg_1 > leg_2
        leg_1, leg_2 = leg_2, leg_1
    end
    col_1 = cmat_index(state, leg_1)
    col_2 = cmat_index(state, leg_2)
    self_trace!(state.cmat, col_1, col_2) # mutates cmat
    push!(state.edges, (leg_1, leg_2))
    return state
end

add_edge!(state::State, edge::Tuple{LegoLeg, LegoLeg}) = add_edge!(state, edge...)

"""
    is_connected_to_firstlego(state::State)::BitVector

Returns vector which stores whether each lego is connected to the first lego.
"""
function is_connected_to_firstlego(state::State)::BitVector
    connected_to_first = falses(state.legos |> length)
    connected_to_first[1] = true
    sort!(state.edges)
    for edge in state.edges
        is_edge_1_connected = connected_to_first[edge[1].lego_id]
        is_edge_2_connected = connected_to_first[edge[2].lego_id]
        if is_edge_1_connected && is_edge_2_connected
            continue
        elseif is_edge_1_connected
            connected_to_first[edge[2].lego_id] = true
        elseif is_edge_2_connected
            connected_to_first[edge[1].lego_id] = true
        else
            continue
        end
    end
    return connected_to_first
end

"""
    distance(state::State) -> Int

Calculate code distance when the first leg of `state` is assigned as logical.
"""
distance(state::State) = _naive_distance(state)

# TODO
"""
Calculate distance.
Use minimum distance of all generated normalizers.
"""
function _naive_distance(state::State)
    # not optimized(can use less alloc)?
    _naive_distance(state.cmat)
end

function _naive_distance(cmat::CheckMatrix)
    # not optimized(can use less alloc)?
    if cmat.ngens != cmat.nlegs
        return 0
    end
    normalizers = cmat |> generators |> GeneratedPauliGroup |> collect
    filter!(x -> x[1] != PauliOps.I, normalizers)
    isempty(normalizers) && @warn "No stabilizer in the code" state
    distance::Integer = minimum(weight, normalizers) - 1 # substitute 1 because first op is always ≠I
    @assert distance >= 0
    return distance
end
