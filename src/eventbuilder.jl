# """
#     function read_toashort(filename::AbstractString)

# Takes a toashort .csv file and adds UNIXTIMEBASE and TOA_S and removes unnecessary columns.
# """
# function read_toashort(filename::AbstractString)
#     df = CSV.read(filename,DataFrame; delim=",", types=[Int32, Int32, Float64, Int32, Int8, Float64, Int32])

#     transform!(df, AsTable([:UNIXTIMEBASE, :TOA_S]) => sum => :UTC_TOA1)
#     select!(df, Not([:RUNNUMBER, :UNIXTIMEBASE, :TOA_S]))
#     transform!(df, :UTC_TOA1 => x -> round.(x, sigdigits=16))
#     transform!(df, :UTC_TOA1_function => :UTC_TOA)
#     select!(df, Not([:UTC_TOA1, :UTC_TOA1_function]))
#     unique!(df)
#     df
# end
"""
RawToaoshort is an input data type which stores all information from the toashort file.
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
