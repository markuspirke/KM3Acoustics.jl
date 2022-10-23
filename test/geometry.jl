using KM3Acoustics
using Test

@testset "geometry" begin
    toystring = ToyString(1, Position(0.0, 0.0, 0.0), 0.0, 0.0, 30.0, 10.0)
    @test ToyModule(1, Location(1, 0), Position(0.0, 0.0, 0.0)) == toy_position(0.0, 0.0, 0, toystring)
    @test ToyModule(1, Location(1, 1), Position(0.0, 0.0, 30.0)) == toy_position(0.0, 0.0, 1, toystring)
    @test ToyModule(1, Location(1, 2), Position(0.0, 0.0, 40.0)) == toy_position(0.0, 0.0, 2, toystring)
    @test 0.025837456976183806 ≈ toy_toa([0.0, 0.0, 0.0], 2, Emitter(1, Position(0.0, 0.0, 0.0)), toystring)
end
