"""
Takes a toashort .csv file and filters out rows where all entries are equal except UNIXTIMEBASE and TOA_S,
but their sum is.
"""
function remove_idevents(filename::AbstractString)
    df = CSV.read(filename,DataFrame)

    transform!(df, [:UNIXTIMEBASE, :TOA_S] => +)
    select!(df, Not([:UNIXTIMEBASE,:TOA_S]))

    mask = nonunique(df)
    mask = mask .== 0

    return df[findall(mask), :]
end
