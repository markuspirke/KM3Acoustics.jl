using KM3Acoustics
using KM3io
using Test

@testset "geometry" begin
    toystring = ToyString(1, Position(0.0, 0.0, 0.0), 0.0, 0.0, [30.0, 40.0, 50.0])
    @test Position(0.0, 0.0, 0.0) == toy_calc_pos(0.0, 0.0, 0.0)
    @test Position(0.0, 0.0, 30.0) == toy_calc_pos(0.0, 0.0, toystring.lengths[1])
    @test 0.06461493383755239 ≈ toy_calc_traveltime(0.0, 0.0, 100.0, Position(0.0, 0.0, 0.0), Position(0.0, 0.0, 0.0))
    a = 0.00311
    b = 85.1
    dx = 0.1
    dy = 0.1
    @test 100.6780399628396 ≈ string_length(dx, dy, 100.0, a, b)
    @test 100.0 ≈ string_inverselength(dx, dy ,  100.6780399628396, a, b)
    @test Position(0.0, 0.0, 100.0) ≈ calc_pos(0.0, 0.0, 100.0, 0.0, 0.0)
    @test Position(10.0, 10.0, 100.0) ≈ calc_pos(0.1, 0.1, 100.6780399628396, a, b)
    @test 0.06525788433842991 ≈ calc_traveltime(dx, dy, 100.6780399628396, a, b, Position(0.0,0.0,0.0), Position(0.0,0.0,0.0))

end
