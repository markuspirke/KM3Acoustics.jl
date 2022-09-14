
const f_s = 195312.5 #sampling frequency


#DAQ_ADF_ANALYSIS_WINDOW_SIZE = 131072
#DAQ_ADF_ANALYSIS_WINDOW_OVERLAP = 7812
#frame_length = DAQ_ADF_ANALYSIS_WINDOW_SIZE - DAQ_ADF_ANALYSIS_WINDOW_OVERLAP #check whether this can be hard coded from the beginning or whether these values change
frame_length = 123260
l = frame_length + 3 #number of 4 Bytes in the whole file
"""
ASignal is a custom type with four fields to store all the information inside the raw acoustic binary files.
- utc_seconds:: UInt32 storing the first 4 Bytes and is a UNIX time stamp
- ns_cycles:: UInt32 storing the second 4 Bytes
- samples:: UInt32 storing the third 4 Bytes, corresponding to the number of data points accuired during the measring window
- pcm:: Vector of Float32 of length frame_length, storing all other 4 Byte blocks. Each entry is a data point of the acoustic signal.
"""
struct ASignal
    #dom_id::String add if necessary
    utc_seconds::UInt32 # UNIX timestamp
    ns_cycles::UInt32 # number of 16ns cycles
    samples::UInt32 #  as 'samples' corresponds to the frame_length which is apprantely a fixed number 123260 so maybe this isnt necessary
    pcm::Vector{Float32}
end
"""
The function read_asignal provides a tool to read in raw acoustic binary files which where recorded by an acoustic detection unit build into the DOMs.
The function takes two arguments as an input. The first argument is the filename of the binary file and the second argument is the number of 4 Byte snippets in the binary.
The whole information from the binary file is return inside our custom type ASignal.
"""
function read_asignal(filename::AbstractString,fourbyte_length::Int)

    container = Vector{UInt32}(undef,3)
    read!(filename,container)
    utc_seconds = container[1]
    ns_cycles = container[2]
    samples = container[3]

    container = Vector{Float32}(undef,fourbyte_length) #now read as floats to get the pcm data
    read!(filename,container)
    pcm = container[4:end] #pcm data starts at entry 4

    return ASignal(utc_seconds, ns_cycles, samples, pcm) #plug everthing into our data type
end

function plot_asignal(signal::ASignal, f_s=f_s, l=frame_length) #this should be done as a recipe, but now just for convience
    T_s = 1/f_s * l
    ts = range(0,T_s,length=l)

    p = plot(ts,signal.pcm)
    xlabel!("time in s")
    ylabel!("amplitude")

    return p
end
"""
The function to_wav takes our custom type ASignal as a first argument and procudes .wav file. The second argument is the path where the .wav file gets stored.
The third argument is the sampling frequency at which the signal was recorded and with the last argument it is possible to amplify the signal.
"""
function to_wav(signal::ASignal, path::AbstractString, f_s=f_s, gain_db=0.0)
    pcm = signal.pcm

    if gain_db != 0.0
        pcm *= 10.0^(0.1 * gain_db)
    end

    wavwrite(pcm, path, Fs=floor(Int,f_s))
end
