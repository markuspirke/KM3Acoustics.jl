using Test


@testset "KM3Acoustics.jl" begin
    include("io.jl")
    include("tools.jl")
    include("utils.jl")
    include("soundvelocity.jl")
end
