"""
Takes a toashort .csv file and filters out rows where all entries are equal except UNIXTIMEBASE and TOA_S,
but their sum is.
"""
function remove_idevents(filename::AbstractString)
    df = CSV.read(filename,DataFrame)

    transform!(df, AsTable([:UNIXTIMEBASE, :TOA_S]) => sum => :UTC_TOA)
    select!(df, Not([:UNIXTIMEBASE,:TOA_S]))

    return unique(df)
end
