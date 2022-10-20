using Test


@testset "KM3Acoustics.jl" begin
    include("io.jl")
    include("tools.jl")
    include("types.jl")
    include("utils.jl")
    include("acoustics.jl")
    include("soundvelocity.jl")
    include("eventbuilder.jl")
    include("calibration.jl")
end
