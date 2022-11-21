using KM3Acoustics

pathdir = "/Users/markuspirke/Projects/KM3Acoustics/testdata/00000133/"
detector = Detector(joinpath(pathdir, "KM3NeT_00000133_00013346.detx"))
events = read_events(joinpath(pathdir, "KM3NeT_00000133_00013346_preevent.h5"), 13346)
hydrophones = get_hydrophones(joinpath(pathdir, "hydrophone.txt"), detector, events)
tripods = read(joinpath(pathdir, "tripod.txt"), Tripod)
emitters = tripod_to_emitter(tripods, detector)

x = 10
fixhydro = [(x, :x), (x, :y), (x, :z)]
fixemitters = []

# pc = Precalibration(detector.pos, events, hydrophones, fixhydro, emitters, fixemitters; rotate=0, nevents=5)
pc = KM3Acoustics.Precalibration(detector.pos, hydrophones, 10, events, emitters; numevents=30)
p0 = KM3Acoustics.precalibration_startvalues(pc)
@show pc(p0)
