
using KM3Acoustics

@testset "misc" begin

    @test ["Foo13", "Foo101"] == sort(["Foo101", "Foo13"], lt=natural)

    @test 42 == parse_runs("42")
    @test 42:47 == parse_runs("42:47")
    @test [42, 43, 47] == parse_runs("42,43,47")

end
