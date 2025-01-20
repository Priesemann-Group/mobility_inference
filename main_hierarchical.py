"""
This Python script models and analyzes the changes in out-of-duration in the year of 2020 given a set of indicators and parameters. 
The script first sets up the necessary configurations and uses a utility function to create directories for saving results and figures. 
Using data_prep_new.py, it then collects various types of data including out-of-home duration (o), employment changes (Kurzarbeit), 
    effective reproduction number (R), cases (C), ICU occupancy (ICU), hospitalization rates (H), and stay-at-home orders (S). 
    If specified, it also collects weather data such as precipitation and temperature changes. 
Then it iterates through all combinations of indicators and creates a model for each combination using the function in model_hierarchical.py.
The model is then fitted to the data using MCMC sampling.
The results are saved in the results directory and figures are saved in the figures directory using plot_new.py.
"""

# Import necessary modules
import pymc as pm
import pickle
import shutil
import pandas as pd
import numpy as np
import arviz as az
from collections import defaultdict
#import numba
#import numpyro
#import nutpie
#import blackjax

# Import local module
import model_hierarchical
import data_prep_hierarchical
import plot_hierarchical
import utils
import xarray
import model_comparison

# Set up basic configurations
name = "2025-01-20_MeckPommincl2023"  # Name of the experiment
test = False # Whether to run a test with fewer samples
single = True  # Whether to run a single model
run = True # Whether to run the model or load the trace from a file
disease_indicator = True # Whether to include disease indicators
plot_figures = True    # Whether to plot figures
ELPD_method = None   # ELPD calculation method: "LFO" or "k-fold_CV"; else set to None
M = 10   # Number of days to predict in ELPD calculation; has to be at least 2

#chosen_model = "BEHHHB"
#chosen_model = "fedStates"
#chosen_model = "cities"
chosen_model = "cities_MeckPomm"
#chosen_model = "national"
#chosen_model = "cities_non_hierarchical"

#Include population density if required by giving any value
pop_density = None

# Include weather parameters if required by giving any value
# If not required, set these to None
precipitation = None
temperature = 1
daylight = None

#Include school vacations and public holidays if required by giving any value
school = 1
holiday = 1


# Generate all combinations of indicators
if disease_indicator:
    all_combinations = utils.indicator_combinations(
    #    base_indicators=["H"], 
        limit=2
        )
else:
    all_combinations = [[]]

# Initialize a dictionary to store disease related data
disease_data_raw = {}
disease_data = {}

# Set up directory for saving results
supDir_name = "results/" + name
utils.make_dir(supDir_name)

# Set up directory for saving figures
figdir_name = "figures/" + name
utils.make_dir(figdir_name)

# Copy the source code into the results directory for record keeping
shutil.copyfile("main_hierarchical.py", f"{supDir_name}/main_new.py")
shutil.copyfile("model_hierarchical.py", f"{supDir_name}/model_new.py")
shutil.copyfile("data_prep_hierarchical.py", f"{supDir_name}/data_prep_new.py")

# Load and prepare data
# Get out of home duration data
d_2020, d_base, dates = data_prep_hierarchical.get_out_of_home_duration(chosen_model)
d_2020_long, d_base_long, dates_long = data_prep_hierarchical.get_out_of_home_duration_long(chosen_model)


# Get R_effective value for disease data
disease_data_raw["R"] = data_prep_hierarchical.get_R_raw(chosen_model)
disease_data["R"] = data_prep_hierarchical.get_R_transformed(disease_data_raw["R"], chosen_model)

# Get R_effective value for disease data
disease_data_raw["logR"] = data_prep_hierarchical.get_logR_raw(disease_data_raw["R"])
disease_data["logR"] = data_prep_hierarchical.get_logR_transformed(disease_data_raw["logR"])

# Get cases, ICU, deaths and hospitalisations data from OWID
disease_data_raw["C"] = data_prep_hierarchical.get_C_raw(chosen_model)
disease_data["C"] = data_prep_hierarchical.get_C_transformed(chosen_model)

disease_data_raw["logC"] = data_prep_hierarchical.get_logC_raw(chosen_model)
disease_data["logC"] = data_prep_hierarchical.get_logC_transformed(chosen_model)

#disease_data_raw["ICU"] = data_prep_hierarchical.get_ICU_raw()
#disease_data["ICU"] = data_prep_hierarchical.get_ICU_transformed(disease_data_raw["ICU"])

#disease_data_raw["logICU"] = data_prep_hierarchical.get_logICU_raw(disease_data_raw["ICU"])
#disease_data["logICU"] = data_prep_hierarchical.get_logICU_transformed(disease_data_raw["logICU"])

disease_data_raw["H"] = data_prep_hierarchical.get_H_raw(chosen_model)
disease_data["H"] = data_prep_hierarchical.get_H_transformed(chosen_model)

disease_data_raw["logH"] = data_prep_hierarchical.get_logH_raw(chosen_model)
disease_data["logH"] = data_prep_hierarchical.get_logH_transformed(chosen_model)

disease_data_raw["D"] = data_prep_hierarchical.get_D_raw(chosen_model)
disease_data["D"] = data_prep_hierarchical.get_D_transformed(chosen_model)

disease_data_raw["logD"] = data_prep_hierarchical.get_logD_raw(chosen_model)
disease_data["logD"] = data_prep_hierarchical.get_logD_transformed(chosen_model)


# # If population density is included, get population density
# if pop_density is not None:
#     pop_density = {
#         "pop_density": data_prep_hierarchical.get_pop_density(chosen_model)
#     }

# # If precipitation is included, get precipitation data
# if precipitation is not None:
#     precipitation = {
#         "precipitation": data_prep_hierarchical.get_precipitation(chosen_model)
#     }

# # If temperature is included, get temperature data
if temperature is not None:
    temperature = {
        "temperature": data_prep_hierarchical.get_temperature(chosen_model)
    }

if daylight is not None:
    daylight = {
        "daylight": data_prep_hierarchical.get_daylight(chosen_model),
    }

#If school is included, get school data
if school is not None:
    school = {
        "school vacation": data_prep_hierarchical.get_school_vacations(chosen_model)
    }

#If public holidays are included, get public holiday data
if holiday is not None:
    holiday = {
        "pub holiday": data_prep_hierarchical.get_pub_holidays(chosen_model)
    }

time_counter = {
        "time counter": data_prep_hierarchical.get_counter(chosen_model),
        "time_counter_long": data_prep_hierarchical.get_counter_long(chosen_model)
}

obs_id_long = data_prep_hierarchical.get_index_long(chosen_model)
fedState, fedStates, obs_id = data_prep_hierarchical.get_federal_states(chosen_model)
lk = None
#lk = data_prep_hierarchical.get_lk(chosen_model)
fedState_long, fedStates_long, obs_id_long = data_prep_hierarchical.get_federal_states_long(chosen_model)
#lk_long = data_prep_hierarchical.get_lk_long(chosen_model)
lk_long = None
if chosen_model == "BEHHHB":
    fedState_coord = np.array([0, 1, 2])
if chosen_model == "fedStates":
    fedState_coord = np.array([0, 1, 2,3,4,5,6,7,8,9,10,11,12,13,14,15])
if chosen_model == "cities":
    fedState_coord = np.array([0,1,2,3,4,5,6,7,8,9])
if chosen_model == "cities_MeckPomm":
    fedState_coord = np.array([0,1,2,3,4,5,6,7,8,9,10,11])
if chosen_model == "cities_non_hierarchical":
    fedState_coord = np.array([0])
#fedState = fedState_coord
counter = xarray.DataArray.to_numpy(time_counter["time counter"])
counter_long = xarray.DataArray.to_numpy(time_counter["time_counter_long"])

if single:
    all_combinations = [
        #["R"],
        # ["logR"],
        #["C"],
        ["C"],
        # ["logC"],
        # ["ICU"],
        # ["logICU"],
        #["H"],
        #["logH"],
        # ["D"],
        # ["logD"]
    ]

# Parameters for ELPD calculation runs
if ELPD_method == "LFO":
    L = 10
elif ELPD_method == "k-fold_CV":
    L = 1

# Run model for each combination of indicators
for indicators in all_combinations:
    # Generate a tag for saving results
    tag = ""
    for indicator in indicators:
        tag += indicator + "_"
    tag = tag[:-1]

    # Set up directory for individual results
    dir_name = supDir_name + "/" + tag
    utils.make_dir(dir_name)

    models = {}
    traces = {}
    if ELPD_method is not None:
        iterable = range(L-1, len(d_2020) - M)
    else:
        iterable = [0]
    for i in iterable:
        # replace observed data after i with nan
        d_obs = d_2020.copy()
        if ELPD_method == "LFO":
            d_obs[i+1:] = float("nan")
            tag2 = tag + f"_{ELPD_method}_" + str(i)
        elif ELPD_method == "k-fold_CV":
            d_obs[i+1 : i+1 + M] = float("nan")
            tag2 = tag + f"_{ELPD_method}_" + str(i)
        else:
            tag2 = tag

        # Create model
        coords = {"fedState": fedState_coord, "obs_id_long": obs_id_long, "obs_id": obs_id, "timeCounter" : counter, "timeCounter_long" : counter_long}
    
        inference_model = pm.Model(coords=coords)

        model_hierarchical.create_model(
            inference_model,
            d_base,
            d_obs,
            indicators,
            disease_data,
            time_counter,
            school_in = school,
            holiday_in = holiday,
            temperature_in=temperature,
            precipitation_in=precipitation,
            daylight_in = daylight,
            pop_density_in = pop_density,
            fed_states_in = fedState,
            fed_states_in_long = fedState_long,
            lk_in = lk,
            lk_in_long = lk_long,
            counter_in = counter
        )
        models[i] = inference_model

        if run:
            # Perform inference
            if test:
                draws = 20 #200
                tune = 20 #200
            else:
                draws = 5000 #1000
                tune = 5000 #1000
            with inference_model:
                approx = pm.fit(n=draws*50)
                trace = approx.sample(draws=draws)
                # trace = pm.sample(
                #     model=inference_model, draws=draws, tune=tune, cores=4, chains=4, nuts_sampler = "pymc",
                #     idata_kwargs={"include_transformed": False}
                # )
            with inference_model:
                pm.compute_log_likelihood(trace)

            # Save inference results
            ## trace
            # path = f"{dir_name}/trace_{tag2}.pickle"
            # with open(path, "wb") as inference_file:
            #     pickle.dump(trace, inference_file)
            # ## summary
            # summary = az.summary(trace, round_to=2)
            # path = f"{dir_name}/summary_{tag2}.csv"
            # summary.to_csv(path)
        else:
            trace = utils.load_trace(name, tag, tag2)

        traces[i] = trace

    inference_model.add_coord("timeCounter", counter, mutable = True)

    # # Save ELPD result to file
    # if ELPD_method is not None:
    #     model_comparison.save_ELPD(models, traces, L, M, len(dates), dir_name, draws, ELPD_method)

    # Plot results
    if plot_figures:
        subFigDir_name = figdir_name + "/" + tag
        plot_hierarchical.analysis_figures(
           inference_model, trace, subFigDir_name, dates, dates_long, indicators, school, holiday, temperature, precipitation, daylight, pop_density, disease_data, disease_data_raw, fedState, chosen_model
        )


#gv = pm.model_to_graphviz(inference_model)
#gv.format = 'png'
#gv.render(filename='model_graph')