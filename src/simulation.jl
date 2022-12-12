"""
    function inverse_waveforms(waveform::Waveform)

Return an inverse ( injective but not bijective ) map of the waveform.txt file. The mapping is not bijective because
there are more Waveform IDs then tripod IDs. In this inverse function I leave out some waveform IDs
and just map all IDs from one tripod to one waveform ID. 
"""
function inverse_waveforms(waveform::Waveform)
    D = Dict{Int8,Int8}()
    for (k, value) in waveform.ids
        D[value] = k
    end
    Waveform(D)
end
"""
    function simulation_times(t0, emitters)
    
Given a time t0, where one wants to start the simulation, and some emitters,
this function returns a tuple of vectors. Each tuple consists of an emitter ID
and a starting time for an acoustic event. The times are randomly selected and are 
seperated by a time window of 20 seconds. 
"""
function simulation_times(t0, emitters)
    xs = Tuple{Int8,Float64}[]
    randemitterids = shuffle(collect(keys(emitters)))
    for (j, id) in enumerate(randemitterids)
        x = (id, t0 + (j - 1) * 20.0) # the first acoustic events is at t0, then every 20s is a next events from different emitters
        push!(xs, x)
    end
    xs
end
"""
    function signal_impulses(t0)

Given a certain time t0 where the acoustic events starts,
this function returns a vector of times, each seperated
by 5 seconds. The vector stores 11 time points, because
a Beacon on the seafloor emitts a series of 11 acoustic
signals every time it sends out a signal. 
"""
function signal_impulses(t0)
    ts = Float64[]
    for i in 0:10 # there are 11 impules during one emission of a signal from a beacon
        push!(ts, t0 + i * 5.0) # and there are 5s between impules
    end
    ts
end
"""
    function acoustic_event(detector, emitter, receivers, toe, run; p=0.8)

Simulates an acoustic event from one emitter to the receivers. The receiver gets the signal with a probability
of p. Returns a RawToashort. As an additional option one can simulates acoustic events with a given error.
Which can be given for example as: error = Normal(0, error) where Normal is a normal distribution from
Distribution.jl. 
"""
function acoustic_event(detector, emitter, invwaveform, receivers, toe, run; p=1.0, error=0)
    emitterwaveform = invwaveform.ids[emitter.id]
    toashorts = RawToashort[]
    if error == 0
        for receiver in values(receivers)
            if rand() < p
                t = traveltime(emitter, receiver, detector.pos.z)
                toa = t + toe #+ rand(error)
                tshort = RawToashort(run, run, toa, receiver.id, emitterwaveform, 0.0, 0.0) # obda set TOA_S = Q = 0
                push!(toashorts, tshort)
            end
        end
    else
        for receiver in values(receivers)
            if rand() < p
                t = traveltime(emitter, receiver, detector.pos.z)
                toa = t + toe + rand(error)
                tshort = RawToashort(run, run, toa, receiver.id, emitterwaveform, 0.0, 0.0) # obda set TOA_S = Q = 0
                push!(toashorts, tshort)
            end
        end

    toashorts
end
"""
    function save_rawtoashorts(filename, toashorts, run)

Saves the simulated acoustic events in the same file format as the
data is stored in the database. However this will return a H5 file not a csv.
"""
function save_rawtoashorts(filename, toashorts, run)
    h5open(filename, "w") do h5f
        write_compound(h5f, "toashort/$(run)", toashorts)
    end
end
"""
    function mutate_modules(modules::T) where {T<:Array}
        
Helper function to change position of a given vector of modules.
The function will ask in the command line whether you want to 
add changes in the postition of a certain module. If no changes 
should be applied type <n> and <enter>. If the position should be 
changed type <change in x as Float> <spc> <change in y as Float>
<spc> <change in z as Float> and <enter>.
"""
function mutate_modules(modules::T) where {T<:Array}
    nmodules = typeof(modules[1])[]
    for mod in modules
        println("Add changes in position of $(typeof(mod)) $(mod.id): ")
        ipt = readline()
        if ipt != "n"
            x, y, z = split(ipt)
            pos = Position(parse.(Float64, [x, y, z])...)
            push!(nmodules, @set mod.pos = mod.pos + pos)
        else
            push!(nmodules, mod)
        end
    end
    nmodules
end

"""
    function mutate_modules(modules::T) where {T<:Dict}
        
Helper function to change position of a given dictionary of modules.
The function will ask in the command line whether you want to 
add changes in the postition of a certain module. If no changes 
should be applied type <n> and <enter>. If the position should be 
changed type <change in x as Float> <spc> <change in y as Float>
<spc> <change in z as Float> and <enter>.
"""
function mutate_modules(modules::T) where {T<:Dict}
    nmodules = typeof(modules)()
    for (k, mod) in modules
        println("Add changes in position of $(typeof(mod)) $(k): ")
        ipt = readline()
        if ipt != "n"
            x, y, z = split(ipt)
            pos = Position(parse.(Float64, [x, y, z])...)
            nmodules[k] = @set mod.pos = mod.pos + pos
        else
            nmodules[k] = mod
        end
    end
    nmodules
end

function shift_modules(modules::T, s::Position) where {T<:OrderedDict}
    nmodules = typeof(modules)()
    for (k, mod) in modules
        nmodules[k] = @set mod.pos = mod.pos + s
    end

    nmodules
end


function diff_modules(m1s, m2s)
    Δs = Position[]
    for k in keys(m1s)
        Δ = m1s[k].pos - m2s[k].pos
        push!(Δs, Δ)
        println("Difference in $(typeof(m1s[k])) $k = $(norm(Δ)) $Δ")
    end
    Δs
end



