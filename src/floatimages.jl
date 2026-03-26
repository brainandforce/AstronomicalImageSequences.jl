"""
    convert_image_eltype(::Type{T}, image::AbstractMatrix{S}) -> AbstractMatrix{T}

Converts the pixel data of an image from `S` to `T`.

When converting integer image data to floating point values, 
"""
convert_image_eltype(::Type{T}, image::AbstractMatrix{T}) = image

function convert_image_eltype(::Type{T}, image::AbstractMatrix{S}) where {S<:Integer,T<:Integer}
    if sizeof(S) > sizeof(T)
    elseif sizeof(S) < sizeof(T)
    else    # this is converting signed to unsigned
    end
end

function convert_image_eltype(
    ::Type{T},
    image::AbstractMatrix{S}
) where {S<:AbstractFloat,T<:AbstractFloat}
    return convert.(T, image)
end

function convert_image_eltype(
    ::Type{T},
    image::AbstractMatrix{S}
) where {S<:Integer,T<:AbstractFloat}
    denom = T(typemax(S)) + one(T)
    return image ./ denom
end
