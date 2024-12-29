__precompile__(false)
plotyes = true #plotting yes/no
testrun = false #true uses sample data, false uses actual data 
forcedownload = false #should download data automatically the first time, else change to true
thin = 32 # step by which to thin the DEM
using Rasters, WhereTheWaterFlows, ArchGDAL
using Downloads, ZipFile
include("helpers.jl")

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

    demorig = crop_dem_nan(replace_missing(Raster(joinpath(download_folder, "dem3.tif")), NaN))
    dem = demorig[1:thin:end, 1:thin:end]
    xs, ys = lookup(dem, X), lookup(dem, Y)
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
# calculate catchments of moulins
moulin_sinks = make_boxes(dem, diff(xs)[1]*5)
cs = [WWF.catchment(dir, s) for s in moulin_sinks] .* (1:4)
cs = Raster(cs[1] .+ cs[2] .+ cs[3] .+ cs[4], missingval=0)

c = Raster(c, missingval=0)
#save geotif
write("area.tif", area, force = true)

@assert size(dem)==(length(xs), length(ys))
#fig = plotyes && plt_it(xs, ys, out, demplot) # using only dem as input will re-run the routing, which takes TIME
#plotyes && save("3plots.png", fig)

#areaplot = maxcar(area, thin_plot*ones(size(area)))[1:thin_plot:end, 1:thin_plot:end]
# sinksplot = maxcar(sinks, thin_plot*ones(size(sinks)))[1:thin_plot:end, 1:thin_plot:end]
fig = plotyes && plt_area(xs, ys, area.data, sinks)
plotyes && save("plot_area.png", fig)

fig = plotyes && heatmap(c)
plotyes && save("plot_catchment.png", fig)

# fig = plotyes && plt_catchments(xs, ys, cs.data) # unfortunately one area is white...
fig = plotyes && heatmap(cs)
plotyes && save("plot_catchment_moulins.png", fig)

demf = WhereTheWaterFlows.fill_dem(dem, sinks, dir) #, small=1e-6)
plotyes && heatmap(demf.-dem)
plt_area(xs, ys, area.data, sinks)
