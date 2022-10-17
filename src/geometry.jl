struct ToyString
    id::Int32
    pos::Position #position of the tbar at the seabed
    θ::Float64 # polar angle
    ϕ::Float64 # azimuthal angle
    h₀::Float64 # height from base to first module
    h::Float64 # height of a floor
end

struct ToyModule
    id::Int32
    location::Location
    pos::Position
end

struct ToyDetector
    strings::Dict{Int32, ToyString}
end

function toy_position(θ, ϕ, j, toystring) # x = [ϕ, θ], j floor
    if j == 1
        x = toystring.pos + toystring.h₀ * j * Position(sin(θ)*cos(ϕ), sin(θ)*sin(ϕ), cos(θ))
        ToyModule(1, Location(1,j), x)
    else
        x = toystring.pos + toystring.h * j * Position(sin(θ)*cos(ϕ), sin(θ)*sin(ϕ), cos(θ))
        ToyModule(1, Location(1,j), x)
    end
end

function toy_toa(p, j, tripod, toystring)
    t, ϕ, θ = p

    mod = toy_position(ϕ, θ, j, toystring)
    R = norm(tripod.pos - mod.pos)
    # V = (velocity(tripod.pos.z).v₀ + velocity(toystring.tbar.z).v₀)/2.0

    toa = t + traveltime(tripod, mod, -2440.0)
end

L(p, j, x, T) = (T - toy_toa(p, j, x))^2

function loss(p, d, toystring::ToyString, emitter::Emitter)
    sum([(toa - toy_toa(p, j, emitter, toystring))^2 for (j, toa) in d])
end

function loss(p, ds, toystring::ToyString, emitters::Vector{Emitter})
    l = length(emitters)
    ps = Vector{Float64}[]

    for i in 1:l
        push!(ps, [p[i], p[l+1:end]...])
    end

    x = 0
    for (i, d) in enumerate(ds)
        x += loss(ps[i], d, toystring, emitters[i])
    end
    x
end

function Loss1(p, d, toystring)
    q = p[1:3]
    tripod = Tripod(1, Position(p[4], p[5], p[6]))
    Loss(q, d, toystring, tripod)
end
