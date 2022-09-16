"""
    nthbitset(n, a) = !Bool((a >> (n - 1)) & 1)

Return `true` if the n-th bit of `a` is set, `false` otherwise.
"""
nthbitset(n, a) = Bool((a >> n) & 1)


"""
    function piezoenabled(m::Module)

Return `true` if the piezo is enabled, `false` otherwise.
"""
function piezoenabled(m::Module)
    !nthbitset(MODULE_STATUS.PIEZO_DISABLE, m.status)
end


"""
    function hydrophonenabled(m::Module)

Return `true` if the hydrophone is enabled, `false` otherwise.
"""
function hydrophoneenabled(m::Module)
    !nthbitset(MODULE_STATUS.HYDROPHONE_DISABLE, m.status)
end
