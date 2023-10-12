import numpy as np
import pandas as pd


def approximate_probability_density(inference_model, trace, M, n_samples=200):
    """ Approximate the probability density of the unobserved data given the inferred parameters

    Args:
        inference_model: Inference model object
        trace: Trace object
        M: Number of time points to predict
        n_samples: Number of samples to draw from the posterior (chain)
    
    Returns:
        np.array of mean probability density
    """
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
    """ Calculate the expected log pointwise predictive density (ELPD) for a given model and trace

    Args:
        models_in: Dictionary of inference models
        traces_in: Dictionary of traces
        L_in: Minimum number of training data points
        M_in: Number of data points to predict
        N_in: Total number of data points
        draws_in: Number of samples to draw from the posterior (chain)

    Returns:
        mean: Mean term-wise ELPD
        sum: Sum of term-wise ELPD
        ELPDs: Dictionary of ELPD terms
    """
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
    """ Save ELPD results to file

    Args:
        inference_model: Inference model object
        traces: Dictionary of traces
        L: Minimum number of training data points
        M: Number of data points to predict
        N: Total number of data points
        dir_name: Directory name
        draws: Number of samples to draw from the posterior (chain)
        method_tag: Tag for method used to calculate ELPD
    
    Returns:
        None
    """
    mean_ELPD, sum_ELPD, ELPD_components = calculate_ELPD(inference_model, traces, L, M, N, draws)
    ELPD_components["sum"] = sum_ELPD
    ELPD_components["mean"] = mean_ELPD
    ELPD_df = pd.DataFrame.from_dict(ELPD_components, orient="index")
    ELPD_df.columns = ["ELPD"]
    ELPD_df.to_csv(dir_name + f"/ELPD_{method_tag}.csv")


def read_ELPD(name_in, indicator_tag_in, method_tag_in):
    """ Read ELPD results from file

    Args:
        name_in: Name of directory
        indicator_tag_in: Tag for indicator
        method_tag_in: Tag for method used to calculate ELPD
    
    Returns:
        pd.DataFrame of ELPD results
    """
    path = f"results/{name_in}/{indicator_tag_in}/ELPD_{method_tag_in}.csv"
    ELPD_df = pd.read_csv(path, index_col=0)
    return ELPD_df


def SE_ELPD(differences_in, L, M, N): 
    """ Calculate standard error of ELPD differences
    
    Args:
        differences_in: pd.DataFrame of ELPD differences
        L: Minimum number of training data points
        M: Number of data points to predict
        N: Total number of data points
    
    Returns:
        Standard error of ELPD differences
    """
    factor = (N-M-L+1) / (N-M-L)

    summ = 0
    for i in range(L-1, N-M):
        difference = float(differences_in.loc[str(i)])
        summ += (difference - float(differences_in.loc["mean"]))**2

    return np.sqrt(factor * summ)


def calculate_ELPD_differences(label1_in, label2_in, method_tag_in, L, M, N, indicator1="", indicator2=""):
    """ Calculate ELPD differences between two models

    Args:
        label1_in: Name of directory for first model
        label2_in: Name of directory for second model
        method_tag_in: Tag for method used to calculate ELPD
        L: Minimum number of training data points
        M: Number of data points to predict
        N: Total number of data points
        indicator1: Tag for indicators of first model
        indicator2: Tag for indicators of second model
    
    Returns:
        mean: Mean term-wise ELPD difference
        SE: Standard error of term-wise ELPD difference
        sum: Sum of term-wise ELPD difference
        ELPD_differences: pd.DataFrame of ELPD differences
    """

    ELPD1 = read_ELPD(label1_in, indicator1, method_tag_in)
    ELPD2 = read_ELPD(label2_in, indicator2, method_tag_in)
    ELPD_differences = ELPD1 - ELPD2
    mean = float(ELPD_differences.loc["mean"])
    SE = SE_ELPD(ELPD_differences, L, M, N)
    sum = float(ELPD_differences.loc["sum"])
    return mean, SE, sum, ELPD_differences
    