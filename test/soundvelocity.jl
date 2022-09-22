using KM3Acoustics
using Test

@testset "soundvelocity" begin
    @test SoundVelocity(1541.0, -2000.0) == velocity(-2000.0)
    @test SoundVelocity(1558.0, -3000.0) == velocity(-3000.0)

    tripod = Tripod(1,Position(0.0,0.0,-3000.0))
    @test SoundVelocity(1558.0, -3000.0) == velocity(tripod)

    mod = DetectorModule(1, Position(100.0,0.0,-3000.0), Location(0, 0), 0, PMT[], missing, 0, missing)
    @test SoundVelocity(1558.0, -3000.0) == velocity(mod)

    mod1 = DetectorModule(1, Position(0.0,0.0,-2000.0), Location(0, 0), 0, PMT[], missing, 0, missing)
    @test 0.06418485237483953 ≈ traveltime(tripod, mod)
    @test 0.06418485237483953 ≈ traveltime(mod, tripod)
    @test 0.6453759476810511 ≈ traveltime(tripod, mod1)
    @test 0.6453759476810511 ≈ traveltime(mod1, tripod)
    # test of get_veloctiy(module) and get_time missing
end
