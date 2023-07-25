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
    # from 22.10.20 to 01.11.20 it is still just a recommendation not a requirement
    # (see https://github.com/OxCGRT/covid-policy-dataset/blob/main/data/OxCGRT_fullwithnotes_national_2020_v1.csv)
    # set all values between dates "2020-10-22" and "2020-11-01" to 1
    df.loc["2020-10-22":"2020-11-01", "stay_home_requirements"] = 1
    df = weekly_formatting(df, dates_in)
    return df


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


def generate_Tstar(amplitude, offset, shift, length):
    x = at.linspace(0, length, length)
    return pm.Deterministic("T_star", -at.power(amplitude * (x + shift), 4.0) + offset)


# function for modulating the impact of temperature
def Gaussian(T, T_star, a):
    return pm.Deterministic("r", at.exp(-a * at.power(T - T_star, 2.0)))


# model
def create_model(
    model_in,
    base_mobility_data_in,
    observed_mobility_data_in,
    NPI_data_in,
    del_weather_data_in,
    avg_weather_data_in,
    indicators_in,
    disease_data_in,
):
    # Gaussian = np.vectorize(Gaussian)
    len_data = observed_mobility_data_in.shape[0]
    with model_in:
        # define data
        m_base_data = pm.ConstantData("m_base", base_mobility_data_in)
        NPI_data = pm.ConstantData("NPI_data", NPI_data_in)
        delta_weather = pm.ConstantData("delta_weather", del_weather_data_in)
        avg_weather = pm.ConstantData("avg_weather", avg_weather_data_in)

        # meta-parameters for the convolution function (delay_cases)
        model_in.diff_data_sim = (
            0  # we are only interested in the reported cases, so no delay
        )
        model_in.sim_len = len_data - model_in.diff_data_sim

        m = m_base_data

        # impact of disease spread
        mu_z_prior = 0.9 ** len(indicators_in)
        for indicator in indicators_in:
            disease_data = pm.ConstantData(indicator, disease_data_in[indicator])

            ## define priors
            factor_disease = pm.LogNormal(
                f"z_{indicator}", mu=np.log(mu_z_prior), tau=10
            )
            mu_disease = pm.LogNormal(f"mu_{indicator}", mu=np.log(1.0), tau=10)
            sigma_disease = pm.LogNormal(f"sigma_{indicator}", mu=np.log(1.0), tau=10)
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
            d = pm.Deterministic(f"d_{indicator}", at.exp(exponent))
            m = m * d

        # impact of NPI
        ## define priors
        factor_NPI = pm.LogNormal("z_S", mu=np.log(0.9), tau=10)
        ## put it together
        exponent = -factor_NPI * NPI_data
        s = pm.Deterministic("s", at.exp(exponent))

        # impact of weather: maximum temperature
        factor_weather = pm.LogNormal("z_T", mu=np.log(0.01), tau=1)
        ## Gaussian to model the impact of optimal absolute temperature
        amplitude = pm.LogNormal("amplitude", mu=np.log(0.08), tau=5)
        offset = pm.Normal("offset", mu=25, sigma=2)
        shift = pm.Normal("shift", mu=-20, sigma=2)
        T_star = generate_Tstar(
            amplitude=amplitude,
            offset=offset,
            shift=shift,
            length=len_data,
        )
        a_r = pm.LogNormal("a_r", mu=np.log(0.01), tau=1)
        weather_relevance = Gaussian(avg_weather, T_star, a_r)
        w = pm.Deterministic(
            "w", at.exp(delta_weather * weather_relevance * factor_weather)
        )

        # define likelihood
        m = pm.Deterministic("m", m * s * w)
        model_error = pm.HalfCauchy("sigma_model", beta=0.5)
        likelihood = pm.Normal(
            "likelihood", mu=m, sigma=model_error, observed=observed_mobility_data_in
        )


"""
# model
def create_model(
    model_in,
    base_mobility_data_in,
    observed_mobility_data_in,
    NPI_data_in,
    del_weather_data_in,
    avg_weather_data_in,
    indicators_in,
    disease_data_in,
):
    # Gaussian = np.vectorize(Gaussian)
    len_data = observed_mobility_data_in.shape[0]
    with model_in:
        # define data
        m_base_data = pm.ConstantData("m_base", base_mobility_data_in)
        NPI_data = pm.ConstantData("NPI_data", NPI_data_in)
        delta_weather = pm.ConstantData("delta_weather", del_weather_data_in)
        avg_weather = pm.ConstantData("avg_weather", avg_weather_data_in)

        # meta-parameters for the convolution function (delay_cases)
        model_in.diff_data_sim = (
            0  # we are only interested in the reported cases, so no delay
        )
        model_in.sim_len = len_data - model_in.diff_data_sim

        m = m_base_data

        # impact of disease spread
        for indicator in indicators_in:
            disease_data = pm.ConstantData(indicator, disease_data_in[indicator])

            ## define priors
            factor_disease = pm.LogNormal(f"z_{indicator}", mu=np.log(0.9), tau=10)
            mu_disease = pm.LogNormal(f"mu_{indicator}", mu=np.log(1.0), tau=10)
            sigma_disease = pm.LogNormal(f"sigma_{indicator}", mu=np.log(1.0), tau=10)
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
            d = pm.Deterministic(f"d_{indicator}", at.exp(exponent))
            m = m * d

        # impact of NPI
        ## define priors
        factor_NPI = pm.LogNormal("z_S", mu=np.log(0.9), tau=10)
        ## put it together
        exponent = -factor_NPI * NPI_data
        s = pm.Deterministic("s", at.exp(exponent))

        # impact of weather: maximum temperature
        factor_weather = pm.LogNormal("z_T", mu=np.log(0.01), tau=1)
        ## Gaussian to model the impact of optimal absolute temperature
        amplitude = pm.LogNormal("amplitude", mu=np.log(0.08), tau=5)
        offset = pm.Normal("offset", mu=25, sigma=2)
        shift = pm.Normal("shift", mu=-20, sigma=2)
        T_star = generate_Tstar(
            amplitude=amplitude,
            offset=offset,
            shift=shift,
            length=len_data,
        )
        a_r = pm.LogNormal("a_r", mu=np.log(0.01), tau=1)
        weather_relevance = Gaussian(avg_weather, T_star, a_r)
        w = pm.Deterministic(
            "w", at.exp(delta_weather * weather_relevance * factor_weather)
        )

        # define likelihood
        m = pm.Deterministic("m", m * s * w)
        model_error = pm.HalfCauchy("sigma_model", beta=0.5)
        likelihood = pm.Normal(
            "likelihood", mu=m, sigma=model_error, observed=observed_mobility_data_in
        )

"""
