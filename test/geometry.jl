using KM3Acoustics
using Test

@testset "geometry" begin
    toystring = ToyString(1, Position(0.0, 0.0, 0.0), 0.0, 0.0, 30.0, 10.0)
    @test ToyModule(1, Location(1, 0), Position(0.0, 0.0, 0.0)) == toy_position(0.0, 0.0, 0, toystring)
end
