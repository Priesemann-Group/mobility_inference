import numpy as np
import pymc as pm
import pytensor.tensor as at

import covid19_inference.covid19_inference as cov19


# For the weather
def generate_Tstar(amplitude, offset, shift, length):
    x = at.linspace(0, length, length)
    return pm.Deterministic("T_star", -at.power(amplitude * (x + shift), 4.0) + offset)


## function for modulating the impact of temperature
def Gaussian(T, T_star, a):
    return pm.Deterministic("r", at.exp(-a * at.power(T - T_star, 2.0)))


def temperature_factor(len_data_in, avg_temperature_in, delta_temperature_in):
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
    a_r = pm.LogNormal("a_r", mu=np.log(0.01), tau=1)
    weather_relevance = Gaussian(avg_temperature_in, T_star, a_r)
    w = pm.Deterministic(
        "w", at.exp(delta_temperature_in * weather_relevance * factor_weather)
    )

    return w


def precipitation_factor(delta_prcp_in):
    delta_prcp = pm.ConstantData("delta_prcp", delta_prcp_in)
    z_P = pm.LogNormal("z_P", mu=np.log(0.05), tau=0.5)
    w = pm.Deterministic("w", at.exp(-z_P * delta_prcp))
    return w


# impact of pandemic fatigue: linear version
def pandemic_fatigue_factor_linear(len_in):
    x = at.linspace(0, len_in, len_in)
    max_x = len_in - 1
    ## pandemic fatigue at the start
    p0 = pm.LogNormal("p0", mu=np.log(1.01), tau=20)
    ## pandemic fatigue rate
    r = pm.TruncatedNormal("r", mu=0.2 / max_x, sigma=0.01 / max_x, lower=-p0 / max_x)
    ## pandemic fatigue
    p = pm.Deterministic("p", p0 + r * x)
    return p


def sigmoid(x, del_t, del_y, v_change, p0=1):
    return del_y / (1 + at.exp(-v_change * (x + del_t))) + p0


# imapct of pandemic fatigue: sigmoid version
def pandemic_fatigue_factor_sigmoid(len_in):
    x = at.linspace(0, len_in, len_in)

    ## location of the change point
    del_t = pm.Normal("del_t", len_in / 2, sigma=len_in / 4)
    ## maximum increase in pandemic fatigue
    del_p = pm.Normal("del_p", mu=0.2, sigma=0.1)
    ## time scale of pandemic fatigue
    tau = pm.LogNormal("tau", mu=np.log(1), tau=1)

    ## pandemic fatigue
    p = pm.Deterministic("p", sigmoid(x, del_t, del_p, tau))
    return p


# model
def create_model(
    model_in,
    base_mobility_data_in,
    observed_mobility_data_in,
    S_data_in,
    school_data_in,
    kurzarbeit_data_in,
    indicators_in,
    disease_data_in,
    delta_prcp_in=None,
):
    len_data = observed_mobility_data_in.shape[0]
    with model_in:
        # define data
        m_base_data = pm.ConstantData("m_base", base_mobility_data_in)
        S_data = pm.ConstantData("S", S_data_in)
        school_data = pm.ConstantData("school_closures", school_data_in)
        kurzarbeit_data = pm.ConstantData("kurzarbeit", kurzarbeit_data_in)
        # delta_weather = pm.ConstantData("delta_weather", del_weather_data_in)
        # avg_weather = pm.ConstantData("avg_weather", avg_weather_data_in)

        # kurzarbeit
        delta_o = pm.LogNormal("delta_o", mu=np.log(5), tau=10)
        m = pm.Deterministic("o_*", m_base_data - delta_o * kurzarbeit_data)

        # impact of disease spread
        mu_z_prior = 0.9 ** len(indicators_in)
        for indicator in indicators_in:
            disease_data = pm.ConstantData(indicator, disease_data_in[indicator])
            disease_data_len = disease_data.shape[0].eval()

            ## define priors
            factor_disease = pm.LogNormal(
                f"z_{indicator}", mu=np.log(mu_z_prior), tau=10
            )
            mu_disease = pm.LogNormal(f"mu_{indicator}", mu=np.log(0.9), tau=10)
            delta = pm.LogNormal(f"delta_{indicator}", mu=np.log(0.1), tau=1)
            sigma_disease = pm.Deterministic(f"sigma_{indicator}", mu_disease - delta)
            ## convolution: SOMETHING IS AMISS HERE
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
            m = m * d

        # impact of NPIs
        ## stay-at-home orders
        ### define priors
        z_S = pm.LogNormal("z_S", mu=np.log(0.95), tau=10)
        ### put it together
        exponent = -z_S * S_data
        s = pm.Deterministic("s", at.exp(exponent))
        m = m * s
        ## school closures
        ### define priors
        z_school = pm.LogNormal("z_school", mu=np.log(0.95), tau=10)
        ### put it together
        exponent = -z_school * school_data
        c = pm.Deterministic("c", at.exp(exponent))
        m = m * c

        # impact of pandemic fatigue
        # p = pandemic_fatigue_factor_linear(len_data)
        # p = pandemic_fatigue_factor_sigmoid(len_data)
        # m = m * p

        # define likelihood
        m = pm.Deterministic("m", m)
        model_error = pm.HalfCauchy("sigma_model", beta=0.5)
        likelihood = pm.Normal(
            "likelihood", mu=m, sigma=model_error, observed=observed_mobility_data_in
        )
