using KM3Acoustics
using Test

const SAMPLES_DIR = joinpath(@__DIR__, "samples")

@testset "simulation" begin
    waveform = read(joinpath(SAMPLES_DIR, "waveform.txt"), Waveform)
    invwaveform = inverse_waveforms(waveform)
    @test 12 == invwaveform.ids[5]
    @test 23 == invwaveform.ids[4]
    @test -17 == invwaveform.ids[3]

    detector = Detector(joinpath(SAMPLES_DIR, "v5.detx"))
    emitters = read(joinpath(SAMPLES_DIR, "tripod.txt"), Emitter, detector)
    t0 = 0.0
    xs = simulation_times(t0, emitters)
    @test 0.0 == xs[1][2]
    @test 20.0 == xs[2][2]
    @test length(emitters) == length(xs)

    impulses = signal_impulses(t0)
    @test impulses[1] == 0.0
    @test impulses[2] == 5.0
    @test impulses[end] == 50.0

    hydrophones = read(joinpath(SAMPLES_DIR, "hydrophone.txt"), Hydrophone)
    basemodules = check_basemodules(detector, hydrophones)
    tshort = acoustic_event(detector, emitters[7], invwaveform, basemodules, t0, 123; p=1.0)
    @test length(basemodules) == length(tshort)
    @test traveltime(basemodules[tshort[1].DOMID], emitters[7], detector.pos.z) ≈ tshort[1].UNIXTIMEBASE
    @test 14 == tshort[1].EMITTERID
    @test 123 == tshort[1].RUNNUMBER
    @test 123 == tshort[1].RUN
    @test traveltime(basemodules[tshort[end].DOMID], emitters[7], detector.pos.z) ≈ tshort[end].UNIXTIMEBASE
    @test 14 == tshort[end].EMITTERID
    @test 123 == tshort[end].RUNNUMBER
    @test 123 == tshort[end].RUN

end
