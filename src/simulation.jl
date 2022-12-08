"""
    function inverse_waveforms(waveform::Waveform)

Return an inverse ( not injective ) map of the waveform.txt file.
"""
function inverse_waveforms(waveform::Waveform)
    D = Dict{Int8,Int8}()
    for (k, value) in waveform.ids
        D[value] = k
    end
    Waveform(D)
end

function simulation_times(t0, emitters)
    xs = Tuple{Int8,Float64}[]
    randemitterids = shuffle(collect(keys(emitters)))
    for (j, id) in enumerate(randemitterids)
        x = (id, t0 + (j - 1) * 20.0) # the first acoustic events is at t0, then every 20s is a next events from different emitters
        push!(xs, x)
    end
    xs
end

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
of p. Returns a RawToashort.
"""
function acoustic_event(detector, emitter, invwaveform, receivers, toe, run; p=1.0)#, error=Normal(0.0, 50e-6))
    emitterwaveform = invwaveform.ids[emitter.id]
    toashorts = RawToashort[]
    for receiver in values(receivers)
        if rand() < p
            t = traveltime(emitter, receiver, detector.pos.z)
            toa = t + toe #+ rand(error)
            tshort = RawToashort(run, run, toa, receiver.id, emitterwaveform, 0.0, 0.0) # obda set TOA_S = Q = 0
            push!(toashorts, tshort)
        end
    end
    toashorts
end

function save_rawtoashorts(filename, toashorts, run)
    h5open(filename, "w") do h5f
        write_compound(h5f, "toashort/$(run)", toashorts)
    end
end

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



