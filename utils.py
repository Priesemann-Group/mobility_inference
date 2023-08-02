import pickle


# load trace from file
def load_trace(tag_in):
    path = f"results/{tag_in}/trace_{tag_in}.pickle"
    with open(path, "rb") as inference_file:
        trace = pickle.load(inference_file)
    return trace
