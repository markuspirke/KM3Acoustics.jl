doc = """Acoustics position calibration.

Usage:
  event_builder.jl [options]  -i INPUT_FILES_DIR -D DETX -E EVENT -r RUN
  event_builder.jl -h | --help
  event_builder.jl --version

Options:
  -D DETX             The detector description file.
  -E EVENT            File containing acoustic events, e. g. KM3NeT_00000049_00011190_00011200_event.h5
  -i INPUT_FILES_DIR  Directory containing tripod.txt, hydrophone.txt, waveform.txt
  -r RUN              Run to analyse.
  -h --help           Show this screen.
  --version           Show version.

"""
using DocOpt
using KM3Acoustics
using ProgressMeter
using Optim

function main()
    args = docopt(doc)
    println("Reading detector")
    detector = Detector(args["-D"])
    println("Reading events")
    events = read_events(args["-E"], parse(Int,args["-r"]))
    println("Reading hydrophones")
    hydrophones = get_hydrophones(joinpath(args["-i"], "hydrophone.txt"), detector, events)
    println("Reading tripods")
    tripods = read(joinpath(args["-i"], "tripod.txt"), Tripod)
    emitters = tripod_to_emitter(tripods, detector)
    key_fixhydro = collect(keys(hydrophones))[1]

    pc = Precalibration(detector.pos, hydrophones, key_fixhydro, events, emitters)
    p0 = precalibration_startvalues(pc)
    res = optimize(pc, p0, ConjugateGradient(); autodiff= :forward)
    println("reduced chi2: $(pc(res.minimizer))")
    new_emitters = get_opt_emitters(pc, res.minimizer)
    new_tripods = emitter_to_tripod(new_emitters, detector)
    new_hydrophones = get_opt_hydrophones(pc, res.minimizer)

    filename = joinpath(args["-i"], "newtripod.txt")
#    rm(filename)
    write(filename, new_tripods)

end

main()
