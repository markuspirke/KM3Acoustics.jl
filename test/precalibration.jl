using KM3Acoustics
using Test

const SAMPLES_DIR = joinpath(@__DIR__, "samples")

@testset "precalibration" begin
    detector = Detector(joinpath(SAMPLES_DIR, "v5.detx"))
    events = read_events(joinpath(SAMPLES_DIR, "KM3NeT_00000133_00013346_preevent.h5"), 13346)
    hydrophones = get_hydrophones(joinpath(SAMPLES_DIR, "hydrophone.txt"), detector, events)
    @test 15 == length(hydrophones)
    @test 10 == collect(keys(hydrophones))[1]
    @test 30 == collect(keys(hydrophones))[end]
    tripods = read(joinpath(SAMPLES_DIR, "tripod.txt"), Tripod)
    emitters = tripod_to_emitter(tripods, detector)
    pc = Precalibration(detector.pos, hydrophones, 10, events, emitters)
    @test Position(587600.0, 4.0168e6, -3450.0) ≈ pc.detector_pos
    @test 15 == length(pc.hydrophones)
    @test 10 == collect(keys(pc.hydrophones))[1]
    @test 30 == collect(keys(pc.hydrophones))[end]
    @test 8 == pc.nevents
    @test 3 == collect(keys(pc.emitters))[1]
    @test 10 == collect(keys(pc.emitters))[end]
    p0 = precalibration_startvalues(pc)
    @test 65 == length(p0)
    @test 1.6643716922418897e9 ≈ p0[end]
    @test -137.46 ≈ p0[1]
    @test 1.4789626721357605e8 ≈ pc(p0)
    @test 1.4789626721357605e8 ≈ pc(p0...)
    @test emitters == get_opt_emitters(pc, p0)
    @test hydrophones == get_opt_hydrophones(pc, p0)
end
