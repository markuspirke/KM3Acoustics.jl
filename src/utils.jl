"""
    function piezoenabled(m::DetectorModule)

Return `true` if the piezo is enabled, `false` otherwise.
"""
piezoenabled(m::DetectorModule) = !nthbitset(MODULE_STATUS.PIEZO_DISABLE, m.status)


"""
    function hydrophonenabled(m::DetectorModule)

Return `true` if the hydrophone is enabled, `false` otherwise.
"""
hydrophoneenabled(m::DetectorModule) = !nthbitset(MODULE_STATUS.HYDROPHONE_DISABLE, m.status)

function write_compound(f, name, data::AbstractArray{T}) where T
     dtype = HDF5.API.h5t_create(HDF5.API.H5T_COMPOUND, sizeof(T))
     for (idx, fn) ∈ enumerate(fieldnames(T))
         HDF5.API.h5t_insert(
             dtype,
             fn,
             fieldoffset(T, idx),
             datatype(fieldtype(T, idx))
         )
     end
     dt = HDF5.Datatype(dtype)
     dset = create_dataset(f, name, dt, dataspace(data))
     write_dataset(dset, dt, data)
 end
