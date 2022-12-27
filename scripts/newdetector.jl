doc = """Generates a new detector file with possible different positions of the modules.

Usage:
  newdetector.jl [options]  -D DETX -m MECH
  newdetector.jl -h | --help
  newdetector.jl --version

Options:
  -D DETX             The detector description file.
  -m MECH             Mechanical parameters of string shape.
  -h --help           Show this screen.
  --version           Show version.

"""
using DocOpt
using KM3Acoustics
using Setfield

function main()
    args = docopt(doc)
    println("Reading detector")
    detector = Detector(args["-D"])

    println("Set angle dx: ")
    dx = parse(Float64, readline())
    println("Set angle dy: ")
    dy = parse(Float64, readline())
    # mechanics = read(args["-m"], MechanicsParameter)
    if dx == 0.0 && dy == 0.0
        ndetector = detector
    else
        ndetector = newdetector(detector, dx, dy)#; mechanics.a, mechanics.b)
    end

    write("simdetector.detx", ndetector)
    open("angles_tx=$(dx)_ty=$(dy).txt", "w") do file
        write(file, "# Input Angles on each string\n")
        write(file, "tx\tty\n")
        write(file, "$(dx)\t$(dy)\n")
    end
end

function newdetector(detector::Detector, dx, dy; a=0.00311, b=400.966)
    nmods = typeof(detector.modules)()
    for mod ∈ detector
        if mod.location.floor != 0
            npos = calc_pos(dx, dy, mod.pos.z, a, b)
            npos = npos + Position(mod.pos.x, mod.pos.y, 0.0)
            nmod = @set mod.pos = npos
            nmods[mod.id] = nmod
        else
            @show mod
            nmods[mod.id] = mod
        end
    end
    @show length(nmods) length(detector.modules)
    ndetector = @set detector.modules = nmods
end

main()
