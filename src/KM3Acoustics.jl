module KM3Acoustics

using Dates
import Base: read, isless
using LinearAlgebra
using Statistics
using StaticArrays

using HDF5
# import DataStructures: DefaultDict

export
    Detector, Hydrophone, Tripod, Waveform, DetectorModule, PMT, Position, UTMPosition, Location,
    TriggerParameter,
    hydrophoneenabled, piezoenabled, write_compound, natural, parse_runs,
    Quaternion, Direction,
    read,
    ASignal,
    SoundVelocity, velocity, traveltime,
    read_toashort, Toashort, Emitter, tripod_to_emitter, Receiver, Transmission, Event, isless, overlap, save_events,
    read_events, group_events, eventtime,
    ToyString, ToyModule, ToyDetector, toy_position, toy_toa, loss

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
include("eventbuilder.jl")
include("calibration.jl")
include("geometry.jl")
end
