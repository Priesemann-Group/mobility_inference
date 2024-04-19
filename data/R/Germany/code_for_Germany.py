#!/usr/bin/env python
# coding: utf-8

# Infering R_eff in the year 2020 with JHU data for a given country
# The first thing we need to do is import some essential stuff. Theses have to be installed and are prerequisites.

import datetime
import numpy as np
import pytensor.tensor as at
import pymc as pm
import pickle
import pandas as pd
from population_sizes import populations
import argparse
import os
import shutil

# This module needs to be downloaded into the same directory.
import covid19_inference as cov19


# ## Preparation for documenting the results and run
# For submitting the run to the queue of the cluster, we want to parse parameters from command or .sh.
parser = argparse.ArgumentParser(description="input parameters")

# These are the possible arguments.
parser.add_argument("--country", default="Germany", type=str, help="country to analyze")
parser.add_argument("--name", default="test", type=str, help="name for this simulation")

# We set some global variables defining the run.
args = parser.parse_args()
country = args.country
tag = country + "_" + args.name

# We create a directory for the results.
dir_name = "R_eff_results/" + tag
## We create the target directory if it does not exist yet
if not os.path.exists(dir_name):
    os.makedirs(dir_name)
    print("Directory ", dir_name, " created.")
else:
    print("Directory ", dir_name, " already exists.")

# To know for every result how it was produced, we copy this source code into the results directory.
shutil.copyfile("infer_R_eff.py", f"{dir_name}/code_for_{tag}.py")


# ## Data retrieval
# The next thing we want to do is (down)load a dataset.
cov19.data_retrieval.set_data_dir("/data.nst/eiftekhar/covid19")
jhu = (
    cov19.data_retrieval.JHU()
)  # One could also parse True to the constructor of the class to force an auto download
jhu.download_all_available_data()

"""
    We can now access this downloaded data by the attribute
    ```
    jhu.data
    ```
    but normally one would use the built in filter methods,
    these can be found [here](https://covid19-inference.readthedocs.io/en/latest/doc/data_retrieval.html#covid19_inference.data_retrieval.JHU.get_new).
"""

# These are the begin and end dates for our data.
bd = datetime.datetime(2020, 3, 15)
ed = datetime.datetime(2020, 12, 15)

# We extract the daily new confirmed number of cases for the specified country and date range.
new_cases_obs = jhu.get_new(
    value="confirmed", country=country, data_begin=bd, data_end=ed
)
# We replace 0 with nan.
new_cases_obs[new_cases_obs == 0] = np.nan

# 

# ## Create the model
# Next, we create the model! There are default values for most of the function arguments.
# But we will try to explicitly set all kwargs for the sake of clarity.

# For the median of the prior for the delay in case reporting we assume 10 days.
pr_delay = 10

params_model = dict(
    new_cases_obs=new_cases_obs,
    data_begin=bd,
    data_end=ed,
    fcast_len=16,
    diff_data_sim=pr_delay + 6,
    N_population=82000000,
)

# Now we need to set the priors for the change points.

# This function returns a range of dates.
def return_change_point_dates(start_date_in, end_date_in, delta_days_in):
    dates = []
    date = start_date_in
    while date <= end_date_in:
        dates.append(date)
        date += datetime.timedelta(days=delta_days_in)
    return dates

# Now we create the date range.
delta_days = 10
change_point_dates = return_change_point_dates(bd-datetime.timedelta(days=params_model["diff_data_sim"]), ed, delta_days)

# With these dates, we set all change points with all of the necessary prior parameters.
def make_change_point(date):
    change_point = dict(
        pr_mean_date_transient=date,
        pr_sigma_date_transient=3,
        pr_median_lambda=1,
        pr_sigma_lambda=0.5,
        pr_median_transient_len=4,
        pr_sigma_transient_len=1,
        relative_to_previous=False,
        pr_factor_to_previous=1,
    )
    return change_point

change_points = [make_change_point(date) for date in change_point_dates]

# The model is specified in a context. Each function in this context has access to the model parameters set.

with cov19.model.Cov19Model(**params_model) as this_model:
    # Create an array of the time dependent (log) effective reproduction number.
    R_eff_log = cov19.model.lambda_t_with_sigmoids(
        pr_median_lambda_0=1.0,
        pr_sigma_lambda_0=0.5,
        sigma_lambda_cp=pm.HalfCauchy(
            "sigma_lambda_cp",
            beta=0.5,
            transform=pm.distributions.transforms.log_exp_m1,
        ),
        change_points_list=change_points,  # The change point priors we constructed earlier
    )
    # Document the non-log version of the array as well.
    R_eff = pm.Deterministic("R_eff", at.exp(R_eff_log))

    # Use the R_eff time series to simulate the spread.
    new_cases = cov19.model.kernelized_spread(
        R_eff,
        name_new_I_t="new_I_t",
    )

    #Delay the cases by a lognormal reporting delay.
    new_cases = cov19.model.delay_cases(
        cases=new_cases,
        #name_cases="delayed_cases",
        #name_delay="delay",
        #name_width="delay_width",
        #pr_mean_of_median=pr_delay,
        #pr_sigma_of_median=0.2,
        #pr_median_of_width=0.3,
    )

    # # Modulate the inferred cases by considering that there is always a fraction of cases reported with another delay depending on the weekday.
    new_cases = cov19.model.week_modulation(
        cases=new_cases, week_modulation_type="by_weekday"
    )

    # # Define the likelihood, uses the new_cases_obs set as model parameter.
    cov19.model.student_t_likelihood(new_cases)


# ## MCMC sampling
# After the model is built, it is sampled using a MCMC sampler.
# The number of parallel runs can be set with the argument `cores=`.
# The sampling can take a long time.
idata = pm.sample(
    model=this_model, tune=500, draws=500, init="advi+adapt_diag", cores=1
)


# ## Saving the results
# Save the trace.
path = f"R_eff_results/traces/idata_{tag}.pickle"
with open(path, "wb") as inference_file:
    pickle.dump(idata, inference_file)

# Save results for $R_{\text{eff}}$ to csv.

# Get results.
R_eff, result_dates = cov19.plot.utils.get_array_from_idata_via_date(
    this_model, idata, "R_eff"
)

# Save results.
results_dict = {
    "date": result_dates,
    "R_eff median": np.median(R_eff, axis=0),
    "R_eff lower bound 95% CI": np.percentile(R_eff, q=2.5, axis=0),
    "R_eff upper bound 95% CI": np.percentile(R_eff, q=97.5, axis=0),
}
df = pd.DataFrame(results_dict)
df.to_csv(f"{dir_name}/R_eff_{tag}.csv")
