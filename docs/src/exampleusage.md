## Example usage
For a complete detector calibration you need several input files, which you should put all in one directory. Here we will call this directory **workingdir**. The first file you need is a **.detx** file. This file stores the geometry of the detector. Then you need a **tripod.txt** file. This stores the ids and positions of the tripods, which are placed on the seabed. The ids in this tripod.txt however, are not the ids used in the acoustic data files coming from the database. To map the ids from the data base we need the **waveform.txt** file. Then a hyrophone is mounted on each basemodule. Here you need a **hydrophone.txt** file, which stores the positions of the hydrophones relative to the basemodule. Then there are a few more file which should be included in the workingdir. **acoustics_fit_parameters.txt**, **acoustics_trigger_parameters.txt** are need for the eventbuilding and calibration procedure. 
## Command Line Tools
In the Github repository there are several scripts which you can use. It is easiest if one just clones the whole GitHub repository with

> git clone https://github.com/mpirke/KM3Acoustics.jl.git

From here you just go into the directory (KM3Acoustics) you just copied to your local computer. Then you can use
```shell
    julia --project=. scripts/<script.jl> ...
```
to run the different scripts.

### Simulation.jl
Each script needs a different set of command line arguments. Lets take a look at the following
```julia
    doc = """Simulation of acoustic events.
    Usage:
    simulation.jl [options]  -i INPUT_FILES_DIR -D DETX -r RUN
    simulation.jl -h | --help
    simulation.jl --version
    Options:
    -D DETX             The detector description file.
    -i INPUT_FILES_DIR  Directory containing tripod.txt, hydrophone.txt, waveform.txt
    -r RUN              Run number for this simulation.
    -h --help           Show this screen.
    --version           Show version.
    """
```
There are 3 **mandatory** arguments:
1. -i INPUT_FILES_DIR: should be the path to the working directory as mentioned in the earlier section.
2. -D DETX: The .detx file with the detector geometry.
3. -r RUN: This will be the run ID for the simulation data.

If you are in the KM3Acoustics directory where the workingdir in included you can use the simulation script with
```shell
    julia --project=. scripts/simulation.jl -i workingdir -D workingdir/detector.detx -r 123
```
This will simulate acoustic events.
