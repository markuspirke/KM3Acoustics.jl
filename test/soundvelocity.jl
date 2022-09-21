using KM3Acoustics

@testset "soundvelocity" begin
    @test SoundVelocity(1541.0, -2000.0) == get_velocity(-2000.0)
    @test SoundVelocity(1558.0, -3000.0) == get_velocity(-3000.0)

    tripod = Tripod(1,Position(1000.0,1000.0,-3000.0))
    @test SoundVelocity(1558.0, -3000.0) == get_velocity(tripod)

    # test of get_veloctiy(module) and get_time missing
end
