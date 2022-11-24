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
    events::OrderedDict{Int8, Vector{Event}}
    numevents
    hydrophones::OrderedDict{Int32, Hydrophone}
    h_map
    fixhydrophones
    emitters::OrderedDict{Int8, Emitter}
    fixemitters
    p0s
    mapping
    ϕ::Float64
    # key_fixhydro::Int
    # keys_fixhydro_z
    # lut_hydrophones::OrderedDict{Int32, Int8}
end
"""
    function Precalibration(detector_pos, hydrophones::OrderedDict{Int32, Hydrophone}, key_fixhydro::Int, events::Vector{Event}, emitters::Dict{Int8, Emitter})

Method to set up the precalibration data type.
"""
function Precalibration(detector_pos, events::Vector{Event}, hydrophones::OrderedDict{Int32, Hydrophone}, fixhydrophones, emitters::Dict{Int8, Emitter}, fixemitters; rotate=0, nevents=10, mask=0)
    h_map = lookuptable_hydrophones(hydrophones)
    sorted_events = sort_fitevents(events, :TOE, rev=false) #sort by Q factor
    fitevents, numevents = group_fitevents(sorted_events, nevents)
    if mask != 0
        fitevents, numevents = select_fitevents(fitevents, mask)
    end

    semitters = sort(emitters)
    if rotate != 0
        if rotate[1] == :Hydrophone
            hydrophones, semitters, ϕ = rotate_detector(hydrophones, semitters, hydrophones[rotate[2]].pos)
        elseif rotate[1] == :Emitter
            hydrophones, semitters, ϕ = rotate_detector(hydrophones, semitters, semitters[rotate[2]].pos)
        end
    else
        ϕ = 0.0
    end
    p0s, mapping = generate_startvalues(hydrophones, semitters, fixhydrophones, fixemitters, fitevents)
    Precalibration(detector_pos, fitevents, numevents, hydrophones, h_map, fixhydrophones, semitters, fixemitters, p0s, mapping, ϕ)
end
"""
    function sort_events_qualityfactor(events::Vector{Event})

Sorts a vector of events. Events with highest mean qualityfactor come first.
"""
function sort_fitevents(events::Vector{Event}, field::Symbol; rev=false)
    xs = Float64[]
    for event in events
        x = mean(event, field)
        push!(xs, x)
    end
    if !rev
        sevents = events[sortperm(xs)]# sort the events by the highest mean quality
    else
        sevents = reverse(events[sortperm(xs)])
    end
    sevents
end
"""
    function group_fitevents(events::Vector{Event}, nevents)

Groups a vector of sorted events, by the emitters which send the event. nevents is the maximum number of events we use
for fitting per emitter.
"""
function group_fitevents(events::Vector{Event}, nevents)
    devents = Dict{Int8, Vector{Event}}()
    for event in events # sort the events from different emitters each up to 10 events
        if (event.id in keys(devents))
            if length(devents[event.id]) < nevents
                push!(devents[event.id], event)
            end
        else
            devents[event.id] = [event]
        end
    end
    sort(devents), nevents*length(devents)
end

function select_fitevents(events, mask)
    newevents = Dict{Int8, Vector{Event}}()
    for (k, event) in events
        newevents[k] = event[mask]
    end
    sort(newevents), length(mask)*length(events)
end

"""
    function generate_startvalues(hydrophones, emitters, fixhydrophones, fixemitters, fitevents)

Generates starting values for the fitting procedure. The startvalues are essentially some old positions of hydrophones and tripods.
The start values for time of emission we take the mean TOE of an acoustic event.
"""
function generate_startvalues(hydrophones, emitters, fixhydrophones, fixemitters, fitevents)
    p = Float64[]
    mapping = Int[]
    idx = 0
    for (id, h) ∈ hydrophones
        for q ∈ (:x, :y, :z)
            idx += 1
            (id, q) ∈ fixhydrophones && continue
            push!(p, getfield(h.pos, q))
            push!(mapping, idx)
        end
    end

    for e ∈ values(emitters)
        for q ∈ (:x, :y, :z)
            idx += 1
            (e.id, q) ∈ fixemitters && continue
            push!(p, getfield(e.pos, q))
            push!(mapping, idx)
        end
    end

    for events in values(fitevents)
        for event in events
            idx += 1
            push!(p, eventtime(event))
            push!(mapping, idx)
        end
    end
    p, mapping
end
"""
    function lookuptable_hydrophones(hydrophones::OrderedDict{Int32, Hydrophone}, key_fixhydro::Int32)

Returns a dictionary which maps the keys to the position in which they are sorted. First key -> 1, second key -> 2, .."""
function lookuptable_hydrophones(hydrophones::OrderedDict{Int32, Hydrophone})
    lut_hydrophones = OrderedDict{Int32, Int8}()
    ks = collect(keys(hydrophones))
    for (i, k) in enumerate(ks)# set one hydrophones fix
        lut_hydrophones[k] = i
    end
    lut_hydrophones
end
"""
    function rotate_detector(hydrophones, emitters, pos)

Rotates the whole detector, including hydrophones and emitters, such that the position which is given as an argument lies in yz plane.
"""
function rotate_detector(hydrophones, emitters, pos)
    pos = Position(pos.x, pos.y, 0.0) #look at the projection in the xy plane
    v = Position(1.0, 0.0, 0.0) # vector along x axis
    ϕ = angle(pos, v)
    M = [cos(ϕ) sin(ϕ) 0; -sin(ϕ) cos(ϕ) 0; 0 0 1] #rotation matrix

    newhydrophones = typeof(hydrophones)()
    for (id, hydrophone) in hydrophones
        newpos = M*hydrophone.pos
        newhydrophones[id] = Hydrophone(hydrophone.location, newpos)
    end
    newemitters = typeof(emitters)()
    for (id, emitter) in emitters
        newpos = M*emitter.pos
        newemitters[id] = Emitter(id, newpos)
    end
    newhydrophones, newemitters, ϕ
end
"""
    function rerotate_detector(hydrophones, emitters, ϕ)

Rotates the whole detector back to the originally position.
"""
function rerotate_detector(hydrophones, emitters, ϕ)
    M = [cos(ϕ) -sin(ϕ) 0; sin(ϕ) cos(ϕ) 0; 0 0 1] #rotation matrix

    newhydrophones = typeof(hydrophones)()
    for (id, hydrophone) in hydrophones
        newpos = M*hydrophone.pos
        newhydrophones[id] = Hydrophone(hydrophone.location, newpos)
    end
    newemitters = typeof(emitters)()
    for (id, emitter) in emitters
        newpos = M*emitter.pos
        newemitters[id] = Emitter(id, newpos)
    end
    newhydrophones, newemitters, ϕ
end
"""
    function unwrap(p, mapping, hydrophones, emitters)

Helper function for mapping the arguments of the fitting function.
"""
function unwrap(p::Vector{T}, pc::Precalibration) where {T}
    final_p = T[]
    for (id, h) ∈ pc.hydrophones
        for q ∈ (:x, :y, :z)
            push!(final_p, getfield(h.pos, q))
        end
    end
    for e ∈ values(pc.emitters)
        for q ∈ (:x, :y, :z)
            push!(final_p, getfield(e.pos, q))
        end
    end
    for _ ∈ 1:pc.numevents
        push!(final_p, 0.0)
    end
    @inbounds for (v, idx) in zip(p, pc.mapping)
        final_p[idx] = v
    end
    final_p
end
"""
    function split_p(ps, hydrophones, emitters, numevents)

Splits the arguments of the fitting function into position of hydrophones, emitters and TOEs.
"""
function split_p(ps, pc::Precalibration)
    n_xyz_hydro = 3*length(pc.hydrophones)
    n_xyz_emitter = 3*length(pc.emitters)
    n_xyz = n_xyz_hydro + n_xyz_emitter
    pos_hydros = [Position(ps[i], ps[i+1], ps[i+2]) for i in 1:3:n_xyz_hydro]
    pos_emitters = [Position(ps[i], ps[i+1], ps[i+2]) for i in n_xyz_hydro+1:3:n_xyz]
    toes = [p for p in ps[n_xyz+1:end]]

    pos_hydros, pos_emitters, toes
end
"""
    function (pc::Precalibration)(p::Vector{T}) where {T}

Function which will be optimized for the precalibration of hydrophones and tripods. Returns a reduced chi2.
"""
function (pc::Precalibration)(p::Vector{T}) where {T}
    ps = unwrap(p, pc)
    pos_hydros, pos_emitters, toes = split_p(ps, pc)
    toas = T[] # measured time of arrivals
    ts = T[] #calculated time of arrivals

    idx_emitter = 0
    idx_event = 0
    n_transmissions = 0
    for (emitter_id, events) in pc.events
        idx_emitter += 1
        for event in events
            idx_event += 1
            for transmission in event.data
                n_transmissions += 1
                idx_hydro = pc.h_map[transmission.string]
                R = norm(pos_hydros[idx_hydro] - pos_emitters[idx_emitter])
                t = traveltime(R, pos_hydros[idx_hydro].z, pos_emitters[idx_emitter].z, pc.detector_pos.z)
                t += toes[idx_event]
                push!(ts, t)
                push!(toas, transmission.TOA)
            end
        end
    end
    ndgf = n_transmissions - length(p)
    chi2(ts, toas)/ndgf
end

# """
#     function (pc::Precalibration)(p::Vector{T}) where {T}

# Function which will be optimized for the precalibration of hydrophones and tripods. Returns a reduced chi2.
# """
# function (pc::Precalibration)(p::Vector{T}) where {T}
#     n_hydro = length(pc.hydrophones) - 1 # number of not fixed hydrophones
#     n_emitters = length(pc.emitters)
#     pos_hydro = Position[]
#     i = 1
#     for (key, value) in pc.lut_hydrophones
#         if key == pc.keys_fixhydro_z[1]
#             push!(pos_hydro, Position(p[i], pc.hydrophones[key].pos.y, pc.hydrophones[key].pos.z))
#             i += 1
#         elseif key == pc.keys_fixhydro_z[2]
#             push!(pos_hydro, Position(p[i], p[i+1], pc.hydrophones[key].pos.z))
#             i += 2
#         else
#             push!(pos_hydro, Position(p[i], p[i+1], p[i+2]))
#             i += 3
#         end
#     end
#     pos_tripod = Position[]
#     for j in 1:n_emitters
#         push!(pos_tripod, Position(p[i], p[i+1], p[i+2]))
#         i += 3
#     end

#     # pos_hydro = [Position(p[i], p[i+1], p[i+2]) for i in 1:3:3*n_hydro] #first arguments are positions of hydro
#     # pos_tripod = [Position(p[i], p[i+1], p[i+2]) for i in 3*n_hydro+1:3:3*(n_hydro+n_emitters)] # then positions of tripods
#     toes = p[i:end] # last entries are toes

#     toas = T[] # measured time of arrivals
#     ts = T[] #calculated time of arrivals
#     index_event = 0
#     n_transmissions = 0
#     for (i, (emitter_id, events)) in enumerate(pc.events)
#         for (j, event) in enumerate(events)
#             index_event += 1
#             for transmission in event.data
#                 n_transmissions += 1
#                 push!(toas, transmission.TOA)
#                 if transmission.string == pc.key_fixhydro # if hydrophone x,y,z fixed
#                     R = norm(pc.hydrophones[transmission.string].pos - pos_tripod[i])
#                     t = traveltime(R, pc.hydrophones[transmission.string].pos.z, pos_tripod[i].z, pc.detector_pos.z)
#                     t += toes[index_event]
#                     push!(ts, t)
#                 elseif transmission.string == pc.keys_fixhydro_z[1]
#                     index_hydro = pc.lut_hydrophones[transmission.string]
#                     R = norm(Position(pos_hydro[index_hydro].x, pc.hydrophones[transmission.string].pos.y, pc.hydrophones[transmission.string].pos.z)) #if y, z position is fixed
#                     t = traveltime(R, pos_hydro[index_hydro].z, pos_tripod[i].z, pc.detector_pos.z)
#                     t += toes[index_event]
#                     push!(ts, t)
#                 elseif transmission.string == pc.keys_fixhydro_z[2]
#                     index_hydro = pc.lut_hydrophones[transmission.string]
#                     R = norm(Position(pos_hydro[index_hydro].x, pos_hydro[index_hydro].y, pc.hydrophones[transmission.string].pos.z)) #if z position is fixed
#                     t = traveltime(R, pos_hydro[index_hydro].z, pos_tripod[i].z, pc.detector_pos.z)
#                     t += toes[index_event]
#                     push!(ts, t)
#                 else
#                     index_hydro = pc.lut_hydrophones[transmission.string]
#                     R = norm(pos_hydro[index_hydro] - pos_tripod[i])
#                     t = traveltime(R, pos_hydro[index_hydro].z, pos_tripod[i].z, pc.detector_pos.z)
#                     t += toes[index_event]
#                     push!(ts, t)

#                 end
#             end
#         end
#     end
#     ndgf = n_transmissions - length(p)
#     chi2(ts, toas)/ndgf
# end

"""
    (pc::Precalibration)(p::Vararg{T}) where {T} = pc([p...])

Function which will be optimized for the precalibration of hydrophones and tripods. Returns a reduced chi2.
"""
(pc::Precalibration)(p::Vararg{T}) where {T} = pc([p...])

function precalibration_startvalues(pc::Precalibration)
    p0s = Float64[]
    for k in collect(keys(pc.lut_hydrophones))
        if k == pc.keys_fixhydro_z[1]
            p0s = vcat(p0s, [pc.hydrophones[k].pos.x]) #only x component to fit
        elseif k == pc.keys_fixhydro_z[2]
            p0s = vcat(p0s, [pc.hydrophones[k].pos.x, pc.hydrophones[k].pos.y]) #only x,y components to fit
        else
            p0s = vcat(p0s, collect(pc.hydrophones[k].pos))
        end
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
        opt_hydrophones[id] = Hydrophone(pc.hydrophones[id].location, pos)
    end
    opt_hydrophones[pc.key_fixhydro] = pc.hydrophones[pc.key_fixhydro]
    opt_hydrophones
end

function detector_precalibration(detector::Detector, newhydrophones::Dict{Int32, Hydrophone}, filename::AbstractString)
    hydrophones = read(filename, Hydrophone)
    hydrophones_map = Dict{Int32, Hydrophone}()
    for hydrophone ∈ hydrophones # makes a dictionary of hydrophones, with string number as keys
        hydrophones_map[hydrophone.location.string] = hydrophone
    end
    new_modules = Dict{Int32, DetectorModule}()
    for mod ∈ detector
        if mod.location.string in keys(newhydrophones)
            pos = newhydrophones[mod.location.string].pos - hydrophones_map[mod.location.string].pos
            newpos = Position(pos.x, pos.y, mod.pos.z)
            new_modules[mod.id] = DetectorModule(mod.id, newpos, mod.location, mod.n_pmts, mod.pmts, mod.q, mod.status, mod.t₀)
        else
            new_modules[mod.id] = mod
        end
    end
    Detector(detector.version, detector.id, detector.validity, detector.pos, detector.utm_ref_grid, detector.n_modules, new_modules, detector.strings, detector.comments)
end
