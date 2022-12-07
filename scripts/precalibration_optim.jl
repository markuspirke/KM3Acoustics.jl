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
using Optim
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
  # fixhydros = []#[(21, :x), (21, :y), (21, :z)]
  fixhydros = fix_all_hydros(hydrophones)
  fixemitter = []
  fixemitter = [(10, :z), (13, :z), (9, :z), (8, :z), (12, :z), (7, :z)]
  KM3Acoustics.diff_modules(refemitters, emitters)
  pc = Precalibration(detector.pos, events, hydrophones, fixhydros, emitters, fixemitter; rotate=0, nevents=10, mask=1:2)
  @show pc(pc.p0s)
  res = Optim.optimize(pc, pc.p0s, Newton(), Optim.Options(; g_tol=1e-12, f_reltol=1e-16, show_trace=true); autodiff=:forward)
  p = res.minimizer
  @show Optim.iterations(res)
  @show Optim.iteration_limit_reached(res)
  @show Optim.converged(res)
  @show pc(p)
  nhydros, nemitters = get_opt_modules(p, pc)
  toes = KM3Acoustics.get_opt_toes(p, pc)
  # @show toes
  Δemitters = KM3Acoustics.diff_modules(refemitters, nemitters)
  # Δhydros = KM3Acoustics.diff_modules(hydrophones, nhydros)
  # Δmean = mean(vcat(Δemitters, Δhydros))

  # nnhydros = KM3Acoustics.shift_modules(nhydros, Δmean)
  # nnemitters = KM3Acoustics.shift_modules(nemitters, Δmean)
  # KM3Acoustics.diff_modules(refemitters, nnemitters)
  # KM3Acoustics.diff_modules(hydrophones, nnhydros)

end

function fix_all_hydros(hydros)
  fixhydros = []
  for k in collect(keys(hydros))
    push!(fixhydros, (k, :x))
    push!(fixhydros, (k, :y))
    push!(fixhydros, (k, :z))
  end
  fixhydros
end


main()
