"""
    function read_toashort(filename::AbstractString)

Takes a toashort .csv file and adds UNIXTIMEBASE and TOA_S and removes unnecessary columns.
"""
function read_toashort(filename::AbstractString)
    df = CSV.read(filename,DataFrame; delim=",", types=[Int32, Int32, Float64, Int32, Int8, Float64, Int32])

    transform!(df, AsTable([:UNIXTIMEBASE, :TOA_S]) => sum => :UTC_TOA)
    select!(df, Not([:RUNNUMBER, :UNIXTIMEBASE, :TOA_S]))

    df
end
"""
Receivers are either DOMs with an piezo element or a baseunit with a hydrophone.
"""
struct Receiver
    id::Int32
    pos::Position
end
"""
The tripods in the seabed are Emitters of acoustics signals.
"""
struct Emitter
    id::Int8
    pos::Position
end
"""
Datatype which has all information of one Transmission which is later needed for the fitting procedure.
"""
struct Transmission
    run::Int32
    id::Int32
    Q::Float64
    TOA::Float64
    TOE::Float64
end
"""
    function isless(A::Transmission, B::Transmission)

Compares two transmissions. Necessary for sorting transmissions in the right way: Sort first by earliest TOA
and if TOAs are equal sort first by higher Quality factor Q.
"""
function isless(A::Transmission, B::Transmission)
    if A.TOA == B.TOA
        return !isless(A.Q, B.Q)
    else
        return isless(A.TOA, B.TOA)
    end
end

