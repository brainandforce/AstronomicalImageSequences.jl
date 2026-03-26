#---Calibration frames-----------------------------------------------------------------------------#
"""
    AbstractCalibrationFrames{M<:AbstractMatrix} <: AbstractDict{Symbol,M}

Supertype for sets of calibration frames of type `M`, all of equal dimensions.
This includes a bias frame, dark frame, and flat frame.
`AbstractCalibrationFrames` can be indexed by the symbols `:bias`, `:dark`, and `:flat`, returning
an array of type `M`.

Calibration frames can be either pre-loaded into memory or lazily constructed through file
references (often as `AbstractString` instances) or generated data (such as an offset level).
"""
abstract type AbstractCalibrationFrames{M} <: AbstractDict{Symbol,M}
end

Base.length(::AbstractCalibrationFrames) = 3

Base.keys(::AbstractCalibrationFrames) = (:bias, :dark, :flat)
Base.values(cf::AbstractCalibrationFrames) = (cf[:bias], cf[:dark], cf[:flat])

function Base.iterate(cf::AbstractCalibrationFrames, state = :bias)
    state === :bias && return (:bias => cf[:bias], :dark)
    state === :dark && return (:dark => cf[:dark], :flat)
    state === :flat && return (:flat => cf[:flat], :done)
    return nothing
end

"""
    CalibrationFrames{M,B,D,F}

References a set of stacked or generated bias, dark, and flat frame data, all convertible to type
`M`.

The references may include `missing` or `nothing`, and indexing returns a null frame which
does not affect stacking: either an array of zeros or ones depending on whether the frame is
additive (biases and darks) or multiplicative (flats).
"""
struct CalibrationFrames{M,B,D,F} <: AbstractCalibrationFrames{M}
    framesize::NTuple{2,Int}    # The common size of all images
    bias::B
    dark::D
    flat::F
end

function CalibrationFrames{M}(bias::B, dark::D, flat::F) where {M,B,D,F}
    # Ensure that the dimensionalities are identical (for anything that's an array)
    sized_args = filter(x -> !isa(x, Union{Nothing,Missing,Real}), (bias, dark, flat))
    sizes = size.(sized_args)
    allequal(sizes) || throw(DimensionMismatch("input images have mismatched dimensions"))
    return CalibrationFrames{M,B,D,F}(first(sizes), bias, dark, flat)
end

function _generate_frame(cf::CalibrationFrames{M}, i::Symbol) where M
    i in tuple(:bias, :dark) && return _generate_frame(+, M, getproperty(cf, i), cf.framesize)
    i in tuple(:flat)        && return _generate_frame(*, M, getproperty(cf, i), cf.framesize)
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