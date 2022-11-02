struct ToyString
    id::Int32
    pos::Position #position of the tbar at the seabed
    θ::Float64 # polar angle
    ϕ::Float64 # azimuthal angle
    lengths::Vector{Float64} # height of floors or length of the string measured from base
end

struct ToyModule
    location::Location
    pos::Position
end

struct RealString
    id::Int32
    pos::Position
    dx::Float64
    dy::Float64
    lengths::Vector{Float64}
end

struct ToyDetector
    strings::Dict{Int32, ToyString}
end

struct RealDetector
    strings::Dict{Int32, RealString}
end
"""
    function toy_calc_pos(θ, ϕ, l)

Given the length of the string up to the module, returns the position of the module,
relative to the basemodule
"""
function toy_calc_pos(θ, ϕ, l)
    Position(l*sin(θ)*cos(ϕ), l*sin(θ)*sin(ϕ), l*cos(θ))
end
"""
    function toy_calc_toa(θ, ϕ, l, basepos, emitterpos)

Given the length of the string up to the module, the angles of the strings,
returns the traveltime between the given module and the emitter.
"""
function toy_calc_traveltime(θ, ϕ, l, basepos, emitterpos)

    modpos = toy_calc_pos(θ, ϕ, l) + basepos
    R = norm(modpos - emitterpos)
    traveltime(R, modpos.z, emitterpos.z, -2440.0)
end

"""
    function string_length(dx, dy, z, a, b)

Given the height of a module located in some string, calculates the length of the string
from the basemodule to the module.
"""
function string_length(dx, dy, z, a, b)
    sqrt(1 + (dx^2 + dy^2)) * z + 0.5*(dx^2 + dy^2) * b*log(1 - a*z)
end
"""
    function string_inverselength(dx, dy, l, a, b)

Given the length of the string up to the module, returns the height of the module.
"""

function string_inverselength(dx, dy, l, a, b; n_iter=20, ϵ=1e-6)
    z = l
    d2 = 0.5*(dx^2 + dy^2)
    for i in 1:n_iter
        l_new = string_length(dx, dy, z, a, b)
        if abs(l - l_new) < ϵ
            break
        end
        z -= (l_new - l) / (1.0 + d2*(1.0 - a*b/(1.0 - a*z)))
    end
    z
end

"""
    function calc_traveltime(dx, dy, l, a, b, basepos, emitterpos)

Calculates the position of a module located an some string at length l measured from the
basemodule.
"""
function calc_pos(dx, dy, l, a, b)
    z = string_inverselength(dx, dy, l, a, b)
    x = dx * z
    y = dy * z

    Position(x, y, z)
end
"""
    function calc_traveltime(dx, dy, l, a, b, basepos, emitterpos)

Calculates the traveltime of a signal of an emitter to a module located at
the position length l at some string.
"""
function calc_traveltime(dx, dy, l, a, b, basepos, emitterpos)

    modpos = calc_pos(dx, dy, l, a, b) + basepos
    R = norm(modpos - emitterpos)
    traveltime(R, modpos.z, emitterpos.z, -2440.0)
    # traveltime(modpos, emitterpos, -2440.0, SoundVelocity(1541.0, -2000.0))
end
