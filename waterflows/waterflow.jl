__precompile__(false)

using Rasters, WhereTheWaterFlows
using ArchGDAL

dem = Raster("100-1012_high_dem_2cm_lv95.tif")
#dem_crop = dem[5000:6000, 5000:6000]
#dem = dem[1:2:length(dem[:,1]), 1:2:length(dem[1, :])]

#plotyes = true
if !@isdefined plotyes
    plotyes = true
end
if plotyes
    @eval using GLMakie
end
using WhereTheWaterFlows
if !(@isdefined WWF)
    const WWF = WhereTheWaterFlows
end

"""
"An artificial DEM"
function ele(x, y; withpit=false, randfac=0.0)
    out = - (x^2 - 1)^2 - (x^2*y - x - 1)^2 + 6 + 0.1*x + 3*y
    if withpit
        out -= 2*exp(-(x^2 + y^2)*50)
    end
    out += randfac*randn()
    return out<0 ? 0.0 : out
end
dx = 0.01
xs = -1.5:dx:1
ys = -0.5:dx:3.0
dem = ele.(xs, ys', randfac=0.1, withpit=true);
"""



"""
"Cropping the DEM to max of may graphic card"
#max_texture_size = 16383 #max of my graphic card
max_texture_size = 10000

if length(dem[:,1]) >= max_texture_size
    print("xmax reduced from $(length(dem[:,1])) to $max_texture_size ")
    xmax = max_texture_size;
else
    xmax = length(dem[:,1])
end
if length(dem[1, :]) >= max_texture_size
    print("ymax reduced from $(length(dem[1, :])) to $max_texture_size ")
    ymax = max_texture_size;
else
    ymax = length(dem[1, :])
end

dem = dem[1:xmax, 1:ymax]
"""

xs = 1:length(dem[:,1])
ys = 1:length(dem[1, :])
plotyes && heatmap(xs, ys, dem)

#area, slen, dir, nout, nin, sinks, pits, c, bnds  = WhereTheWaterFlows.waterflows(dem, drain_pits=true);
area, slen, dir, nout, nin, sinks, pits, c, bnds  = WhereTheWaterFlows.waterflows(dem, drain_pits=true);

@assert size(dem)==(length(xs), length(ys))
plotyes && plt_it(xs, ys, dem)
plotyes && plt_area(xs, ys, area, sinks)

plotyes && plt_catchments(xs, ys, c)

demf = WhereTheWaterFlows.fill_dem(dem, sinks, dir) #, small=1e-6)
plotyes && heatmap(xs, ys, demf.-dem)