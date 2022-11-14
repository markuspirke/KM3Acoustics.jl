"""
The speed of sound in the ocean varies with temperature, salinity and depth (pressure).
The KM3net detector operates at a depth of around 2000 - 3000m. At these depths
the temperature differences are negligible. The changes of the sound velocity due to salinity
are overall very small and will also be neglected here. With these assumption the speed of sound
varies linearly with changes in depth.
As a reference point we take the speed of sound at -2000.0m below the sea surface, which results
in a speed of 1541.0 m/s.
The velocity changes by 17 m/s per 1000m increase in depth.
"""

const dv_dz = -17.0e-3


struct SoundVelocity
    v₀
    z
    dv_dz

    SoundVelocity(v₀, z) = new(v₀, z, dv_dz)
end

ref_soundvelocity = SoundVelocity(1541.0, -2000.0)


"""
    function get_velocity(z::T; ref_soundvelocity=ref_soundvelocity, dv_dz=dv_dz)

For a given depth z, returns the speed of sound at that depth.
"""
function velocity(z::T; ref=ref_soundvelocity) where {T<:Real}

    v = (z - ref.z)*ref.dv_dz + ref.v₀

    SoundVelocity(v,z)
end

function velocity(z::T, z_reference; ref=ref_soundvelocity) where {T<:Real}

    z += z_reference
    v = (z - ref.z)*ref.dv_dz + ref.v₀

    SoundVelocity(v,z)
end
"""
    function get_velocity(T::DetectorModule; ref_soundvelocity=ref_soundvelocity, dv_dz=dv_dz)

For a given module or tripod returns the speed of sound at the depth of the module or tripod.
"""
function velocity(T; ref=ref_soundvelocity)
    velocity(T.pos.z)
end
function velocity(T, z_reference; ref=ref_soundvelocity)
    velocity(T.pos.z, z_reference)
end
"""
    function traveltime(A, B)

For a given module, tripod, emitter or receiver returns the time it takes for the signals to travel from the
tripod to the module.
"""
function traveltime(A, B)
    v_A = velocity(A) #sound velocity at height of tripod
    v_B = velocity(B) #sound veloctity at height of module

    R = norm(A.pos - B.pos) #distance between tripod and module
    dz = A.pos.z - B.pos.z #difference in height

    if dz ≈ 0.0
        abs(R/v_A.v₀)
    else
        abs(R/(dz * v_A.dv_dz) * log(abs(v_A.v₀/v_B.v₀))) #result of integration
    end
end

"""
    traveltime(A, B, z_reference::Float64)

For a given module, tripod, emitter or receiver returns the time it takes for the signals to travel from the
tripod to the module. The z positions are referenced to z_reference.
"""
function traveltime(A, B, z_reference)
    v_A = velocity(A, z_reference) #sound velocity at height of tripod
    v_B = velocity(B, z_reference) #sound veloctity at height of module

    R = norm(A.pos - B.pos) #distance between tripod and module
    dz = A.pos.z - B.pos.z #difference in height

    if dz ≈ 0.0
        abs(R/v_A.v₀)
    else
        abs(R/(dz * v_A.dv_dz) * log(abs(v_A.v₀/v_B.v₀)))#result of integration
    end
end
"""
    traveltime(R::Float64, z1::Float64, z2::Float64)

For a given distance between to points and their heights, returns the time for an acoustic signal
to travel between the points.
"""
function traveltime(R::T, z1::T, z2::T) where {T<:Real}
    v_1 = velocity(z1) #sound velocity at height of tripod
    v_2 = velocity(z2) #sound veloctity at height of module

    dz = z1 - z2 #difference in height

    if dz ≈ 0.0
        abs(R/v_1.v₀)
    else
        abs(R/(dz * v_1.dv_dz) * log(abs(v_1.v₀/v_2.v₀))) #result of integration
    end
end

"""
    traveltime(R::Float64, z1::Float64, z2::Float64, z_reference::Float64)

For a given distance between to points and their heights, returns the time for an acoustic signal
to travel between the points. Heights are referenced to z_reference.
"""
function traveltime(R, z1, z2, z_reference)

    v_1 = velocity(z1, z_reference) #sound velocity at height of tripod
    v_2 = velocity(z2, z_reference) #sound veloctity at height of module

    dz = z1 - z2 #difference in height

    if dz ≈ 0.0
        abs(R/v_1.v₀)
    else
        abs(R/(dz * v_1.dv_dz) * log(abs(v_1.v₀/v_2.v₀))) #result of integration
    end
end
"""
    function traveltime(x::Position, y::Position)

Given to Positions, returns the time for an acoustic signal to travel between positions.
"""
function traveltime(x::Position, y::Position)

    v_1 = velocity(x.z) #sound velocity at height of tripod
    v_2 = velocity(y.z) #sound veloctity at height of module

    R = norm(x - y) #distance between tripod and module
    dz = x.z - y.z #difference in height

    if dz ≈ 0.0
        abs(R/v_1.v₀)
    else
        abs(R/(dz * v_1.dv_dz) * log(abs(v_1.v₀/v_2.v₀))) #result of integration
    end
end

"""
    function traveltime(x::Position, y::Position, z_reference::Float64)

Given to Positions, returns the time for an acoustic signal to travel between positions.
Heights are referenced to z_reference.
"""
function traveltime(x::Position{T}, y::Position{T}, z_reference) where {T<:Real}

    v_1 = velocity(x.z, z_reference) #sound velocity at height of tripod
    v_2 = velocity(y.z, z_reference) #sound veloctity at height of module

    R = norm(x - y) #distance between tripod and module
    dz = x.z - y.z #difference in height

    if dz ≈ 0.0
        abs(R/v_1.v₀)
    else
        abs(R/(dz * v_1.dv_dz) * log(abs(v_1.v₀/v_2.v₀))) #result of integration
    end
end
