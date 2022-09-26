doc = """Acoustics event builder.

Usage:
  event_builder.jl [options] -i INPUT_FILES_DIR -D DETX -t TOASHORTS
  event_builder.jl -h | --help
  event_builder.jl --version

Options:
  -t TOASHORTS        A CSV file containing the TOAs, obtained from the KM3NeT DB (toashorts).
  -D DETX             The detector description file.
  -i INPUT_FILES_DIR  Directory containing tripod.txt, hydrophone.txt...
  -h --help           Show this screen.
  --version           Show version.

"""

using DocOpt
args = docopt(doc)

using KM3Acoustics

function main()
    detector = Detector(args["-D"])

    println("Reading hydrophones")
    hydrophones = read(joinpath(args["-i"], "hydrophone.txt"), Hydrophone)

    println("Reading tripods")
    tripods = read(joinpath(args["-i"], "tripod.txt"), Tripod)

    # receivers = Dict{Int, Receiver}()
    # emitters = Dict{Int, Emitter}()


    for (module_id, mod) ∈ detector.modules
        if (mod.location.floor == 0 && hydrophoneenabled(mod)) || (mod.location.floor != 0 && piezoenabled(mod))
            pos = Position(0, 0, 0)
        end
    end
end
main()
