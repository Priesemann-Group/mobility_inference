"""
This Python script models and analyzes the changes in out-of-duration in the year of 2020 given a set of indicators and parameters. 
The script first sets up the necessary configurations and uses a utility function to create directories for saving results and figures. 
Using data_prep_new.py, it then collects various types of data including out-of-home duration (o), employment changes (Kurzarbeit), 
    effective reproduction number (R), cases (C), ICU occupancy (ICU), hospitalization rates (H), and stay-at-home orders (S). 
    If specified, it also collects weather data such as precipitation and temperature changes. 
Then it iterates through all combinations of indicators and creates a model for each combination using the function in model.py.
The model is then fitted to the data using MCMC sampling.
The results are saved in the results directory and figures are saved in the figures directory using plot_new.py.
"""

# Import necessary modules
import pymc as pm
import pickle
import shutil
import pandas as pd
import arviz as az

# Import local module
import model_new
import data_prep_new
import plot_new
import utils
import model_comparison

# Set up basic configurations
name = "temperature_x2_incldaylight"  # Name of the experiment
test = True  # Whether to run a test with fewer samples
single = True  # Whether to run a single model
run = True  # Whether to run the model or load the trace from a file
disease_indicator = True # Whether to include disease indicators
stay_at_home = None # Whether to include stay-at-home orders as an indicator; None if not included
plot_figures = True    # Whether to plot figures
ELPD_method = None   # ELPD calculation method: "LFO" or "k-fold_CV"; else set to None
M = 10   # Number of days to predict in ELPD calculation; has to be at least 2

#Include population density if required by giving any value
pop_density = None

# Include weather parameters if required by giving any value
# If not required, set these to None
precipitation = None
temperature = 1
daylight = 1

#Include school vacations and public holidays if required by giving any value
school = 1
holiday = 1

# Generate all combinations of indicators
if disease_indicator:
    all_combinations = utils.indicator_combinations(
    #    base_indicators=["H"], 
        limit=1
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
shutil.copyfile("main_new.py", f"{supDir_name}/main_new.py")
shutil.copyfile("model_new.py", f"{supDir_name}/model_new.py")
shutil.copyfile("data_prep_new.py", f"{supDir_name}/data_prep_new.py")

# Load and prepare data
# Get out of home duration data
d_2020, d_base, dates_2020, dates_2022 = data_prep_new.get_out_of_home_duration()
dates = pd.to_datetime(dates_2020)

# Get R_effective value for disease data
disease_data_raw["R"] = data_prep_new.get_R_raw()
disease_data["R"] = data_prep_new.get_R_transformed(disease_data_raw["R"])

# Get R_effective value for disease data
disease_data_raw["logR"] = data_prep_new.get_logR_raw(disease_data_raw["R"])
disease_data["logR"] = data_prep_new.get_logR_transformed(disease_data_raw["logR"])


# Get OWID data
owid = data_prep_new.get_owid()

# Get cases, ICU, deaths and hospitalisations data from OWID
disease_data_raw["C"] = data_prep_new.get_C_raw(owid)
disease_data["C"] = data_prep_new.get_C_transformed(disease_data_raw["C"])

disease_data_raw["logC"] = data_prep_new.get_logC_raw(disease_data_raw["C"])
disease_data["logC"] = data_prep_new.get_logC_transformed(disease_data_raw["logC"])

disease_data_raw["ICU"] = data_prep_new.get_ICU_raw(owid)
disease_data["ICU"] = data_prep_new.get_ICU_transformed(disease_data_raw["ICU"])

disease_data_raw["logICU"] = data_prep_new.get_logICU_raw(disease_data_raw["ICU"])
disease_data["logICU"] = data_prep_new.get_logICU_transformed(disease_data_raw["logICU"])

disease_data_raw["H"] = data_prep_new.get_H_raw(owid)
disease_data["H"] = data_prep_new.get_H_transformed(disease_data_raw["H"])

disease_data_raw["logH"] = data_prep_new.get_logH_raw(disease_data_raw["H"])
disease_data["logH"] = data_prep_new.get_logH_transformed(disease_data_raw["logH"])

disease_data_raw["D"] = data_prep_new.get_D_raw(owid)
disease_data["D"] = data_prep_new.get_D_transformed(disease_data_raw["D"])

disease_data_raw["logD"] = data_prep_new.get_logD_raw(disease_data_raw["D"])
disease_data["logD"] = data_prep_new.get_logD_transformed(disease_data_raw["logD"])

# disease_data_raw["G"] = data_prep_new.get_G_raw(dates_2020)
# disease_data["G"] = data_prep_new.get_G_transformed(disease_data_raw["G"])

#Include vectors of ones for mobility

# If population density is included, get population density
if pop_density is not None:
    pop_density = {
        "pop_density": data_prep_new.get_pop_density(dates_2020)
    }

# If precipitation is included, get precipitation data
if precipitation is not None:
    precipitation = {
        "precipitation": data_prep_new.get_precipitation(dates_2020)
    }

# If temperature is included, get temperature data
if temperature is not None:
    temperature = {
        "temperature": data_prep_new.get_temperature(dates_2020),
        "delta_temperature": data_prep_new.get_avg_temperature(dates_2020)
    }

if daylight is not None:
    daylight = {
        "daylight": data_prep_new.get_daylight(dates_2020),
    }

#If school is included, get school data
if school is not None:
    school = {
        "school vacation": data_prep_new.get_school_vacations(dates_2020)
    }

#If public holidays are included, get public holiday data
if holiday is not None:
    holiday = {
        "pub holiday": data_prep_new.get_pub_holidays(dates_2020)
    }

if single:
    all_combinations = [
        # ["R"],
        # ["logR"],
        # ["C"],
        # ["logC"],
        # ["ICU"],
        # ["logICU"],
        # ["H"],
        ["logH"],
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
        inference_model = pm.Model()
        model_new.create_model(
            inference_model,
            d_base,
            d_obs,
            indicators,
            disease_data,
            school_in = school,
            holiday_in = holiday,
            temperature_in=temperature,
            precipitation_in=precipitation,
            daylight_in = daylight,
            pop_density_in = pop_density
        )
        models[i] = inference_model

        if run:
            # Perform inference
            if test:
                draws = 200 #200
                tune = 200 #200
            else:
                draws = 500 #1000
                tune = 500 #1000
            trace = pm.sample(
                model=inference_model, draws=draws, tune=tune, cores=1, chains=4, 
                idata_kwargs={"include_transformed": False}
            )
            with inference_model:
                pm.compute_log_likelihood(trace)

            # Save inference results
            ## trace
            path = f"{dir_name}/trace_{tag2}.pickle"
            with open(path, "wb") as inference_file:
                pickle.dump(trace, inference_file)
            ## summary
            summary = az.summary(trace, round_to=2)
            path = f"{dir_name}/summary_{tag2}.csv"
            summary.to_csv(path)
        else:
            trace = utils.load_trace(name, tag, tag2)

        traces[i] = trace

    # Save ELPD result to file
    if ELPD_method is not None:
        model_comparison.save_ELPD(models, traces, L, M, len(d_2020), dir_name, draws, ELPD_method)

    # Plot results
    if plot_figures:
        subFigDir_name = figdir_name + "/" + tag
        plot_new.analysis_figures(
            inference_model, trace, subFigDir_name, dates, indicators, school, holiday, temperature, precipitation, daylight, pop_density, disease_data, disease_data_raw
        )
