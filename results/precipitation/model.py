import numpy as np
import pymc as pm
import pytensor.tensor as at
import xarray as xr

import covid19_inference.covid19_inference as cov19
import data_prep


# For the weather
def generate_Tstar(amplitude, offset, shift, length):
    x = at.linspace(0, length, length)
    return pm.Deterministic("T_star", -at.power(amplitude * (x + shift), 4.0) + offset)


## function for modulating the impact of temperature
def Gaussian(T, T_star, a):
    return pm.Deterministic("rho", at.exp(-a * at.power(T - T_star, 2.0)))


def temperature_factor(len_data_in, temperature_in):
    # data
    delta_T = pm.ConstantData("delta_T", temperature_in["delta"])
    avg_T = pm.ConstantData("avg_T", temperature_in["average"])

    # impact of weather: maximum temperature
    factor_weather = pm.LogNormal("z_T", mu=np.log(0.01), tau=1)
    ## Gaussian to model the impact of optimal absolute temperature
    amplitude = pm.LogNormal("amplitude", mu=np.log(0.08), tau=20)
    offset = pm.Normal("offset", mu=25, sigma=2)
    shift = pm.Normal("shift", mu=-20, sigma=2)
    T_star = generate_Tstar(
        amplitude=amplitude,
        offset=offset,
        shift=shift,
        length=len_data_in,
    )
    a_r = pm.LogNormal("a_rho", mu=np.log(0.01), tau=1)
    weather_relevance = Gaussian(avg_T, T_star, a_r)
    w = pm.Deterministic("theta", at.exp(delta_T * weather_relevance * factor_weather))

    return w


def precipitation_factor(delta_prcp_in):
    delta_prcp = pm.ConstantData("delta_prcp", delta_prcp_in)
    z_P = pm.LogNormal("z_P", mu=np.log(0.05), tau=0.5)
    w = pm.Deterministic("p", at.exp(-z_P * delta_prcp))
    return w


# impact of pandemic fatigue: linear version
def pandemic_fatigue_factor_linear(len_in):
    x = at.linspace(0, len_in, len_in)
    max_x = len_in - 1
    ## pandemic fatigue at the start
    p0 = pm.LogNormal("f0", mu=np.log(1.01), tau=20)
    ## pandemic fatigue rate
    r = pm.TruncatedNormal("r", mu=0.2 / max_x, sigma=0.01 / max_x, lower=-p0 / max_x)
    ## pandemic fatigue
    p = pm.Deterministic("f", p0 + r * x)
    return p


def sigmoid(x, del_t, del_y, v_change, p0=1):
    return del_y / (1 + at.exp(-v_change * (x + del_t))) + p0


# imapct of pandemic fatigue: sigmoid version
def pandemic_fatigue_factor_sigmoid(len_in):
    x = at.linspace(0, len_in, len_in)

    ## location of the change point
    del_t = pm.Normal("del_t", len_in / 2, sigma=len_in / 4)
    ## maximum increase in pandemic fatigue
    del_p = pm.Normal("del_f", mu=0.2, sigma=0.1)
    ## time scale of pandemic fatigue
    tau = pm.LogNormal("tau", mu=np.log(1), tau=1)

    ## pandemic fatigue
    p = pm.Deterministic("f", sigmoid(x, del_t, del_p, tau))
    return p


def disease_factor(indicator, disease_data_in, len_data, mu_z_prior=0.9):
    disease_data = pm.ConstantData(indicator, disease_data_in[indicator])
    disease_data_len = disease_data.shape[0].eval()

    ## define priors
    factor_disease = pm.LogNormal(f"z_{indicator}", mu=np.log(mu_z_prior), tau=10)
    mu_disease = pm.LogNormal(f"mu_{indicator}", mu=np.log(1), tau=10)
    sigma_disease = pm.LogNormal(f"sigma_{indicator}", mu=np.log(1), tau=10)
    ## convolution
    risk = cov19.model.delay_cases(
        cases=disease_data,
        delay_kernel="gamma",
        median_delay=mu_disease,
        scale_delay=sigma_disease,
        len_input_arr=disease_data_len,
        len_output_arr=len_data,
        diff_input_output=disease_data_len - len_data,
    )
    ## put it together
    exponent = -factor_disease * risk
    d = pm.Deterministic(f"d_{indicator}", at.exp(exponent))
    return d


def disease_factor_sigma_smaller_mu(
    indicator, disease_data_in, len_data, mu_z_prior=0.9
):
    disease_data = pm.ConstantData(indicator, disease_data_in[indicator])
    disease_data_len = disease_data.shape[0].eval()

    ## define priors
    factor_disease = pm.LogNormal(f"z_{indicator}", mu=np.log(mu_z_prior), tau=10)
    mu_disease = pm.LogNormal(f"mu_{indicator}", mu=np.log(0.9), tau=10)
    delta = pm.LogNormal(f"delta_{indicator}", mu=np.log(0.1), tau=1)
    sigma_disease = pm.Deterministic(f"sigma_{indicator}", mu_disease - delta)
    ## convolution
    risk = cov19.model.delay_cases(
        cases=disease_data,
        delay_kernel="gamma",
        median_delay=mu_disease,
        scale_delay=sigma_disease,
        len_input_arr=disease_data_len,
        len_output_arr=len_data,
        diff_input_output=disease_data_len - len_data,
    )
    ## put it together
    exponent = -factor_disease * risk
    d = pm.Deterministic(f"d_{indicator}", at.exp(exponent))
    return d


def correct_for_kurzarbeit(kurzarbeit_data_in, dates_2020, dates_2022_in, m_base_data):
    ## be aware that the time series goes from present to past
    kurzarbeit = kurzarbeit_data_in["Anzahl Kurzarbeitende"].values
    ## delay / advance kurzarbeit to correct reporting delay
    mu_K = pm.LogNormal("mu_K", mu=np.log(1), tau=10)
    sigma_K = pm.LogNormal("sigma_K", mu=np.log(0.6), tau=6)
    advanced_kurzarbeit = cov19.model.delay_cases(
        cases=kurzarbeit,
        delay_kernel="gamma",
        median_delay=mu_K,
        scale_delay=sigma_K,
        len_input_arr=len(kurzarbeit),
        len_output_arr=len(kurzarbeit),
        diff_input_output=0,
    )
    kurzarbeit_data_in["Kurzarbeitende korrigiert"] = advanced_kurzarbeit.eval()
    ## get weekly data for 2020 and 2022
    df_kurzarbeit_2020 = data_prep.get_weekly_kurzarbeit(
        kurzarbeit_data_in, dates_2020, "2020"
    )
    df_kurzarbeit_2022 = data_prep.get_weekly_kurzarbeit(
        kurzarbeit_data_in, dates_2022_in, "2022"
    )

    ## get difference between 2020 and 2022 as fraction of population
    population = 83237124
    KA_2020 = df_kurzarbeit_2020["Anzahl Kurzarbeitende"].values
    KA_2022 = df_kurzarbeit_2022["Anzahl Kurzarbeitende"].values
    KA_diff = (KA_2020 - KA_2022) / population

    ## make xarray of KA_diff with mobility_dates_2020 as index
    KA_diff_xr = xr.DataArray(KA_diff, coords=[dates_2020], dims=["date"])
    KA_diff_xr = pm.ConstantData("Kurzarbeit", KA_diff_xr)

    delta_o = pm.LogNormal("delta_o", mu=np.log(5), tau=10)
    m = pm.Deterministic("o_*", m_base_data - delta_o * KA_diff_xr)
    return m


# model
def create_model(
    model_in,
    base_mobility_data_in,
    observed_mobility_data_in,
    S_data_in,
    kurzarbeit_data_in,
    indicators_in,
    disease_data_in,
    dates_2022_in,
    pandemic_fatigue="sigmoid",
    delta_prcp_in=None,
    temperature_in=None,
    school_data_in=None,
):
    len_data = observed_mobility_data_in.shape[0]
    dates_2020 = observed_mobility_data_in.coords["date"].values
    with model_in:
        # define data
        m_base_data = pm.ConstantData("m_base", base_mobility_data_in)
        S_data = pm.ConstantData("S", S_data_in)

        # kurzarbeit
        m = correct_for_kurzarbeit(
            kurzarbeit_data_in, dates_2020, dates_2022_in, m_base_data
        )

        # impact of disease spread
        mu_z_prior = 0.9 ** len(indicators_in)
        for indicator in indicators_in:
            m *= disease_factor(indicator, disease_data_in, len_data, mu_z_prior)

        # impact of NPIs
        ## stay-at-home orders
        ### define priors
        z_S = pm.LogNormal("z_S", mu=np.log(0.9), tau=10)
        ### put it together
        exponent = -z_S * S_data
        s = pm.Deterministic("s", at.exp(exponent))
        m = m * s

        ## school closures | can probably be removed
        if school_data_in is not None:
            school_data = pm.ConstantData("school_closures", school_data_in)
            ### define priors
            z_school = pm.LogNormal("z_school", mu=np.log(0.95), tau=10)
            ### put it together
            exponent = -z_school * school_data
            c = pm.Deterministic("c", at.exp(exponent))
            m = m * c

        # impact of pandemic fatigue
        if pandemic_fatigue == "linear":
            m *= pandemic_fatigue_factor_linear(len_data)
        elif pandemic_fatigue == "sigmoid":
            m *= pandemic_fatigue_factor_sigmoid(len_data)

        # impact of weather
        ## precipitation
        if delta_prcp_in is not None:
            m *= precipitation_factor(delta_prcp_in)
        ## temperature
        if temperature_in is not None:
            m *= temperature_factor(len_data, temperature_in)

        # define likelihood
        m = pm.Deterministic("m", m)
        model_error = pm.HalfCauchy("sigma_model", beta=0.5)
        likelihood = pm.Normal(
            "likelihood", mu=m, sigma=model_error, observed=observed_mobility_data_in
        )
