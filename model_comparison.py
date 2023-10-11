import numpy as np
import pandas as pd


def approximate_probability_density(inference_model, trace, M, n_samples=200):
    # Calculate the log probability densities of the unobserved data given the inferred parameters
    log_likelihood_func_tmp = inference_model.compile_logp(vars=inference_model.free_RVs[-1], sum=False)
    
    log_likelihood = []
    for chain in range(4):
        for draw in range(n_samples):
            # collect inferred parameters / variables
            variables = trace.posterior.isel(chain=chain, draw=draw).items()
            relevant_vars = inference_model.continuous_value_vars
            var_dict = {key: var for key, var in variables if key in map(str, relevant_vars)}

            log_p_density = log_likelihood_func_tmp(var_dict)[0]
            log_likelihood.append(log_p_density)

    # Take sum from i+1 to i+M per sample to get relevant logp density
    relevant_logp = []
    for sample in log_likelihood:
        relevant_logp.append(np.sum(sample[:M]))

    # Take exp to get probability density per sample
    probabilities = np.exp(relevant_logp)

    return np.mean(probabilities)


def calculate_ELPD(models_in, traces_in, L_in, M_in, N_in, draws_in):
    ELPDs = {}
    sum = 0
    # sum over log probability densities of all 'predictions'
    for i in range(L_in-1, N_in - M_in):
        prob = approximate_probability_density(models_in[i], traces_in[i], M_in, n_samples=draws_in)
        component = np.log(prob)
        ELPDs[i] = component
        sum += component

    mean = sum / (N_in - M_in - L_in + 1)
    return mean, sum, ELPDs


def save_ELPD(inference_model, traces, L, M, N, dir_name, draws, method_tag):
    # save ELPD results to file
    mean_ELPD, sum_ELPD, ELPD_components = calculate_ELPD(inference_model, traces, L, M, N, draws)
    ELPD_components["sum"] = sum_ELPD
    ELPD_components["mean"] = mean_ELPD
    ELPD_df = pd.DataFrame.from_dict(ELPD_components, orient="index")
    ELPD_df.columns = ["ELPD"]
    ELPD_df.to_csv(dir_name + f"/ELPD_{method_tag}.csv")


def read_ELPD(name_in, indicator_tag_in, method_tag_in):
    path = f"results/{name_in}/{indicator_tag_in}/ELPD_{method_tag_in}.csv"
    ELPD_df = pd.read_csv(path, index_col=0)
    return ELPD_df


def SE_ELPD(differences_in, L, M, N): 
    factor = (N-M-L+1) / (N-M-L)

    summ = 0
    for i in range(L-1, N-M):
        difference = float(differences_in.loc[str(i)])
        summ += (difference - float(differences_in.loc["mean"]))**2

    return np.sqrt(factor * summ)


def calculate_ELPD_differences(label1_in, label2_in, M, indicator1="", indicator2=""):
    ELPD1 = read_ELPD(label1_in, indicator1)
    ELPD2 = read_ELPD(label2_in, indicator2)
    ELPD_differences = ELPD1 - ELPD2
    mean = float(ELPD_differences.loc["mean"])
    SE = SE_ELPD(ELPD_differences, M=M)
    sum = float(ELPD_differences.loc["sum"])
    return mean, SE, sum, ELPD_differences
    