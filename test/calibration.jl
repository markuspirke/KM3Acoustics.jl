using KM3Acoustics
using Test
using HDF5

const SAMPLES_DIR = joinpath(@__DIR__, "samples")

@testset "calibration" begin
    events = read_events(joinpath(SAMPLES_DIR, "KM3NeT_00000049_00011190_event.h5"), 11190)
    @test 49 == events[1].oid
    @test 11190 == events[1].run
    @test 102 == length(events[1])
    @test 809503416 == events[1].data[1].id
    @test 308 == length(events)
    events = h5open(joinpath(SAMPLES_DIR, "KM3NeT_00000049_00011190_event.h5"), "r") do h5f
        read_events(h5f, 11190)
    end
    @test 49 == events[1].oid
    @test 11190 == events[1].run
    @test 102 == length(events[1])
    @test 809503416 == events[1].data[1].id
    @test 308 == length(events)

    gevents = group_events(events)
    @test 13 == length(gevents)
    @test 2 == length(gevents[1])
    @test 49 == gevents[1][1].oid
    @test 11190 == gevents[1][1].run
    @test 104 == gevents[1][1].length
    @test 2 == gevents[1][1].id
    @test 809503416 == gevents[1][1].data[1].id
    @test 3 == gevents[1][2].id

    gevents1 = KM3Acoustics.group_events1(events)
    @test 13 == length(gevents1)
    @test 23 == length(gevents1[1])
    @test 49 == gevents1[1][1].oid
    @test 11190 == gevents1[1][1].run
    @test 808960332 == gevents1[1][1].data[1].id

    @test 1.6358896064384315e9 ≈ eventtime(events[1])

    detector = Detector(joinpath(SAMPLES_DIR, "v5.detx"))
    basemodules = get_basemodules(detector.modules)
    @test 19 == length(basemodules)
    @test ToyModule(Location(21, 0), [28.28, 365.86, -7.63198515148041]) == basemodules[1]
    @test ToyModule(Location(19, 0), [184.32, 306.43, 0.950014848519585]) == basemodules[end]
    toydetector = init_toydetector(basemodules, detector.modules)
    @test 19 == length(toydetector.strings)
    @test Position(-22.2, 295.3, -6.60198515148041) == toydetector.strings[16].pos
    realdetector = init_realdetector(basemodules, detector.modules)
    @test 19 == length(toydetector.strings)
    @test Position(-22.2, 295.3, -6.60198515148041) == realdetector.strings[16].pos
    emitters = Dict{Int8, Emitter}()
    emitters[1] = Emitter(1, Position(0.0, 0.0, 0.0))
    testevent = Event(1, 1, 1, 1, Transmission[Transmission(809503416, 16, 1, 20345.0, 1.6358896516049924e9, 1.6358896514386847e9)])
    tscal = ToyStringCalibration(toydetector.strings[16], [testevent], emitters)
    @test 1.6358896514386847e9 ≈ tscal.time
    @test 16 == tscal.string
    @test Position(-22.2, 295.3, -6.60198515148041) == tscal.basepos
    @test 1 == tscal.events[1].id
    @test 16 == tscal.events[1].transmissions[1].string
    @test 1.6358896516049924e9 ≈ tscal.events[1].transmissions[1].TOA
    @test [69.60198060720671] ≈ tscal.events[1].lengths

    scal = StringCalibration(1.0, 1.0, realdetector.strings[16], [testevent], emitters)
    @test 1.0 ≈ scal.a
    @test 1.0 ≈ scal.b
    @test 1.6358896514386847e9 ≈ tscal.time
    @test 16 == tscal.string
    @test Position(-22.2, 295.3, -6.60198515148041) == tscal.basepos
    @test 1 == tscal.events[1].id
    @test 16 == tscal.events[1].transmissions[1].string
    @test 1.6358896516049924e9 ≈ tscal.events[1].transmissions[1].TOA
    @test [69.60198060720671] ≈ tscal.events[1].lengths

    @test 0.0 ≈ chi2([1.0, 2.0], [1.0, 2.0])
    @test 20000.0 ≈ chi2(1.0,2.0)
end
