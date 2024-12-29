If you have this running on Linux then executing in this folder `./start_notebook` should get a
local Jupyter notebook server running (not tested by me).

The following notebooks are provided and should be looked-at and run in this order:
- `1_intro` 
- [`2_calibration.ipynb`](2_calibration.ipynb) to input and process your conductivity logger calibrations as well as pressure logger calibrations
- [`3_traces.ipynb`](3_traces.ipynb) reads CTD sensor data and partition into individual tracer experiments
- [`4_process_traces.ipynb`](4_process_traces.ipynb) process the traces to produce discharges and peak-times
- [`5_stage-discharge-relation`](5_stage-discharge-relation.ipynb) Fit a linear stage-discharge relation and apply it to get time series of the discharges
- [`6_Statistics`](6_Statistics.ipynb) Read in all data, assign uncertainties, plot values and perform statistical tests
- [`7_Plotgenerator`](7_Plotgenerator.ipynb) Produces some publication-ready plots


Additionally there are the following files
- [`quick_data_visualisation.ipynb`](quick_data_visualisation.ipynb) allows to plot sensor data
- [`helper_functions.ipynb`](helper_functions.ipynb) various helper functions used in the scripts