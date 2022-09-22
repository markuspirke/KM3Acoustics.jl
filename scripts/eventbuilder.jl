doc = """Acoustics event builder.

Usage:
  event_builder.jl [options] -t TOASHORTS -D DETX
  event_builder.jl -h | --help
  event_builder.jl --version

Options:
  -t TOASHORTS        A CSV file containing the TOAs, obtained from the KM3NeT DB (toashorts).
  -D DETX             The detector description file.
  -H HYDROPHONEFILE   The hydrophones file with locations and positions [default: hydrophone.txt].
  -T TRIPODFILE       The hydrophones file with locations and positions [default: tripod.txt].
  -h --help           Show this screen.
  --version           Show version.

"""

using DocOpt
args = docopt(doc)

using KM3Acoustics

function main()
    detector = Detector(args["-D"])
    println("Reading hydrophones")
    hydrophones = read(args["-H"], Hydrophone)
    tripods = read(args["-T"], Tripod)
    println("Reading tripods")

    # receivers = Dict{Int, Receiver}()
    # emitters = Dict{Int, Emitter}()


    for (module_id, mod) ∈ detector.modules
        if (mod.location.floor == 0 && hydrophoneenabled(mod)) || (mod.location.floor != 0 && piezoenabled(mod))
            pos = Position(0, 0, 0)
        end
    end
end
main()
