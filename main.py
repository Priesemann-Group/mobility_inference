import pymc as pm
import os
import pickle
import shutil
import pandas as pd

import model
import data_prep
import plot
import utils


name = "no_weather"

pandemic_fatigue = "linear"

# set to None if to be excluded, else set to anything
precipitation = None
temperature = None

# We create a list of all indicator combinations.
all_combinations = utils.indicator_combinations()

disease_data = {}

# We create a directory for the results.
supDir_name = "results/" + name
## We create the target directory if it does not exist yet
if not os.path.exists(supDir_name):
    os.mkdir(supDir_name)
    print("Directory ", supDir_name, " created.")
else:
    print("Directory ", supDir_name, " already exists.")

# We create a directory for the figures.
figdir_name = "figures/" + name
## We create the target directory if it does not exist yet
if not os.path.exists(figdir_name):
    os.mkdir(figdir_name)
    print("Directory ", figdir_name, " created.")
else:
    print("Directory ", figdir_name, " already exists.")

# To know for every result how it was produced, we copy this source code into the results directory.
shutil.copyfile("main.py", f"{supDir_name}/main.py")
shutil.copyfile("model.py", f"{supDir_name}/model.py")
shutil.copyfile("data_prep.py", f"{supDir_name}/data_prep.py")

# Data
## Out of home duration
o_2020, o_base, dates_2020, dates_2022 = data_prep.get_out_of_home_duration()
dates = pd.to_datetime(dates_2020)

## Kurzarbeit
kurzarbeit_df = data_prep.get_total_kurzarbeit()

## R
disease_data["R"] = data_prep.get_R(dates_2020)

## OWID
owid = data_prep.get_owid()

### cases
disease_data["C"] = data_prep.get_C(owid, dates_2020)

### ICU
disease_data["ICU"] = data_prep.get_ICU(owid, dates_2020)

### hospitalisations
disease_data["H"] = data_prep.get_H(owid, dates_2020)

## NPI
### stay at home orders
stay_at_home_2020 = data_prep.get_S(dates_2020)
### school closures: will probably not be used anymore
# schook_closures_2020 = data_prep.get_school_closures(dates_2020)

## weather
### precipitation
if precipitation is not None:
    precipitation = data_prep.get_delta_prcp(dates_2020, dates_2022)
### temperature
if temperature is not None:
    temperature = {
        "average": data_prep.get_avg_T(dates_2020, dates_2022),
        "delta": data_prep.get_delta_T(dates_2020, dates_2022),
    }

# Now to the model runs
for indicators in all_combinations:
    # for saving the results
    tag = ""
    for indicator in indicators:
        tag += indicator + "_"
    tag = tag[:-1]

    ## We create a directory for the individual results.
    dir_name = supDir_name + "/" + tag
    ### We create the target directory if it does not exist yet
    if not os.path.exists(dir_name):
        os.mkdir(dir_name)
        print("Directory ", dir_name, " created.")
    else:
        print("Directory ", dir_name, " already exists.")

    # Model
    inference_model = pm.Model()
    model.create_model(
        inference_model,
        o_base,
        o_2020,
        stay_at_home_2020,
        kurzarbeit_df,
        indicators,
        disease_data,
        dates_2022,
        pandemic_fatigue,
        delta_prcp_in=precipitation,
        temperature_in=temperature,
    )

    # Inference
    trace = pm.sample(model=inference_model, draws=200, tune=200, cores=1, chains=4)
    with inference_model:
        pm.compute_log_likelihood(trace)

    # Save the trace
    path = f"{dir_name}/trace_{tag}.pickle"
    with open(path, "wb") as inference_file:
        pickle.dump(trace, inference_file)

    # Plot all figures
    subFigDir_name = figdir_name + "/" + tag
    plot.analysis_figures(
        inference_model, trace, subFigDir_name, dates, indicators, pandemic_fatigue
    )
