# general modules
import numpy as np
import pymc as pm
import pandas as pd
from pyparsing import alphanums
import pytensor.tensor as at
#import xarray as xr

# local modules
import covid19_inference as cov19
import covid19_inference.model

#Out-of-home-duration_base --> DEPENDS ON FED STATE
def duration_base(d_base_input, fedState_idx, time_counter_in):
    """
    Args:

    Returns:
    Base duration
    """
    
    time_counter = pm.MutableData(f"counter", time_counter_in["time counter"], dims = ("obs_id"))

    mu_dbase = pm.Normal("mu_dbase_hyperprior", mu=0, sigma=0.1)
    sigma_dbase = pm.Exponential("sigma_dbase_hyperprior", 10)
    #d_factor = pm.Normal("d_factor", mu = mu_dbase, sigma = sigma_dbase , dims = ("fedState"))
    d_factor_tilde_2020 = pm.Normal("d_factor_tilde", mu = 0, sigma = 1, dims=("fedState"))
    d_factor_2020 = pm.Deterministic("d_factor", at.exp(mu_dbase + sigma_dbase*d_factor_tilde_2020), dims=("fedState"))

    # mu_dbase2024 = pm.Normal("mu_dbase_hyperprior2024", mu=0, sigma=0.1)
    # sigma_dbase2024 = pm.Exponential("sigma_dbase_hyperprior2024", 10)
    # d_factor_tilde_2024 = pm.Normal("d_factor_tilde2024", mu = 0, sigma = 1, dims=("fedState"))
    # d_factor_2024 = pm.Deterministic("d_factor2024", at.exp(mu_dbase2024 + sigma_dbase2024*d_factor_tilde_2024), dims=("fedState"))

    # d_factor_fin = pm.math.switch(56 > time_counter, d_factor_2020[fedState_idx], d_factor_2024[fedState_idx])

    d_base = pm.Deterministic("d_base", d_base_input*d_factor_2020[fedState_idx], dims=("obs_id"))

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
    mu_vac = pm.Uniform("mu_vac", lower=0.8, upper=1.0)
    #sigma_vac = pm.HalfCauchy("sigma_vac", beta = 10)
    sigma_vac = pm.Exponential("sigma_vac", 10)
    theta_tilde = pm.Normal("theta_v_tilde", mu = 0, sigma = 1, dims=("fedState"))
    theta = pm.Deterministic("theta_v", mu_vac + sigma_vac*theta_tilde, dims=("fedState"))


    #scale_v = pm.LogNormal("scale_v", mu=np.log(0.5), tau=5)
    v = pm.Deterministic("vacation_factor", (((theta[fedState_idx]-1) / 7 )* vacation_data + 1), dims = "obs_id")
    
    return v

def holiday_factor(holiday_data_in, fedState_idx):
    """
    Args:
    holiday_data_in: Public holiday data

    Returns:
    Public holiday vacation modulation factor (pymc variable)
    """
    holiday_data = pm.MutableData("holiday_data_in", holiday_data_in["pub holiday"], dims ="obs_id")

    mu_hol = pm.Uniform("mu_hol", lower=0.9, upper=1.0)
    #theta = pm.Normal("theta_h", mu = mu_hol, sigma = sigma_hol, dims = "fedState")
    sigma_hol = pm.Exponential("sigma_hol", 10)
    theta_tilde = pm.Normal("theta_h_tilde", mu = 0, sigma = 1, dims=("fedState"))
    theta = pm.Deterministic("theta_h", mu_hol + sigma_hol*theta_tilde, dims=("fedState"))

    h = pm.Deterministic("holiday_factor", (((theta[fedState_idx]-1) / 7)* holiday_data + 1), dims = "obs_id")
    
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

    mu_amp_temp = pm.HalfCauchy("mu_amp_temp", beta = 1)
    #mu_amp_temp = pm.Lognormal("mu_amp_temp", mu = np.log(1.3), sigma = 0.5)
    #sigma_amp_temp = pm.HalfCauchy("sigma_amp_temp", beta = 10)
    #sigma_amp_temp = pm.Gamma(f"sigma_amp_temp", alpha = 2, beta = 1)
    sigma_amp_temp = pm.Exponential("sigma_amp_temp", 10)
    #amplitude_temperature = pm.Normal("amplitude_temperature", mu = mu_amp_temp, sigma = sigma_amp_temp, dims = "fedState")
    amplitude_temperature_tilde = pm.Normal("amplitude_temperature_tilde", mu = 0, sigma = 1, dims=("fedState"))
    amplitude_temperature = pm.Deterministic("amplitude_temperature", mu_amp_temp + sigma_amp_temp*amplitude_temperature_tilde, dims=("fedState"))

    #shift_temperature = pm.LogNormal("shift_temperature", mu = np.log(20), sigma = 0.2)
    mu_shift_temp = pm.Normal("mu_shift_temp", mu = 15, sigma = 3)
    #sigma_shift_temp = pm.HalfCauchy("sigma_shift_temp", beta = 10)
    sigma_shift_temp = pm.Exponential(f"sigma_shift_temp", 10)
    #shift_temperature = pm.Normal("shift_temperature", mu = mu_shift_temp, sigma = sigma_shift_temp, dims = "fedState") #Updated according to J's recommendation 
    shift_temperature_tilde = pm.Normal("shift_temperature_tilde", mu = 0, sigma = 1, dims=("fedState"))
    shift_temperature = pm.Deterministic("shift_temperature", mu_shift_temp + sigma_shift_temp*shift_temperature_tilde, dims=("fedState"))

    mu_slope_temp = pm.Normal("mu_slope_log_temp", mu = np.log(4), sigma = 0.5)
    mu_slope_exp_temp = pm.Deterministic("mu_slope_temp", at.exp(mu_slope_temp))
    #sigma_slope_temp = pm.HalfCauchy("sigma_slope_temp", beta = 10)
    #sigma_slope_temp = pm.Gamma(f"sigma_slope_temp", alpha = 2, beta = 1)
    sigma_slope_temp = pm.Exponential("sigma_slope_temp", 10)
    #slope_temperature = pm.Normal("slope_temperature", mu = mu_slope_temp, sigma = sigma_slope_temp, dims = "fedState")
    slope_temperature_tilde = pm.Normal("slope_temperature_tilde", mu = 0, sigma = 1, dims=("fedState"))
    slope_temperature = pm.Deterministic("slope_temperature", at.exp(mu_slope_temp + sigma_slope_temp*slope_temperature_tilde), dims=("fedState"))

    #intercept_temperature = pm.LogNormal("intercept_temperature", mu = np.log(1), sigma = 0.1, dims = "fedState")
    #intercept_temperature = pm.Deterministic("intercept_temperature", 1 - amplitude_temperature*(1/(1+np.exp(-(15/slope_temperature-shift_temperature)))), dims = "fedState")
    intercept_temperature = pm.Deterministic("intercept_temperature", 1-amplitude_temperature/2)

    temperature_factor = pm.Deterministic("temperature_factor", amplitude_temperature[fedState_x]*(1/(1+np.exp(-(Tmax_2020-shift_temperature[fedState_x])/(slope_temperature[fedState_x]+0.05)))) + intercept_temperature[fedState_x], dims = "obs_id")

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
    
    mu_amp_light = pm.HalfCauchy("mu_amp_daylight", beta = 0.5)
    sigma_amp_light = pm.HalfCauchy("sigma_amp_daylight", beta = 10)
    amplitude_daylight = pm.Normal("amplitude_daylight", mu = mu_amp_light, sigma = sigma_amp_light, dims = "fedState") #Based on advice by J, a HalfCauchy distr. is being used
    
    mu_shift_light = pm.Normal("mu_shift_daylight", mu = 12, sigma = 1)
    sigma_shift_light = pm.HalfCauchy("sigma_shift_daylight", beta = 10)
    shift_daylight = pm.Normal("shift_daylight", mu = mu_shift_light, sigma = sigma_shift_light, dims = "fedState") 
    
    mu_slope_light = pm.LogNormal("mu_slope_daylight", mu = np.log(1), sigma = 0.1,)
    sigma_slope_light = pm.HalfCauchy("sigma_slope_daylight", beta = 10)
    slope_daylight = pm.Normal("slope_daylight", mu = mu_slope_light, sigma = sigma_slope_light, dims = "fedState")
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
def disease_factor(indicator, disease_data_in, time_counter_in, len_data, fedState_idx, counter, mu_z_prior_1=0.7, mu_z_prior_2=0.8, model = None, chosen_model = None, incl2024 = True):
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

    time_counter = pm.MutableData(f"counter_{indicator}", time_counter_in["time counter"], dims = ("obs_id"))
    time_counter_long = pm.MutableData(f"counter_{indicator}_long", time_counter_in["time_counter_long"], dims = ("obs_id_long"))

    ## define priors
    mu_gamma_disease = pm.Normal(f"mu_gamma_log_{indicator}", mu=3, sigma=0.5) #Mean of Gamma distribution
    mu_gamma_exp_disease = pm.Deterministic(f"mu_gamma_{indicator}", at.softplus(mu_gamma_disease)) #Mean of Gamma distribution
    # #sigma_gamma_disease = pm.HalfCauchy(f"sigma_gamma_{indicator}", beta = 5)
    # #sigma_gamma_disease = pm.Gamma(f"sigma_gamma_{indicator}", alpha = 2, beta = 1)    
    #sigma_gamma_disease = pm.Exponential(f"sigma_gamma_{indicator}", 10)
    sigma_gamma_disease = pm.HalfNormal(f"sigma_gamma_{indicator}", sigma = 0.5)
    mu_disease_tilde = pm.Normal(f"mu_{indicator}_tilde", mu = mu_gamma_disease, sigma = sigma_gamma_disease, dims = "fedState")
    mu_disease = pm.Deterministic(f"mu_{indicator}", at.softplus(mu_disease_tilde), dims = "fedState")
    
    alpha_disease = pm.LogNormal(f"alpha_{indicator}", mu=np.log(3), sigma=0.5) 
    sigma_disease = pm.Deterministic( #Variance of Gamma Distribution
        f"sigma_{indicator}", mu_disease / at.sqrt(alpha_disease+0.05), dims = "fedState"
    )
    
    if chosen_model == "cities":
        disease_data = pd.read_csv("./data/input_data_hierarchical/casesmatrix_cities.csv", header = 0, index_col=0, parse_dates=True)
        disease_data = pm.Data(f"disease_{indicator}_long", np.array(disease_data))
    if chosen_model == "fedStates":
        if incl2024 == True:
            disease_data = pd.read_csv("./data/input_data_hierarchical/casesmatrix_fedstates.csv", header = 0, index_col=0, parse_dates=True)
            disease_data = pm.Data(f"disease_{indicator}_long", np.array(disease_data))
        else:
            disease_data = pd.read_csv("./data/input_data_hierarchical/casesmatrix_fedstates_no2024.csv", header = 0, index_col=0, parse_dates=True)
            disease_data = pm.Data(f"disease_{indicator}_long", np.array(disease_data))
    if chosen_model == "fedStates_nat":
        if incl2024 == True:
            disease_data = pd.read_csv("./data/input_data_hierarchical/casesmatrix_fedstates_nat.csv", header = 0, index_col=0, parse_dates=True)
            disease_data = pm.Data(f"disease_{indicator}_long", np.array(disease_data))
        else:
            disease_data = pd.read_csv("./data/input_data_hierarchical/casesmatrix_fedstates_nat_no2024.csv", header = 0, index_col=0, parse_dates=True)
            disease_data = pm.Data(f"disease_{indicator}_long", np.array(disease_data))
    if chosen_model == "countieswithproblems":
        disease_data = pd.read_csv("./data/input_data_hierarchical/casesmatrix_countieswithproblems.csv", header = 0, index_col=0, parse_dates=True)
        disease_data = pm.Data(f"disease_{indicator}_long", np.array(disease_data))
    if chosen_model == "cities_MeckPomm":
        disease_data = pd.read_csv("./data/input_data_hierarchical/casesmatrix_cities_MeckPomm.csv", header = 0, index_col=0, parse_dates=True)
        disease_data = pm.Data(f"disease_{indicator}_long", np.array(disease_data))
    if chosen_model == "large":
        disease_data = pd.read_csv("./data/input_data_hierarchical/casesmatrix_large.csv", header = 0, index_col=0, parse_dates=True)
        disease_data = pm.Data(f"disease_{indicator}_long", np.array(disease_data))
    if chosen_model == "firsthundred":
        if incl2024 == True:
            disease_data = pd.read_csv("./data/input_data_hierarchical/casesmatrix_firsthundred.csv", header = 0, index_col=0, parse_dates=True)
            disease_data = pm.Data(f"disease_{indicator}_long", np.array(disease_data))
        else:
            disease_data = pd.read_csv("./data/input_data_hierarchical/casesmatrix_firsthundred_no2024.csv", header = 0, index_col=0, parse_dates=True)
            disease_data = pm.Data(f"disease_{indicator}_long", np.array(disease_data))
    if chosen_model == "secondhundred":
        disease_data = pd.read_csv("./data/input_data_hierarchical/casesmatrix_secondhundred.csv", header = 0, index_col=0, parse_dates=True)
        disease_data = pm.Data(f"disease_{indicator}_long", np.array(disease_data))
    if chosen_model == "thirdhundred":
        disease_data = pd.read_csv("./data/input_data_hierarchical/casesmatrix_thirdhundred.csv", header = 0, index_col=0, parse_dates=True)
        disease_data = pm.Data(f"disease_{indicator}_long", np.array(disease_data))
    if chosen_model == "fourthhundred":
        disease_data = pd.read_csv("./data/input_data_hierarchical/casesmatrix_fourthhundred.csv", header = 0, index_col=0, parse_dates=True)
        disease_data = pm.Data(f"disease_{indicator}_long", np.array(disease_data))
    if chosen_model == "firstsecondhundred":
        disease_data = pd.read_csv("./data/input_data_hierarchical/casesmatrix_firstsecondhundred.csv", header = 0, index_col=0, parse_dates=True)
        disease_data = pm.Data(f"disease_{indicator}_long", np.array(disease_data))
    if chosen_model == "fourhundred":
        disease_data = pd.read_csv("./data/input_data_hierarchical/casesmatrix_fourhundred.csv", header = 0, index_col=0, parse_dates=True)
        disease_data = pm.Data(f"disease_{indicator}_long", np.array(disease_data))
    if chosen_model == "thirdfourthhundred":
        disease_data = pd.read_csv("./data/input_data_hierarchical/casesmatrix_thirdfourthhundred.csv", header = 0, index_col=0, parse_dates=True)
        disease_data = pm.Data(f"disease_{indicator}_long", np.array(disease_data))
    
    if incl2024:
        long = 108
        short = 104
    else:
        long = 56
        short = 52
    
    # convolve disease data with delay kernel
    risk = cov19.model.delay._delay_kernel(
        input_arr=disease_data,
        kernel_type="gamma",
        median_delay=mu_disease,
        scale_delay= sigma_disease,
        len_input_arr=long,
        len_output_arr=short,
        #num_seperated_axes = 10,
        delay_betw_input_output=4,
    )
    
    risk = pm.Deterministic(f"risk_{indicator}", risk.T.flatten(), dims = ("obs_id"))

    mu_slope_disease = pm.Normal(f"mu_slope_log_{indicator}", mu = 15, sigma = 2)
    mu_slope_exp_dis = pm.Deterministic(f"mu_slope_{indicator}", at.softplus(mu_slope_disease))
    #sigma_slope_disease = pm.HalfCauchy(f"sigma_slope_{indicator}", beta = 10)
    #sigma_slope_disease = pm.Gamma(f"sigma_slope_{indicator}", alpha = 2, beta = 1)
    #sigma_slope_disease = pm.Exponential(f"sigma_slope_{indicator}", 10)
    sigma_slope_disease = pm.HalfNormal(f"sigma_slope_{indicator}", sigma = 2)
    slope_disease_tilde = pm.Normal(f"slope_{indicator}_tilde", mu = mu_slope_disease, sigma = sigma_slope_disease, dims=("fedState"))
    slope_disease = pm.Deterministic(f"slope_{indicator}", at.softplus(slope_disease_tilde), dims=("fedState"))
    
    mu_multiplicator_disease = pm.Normal(f"mu_multiplicator_log_{indicator}", mu = np.log(1.5), sigma = 0.5)
    mu_multiplicator_disease = pm.Deterministic(f"mu_multiplicator_{indicator}", at.exp(mu_multiplicator_disease))
    sigma_multiplicator_disease = pm.Exponential(f"sigma_multiplicator_{indicator}", 10)
    multiplicator_disease_tilde = pm.Normal(f"multiplicator_{indicator}_tilde", mu = 0, sigma = 1, dims=("fedState"))
    multiplicator_disease = pm.Deterministic(f"multiplicator_{indicator}", at.exp(mu_multiplicator_disease + sigma_multiplicator_disease*multiplicator_disease_tilde), dims=("fedState"))

    factor_disease = pm.Deterministic(f"factor_{indicator}", multiplicator_disease[fedState_idx]*np.exp(-time_counter/(slope_disease[fedState_idx]+0.01)), dims=("obs_id"))
    
    #factor_disease_fin = pm.math.switch(56 > time_counter, factor_disease, 0)
    #factor_disease_fin = pm.math.switch(time_counter < 52, factor_disease, 0)
    # # #factor_disease = pm.Deterministic(f"factor_{indicator}", np.exp(disease_data/1), dims=("fedState"))
    #exponent = pm.Deterministic(f"exponent_{indicator}", - factor_disease * risk, dims = "fedState")

    d = pm.Deterministic(f"d_{indicator}", at.exp(- factor_disease*risk), dims = "obs_id")

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
    fed_states_in_long=None,
    lk_in=None,
    lk_in_long=None,
    counter_in=None,
    chosen_model_in=None,
    incl2024_in = True
):

    len_data = observed_mobility_data_in.shape[0]
    with model_in:
        #lk_name = pm.MutableData("lk_name", lk_in, dims=("obs_id",))
        #lk_name_long = pm.MutableData("lk_name_long", lk_in_long, dims=("obs_id_long",))
        fedState_x = pm.MutableData("fedState_idx", fed_states_in, dims=("obs_id",))
        fedState_x_long = pm.MutableData("fedState_idx_long", fed_states_in_long, dims=("obs_id_long",))
        # define data
        m = duration_base(base_mobility_data_in, fedState_x, time_counter_in)

        # # # #impact of disease spread
        if indicators_in is not None:
            for indicator in indicators_in:
                mu_z_prior1 = np.power(0.9, 1/len(indicators_in))
                mu_z_prior2 = np.power(0.9, 1/len(indicators_in))
                m *= disease_factor(indicator, disease_data_in, time_counter_in, len_data, fed_states_in, mu_z_prior1, mu_z_prior2, model = model_in, chosen_model = chosen_model_in, incl2024 = incl2024_in)

        if pop_density_in is not None:
            m *= pop_density_factor(pop_density_in, fed_states_in)

        #impact of school vacations
        if school_in is not None:
            m *= vacation_factor(school_in, fed_states_in)

        # # #impact of holiday data
        if holiday_in is not None:
            m*= holiday_factor(holiday_in, fed_states_in)

        # # #impact of weather
        # # # precipitation
        if precipitation_in is not None:
            m *= precipitation_factor(precipitation_in, fed_states_in)
            
        # # temperature
        if temperature_in is not None:
            m *= temperature_factor(temperature_in, fed_states_in)

        # # # daylight
        if daylight_in is not None:
            m *= daylight_factor(daylight_in, fed_states_in)

        # # # define likelihood

        m = pm.Deterministic("m", m, dims="obs_id") #Here: dims=fedState?? or rather m[fedState_idx]?

        model_error = pm.HalfCauchy("sigma_model", beta=2)
        d = pm.StudentT(
            "d", mu=m, sigma=model_error+0.01, nu = 4, observed=observed_mobility_data_in, dims="obs_id"
        )
