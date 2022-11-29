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


end
