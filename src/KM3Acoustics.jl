module KM3Acoustics

using Dates

using StaticArrays
using WAV
using Plots

using CSV
using DataFrames

export
   read_asignal, plot_asignal, to_wav

for inc ∈ readdir(joinpath(@__DIR__, "definitions"), join=true)
    include(inc)
end

include("types.jl")
include("tools.jl")
include("io.jl")
include("acoustics.jl")
include("acoustics_eventbuilder.jl")
end
