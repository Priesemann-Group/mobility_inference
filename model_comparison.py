import numpy as np

def approximate_probability_density(inference_model, trace, L, M, N_in, n_samples=500):
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
    # Take sum from L+1 to L+M per sample to get relevant logp density
    relevant_logp = []
    for ls in log_likelihood:
        sample = ls[0]
        relevant_logp.append(np.sum(sample[L+1:L+M]))

    # Take exp to get probability density per sample
    probabilities = np.exp(relevant_logp)

    # Take average over samples
    return np.mean(probabilities)

def calculate_ELPD_LFO(model_in, traces_in, L_in, M_in, N_in):
    sum = 0
    # sum over log probability densities of all 'predictions'
    for i in range(L_in, N_in - M_in):
        trace = traces_in[i]
        prob = approximate_probability_density(model_in, trace, L_in, M_in, N_in, n_samples=200)
        sum += np.log(prob)
    return sum

def save_ELPD_LFO(inference_model, traces, L, M, N, dir_name):
    ELPD = calculate_ELPD_LFO(inference_model, traces, L, M, N)
    # save ELPD result to file
    path = f"{dir_name}/ELPD.csv"
    with open(path, "w") as f:
        f.write(str(ELPD))