doc = """Acoustics event builder.

Usage:
  event_builder.jl [options]  -i INPUT_FILES_DIR -D DETX -t TOASHORTS
  event_builder.jl -h | --help
  event_builder.jl --version

Options:
  -t TOASHORTS        A CSV file containing the TOAs, obtained from the KM3NeT DB (toashorts).
  -D DETX             The detector description file.
  -i INPUT_FILES_DIR  Directory containing tripod.txt, hydrophone.txt, waveform.txt
  -h --help           Show this screen.
  --version           Show version.

"""
using DocOpt
args = docopt(doc)
println("using KM3Acoustics")
using KM3Acoustics
import DataStructures: DefaultDict
println("import DefaultDict")
#using DataStructures # maybe better import DataStructures: DefaultDict
# import DataStructures: DefaultDict

function main()
    println("Reading detector")
    detector = Detector(args["-D"])
    println("Reading toashort")
    toashort = read_toashort(args["-t"])

    println("Reading hydrophones")
    hydrophones = read(joinpath(args["-i"], "hydrophone.txt"), Hydrophone)
    println("Reading tripods")
    tripods = read(joinpath(args["-i"], "tripod.txt"), Tripod)
    println("Reading waveforms")
    waveforms = read(joinpath(args["-i"], "waveform.txt"), Waveform)
    trigger = read(joinpath(args["-i"], "acoustics_trigger_parameters.txt"), TriggerParameter)
    println("Reading trigger parameters")


    receivers = Dict{Int32, Receiver}()
    emitters = Dict{Int8, Emitter}()

    tripod_to_emitter!(tripods, emitters, detector)

    hydrophones1 = Dict{Int32, Hydrophone}()
    for hydrophone ∈ hydrophones # makes a dictionary of hydrophones, with string number as keys
        hydrophones1[hydrophone.location.string] = hydrophone
    end

    check_modules!(receivers, detector, hydrophones1)

    DD = Dict{Int32, Vector{Transmission}}()
    for (id, emitter) ∈ emitters
        DD[id] = Transmission[]
    end

    calculate_TOE!(DD, toashort, waveforms, receivers, emitters)

    events = Event[]
    build_events!(events, DD, trigger, detector)

    #     eventX = events[1]
    #     N = 1
    #     while N <= length(events)
    #         if event[N] != eventx
    #             eventx = event
    #         end

    #         while N <= length(events) && match(event[N],eventX)
    #             merge(event[N], eventX)
    #             N += 1
    #         end
    #     end
    # end
end

function tripod_to_emitter!(tripods, emitters, detector)
    for tripod ∈ tripods # change position of tripods from .txt file to relative position of the detector
        emitters[tripod.id] = Emitter(tripod.id, tripod.pos - detector.pos)
    end
end

function check_modules!(receivers, detector,hydrophones)
    for (module_id, mod) ∈ detector.modules # go through all modules and check whether they are base modules and have hydrophone
        if (mod.location.floor == 0 && hydrophoneenabled(mod)) || (mod.location.floor != 0 && piezoenabled(mod)) #or they are no base module and have piezo
            pos = Position(0, 0, 0)
            if mod.location.floor == 0 # if base module and hydrophone
               pos += hydrophones[mod.location.string].pos # position in of hydrophone relative to T bar gets added
            end
            pos += mod.pos
            receivers[module_id] = Receiver(module_id, pos)
        end
    end
end

function calculate_TOE!(DD, toashort, waveforms, receivers, emitters)
    for row ∈ eachrow(toashort)
        emitter_id = waveforms.ids[row.EMITTERID]
        if (haskey(receivers, row.DOMID)) && (haskey(emitters, emitter_id))
            toe = row.UTC_TOA - traveltime(receivers[row.DOMID], emitters[emitter_id])
            T = Transmission(row.RUN, row.DOMID, row.QUALITYFACTOR, row.UTC_TOA, toe)
            push!(DD[emitter_id], T)
        end
    end
end

function build_events!(events, DD, trigger, detector)
    for (emitter_id, transmissions) ∈ DD
        sort!(transmissions, by = x -> x.TOE)
        L = length(transmissions)
        for (i, transmission) ∈ enumerate(transmissions) # go through all signals
            j = copy(i)
            j += 1
            while (j <= L) && (transmissions[j].TOE - transmission.TOE <= trigger.tmax)
                j += 1 # group signal during a certain kind of time intervall
            end
            k = j - i + 1 #events in time frame
            if k >= trigger.nmin #if more then 90 signal during tmax write down the event
               push!(events, Event(detector.id, k, emitter_id, transmissions[i:j]))
            end
        end
    end
end

main()
