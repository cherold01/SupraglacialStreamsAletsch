The script `waterflow.jl` will download the digital elevation models as .tif files and process them. Outputs are:
- *area.tif* raster file with the cell value of each pixel = the number of cells flowing into that cell
- *plot_area.png* plot of *area.tif*
- *plot_catchment.png* plot of all different catchments found in the DEM
- *plot_catchment_moulins* plot of the catchments of all moulins. moulins were defined before

setting thin = 1 will likely not work on a normal device and will require some more computational power since it can use up to 60GB of RAM. 

