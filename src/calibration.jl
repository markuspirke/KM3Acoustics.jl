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
    calib_events = Dict{Int8, Event}[]
    while i < length(events)
        different_tripod = false
        combined_events = Dict{Int8, Event}()
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
        if  length(keys(combined_events)) >= 2
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

eventtime(event::Event) =  mean([transmission.TOE for transmission in event.data])


function loss(p, events::Vector{Event}, toystring::ToyString, emitters)
    l = length(events)
    ps = Vector{Float64}[] # for each event a seperate loss function is calculated which needs (TOE, θ, ϕ)
    for i in 1:l # first k entries in p are TOES, last two θ, ϕ
        push!(ps, [p[i], p[l+1:end]...])
    end
    x = 0.0
    for (i, event) in enumerate(events)
       x += loss(ps[i], event.data, toystring, emitters[event.id])
    end
    x
end

function loss(p, transmissions::Vector{Transmission}, toystring::ToyString, emitter::Emitter)
    ts = Transmission[]
    for transmission in transmissions
        if transmission.string == toystring.id
            push!(ts, transmission)
        end
    end
    sum([(transmission.TOA - toy_toa(p, transmission.floor, emitter, toystring))^2 for transmission in ts])
end




#function trigger()
