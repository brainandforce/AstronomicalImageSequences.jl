#---Calibration frames-----------------------------------------------------------------------------#
"""
    AbstractCalibrationFrames{M<:AbstractMatrix} <: AbstractDict{Symbol,M}

Supertype for sets of calibration frames of type `M`, all of equal size.

Calibration frames can be either pre-loaded into memory or lazily constructed through file
references or generated data.
If the 
"""
abstract type AbstractCalibrationFrames{M} <: AbstractDict{Symbol,M}
end

Base.length(::AbstractCalibrationFrames) = 3

"""
    CalibrationFrames{M,B,D,F}

References a set of stacked or generated bias, dark, and flat frame data, all convertible to type
`M`.

The references may include `missing` or `nothing`, and indexing returns a null frame which
does not affect stacking: either an array of zeros or ones depending on whether the frame is
additive (biases and darks) or multiplicative (flats).
"""
struct CalibrationFrames{M,B,D,F} <: AbstractCalibrationFrames{M}
    framesize::NTuple{2,Int}
    bias::B
    dark::D
    flat::F
end

function _generate_frame(cf::CalibrationFrames{M}, i::Symbol) where M<:AbstractMatrix
    i in (:bias, :dark) && return _generate_frame(+, M, getproperty(cf, i), cf.framesize)
    i in (:flat)        && return _generate_frame(*, M, getproperty(cf, i), cf.framesize)
    throw(KeyError(i))
end

function _generate_frame(
    ::Union{typeof(+),typeof(*)},
    ::Type{M},
    data::AbstractMatrix,
    sz::NTuple{2,Int}
) where M
    return convert(M, data)
end

function _generate_frame(
    ::Union{typeof(+),typeof(*)},
    ::Type{M},
    data,
    sz::NTuple{2,Int} = size(M) # this can only be omitted for StaticMatrix!
) where M
    return convert(M, fill(data, sz))
end

function _generate_frame(
    ::typeof(+),
    ::Type{M},
    ::Union{Nothing,Missing},
    sz::NTuple{2,Int} = size(M) # this can only be omitted for StaticMatrix!
) where M
    return _generate_frame(+, M, zero(eltype(M)), sz)
end

function _generate_frame(
    ::typeof(*),
    ::Type{M},
    ::Union{Nothing,Missing},
    sz::NTuple{2,Int} = size(M) # this can only be omitted for StaticMatrix!
) where M
    return _generate_frame(*, M, one(eltype(M)), sz)
end

Base.getindex(cf::CalibrationFrames, i::Symbol) = _generate_frame(cf, i)

"""
    calibrate(image::AbstractMatrix, cf::AbstractCalibrationFrames)

Calibrates the image with a given set of calibration frame data.
"""
function calibrate(image::AbstractMatrix, cf::AbstractCalibrationFrames{M}) where M
    T = promote(eltype(image), eltype(M))
    result = similar(image, T)
    result .= (image - cf[:bias] - cf[:dark]) / cf[:flat]
    return result
end