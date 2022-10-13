using KM3Acoustics
using Test
using HDF5

const SAMPLES_DIR = joinpath(@__DIR__, "samples")

@testset "eventbuilder" begin
    df = read_toashort(joinpath(SAMPLES_DIR, "input_toashort.csv"))
    @test 11190 == df.RUN[1]
    @test 808960332 == df.DOMID[1]
    @test -13 == df.EMITTERID[1]
    @test 2270 == df.QUALITYFACTOR[1]
    @test 1.6358893684634418e9 ≈ df.UTC_TOA[1]

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

    event = Event(49, 11190, 2, 1, [t1, t2])
    save_events([event], SAMPLES_DIR)

    filename = "KM3NeT_00000049_00011190_event.h5"
    header = h5read(joinpath(SAMPLES_DIR, filename), "event1/header")
    @test 49 == header[1]
    @test 2 == header[2]
    @test 1 == header[3]

    transmissions = reinterpret(Transmission, h5read(joinpath(SAMPLES_DIR, filename), "event1/transmissions"))
    @test t1 == transmissions[1]
    @test t2 == transmissions[2]

    rm(joinpath(SAMPLES_DIR, filename))

end
