# About

This repository contains all code necessary to reproduce the results presented in 

Paltra S, Dehning J, Priesemann V and Nagel K (2026) Inferring mobility reductions from COVID-19 disease spread along the urban-rural gradient. Front. Public Health 14:1840916. doi: [10.3389/fpubh.2026.1840916](https://doi.org/10.3389/fpubh.2026.1840916)

This project is the result of the collaboration between the groups of Kai Nagel, TU Berlin, and Viola Priesemann, MPI for Dynamics and Self-Organisation, as part of the BMBF-funded infoXpand consortium.
Main contributors: Sydyney Paltra, Emil Iftekhar, Jonas Dehning

# File structure
This is the source code to analyse the various contributions that lead to changes in out-of-home duration in the year of 2020 compared to baseline years.
The core method is Bayesian Inference using pymc.

To make the code run, it is necessary to download the covid19_inference module from github first:
https://github.com/Priesemann-Group/covid19_inference/

## Files
The code is centered around main.py that uses functions in the following files:
- data_prep_hierarchical.py: Contains functions to prepare and return input data for the inference model
- main_hierarchical.py : Contains functions to run the inference model. Allows the user to create an output directory, set certain parameters, choose sampler
- model_hierarchical.py: Contains functions to build and return the inference model. User may choose from different functional forms for weather factor
- utils.py: Contains a few utility functions
- plot_hierarchical.py: Contains functions to plot the results the inference
- model_comparison.py: Contains functions to calculate the ELPDs

cluster_run.sh is used to run the inference on the cluster.
Sometimes it is possible that no local data for the disease indicators is stored. As the cluster does not have internet access to download the Our World in Data data, one needs to run the cells of
    download_OWID.ipynb 
before using the cluster for the inference.

## Directories
- data: Storage for some of the (raw) input data
- results: Storage for the inference results, e.g. traces and source files
- figures: Storage for all the produced figures
- archived: old files

## Deprecated scripts

### R
- plot_results.ipynb is mainly used to plot model comparison figures. (It is quite messy right now.)
- input_data_analysis.ipynb is a messy notebook to pre-analyse the input data. May be archived at some point.
- Postprocesxing_Clean.R
- Postprocessing_CountyTypeAnalysis.R


