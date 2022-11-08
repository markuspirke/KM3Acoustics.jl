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
            else
                @warn "no hydrophone for string $(mod.location.string) or hydrophone not in events"
            end
        end
    end
    sort(new_hydrophones)
end
"""
    struct Precalibration <: Function

Data structure which stores all information needed for the precalibration process.
"""
struct Precalibration <: Function
    detector_pos::Position
    hydrophones::OrderedDict{Int32, Hydrophone}
    lut_hydrophones::OrderedDict{Int32, Int8}
    events::OrderedDict{Int8, Vector{Event}}
    nevents
    emitters::OrderedDict{Int8, Emitter}
end
"""
    function Precalibration(detector_pos, hydrophones, events::Vector{Event}, emitters::Dict{Int8, Emitter})

Method to set up the precalibration data type.
"""
function Precalibration(detector_pos, hydrophones, events::Vector{Event}, emitters::Dict{Int8, Emitter})
    Qs = Float64[]
    for event in events
        Q = mean([transmission.Q for transmission in event.data])
        push!(Qs, Q)
    end
    perm = sortperm(Qs) # sort the events by the highest mean quality
    devents = Dict{Int8, Vector{Event}}()
    for event in events[perm] # sort the events from different emitters each up to 10 events
        if (event.id in keys(devents))
            if length(devents[event.id]) < 20
                push!(devents[event.id], event)
            end
        else
            devents[event.id] = [event]
        end
    end
    devents = sort(devents)
    hydrophones_sorted = sort(hydrophones)
    lut_hydrophones = OrderedDict{Int32, Int8}()
    for (i, k) in enumerate(collect(keys(hydrophones_sorted))[1:end-1]) # set one hydrophones fix
        lut_hydrophones[k] = i
    end

    Precalibration(detector_pos, hydrophones_sorted, lut_hydrophones, devents, length(events), sort(emitters))
end
#order of input arguments from string 0, 1, 2, 3 ... and 5, 7, 11, ... hydrophones
function (pc::Precalibration)(p::Vector{T}) where {T}
    n_hydro = length(pc.hydrophones) - 1 # number of not fixed hydrophones
    n_emitters = length(pc.emitters)
    pos_hydro = [Position(p[i], p[i+1], p[i+2]) for i in 1:3:3*n_hydro] #first arguments are positions of hydro
    pos_tripod = [Position(p[i], p[i+1], p[i+2]) for i in 3*n_hydro+1:3:3*(n_hydro+n_emitters)] # then positions of tripods
    toes = p[3*(n_hydro+n_emitters)+1:end] # last entries are toes

    toas = T[] # measured time of arrivals
    ts = T[] #calculated time of arrivals
    index_event = 0
    for (i, (emitter_id, events)) in enumerate(pc.events)
        for (j, event) in enumerate(events)
            index_event += 1
            for transmission in event.data
                push!(toas, transmission.TOA)
                if transmission.string == collect(keys(pc.hydrophones))[end]
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
    chi2(ts, toas)
end

function precalibration_startvalues(pc::Precalibration)
    p0s = Float64[]
    for k in collect(keys(pc.lut_hydrophones))
        p0s = vcat(p0s, collect(pc.hydrophones[k].pos))
    end
    @show length(p0s)
    for emitter in collect(values(pc.emitters))
        p0s = vcat(p0s, collect(emitter.pos))
    end
    @show length(p0s)
    for events in values(pc.events)
        for event in events
            push!(p0s, eventtime(event))
        end
    end
    p0s
end

function get_opt_emitters(pc, p)
    n_hydro = length(pc.hydrophones) - 1 # number of not fixed hydrophones
    n_emitters = length(pc.emitters)
    pos_tripod = [Position(p[i], p[i+1], p[i+2]) for i in 3*n_hydro+1:3:3*(n_hydro+n_emitters)] # then positions of tripods
    emitter_keys = collect(keys(pc.emitters))
    opt_emitters = Dict{Int8, Emitter}()
    for (i, pos) in enumerate(pos_tripod)
        id = emitter_keys[i]
        @show id
        opt_emitters[id] = Emitter(id, pos)
    end

    opt_emitters
end
