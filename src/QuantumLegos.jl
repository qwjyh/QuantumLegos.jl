module QuantumLegos

export PauliOps
export pauliop, GeneratedPauliGroup, weight

export Lego, LegoLeg, edge, CheckMatrix, checkmatrix, generators, State, add_lego!, add_edge!, distance

using StaticArrays
using IterTools

# PauliOps submodule
include("PauliOps/PauliOps.jl")
using .PauliOps

include("checkmatrix.jl")
include("game.jl")

end
