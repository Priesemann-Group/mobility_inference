import pickle
import itertools
import os


# create list of indicator combinations
def indicator_combinations(base_indicators=["R", "C", "H", "ICU"]):
    all_combinations = []
    for L in range(len(base_indicators) + 1):
        for subset in itertools.combinations(base_indicators, L):
            all_combinations.append(subset)
    return all_combinations[1:]


# load trace from file
def load_trace(tag_in, indicator_str_in):
    path = f"results/{tag_in}/{indicator_str_in}/trace_{indicator_str_in}.pickle"
    with open(path, "rb") as inference_file:
        trace = pickle.load(inference_file)
    return trace


# make directory
def make_dir(dir_name_in):
    # We create the target directory if it does not exist yet.
    if not os.path.exists(dir_name_in):
        os.mkdir(dir_name_in)
        print("Directory ", dir_name_in, " created.")
    else:
        print("Directory ", dir_name_in, " already exists.")
