"""
Pauli operator
"""
module PauliOps

using StaticArrays
using IterTools

export SinglePauliOp, PauliOp
export single_pauliop, pauliop
export weight, xweight, zweight
export GeneratedPauliGroup

"""
    @enum SinglePauliOp begin
        I
        X
        Y
        Z
    end

Pauli Operator on a single qubit.
"""
@enum SinglePauliOp begin
    I
    X
    Y
    Z
end

"""
    PauliOp{N}

Pauli operator on multiple qubits.
"""
const PauliOp{N} = SVector{N, SinglePauliOp}

"""
    single_pauliop(char::Char)::SinglePauliOp

Convert `char` to `SinglePauliOp`.
"""
function single_pauliop(char::Char)::SinglePauliOp
    char == 'I' && return I
    char == 'X' && return X
    char == 'Y' && return Y
    char == 'Z' && return Z
    throw(ArgumentError("invalid char for pauli operator (must be I, X, Y, or Z)"))
end

function Base.String(p::SinglePauliOp)
    p == I && return "I"
    p == X && return "X"
    p == Y && return "Y"
    p == Z && return "Z"
end

@inline function single_pauli_product(x::T, y::T)::T where {T <: SinglePauliOp}
    if x == I
        return y
    elseif y == I
        return x
    elseif x == y
        return I
    else
        x == X && y == Y && return Z
        x == X && y == Z && return Y
        x == Y && y == Z && return X
        return single_pauli_product(y, x)
    end
end

Base.:(*)(x::T, y::T) where {T <: SinglePauliOp} = single_pauli_product(x, y)

"""
    pauliop(str::AbstractString)::PauliOp

Convert `str` to `PauliOp`.
"""
function pauliop(str::AbstractString)::PauliOp
    SVector(single_pauliop.(collect(str))...)
end

Base.String(p::PauliOp) = join(String.(p))
Base.show(io::IO, p::PauliOp) = print(io, "pauliop(\"$(String(p))\")")
Base.summary(io::IO, p::PauliOp) = print(io, "$(length(p))-element PauliOp")
# function Base.show(io::IO, ::MIME"text/plain", p::PauliOp)
#     if get(io, :compact, false)
#         print(io, String(p))
#     else
#         summary(io, p)
#         print(io, ": ", String(p))
#     end
# end

"""
    weight(p::PauliOp, [init = 1])

Weight of the operator `p`, i.e. non \$I\$ operator.
"""
function weight(p::PauliOp, init::Integer = 1)
    # length(filter(!=(PauliOps.I), p))
    count = 0
    for i in eachindex(p)
        i < init && continue
        if p[i] != PauliOps.I
            count += 1
        end
    end
    count
end

"""
    xweight(p::PauliOp, [init = 1])

Number of \$X, Y\$ in `p`.
"""
function xweight(p::PauliOp, init::Integer = 1)
    count = 0
    for i in eachindex(p)
        i < init && continue
        if p[i] == PauliOps.X || p[i] == PauliOps.Y
            count += 1
        end
    end
    count
end

"""
    zweight(p::PauliOp, [init = 1])

Number of \$Z, Y\$ in `p`.
a"""
function zweight(p::PauliOp, init::Integer = 1)
    # length(filter(!=(PauliOps.I), p))
    count = 0
    for i in eachindex(p)
        i < init && continue
        if p[i] == PauliOps.Z || p[i] == PauliOps.Y
            count += 1
        end
    end
    count
end

# should have compatibility with other packages like AbstractAlgebra?
"""
    struct GeneratedPauliGroup

Iterator for group generated from `gens`.

    GeneratedPauliGroup(gens::AbstractVector{T}) where {T <: PauliOp}

# Examples
```jldoctest
julia> gens = pauliop.(["IIXX", "IZZI"])
2-element Vector{StaticArraysCore.SVector{4, QuantumLegos.PauliOps.SinglePauliOp}}:
 pauliop("IIXX")
 pauliop("IZZI")

julia> g = PauliOps.GeneratedPauliGroup(gens)
GeneratedPauliGroup{4}(StaticArraysCore.SVector{4, QuantumLegos.PauliOps.SinglePauliOp}[pauliop("IIXX"), pauliop("IZZI")], IterTools.Subsets{Vector{StaticArraysCore.SVector{4, QuantumLegos.PauliOps.SinglePauliOp}}}(StaticArraysCore.SVector{4, QuantumLegos.PauliOps.SinglePauliOp}[pauliop("IIXX"), pauliop("IZZI")]))

julia> collect(g)
4-element Vector{StaticArraysCore.SVector{4, QuantumLegos.PauliOps.SinglePauliOp}}:
 pauliop("IIII")
 pauliop("IIXX")
 pauliop("IZZI")
 pauliop("IZYX")
```
"""
struct GeneratedPauliGroup{N}
    gens::AbstractVector{PauliOp{N}}
    subsets::IterTools.Subsets
    function GeneratedPauliGroup(gens::AbstractVector{T}) where {T <: PauliOp}
        length.(gens) |> unique |> length |> ==(1) ||
            throw(ArgumentError("All generators must have the same length."))
        subsets = IterTools.subsets(gens)
        N = length(gens[1])
        new{N}(gens, subsets)
    end
end

function Base.iterate(g::GeneratedPauliGroup)
    next = iterate(g.subsets)
    isnothing(next) && return nothing

    subset, state = next
    init::PauliOp{length(g.gens[1])} = fill(I, length(g.gens[1]))
    return (init, state)
end

function Base.iterate(g::GeneratedPauliGroup, state)
    ret = iterate(g.subsets, state)
    isnothing(ret) && return nothing

    subset, state = ret
    return (reduce(.*, subset), state)
end

Base.length(g::GeneratedPauliGroup) = length(g.subsets)
Base.eltype(::Type{GeneratedPauliGroup{N}}) where {N} = PauliOp{N}

end # module PauliOps
