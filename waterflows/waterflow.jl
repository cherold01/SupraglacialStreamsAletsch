__precompile__(false)
plotyes = false
using Rasters, WhereTheWaterFlows, ArchGDAL
using Downloads, ZipFile

# URL for the folder (replace with your actual link)
#folder_url = "https://polybox.ethz.ch/index.php/s/7es7qxqCAFOoVUt/download"

urls = [
    "https://polybox.ethz.ch/index.php/s/KXRunB4blk82XMA/download"
    "https://polybox.ethz.ch/index.php/s/6rVraOz9owox2qV/download"
    "https://polybox.ethz.ch/index.php/s/kWw1gxRUxP4xXQ4/download"
    "https://polybox.ethz.ch/index.php/s/Ul4UXndUtO6qbqS/download"
    "https://polybox.ethz.ch/index.php/s/a2RwtK0ar4mijXm/download"
]

# Folder to save the files
download_folder = joinpath(@__DIR__,"data\\raw\\dem")
isdir(download_folder) || mkdir(download_folder)

# Download each file
for (i, url) in enumerate(urls)
    file_name = joinpath(download_folder, "dem$(i).tif")
    println("Downloading $url to $file_name")
    Downloads.download(url, file_name)
end

println("Download complete!")
"""
# Define the path for the downloaded zip file
zip_file_path = joinpath(download_folder, "aletsch_dems.zip")


# Download the zip file
println("Downloading the folder as a zip file...")
Downloads.download(folder_url, zip_file_path)

# Extract the zip file
println("Extracting the zip file...")
r = ZipFile.Reader(zip_file_path)

?println("Download and extraction complete!")
"""

dem = Raster(joinpath(download_folder, "dem1.tif"))
#dem = Raster("100-1012_high_dem_2cm_lv95.tif")
#dem_crop = dem[5000:6000, 5000:6000]
#dem = dem[1:2:length(dem[:,1]), 1:2:length(dem[1, :])]

#plotyes = true
if !@isdefined plotyes
    plotyes = true
end
if plotyes
    @eval using CairoMakie
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