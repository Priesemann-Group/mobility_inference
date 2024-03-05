# general modules
import numpy as np
import pymc as pm
import pytensor.tensor as at
#import xarray as xr

# local modules
import covid19_inference as cov19

#Impact of school holidays
def duration_base(d_base):
    """
    Args:

    Returns:
    Base duration
    """


    d_factor = pm.Normal("d_factor", mu=12, sigma=1)

    d_base = pm.Deterministic("d_base", d_base*d_factor)

    return d_base

def vacation_factor(vacation_data_in):
    """
    Args:
    vacation_data_in: Vacation data

    Returns:
    School vacation modulation factor (pymc variable)
    """
    vacation_data = pm.ConstantData("vacation_data_in", vacation_data_in["school vacation"])

    theta_v = pm.Uniform("theta_v", lower=0.8, upper=1.0)
    #scale_v = pm.LogNormal("scale_v", mu=np.log(0.5), tau=5)
    v = pm.Deterministic("vacation_factor", ((theta_v-1) / 7 * vacation_data + 1))
    
    return v

def holiday_factor(holiday_data_in):
    """
    Args:
    holiday_data_in: Public holiday data

    Returns:
    Public holiday vacation modulation factor (pymc variable)
    """
    holiday_data = pm.ConstantData("holiday_data_in", holiday_data_in["pub holiday"])

    theta_h = pm.Uniform("theta_h", lower=0.9, upper=1.0)
    h = pm.Deterministic("holiday_factor", ((theta_h-1) / 7 * holiday_data + 1))
    
    return h


## temperature factor
def generate_Tstar(amplitude, offset, shift, slope, length):
    """
    Args:
        Paramaters: amplitude, offset, shift (pymc variables or just numbers)
        length: Length of curve or data (int)

    Returns:
        T_star: Temperature sensitivity

    """

    x = at.linspace(0, length, length)
    return pm.Deterministic("T_star", amplitude/(1+np.exp(slope*(x+shift)))+offset)

## temperature factor
##x^4
def temperature_factor(temperature_in):
    """Generates go-out temperature curve using 4th order polynomial.

    Args:
        Paramaters: amplitude, offset, shift (pymc variables or just numbers)
        length: Length of curve or data (int)

    Returns:
        T_star: Go-out temperature curve (pymc variable)

    """

    Tmax_2020 = pm.ConstantData("max_Temp", temperature_in["temperature"])

    amplitude = pm.Normal("amplitude", mu=0.02, sigma = 0.002)
    offset = pm.Normal("offset", mu=1, sigma=0.1)
    shift = pm.Normal("shift", mu=-20, sigma=2)

    return pm.Deterministic("temperature_factor", -at.power(amplitude * (Tmax_2020 + shift), 2.0) + offset)

##x^2
# def temperature_factor(temperature_in):
#     """Generates go-out temperature curve using 4th order polynomial.

#     Args:
#         Paramaters: amplitude, offset, shift (pymc variables or just numbers)
#         length: Length of curve or data (int)

#     Returns:
#         T_star: Go-out temperature curve (pymc variable)

#     """

#     Tmax_2020 = pm.ConstantData("max_Temp", temperature_in["temperature"])

#     amplitude = pm.Normal("amplitude", mu=0.05, sigma = 0.005)
#     offset = pm.Normal("offset", mu=1, sigma=0.01)
#     shift = pm.Normal("shift", mu=-20, sigma=2)

#     return pm.Deterministic("temperature_factor", -at.power(amplitude * (Tmax_2020 + shift), 2.0) + offset)

#First T_star, then temp_factor
def generate_Tstar(amplitude, shift, temperature_in):
    """
    Args:
        Paramaters: amplitude, offset, shift (pymc variables or just numbers)
        length: Length of curve or data (int)

    Returns:
        T_star: Temperature sensitivity

    """
    Tmax_2020 = pm.ConstantData("max_Temp", temperature_in["temperature"])

    return pm.Deterministic("T_star", at.power(amplitude * (Tmax_2020 + shift), 4.0))

# def temperature_factor(temperature_in):
#     """Generates go-out temperature curve using 4th order polynomial.

#     Args:
#         Paramaters: amplitude, offset, shift (pymc variables or just numbers)
#         length: Length of curve or data (int)

#     Returns:
#         T_star: Go-out temperature curve (pymc variable)

#     """

#     amplitude = pm.Normal("amplitude", mu=0.5, sigma = 0.05)
#     shift = pm.Normal("shift", mu=-27, sigma=2)

#     T_star = generate_Tstar(
#         amplitude=amplitude,
#         shift = shift,
#         temperature_in=temperature_in
#     )

#     z_w = pm.LogNormal("z_w", mu=np.log(0.01), tau=1)

#     return pm.Deterministic("temperature_factor", np.exp(-z_w*T_star))

def precipitation_factor(precipitation_data_in):
    """
    Args:
    precipitation_data_in: Precipitation data

    Returns:
    Precipitation modulation factor (pymc variable)
    """
    precipitation_data = pm.ConstantData("precipitation_data_in", precipitation_data_in["precipitation"])

    scale_zp = pm.LogNormal("z_p", mu = np.log(0.75), sigma = 0.1)
    p = pm.Deterministic("precipitation_factor", np.exp(- scale_zp * precipitation_data))
    
    return p

#Impact of disease spread
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
    mu_disease = pm.LogNormal(f"mu_{indicator}", mu=np.log(15), sigma=0.5)
    # sigma_disease = pm.Uniform(f"sigma_{indicator}", lower=1 / 7, upper=12)
    alpha_disease = pm.LogNormal(f"alpha_{indicator}", mu=np.log(3), sigma=0.25)
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

# --- Total model --- #


def create_model(
    model_in,
    base_mobility_data_in,
    observed_mobility_data_in,
    indicators_in,
    disease_data_in,
    school_in,
    holiday_in,
    precipitation_in=None,
    temperature_in=None,
):
    len_data = observed_mobility_data_in.shape[0]
    with model_in:
        # define data
        m = duration_base(base_mobility_data_in)

        # impact of disease spread
        for indicator in indicators_in:
            mu_z_prior = np.power(0.9, 1/len(indicators_in))
            m *= disease_factor(indicator, disease_data_in, len_data, mu_z_prior)

        #impact of school vacations
        if school_in is not None:
            m *= vacation_factor(school_in)

        #impact of holiday data
        if holiday_in is not None:
            m*= holiday_factor(holiday_in)

        # impact of weather
        ## precipitation
        if precipitation_in is not None:
            m *= precipitation_factor(precipitation_in)
            
        ## temperature
        if temperature_in is not None:
            m *= temperature_factor(temperature_in)

        # define likelihood
        m = pm.Deterministic("m", m)
        model_error = pm.HalfCauchy("sigma_model", beta=0.2)
        d = pm.Normal(
            "d", mu=m, sigma=model_error, observed=observed_mobility_data_in
        )
