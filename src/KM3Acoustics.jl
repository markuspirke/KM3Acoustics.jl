module KM3Acoustics

using Dates
import Base: read, write, isless
using LinearAlgebra
using Random
using Setfield
using AngleBetweenVectors
using Statistics
using Printf
using StaticArrays
using HDF5
import DataStructures: DefaultDict
import OrderedCollections: OrderedDict

export
    Detector, Hydrophone, Tripod, Waveform, DetectorModule, PMT,
    Position, UTMPosition, Location,
    TriggerParameter,
    hydrophoneenabled, piezoenabled, write_compound, natural, parse_runs,
    Quaternion, Direction,
    read, write,
    mean, std,
    ASignal,
    SoundVelocity, velocity, traveltime,
    read_toashort, RawToashort, Toashort, Emitter, tripod_to_emitter, emitter_to_tripod,
    Receiver, Transmission, Event, isless, overlap, save_events, check_basemodules,
    read_events, group_events, eventtime,
    get_basemodules, ToyStringCalibration, StringCalibration, chi2,
    init_toydetector, init_realdetector,
    ToyString, ToyModule, ToyDetector, toy_calc_pos, toy_calc_traveltime,
    string_length, string_inverselength, calc_pos, calc_traveltime,
    get_hydrophones, Precalibration, precalibration_startvalues, rotate_detector, rerotate_detector,
    sort_fitevents, group_fitevents, generate_startvalues, lookuptable_hydrophones,
    unwrap, split_p, get_opt_modules, precalib_detector,
    inverse_waveforms, simulation_times, signal_impulses, acoustic_event, save_rawtoashorts


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
include("geometry.jl")
include("calibration.jl")
include("precalibration.jl")
include("statistics.jl")
include("simulation.jl")
end
