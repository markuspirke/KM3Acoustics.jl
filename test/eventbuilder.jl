using KM3Acoustics
using Test

const SAMPLES_DIR = joinpath(@__DIR__, "samples")

@testset "eventbuilder" begin
    df = read_toashort(joinpath(SAMPLES_DIR, "input_toashort.csv"))
    @test 11190 == df.RUN[1]
    @test 808960332 == df.DOMID[1]
    @test -13 == df.EMITTERID[1]
    @test 2270 == df.QUALITYFACTOR[1]
    @test 1.6358893684634418e9 ≈ df.UTC_TOA[1]

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
