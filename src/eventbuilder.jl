"""
RawToashort is an input data type which stores all information from the toashort file.
"""
struct RawToashort
    RUN::Int64
    RUNNUMBER::Int64
    UNIXTIMEBASE::Float64
    DOMID::Int64
    EMITTERID::Int64
    TOA_S::Float64
    QUALITYFACTOR::Int64
end
"""
Toashort is an input data type which stores all important information from the toashort file.
"""
struct Toashort
    RUN::Int32
    DOMID::Int32
    EMITTERID::Int8
    QUALITYFACTOR::Float64
    UTC_TOA::Float64
end
"""
    function read(file::HDF5.File, T::Type{Toashort}, run::Int)

Reads a HDF5 file of toashorts.
"""
function read(file::HDF5.File, T::Type{Toashort}, run::Int)
    raw_signals = read_toa(file, run)
    preprocess(raw_signals)
end
"""
    function read(filename::AbstractString, T::Type{Toashort}, run::Int)

Reads a HDF5 file of toashorts.
"""
function read(filename::AbstractString, T::Type{Toashort}, run::Int)
    file = h5open(filename, "r") do h5f
        read(h5f, T, run)
    end
    file
end
"""
    function read_toa(filename::AbstractString, run::Int)

Acts as a function barrier. Opens the H5 File and reads the dataset for a specific group.
"""
function read_toa(file::HDF5.File, run::Int)
    read(file["toashort/$(run)"], RawToashort)
end
"""
    function preprocess(raw_signals)

Calculates UTC TOA and removes duplicate data.
"""
function preprocess(raw_signals)
    toashorts = Toashort[]
    sizehint!(toashorts, length(raw_signals))
    for signal in raw_signals
        toa = signal.UNIXTIMEBASE + signal.TOA_S
        toa = round(toa, sigdigits=16)
        push!(toashorts, Toashort(signal.RUN, signal.DOMID, signal.EMITTERID, signal.QUALITYFACTOR, toa))
    end
    unique!(toashorts)
    toashorts
end

"""
Receivers are either DOMs with an piezo element or a baseunit with a hydrophone.
"""
struct Receiver
    id::Int32
    pos::Position
    location::Location
    t₀::Float64
end
"""
The tripods in the seabed are Emitters of acoustics signals.
"""
struct Emitter
    id::Int8
    pos::Position
end
"""
    function read(filename::AbstractString, Emitter, detector::Detector)

Reads in the tripod file, and return them as Emitters, where the positions are references
in the detector coordinate system.
"""
function read(filename::AbstractString, Emitter, detector::Detector)
    tripods = read(filename, Tripod)
    emitters = tripod_to_emitter(tripods, detector)
end
"""
    function tripod_to_emitter(tripods, detector)

Tripods position reference gets changed, such that the position is measured from the position of the detector.
Returns a dictionary.
"""
function tripod_to_emitter(tripods, detector)
    emitters = Dict{Int8, Emitter}()
    for tripod ∈ tripods # change position of tripods from .txt file to relative position of the detector
        emitters[tripod.id] = Emitter(tripod.id, tripod.pos - detector.pos)
    end
    emitters
end
"""
    function emitter_to_tripod(emitters::Dict{Int8, Emitter}, detector)

Takes in a dictionary of emitters and returns a vector of tripods.
"""
function emitter_to_tripod(emitters::Dict{Int8, Emitter}, detector)
    tripods = Tripod[]
    for (id, emitter) ∈ sort(emitters)# change position of tripods from .txt file to relative position of the detector
        push!(tripods, Tripod(id, emitter.pos + detector.pos))
    end
    tripods
end
"""
    function check_modules!(receivers, detector, hydrophones)

Checks if the modules in detector have hydrophones or piezos, if they have they will be written in receiver and emitters dicts.
"""
function check_basemodules(detector, hydrophones)
    receivers = Dict{Int32, Receiver}()

    hydrophones_map = Dict{Int32, Hydrophone}()
    for hydrophone ∈ hydrophones # makes a dictionary of hydrophones, with string number as keys
        hydrophones_map[hydrophone.location.string] = hydrophone
    end
    n_hydro = 0
    for (module_id, mod) ∈ detector.modules # go through all modules and check whether they are base modules and have hydrophone
        if (mod.location.floor == 0 && hydrophoneenabled(mod))
            if mod.location.string in keys(hydrophones_map)
                n_hydro += 1
                pos = hydrophones_map[mod.location.string].pos
                pos += mod.pos
                receivers[module_id] = Receiver(module_id, pos, mod.location, mod.t₀)
            else
                @warn "no hydrophone for string $(mod.location.string)"
            end
        end
    end
    receivers
end
"""
Datatype which has all information of one Transmission which is later needed for the fitting procedure.
"""
struct Transmission
    id::Int32
    string::Int32
    floor::Int8
    Q::Float64
    TOA::Float64
    TOE::Float64
end
"""
An accoustic event is a collection, of a minimum number,
of accoustic signals emmited from one tripod,
gathered from multiple modules during a certain period of time.
"""
struct Event
    oid::Int32
    run::Int32
    length::Int32
    id::Int8
    data::Vector{Transmission}
end
Base.length(T::Event) = T.length
Base.show(event::Event) = print("Event from tripod $(event.id) with $(length(event)) transmissions.")
"""
EventHeader contains the information aboout detector, emitter, run.
"""
struct EventHeader
    oid::Int32
    length::Int32
    id::Int8
end
"""
    function isless(A::Transmission, B::Transmission)

Compares two transmissions. Necessary for sorting transmissions in the right way: Sort first by earliest TOA
and if TOAs are equal sort first by higher Quality factor Q.
"""
function isless(A::Transmission, B::Transmission)
    if A.TOA == B.TOA
        return !isless(A.Q, B.Q)
    else
        return isless(A.TOA, B.TOA)
    end
end
"""
    function overlap(A::Event, B::Event, tmax::Float64)

Compares two events, which are already sorted by TOE, to check for overlap.
If TOE of last signal of first event bigger than TOE of first signal of second event minus TMAX
there is an overlap between signals.
"""
function overlap(A::Event, B::Event, tmax::Float64)
    if A.data[end].TOE >= B.data[1].TOE - tmax
        true
    else
        false
    end
end

"""


# Compares two events and merges them if they overlap.
# """
#function merge(A::Event, B::Event)
"""
    function save_events(events)

Output events as HDF5 file.
"""
function save_events(events, file, run)
    for (i, event) in enumerate(events)
        header = [event.oid, event.length, event.id]
        write(file, "$(run)/event$(i)/header", header)
        write_compound(file, "$(run)/event$(i)/transmissions", event.data)
    end
end
