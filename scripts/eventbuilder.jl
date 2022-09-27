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
    toashort = remove_idevents(args["-t"])

    println(Dates.format(now(), "HH:MM:SS"))
    println("Reading hydrophones")
    hydrophones = read(joinpath(args["-i"], "hydrophone.txt"), Hydrophone)
    println("Reading tripods")
    tripods = read(joinpath(args["-i"], "tripod.txt"), Tripod)
    println("Reading waveforms")
    waveforms = read(joinpath(args["-i"], "waveform.txt"), Waveform)
    println(Dates.format(now(), "HH:MM:SS"))


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

    transmissions = DefaultDict{Int32, DefaultDict}(DefaultDict{Int32, Vector{Transmission}}(Vector{Float64}))

    for row in eachrow(toashort)
        emitter_id = waveforms.ids[row.EMITTERID]
        if (haskey(receivers, row.DOMID)) && (haskey(emitters, emitter_id))
            toe = row.UTC_TOA - traveltime(receivers[row.DOMID], emitters[emitter_id])
            T = Transmission(row.RUN, row.DOMID, row.QUALITYFACTOR, row.UTC_TOA, toe)
            push!(transmissions[emitter_id][row.DOMID], T)
        end
    end
    println(Dates.format(now(), "HH:MM:SS"))
    println([length(transmissions[1][808960332]), length(transmissions[2][808960332]), length(transmissions[3][808960332])])

    for (emmiter_id, receivers) in transmissions
       for (receiver_id, transmission) in receivers
           sort!(transmission)
           unique!(x -> x.TOA, transmission)
        end
    end

    println([length(transmissions[1][808960332]), length(transmissions[2][808960332]), length(transmissions[3][808960332])])
    println(Dates.format(now(), "HH:MM:SS"))

    # for (emitter_id,emitter) ∈ emitters
    #     d = DefaultDict{Int32, Vector{Transmission}}(Vector{Transmission})
    #     for (receiver_id,receiver) in receivers
    #         toe = traveltime(emitter,receiver)
    #         T = Transmission()




    
end
main()
