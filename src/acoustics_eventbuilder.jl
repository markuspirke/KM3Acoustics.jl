"""
Takes a toashort .csv file and filters out rows where all entries are equal except UNIXTIMEBASE and TOA_S,
but their sum is.
"""
function remove_idevents(filename::AbstractString)
    df = CSV.read(filename,DataFrame; delim=",", types=[Int32, Int32, Float64, Int32, Int8, Float64, Int32])

    transform!(df, AsTable([:UNIXTIMEBASE, :TOA_S]) => sum => :UTC_TOA)
    select!(df, Not([:RUNNUMBER, :UNIXTIMEBASE, :TOA_S]))
    df = unique(df)

    sort!(df, [:DOMID, :UTC_TOA])
#    gdf = groupby(df, :EMITTERID)
    df
#    gdf
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



# gdf[(emitterid = 28,)] to index
