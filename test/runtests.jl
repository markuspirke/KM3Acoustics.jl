import KM3Acoustics: Detector
using Test

const SAMPLES_DIR = joinpath(@__DIR__, "samples")

@testset "KM3Acoustics.jl" begin
    for version ∈ 1:5
        d = Detector(joinpath(SAMPLES_DIR, "v$(version).detx"))
        if version < 4
            # no base modules in DETX
            @test 342 == length(d.modules)
        else
            @test 361 == length(d.modules)
        end
    end
end
