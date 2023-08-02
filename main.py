import pymc as pm
import os
import pickle
import shutil

import model
import data_prep


indicators = ["R"]
name = "test"

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
shutil.copyfile("main.py", f"{dir_name}/main.py")
shutil.copyfile("model.py", f"{dir_name}/model.py")
shutil.copyfile("data_prep.py", f"{dir_name}/data_prep.py")

# Data
## Out of home duration
o_2020, o_base, dates_2020, dates_2022 = data_prep.get_out_of_home_duration()

## Kurzarbeit
kurzarbeit = data_prep.get_kurzarbeit(dates_2020, dates_2022)

## R
if "R" in indicators:
    disease_data["R"] = data_prep.get_R(dates_2020)

## OWID
if "ICU" in indicators or "C" in indicators or "H" in indicators:
    owid = data_prep.get_owid()

### cases
if "C" in indicators:
    disease_data["C"] = data_prep.get_C(owid, dates_2020)

### ICU
if "ICU" in indicators:
    disease_data["ICU"] = data_prep.get_ICU(owid, dates_2020)

### hospitalisations
if "H" in indicators:
    disease_data["H"] = data_prep.get_H(owid, dates_2020)

## NPI
### stay at home orders
stay_at_home_2020 = data_prep.get_S(dates_2020)
### school closures
schook_closures_2020 = data_prep.get_school_closures(dates_2020)

## Weather
# to do later

# Model
inference_model = pm.Model()
model.create_model(
    inference_model,
    o_base,
    o_2020,
    stay_at_home_2020,
    schook_closures_2020,
    kurzarbeit,
    indicators,
    disease_data,
)

# Inference
trace = pm.sample(model=inference_model, draws=200, tune=200, cores=1, chains=2)
with inference_model:
    pm.compute_log_likelihood(trace)

# Save the trace
path = f"{dir_name}/trace_{tag}.pickle"
with open(path, "wb") as inference_file:
    pickle.dump(trace, inference_file)
