using KM3Acoustics
using KM3io
using Test

const SAMPLES_DIR = joinpath(@__DIR__, "samples")

@testset "soundvelocity" begin
    @test SoundVelocity(1541.0, -2000.0) == velocity(-2000.0)
    @test SoundVelocity(1541.0, -2000.0) == velocity(0.0, -2000.0)
    @test SoundVelocity(1558.0, -3000.0) == velocity(-3000.0)
    @test SoundVelocity(1558.0, -3000.0) == velocity(-1000.0, -2000.0)

    pos_tripod = Position(0.0,0.0,-3000.0)
    pos_tripod_rel = Position(0.0, 0.0, -1000.0)
    tripod = Tripod(1, pos_tripod)
    tripod_rel = Tripod(1, pos_tripod_rel)
    @test SoundVelocity(1558.0, -3000.0) == velocity(tripod)
    @test SoundVelocity(1558.0, -3000.0) == velocity(tripod_rel, -2000.0)
    pos_mod = Position(100.0,0.0,-3000.0)
    pos_mod_rel = Position(100.0,0.0,-1000.0)
    mod = DetectorModule(1, pos_mod, Location(0, 0), 0, PMT[], missing, 0, 0)
    mod_rel = DetectorModule(1, pos_mod_rel, Location(0, 0), 0, PMT[], missing, 0, 0)
    @test SoundVelocity(1558.0, -3000.0) == velocity(mod)
    @test SoundVelocity(1558.0, -3000.0) == velocity(mod_rel, -2000.0)

    pos_mod1 = Position(0.0,0.0,-2000.0)
    mod1 = DetectorModule(1, pos_mod1, Location(0, 0), 0, PMT[], missing, 0, 0)
    pos_mod1_rel = Position(0.0,0.0,0.0)
    mod1_rel = DetectorModule(1, pos_mod1_rel, Location(0, 0), 0, PMT[], missing, 0, 0)
    mod2 = DetectorModule(1, Position(1541.0,0.0,-2000.0), Location(0, 0), 0, PMT[], missing, 0, 0)
    mod2_rel = DetectorModule(1, Position(1541.0,0.0, 0.0), Location(0, 0), 0, PMT[], missing, 0, 0)
    @test 0.06418485237483953 ≈ traveltime(tripod, mod)
    @test 0.06418485237483953 ≈ traveltime(tripod_rel, mod_rel, -2000.0)
    @test 0.06418485237483953 ≈ traveltime(mod, tripod)
    @test 0.06418485237483953 ≈ traveltime(mod_rel, tripod_rel, -2000.0)
    @test 0.6453759476810511 ≈ traveltime(tripod, mod1)
    @test 0.6453759476810511 ≈ traveltime(tripod_rel, mod1_rel, -2000.0)
    @test 0.6453759476810511 ≈ traveltime(mod1, tripod)
    @test 0.6453759476810511 ≈ traveltime(mod1_rel, tripod_rel, -2000.0)
    @test 1.0 ≈ traveltime(mod1, mod2)
    @test 1.0 ≈ traveltime(mod1_rel, mod2_rel, -2000.0)

    emitter = Emitter(1,Position(0.0,0.0,-3000.0))
    @test SoundVelocity(1558.0, -3000.0) == velocity(emitter)

    receiver = Receiver(1, Position(100.0,0.0,-3000.0), Location(1,1), 0.0)
    @test SoundVelocity(1558.0, -3000.0) == velocity(receiver)

    receiver1 = Receiver(1, Position(0.0,0.0,-2000.0), Location(1,1), 0.0)
    @test 0.06418485237483953 ≈ traveltime(emitter, receiver)
    @test 0.06418485237483953 ≈ traveltime(receiver, emitter)
    @test 0.6453759476810511 ≈ traveltime(emitter, receiver1)
    @test 0.6453759476810511 ≈ traveltime(receiver1, emitter)

    @test 0.032452012674856874 ≈ traveltime(50.0, 1.0, 30.0, -2000.0)
    @test 0.032452012674856874 ≈ traveltime(50.0, -1999.0, -1970.0)
    @test 1.0 ≈ traveltime(1541.0, -2000.0, -2000.0)
    @test 1.0 ≈ traveltime(1541.0, 0.0, 0.0, -2000.0)


    @test 0.6453759476810511 ≈ traveltime(pos_tripod, pos_mod1)
    @test 0.6453759476810511 ≈ traveltime(pos_tripod_rel, pos_mod1_rel, -2000.0)

    @test 1.0 ≈ traveltime(Position(1541.0, 0.0, -2000.0), Position(0.0, 0.0, -2000.0))
    @test 1.0 ≈ traveltime(Position(1541.0, 0.0, 0.0), Position(0.0, 0.0, 0.0), -2000.0)

end
