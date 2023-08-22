"""
Module inferring drivers of out-of-home duration changes.
The model combines the effects of different factors like policy interventions, 
disease spread, weather, and pandemic fatigue to model observed out-of-home duration patterns.

The overall workflow is:

1. Define model components as separate functions
2. Load/process data
3. Construct model by multiplying together components
4. Define likelihood based on observed data
"""

# general modules
import numpy as np
import pymc as pm
import pytensor.tensor as at
import xarray as xr

# local modules
import covid19_inference.covid19_inference as cov19
import data_prep


# --- Model components --- #


# NPIs
def return_s(S_in):
    """Models impact of stay-at-home orders.

    Args:
        S_in: Stay-at-home order stringency index (pm.ConstantData)

    Returns:
        Stay-at-home order modulation factor (pymc variable)
    """

    ## define prior
    z_S = pm.LogNormal("z_S", mu=np.log(0.5), tau=5)

    ## put it together
    exponent = -z_S * S_in
    s = pm.Deterministic("s", at.exp(exponent))

    return s


## NOT IN USE ANYMORE
def school_closure_factor(school_data_in):
    """Models impact of school closures.

    Args:
      school_data_in: School closure policy data (pm.ConstantData)

    Returns:
      School closure modulation factor (pymc variable)
    """

    ## data
    school_data = pm.ConstantData("school_closures", school_data_in)

    ## prior
    z_school = pm.LogNormal("z_school", mu=np.log(0.95), tau=10)

    ## put it together
    exponent = -z_school * school_data
    c = pm.Deterministic("c", at.exp(exponent))

    return c


# impact of weather
## temperature
### utility functions for temperature factor
def generate_Tstar(amplitude, offset, shift, length):
    """Generates go-out temperature curve using 4th order polynomial.

    Args:
        Paramaters: amplitude, offset, shift (pymc variables or just numbers)
        length: Length of curve or data (int)

    Returns:
        T_star: Go-out temperature curve (pymc variable)

    """

    x = at.linspace(0, length, length)
    return pm.Deterministic("T_star", -at.power(amplitude * (x + shift), 4.0) + offset)


def Gaussian(T, T_star, a):
    """Models impact of temperature deviation from optimal temperature.

    Args:
        T: Some temperature data (pm.ConstantData)
        T_star: Go-out temperature curve (pm.Deterministic)
        a: Sensitivity / scale parameter (pymc variable or just number)

    Returns:
        rho: Temperature modulation factor (pymc variable)
    """

    return pm.Deterministic("rho", at.exp(-a * at.power(T - T_star, 2.0)))


## temperature factor
def temperature_factor(len_data_in, temperature_in):
    """Models impact of temperature on mobility.

    Args:
        len_data_in: Length of time series (int)
        temperature_in: Dictionary with temperature data (xr.DataArray)

    Returns:
        Temperature multiplier (pymc variable)

    """

    # temperature data
    delta_T = pm.ConstantData("delta_T", temperature_in["delta"])
    avg_T = pm.ConstantData("avg_T", temperature_in["average"])

    # impact of weather: maximum temperature
    factor_weather = pm.LogNormal("z_T", mu=np.log(0.01), tau=1)

    # Gaussian to model the impact of optimal absolute temperature
    ## minimimum go-out temperature
    ### priors
    amplitude = pm.LogNormal("amplitude", mu=np.log(0.08), tau=20)
    offset = pm.Normal("offset", mu=25, sigma=2)
    shift = pm.Normal("shift", mu=-20, sigma=2)
    ### get go-out temperature
    T_star = generate_Tstar(
        amplitude=amplitude,
        offset=offset,
        shift=shift,
        length=len_data_in,
    )
    ## calculate relevance of temperature differences
    a_r = pm.LogNormal("a_rho", mu=np.log(0.01), tau=1)
    weather_relevance = Gaussian(avg_T, T_star, a_r)

    # put it together
    w = pm.Deterministic("theta", at.exp(delta_T * weather_relevance * factor_weather))

    return w


## precipitation
def precipitation_factor(delta_prcp_in):
    """Models impact of precipitation on mobility.

    Args:
    delta_prcp_in: Precipitation data (pm.ConstantData)

    Returns:
    Precipitation modulation factor (pymc variable)
    """

    # priors
    delta_prcp = pm.ConstantData("delta_prcp", delta_prcp_in)
    z_P = pm.LogNormal("z_P", mu=np.log(0.05), tau=0.5)

    # put it together
    w = pm.Deterministic("p", at.exp(-z_P * delta_prcp))

    return w


# pandemic fatigue
# impact of pandemic fatigue: linear version
def pandemic_fatigue_factor_linear(len_in):
    """Models linear pandemic fatigue over time.

    Args:
    len_in: Length of time series (int)

    Returns:
    Linear pandemic modulation factor (pymc variable)
    """

    x = at.linspace(0, len_in, len_in)
    max_x = len_in - 1
    ## pandemic fatigue (addition) at the start
    p0 = pm.LogNormal("f0", mu=np.log(0.01), tau=0.2)
    ## pandemic fatigue rate
    r = pm.TruncatedNormal("r", mu=0.2 / max_x, sigma=0.01 / max_x, lower=-p0 / max_x)
    ## pandemic fatigue
    p = pm.Deterministic("f", 1 + p0 + r * x)

    return p


# impact of pandemic fatigue: sigmoid version
## utility function
def sigmoid(x, del_t, del_y, v_change, p0=1):
    return del_y / (1 + at.exp(-v_change * (x + del_t))) + p0


## multiplier
def pandemic_fatigue_factor_sigmoid(len_in):
    """Models sigmoid pandemic fatigue over time.

    Args:
    len_in: Length of time series (int)

    Returns:
    Sigmoid pandemic modulation factor (pymc variable)
    """
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


# impact of disease spread
def disease_factor(indicator, disease_data_in, len_data, mu_z_prior=0.9):
    """Models impact of disease spread on mobility.

    Args:
    indicator: Name of disease indicator (str)
    disease_data_in: Disease data (dict of xr.DataArray)
    len_data: Length of mobility time series (int)
    mu_z_prior: Prior mean for disease impact (float)

    Returns:
    Disease spread modulation factor (pymc variable)
    """

    ## data
    disease_data = pm.ConstantData(indicator, disease_data_in[indicator])
    disease_data_len = disease_data.shape[0].eval()

    ## define priors
    factor_disease = pm.LogNormal(f"z_{indicator}", mu=np.log(mu_z_prior), tau=10)
    # mu_disease = pm.Uniform(f"mu_{indicator}", lower=1 / 7, upper=12)
    mu_disease = pm.LogNormal(f"mu_{indicator}", mu=np.log(2), tau=8)
    sigma_disease = pm.LogNormal(f"sigma_{indicator}", mu=np.log(1), tau=7)

    ## convolve disease data with delay kernel
    risk = cov19.model.delay_cases(
        cases=disease_data,
        delay_kernel="gamma",
        median_delay=mu_disease,
        scale_delay=sigma_disease,
        len_input_arr=disease_data_len,
        len_output_arr=len_data,
        diff_input_output=disease_data_len - len_data,
    )
    risk = pm.Deterministic(f"risk_{indicator}", risk)

    ## put it together
    exponent = -factor_disease * risk
    d = pm.Deterministic(f"d_{indicator}", at.exp(exponent))

    return d


## if you want to enforce that sigma of the kernel is smaller than mu use this
## but check first whether it needs to be updated according to disease_factor()
def disease_factor_sigma_smaller_mu(
    indicator, disease_data_in, len_data, mu_z_prior=0.9
):
    """Disease factor model with sigma < mu constraint.
    Otherwise same as disease_factor."""

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


# NOT IN USE ANYMORE | Home office and Kurzarbeit
def correct_for_home_office_and_kurzarbeit(ho_ka_data_in, m_base_data):
    """Adjusts baseline out-of-hone duration for short-time work changes.

    Args:
        ho_ka_data_in: Home office and short-time work data (Xarray.DataArray)
        m_base_data: Baseline mobility (pm.ConstantData)

    Returns:
        Adjusted baseline mobility (pymc variable)
    """
    ho_ka_data = pm.ConstantData("HO_KA", ho_ka_data_in)
    ## correct baseline out-of-home duration
    delta_o = pm.LogNormal("delta_o", mu=np.log(8), tau=10)
    m = pm.Deterministic("o_*", m_base_data - delta_o * ho_ka_data)

    return m


# Kurzarbeit
def correct_for_kurzarbeit(kurzarbeit_data_in, m_base_data):
    """Adjusts baseline out-of-home duration for short-time work changes.

    Args:
        kurzarbeit_data_in: Difference in short-time work rate between 2020 and 2022 (Xarray.DataArray)
        m_base_data: Baseline mobility (pm.ConstantData)

    Returns:
        Adjusted baseline mobility (pymc variable)
    """
    ka_data = pm.ConstantData("Kurzarbeit", kurzarbeit_data_in)
    ## correct baseline out-of-home duration
    delta_k = pm.LogNormal("delta_k", mu=np.log(8), tau=10)
    return m_base_data - delta_k * ka_data


def correct_for_home_office(home_office_data_in, m_base_data):
    """Adjusts baseline out-of-home duration for home office patterns.

    Args:
        home_office_data_in: Difference in home office rate between 2020 and 2022 (Xarray.DataArray)
        m_base_data: Baseline mobility (pm.ConstantData)

    Returns:
        Adjusted baseline mobility (pymc variable)
    """
    ho_data = pm.ConstantData("home_office", home_office_data_in)
    ## correct baseline out-of-home duration
    delta_h = pm.LogNormal("delta_h", mu=np.log(8), tau=10)
    return m_base_data - delta_h * ho_data


## NOT IN USE ANYMORE
def correct_for_OLD_kurzarbeit(
    kurzarbeit_data_in, dates_2020, dates_2022_in, m_base_data
):
    """Adjusts baseline out-of-hone duration for short-time work changes.

    Args:
        kurzarbeit_data_in: Short-time work data (pd.DataFrame)
        dates_2020: 2020 dates (pd.DatetimeIndex)
        dates_2022_in: 2022 dates (pd.DatetimeIndex)
        m_base_data: Baseline mobility (pm.ConstantData)

    Returns:
        Adjusted baseline mobility (pymc variable)
    """

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

    ## correct baseline out-of-home duration
    delta_o = pm.LogNormal("delta_o", mu=np.log(5), tau=10)
    m = pm.Deterministic("o_*", m_base_data - delta_o * KA_diff_xr)

    return m


# --- Total model --- #


def create_model(
    model_in,
    base_mobility_data_in,
    observed_mobility_data_in,
    S_data_in,
    kurzarbeit_data_in,
    homeOffice_data_in,
    indicators_in,
    disease_data_in,
    pandemic_fatigue="sigmoid",
    delta_prcp_in=None,
    temperature_in=None,
    school_data_in=None,
):
    len_data = observed_mobility_data_in.shape[0]
    with model_in:
        # define data
        m_base_data = pm.ConstantData("m_base", base_mobility_data_in)
        S_data = pm.ConstantData("S", S_data_in)

        # kurzarbeit
        m = correct_for_kurzarbeit(kurzarbeit_data_in, m_base_data)
        m = correct_for_home_office(homeOffice_data_in, m)
        m = pm.Deterministic("o_*", m)

        # impact of disease spread
        mu_z_prior = 0.5 ** len(indicators_in)
        for indicator in indicators_in:
            m *= disease_factor(indicator, disease_data_in, len_data, mu_z_prior)

        # impact of NPIs
        ## stay-at-home orders
        m = m * return_s(S_data)

        ## school closures | can be removed
        if school_data_in is not None:
            m = m * school_closure_factor(school_data_in)

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
