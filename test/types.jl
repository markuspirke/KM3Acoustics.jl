using KM3Acoustics
using Test

@testset "types" begin
    @test Direction(0.0, 0.0, 1.0) ≈ Direction(0.0, 0.0)
    @test Direction(0.0, 1.0, 0.0) ≈ Direction(pi/2, pi/2)
end
