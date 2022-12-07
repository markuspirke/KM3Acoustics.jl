doc = """Acoustics event builder for precalibration.

Usage:
  event_builder.jl [options]  -i INPUT_FILES_DIR -D DETX -r RUN
  event_builder.jl -h | --help
  event_builder.jl --version

Options:
  -D DETX             The detector description file.
  -i INPUT_FILES_DIR  Directory containing tripod.txt, hydrophone.txt, waveform.txt
  -r RUN             The runs to analyse, e.g. 2 or 2:11 or 2,7,11.
  -h --help           Show this screen.
  --version           Show version.

"""
using DocOpt
using KM3Acoustics
using Dates
using HDF5
using ProgressMeter

function main()
  args = docopt(doc)
  println("Reading detector")
  detector = Detector(args["-D"])
  println("Reading hydrophones")
  hydrophones = read(joinpath(args["-i"], "hydrophone.txt"), Hydrophone)
  println("Reading tripods")
  emitters = read(joinpath(args["-i"], "tripod.txt"), Emitter, detector)
  println("Reading waveforms")
  waveforms = read(joinpath(args["-i"], "waveform.txt"), Waveform)
  run = parse(Int, args["-r"])

  basemodules = check_basemodules(detector, hydrophones)
  invwaveforms = inverse_waveforms(waveforms)
  t0 = datetime2unix(now())
  id_times = simulation_times(t0, emitters)
  rawtoashorts = RawToashort[]

  for (id, t) in id_times
    tshorts = simulate(detector, emitters[id], invwaveforms, basemodules, t, run)
    rawtoashorts = vcat(rawtoashorts, tshorts)
  end
  run_number = lpad(run, 8, '0')
  det_id = lpad(detector.id, 8, '0')
  filename = "KM3NeT_$(det_id)_$(run_number)_simtoashort.h5"
  save_rawtoashorts(filename, rawtoashorts, run)
end

function simulate(detector, emitter, invwaveforms, basemodules, t0, run)
  ts = signal_impulses(t0)
  toashorts = RawToashort[]
  for t in ts
    tshorts = acoustic_event(detector, emitter, invwaveforms, basemodules, t, run; p=1.0)
    toashorts = vcat(toashorts, tshorts)
  end
  toashorts
end

"""
    function check_modules!(receivers, detector, hydrophones)

Checks if the modules in detector have hydrophones or piezos, if they have they will be written in receiver and emitters dicts.
"""
function check_modules(detector, hydrophones)
  receivers = Dict{Int32,Receiver}()

  hydrophones_map = Dict{Int32,Hydrophone}()
  for hydrophone ∈ hydrophones # makes a dictionary of hydrophones, with string number as keys
    hydrophones_map[hydrophone.location.string] = hydrophone
  end

  for (module_id, mod) ∈ detector.modules # go through all modules and check whether they are base modules and have hydrophone
    if (mod.location.floor == 0 && hydrophoneenabled(mod)) || (mod.location.floor != 0 && piezoenabled(mod)) #or they are no base module and have piezo
      pos = Position(0, 0, 0)
      if mod.location.floor == 0 # if base module and hydrophone
        if mod.location.string in keys(hydrophones_map)
          pos += hydrophones_map[mod.location.string].pos # position in of hydrophone relative to T bar gets added
        else
          @warn "no hydrophone for string $(mod.location.string)"
        end
      end
      pos += mod.pos
      receivers[module_id] = Receiver(module_id, pos, mod.location, mod.t₀)
    end
  end
end
main()
