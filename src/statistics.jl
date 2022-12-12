"""
    function Statistics.mean(event::Event, field::Symbol)

Return the mean of a given field from the data included in the event. 
"""
function Statistics.mean(event::Event, field::Symbol)
    mean([getfield(transmission, field) for transmission in event.data])
end

"""
    function Statistics.std(event::Event, field::Symbol)

Return the std of a given field from the data included in the event. 
"""
function Statistics.std(event::Event, field::Symbol)
    std([getfield(transmission, field) for transmission in event.data])
end
