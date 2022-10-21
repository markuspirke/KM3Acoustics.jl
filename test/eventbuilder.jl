using KM3Acoustics
using Test
using HDF5

const SAMPLES_DIR = joinpath(@__DIR__, "samples")

@testset "eventbuilder" begin
    toashorts = h5open(joinpath(SAMPLES_DIR, "toashort_test.h5"), "r") do h5f
                           read(h5f, Toashort, 11190)
                end
    # toashorts = read(joinpath(SAMPLES_DIR, "toashort_test.h5"), Toashort, 11190)
    @test 11190 == toashorts[1].RUN
    @test 808960332 == toashorts[1].DOMID
    @test -13 == toashorts[1].EMITTERID
    @test 2270.0 ≈ toashorts[1].QUALITYFACTOR
    @test 2153.0 ≈ toashorts[2].QUALITYFACTOR
    @test 1.635889368463442e9 ≈ toashorts[1].UTC_TOA

    tripods = read(joinpath(SAMPLES_DIR, "tripod.txt"), Tripod)
    detector = Detector(joinpath(SAMPLES_DIR, "v5.detx"))
    emitters = tripod_to_emitter(tripods, detector)
    @test 7 == emitters[7].id
    @test Position(-401.3719999999739, -571.3070000000298, 16.69399999999996) ≈ emitters[7].pos

    A = Transmission(1, 1, 1, 1.0, 1.1, 0.0)
    B = Transmission(1, 1, 1,  2.0, 1.1, 0.0)
    C = Transmission(1, 1, 1,  1.0, 1.0, 0.0)

    @test false == isless(A, B) # A.TOA = B.TOA, but B.Q > A.Q => B should be first
    @test true == isless(B, A)
    @test false == isless(B, C) # C.TOA < B.TOA => C should be first
    @test true == isless(C, B)

    @test [B, A] == sort!([A, B])
    @test [B, A] == sort!([B, A])
    @test [C, B] == sort!([B, C])
    @test [C, B] == sort!([C, B])

    t1 = Transmission(1, 1, 1,  1.0, 1.0, 1.1)
    t2 = Transmission(1, 1, 1,  1.0, 1.0, 1.2)
    t3 = Transmission(1, 1, 1,  1.0, 1.0, 1.25)
    t4 = Transmission(1, 1, 1,  1.0, 1.0, 1.46)
    t5 = Transmission(1, 1, 1,  1.0, 1.0, 1.5)
    e1 = Event(1, 1, 1, 1, [t1, t2, t3])
    e2 = Event(1, 1, 1, 1, [t2, t3])
    e3 = Event(1, 1, 1, 1, [t4, t5])
    @test true == overlap(e1, e1, 0.2)
    @test false == overlap(e1, e3, 0.2)
    @test 1 == length(e1)

    event = Event(49, 1, 2, 1, [t1, t2])
    filename = "KM3NeT_00000049_00000001_event.h5"
    h5open(joinpath(SAMPLES_DIR, filename), "w") do h5f
        save_events([event], h5f, 1)
    end
    header = h5read(joinpath(SAMPLES_DIR, filename), "/1/event1/header")
    @test 49 == header[1]
    @test 2 == header[2]
    @test 1 == header[3]

    transmissions = reinterpret(Transmission, h5read(joinpath(SAMPLES_DIR, filename), "/1/event1/transmissions"))
    @test t1 == transmissions[1]
    @test t2 == transmissions[2]

    rm(joinpath(SAMPLES_DIR, filename))

end
