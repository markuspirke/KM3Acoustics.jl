using KM3Acoustics
using Test

@testset "eventbuilder" begin
    A = Transmission(1, 1, 1.0, 1.1, 0.0)
    B = Transmission(1, 1, 2.0, 1.1, 0.0)
    C = Transmission(1, 1, 1.0, 1.0, 0.0)

    @test false == isless(A, B) # A.TOA = B.TOA, but B.Q > A.Q => B should be first
    @test true == isless(B, A)
    @test false == isless(B, C) # C.TOA < B.TOA => C should be first
    @test true == isless(C, B)

    @test [B, A] == sort!([A, B])
    @test [B, A] == sort!([B, A])
    @test [C, B] == sort!([B, C])
    @test [C, B] == sort!([C, B])
end
