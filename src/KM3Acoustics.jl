module KM3Acoustics

using Dates
import Base: read

using LinearAlgebra
using StaticArrays
using WAV

using CSV
using DataFrames

export
    Detector, Hydrophone, Tripod, Waveform, DetectorModule, PMT, Position, UTMPosition, Location,
    hydrophoneenabled, piezoenabled,
    Quaternion,
    read,
    ASignal, to_wav,
    SoundVelocity, velocity, traveltime,
    remove_idevents, Emitter, Receiver, Transmission



for inc ∈ readdir(joinpath(@__DIR__, "definitions"), join=true)
    !endswith(inc, ".jl") && continue
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
