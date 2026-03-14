module AstronomicalImageSequences

using Dates

import Base: @propagate_inbounds

include("bayer.jl")
export ColorFilterArray, BayerCFA, CFAImage
include("calibration.jl")
export AbstractCalibrationFrames, CalibrationFrames
export calibrate
include("sequences.jl")
export AbstractImageSequence, StackableSequence, SessionSequence, ProjectSequence

end
