import numpy as np
import pandas as pd

def approximate_probability_density(inference_model, trace, i_in, M, N_in, n_samples=200):
    # Calculate the log probability densities of the data given the inferred parameters
    log_likelihood_func_tmp = inference_model.compile_logp(vars=inference_model.free_RVs[:-1]+inference_model.observed_RVs, sum=False)
    ## Only get log p function for observed variables
    log_likelihood_func = lambda x: log_likelihood_func_tmp(x)[len(inference_model.free_RVs)-1:len(inference_model.free_RVs)-1+N_in]

    log_likelihood = []
    for chain in range(1):
        for draw in range(n_samples):
            variables = trace.posterior.isel(chain=chain, draw=draw).items()
            relevant_vars = inference_model.continuous_value_vars[:-1]
            var_dict = {key: var for key, var in variables if key in map(str, relevant_vars)}
            log_likelihood.append(log_likelihood_func(var_dict))

    # Take sum from i+1 to i+M per sample to get relevant logp density
    relevant_logp = []
    for ls in log_likelihood:
        sample = ls[0]
        relevant_logp.append(np.sum(sample[i_in:i_in+M]))

    # Take exp to get probability density per sample
    probabilities = np.exp(relevant_logp)

    return np.mean(probabilities)


def calculate_ELPD_LFO(model_in, traces_in, L_in, M_in, N_in):
    ELPDs = {}
    sum = 0
    # sum over log probability densities of all 'predictions'
    for i in range(L_in, N_in - M_in):
        trace = traces_in[i]
        prob = approximate_probability_density(model_in, trace, i, M_in, N_in, n_samples=1000)
        component = np.log(prob)
        ELPDs[i] = component
        sum += component

    return sum, ELPDs


def save_ELPD_LFO(inference_model, traces, L, M, N, dir_name):
    # save ELPD results to file
    mean_ELPD, ELPD_components = calculate_ELPD_LFO(inference_model, traces, L, M, N)
    ELPD_components["mean"] = mean_ELPD
    ELPD_df = pd.DataFrame.from_dict(ELPD_components, orient="index")
    ELPD_df.columns = ["ELPD_LFO"]
    ELPD_df.to_csv(dir_name + "/ELPD_LFO.csv")