doc = """Acoustics position calibration.

Usage:
  precalibration.jl [options]  -i INPUT_FILES_DIR -D DETX -E EVENT -r RUN
  precalibration.jl -h | --help
  precalibration.jl --version

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
using JuMP
using Ipopt
#using KM3AcousticsPlots
#using GLMakie

function main()
  args = docopt(doc)
  println("Reading detector")
  detector = Detector(args["-D"])
  println("Reading events")
  events = read_events(args["-E"], parse(Int, args["-r"]))
  println("Reading hydrophones")
  hydrophones = get_hydrophones(joinpath(args["-i"], "hydrophone.txt"), detector, events)
  println("Reading tripods")
  refemitters = read(joinpath(args["-i"], "tripod.txt"), Emitter, detector)
  emitters = read(joinpath(args["-i"], "modified_tripod.txt"), Emitter, detector)

  fixhydros = []
  fixemitter = [(8, :x), (8, :y), (8, :z)]
  pc = Precalibration(detector.pos, events, hydrophones, fixhydros, emitters, fixemitter; rotate=0, nevents=30, mask=1:3)
  @show pc(pc.p0s)
  model = Model(optimizer_with_attributes(
    Ipopt.Optimizer,
    "tol" => 1e-3,
    "max_iter" => 200,
    "print_level" => 3)
  )
  #        set_optimizer_attribute(model, "max_cpu_time", 60.0)
  register(model, :pc, length(pc.p0s), pc; autodiff=true)
  @variable(model, x[1:length(pc.p0s)])
  for (i, xi) in enumerate(x)
    set_start_value(xi, pc.p0s[i])
  end
  # @constraint(model, ch, -4.0 .<= x[3:3:3*length(pc.hydrophones)] - pc.p0s[3:3:3*length(hydrophones)] .<= 4.0)
  # @constraint(model, c, -1e-4 .<= x[length(pc.p0s)-pc.numevents+1:end] - pc.p0s[length(pc.p0s)-pc.numevents+1:end] .<= 1e-4)
  @NLobjective(model, Min, pc(x...))
  JuMP.optimize!(model)
  p = value.(x)
  @show pc(p)
  nhydros, nemitters = get_opt_modules(p, pc)
  KM3Acoustics.diff_modules(refemitters, nemitters)
end

main()
