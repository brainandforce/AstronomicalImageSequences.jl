"""
    AstronomicalImageSequences.ColorFilterArray{D} <: AbstractMatrix{UInt8}

Supertype for different kinds of color filter arrays of linear size `D`.
The channels are enumerated by `UInt8` data, with `0x1`, `0x2`, and `0x3` corresponding to red,
green, and blue channels.
In principle, custom types can use all possible `UInt8` values to refer to up to 128 different
channels per sensor.
"""
abstract type ColorFilterArray{D} <: AbstractMatrix{UInt8}
end

Base.size(::ColorFilterArray{D}) where D = tuple(D,D)
Base.IndexStyle(::Type{<:ColorFilterArray}) = IndexLinear()

function Base.getindex(cfa::ColorFilterArray{D}, i1::Int, i2::Int) where D
    return @inbounds getindex(cfa, LinearIndices(cfa)[mod1(i1, D), mod1(i2, D)])
end

"""
    _channel_to_uint8(c::Char)
    _channel_to_uint8(s::AbstractString)

Converts a character to a `UInt8` representing the relevant color channel:
  * `'R'` and `'r'` become `0x1`.
  * `'G'` and `'g'` become `0x2`.
  * `'B'` and `'b'` become `0x3`.
  * Other inputs become `0x0`.

For a string argument, the first character is used to make this determination.
"""
function _channel_to_uint8(c::Char)
    c in ('r', 'R') && return 0b01
    c in ('g', 'G') && return 0b10
    c in ('b', 'B') && return 0b11
    return 0b00
end

_channel_to_uint8(s::AbstractString) = _channel_to_uint8(first(s))

#---Bayer color filter arrays----------------------------------------------------------------------#
"""
    AstronomicalImageSequences.BayerCFA <: AstronomicalImageSequences.ColorFilterArray{2}

Represents a Bayer or Bayer-like color filter array in a particular orientation.

The traditional Bayer matrix consists of diagonals of green pixels combined with diagonals of
alternating red and blue pixels. This type supports all other possible arrangements of color 
filters in a 2×2 block of pixels.
"""
struct BayerCFA <: ColorFilterArray{2}
    data::UInt8
end

function BayerCFA(spec::AbstractString)
    data  = _channel_to_uint8(spec[1]) << 0x0
    data += _channel_to_uint8(spec[2]) << 0x4
    data += _channel_to_uint8(spec[3]) << 0x2
    data += _channel_to_uint8(spec[4]) << 0x6
    return BayerCFA(data)
end

BayerCFA(spec::Symbol) = BayerCFA(String(spec))

function Base.getindex(cfa::BayerCFA, i::Int)
    @boundscheck checkbounds(cfa, i)
    shift = UInt8(2 * ((i - 1) % length(cfa)))
    mask = 0b11 << shift
    return (cfa.data & mask) >> shift
end

Base.String(cfa::BayerCFA) = join(('X', 'R', 'G', 'B')[n+1] for n in cfa[[1,3,2,4]])
Base.show(io::IO, cfa::BayerCFA) = print(io, typeof(cfa), "(\"", String(cfa), "\")") 
Base.summary(io::IO, cfa::BayerCFA) = print(io, "Bayer color filter array (", String(cfa), ")")

#---Fujifilm X-trans matrix------------------------------------------------------------------------#

#= TODO: implement this matrix
"""
    AstronomicalImageSequences.XTransCFA <: AstronomicalImageSequences.ColorFilterArray{6}

Represents the special 6×6 X-Trans color filter array used by Fujifilm cameras.
"""
struct XTransCFA
end
=#

#---Matrix with associated color filter array------------------------------------------------------#
"""
    CFAImage{T,M<:AbstractMatrix{T},C<:ColorFilterArray} <: AbstractMatrix{T}

Represents image data of type `T` (often `Int16` or `Float32`) associated with color filter array.
The arrangement of the color filter array is given by a `ColorFilterArray` object.
`AstronomicalImageSequences.ColorFilterArray`, and operations on the array which may return a
subarray or a permutation of the array will update the layout of the `ColorFilterArray` object.
"""
struct CFAImage{T,M<:AbstractMatrix{T},C<:ColorFilterArray} <: AbstractMatrix{T}
    data::M
    cfa::C
end

Base.size(m::CFAImage) = size(m.data)
@propagate_inbounds Base.getindex(m::CFAImage, i::Int) = getindex(m.data, i)
@propagate_inbounds Base.setindex!(m::CFAImage, x, i::Int) = setindex!(m.data, x, i)

#---Special functions for when we reindex a CFAImage-----------------------------------------------#
