doc = """Acoustics event builder for precalibration.

Usage:
  event_builder.jl [options]  -i INPUT_FILES_DIR -D DETX -t TOASHORTS -r RUNS
  event_builder.jl -h | --help
  event_builder.jl --version

Options:
  -t TOASHORTS        A CSV file containing the TOAs, obtained from the KM3NeT DB (toashorts).
  -D DETX             The detector description file.
  -i INPUT_FILES_DIR  Directory containing tripod.txt, hydrophone.txt, waveform.txt
  -r RUNS             The runs to analyse, e.g. 2 or 2:11 or 2,7,11.
  -h --help           Show this screen.
  --version           Show version.

"""
using DocOpt
using KM3Acoustics
using HDF5
using ProgressMeter
import DataStructures: DefaultDict

function main()
    args = docopt(doc)
    println("Reading detector")
    detector = Detector(args["-D"])
    println("Reading hydrophones")
    hydrophones = read(joinpath(args["-i"], "hydrophone.txt"), Hydrophone)
    println("Reading tripods")
    tripods = read(joinpath(args["-i"], "tripod.txt"), Tripod)
    println("Reading waveforms")
    waveforms = read(joinpath(args["-i"], "waveform.txt"), Waveform)

    println("Time window for trigger in ms: ")
    trigtime = parse(Float64, readline())
    println("Minimum number of modules which detected a signal: ")
    trignumber = parse(Int64, readline())
    trigger_param = TriggerParameter(0.0, trigtime * 1e-3, trignumber)

    emitters = tripod_to_emitter(tripods, detector)
    emitters = mutate_modules(emitters)
    emitter_aliens = DefaultDict{Int8,Int}(0)

    write("modified_tripod.txt", emitter_to_tripod(emitters, detector))
    receivers = check_basemodules(detector, hydrophones)
    h5open(args["-t"], "r") do inh5 #open toashorts.h5
        ks = parse.(Int, keys(inh5["toashort"])) # ks all RUNs which are in toashorts.h5
        runs = parse_runs(args["-r"]) # RUNs we want to process

        if typeof(runs) == Int # for output filename
            run_number = lpad(runs, 8, '0')
            det_id = lpad(detector.id, 8, '0')
            filename = "KM3NeT_$(det_id)_$(run_number)_simevent.h5"
        elseif typeof(runs) == UnitRange{Int}
            run_min = lpad(runs[1], 8, '0')
            run_max = lpad(runs[end], 8, '0')
            det_id = lpad(detector.id, 8, '0')
            filename = "KM3NeT_$(det_id)_$(run_min)_$(run_max)_simevent.h5"
        end
        println("Reading toashort")
        h5open(filename, "w") do outh5
            @showprogress "Processing runs" for run in runs
                if run in ks
                    toashorts = read(inh5, Toashort, run)
                    all_transmissions = transmissions_by_emitterid(emitters)
                    calculate_TOE!(all_transmissions, toashorts, waveforms, receivers, emitters, detector.pos.z, emitter_aliens)
                    events = build_events(all_transmissions, detector.id, run, trigger!, trigger_param)
                    print_results(run, emitter_aliens, all_transmissions, events)
                    save_events(events, outh5, run)
                else
                    @warn "run $(run) not in toashorts.h5"
                end
            end
        end
    end
end
"""
    function transmissions_container(emitters)

Sets up an dictionary with keys emitter id for all transmissions.
"""
function transmissions_by_emitterid(emitters)
    d = Dict{Int32,Vector{Transmission}}()
    for (id, emitter) ∈ emitters
        d[id] = Transmission[]
    end
    d
end
"""
    function calculate_TOE!(DD, toashorts, waveforms, receivers, emitters)

Changes emitter ids from toashort to tripod ids from tripod.txt. Then checks if ids from the signals from toashorts coincide
with ids in the detector. If they coincide the TOE is calculated and a transmission is pushed into an Dictionary.
"""
function calculate_TOE!(all_transmissions, toashorts, waveforms, receivers, emitters, det_depth, emitter_aliens)
    for toashort ∈ toashorts
        if toashort.EMITTERID in keys(waveforms.ids)
            emitter_id = waveforms.ids[toashort.EMITTERID]
            if (haskey(receivers, toashort.DOMID)) && (haskey(emitters, emitter_id))
                if toashort.QUALITYFACTOR >= 0.0
                    toa = toashort.UTC_TOA
                    toe = toa - traveltime(receivers[toashort.DOMID], emitters[emitter_id], det_depth)
                    T = Transmission(toashort.DOMID, receivers[toashort.DOMID].location.string, receivers[toashort.DOMID].location.floor, toashort.QUALITYFACTOR, toa, toe)
                    push!(all_transmissions[emitter_id], T)
                end
            end
        else
            emitter_aliens[toashort.EMITTERID] += 1
        end
    end
end
"""
    function trigger!(events, emitter_id, transmissions, trigger, det_id)

If the number of signals from one emitter during a time window tmax exceeds a preset threshold and event is triggered.
An event is written if more than nmin signals appear during the time window and if the time difference between additional signals is
less than tmax these signals are also included in the event.
"""
function trigger!(events, emitter_id, transmissions, trigger, det_id, run_number)
    L = length(transmissions)
    j = 2 # start at two to compare with event 1
    i = 1
    while (i <= L) && (j <= L) # go through all signals
        while (j <= L - 1) && (transmissions[j].TOE - transmissions[i].TOE <= trigger.tmax)
            j += 1 # group signal during a certain kind of time intervall
        end
        k = j - i + 1 #events in time frame

        if k >= trigger.nmin #if more then 90 signal during tmax write down the event
            push!(events, Event(det_id, run_number, k, emitter_id, transmissions[i:j-1]))
            i = j #set loop to event j which is the first event not involved in event ealier
        else
            i += 1 #if less then nmin signals start with next transmission
        end
    end
end
"""
    function build_events!(events, DD, det_id, trigger)

Sorts all transmissions from one emitter by TOE and then build events.
"""
function build_events(all_transmissions, det_id, run_number, trigger!, trigger_param)
    events = Event[]
    for (emitter_id, transmissions) ∈ all_transmissions
        sort!(transmissions, by=x -> x.TOE)
        trigger!(events, emitter_id, transmissions, trigger_param, det_id, run_number)
    end
    events
end
"""
Summary of the eventbuilder.
"""
function print_results(run, emitter_aliens, all_transmissions, events; check_basemodules=false)
    for (id, transmissions) in all_transmissions
        number_transmissions = length(transmissions)
        println("number of transmissions in run $(run): $(id) $(number_transmissions)")
    end
    if length(emitter_aliens) != 0
        @warn "unknown emitter in toashorts"
    end
    for (id, aliens) in emitter_aliens
        println("number of aliens in run $(run): $(id) $(aliens)")
    end
    event_counter = DefaultDict{Int8,Int}(0)
    for event in events
        event_counter[event.id] += 1
    end
    if check_basemodules
        N_basemodules = 0
        for event in events
            n_basemodules = 0
            for transmission in event.data
                if transmission.floor == 0
                    n_basemodules += 1
                end
            end
            if n_basemodules > 0
                N_basemodules += 1
                println("number of basemodules involved in event in run $(run): $(n_basemodules)")
            end
        end
        if N_basemodules == 0
            @warn "no basemodules involved in any event in run $(run)"
        end
    end

    for (id, number_events) in event_counter
        println("number of events in run $(run): $(id) $(number_events)")
    end
end
main()
