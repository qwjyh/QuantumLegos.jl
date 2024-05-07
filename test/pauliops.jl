@testset "SinglePauliOp" begin
    @test PauliOps.single_pauliop('I') == PauliOps.I
    @test_throws ArgumentError PauliOps.single_pauliop('a')
end

@testset "SinglePauliOp Product" begin
    using QuantumLegos.PauliOps: I, X, Y, Z
    @test I * X == X
    @test Z * I == Z
    @test X * Y == Z
    @test Z * X == Y
    @test X * X == I
end

@testset "PauliOp" begin
    @test pauliop("IXYZ") == [PauliOps.I, PauliOps.X, PauliOps.Y, PauliOps.Z]
    @test pauliop("IIXXZZ") ==
          [PauliOps.I, PauliOps.I, PauliOps.X, PauliOps.X, PauliOps.Z, PauliOps.Z]
end

@testset "weight" begin
    p = pauliop("IXYZIXYZ")
    @test weight(p) == 6
    @test QuantumLegos.xweight(p) == 4
    @test QuantumLegos.zweight(p) == 4
end
