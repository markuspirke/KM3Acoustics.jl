function Statistics.mean(event::Event)
    mean([transmission.TOE for transmission in event.data])
end

function Statistics.std(event::Event)
    std([transmission.TOE for transmission in event.data])
end
