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
#import xarray as xr

# local modules
import covid19_inference.covid19_inference as cov19
#import data_prep


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
    temperature_relevance = Gaussian(avg_T, T_star, a_r)

    # put it together
    w = pm.Deterministic("theta", 1 + delta_T * temperature_relevance * factor_weather)

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
    w = pm.Deterministic("p", 1 - z_P * delta_prcp)

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
    del_t = pm.Normal("del_t", -len_in / 2, sigma=len_in / 4)
    ## maximum increase in pandemic fatigue
    del_f = pm.Normal("del_f", mu=0.2, sigma=0.1)
    ## time scale of pandemic fatigue
    tau = pm.LogNormal("tau", mu=np.log(1), tau=1)

    ## pandemic fatigue
    p = pm.Deterministic("f", sigmoid(x, del_t, del_f, tau))

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
    mu_disease = pm.LogNormal(f"mu_{indicator}", mu=np.log(1), sigma=0.5)
    # sigma_disease = pm.Uniform(f"sigma_{indicator}", lower=1 / 7, upper=12)
    alpha_disease = pm.LogNormal(f"alpha_{indicator}", mu=np.log(2), sigma=0.25)
    sigma_disease = pm.Deterministic(
        f"sigma_{indicator}", mu_disease / at.sqrt(alpha_disease)
    )

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
    k = pm.Deterministic("k", delta_k * ka_data)
    return m_base_data - k


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
    h = pm.Deterministic("h", delta_h * ho_data)
    return m_base_data - h


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
):
    len_data = observed_mobility_data_in.shape[0]
    with model_in:
        # define data
        m_base_data = pm.ConstantData("m_base", base_mobility_data_in)

        # kurzarbeit
        m = correct_for_kurzarbeit(kurzarbeit_data_in, m_base_data)
        m = correct_for_home_office(homeOffice_data_in, m)
        m = pm.Deterministic("o_*", m)

        # impact of disease spread
        for indicator in indicators_in:
            mu_z_prior = np.power(0.9, 1/len(indicators_in))
            m *= disease_factor(indicator, disease_data_in, len_data, mu_z_prior)

        # impact of NPIs
        ## stay-at-home orders
        if S_data_in is not None:
            S_data = pm.ConstantData("S", S_data_in)
            m = m * return_s(S_data)

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
        o = pm.Normal(
            "o", mu=m, sigma=model_error, observed=observed_mobility_data_in
        )
