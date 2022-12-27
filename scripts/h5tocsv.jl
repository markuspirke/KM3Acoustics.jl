doc = """Turn toashorts.h5 to toashorts.csv

Usage:
  newdetector.jl [options]  -t toashort -r RUN
  newdetector.jl -h | --help
  newdetector.jl --version

Options:
  -t toashort         Toashort in h5 format.
  -r RUN              Run number
  -h --help           Show this screen.
  --version           Show version.

"""

using DocOpt
using HDF5
using DelimitedFiles

function main()
    args = docopt(doc)
    println("Reading toashorts")
    rnumber = parse(Int, args["-r"])
    toashorts = h5open(args["-t"], "r") do io
        read(io["toashort/$(rnumber)"])
    end

    names = collect(keys(toashorts[1]))
    names = String.(names)
    names = hcat(names...)

    open("simtoashort.csv", "w") do io
        writedlm(io, names, "\t")
        writedlm(io, toashorts, "\t")
    end
end

main()
