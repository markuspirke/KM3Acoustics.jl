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
    v₀::Float64
    z::Float64
end

const ref_soundvelocity = SoundVelocity(1541.0, -2000.0)


"""
    function get_velocity(z::Float64, ref::SoundVelocity=ref_soundvelocity, dv_dz=dv_dz)

For a given depth z, returns the speed of sound at that depth.
"""
function get_velocity(z::Float64, ref::SoundVelocity=ref_soundvelocity, dv_dz=dv_dz)

    v = (z - ref.z)*dv_dz + ref.v₀

    SoundVelocity(v,z)
end

"""
    function get_velocity(T::Tripod, ref::SoundVelocity=ref_soundvelocity, dv_dz=dv_dz)

For a given tripod, returns the speed of sound at the depth of the tripod.
"""
function get_velocity(T::Tripod, ref::SoundVelocity=ref_soundvelocity, dv_dz=dv_dz)

    get_velocity(T.pos.z)
end
"""
    function get_velocity(T::DetectorModule, ref::SoundVelocity=ref_soundvelocity, dv_dz=dv_dz)

For a given module, returns the speed of sound at the depth of the module.
"""
function get_velocity(T::DetectorModule, ref::SoundVelocity=ref_soundvelocity, dv_dz=dv_dz)

    get_velocity(T.pos.z)
end
"""
    function get_time(D::DetectorModule, T::Tripod, dv_dz=dv_dz)

For a given module and tripod, returns the time it takes for the signals to travel from the
tripod to the module.
"""
function get_time(D::DetectorModule, T::Tripod, dv_dz=dv_dz)
    v_D = get_velocity(D) #sound velocity at height of tripod
    v_T = get_velocity(T) #sound veloctity at height of module

    R = norm(D.pos - T.pos) #distance between tripod and module
    dz = norm(D.pos.z - T.pos.z) #difference in height

    R/(dz * dv_dz) * log(v_D/v_T) #result of integration
end
