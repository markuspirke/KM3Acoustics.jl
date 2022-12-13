# KM3Acoustics

[![Build Status](https://github.com/mpirke/KM3Acoustics.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/mpirke/KM3Acoustics.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/mpirke/KM3Acoustics.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/mpirke/KM3Acoustics.jl)
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://mpirke.github.io/KM3Acoustics.jl/dev/)

KM3Acoustics is a Julia package for the acoustic position calibration of the KM3NeT detectors. At the moment it is possible to reconstruct acoustic events and simulate acoustic events.

## Usage
KM3Acoustics.jl is not an official registered Julia package. The easiest way to way to use this package is to add the KM3NeT registry to your Julia registires.
Just clone the following repository with

> git clone https://git.km3net.de/common/julia-registry ~/.julia/registries/KM3NeT

then you can just use this package in the usual way. For example

> julia> import Pkg; Pkg.add("KM3Acoustics")

You can also visit the KM3NeT GitLab site for more information, about the KM3NeT Julia registry, with the following link

 > https://git.km3net.de/common/julia-registry/-/blob/main/README.md

 ## Introduction

 The most basic thing you need to calibrate a detector, is obviously the detector itself. The **Detector** struct is a type which stores 
 all the information from a .detx file. There is also a method that allows you to read in such a .detx file with the Detector struct.
 This is done in the following way: 

 ```julia
    detector = Detector(filename)
 ```




