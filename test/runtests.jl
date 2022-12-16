using Test


@testset "KM3Acoustics.jl" begin
    include("soundvelocity.jl")
    include("eventbuilder.jl")
    include("geometry.jl")
    include("calibration.jl")
    include("precalibration.jl")
    include("simulation.jl")
end
