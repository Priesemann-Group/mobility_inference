import numpy as np
import scipy.stats as stats
import pandas as pd
import pymc as pm
import pytensor.tensor as at

import covid19_inference.covid19_inference as cov19


def _cut_off_before_monday(df):
    while df.index[0].dayofweek != 0:
        df = df[1:]
    return df


# weekly average placed on Sunday
def weekly_formatting(df_in, dates_in):
    df = _cut_off_before_monday(df_in)
    df = df.resample("7D").mean()
    df.index = df.index + pd.Timedelta(days=6)
    return df.filter(items=dates_in, axis=0)


# transform data: logistic of z-score
def transform_data(df_in):
    df = stats.zscore(df_in)
    return 1 / (1 + np.exp(-df))


def get_NPI_data(filename_in, dates_in):
    df = pd.read_csv(filename_in, index_col=2, parse_dates=True)
    df = df[df["Entity"] == "Germany"]
    return weekly_formatting(df, dates_in)


# calculate differences between the years
def return_differences(df2020_in, df2022_in, label_in):
    delta = df2020_in[label_in].values - df2022_in[label_in].values
    if label_in == "prcp":
        delta = -delta
    return delta


# calculate average between the years
def return_averages(df1_in, df2_in, label_in):
    average = (df1_in[label_in].values + df2_in[label_in].values) / 2
    return average


# 'optimal' temperature
def generate_Tstar(amplitude, scale, offset, shift, length):
    x = at.linspace(0, length, length)
    return amplitude * at.sin(at.cos(scale * x + shift)) + offset


# function for modulating the impact of temperature
def Gaussian(T, T_star):
    return at.exp(-at.power(T - T_star, 2.0))


# single indicator model
def single_indicator_model(
    data_in,
    model_in,
    base_mobility_data_in,
    observed_mobility_data_in,
    NPI_data_in,
    del_weather_data_in,
    avg_weather_data_in,
    data_str_in="disease_data",
    factor_str_in="z",
    mu_str_in="mu",
    sigma_str_in="sigma",
    d_str_in="d",
    m_str_in="m",
):
    Gaussian = np.vectorize(Gaussian)
    len_data = data_in.shape[0]
    with model_in:
        # define data
        m_base_data = pm.ConstantData("m_base", base_mobility_data_in)
        disease_data = pm.ConstantData(data_str_in, data_in)
        NPI_data = pm.ConstantData("NPI_data", NPI_data_in)
        delta_weather = pm.ConstantData("delta_weather", del_weather_data_in)
        avg_weather = pm.ConstantData("avg_weather", avg_weather_data_in)

        # define hyper-parameters
        mu_factor = 0.2
        sigma_factor = 0.05
        mu_mu = 1.0
        sigma_mu = 0.2
        mu_sigma = 0.3
        sigma_sigma = 0.1

        # meta-parameters for the convolution function (delay_cases)
        model_in.diff_data_sim = (
            0  # we are only interested in the reported cases, so no delay
        )
        model_in.sim_len = len_data - model_in.diff_data_sim

        # impact of disease spread
        ## define priors
        factor_disease = pm.Normal(factor_str_in, mu=mu_factor, sigma=sigma_factor)
        mu_disease = pm.LogNormal(mu_str_in, mu=mu_mu, sigma=sigma_mu)
        sigma_disease = pm.LogNormal(sigma_str_in, mu=mu_sigma, sigma=sigma_sigma)
        ## convolution
        risk = cov19.model.delay_cases(
            cases=disease_data,
            delay_kernel="gamma",
            median_delay=mu_disease,
            scale_delay=sigma_disease,
            len_input_arr=len_data,
            len_output_arr=model_in.sim_len,
        )
        ## put it together
        exponent = -factor_disease * risk
        d = pm.Deterministic(d_str_in, at.exp(exponent))

        # impact of NPI
        ## define priors
        factor_NPI = pm.Normal("z_NPI", mu=mu_factor, sigma=sigma_factor)
        mu_NPI = pm.LogNormal("mu_NPI", mu=mu_mu, sigma=sigma_mu)
        sigma_NPI = pm.LogNormal("sigma_NPI", mu=mu_sigma, sigma=sigma_sigma)
        ## convolution
        risk = cov19.model.delay_cases(
            cases=NPI_data,
            delay_kernel="gamma",
            median_delay=mu_NPI,
            scale_delay=sigma_NPI,
            len_input_arr=len_data,
            len_output_arr=model_in.sim_len,
        )
        ## put it together
        exponent = -factor_NPI * risk
        s = pm.Deterministic("s", at.exp(exponent))

        # impact of weather: maximum temperature
        factor_weather = pm.LogNormal("z_weather", mu=10, sigma=2)
        ## Gaussian to model the impact of optimal absolute temperature
        amplitude = pm.Normal("amplitude", mu=19, sigma=2)
        scale = pm.Normal("scale", mu=0.07, sigma=0.01)
        offset = pm.Normal("offset", mu=10, sigma=2)
        shift = pm.Normal("shift", mu=5, sigma=1)
        T_star = generate_Tstar(
            amplitude=amplitude,
            scale=scale,
            offset=offset,
            shift=shift,
            length=len_data,
        )
        weather_relevance = Gaussian(avg_weather, T_star)
        w = pm.Deterministic(
            "W", at.exp(delta_weather * weather_relevance / factor_weather)
        )

        # define likelihood
        m = pm.Deterministic(m_str_in, m_base_data * d * s * w)
        model_error = pm.HalfCauchy("sigma_model", beta=0.5)
        likelihood = pm.Normal(
            "likelihood", mu=m, sigma=model_error, observed=observed_mobility_data_in
        )
