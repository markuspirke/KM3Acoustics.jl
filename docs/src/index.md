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
   julia> using KM3Acoustics

   julia> detector = Detector(filename)
```

From here it is easy to get access to for examples modules or the position of the detector.

```julia
   julia> detector.pos
```

Gives you the UTM position of the detector.

```julia
   julia> detector.modules
   julia> mod = detector.modules[808965918]
```

Will return a dictionary where the keys represent the ID of a certain module and the value is the module itself.

It is also possible to read in other basic modules with the read function. For example if you want to read in the 
tripods, which are placed on the seabed. Here we defined a new data type called **Emitter**. The position of the emitters
are referenced with respect to the detector coordinate system. 

```julia
   julia> emitters = read(filename, Emitter, detector)
   julia> emitter7 = emitters[7]
```

From here you can calculate for example the time it takes for an acoustic signal to travel from a certain emitter to an module.

```julia
   julia> t = traveltime(emitter7, mod, detector.pos.z)
```

The traveltime function takes in two modules, but also needs the depth of the detector, as the soundvelocity in water depends
on the depth, and the z position of both the emitter and module is referenced with respect to the detector.
