doc = """Acoustics position calibration.

Usage:
  event_builder.jl [options]  -i INPUT_FILES_DIR -D DETX -E EVENT
  event_builder.jl -h | --help
  event_builder.jl --version

Options:
  -D DETX             The detector description file.
  -E EVENT            File containing acoustic events, e. g. KM3NeT_00000049_00011190_00011200_event.h5
  -i INPUT_FILES_DIR  Directory containing tripod.txt, hydrophone.txt, waveform.txt
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
    println("Reading hydrophones")
    hydrophones = read(joinpath(args["-i"], "hydrophone.txt"), Hydrophone)
    println("Reading tripods")
    tripods = read(joinpath(args["-i"], "tripod.txt"), Tripod)
    println("   Reading waveforms")
    waveforms = read(joinpath(args["-i"], "waveform.txt"), Waveform)

    events = read_events(args["-E"], 11190)
    calibration_events = group_events(events)


    emitters = tripod_to_emitter(tripods, detector)
    basemodules = get_basemodules(detector.modules, hydrophones)
    h = 9.5 # should be some function which returns all fixed parameters
    h₀ = 27.92
    initial_detector = init_toydetector(basemodules, h, h₀)
end

function init_optimparameters(events)
    toes = eventtime.(events)
    push!(0.0, toes)
    push!(0.0, toes)
    toes
end

main()
