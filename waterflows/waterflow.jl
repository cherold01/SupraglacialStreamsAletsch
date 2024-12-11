__precompile__(false)
plotyes = true #plotting yes/no
testrun = false #true uses sample data, false uses actual data 
forcedownload = true #should download data automatically the first time, else change to true
thin = 32 # step by which to thin the DEM
using Rasters, WhereTheWaterFlows, ArchGDAL
using Downloads, ZipFile
include("filter.jl")

# URL for the folder (replace with your actual link)
#folder_url = "https://polybox.ethz.ch/index.php/s/7es7qxqCAFOoVUt/download"

if testrun == false
    # Folder to save the files
    download_folder = joinpath(@__DIR__,"../data/raw/dem")
    isdir(download_folder) || mkdir(download_folder)

    if !isfile(joinpath(download_folder, "dem1.tif")) || forcedownload

        urls = [
            "https://polybox.ethz.ch/index.php/s/KXRunB4blk82XMA/download"
            "https://polybox.ethz.ch/index.php/s/6rVraOz9owox2qV/download"
            "https://polybox.ethz.ch/index.php/s/kWw1gxRUxP4xXQ4/download"
            "https://polybox.ethz.ch/index.php/s/Ul4UXndUtO6qbqS/download"
            "https://polybox.ethz.ch/index.php/s/a2RwtK0ar4mijXm/download"
            "https://polybox.ethz.ch/index.php/s/Zyl26bkRfRBD6Rc/download"
        ]

        # Download each file
        for (i, url) in enumerate(urls)
            file_name = joinpath(download_folder, "dem$(i).tif")
            println("Downloading $url to $file_name")
            Downloads.download(url, file_name)
        end
        println("Download complete!")
    end

    """
    #for zip folders
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

    demorig = Raster(joinpath(download_folder, "dem6.tif"))
    #dem = Raster("100-1012_high_dem_2cm_lv95.tif")
    #dem_crop = dem[5000:6000, 5000:6000]
    dem = demorig[1:thin:end, 1:thin:end]
    # Filtering doesn't seem to do much
    # dem = boxcar(dem, 5*ones(Int, size(dem)))

    xs = 1:length(dem[:,1])
    ys = 1:length(dem[1, :])
    dem = dem.data # raster causes some problems
end


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

if testrun == true
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
end

# maybe filter and thin:
thin_plot = 1
#demplot = maxcar(dem, thin_plot*ones(size(dem)))[1:thin_plot:end, 1:thin_plot:end]
#plotyes && heatmap(xs, ys, demplot)

#TODO: thin-filter other vars as well

@time out = WhereTheWaterFlows.waterflows(dem, drain_pits=true);
area, slen, dir, nout, nin, sinks, pits, c, bnds = out

@assert size(dem)==(length(xs), length(ys))
#fig = plotyes && plt_it(xs, ys, out, demplot) # using only dem as input will re-run the routing, which takes TIME
#plotyes && save("3plots.png", fig)

#areaplot = maxcar(area, thin_plot*ones(size(area)))[1:thin_plot:end, 1:thin_plot:end]
# sinksplot = maxcar(sinks, thin_plot*ones(size(sinks)))[1:thin_plot:end, 1:thin_plot:end]
fig = plotyes && plt_area(xs, ys, area, sinks)
plotyes && save("plot_area.png", fig)

cplot = c[1:thin_plot:end, 1:thin_plot:end]
fig = plotyes && plt_catchments(xs, ys, cplot)
plotyes && save("plot_catchment.png", fig)

demf = WhereTheWaterFlows.fill_dem(dem, sinks, dir) #, small=1e-6)
plotyes && heatmap(xs, ys, demf.-dem)
plt_area(xs, ys, area, sinks)
