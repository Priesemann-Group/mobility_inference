import pymc as pm
import numpy as np
import pandas as pd
import os
import pickle
import shutil
import xarray as xr

import covid19_inference.covid19_inference as cov19
import utils
import model


indicators = ["C"]
name = "kurzarbeit"

disease_data = {}

# for saving the results
tags = ""
for indicator in indicators:
    tags += indicator + "_"
tag = tags + name
# We create a directory for the results.
dir_name = "results/" + tag
## We create the target directory if it does not exist yet
if not os.path.exists(dir_name):
    os.mkdir(dir_name)
    print("Directory ", dir_name, " created.")
else:
    print("Directory ", dir_name, " already exists.")

# To know for every result how it was produced, we copy this source code into the results directory.
shutil.copyfile("model.py", f"{dir_name}/code_for_{tag}.py")
shutil.copyfile("utils.py", f"{dir_name}/utils_for_{tag}.py")

# Data
## Out of home duration
path_mobility = "data/mobility/mobilityData_OverviewBL_weekly.csv"
mobility_df = pd.read_csv(path_mobility, parse_dates=True, index_col=0, delimiter=";")
mobility_df = mobility_df[mobility_df["BundeslandID"] == "Deutschland"]
mobility_df["week"] = mobility_df.index.isocalendar().week

### get dates
mobility_dates = mobility_df.index.values
dates_2020 = mobility_dates[mobility_dates < np.datetime64("2020-12-20")]
mobility_dates_2020 = dates_2020[dates_2020 > np.datetime64("2020-03-29")]
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


## Kurzarbeit
df = pd.read_csv("data/kurzarbeit.csv", sep=";")
df["year"] = df["Berichtsmonat"].str[-4:]
df["month"] = df["Berichtsmonat"].str[:-5]

### turn month names into numbers with german_month_to_num function
df["month"] = df["month"].apply(utils.german_month_to_num)

df_kurzarbeit_2020 = utils.get_weekly_kurzarbeit(df, mobility_dates_2020, "2020")
df_kurzarbeit_2022 = utils.get_weekly_kurzarbeit(
    df, mobility_dates_2022_shortened, "2022"
)

### get difference between 2020 and 2022 as fraction of population
population = 83237124
KA_2020 = df_kurzarbeit_2020["Anzahl Kurzarbeitende"].values
KA_2022 = df_kurzarbeit_2022["Anzahl Kurzarbeitende"].values
KA_diff = (KA_2020 - KA_2022) / population

### make xarray of KA_diff with mobility_dates_2020 as index
KA_diff_xr = xr.DataArray(KA_diff, coords=[mobility_dates_2020], dims=["date"])


## R
if "R" in indicators:
    path_R = "data/R/Germany/R_eff_Germany.csv"
    R_df = pd.read_csv(path_R, index_col=1, parse_dates=True)

    ### weekly average placed on Sunday
    df = utils.weekly_formatting(R_df, mobility_dates_2020)
    df = utils.transform_data(df["R_eff median"])
    R_data = df.to_xarray()
    disease_data["R"] = R_data

## OWID
if "ICU" in indicators or "C" in indicators or "H" in indicators:
    cov19.data_retrieval.set_data_dir("/data.nst/eiftekhar/covid19/")
    owid = cov19.data_retrieval.OWD()
    owid.download_all_available_data()

### cases
if "C" in indicators:
    case_data = owid._filter(
        value="new_cases_smoothed_per_million",
        country="Germany",
    )
    case_data = utils.weekly_formatting(case_data, mobility_dates_2020)
    case_data = utils.transform_data(case_data).to_xarray()
    disease_data["C"] = case_data

### ICU
if "ICU" in indicators:
    ICU_data = owid._filter(
        value="icu_patients_per_million",
        country="Germany",
    )
    ICU_data = utils.weekly_formatting(ICU_data, mobility_dates_2020)
    ICU_data = utils.transform_data(ICU_data).to_xarray()
    disease_data["ICU"] = ICU_data

### hospitalisations
if "H" in indicators:
    H_data = owid._filter(
        value="weekly_hosp_admissions_per_million",
        country="Germany",
    )
    H_data = utils.weekly_formatting(H_data, mobility_dates_2020)
    H_data = utils.transform_data(H_data).to_xarray()
    disease_data["H"] = H_data

## NPI
stay_at_home_2020 = utils.get_NPI_data(
    "data/NPIs/stay-at-home-covid.csv", mobility_dates_2020
)
stay_at_home_2020 = utils.transform_data(stay_at_home_2020)
stay_at_home_2020 = stay_at_home_2020["stay_home_requirements"].to_xarray()

## Weather
weather_df = pd.read_csv(
    "data/weather/weatherData2020and2022.csv", parse_dates=True, index_col=0
)

### filter for mobility_dates_2020
weather_df_2020 = weather_df[weather_df.index.isin(mobility_dates_2020)]
weather_df_2022 = weather_df[weather_df.index.isin(mobility_dates_2022_shortened)]

### calculate differences between the years
#### temperature
# delta_tmax = utils.return_differences(weather_df_2020, weather_df_2022, "tmax")
# delta_tmax = xr.DataArray(
#     delta_tmax, dims="date", coords={"date": mobility_dates_2020}, name="delta_tmax"
# )
#### precipitation
delta_prcp = utils.return_differences(weather_df_2020, weather_df_2022, "prcp")
delta_prcp = xr.DataArray(
    delta_prcp, dims="date", coords={"date": mobility_dates_2020}, name="delta_prcp"
)

### calculate average between the years
#### temperature
# average_tmax = utils.return_averages(weather_df_2020, weather_df_2022, "tmax")
# average_tmax = xr.DataArray(
#     average_tmax, dims="date", coords={"date": mobility_dates_2020}, name="average_tmax"
# )

# Model
inference_model = pm.Model()
model.create_model(
    inference_model,
    baseline_mobility,
    mobility_data_2020,
    stay_at_home_2020,
    KA_diff_xr,
    indicators,
    disease_data,
    delta_prcp,
)

# Inference
trace = pm.sample(model=inference_model, draws=200, tune=200, cores=1, chains=2)
with inference_model:
    pm.compute_log_likelihood(trace)

# Save the trace
path = f"{dir_name}/trace_{tag}.pickle"
with open(path, "wb") as inference_file:
    pickle.dump(trace, inference_file)
