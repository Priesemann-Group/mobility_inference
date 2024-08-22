# general modules
import numpy as np
import pymc as pm
from pyparsing import alphanums
import pytensor.tensor as at
#import xarray as xr

# local modules
import covid19_inference as cov19

#Out-of-home-duration_base --> DEPENDS ON FED STATE
def duration_base(d_base_input, fedState_idx):
    """
    Args:

    Returns:
    Base duration
    """
    d_factor = pm.Normal("d_factor", mu=10, sigma=2, dims = ("fedState"))

    d_base = pm.Deterministic("d_base", d_base_input*d_factor[fedState_idx], dims=("obs_id"))

    return d_base

#Influence of population density --> DEPENDS ON FED STATE
def pop_density_factor(pop_density_in, fedState):
    """
    Args:
    pop_density_in: Population density data

    Returns:
    Population density data modulation factor (pymc variable)
    """

    alpha_v = pm.Normal("alpha_pop", mu = 0.00001, sigma = 0.001, dims = "fedState")
    beta_v = pm.Normal("beta_pop", mu = 1, sigma = 0.000001, dims ="fedState")

    alpha = alpha_v[fedState]
    beta = beta_v[fedState]

    pop_density_data = pm.ConstantData("pop_density_data_in", pop_density_in["pop_density"], dims = "obs_id")

    pop = pm.Deterministic("pop_density_factor", alpha * pop_density_data + beta)

    return pop

def vacation_factor(vacation_data_in, fedState_idx):
    """
    Args:
    vacation_data_in: Vacation data

    Returns:
    School vacation modulation factor (pymc variable)
    """

    vacation_data = pm.MutableData("vacation_data_in", vacation_data_in["school vacation"], dims="obs_id")
        
    theta = pm.Uniform("theta_v", lower=0.8, upper=1.0, dims = "fedState")

    #scale_v = pm.LogNormal("scale_v", mu=np.log(0.5), tau=5)
    v = pm.Deterministic("vacation_factor", ((theta[fedState_idx]-1) / 7 * vacation_data + 1), dims = "obs_id")
    
    return v

def holiday_factor(holiday_data_in, fedState_idx):
    """
    Args:
    holiday_data_in: Public holiday data

    Returns:
    Public holiday vacation modulation factor (pymc variable)
    """
    holiday_data = pm.MutableData("holiday_data_in", holiday_data_in["pub holiday"], dims ="obs_id")

    theta = pm.Uniform("theta_h", lower=0.9, upper=1.0, dims ="fedState")
    h = pm.Deterministic("holiday_factor", ((theta[fedState_idx]-1) / 7 * holiday_data + 1), dims = "obs_id")
    
    return h


## temperature factor
#sigmoid
def temperature_factor(temperature_in, fedState_x):
    """
    Args:
       temperature_data_in: Temperature data

    Returns:
        T_star: Temperature sensitivity

    """

    Tmax_2020 = pm.MutableData("max_Temp", temperature_in["temperature"], dims = ("obs_id",))

    amplitude_temperature = pm.HalfCauchy("amplitude_temperature", beta = 0.5, dims = "fedState")

    #shift_temperature = pm.LogNormal("shift_temperature", mu = np.log(20), sigma = 0.2)
    shift_temperature = pm.Normal("shift_temperature", mu = 15, sigma = 10, dims = "fedState") #Updated according to J's recommendation 
    slope_temperature = pm.Lognormal("slope_temperature", mu = np.log(1), sigma = 0.25, dims = "fedState")
    #intercept_temperature = pm.LogNormal("intercept_temperature", mu = np.log(0.9), sigma = 0.1, dims = "fedState")
    intercept_temperature = pm.Deterministic("intercept_temperature", 1 - amplitude_temperature*(1/(1+np.exp(-(20/slope_temperature-shift_temperature)))), dims = "fedState")

    temperature_factor = pm.Deterministic("temperature_factor", amplitude_temperature[fedState_x]*(1/(1+np.exp(-(Tmax_2020/slope_temperature[fedState_x]-shift_temperature[fedState_x])))) + intercept_temperature[fedState_x], dims = "obs_id")

    return temperature_factor

#sine
# def temperature_factor(temperature_in):
#     """
#     Args:
#        temperature_data_in: Temperature data

#     Returns:
#         T_star: Temperature sensitivity

#     """

#     Tmax_2020 = pm.ConstantData("max_Temp", temperature_in["temperature"])

#     amplitude = pm.Normal("amplitude", mu=0.5, sigma = 0.1)
#     offset = pm.Normal("offset", mu=1, sigma=0.1)
#     shift = pm.Normal("shift", mu=-20, sigma=2)

#     return pm.Deterministic("temperature_factor", np.sin(amplitude*(Tmax_2020+shift)))

## temperature factor
##x^4
# def temperature_factor(temperature_in):
#     """Generates go-out temperature curve using 4th order polynomial.

#     Args:
#         temperature_data_in: Temperature data

#     Returns:
#         T_star: Go-out temperature curve (pymc variable)

#     """

#     Tmax_2020 = pm.ConstantData("max_Temp", temperature_in["temperature"])

#     amplitude = pm.Normal("amplitude", mu=0.02, sigma = 0.002)
#     offset = pm.Normal("offset", mu=1, sigma=0.1)
#     shift = pm.Normal("shift", mu=-20, sigma=2)

#     return pm.Deterministic("temperature_factor", -at.power(amplitude * (Tmax_2020 + shift), 4.0) + offset)

##x^2
# def temperature_factor(temperature_in, fedState):
#     """Generates go-out temperature curve using 4th order polynomial.

#     Args:
#        temperature_data_in: Temperature data

#     Returns:
#         T_star: Go-out temperature curve (pymc variable)

#     """

#     Tmax_2020 = pm.MutableData("max_Temp", temperature_in["temperature"], dims = "fedState")

#     amplitude_v = pm.Normal("amplitude", mu=0.05, sigma = 0.005, dims = "fedState")
#     amplitude = amplitude_v[fedState]
#     offset_v = pm.Normal("offset", mu=1, sigma=0.01, dims = "fedState")
#     offset = offset_v[fedState]
#     shift_v = pm.Normal("shift", mu=-20, sigma=2, dims = "fedState")
#     shift = shift_v[fedState]

#     return pm.Deterministic("temperature_factor", -at.power(amplitude * (Tmax_2020 + shift), 2.0) + offset, dims = "fedState")

def precipitation_factor(precipitation_data_in, fedState):
    """
    Args:
    precipitation_data_in: Precipitation data

    Returns:
    Precipitation modulation factor (pymc variable)
    """
    precipitation_data = pm.MutableData("precipitation_data_in", precipitation_data_in["precipitation"], dims = "fedState")

    scale_zp_v = pm.LogNormal("z_p", mu = np.log(0.75), sigma = 0.1, dims = "fedState")
    scale_zp = scale_zp_v[fedState]
    p = pm.Deterministic("precipitation_factor", np.exp(- scale_zp * precipitation_data), dims = "fedState")
    
    return p


def daylight_factor(daylight_data_in, fedState_x):
    """
    Args:
    daylight_data_in: Precipitation data

    Returns:
    Daylight modulation factor (pymc variable)
    """
    daylight_data = pm.MutableData("daylight_data_in", daylight_data_in["daylight"], dims = ("obs_id",))

    #amplitude_daylight = pm.LogNormal("amplitude_daylight", mu = np.log(0.2), sigma = 0.05)
    amplitude_daylight = pm.HalfCauchy("amplitude_daylight", beta = 0.5, dims = "fedState") #Based on advice by J, a HalfCauchy distr. is being used
    shift_daylight = pm.Normal("shift_daylight", mu = 12, sigma = 1, dims = "fedState") 
    slope_daylight = pm.Lognormal("slope_daylight", mu = np.log(1), sigma = 0.1, dims = "fedState")
    #intercept_daylight = pm.LogNormal("intercept_daylight", mu = np.log(0.8), sigma = 0.1, dims = "fedState")
    intercept_daylight = pm.Deterministic("intercept_daylight", 1 - amplitude_daylight*(1/(1+np.exp(-(12.23/slope_daylight-shift_daylight)))), dims = "fedState")

    day = pm.Deterministic("daylight_factor", amplitude_daylight[fedState_x]*(1/(1+np.exp(-(daylight_data/slope_daylight[fedState_x]-shift_daylight[fedState_x])))) + intercept_daylight[fedState_x], dims = "obs_id")

    return day

# def daylight_factor(daylight_data_in):
# #Using a sigmoidal function

#     """
#     Args:
#     daylight_data_in: Precipitation data

#     Returns:
#     Daylight modulation factor (pymc variable)
#     """
#     daylight_data = pm.MutableData("daylight_data_in", daylight_data_in["daylight"], dims = "fedState")

#     alpha = pm.Normal("alpha_day", mu = 0.5, sigma = 0.005) #TODO: Find adequate non-neg. distribution
#     beta = pm.Normal("beta_day", mu = 20, sigma = 0.05)
#     day = pm.Deterministic("daylight_factor", 1/(1+np.exp(alpha*(daylight_data+beta)))+1, dims = "fedState") 

#     return day

#Impact of disease spread
def disease_factor(indicator, disease_data_in, time_counter_in, len_data, fedState_idx, counter, mu_z_prior_1=0.7, mu_z_prior_2=0.8):
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
    disease_data = pm.MutableData(indicator, disease_data_in[indicator], dims = "obs_id_long")
    #disease_data_len = len(disease_data_in["C_full"])
    disease_data_len = disease_data.shape[0].eval()
    #idx = np.arange(0,37*16,1)
    idx = np.arange(0, 37*3,1)
    time_counter = pm.MutableData(f"counter_{indicator}", time_counter_in["time counter"], dims = ("obs_id"))

    ## define priors
    mu_disease = pm.LogNormal(f"mu_{indicator}", mu=np.log(2), sigma=0.5) #Mean of Gamma distribution
    alpha_disease = pm.LogNormal(f"alpha_{indicator}", mu=np.log(3), sigma=0.5) 
    sigma_disease = pm.Deterministic( #Variance of Gamma Distribution
        f"sigma_{indicator}", mu_disease / at.sqrt(alpha_disease)
    )

    # convolve disease data with delay kernel
    risk = cov19.model.delay_cases(
        cases=disease_data,
        delay_kernel="gamma",
        median_delay=mu_disease,
        scale_delay=sigma_disease,
        len_input_arr=disease_data_len,
        len_output_arr=len_data,
        diff_input_output=disease_data_len - len_data,
    )
    #risk = disease_data
    risk = pm.Deterministic(f"risk_{indicator}", risk, dims = "obs_id")

    # amplitude_disease = pm.LogNormal(f"amplitude_{indicator}", mu = np.log(0.6), sigma = 0.3, dims=("fedState"))
    # shift_disease = pm.LogNormal(f"shift_{indicator}", mu = np.log(0.3), sigma = 0.1, dims=("fedState"))
    slope_disease = pm.Lognormal(f"slope_{indicator}", mu = np.log(10), sigma = 1, dims=("fedState"))
    intercept_disease = pm.LogNormal(f"intercept_{indicator}", mu = np.log(1.5), sigma = 1, dims=("fedState"))

    # # #factor_disease = pm.Deterministic(f"factor_{indicator}", amplitude_disease[fedState_idx]*(1/(1+np.exp((disease_data[fedState_idx]/slope_disease[fedState_idx]-shift_disease[fedState_idx])))) + intercept_disease[fedState_idx], dims="obs_id")
    factor_disease = pm.Deterministic(f"factor_{indicator}", np.exp(-time_counter/slope_disease[fedState_idx]) + intercept_disease[fedState_idx], dims=("obs_id"))
    # # #factor_disease = pm.Deterministic(f"factor_{indicator}", np.exp(disease_data/1), dims=("fedState"))
    #exponent = pm.Deterministic(f"exponent_{indicator}", - factor_disease * risk, dims = "fedState")

    d = pm.Deterministic(f"d_{indicator}", at.exp(- factor_disease * risk[fedState_idx]), dims = "obs_id")

    return d

# --- Total model --- #


def create_model(
    model_in,
    base_mobility_data_in,
    observed_mobility_data_in,
    indicators_in,
    disease_data_in,
    time_counter_in,
    school_in,
    holiday_in,
    precipitation_in=None,
    temperature_in=None,
    daylight_in=None,
    pop_density_in=None,
    fed_states_in=None,
    counter_in=None
):

    len_data = observed_mobility_data_in.shape[0]
    with model_in:
        fedState_x = pm.MutableData("fedState_idx", fed_states_in, dims=("obs_id",))
        # define data
        m = duration_base(base_mobility_data_in, fedState_x)

        # # #impact of disease spread
        if indicators_in is not None:
            for indicator in indicators_in:
                mu_z_prior1 = np.power(0.9, 1/len(indicators_in))
                mu_z_prior2 = np.power(0.9, 1/len(indicators_in))
                m *= disease_factor(indicator, disease_data_in, time_counter_in, len_data, fed_states_in, mu_z_prior1, mu_z_prior2)

        # if pop_density_in is not None:
        #     m *= pop_density_factor(pop_density_in, fed_states_in)

        #impact of school vacations
        if school_in is not None:
            m *= vacation_factor(school_in, fed_states_in)

        # #impact of holiday data
        if holiday_in is not None:
            m*= holiday_factor(holiday_in, fed_states_in)

        # #impact of weather
        # # precipitation
        if precipitation_in is not None:
            m *= precipitation_factor(precipitation_in, fed_states_in)
            
        # temperature
        if temperature_in is not None:
            m *= temperature_factor(temperature_in, fed_states_in)

        # # daylight
        if daylight_in is not None:
            m *= daylight_factor(daylight_in, fed_states_in)

        # # define likelihood

        m = pm.Deterministic("m", m, dims="obs_id") #Here: dims=fedState?? or rather m[fedState_idx]?

        model_error = pm.HalfCauchy("sigma_model", beta=0.2)
        d = pm.Normal(
            "d", mu=m, sigma=model_error, observed=observed_mobility_data_in, dims="obs_id"
        )
