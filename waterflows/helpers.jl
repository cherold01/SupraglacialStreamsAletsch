"""
    Make boxes which act as sinks at the moulin locations.
"""
function make_boxes(dem::Raster, window)
    moulins = [[2646056.535,1150304.399],
               [2645712.940,1149876.606],
               [2645741.764,1149954.499],
               [2645801.772,1150039.150] ]
    xs, ys = lookup(dem, X), lookup(dem, Y)
    boxes = []
    for m in moulins
        ix = X((m[1]-window)..(m[1]+window))
        iy = Y((m[2]-window)..(m[2]+window))
        push!(boxes, Raster(CartesianIndices(dem), dims=dims(dem))[ix,iy].data)
    end
    return boxes
end

function crop_dem_nan(dem)
    #crop DEM to exclude areas with only NaN
    # Find all indices that are not NaN
    indices = findall(!isnan, dem)
    # Extract x and y coordinates
    x_coords = [I[1] for I in indices]
    y_coords = [I[2] for I in indices]
    # Find the first and last x and y values
    first_x = minimum(x_coords)
    last_x = maximum(x_coords)
    first_y = minimum(y_coords)
    last_y = maximum(y_coords)
    return dem[first_x:last_x, first_y:last_y]
end


# A boxcar, aka running average, filter.  From GlacioTools

"""
    boxcar(A::AbstractArray, window::AbstractArray, weights)

Moving average filter with spatially dependent filter window and weighting of cells.
Filters over ±window.
"""
function boxcar(A::AbstractArray{T,N}, window::AbstractArray{<:Integer,N},
                weights::AbstractArray{<:Number,N}=ones(size(A)...)) where {T,N}
    out = similar(A)
    R = CartesianIndices(size(A))
    I1, Iend = first(R), last(R)
    Threads.@threads for I in R # @inbounds does not help
        out[I] = NaN
        n, s = 0, zero(eltype(out))
        I_ul = CartesianIndex(I1.I.*window[I])
        for J in CartesianIndices(UnitRange.(max(I1, I-I_ul).I , min(Iend, I+I_ul).I) )
            # used to be CartesianRange(max(I1, I-I_l), min(Iend, I+I_u) )
            # now it is probably something simpler than what I use above
            AJ, w = A[J], weights[J]
            if !isnan(AJ) && w!=0
                s += A[J]
                n += 1
            end
        end
        if n==0
            out[I] = A[I]
        else
            out[I] = s/n # note: ==NaN if n==s==0
        end
    end
    out
end

"""
    maxcar(A::AbstractArray, window::AbstractArray)

Moving max filter with spatially dependent filter window and weighting of cells.
Filters over ±window.
"""
function maxcar(A::AbstractArray{T,N}, window::AbstractArray{<:Integer,N}) where {T,N}
    out = similar(A)
    R = CartesianIndices(size(A))
    I1, Iend = first(R), last(R)
    Threads.@threads for I in R # @inbounds does not help
        out[I] = typemin(T)
        I_ul = CartesianIndex(I1.I.*window[I])
        for J in CartesianIndices(UnitRange.(max(I1, I-I_ul).I , min(Iend, I+I_ul).I) )
            # used to be CartesianRange(max(I1, I-I_l), min(Iend, I+I_u) )
            # now it is probably something simpler than what I use above
            if !isnan(A[J])
                out[I] = max(A[J], out[I])
            end
        end
    end
    out
end
