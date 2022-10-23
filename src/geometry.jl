struct ToyString
    id::Int32
    pos::Position #position of the tbar at the seabed
    θ::Float64 # polar angle
    ϕ::Float64 # azimuthal angle
    h₀::Float64 # height from base to first module
    h::Float64 # height of a floor
end

struct ToyModule
    id::Int32 #why ID ???
    location::Location
    pos::Position
end

struct ToyDetector
    strings::Dict{Int32, ToyString}
end

function toy_position(θ, ϕ, j, toystring) # x = [ϕ, θ], j floor
    if j == 0
        ToyModule(1, Location(toystring.id, j), toystring.pos)
    elseif j == 1
        x = toystring.pos + toystring.h₀ * j * Position(sin(θ)*cos(ϕ), sin(θ)*sin(ϕ), cos(θ))
        ToyModule(1, Location(1,j), x)
    else
        x = toystring.pos + (toystring.h * (j-1) + toystring.h₀) * Position(sin(θ)*cos(ϕ), sin(θ)*sin(ϕ), cos(θ))
        ToyModule(1, Location(1,j), x)
    end
end

function toy_toa(p, j, tripod, toystring)
    t, ϕ, θ = p

    mod = toy_position(ϕ, θ, j, toystring)

    toa = t + traveltime(tripod, mod, -2440.0)
end

