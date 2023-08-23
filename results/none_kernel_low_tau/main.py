"""
This Python script models and analyzes the changes in out-of-duration in the year of 2020 given a set of indicators and parameters. 
The script first sets up the necessary configurations and uses a utility function to create directories for saving results and figures. 
Using data_prep.py, it then collects various types of data including out-of-home duration (o), employment changes (Kurzarbeit), 
    effective reproduction number (R), cases (C), ICU occupancy (ICU), hospitalization rates (H), and stay-at-home orders (S). 
    If specified, it also collects weather data such as precipitation and temperature changes. 
Then it iterates through all combinations of indicators and creates a model for each combination using the function in model.py.
The model is then fitted to the data using MCMC sampling.
The results are saved in the results directory and figures are saved in the figures directory using plot.py.
"""

# Import necessary modules
import pymc as pm
import pickle
import shutil
import pandas as pd
import arviz as az

# Import local modules
import model
import data_prep
import plot
import utils

# Set up basic configurations
name = "none_kernel_low_tau"  # Name of the experiment
pandemic_fatigue = "none"  # Type of pandemic fatigue function: 'linear' or 'sigmoid'
test = False  # Whether to run a test with fewer samples
single = False  # Whether to run a single model
run = True  # Whether to run the model or load the trace from a file

# Include weather parameters if required by giving any value
# If not required, set these to None
precipitation = None
temperature = None

# Generate all combinations of indicators
all_combinations = utils.indicator_combinations()

# Initialize a dictionary to store disease related data
disease_data = {}

# Set up directory for saving results
supDir_name = "results/" + name
utils.make_dir(supDir_name)

# Set up directory for saving figures
figdir_name = "figures/" + name
utils.make_dir(figdir_name)

# Copy the source code into the results directory for record keeping
shutil.copyfile("main.py", f"{supDir_name}/main.py")
shutil.copyfile("model.py", f"{supDir_name}/model.py")
shutil.copyfile("data_prep.py", f"{supDir_name}/data_prep.py")

# Load and prepare data
# Get out of home duration data
o_2020, o_base, dates_2020, dates_2022 = data_prep.get_out_of_home_duration()
dates = pd.to_datetime(dates_2020)

# Get difference in kurzarbeit data
kurzarbeit_df = data_prep.get_kurzarbeit(dates_2020)

# Get difference in home office data
home_office_df = data_prep.get_home_office_difference(dates_2020)

# Get R_effective value for disease data
disease_data["R"] = data_prep.get_R()

# Get OWID data
owid = data_prep.get_owid()

# Get cases, ICU, and hospitalisations data from OWID
disease_data["C"] = data_prep.get_C(owid)
disease_data["ICU"] = data_prep.get_ICU(owid)
disease_data["H"] = data_prep.get_H(owid)

# Get stay at home orders data
stay_at_home_2020 = data_prep.get_S(dates_2020)

# If precipitation is included, get precipitation data
if precipitation is not None:
    precipitation = data_prep.get_delta_prcp(dates_2020, dates_2022)

# If temperature is included, get temperature data
if temperature is not None:
    temperature = {
        "average": data_prep.get_avg_T(dates_2020, dates_2022),
        "delta": data_prep.get_delta_T(dates_2020, dates_2022),
    }

if single:
    all_combinations = [
        ["R"],
        [
            # "R",
            "C"
        ],
    ]

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

    # Create model
    inference_model = pm.Model()
    model.create_model(
        inference_model,
        o_base,
        o_2020,
        stay_at_home_2020,
        kurzarbeit_df,
        home_office_df,
        indicators,
        disease_data,
        pandemic_fatigue,
        delta_prcp_in=precipitation,
        temperature_in=temperature,
    )

    if run:
        # Perform inference
        if test:
            trace = pm.sample(
                model=inference_model, draws=200, tune=200, cores=1, chains=4
            )
        else:
            trace = pm.sample(
                model=inference_model, draws=1000, tune=1000, cores=1, chains=4
            )
        with inference_model:
            pm.compute_log_likelihood(trace)

        # Save inference results
        ## trace
        path = f"{dir_name}/trace_{tag}.pickle"
        with open(path, "wb") as inference_file:
            pickle.dump(trace, inference_file)
        ## summary
        summary = az.summary(trace, round_to=2)
        path = f"{dir_name}/summary_{tag}.csv"
        summary.to_csv(path)
    else:
        trace = utils.load_trace(name, tag)

    # Plot results
    subFigDir_name = figdir_name + "/" + tag
    plot.analysis_figures(
        inference_model, trace, subFigDir_name, dates, indicators, pandemic_fatigue
    )
