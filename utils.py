import pickle
import itertools


# create list of indicator combinations
def indicator_combinations(base_indicators=["C", "R", "ICU", "H"]):
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
