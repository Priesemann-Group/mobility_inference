# general modules
import numpy as np
import pymc as pm
from pyparsing import alphanums
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
    d_factor = pm.Normal("d_factor", mu=8, sigma=2)

    d_base = pm.Deterministic("d_base", d_base*d_factor)

    return d_base

def pop_density_factor(pop_density_in):
    """
    Args:
    pop_density_in: Population density data

    Returns:
    Population density data modulation factor (pymc variable)
    """

    alpha = pm.Normal("alpha_pop", mu = 0.00001, sigma = 0.001)
    beta = pm.Normal("beta_pop", mu = 1, sigma = 0.000001)

    pop_density_data = pm.ConstantData("pop_density_data_in", pop_density_in["pop_density"])

    pop = pm.Deterministic("pop_density_factor", alpha * pop_density_data + beta)

    return pop

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
#sigmoid
def temperature_factor(temperature_in):
    """
    Args:
       temperature_data_in: Temperature data

    Returns:
        T_star: Temperature sensitivity

    """

    Tmax_2020 = pm.ConstantData("max_Temp", temperature_in["temperature"])

    amplitude_temperature = pm.HalfCauchy("amplitude_temperature", beta = 0.5)
    #amplitude_temperature = pm.LogNormal("amplitude_temperature", mu = np.log(0.2), sigma = 0.05)
    #shift_temperature = pm.LogNormal("shift_temperature", mu = np.log(20), sigma = 0.2)
    shift_temperature = pm.Normal("shift_temperature", mu = 15, sigma = 10) #Updated according to J's recommendation 
    slope_temperature = pm.Lognormal("slope_temperature", mu = np.log(1), sigma = 0.25)
    #intercept_temperature = pm.LogNormal("intercept_temperature", mu = np.log(1), sigma = 0.1)
    intercept_temperature = pm.Deterministic("intercept_temperature", 1 - amplitude_temperature*(1/(1+np.exp(-(20/slope_temperature-shift_temperature)))))

    temperature_factor = pm.Deterministic("temperature_factor", amplitude_temperature*(1/(1+np.exp(-(Tmax_2020/slope_temperature-shift_temperature)))) + intercept_temperature)
    
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

#     #amplitude_temperature = pm.LogNormal("amplitude_temperature", mu = np.log(0.2), sigma = 0.05)
#     amplitude_temperature = pm.HalfCauchy("amplitude_temperature", beta = 0.5) #Based on advice by J, I am ussing a HalfCauchy instead of a Lognormal distr.
#     shift_temperature = pm.LogNormal("shift_temperature", mu = np.log(17), sigma = 0.2) 
#     slope_temperature = pm.Lognormal("slope_temperature", mu = np.log(1/5), sigma = 0.05)
#     intercept_temperature = pm.LogNormal("intercept_temperature", mu = np.log(0.9), sigma = 0.05)

#     temperature_factor = pm.Deterministic("temperature_factor", amplitude_temperature*np.sin((Tmax_2020/slope_temperature-shift_temperature))+intercept_temperature)

#     return temperature_factor

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
# def temperature_factor(temperature_in):
#     """Generates go-out temperature curve using 4th order polynomial.

#     Args:
#        temperature_data_in: Temperature data

#     Returns:
#         T_star: Go-out temperature curve (pymc variable)

#     """

#     Tmax_2020 = pm.ConstantData("max_Temp", temperature_in["temperature"])

#     amplitude = pm.Normal("amplitude", mu=0.05, sigma = 0.005)
#     offset = pm.Normal("offset", mu=1, sigma=0.01)
#     shift = pm.Normal("shift", mu=-20, sigma=2)

#     return pm.Deterministic("temperature_factor", -at.power(amplitude * (Tmax_2020 + shift), 2.0) + offset)

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

# def daylight_factor(daylight_data_in):
#     """
#     Args:
#     daylight_data_in: Precipitation data

#     Returns:
#     Daylight modulation factor (pymc variable)
#     """
#     daylight_data = pm.ConstantData("daylight_data_in", daylight_data_in["daylight"])

#     alpha = pm.Normal("alpha_day", mu = 0.2, sigma = 0.01)
#     beta = pm.Normal("beta_day", mu = -2, sigma = 0.1)
#     day = pm.Deterministic("daylight_factor", alpha * daylight_data + beta)

#     return day

def daylight_factor(daylight_data_in):
    """
    Args:
    daylight_data_in: Precipitation data

    Returns:
    Daylight modulation factor (pymc variable)
    """
    daylight_data = pm.ConstantData("daylight_data_in", daylight_data_in["daylight"])

    #amplitude_daylight = pm.LogNormal("amplitude_daylight", mu = np.log(0.2), sigma = 0.05)
    amplitude_daylight = pm.HalfCauchy("amplitude_daylight", beta = 0.5) #Based on advice by J, a HalfCauchy distr. is being used
    shift_daylight = pm.LogNormal("shift_daylight", mu = np.log(12.23), sigma = 0.1) 
    slope_daylight = pm.Lognormal("slope_daylight", mu = np.log(1), sigma = 0.3)
    intercept_daylight = pm.Deterministic("intercept_daylight", 1 - amplitude_daylight*(1/(1+np.exp(-(12.23/slope_daylight-shift_daylight)))))
    #intercept_daylight = pm.LogNormal("intercept_daylight", mu = np.log(0.9), sigma = 0.3)

    day = pm.Deterministic("daylight_factor", amplitude_daylight*(1/(1+np.exp(-(daylight_data/slope_daylight-shift_daylight)))) + intercept_daylight)

    return day

#Impact of disease spread
def disease_factor(indicator, disease_data_in, len_data, mu_z_prior_1=0.7, mu_z_prior_2=0.8):
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
    idx = np.arange(0,90,1)

    ## define priors
    mu_disease = pm.LogNormal(f"mu_{indicator}", mu=np.log(2), sigma=0.2) #Mean of Gamma distribution
    alpha_disease = pm.LogNormal(f"alpha_{indicator}", mu=np.log(3), sigma=0.25) 
    sigma_disease = pm.Deterministic( #Variance of Gamma Distribution
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
    #factor_disease = pm.math.switch(15 > idx, factor_disease_1, factor_disease_2)
    
    amplitude_disease = pm.LogNormal(f"amplitude_{indicator}", mu = np.log(0.6), sigma = 0.3)
    shift_disease = pm.LogNormal(f"shift_{indicator}", mu = np.log(15), sigma = 1 )
    slope_disease = pm.Lognormal(f"slope_{indicator}", mu = np.log(40), sigma = 2)
    intercept_disease = pm.LogNormal(f"intercept_{indicator}", mu = np.log(0.5), sigma = 0.1)

    factor_disease = pm.Deterministic(f"factor_{indicator}", amplitude_disease*(1/(1+np.exp((idx/slope_disease-shift_disease)))) + intercept_disease)
    #factor_disease = pm.Deterministic(f"factor_{indicator}", np.exp(-idx/slope_disease))
    
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
    daylight_in=None,
    pop_density_in=None
):
    len_data = observed_mobility_data_in.shape[0]
    with model_in:
        # define data
        m = duration_base(base_mobility_data_in)

        # impact of disease spread
        if indicators_in is not None:
            for indicator in indicators_in:
                mu_z_prior = np.power(0.9, 1/len(indicators_in))
                m *= disease_factor(indicator, disease_data_in, len_data, mu_z_prior)

        if pop_density_in is not None:
            m *= pop_density_factor(pop_density_in)

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

        ## daylight
        if daylight_in is not None:
            m *= daylight_factor(daylight_in)

        # define likelihood
        m = pm.Deterministic("m", m)
        model_error = pm.HalfCauchy("sigma_model", beta=0.2)
        d = pm.Normal(
            "d", mu=m, sigma=model_error, observed=observed_mobility_data_in
        )
