using KM3Acoustics
using Test

const SAMPLES_DIR = joinpath(@__DIR__, "samples")


@testset "utils" begin
    mod = DetectorModule(1, missing, Location(0, 0), 0, PMT[], missing, 0, missing)
    @test hydrophoneenabled(mod)
    @test piezoenabled(mod)

    status = 1 << KM3Acoustics.MODULE_STATUS.PIEZO_DISABLE
    mod = DetectorModule(1, missing, Location(0, 0), 0, PMT[], missing, status, missing)
    @test !piezoenabled(mod)
    @test hydrophoneenabled(mod)

    status = 1 << KM3Acoustics.MODULE_STATUS.HYDROPHONE_DISABLE
    mod = DetectorModule(1, missing, Location(0, 0), 0, PMT[], missing, status, missing)
    @test piezoenabled(mod)
    @test !hydrophoneenabled(mod)

    status = (1 << KM3Acoustics.MODULE_STATUS.HYDROPHONE_DISABLE) | (1 << KM3Acoustics.MODULE_STATUS.PIEZO_DISABLE)
    mod = DetectorModule(1, missing, Location(0, 0), 0, PMT[], missing, status, missing)
    @test !piezoenabled(mod)
    @test !hydrophoneenabled(mod)
end
