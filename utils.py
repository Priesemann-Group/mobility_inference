import pickle
import itertools
import os


# create list of indicator combinations
def indicator_combinations(base_indicators=["R", "C", "H", "ICU", "D"], limit=5):
    """Creates a list of all possible combinations of indicators.

    Parameters:
        base_indicators (list): list of indicators to combine
        limit (int): maximum number of indicators in a combination
    Returns:
        list: list of all possible combinations of indicators"""
    all_combinations = []
    for L in range(len(base_indicators) + 1):
        for subset in itertools.combinations(base_indicators, L):
            if len(subset) <= limit:
                all_combinations.append(subset)
    return all_combinations[1:]


# load trace from file
def load_trace(tag_in, indicator_str_in, dir_str_in=None):
    """Loads a trace from a pickle file.

    Parameters:
        tag_in (str): tag of the model
        indicator_str_in (str): string of indicators
    Returns:
        trace: trace of the model"""
    if dir_str_in is None:
        path = f"results/{tag_in}/trace_{indicator_str_in}.pickle"
    else:
        path = f"results/{tag_in}/{dir_str_in}/trace_{indicator_str_in}.pickle"
    with open(path, "rb") as inference_file:
        trace = pickle.load(inference_file)
    return trace


# make directory
def make_dir(dir_name_in):
    """Creates a directory if it does not exist yet.

    Parameters:
        dir_name_in (str): name of the directory
    Returns:
        None"""
    # We create the target directory if it does not exist yet.
    if not os.path.exists(dir_name_in):
        os.mkdir(dir_name_in)
        print("Directory ", dir_name_in, " created.")
    else:
        print("Directory ", dir_name_in, " already exists.")
