function Statistics.mean(event::Event, field::Symbol)
    mean([getfield(transmission, field) for transmission in event.data])
end

function Statistics.std(event::Event, field::Symbol)
    std([getfield(transmission, field) for transmission in event.data])
end
