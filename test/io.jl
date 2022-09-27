using Test

using KM3Acoustics
using Dates

const SAMPLES_DIR = joinpath(@__DIR__, "samples")


@testset "io" begin
    @testset "DETX parsing" begin
        for version ∈ 1:5
            d = Detector(joinpath(SAMPLES_DIR, "v$(version).detx"))
            if version < 4
                # no base modules in DETX
                @test 342 == length(d.modules)
            else
                # base module attributes
                @test 361 == length(d.modules)
                @test 116.600007 ≈ d.modules[808992603].pos.x  # optical module
                @test 106.95 ≈ d.modules[808469291].pos.y  # base module
                @test 97.3720395 ≈ d.modules[808974928].pos.z  # base module
                @test Quaternion(1, 0, 0, 0) ≈ d.modules[808995481].q
                @test 0.0 ≈ d.modules[808966287].t₀
                if version > 5
                    # module status introduced in v5
                    @test 0 == d.modules[808966287].status
                end
            end

            if version > 1
                @test UTMPosition(587600, 4016800, -3450) ≈ d.pos
                @test 1654207200.0 == datetime2unix(d.validity.from)
                @test 9999999999.0 == datetime2unix(d.validity.to)
            end

            @test 31 == d.modules[808992603].n_pmts
            @test 30 ≈ d.modules[817287557].location.string
            @test 18 ≈ d.modules[817287557].location.floor
        end
    end
    @testset "hydrophones" begin
        hydrophones = read(joinpath(SAMPLES_DIR, "hydrophone.txt"), Hydrophone)
        @test 19 == length(hydrophones)
        @test Location(10, 0) == hydrophones[1].location
        @test Position(0.770, -0.065, 1.470) ≈ hydrophones[1].pos
        @test Location(28, 0) == hydrophones[end].location
        @test Position(0.770, -0.065, 1.470) ≈ hydrophones[end].pos
    end

    @testset "tripod" begin
        tripods = read(joinpath(SAMPLES_DIR, "tripod.txt"), Tripod)
        @test 5 == length(tripods)
        @test 3 == tripods[1].id
        @test Position(587848.700, +4016749.700, -3450.467) ≈ tripods[1].pos
        @test 10 == tripods[end].id
        @test Position(587763.722, 4.017253398e6, -3453.894) ≈ tripods[end].pos
    end

    @testset "waveform" begin
        waveform = read(joinpath(SAMPLES_DIR, "waveform.txt"), Waveform)
        @test 10 == length(waveform.ids)
        @test waveform.ids[16] == 3
        @test waveform.ids[-15] == 7
    end

    @testset "utilities" begin
        mod = DetectorModule(1, missing, Location(0, 0), 0, PMT[], missing, 0, missing)
        @test hydrophoneenabled(mod)
        @test piezoenabled(mod)
    end
end
