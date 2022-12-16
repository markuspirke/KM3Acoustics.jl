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

"""
    function natural(x, y)

For sorting arrays of strings, including numbers in the strings.
Usage: x = ["Foo101", "Foo13"] -> sort(x, lt=natural) -> ["Foo13", "Foo101"]
"""
function natural(x, y)
    k(x) = [occursin(r"\d+", s) ? parse(Int, s) : s
            for s in split(replace(x, r"\d+" => s -> " $s "))]
    A = k(x)
    B = k(y)
    for (a, b) in zip(A, B)
        if !isequal(a, b)
            return typeof(a) <: typeof(b) ? isless(a, b) :
                   isa(a, Int) ? true : false
        end
    end
    return length(A) < length(B)
end
"""
    function parse_runs(r)

Helper function to parse runs in eventbuilder script.
"""
function parse_runs(r)
    if tryparse(Int, r) !== nothing
        return parse(Int, r)
    elseif occursin(":", r)
        rmin, rmax = parse.(Int, split(r, ":"))
        return rmin:rmax
    elseif occursin(",", r)
        rs = parse.(Int, split(r, ","))
    end
end
