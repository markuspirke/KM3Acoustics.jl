using KM3Acoustics
pathtest = "/Users/markuspirke/Projects/KM3Acoustics/test/samples/"
pathdir = "/Users/markuspirke/Projects/KM3Acoustics/testdata/00000133/"
detector = Detector(joinpath(pathtest, "KM3NeT_00000133_00013346.detx"))
events = read_events(joinpath(pathtest, "KM3NeT_00000133_00013346_preevent.h5"), 13346)
hydrophones = get_hydrophones(joinpath(pathtest, "hydrophone.txt"), detector, events)
emitters = read(joinpath(pathtest, "tripod.txt"), Emitter, detector)
# tripods = read(joinpath(pathdir, "tripod.txt"), Tripod)
# emitters = tripod_to_emitter(tripods, detector)

x = 10
fixhydro = [(x, :x), (x, :y), (x, :z)]
fixemitters = []

pc = Precalibration(detector.pos, events, hydrophones, fixhydro, emitters, fixemitters; rotate=0, nevents=10)
@show pc(pc.p0s)
