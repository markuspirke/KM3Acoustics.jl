doc = """Acoustics event builder for precalibration.

Usage:
  event_builder.jl [options]  -i INPUT_FILES_DIR -D DETX -e EVENTS -r RUNS
  event_builder.jl -h | --help
  event_builder.jl --version

Options:
  -D DETX             The detector description file.
  -e EVENTS           Acoustics events for calibration.
  -i INPUT_FILES_DIR  Directory containing tripod.txt, hydrophone.txt, waveform.txt
  -r RUNS             The runs to analyse, e.g. 2 or 2:11 or 2,7,11.
  -h --help           Show this screen.
  --version           Show version.

"""
using DocOpt
using KM3Acoustics
using HDF5
using ProgressMeter

function main()
    args = docopt(doc)
    println("Reading detector")
    detector = Detector(args["-D"])
    println("Reading events")
    events = read_events(args["-e"], parse(Int, args["-r"]))
    println("Reading hydrophones")
    hydrophones = get_hydrophones(joinpath(args["-i"], "hydrophone.txt"), detector, events)
    println("Reading tripods")
    emitters = read(joinpath(args["-i"], "tripod.txt"), Emitter, detector)

    fixhydro = []
    fixemitters = []
    pc = Precalibration(detector.pos, events, hydrophones, fixhydro, emitters, fixemitters; rotate=0, nevents=10)
    @show pc(pc.p0s)
end

main()