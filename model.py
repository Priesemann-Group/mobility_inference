import pymc as pm
import numpy as np
import pandas as pd

# import matplotlib.pyplot as plt
import arviz as az
import pickle

# from scipy import stats
import pytensor.tensor as at
import xarray as xr

import covid19_inference.covid19_inference as cov19
import utils

# increase plt fontsize
# plt.rcParams.update({'font.size': 20})
# from matplotlib import lines, patches


# Data
## Out of home duration
path_mobility = "data/mobility/mobilityData_OverviewBL_weekly.csv"
mobility_df = pd.read_csv(path_mobility, parse_dates=True, index_col=0, delimiter=";")
mobility_df = mobility_df[mobility_df["BundeslandID"] == "Deutschland"]
mobility_df["week"] = mobility_df.index.isocalendar().week

### get dates
mobility_dates = mobility_df.index.values
mobility_dates_2020 = mobility_dates[mobility_dates < np.datetime64("2020-12-20")]
mobility_dates_2020 = mobility_dates_2020[
    mobility_dates_2020 > np.datetime64("2020-03-29")
]
mobility_dates_2022 = mobility_dates[mobility_dates < np.datetime64("2022-12-20")]
mobility_dates_2022_shortened = mobility_dates_2022[-len(mobility_dates_2020) :]

### get out of home duration data
mobility_df_2020 = mobility_df.filter(items=mobility_dates_2020, axis=0)
mobility_data_2020 = mobility_df_2020["outOfHomeDuration"].to_xarray()

baseline_mobility_df = pd.read_csv(
    "data/mobility/baseline_mobility.csv", parse_dates=True, index_col=0
)
baseline_mobility_df = baseline_mobility_df.filter(
    items=mobility_dates_2022_shortened, axis=0
)
## replace index by mobility_dates_2020
baseline_mobility_df.index = mobility_dates_2020
## rename index to "date"
baseline_mobility_df.index.name = "date"
baseline_mobility = baseline_mobility_df["outOfHomeDuration"].to_xarray()

## R
path_R = "data/R/Germany/R_eff_Germany.csv"
R_df = pd.read_csv(path_R, index_col=1, parse_dates=True)

### weekly average placed on Sunday
df = utils.weekly_formatting(R_df, mobility_dates_2020)
df = utils.transform_data(df["R_eff median"])
R_data = df.to_xarray()

## NPI
stay_at_home_2020 = utils.get_NPI_data(
    "data/NPIs/stay-at-home-covid.csv", mobility_dates_2020
)
stay_at_home_2020 = utils.transform_data(stay_at_home_2020)
stay_at_home_2020 = stay_at_home_2020["stay_home_requirements"].to_xarray()

## Temperature
weather_df = pd.read_csv(
    "data/weather/weatherData2020and2022.csv", parse_dates=True, index_col=0
)

### filter for mobility_dates_2020
weather_df_2020 = weather_df[weather_df.index.isin(mobility_dates_2020)]
weather_df_2022 = weather_df[weather_df.index.isin(mobility_dates_2022_shortened)]

### calculate differences between the years
delta_tmax = utils.return_differences(weather_df_2020, weather_df_2022, "tmax")
delta_tmax = xr.DataArray(
    delta_tmax, dims="date", coords={"date": mobility_dates_2020}, name="delta_tmax"
)

### calculate average between the years
average_tmax = utils.return_averages(weather_df_2020, weather_df_2022, "tmax")
average_tmax = xr.DataArray(
    average_tmax, dims="date", coords={"date": mobility_dates_2020}, name="average_tmax"
)

# Model
R_model = pm.Model()
utils.single_indicator_model(
    R_data,
    R_model,
    baseline_mobility,
    mobility_data_2020,
    stay_at_home_2020,
    delta_tmax,
    average_tmax,
)

# Inference
R_trace = pm.sample(model=R_model, draws=100, tune=100, cores=1, chains=2)
with R_model:
    pm.compute_log_likelihood(R_trace)

# Save the trace
path = f"results/raw/trace_{tag}.pickle"
with open(path, "wb") as inference_file:
    pickle.dump(R_trace, inference_file)
