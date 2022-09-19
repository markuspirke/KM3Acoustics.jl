import KM3Acoustics: Detector, Hydrophone, Position, UTMPosition, Location, Quaternion, Tripod
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
        @test 3 == length(tripods)
        @test 1 == tripods[1].id
        @test Position(256877.500, 4743716.700, -2437.314) ≈ tripods[1].pos
        @test 3 == tripods[end].id
        @test Position(257096.200, 4743636.000, -2439.354) ≈ tripods[end].pos
    end
end
