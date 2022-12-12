"""
    function read(file::HDF5.File, T::Type{Event}, run)

Reads in all events of a certain run from event.h5 file.
"""
function read_events(file::HDF5.File, run)
    ks = sort(keys(file["$(run)"]), lt=natural)
    events = Event[]
    sizehint!(events, length(ks))
    for k in ks
        _read_events!(events, file, run, k)
    end
    events
end
"""
    function read_events(filename::AbstractString, run)

Reads in all events of a certain run from event.h5 file.
"""
function read_events(filename::AbstractString, run)
    events = h5open(filename, "r") do file
        ks = sort(keys(file["$(run)"]), lt=natural)
        events = Event[]
        sizehint!(events, length(ks))
        for k in ks
            _read_events!(events, file, run, k)
        end
        events
    end
end
#helper functions
_get_header(file::HDF5.File, run, event) = read(file["$(run)/$(event)/header"])
_get_transmissions(file::HDF5.File, run, event) = read(file["$(run)/$(event)/transmissions"], Transmission)
function _read_events!(events, file, run, event)
    header = _get_header(file, run, event)
    transmissions = _get_transmissions(file, run, event)
    push!(events, Event(header[1], run, header[2], header[3], transmissions))
end
"""
Groups events during a certain time window. Within this time window there should be at least two events from different tripods.
"""
function group_events(events::Vector{Event})
    toes = eventtime.(events)
    p = sortperm(toes)
    toes = toes[p]
    events = events[p]
    i = 1
    calib_events = Dict{Int8,Event}[]
    while i < length(events)
        different_tripod = false
        combined_events = Dict{Int8,Event}()
        combined_events[events[i].id] = events[i]
        j = i + 1
        while j < length(events)
            if toes[j] - toes[i] < 600.0 # need to check velocities of currents in deep water, but lets take 1cm per second as a start
                if events[j].id in keys(combined_events) && events[j].length >= events[i].length
                    combined_events[events[j].id] = events[j]
                elseif !(events[j].id in keys(combined_events))
                    combined_events[events[j].id] = events[j]
                end
            else
                break
            end
            j += 1
        end
        if length(keys(combined_events)) >= 2
            push!(calib_events, combined_events)
            i = j - 1
        end
        i += 1
    end
    out_events = Vector{Event}[]
    for calib_event in calib_events
        x = Event[] #not pretty!!!
        for (i, event) in calib_event
            push!(x, event)
        end
        push!(out_events, x)
    end
    out_events
end

function group_events1(events::Vector{Event})
    toes = eventtime.(events)
    p = sortperm(toes)
    toes = toes[p]
    events = events[p]
    i = 1
    calib_events = Vector{Event}[]
    while i < length(events)
        different_tripod = false
        gevents = [events[i]]
        j = i + 1
        while j < length(events)
            if toes[j] - toes[i] < 600.0 # need to check velocities of currents in deep water, but lets take 1cm per second as a start
                push!(gevents, events[j])
                if events[i].id != events[j].id
                    different_tripod = true
                end
            else
                break
            end
            j += 1
        end
        if different_tripod
            push!(calib_events, gevents)
            i = j - 1
        end
        i += 1
    end
    calib_events
end
eventtime(event::Event) = mean([transmission.TOE for transmission in event.data])
"""
    function get_basemodules(modules, hydrophones)

Returns all basemodules and positions.
"""
function get_basemodules(modules) #maybe need to use hyrdophone.txt???

    basemodules = ToyModule[]
    for (id, mod) ∈ modules # we need all basemodules as a fixed point for our model
        if mod.location.floor == 0
            push!(basemodules, ToyModule(mod.location, mod.pos))
        end
    end
    basemodules
end

"""
    function init_toydetector(basemodules, modules)

Initializes an detector without calibration.
"""
function init_toydetector(basemodules, modules)
    strings = Dict{Int32,ToyString}()
    for basemod ∈ basemodules
        heights = Float64[]
        for (id, mod) ∈ modules
            if (mod.location.string == basemod.location.string) && mod.location.floor != 0
                push!(heights, mod.pos.z)
            end
            sort!(heights)
        end
        heights = heights .- basemod.pos.z
        strings[basemod.location.string] = ToyString(basemod.location.string, basemod.pos, 0.0, 0.0, heights)
    end
    ToyDetector(strings)
end

"""
    function init_realdetector(basemodules, modules)

Initializes an detector without calibration.
"""
function init_realdetector(basemodules, modules)
    strings = Dict{Int32,RealString}()
    for basemod ∈ basemodules
        heights = Float64[]
        for (id, mod) ∈ modules
            if (mod.location.string == basemod.location.string) && mod.location.floor != 0 # if module in string and no basemodule write out heights
                push!(heights, mod.pos.z)
            end
            sort!(heights)
        end
        heights = heights .- basemod.pos.z
        strings[basemod.location.string] = RealString(basemod.location.string, basemod.pos, 0.0, 0.0, heights)
    end
    RealDetector(strings)
end

# function loss(p, events::Vector{Event}, toystring::ToyString, emitters, error)
#     l = length(events)
#     ps = Vector{Float64}[] # for each event a seperate loss function is calculated which needs (TOE, θ, ϕ)
#     for i in 1:l # first k entries in p are TOES, last two θ, ϕ
#         push!(ps, [p[i], p[l+1:end]...])
#     end
#     x = 0.0
#     for (i, event) in enumerate(events)
#        x += loss(ps[i], event.data, toystring, emitters[event.id], error)
#     end
#     x
# end

# function loss(p, transmissions::Vector{Transmission}, toystring::ToyString, emitter::Emitter, error)
#     ts = Transmission[]
#     for transmission in transmissions
#         if transmission.string == toystring.id
#             push!(ts, transmission)
#         end
#     end
#     sum([(transmission.TOA - toy_toa(p, transmission.floor, emitter, toystring))^2/error for transmission in ts])
# end


struct CalibrationEvent
    id::Int8
    transmissions::Vector{Transmission}
    lengths::Vector{Float64}
end
"""
Stores all the information needed for toy optimization procedure.
"""
struct ToyStringCalibration <: Function
    time::Float64
    string::Int32
    basepos::Position
    events::Vector{CalibrationEvent}
    toes::Vector{Float64}
    emitters::Dict{Int8,Emitter}
end
"""
Additional contructor for ToyStringCalibration.
"""
function ToyStringCalibration(line::ToyString, events::Vector{Event}, emitters::Dict{Int8,Emitter})
    toes = eventtime.(events)
    time = mean(toes)
    cevents = CalibrationEvent[]
    for event in events
        transmissions = Transmission[]
        ls = Float64[]
        for transmission in event.data
            if (transmission.string == line.id) && transmission.floor != 0
                push!(transmissions, transmission)
                push!(ls, line.lengths[transmission.floor])
            end
        end
        push!(cevents, CalibrationEvent(event.id, transmissions, ls))
    end
    ToyStringCalibration(time, line.id, line.pos, cevents, toes, emitters)
end
"""
    function (tsc::ToyStringCalibration)(t1::T, t2::T, θ::T, ϕ::T) where {T<:Real}

Function to be minimized.
"""
function (tsc::ToyStringCalibration)(t1::T, t2::T, θ::T, ϕ::T) where {T<:Real}
    toes = [t1, t2]
    # toes = p[1:end-2]
    # dx = p[end-1]
    # dy = p[end]
    ts = T[] # calculated time of arrivals
    toas = T[] # measured time of arrivals
    for (i, cevent) in enumerate(tsc.events)
        for (j, transmission) in enumerate(cevent.transmissions)
            push!(toas, transmission.TOA)
            t = toy_calc_traveltime(θ, ϕ, cevent.lengths[j], tsc.basepos, tsc.emitters[cevent.id].pos)
            t += toes[i]
            push!(ts, t)
        end
    end
    chi2(ts, toas)
end
struct ToyDetectorCalibration <: Function
    tscs::Vector{ToyStringCalibration}
end
function ToyDetectorCalibration(detector::ToyDetector, events::Vector{Event}, emitters::Dict{Int8,Emitter})
    strings = ToyStringCalibration[]
    for (id, string) in detector.strings
        push!(strings, ToyStringCalibration(string, events, emitters))
    end
    ToyDetectorCalibration(strings)
end
function (tdc::ToyDetectorCalibration)(t1::T, t2::T, αs::Vararg{T}) where {T}
    l = length(αs)
    θs = [αs[i] for i in 1:l/2]
    ϕs = [αs[i] for i in l/2+1:l]
    chi2 = 0.0
    for (i, tsc) in enumerate(tdc.tscs)
        chi2 += tsc(t1, t2, θs[i], ϕs[i])
    end
    chi2
end
"""
Stores all the information needed for optimization procedure.
"""
struct StringCalibration <: Function
    time::Float64
    a::Float64
    b::Float64
    string::Int32
    basepos::Position
    events::Vector{CalibrationEvent}
    toes::Vector{Float64}
    tripods::Dict{Int8,Emitter}
end

"""
Additional contructor for StringCalibration.
"""
function StringCalibration(a::Float64, b::Float64, line::RealString, events::Vector{Event}, tripods::Dict{Int8,Emitter})
    toes = eventtime.(events)
    time = mean(toes)
    cevents = CalibrationEvent[]
    for event in events
        transmissions = Transmission[]
        ls = Float64[]
        for transmission in event.data
            if (transmission.string == line.id) && transmission.floor != 0
                push!(transmissions, transmission)
                push!(ls, line.lengths[transmission.floor])
            end
        end
        push!(cevents, CalibrationEvent(event.id, transmissions, ls))
    end
    StringCalibration(time, a, b, line.id, line.pos, cevents, toes, tripods)
end

# function (sc::StringCalibration)(toes::Vector{T}, dx::T, dy::T) where {T<:Real}
function (sc::StringCalibration)(t1::T, t2::T, dx::T, dy::T) where {T<:Real}
    toes = [t1, t2]
    # toes = p[1:end-2]
    # dx = p[end-1]
    # dy = p[end]
    ts = T[] # calculated time of arrivals
    toas = T[] # measured time of arrivals
    for (i, cevent) in enumerate(sc.events)
        for (j, transmission) in enumerate(cevent.transmissions)
            push!(toas, transmission.TOA)
            t = calc_traveltime(dx, dy, cevent.lengths[j], sc.a, sc.b, sc.basepos, sc.tripods[cevent.id].pos)
            t += toes[i]
            push!(ts, t)
        end
    end
    chi2(ts, toas)
end

function chi2(toas, toas_measured; error=50e-6)
    x = 0.0
    for (i, toa) ∈ enumerate(toas)
        x += (toa - toas_measured[i])^2 / error^2
    end
    x
end

#function trigger()
