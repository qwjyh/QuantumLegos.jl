# PauliOps

submodule

## Example
```jldoctest
julia> using QuantumLegos

julia> p = PauliOps.single_pauliop('I')
I::SinglePauliOp = 0

julia> typeof(p)
Enum QuantumLegos.PauliOps.SinglePauliOp:
I = 0
X = 1
Y = 2
Z = 3

julia> pauliop("IXYZ")
4-element PauliOp:
 I::SinglePauliOp = 0
 X::SinglePauliOp = 1
 Y::SinglePauliOp = 2
 Z::SinglePauliOp = 3

julia> typeof(ans)
SVector{4, SinglePauliOp} (alias for StaticArraysCore.SArray{Tuple{4}, QuantumLegos.PauliOps.SinglePauliOp, 1, 4})

julia> PauliOps.I * PauliOps.X
X::SinglePauliOp = 1

julia> PauliOps.X * PauliOps.Z
Y::SinglePauliOp = 2

julia> pauliop("IIX") .* pauliop("XIY")
3-element PauliOp:
 X::SinglePauliOp = 1
 I::SinglePauliOp = 0
 Z::SinglePauliOp = 3
```

## API
```@autodocs
Modules = [PauliOps]
```

