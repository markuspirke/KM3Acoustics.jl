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
