"""
    function get_hydrophones(filename::AbstractString, detector::Detector, events::Vector{Event})

Takes in a filename relating to hydrophones, a detector file and events from eventbuilder. Outputs an ordered
dictionary of hydrophones which are involved in some event and in detector.
"""
function get_hydrophones(filename::AbstractString, detector::Detector, events::Vector{Event})
    hydrophones = read(filename, Hydrophone)

    hydrophones_map = Dict{Int32, Hydrophone}()
    for hydrophone ∈ hydrophones # makes a dictionary of hydrophones, with string number as keys
        hydrophones_map[hydrophone.location.string] = hydrophone
    end
    hydrophones_signal = Int32[] #take only those hydrophones which have received an signal from a tripod
    for event in events
        for transmission in event.data
            if transmission.string in hydrophones_signal
                continue
            else
                push!(hydrophones_signal, transmission.string)
            end
        end
    end

    new_hydrophones = Dict{Int32, Hydrophone}()

    for (module_id, mod) ∈ detector.modules # go through all modules and check whether they are base modules and have hydrophone
        if (mod.location.floor == 0 && hydrophoneenabled(mod))
            if (mod.location.string in keys(hydrophones_map)) && (mod.location.string in hydrophones_signal)
                pos = hydrophones_map[mod.location.string].pos
                pos += mod.pos
                h = Hydrophone(hydrophones_map[mod.location.string].location, pos)
                new_hydrophones[mod.location.string] = h
            elseif !(mod.location.string in hydrophones_signal)
                @warn  "hydrophone from string not in events"
            else
                @warn "no active hydrophone for string $(mod.location.string)"
            end
        elseif mod.location.floor == 0 && !hydrophoneenabled(mod)
            @warn "hydrophone $(mod.location.string) not activated"
        end
    end
    sort(new_hydrophones)
end
"""
    struct Precalibration <: Function

Data structure which stores all information needed for the precalibration process.
"""
struct Precalibration <: Function
    detector_pos
    hydrophones::OrderedDict{Int32, Hydrophone}
    key_fixhydro::Int
    lut_hydrophones::OrderedDict{Int32, Int8}
    events::OrderedDict{Int8, Vector{Event}}
    nevents::Int
    emitters::OrderedDict{Int8, Emitter}
end
"""
    function Precalibration(detector_pos, hydrophones, events::Vector{Event}, emitters::Dict{Int8, Emitter})

Method to set up the precalibration data type.
"""
function Precalibration(detector_pos, hydrophones::OrderedDict{Int32, Hydrophone}, key_fixhydro::Int, events::Vector{Event}, emitters::Dict{Int8, Emitter})
    sorted_events = sort_events_qualityfactor(events)
    devents = Dict{Int8, Vector{Event}}()
    for event in sorted_events # sort the events from different emitters each up to 10 events
        if (event.id in keys(devents))
            if length(devents[event.id]) < 20
                push!(devents[event.id], event)
            end
        else
            devents[event.id] = [event]
        end
    end
    devents = sort(devents)
    lut_hydrophones = lookuptable_hydrophones(hydrophones, key_fixhydro)

    Precalibration(detector_pos, hydrophones, key_fixhydro, lut_hydrophones, devents, length(events), sort(emitters))
end
"""
    function sort_events_qualityfactor(events::Vector{Event})

Sorts a vector of events. Events with highest mean qualityfactor come first.
"""
function sort_events_qualityfactor(events::Vector{Event})
    Qs = Float64[]
    for event in events
        Q = mean([transmission.Q for transmission in event.data])
        push!(Qs, Q)
    end
    events[sortperm(Qs)]# sort the events by the highest mean quality
end
"""
    function lookuptable_hydrophones(hydrophones::OrderedDict{Int32, Hydrophone}, key_fixhydro::Int32)

Returns a dictionary which maps the keys to the position in which they are sorted. First key -> 1, second key -> 2, .."""
function lookuptable_hydrophones(hydrophones::OrderedDict{Int32, Hydrophone}, key_fixhydro)
    lut_hydrophones = OrderedDict{Int32, Int8}()
    ks = collect(keys(hydrophones))
    mask = ks .== key_fixhydro
    ks = ks[mask .== 0] # returns all keys except the fixhydro key
    for (i, k) in enumerate(ks)# set one hydrophones fix
        lut_hydrophones[k] = i
    end
    lut_hydrophones
end

"""
    function (pc::Precalibration)(p::Vector{T}) where {T}

Function which will be optimized for the precalibration of hydrophones and tripods. Returns a reduced chi2.
"""
function (pc::Precalibration)(p::Vector{T}) where {T}
    n_hydro = length(pc.hydrophones) - 1 # number of not fixed hydrophones
    n_emitters = length(pc.emitters)
    pos_hydro = [Position(p[i], p[i+1], p[i+2]) for i in 1:3:3*n_hydro] #first arguments are positions of hydro
    pos_tripod = [Position(p[i], p[i+1], p[i+2]) for i in 3*n_hydro+1:3:3*(n_hydro+n_emitters)] # then positions of tripods
    toes = p[3*(n_hydro+n_emitters)+1:end] # last entries are toes

    toas = T[] # measured time of arrivals
    ts = T[] #calculated time of arrivals
    index_event = 0
    n_transmissions = 0
    for (i, (emitter_id, events)) in enumerate(pc.events)
        for (j, event) in enumerate(events)
            index_event += 1
            for transmission in event.data
                n_transmissions += 1
                push!(toas, transmission.TOA)
                if transmission.string == pc.key_fixhydro
                    R = norm(pc.hydrophones[transmission.string].pos - pos_tripod[i])
                    t = traveltime(R, pc.hydrophones[transmission.string].pos.z, pos_tripod[i].z, pc.detector_pos.z)
                    t += toes[index_event]
                    push!(ts, t)
                else
                    index_hydro = pc.lut_hydrophones[transmission.string]
                    R = norm(pos_hydro[index_hydro] - pos_tripod[i])
                    t = traveltime(R, pos_hydro[index_hydro].z, pos_tripod[i].z, pc.detector_pos.z)
                    t += toes[index_event]
                    push!(ts, t)
                end
            end
        end
    end
    ndgf = n_transmissions - length(p)
    chi2(ts, toas)/ndgf
end

"""
    (pc::Precalibration)(p::Vararg{T}) where {T} = pc([p...])

Function which will be optimized for the precalibration of hydrophones and tripods. Returns a reduced chi2.
"""
(pc::Precalibration)(p::Vararg{T}) where {T} = pc([p...])

function precalibration_startvalues(pc::Precalibration)
    p0s = Float64[]
    for k in collect(keys(pc.lut_hydrophones))
        p0s = vcat(p0s, collect(pc.hydrophones[k].pos))
    end
    for emitter in collect(values(pc.emitters))
        p0s = vcat(p0s, collect(emitter.pos))
    end
    for events in values(pc.events)
        for event in events
            push!(p0s, eventtime(event))
        end
    end
    p0s
end

"""
    function get_opt_emitters(pc, p)

Return a dictionary of emitters with precalibrated positions.
"""
function get_opt_emitters(pc::Precalibration, p)
    n_hydro = length(pc.hydrophones) - 1 # number of not fixed hydrophones
    n_emitters = length(pc.emitters)
    pos_tripod = [Position(p[i], p[i+1], p[i+2]) for i in 3*n_hydro+1:3:3*(n_hydro+n_emitters)] # then positions of tripods
    emitter_keys = collect(keys(pc.emitters))
    opt_emitters = Dict{Int8, Emitter}()
    for (i, pos) in enumerate(pos_tripod)
        id = emitter_keys[i]
        opt_emitters[id] = Emitter(id, pos)
    end
    opt_emitters
end
"""
    function get_opt_hydrophones(pc, p)

Return a dictionary of hydrophones with precalibrated positions.
"""
function get_opt_hydrophones(pc::Precalibration, p)
    n_hydro = length(pc.hydrophones) - 1 # number of not fixed hydrophones
    pos_hydro = [Position(p[i], p[i+1], p[i+2]) for i in 1:3:3*n_hydro] #first arguments are positions of hydro
    hydro_keys = collect(keys(pc.lut_hydrophones))
    opt_hydrophones = Dict{Int32, Hydrophone}()
    for (i, pos) in enumerate(pos_hydro)
        id = hydro_keys[i]
        @show Hydrophone(pc.hydrophones[id].location, pos)
        opt_hydrophones[id] = Hydrophone(pc.hydrophones[id].location, pos)
    end
    opt_hydrophones[pc.key_fixhydro] = pc.hydrophones[pc.key_fixhydro]
    opt_hydrophones
end
