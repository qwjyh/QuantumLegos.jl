# How to calculate code distance from the state.

!!! warning "WIP"
    This document is not fully completed.

## Definition of code distance.

Let's consider encoding circuit with $1$ logical bit and $k$ physical qubits[^1].
Then this encoding has two physical basis, $\ket{0}_L$ and $\ket{1}_L$.
The **distance** of this encoding is the minimum bit flip required to convert between $\ket{0}_L$ and $\ket{1}_L$.

[^1]: Not all state can be formalized like this. TODO

## Classification of the stabilizers.

When treating `State`, the logical leg is not assigned and one can treat all stabilizers equally.
However, if logical leg is assigned to the state, these stabilizers can be classified to $4$ groups.

1. stabilizers on physical qubits
2. ​$\bar{X}$, which corresponds to logical $X$
3. ​$\bar{Z}$, which corresponds to logical $Z$
4. ​$\bar{Y}$, which corresponds to logical $Y$

Let $\ket{V}$ is the dual state of the channel or encoding map $[[n, 1, d]]$,

```math
distance = \min_{S \in stabilizers} \#\left\{ i \mid \bar{Z}_i ≠ S_i \right\}
```

## Calculating code distance from the check matrix.

TODO: nor required if the performance doesn't matter.

## Examples

### $[[5, 1, 3]]$ code

​$[[5, 1, 3]]$ code has $4$ stabilizers generators, $XZZXI, IXZZX, XIXZZ, ZXIXZ$ and $2$ logical operators, $\bar{X} = XXXXX$ and $\bar{Z} = ZZZZZ$.
Therefore, stabilizer generators for the corresponding state $[[6, 0]]$ is $IXZZXI, IIXZZX, IXIXZZ, IZXIXZ, XXXXXX, ZZZZZZ$.

Let's construct $[[6, 0]]$ state on QuantumLegos.jl.
```jldoctest 1
julia> using QuantumLegos

julia> stab_513 = pauliop.(["IXZZXI", "IIXZZX", "IXIXZZ", "IZXIXZ", "XXXXXX", "ZZZZZZ"])
6-element Vector{StaticArraysCore.SVector{6, QuantumLegos.PauliOps.SinglePauliOp}}:
 pauliop("IXZZXI")
 pauliop("IIXZZX")
 pauliop("IXIXZZ")
 pauliop("IZXIXZ")
 pauliop("XXXXXX")
 pauliop("ZZZZZZ")

julia> lego_513 = Lego(stab_513)
Lego{6}(6, StaticArraysCore.SVector{6, QuantumLegos.PauliOps.SinglePauliOp}[pauliop("IXZZXI"), pauliop("IIXZZX"), pauliop("IXIXZZ"), pauliop("IZXIXZ"), pauliop("XXXXXX"), pauliop("ZZZZZZ")])

julia> state_513 = State([lego_513], edge.([]))
State(Lego[Lego{6}(6, StaticArraysCore.SVector{6, QuantumLegos.PauliOps.SinglePauliOp}[pauliop("IXZZXI"), pauliop("IIXZZX"), pauliop("IXIXZZ"), pauliop("IZXIXZ"), pauliop("XXXXXX"), pauliop("ZZZZZZ")])], Tuple{LegoLeg, LegoLeg}[], CheckMatrix(Bool[0 1 … 0 0; 0 0 … 1 0; … ; 1 1 … 0 0; 0 0 … 1 1], 6, 6))

```

Then collect generators of the state.
```jldoctest 1
julia> normalizers = state_513.cmat |> generators |> GeneratedPauliGroup |> collect
64-element Vector{StaticArraysCore.SVector{6, QuantumLegos.PauliOps.SinglePauliOp}}:
 pauliop("IIIIII")
 pauliop("IXZZXI")
 pauliop("IIXZZX")
 pauliop("IXYIYX")
 pauliop("IXIXZZ")
 pauliop("IIZYYZ")
 pauliop("IXXYIY")
 pauliop("IIYXXY")
 pauliop("IZXIXZ")
 pauliop("IYYZIZ")
 ⋮
 pauliop("YYIZZI")
 pauliop("YXZYZX")
 pauliop("YIIXYX")
 pauliop("YXYXII")
 pauliop("YIXYXI")
 pauliop("YIZZIY")
 pauliop("YXIIXY")
 pauliop("YIYIZZ")
 pauliop("YXXZYZ")

```

Get stabilizer and normalizers of the $[[5, 1, 3]]$ code by assigning the first leg as logical.
```jldoctest 1
julia> stabs = filter(x -> x[1] == PauliOps.I, normalizers)
16-element Vector{StaticArraysCore.SVector{6, QuantumLegos.PauliOps.SinglePauliOp}}:
 pauliop("IIIIII")
 pauliop("IXZZXI")
 pauliop("IIXZZX")
 pauliop("IXYIYX")
 pauliop("IXIXZZ")
 pauliop("IIZYYZ")
 pauliop("IXXYIY")
 pauliop("IIYXXY")
 pauliop("IZXIXZ")
 pauliop("IYYZIZ")
 pauliop("IZIZYY")
 pauliop("IYZIZY")
 pauliop("IYXXYI")
 pauliop("IZYYZI")
 pauliop("IYIYXX")
 pauliop("IZZXIX")

julia> norm_x = filter(x -> x[1] == PauliOps.X, normalizers)
16-element Vector{StaticArraysCore.SVector{6, QuantumLegos.PauliOps.SinglePauliOp}}:
 pauliop("XXXXXX")
 pauliop("XIYYIX")
 pauliop("XXIYYI")
 pauliop("XIZXZI")
 pauliop("XIXIYY")
 pauliop("XXYZZY")
 pauliop("XIIZXZ")
 pauliop("XXZIIZ")
 pauliop("XYIXIY")
 pauliop("XZZYXY")
 pauliop("XYXYZZ")
 pauliop("XZYXYZ")
 pauliop("XZIIZX")
 pauliop("XYZZYX")
 pauliop("XZXZII")
 pauliop("XYYIXI")

julia> norm_y = filter(x -> x[1] == PauliOps.Y, normalizers)
16-element Vector{StaticArraysCore.SVector{6, QuantumLegos.PauliOps.SinglePauliOp}}:
 pauliop("YYYYYY")
 pauliop("YZXXZY")
 pauliop("YYZXXZ")
 pauliop("YZIYIZ")
 pauliop("YZYZXX")
 pauliop("YYXIIX")
 pauliop("YZZIYI")
 pauliop("YYIZZI")
 pauliop("YXZYZX")
 pauliop("YIIXYX")
 pauliop("YXYXII")
 pauliop("YIXYXI")
 pauliop("YIZZIY")
 pauliop("YXIIXY")
 pauliop("YIYIZZ")
 pauliop("YXXZYZ")

julia> norm_z = filter(x -> x[1] == PauliOps.Z, normalizers)
16-element Vector{StaticArraysCore.SVector{6, QuantumLegos.PauliOps.SinglePauliOp}}:
 pauliop("ZZZZZZ")
 pauliop("ZYIIYZ")
 pauliop("ZZYIIY")
 pauliop("ZYXZXY")
 pauliop("ZYZYII")
 pauliop("ZZIXXI")
 pauliop("ZYYXZX")
 pauliop("ZZXYYX")
 pauliop("ZIYZYI")
 pauliop("ZXXIZI")
 pauliop("ZIZIXX")
 pauliop("ZXIZIX")
 pauliop("ZXYYXZ")
 pauliop("ZIXXIZ")
 pauliop("ZXZXYY")
 pauliop("ZIIYZY")

```

These normalizers are generated from one logical operator and stabilizers.
```jldoctest 1
julia> map(x -> x .* pauliop("XXXXXX"), stabs) |> Set == Set(norm_x)
true

julia> map(x -> x .* pauliop("ZZZZZZ"), stabs) |> Set == Set(norm_x)
false

julia> map(x -> x .* pauliop("ZZZZZZ"), stabs) |> Set == Set(norm_z)
true

julia> map(x -> x .* pauliop("YYYYYY"), stabs) |> Set == Set(norm_y)
true

julia> using IterTools

julia> groupby(x -> x[1], normalizers) .|> Set == Set.([stabs, norm_x, norm_z, norm_y])
true

```

Define a function to get weight of the operator.
```jldoctest 1
julia> function weight(x, i = 1)
           count(x[i:end] .!= PauliOps.I)
       end
weight (generic function with 2 methods)

julia> weight(pauliop("XIXIXI"))
3

julia> weight(pauliop("XIXIXI"), 2)
2

```

Calculate coefficients of enumerator polynomial.
```jldoctest 1
julia> using DataStructures

julia> stabs .|> weight |> counter
Accumulator{Int64, Int64} with 2 entries:
  0 => 1
  4 => 15

julia> function weight(i::Integer)
           Base.Fix2(weight, i)
       end
weight (generic function with 3 methods)

julia> normalizers .|> weight(2) |> counter
Accumulator{Int64, Int64} with 4 entries:
  0 => 1
  4 => 15
  5 => 18
  3 => 30

julia> [norm_x..., norm_y..., norm_z...] .|> weight(2) |> counter
Accumulator{Int64, Int64} with 2 entries:
  5 => 18
  3 => 30

julia> [norm_x..., norm_y..., norm_z...] .|> weight(2) |> counter |> keys |> minimum
3

```
Code distance of the encoding is the minimum degree of the non-zero term in the normalizer's polynomial($B$) and not in the stabilizer's polynomial($A$).
So the code distance of this encoding is $3$.
