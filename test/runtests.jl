# for language server completion
# must be removed for test
true || include("../src/QuantumLegos.jl")

using QuantumLegos
using Test
using Documenter
using Aqua
using JET

@testset "QuantumLegos.jl" begin
    @testset "PauliOps" begin
        include("pauliops.jl")
    end

    @testset "Lego" begin
        stabilizers = pauliop.(["II", "XX"])
        wrong_stabilizers = pauliop.(["I", "XX"]) # not SVector
        @info stabilizers
        @test_throws ArgumentError QuantumLegos.Lego(3, stabilizers)
        @test_throws MethodError QuantumLegos.Lego(2, wrong_stabilizers)
    end

    @testset "CheckMatrix" begin
        @test_throws ArgumentError QuantumLegos.CheckMatrix([true false; false true], 2, 2)
        @test_throws ArgumentError QuantumLegos.CheckMatrix([true false; false true], 1, 1)
        @test QuantumLegos.CheckMatrix([true false; false true]) ==
              QuantumLegos.CheckMatrix(Bool[1 0; 0 1], 1, 2)
        @test_throws ArgumentError QuantumLegos.CheckMatrix([true false true; false true true])

        @test_throws MethodError QuantumLegos.checkmatrix(pauliop.(["I", "IX"]))
        @test_throws ArgumentError QuantumLegos.checkmatrix(PauliOps.PauliOp[])
        @test QuantumLegos.checkmatrix(pauliop.(["IIXX", "IZZI"])) ==
              QuantumLegos.CheckMatrix(Bool[0 0 1 1 0 0 0 0; 0 0 0 0 0 1 1 0])
        @test QuantumLegos.checkmatrix(pauliop.(["YIXX", "IZYI"])) ==
              QuantumLegos.CheckMatrix(Bool[1 0 1 1 1 0 0 0; 0 0 1 0 0 1 1 0])

        let
            gens = pauliop.(["IIXX", "IZZI"])
            cmat_1 = QuantumLegos.checkmatrix(gens)
            @test QuantumLegos.xpart(cmat_1) == Bool[0 0 1 1; 0 0 0 0]
            @test QuantumLegos.zpart(cmat_1) == Bool[0 0 0 0; 0 1 1 0]
            @test generators(cmat_1) == gens
        end
        let
            gens = pauliop.(["YIXX", "IZYI"])
            cmat_2 = QuantumLegos.checkmatrix(gens)
            @test QuantumLegos.xpart(cmat_2) == Bool[1 0 1 1; 0 0 1 0]
            @test QuantumLegos.zpart(cmat_2) == Bool[1 0 0 0; 0 1 1 0]
            @test generators(cmat_2) == gens
        end

        @testset "eliminate_column!" begin
            let
                cmat = QuantumLegos.CheckMatrix(Bool[
                    1 0 0 1
                    1 0 1 1
                ])
                @test QuantumLegos.eliminate_column!(cmat, 1, Int64[]) == 1
                @test cmat.cmat == Bool[
                    1 0 0 1
                    0 0 1 0
                ]
            end
            let
                cmat = QuantumLegos.CheckMatrix(Bool[
                    1 0 0 1
                    1 0 1 1
                ])
                @test QuantumLegos.eliminate_column!(cmat, 1, Int64[1]) == 2
                @test cmat.cmat == Bool[
                    0 0 1 0
                    1 0 1 1
                ]
            end
            let
                cmat = QuantumLegos.CheckMatrix(
                    Bool[
                        1 1 0 1 0 0 1 1
                        0 0 1 1 0 1 0 1
                        0 1 1 0 1 0 1 1
                        0 1 0 1 0 1 0 1
                    ],
                )
                @test QuantumLegos.eliminate_column!(cmat, 2, [1]) == 3
                @test cmat.cmat == Bool[
                    1 0 1 1 1 0 0 0
                    0 0 1 1 0 1 0 1
                    0 1 1 0 1 0 1 1
                    0 0 1 1 1 1 1 0
                ]
            end
            let
                cmat = QuantumLegos.CheckMatrix(
                    Bool[
                        1 1 0 1 0 0 1 1
                        0 0 1 1 0 1 0 1
                        0 1 1 0 1 0 1 1
                        0 1 0 1 0 1 0 1
                    ],
                )
                @test QuantumLegos.eliminate_column!(cmat, 2, [1, nothing]) == 3
                @test cmat.cmat == Bool[
                    1 0 1 1 1 0 0 0
                    0 0 1 1 0 1 0 1
                    0 1 1 0 1 0 1 1
                    0 0 1 1 1 1 1 0
                ]
            end
            let
                cmat = QuantumLegos.CheckMatrix(
                    Bool[
                        1 0 0 0 1 1 0 1
                        0 1 0 1 0 1 1 0
                        0 1 0 0 0 1 0 0
                        1 1 0 1 0 0 0 1
                    ],
                )
                @test QuantumLegos.eliminate_column!(cmat, 3, Int[]) === nothing
            end
            let
                # random test (robustness)
                function random_test()::Bool
                    test_mat = rand(Bool, (8, 16))
                    cmat = QuantumLegos.CheckMatrix(copy(test_mat))
                    keep_indices = (1:8)[rand(1:8, rand(0:8))]
                    keep_index = rand(1:16)
                    try
                        QuantumLegos.eliminate_column!(cmat, keep_index, keep_indices)
                        return true
                    catch e
                        # unexpected error
                        @error "Error on eliminate_column! with keep_index: $(keep_index), avoid: $(keep_indices), matrix:" cmat
                        @error "error: " e
                        return false
                    end
                end

                for i in 1:100
                    # @info i
                    @test random_test()
                end
            end
            @testset "ArgumentError" begin
                cmat = CheckMatrix(rand(Bool, (6, 12)))
                @test_throws ArgumentError QuantumLegos.eliminate_column!(cmat, 3, [1, 7])
            end
        end
        @testset "swap_row!" begin
            let
                m = rand(Bool, (10, 10))
                m_copy = copy(m)
                QuantumLegos.swap_row!(m, 3, 7)
                QuantumLegos.swap_row!(m, 3, 7)
                @test m == m_copy
            end
            let
                m = rand(Bool, (10, 10))
                m = BitMatrix(m)
                m_copy = copy(m)
                QuantumLegos.swap_row!(m, 4, 2)
                QuantumLegos.swap_row!(m, 4, 2)
                @test m == m_copy
            end
        end
        @testset "align_row!" begin
            mat = Bool[
                1 0 1 1 0 0 1 0
                0 1 0 1 0 1 0 0
                1 1 1 0 0 1 0 0
                1 0 0 1 0 1 0 0
            ]
            mat_1 = copy(mat)
            @test 1 == QuantumLegos.align_row!(mat_1, 3, Int64[])
            @test mat_1 == Bool[
                1 1 1 0 0 1 0 0
                0 1 0 1 0 1 0 0
                1 0 1 1 0 0 1 0
                1 0 0 1 0 1 0 0
            ]
            mat_1 = copy(mat)
            @test 1 == QuantumLegos.align_row!(mat_1, 3, [nothing])
            @test mat_1 == Bool[
                1 1 1 0 0 1 0 0
                0 1 0 1 0 1 0 0
                1 0 1 1 0 0 1 0
                1 0 0 1 0 1 0 0
            ]
            mat_2 = copy(mat)
            @test 2 == QuantumLegos.align_row!(mat_2, 3, [1])
            @test mat_2 == Bool[
                1 0 1 1 0 0 1 0
                1 1 1 0 0 1 0 0
                0 1 0 1 0 1 0 0
                1 0 0 1 0 1 0 0
            ]
            mat_3 = copy(mat)
            @test 3 == QuantumLegos.align_row!(mat_3, 3, [1, nothing, 3])
            @test mat_3 == Bool[
                1 0 1 1 0 0 1 0
                0 1 0 1 0 1 0 0
                1 1 1 0 0 1 0 0 # 3
                1 0 0 1 0 1 0 0 # 4
            ]
            mat_3_2 = copy(mat_3)
            @test 4 == QuantumLegos.align_row!(mat_3, 4, [1, nothing, 3])
            @test mat_3 == mat_3_2
            @test nothing === QuantumLegos.align_row!(mat_3, nothing, [1, 2])
            @test nothing === QuantumLegos.align_row!(mat_3, nothing, [1, 2, nothing])
            @test nothing === QuantumLegos.align_row!(mat_3, nothing, [nothing])
        end
        @testset "ref!" begin
            @testset "compare with AbstractAlgebra" begin
                # test using existing package
                using AbstractAlgebra
                F₂ = GF(2) # finite field

                """
                Compare self-implemented `ref!` with AbstractAlgebra's `rref!` or `rank`.
                """
                function random_test(size::Tuple{T, T}) where {T <: Integer}
                    mat = rand(Bool, size)
                    cmat = CheckMatrix(mat)
                    S = matrix_space(F₂, size...)
                    cmat_aa = S(F₂.(mat))
                    # r_aa, A_aa = AbstractAlgebra.rref(cmat_aa)
                    # cmat_aa = A_aa.entries .|> ==(1) |> Matrix{Bool} |> CheckMatrix
                    r_aa = rank(cmat_aa)
                    r = QuantumLegos.ref!(cmat)
                    # @info "compare cmat" cmat cmat_aa
                    @test r == r_aa
                end
                for _ in 1:10
                    random_test((2, 4))
                    random_test((4, 8))
                    random_test((100, 200))
                end
            end
            @testset "manual sample" begin
                import LinearAlgebra
                mat =
                    Bool[1 0 0 1 1 0 0 0; 0 1 0 0 1 1 0 1; 0 0 1 1 0 1 0 1; 0 1 0 0 1 0 0 1]
                cmat = CheckMatrix(mat)
                @test QuantumLegos.ref!(cmat) == LinearAlgebra.rank(mat)
                @test cmat == CheckMatrix(
                    Bool[
                        1 0 0 1 1 0 0 0
                        0 1 0 0 1 1 0 1
                        0 0 1 1 0 1 0 1
                        0 0 0 0 0 1 0 0
                    ],
                    4,
                    4,
                )
                let
                    mat = copy(mat)
                    dependent_row = reduce(.⊻, eachrow(mat)[[1, 2]])
                    mat[4, :] = dependent_row
                    cmat = CheckMatrix(mat)
                    @test QuantumLegos.ref!(cmat) == LinearAlgebra.rank(mat) == 3
                end
                let
                    mat = copy(mat)
                    dependent_row = reduce(.⊻, eachrow(mat)[[1, 2]])
                    mat = vcat(mat, dependent_row')
                    dependent_row = reduce(.⊻, eachrow(mat)[[1, 2, 3]])
                    mat = vcat(mat, dependent_row')
                    dependent_row = reduce(.⊻, eachrow(mat)[[2, 4]])
                    mat = vcat(mat, dependent_row')
                    cmat = CheckMatrix(mat)
                    @test QuantumLegos.ref!(cmat) == rank(mat) == 3
                end
            end
            @testset "generated group is invariant under ref!" begin
                for _ in 1:10
                    cmat = CheckMatrix(rand(Bool, (8, 12)))
                    before = cmat |> generators |> GeneratedPauliGroup |> Set
                    QuantumLegos.ref!(cmat)
                    @test cmat |> generators |> GeneratedPauliGroup |> Set |> ==(before)
                end
            end
        end
        @testset "eliminate_dependent_row!" begin
            @testset "trivial" begin
                cmat = CheckMatrix(
                    Bool[
                        1 0 0 1 0 1 0 1
                        0 1 1 0 0 1 1 0
                        0 0 0 1 1 0 1 0
                        0 0 0 0 0 0 0 0
                    ],
                )
                @test QuantumLegos.eliminate_dependent_row!(cmat) == CheckMatrix(
                    Bool[1 0 0 1 0 1 0 1; 0 1 1 0 0 1 1 0; 0 0 0 1 1 0 1 0],
                    4,
                    3,
                )
            end
            @testset "less trivial" begin
                cmat = CheckMatrix(
                    Bool[
                        1 0 0 1 0 1 0 1
                        0 1 1 0 0 1 1 0
                        0 0 0 1 1 0 1 0
                        1 1 1 1 0 0 1 1
                    ],
                )
                @test QuantumLegos.eliminate_dependent_row!(cmat) == CheckMatrix(
                    Bool[1 0 0 1 0 1 0 1; 0 1 1 0 0 1 1 0; 0 0 0 1 1 0 1 0],
                    4,
                    3,
                )
            end
            # TODO: add more?
        end
        @testset "self_trace!" begin
            cmat = CheckMatrix(rand(Bool, (8, 16)))
            @test_throws ArgumentError QuantumLegos.self_trace!(cmat, 16, 17)
            @test_throws ArgumentError QuantumLegos.self_trace!(cmat, 18, 17)
        end
    end

    @testset "State" begin
        @testset "LegoLeg" begin
            @test LegoLeg(0, 1) < LegoLeg(1, 0)
            @test LegoLeg(2, 1) > LegoLeg(1, 0)
            @test LegoLeg(1, 0) < LegoLeg(1, 1)
            @test LegoLeg(1, 1) == LegoLeg(1, 1)

            @test sort(LegoLeg.([(1, 2), (2, 3), (0, 2), (0, 1)])) ==
                  LegoLeg[LegoLeg(0, 1), LegoLeg(0, 2), LegoLeg(1, 2), LegoLeg(2, 3)]
        end
        @testset "edge" begin
            @test edge(1, 2, 3, 4) == (LegoLeg(1, 2), LegoLeg(3, 4))
            @test edge((1, 2, 3, 4)) == (LegoLeg(1, 2), LegoLeg(3, 4))
            @test edge(((1, 2), (3, 4))) == (LegoLeg(1, 2), LegoLeg(3, 4))
        end
        @testset "0 lego, 0 leg" begin
            @test_throws ArgumentError QuantumLegos.State(Lego{6}[], Tuple{LegoLeg, LegoLeg}[])
        end
        @testset "1 lego, 0 leg" begin
            stabgens = pauliop.(["IIXX", "XXII", "IZZI", "ZIIZ"])
            lego = QuantumLegos.Lego(stabgens)
            state = QuantumLegos.State([lego], Tuple{LegoLeg, LegoLeg}[])
            cmat = QuantumLegos.checkmatrix(stabgens)
            @test state == QuantumLegos.State([lego], Tuple{LegoLeg, LegoLeg}[])
            @test state.legos == [lego]
            @test state.edges == Tuple{LegoLeg, LegoLeg}[]
            @test state.cmat == cmat
        end
        @testset "2+ legos, 0 leg" begin
            stabgens = pauliop.(["IIXX", "XXII", "IZZI", "ZIIZ"])
            lego = QuantumLegos.Lego(stabgens)
            state_1 = QuantumLegos.State([lego], Tuple{LegoLeg, LegoLeg}[])
            add_lego!(state_1, lego)
            @test state_1.legos == [lego, lego]
            @test state_1.edges == Tuple{LegoLeg, LegoLeg}[]
            @test state_1.cmat.ngens == 8
            @test state_1.cmat.nlegs == 8
            state_2 = QuantumLegos.State([lego, lego], Tuple{LegoLeg, LegoLeg}[])
            @test state_1 == state_2
            @test all(state_2.cmat.cmat[5:8, 1:4] .== false) # block diagonal
        end
        @testset "2+ legos, 1+ legs" begin
            stabgens = pauliop.(["IIXX", "XXII", "IZZI", "ZIIZ"])
            lego = QuantumLegos.Lego(stabgens)
            @test_throws ArgumentError State([lego, lego], edge.([(1, 1, 1, 1)]))
        end
        @testset "is_connected_to_firstlego" begin
            stabilizers = pauliop.(["IIXXXX", "IIZZZZ", "ZIZIZI", "IZIZIZ", "IXIIXX", "XIXXII"])
            lego = Lego(stabilizers)
            let
                state =
                    State(fill(lego, 6), edge.([(3, 2, 1, 5), (5, 2, 3, 3), (4, 1, 5, 1)]))
                @test QuantumLegos.is_connected_to_firstlego(state) ==
                      BitVector([1, 0, 1, 1, 1, 0])
            end
            let
                state = State(
                    fill(lego, 7),
                    edge.([(3, 2, 1, 5), (5, 2, 3, 3), (4, 1, 5, 1), (2, 2, 3, 1)]),
                )
                @test QuantumLegos.is_connected_to_firstlego(state) ==
                      BitVector([1, 1, 1, 1, 1, 0, 0])
            end
        end
    end

    @testset "Doctest" begin
        DocMeta.setdocmeta!(
            QuantumLegos,
            :DocTestSetup,
            :(using QuantumLegos; ENV["JULIA_DEBUG"] = "");
            recursive = true,
        )
        doctest(QuantumLegos)
    end

    # @testset "Code quality (Aqua.jl)" begin
    #     Aqua.test_all(QuantumLegos)
    # end
    # @testset "Code linting (JET.jl)" begin
    #     JET.test_package(QuantumLegos; target_defined_modules = true)
    # end
end
