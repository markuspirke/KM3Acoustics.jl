"""
The photomultiplier tube of an optical module. The `id` stands for the DAQ
channel ID.

A non-zero status means the PMT is "not OK". Individual bits can be read out
to identify the problem (see definitions/pmt_status.jl for the bit positions
and check them using the `nthbitset()` function).

"""
struct PMT
    id::Int32
    pos::Position
    dir::Direction
    t₀::Float64
    status::Union{Int32, Missing}
end


"""
A module's location in the detector where string represents the
detection unit identifier and floor counts from 0 from the bottom
to top. Base modules are sitting on floor 0 and optical modules
on floor 1 and higher.

"""
struct Location
    string::Int32
    floor::Int8
end


"""
Either a base module or an optical module. A non-zero status means the
module is "not OK". Individual bits can be read out to identify the problem (see
definitions/module_status.jl for the bit positions and check them using the
`nthbitset()` function).

"""
struct DetectorModule
    id::Int32
    pos::Union{Position, Missing}
    location::Location
    n_pmts::Int8
    pmts::Vector{PMT}
    q::Union{Quaternion, Missing}
    status::Union{Int32, Missing}
    t₀::Union{Float64, Missing}
end

"""
A hydrophone, typically installed in the base module of a KM3NeT detector's
string.
"""
struct Hydrophone
    location::Location
    pos::Position
end

"""
    function read(filename::AbstractString, T::Type{Hydrophone})

Reads a vector of `Hydrophone`s from an ASCII file.
"""
function read(filename::AbstractString, T::Type{Hydrophone})
    hydrophones = T[]
    for line ∈ readlines(filename)
        if startswith(line, "#")
            continue
        end
        string, floor, x, y, z = split(line)
        location = Location(parse(Int32, string), parse(Int8, floor))
        pos = Position(parse.(Float64, [x, y, z])...)
        push!(hydrophones, T(location, pos))
    end
    hydrophones
end
"""
A tripod installed on the seabed which sends acoustic signals to modules.
"""
struct Tripod
    id::Int8
    pos::Position
end
"""
    function read(filename:AbstractString, T::Type{Tripod})

Reads a vector of `Tripod`s from an ASCII file.
"""
function read(filename::AbstractString, T::Type{Tripod})
    tripods = T[]
    for line ∈ readlines(filename)
        if startswith(line, "#")
            continue
        end
        id, x, y, z = split(line)
        id = parse(Int8, id)
        pos = Position(parse.(Float64, [x, y, z])...)
        push!(tripods, T(id, pos))
    end
    tripods
end
"""
Waveform translates Emitter ID to Tripod ID.
"""
struct Waveform
    ids::Dict{Int8, Int8}
end
"""
    function read(filename::AbstractString, T::Type{Waveform})

Reads the waveform ASCII file.
"""
function read(filename::AbstractString, T::Type{Waveform})

    D = Dict{Int8, Int8}()
    for line ∈ readlines(filename)
        if startswith(line, "#")
            continue
        end

        key, value = split(line)
        key, value = parse.(Int8, [key, value])

        D[key] = value
    end

    T(D)
end
"""
Certain parameters which define an acoustic event.
"""
struct TriggerParameter
    q::Float64
    tmax::Float64
    nmin::Int32
end
"""
    function read(filename::AbstractString, T::Type{TriggerParameter})

Reads the 'acoustics_trigger_parameters.txt' file.
"""
function read(filename::AbstractString, T::Type{TriggerParameter})
    lines = readlines(filename)
    q = split(split(lines[1])[end], ";")[1]
    tmax = split(split(lines[2])[end], ";")[1]
    nmin = split(split(lines[3])[end], ";")[1]

    q = parse(Float64, q)
    tmax = parse(Float64, tmax)
    nmin = parse(Int32, nmin)

    TriggerParameter(q, tmax, nmin)
end
"""
A KM3NeT detector.

"""
struct Detector
    id::Int32
    validity::Union{DateRange, Missing}
    pos::Union{UTMPosition, Missing}
    n_modules::Int32
    modules::Dict{Int32, DetectorModule}
end


"""
    function Detector(filename::AbstractString)

Create a `Detector` instance from a DETX file.
"""
function Detector(filename::AbstractString)
    open(filename, "r") do fobj
        Detector(fobj)
    end
end


"""
    function Detector(io::IO)

Create a `Detector` instance from an IO stream.
"""
function Detector(io::IO)
    lines = readlines(io)
    filter!(e->!startswith(e, "#") && !isempty(strip(e)), lines)

    first_line = lowercase(first(lines))  # version can be v or V, halleluja

    if occursin("v", first_line)
        det_id, version = map(x->parse(Int,x), split(first_line, 'v'))
        # TODO: reference grid is not read out
        validity = DateRange(map(unix2datetime, map(x->parse(Float64, x), split(lines[2])))...)
        utm_position = UTMPosition(map(x->parse(Float64, x), split(lines[3])[4:6])...)
        n_modules = parse(Int, lines[4])
        idx = 5
    else
        det_id, n_modules = map(x->parse(Int,x), split(first_line))
        version = 1
        utm_position = missing
        validity = missing
        idx = 2
    end

    modules = Dict{Int32, DetectorModule}()

    for mod ∈ 1:n_modules
        elements = split(lines[idx])
        module_id, string, floor = map(x->parse(Int, x), elements[1:3])
        if version >= 4
            x, y, z, q0, qx, qy, qz, t₀ = map(x->parse(Float64, x), elements[4:12])
            pos = Position(x, y, z)
            q = Quaternion(q0, qx, qy, qz)
        else
            pos = missing
            q = missing
            t₀ = missing
        end
        if version >= 5
            status = parse(Float64, elements[12])
        else
            status = missing
        end
        n_pmts = parse(Int, elements[end])

        pmts = PMT[]
        for pmt in 1:n_pmts
            l = split(lines[idx+pmt])
            pmt_id = parse(Int,first(l))
            x, y, z, dx, dy, dz = map(x->parse(Float64, x), l[2:7])
            t0 = parse(Float64,l[8])
            if version >= 3
                pmt_status = parse(Int, l[9])
            else
                pmt_status = missing
            end
            push!(pmts, PMT(pmt_id, Position(x, y, z), Direction(dx, dy, dz), t0, pmt_status))
        end
        modules[module_id] = DetectorModule(module_id, pos, Location(string, floor), n_pmts, pmts, q, status, t₀)
        idx += n_pmts + 1
    end

    Detector(det_id, validity, utm_position, n_modules, modules)
end
