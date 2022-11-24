using KM3Acoustics
using Test

const SAMPLES_DIR = joinpath(@__DIR__, "samples")

@testset "precalibration" begin
    detector = Detector(joinpath(SAMPLES_DIR, "KM3NeT_00000133_00013346.detx"))
    events = read_events(joinpath(SAMPLES_DIR, "KM3NeT_00000133_00013346_preevent.h5"), 13346)
    hydrophones = get_hydrophones(joinpath(SAMPLES_DIR, "hydrophone.txt"), detector, events)
    @test 15 == length(hydrophones)
    @test 10 == collect(keys(hydrophones))[1]
    @test 30 == collect(keys(hydrophones))[end]
    emitters = read(joinpath(SAMPLES_DIR, "tripod.txt"), Emitter, detector)
    fixhydro = [(10, :x), (10, :y), (10, :z)]
    fixemitter = []
    pc = Precalibration(detector.pos, events, hydrophones, fixhydro, emitters, fixemitter, rotate=0, nevents=2)
    @test 72 == length(pc.p0s)
    @test -137.45999999999998 ≈ pc.p0s[1]
    ps = unwrap(pc.p0s, pc)
    pos_hydro, pos_emitter, toes = split_p(ps, pc)
    @test Position(52.77, 180.185, 2.420014848519585) == pos_hydro[1]
    @test Position(-401.3719999999739, -571.3070000000298, 16.69399999999996) == pos_emitter[1]
    @test toes[1] == eventtime(pc.events[7][1])
    @test 2 == length(pc.events[7])
    pc1 = Precalibration(detector.pos, events, hydrophones, fixhydro, emitters, fixemitter, rotate=0, nevents=2, mask=2:2)
    @test 1 == length(pc1.events[7])
    @test toes[2] == eventtime(pc1.events[7][1])

    testhydros = Dict([(1, Hydrophone(Location(0, 0), Position(0.0, 1.0, 0.0))), (2, Hydrophone(Location(0, 0), Position(1.0, 0.0, 0.0)))])
    testtripods = Dict([(1, Emitter(1, Position(0.0, -1.0, 1.0)))])
    rothydros, rottripods, ϕ = rotate_detector(testhydros, testtripods, Position(0.0,1.0, 0.0))
    @test Position(1.0, 0.0, 0.0) ≈ rothydros[1].pos
    @test Position(-1.0, 0.0, 1.0) ≈ rottripods[1].pos
    @test pi/2 ≈ ϕ
    rerothydros, rerottripods = rerotate_detector(rothydros, rottripods, ϕ)
    @test testhydros[1].pos ≈ rerothydros[1].pos
    @test testtripods[1].pos ≈ rerottripods[1].pos
    # pc = Precalibration(detector.pos, events, hydrophones, fixhydro, emitters, fixemitter, nevent=5)

    # pc = Precalibration(detector.pos, hydrophones, 10, events, emitters, numevents=3)
    # @test Position(587600.0, 4.0168e6, -3450.0) ≈ pc.detector_pos
    # @test 15 == length(pc.hydrophones)
    # @test 10 == collect(keys(pc.hydrophones))[1]
    # @test 30 == collect(keys(pc.hydrophones))[end]
    # @test 6 == pc.nevents
    # @test 7 == collect(keys(pc.emitters))[1]
    # @test 13 == collect(keys(pc.emitters))[end]
    # p0 = precalibration_startvalues(pc)
    # @test 63 == length(p0)
    # @test 1.6643716922418897e9 ≈ p0[end]
    # @test -137.46 ≈ p0[1]
    # @test -2.37144897891234e7 ≈ pc(p0)
    # @test 3.6103302860852994e7 ≈ pc(p0...)
    # @test emitters == get_opt_emitters(pc, p0)
    # @test hydrophones == get_opt_hydrophones(pc, p0)
end

@testset "statistics" begin
    events = read_events(joinpath(SAMPLES_DIR, "KM3NeT_00000133_00013346_preevent.h5"), 13346)
    @test 1.6643707765755563e9 ≈ mean(events[1], :TOE)
    @test 0.0037644351140815745 ≈ std(events[1], :TOE)
end
