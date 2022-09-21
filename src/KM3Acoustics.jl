module KM3Acoustics

using Dates
import Base: read

using StaticArrays
using WAV
using Plots

using CSV
using DataFrames

export
    Detector, Hydrophone, Tripod, DetectorModule, PMT, Position, UTMPosition, Location,
    hydrophoneenabled, piezoenabled,
    Quaternion,
    read,
    plot_asignal, to_wav,
    SoundVelocity, get_velocity, get_time


for inc ∈ readdir(joinpath(@__DIR__, "definitions"), join=true)
    include(inc)
end

include("types.jl")
include("tools.jl")
include("io.jl")
include("utils.jl")
include("acoustics.jl")
include("soundvelocity.jl")
include("acoustics_eventbuilder.jl")
end
