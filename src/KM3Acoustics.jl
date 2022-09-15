module KM3Acoustics

using WAV
using Plots

using CSV
using DataFrames

export
   read_asignal, plot_asignal, to_wav

include("acoustics.jl")
include("acoustics_eventbuilder.jl")
end
