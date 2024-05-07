```@meta
CurrentModule = QuantumLegos
```

# QuantumLegos

Documentation for QuantumLegos.

All contents:

```@contents
```

# Example

## CheckMatrix and defining Lego
```jldoctest
julia> using QuantumLegos

julia> stabilizers = pauliop.(["IIXXXX", "IIZZZZ", "ZIZZII", "IZZIZI", "IXXXII", "XIXIXI"])
6-element Vector{StaticArraysCore.SVector{6, QuantumLegos.PauliOps.SinglePauliOp}}:
 pauliop("IIXXXX")
 pauliop("IIZZZZ")
 pauliop("ZIZZII")
 pauliop("IZZIZI")
 pauliop("IXXXII")
 pauliop("XIXIXI")

julia> cmat = checkmatrix(stabilizers)
CheckMatrix with 6 generators, 6 legs:
  0  0  1  1  1  1 | 0  0  0  0  0  0
  0  0  0  0  0  0 | 0  0  1  1  1  1
  0  0  0  0  0  0 | 1  0  1  1  0  0
  0  0  0  0  0  0 | 0  1  1  0  1  0
  0  1  1  1  0  0 | 0  0  0  0  0  0
  1  0  1  0  1  0 | 0  0  0  0  0  0


julia> cmat.nlegs
6

julia> cmat.ngens
6

julia> cmat.cmat
6×12 Matrix{Bool}:
 0  0  1  1  1  1  0  0  0  0  0  0
 0  0  0  0  0  0  0  0  1  1  1  1
 0  0  0  0  0  0  1  0  1  1  0  0
 0  0  0  0  0  0  0  1  1  0  1  0
 0  1  1  1  0  0  0  0  0  0  0  0
 1  0  1  0  1  0  0  0  0  0  0  0

julia> # define lego

julia> lego = Lego(stabilizers)
Lego{6}(6, StaticArraysCore.SVector{6, QuantumLegos.PauliOps.SinglePauliOp}[pauliop("IIXXXX"), pauliop("IIZZZZ"), pauliop("ZIZZII"), pauliop("IZZIZI"), pauliop("IXXXII"), pauliop("XIXIXI")])

julia> lego.stabgens |> checkmatrix
CheckMatrix with 6 generators, 6 legs:
  0  0  1  1  1  1 | 0  0  0  0  0  0
  0  0  0  0  0  0 | 0  0  1  1  1  1
  0  0  0  0  0  0 | 1  0  1  1  0  0
  0  0  0  0  0  0 | 0  1  1  0  1  0
  0  1  1  1  0  0 | 0  0  0  0  0  0
  1  0  1  0  1  0 | 0  0  0  0  0  0

```

- [`pauliop`](@ref)
- [`checkmatrix`](@ref) and [`CheckMatrix`](@ref)
- [`Lego`](@ref)

## Defining and Updating State
```jldoctest
julia> using QuantumLegos

julia> stabilizers = pauliop.(["IIXXXX", "IIZZZZ", "ZIZZII", "IZZIZI", "IXXXII", "XIXIXI"])
6-element Vector{StaticArraysCore.SVector{6, QuantumLegos.PauliOps.SinglePauliOp}}:
 pauliop("IIXXXX")
 pauliop("IIZZZZ")
 pauliop("ZIZZII")
 pauliop("IZZIZI")
 pauliop("IXXXII")
 pauliop("XIXIXI")

julia> lego = Lego(stabilizers)
Lego{6}(6, StaticArraysCore.SVector{6, QuantumLegos.PauliOps.SinglePauliOp}[pauliop("IIXXXX"), pauliop("IIZZZZ"), pauliop("ZIZZII"), pauliop("IZZIZI"), pauliop("IXXXII"), pauliop("XIXIXI")])

julia> # state with 1 lego, 0 leg

julia> st = State([lego, ], Tuple{LegoLeg, LegoLeg}[])
State(Lego[Lego{6}(6, StaticArraysCore.SVector{6, QuantumLegos.PauliOps.SinglePauliOp}[pauliop("IIXXXX"), pauliop("IIZZZZ"), pauliop("ZIZZII"), pauliop("IZZIZI"), pauliop("IXXXII"), pauliop("XIXIXI")])], Tuple{LegoLeg, LegoLeg}[], CheckMatrix(Bool[0 0 … 0 0; 0 0 … 1 1; … ; 0 1 … 0 0; 1 0 … 0 0], 6, 6))

julia> st.cmat.cmat
6×12 Matrix{Bool}:
 0  0  1  1  1  1  0  0  0  0  0  0
 0  0  0  0  0  0  0  0  1  1  1  1
 0  0  0  0  0  0  1  0  1  1  0  0
 0  0  0  0  0  0  0  1  1  0  1  0
 0  1  1  1  0  0  0  0  0  0  0  0
 1  0  1  0  1  0  0  0  0  0  0  0

julia> add_lego!(st, lego)
State(Lego[Lego{6}(6, StaticArraysCore.SVector{6, QuantumLegos.PauliOps.SinglePauliOp}[pauliop("IIXXXX"), pauliop("IIZZZZ"), pauliop("ZIZZII"), pauliop("IZZIZI"), pauliop("IXXXII"), pauliop("XIXIXI")]), Lego{6}(6, StaticArraysCore.SVector{6, QuantumLegos.PauliOps.SinglePauliOp}[pauliop("IIXXXX"), pauliop("IIZZZZ"), pauliop("ZIZZII"), pauliop("IZZIZI"), pauliop("IXXXII"), pauliop("XIXIXI")])], Tuple{LegoLeg, LegoLeg}[], CheckMatrix(Bool[0 0 … 0 0; 0 0 … 0 0; … ; 0 0 … 0 0; 0 0 … 0 0], 12, 12))

julia> st.cmat.cmat
12×24 Matrix{Bool}:
 0  0  1  1  1  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
 0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  1  1  1  0  0  0  0  0  0
 0  0  0  0  0  0  0  0  0  0  0  0  1  0  1  1  0  0  0  0  0  0  0  0
 0  0  0  0  0  0  0  0  0  0  0  0  0  1  1  0  1  0  0  0  0  0  0  0
 0  1  1  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
 1  0  1  0  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
 0  0  0  0  0  0  0  0  1  1  1  1  0  0  0  0  0  0  0  0  0  0  0  0
 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  1  1  1
 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  0  1  1  0  0
 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1  1  0  1  0
 0  0  0  0  0  0  0  1  1  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0
 0  0  0  0  0  0  1  0  1  0  1  0  0  0  0  0  0  0  0  0  0  0  0  0

julia> # state with 2 legos, 0 leg

julia> st2 = State([lego, lego], Tuple{LegoLeg, LegoLeg}[])
State(Lego[Lego{6}(6, StaticArraysCore.SVector{6, QuantumLegos.PauliOps.SinglePauliOp}[pauliop("IIXXXX"), pauliop("IIZZZZ"), pauliop("ZIZZII"), pauliop("IZZIZI"), pauliop("IXXXII"), pauliop("XIXIXI")]), Lego{6}(6, StaticArraysCore.SVector{6, QuantumLegos.PauliOps.SinglePauliOp}[pauliop("IIXXXX"), pauliop("IIZZZZ"), pauliop("ZIZZII"), pauliop("IZZIZI"), pauliop("IXXXII"), pauliop("XIXIXI")])], Tuple{LegoLeg, LegoLeg}[], CheckMatrix(Bool[0 0 … 0 0; 0 0 … 0 0; … ; 0 0 … 0 0; 0 0 … 0 0], 12, 12))

julia> st == st2
true
```

## 2 Lego 1 edge state
```jldoctest
julia> using QuantumLegos

julia> stabilizers = pauliop.(["IIXXXX", "IIZZZZ", "ZIZZII", "IZZIZI", "IXXXII", "XIXIXI"])
6-element Vector{StaticArraysCore.SVector{6, QuantumLegos.PauliOps.SinglePauliOp}}:
 pauliop("IIXXXX")
 pauliop("IIZZZZ")
 pauliop("ZIZZII")
 pauliop("IZZIZI")
 pauliop("IXXXII")
 pauliop("XIXIXI")

julia> lego = Lego(stabilizers)
Lego{6}(6, StaticArraysCore.SVector{6, QuantumLegos.PauliOps.SinglePauliOp}[pauliop("IIXXXX"), pauliop("IIZZZZ"), pauliop("ZIZZII"), pauliop("IZZIZI"), pauliop("IXXXII"), pauliop("XIXIXI")])

julia> state = State([lego, lego], edge.([((1, 3), (2, 3))]))
State(Lego[Lego{6}(6, StaticArraysCore.SVector{6, QuantumLegos.PauliOps.SinglePauliOp}[pauliop("IIXXXX"), pauliop("IIZZZZ"), pauliop("ZIZZII"), pauliop("IZZIZI"), pauliop("IXXXII"), pauliop("XIXIXI")]), Lego{6}(6, StaticArraysCore.SVector{6, QuantumLegos.PauliOps.SinglePauliOp}[pauliop("IIXXXX"), pauliop("IIZZZZ"), pauliop("ZIZZII"), pauliop("IZZIZI"), pauliop("IXXXII"), pauliop("XIXIXI")])], Tuple{LegoLeg, LegoLeg}[(LegoLeg(1, 3), LegoLeg(2, 3))], CheckMatrix(Bool[1 0 … 0 0; 0 1 … 0 0; … ; 0 0 … 1 1; 0 0 … 0 1], 10, 10))

julia> state.cmat
CheckMatrix with 10 generators, 10 legs:
  1  0  1  0  1  0  0  0  0  0 | 0  0  0  0  0  0  0  0  0  0
  0  1  0  1  1  0  0  0  0  0 | 0  0  0  0  0  0  0  0  0  0
  0  0  1  1  1  0  0  1  1  1 | 0  0  0  0  0  0  0  0  0  0
  0  0  0  0  0  1  0  1  0  1 | 0  0  0  0  0  0  0  0  0  0
  0  0  0  0  0  0  1  0  1  1 | 0  0  0  0  0  0  0  0  0  0
  0  0  0  0  0  0  0  0  0  0 | 1  0  0  1  1  0  0  0  0  0
  0  0  0  0  0  0  0  0  0  0 | 0  1  1  0  1  0  0  0  0  0
  0  0  0  0  0  0  0  0  0  0 | 0  0  1  1  1  0  0  1  1  1
  0  0  0  0  0  0  0  0  0  0 | 0  0  0  0  0  1  0  0  1  1
  0  0  0  0  0  0  0  0  0  0 | 0  0  0  0  0  0  1  1  0  1


julia> pg = state.cmat |> generators |> GeneratedPauliGroup
GeneratedPauliGroup{10}(StaticArraysCore.SVector{10, QuantumLegos.PauliOps.SinglePauliOp}[pauliop("XIXIXIIIII"), pauliop("IXIXXIIIII"), pauliop("IIXXXIIXXX"), pauliop("IIIIIXIXIX"), pauliop("IIIIIIXIXX"), pauliop("ZIIZZIIIII"), pauliop("IZZIZIIIII"), pauliop("IIZZZIIZZZ"), pauliop("IIIIIZIIZZ"), pauliop("IIIIIIZZIZ")], IterTools.Subsets{Vector{StaticArraysCore.SVector{N, QuantumLegos.PauliOps.SinglePauliOp} where N}}(StaticArraysCore.SVector{N, QuantumLegos.PauliOps.SinglePauliOp} where N[pauliop("XIXIXIIIII"), pauliop("IXIXXIIIII"), pauliop("IIXXXIIXXX"), pauliop("IIIIIXIXIX"), pauliop("IIIIIIXIXX"), pauliop("ZIIZZIIIII"), pauliop("IZZIZIIIII"), pauliop("IIZZZIIZZZ"), pauliop("IIIIIZIIZZ"), pauliop("IIIIIIZZIZ")]))

julia> pauliop("XIIXIXIIXI") in pg
true

```

# Internal(how it works)

## Notes on Overall flow
Details on [^1]
- state is translated to a single check matrix
  - the size is ≤ $N \times 2N$ where $N$ is maximum number of lego logs.
- any contraction can be performed on this single check matrix
- if the check matrix can be represented as direct sum of matrices with $k N$ columns where $k ∈ ℕ$, then they are not contracted

### Construction of State
Construction of `State` is completed by calling `State` constructor recursively.

1. Construct `State` without edge. Just adding legos. Checkmatrix is just a direct sum of each lego's checkmatrix
2. Concatenate each edges. During this operation, self tracing of checkmatrix is evaluated.

Each constructor calls action function (which is a map from `State` to `State`).
Therefore, action functions can be used both for direct construction of `State` and action application to `State` during the game.

# API

```@index
```

```@autodocs
Modules = [QuantumLegos]
Pages   = ["game.jl"]
```

[^1]: [C. Cao and B. Lackey, ‘Approximate Bacon-Shor code and holography’, J. High Energ. Phys., vol. 2021, no. 5, p. 127, May 2021, doi: 10.1007/JHEP05(2021)127.](https://doi.org/10.1007/JHEP05(2021)127)

