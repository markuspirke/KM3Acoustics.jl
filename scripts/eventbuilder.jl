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
using Dates
println(Dates.format(now(), "HH:MM:SS"))
println("using docopt")
using DocOpt
args = docopt(doc)
println(Dates.format(now(), "HH:MM:SS"))
println("using KM3Acoustics")
using KM3Acoustics
println(Dates.format(now(), "HH:MM:SS"))
import DataStructures: DefaultDict
println("import DefaultDict")
#using DataStructures # maybe better import DataStructures: DefaultDict
# import DataStructures: DefaultDict
println(Dates.format(now(), "HH:MM:SS"))
println("read in detx")

function main()
    detector = Detector(args["-D"])
    println(Dates.format(now(), "HH:MM:SS"))
    println("reading toashort")
    println("Reading toashort")
    toashort = read_toashort(args["-t"])

    println(Dates.format(now(), "HH:MM:SS"))
    println("Reading hydrophones")
    hydrophones = read(joinpath(args["-i"], "hydrophone.txt"), Hydrophone)
    println("Reading tripods")
    tripods = read(joinpath(args["-i"], "tripod.txt"), Tripod)
    println("Reading waveforms")
    waveforms = read(joinpath(args["-i"], "waveform.txt"), Waveform)
    println(Dates.format(now(), "HH:MM:SS"))
    trigger = read(joinpath(args["-i"], "acoustics_trigger_parameters.txt"), TriggerParameter)
    println("Reading trigger parameters")


    receivers = Dict{Int32, Receiver}()
    emitters = Dict{Int8, Emitter}()
    for tripod ∈ tripods
        emitters[tripod.id] = Emitter(tripod.id, tripod.pos - detector.pos)
    end
    hydrophones1 = Dict{Int32, Hydrophone}()
    for hydrophone ∈ hydrophones
        hydrophones1[hydrophone.location.string] = hydrophone
    end

    for (module_id, mod) ∈ detector.modules
        if (mod.location.floor == 0 && hydrophoneenabled(mod)) || (mod.location.floor != 0 && piezoenabled(mod))
            pos = Position(0, 0, 0)
            if mod.location.floor == 0
               pos += hydrophones1[mod.location.string].pos
            end
            pos += mod.pos
            receivers[module_id] = Receiver(module_id, pos)
        end
    end

    DD = DefaultDict{Int32, DefaultDict}(DefaultDict{Int32, Vector{Transmission}}(Vector{Float64}))

    for row ∈ eachrow(toashort)
        emitter_id = waveforms.ids[row.EMITTERID] # transform EMITTERID from toashort to tripod ID
        if (haskey(receivers, row.DOMID)) && (haskey(emitters, emitter_id)) #check if DOM and Tripod is in detector
            toe = row.UTC_TOA - traveltime(receivers[row.DOMID], emitters[emitter_id]) #calculate TOE
            T = Transmission(row.RUN, row.DOMID, row.QUALITYFACTOR, row.UTC_TOA, toe) #write info in transmission
            push!(DD[emitter_id][row.DOMID], T)
        end
    end
    println(Dates.format(now(), "HH:MM:SS"))
    println([length(DD[1][808960332]), length(DD[2][808960332]), length(DD[3][808960332])])

    for (emitter_id, receivers) ∈ DD #filter out similar events
       for (receiver_id, transmissions) ∈ receivers
           sort!(transmissions)
           unique!(x -> x.TOA, transmissions)
           # sort!(transmissions, by = x -> x.TOE) # at last sort the transmissions by TOE
        end
    end

    println([length(DD[1][808960332]), length(DD[2][808960332]), length(DD[3][808960332])])
    println(typeof(DD[1][808960332]))
    println(Dates.format(now(), "HH:MM:SS"))

    events = Event[]
    println(length(DD))
    for (emitter_id, receivers) ∈ DD
        transmissions_buffer = Transmission[]
        for (receiver_id, transmissions) ∈ receivers #there is still some statistics missing
            transmissions_buffer = vcat(transmissions_buffer, transmissions)
        end
        sort!(transmissions_buffer, by = x -> x.TOE)
        buffer_length = length(transmissions_buffer)

        for (i, transmission) ∈ enumerate(transmissions_buffer)
            j = copy(i)
            j += 1
            while (j <= buffer_length) && (transmissions_buffer[j].TOE - transmission.TOE <= trigger.tmax)
                j += 1
            end
            k = j - i + 1 #events in time frame
            if k >= trigger.nmin
               push!(events, Event(detector.id, k, emitter_id, transmissions_buffer[i:j]))
            end
        end
    end
    println(length(events))
    print(events[2])
            
end
main()
