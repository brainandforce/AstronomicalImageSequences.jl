"""
    AbstractImageSequence{M<:AbstractMatrix,F} <: AbstractVector{M}

Supertype for all image sequences.

Images are referenced by data of some type `I`; often this will be a type that can store a file
path, but it could also be the image data itself.
They are dereferenced with a function of type `F`.
Indexing an `AbstractImageSequence{M}` returns image data of type `M` by calling the dereferencing
function upon the references.

When implementing a custom type, it is easiest to implement a dereferencing function with field
`f::F` and references to image data with field `refs::AbstractVector{I}`.
"""
abstract type AbstractImageSequence{M<:AbstractMatrix,F} <: AbstractVector{M}
end

Base.size(seq::AbstractImageSequence) = size(seq.refs)
Base.IndexStyle(::Type{<:AbstractImageSequence}) = IndexLinear

@propagate_inbounds function Base.getindex(seq::AbstractImageSequence{M}, i::Int) where M
    return convert(M, seq.f(seq.refs[i]))
end

"""
    StackableSequence{M<:AbstractMatrix,F,I} <: AbstractImageSequence{M,F,I}

Lazily references a sequence of images taken with a common configuration.
Images referenced by this sequence should be able to be stacked together, which includes all
calibration (with biases, darks, and flats) and registration steps.
"""
struct StackableSequence{M<:AbstractMatrix,F,I} <: AbstractImageSequence{M,F}
    f::F
    refs::Vector{I}
end

"""
    StackableSequence{M}(f, refs::AbstractVector, [filter::Union{Symbol,AbstractString}])

Construct a `StackableSequence` from a function `f` that can be applied to a list of references
`refs` to obtain image data of type `M`.

In general, `Matrix{T}` is a safe bet for monochrome images, with `T` often being `Int16` or
`UInt16` for raw images produced directly from cameras, and `Float32` after other processing steps
have been performed.
For raw color images (not debayered), `ColorFilterMatrix{T,Matrix{T},C}` associates `Matrix{T}`
with a color filter array of type `C`.
For multi-channel images, such as debayered images, we recommend using types provided by
[ColorTypes.jl](https://github.com/JuliaGraphics/ColorTypes.jl), such as `RGB{N0f16}` or 
`RGB{Float32}`.
"""
function StackableSequence{M}(f, refs::AbstractVector) where M
    return StackableSequence{M,typeof(f),eltype(refs)}(f, refs)
end

function StackableSequence(images::AbstractVector{M}) where M<:AbstractMatrix
    return StackableSequence{M}(identity, images)
end

#---Compositions of sequences taken with differing but related settings----------------------------#
"""
    SessionSequence{S<:AbstractImageSequence} <: AbstractVector{S}

Lazily references multiple sequences of images taken on a single night with the same equipment.
This type also stores the start date of the session.
"""
struct SessionSequence{S<:AbstractImageSequence} <: AbstractVector{S}
    data::Vector{S}
    start::Date
end

Base.size(seq::SessionSequence) = size(seq.data)
Base.IndexStyle(::Type{<:SessionSequence}) = IndexLinear()
@propagate_inbounds Base.getindex(seq::SessionSequence, i::Int) = getindex(seq.data, i)

"""
    ProjectSequence{S<:SessionSequence} <: AbstractVector{S}

Lazily references a series of imaging sessions taken over multiple runs.
"""
struct ProjectSequence{S<:SessionSequence} <: AbstractVector{S}
    data::Vector{S}
end

Base.size(seq::ProjectSequence) = size(seq.data)
Base.IndexStyle(::Type{<:ProjectSequence}) = IndexLinear()
@propagate_inbounds Base.getindex(seq::ProjectSequence, i::Int) = getindex(seq.data, i)

"""
    MosaicSequence{S<:ProjectSequence} <: AbstractMatrix{Union{S,Missing}}

A matrix of `ProjectSequence` instances, with the indices corresponding to the position of each
frame's contribution the final image.
If a frame is not present in the final output, `missing` may be substituted.
"""
struct MosaicSequence{S<:ProjectSequence} <: AbstractMatrix{Union{S,Missing}}
    projects::Matrix{Union{S,Missing}}
end