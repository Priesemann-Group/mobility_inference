import numpy as np
import arviz as az
import xarray as xr
import datetime
import warnings

import matplotlib.pyplot as plt

plt.rcParams.update({"font.size": 20})
from matplotlib import lines, patches
from matplotlib import colormaps

# to import FormatStrFormatter
#import matplotlib.ticker as ticker

import covid19_inference as cov19
import utils

colormap = colormaps["tab20b"]
colors = {
    # diseaes
    "R": colormap(0.0),
    "logR": colormap(0.0),
    "C": colormap(0.05),
    "logC": colormap(0.05),
    "H": colormap(0.1),
    "logH": colormap(0.1),
    "ICU": colormap(0.15),
    "logICU": colormap(0.15),
    "D": (0.803921568627451, 0.807843137254902, 0.9294117647058824, 1),
    "logD": (0.803921568627451, 0.807843137254902, 0.9294117647058824, 1),
    "G": colormap(0.0),
    # NPI
    ## population density
    "pop": colormap(0.2),
    ## school vacation
    "v": colormap(0.25),
    ## public holidays
    "h": colormap(0.3),
     # daylight
    "L": colormap(0.7),
    # temperature
    "T": colormap(0.4),
    "delT": colormap(0.45),
    # precipitation
    "p": colormap(0.5),
    "w_2022": colormap(0.55),
    # pandemic fatigue
    "f": colormap(0.6),
    "sigmoid": colormap(0.75),
    # out-of-home duration
    "d": colormap(0.8),
    "d_obs": colormap(0.85),
    "d_*": colormap(0.9),
    "d_base": colormap(0.95),
}


def concatenate_chains_and_draws(xarray_in):
    array = np.array(xarray_in)
    return array.reshape(-1, array.shape[-1])


def plot_timeseries(ax_in, x_in, array_in, label_in, color_in, alpha=0.5):
    if type(array_in) == xr.DataArray:
        array = concatenate_chains_and_draws(array_in)
    else:
        array = array_in
    ax_in.plot(
        x_in, np.median(array, axis=0), label=label_in, color=color_in, linewidth=3
    )
    ax_in.fill_between(
        x_in,
        np.percentile(array, q=3, axis=0),
        np.percentile(array, q=97, axis=0),
        alpha=alpha,
        color=color_in,
    )


def format_x_axis(ax_in, x_in, last=False, n_xticks=6, year=2020):
    # get x tick locations
    xticks = np.linspace(0, len(x_in) - 1, n_xticks, dtype=int)
    # get x tick labels
    xticklabels = [x_in[i] for i in xticks]
    # set x ticks
    ax_in.set_xticks([x_in[i] for i in xticks])
    # increase x tick length
    ax_in.tick_params(axis="x", length=10)
    if last:
        # set x tick labels
        ax_in.set_xticklabels(xticklabels)
        ax_in.set_xlabel(f"Year {year}")
    else:
        # set x tick labels
        ax_in.set_xticklabels([])
    # set x limits
    ax_in.set_xlim(x_in[0], x_in[-1])


def Gamma(x, mu=None, sigma=None, alpha=None, beta=None):
    """
    Calculates a gamma distribution pdf for integer spaced x input. Parametrized similarly to
    :class:`pymc.Gamma`
    """
    assert (alpha is None and beta is None) != (mu is None and sigma is None)
    if alpha is None and beta is None:
        alpha = mu**2 / (sigma**2 + 1e-8)
        beta = mu / (sigma**2 + 1e-8)
    with warnings.catch_warnings():
        warnings.filterwarnings("ignore", message=".*invalid value encountered.*")
        distr = beta**alpha * x ** (alpha - 1) * np.exp(-beta * x)
    distr = np.where(np.isnan(distr), np.zeros_like(distr), distr)
    distr = np.where(np.isinf(distr), np.zeros_like(distr), distr)

    # normalize, add a small offset in case the sum is zero
    return distr / (np.sum(distr, axis=0) + 1e-8)


def get_values(tag_in, variable_in, trace):
    array = np.array(trace.posterior[f"{variable_in}_{tag_in}"])
    return array.reshape(-1)


def plot_gamma_parameters(trace, indicators, tag_in):
    for indicator in indicators:
        # make scatter plot of mu and sigma of gamma kernel
        fig, ax = plt.subplots(1, 1, figsize=(2, 2))

        # get kernel data
        mus = get_values(indicator, "mu", trace)
        sigmas = get_values(indicator, "sigma", trace)

        # plot
        ax.scatter(mus, sigmas, color=colors[indicator], alpha=0.1)
        ax.set_xlabel(f"$\\mu_{indicator}$")
        ax.set_ylabel(f"$\\sigma_{indicator}$")
        # ax.set_title(f"Gamma kernel\nparameters for {indicator}")

        # save figure
        fig.savefig(f"{tag_in}/gamma_parameters_{indicator}.png", bbox_inches="tight")
        fig.savefig(f"{tag_in}/gamma_parameters_{indicator}.pdf", bbox_inches="tight")


def plot_convolution(tag, axs, last, trace, dates):
    # get kernel data
    mus = get_values(tag, "mu", trace)
    sigmas = get_values(tag, "sigma", trace)

    mu_median = round(np.median(mus), 1)
    xmax = 2 * mu_median
    x = np.linspace(0, xmax, 100)
    ys = []
    for i in range(len(mus)):
        mu = mus[i]
        sigma = sigmas[i]
        y = Gamma(
            x,
            mu=mu,
            sigma=sigma,
        )
        ys.append(y)
    # make ndarray of ys
    ys = np.array(ys)

    # plot the gamma kernel
    ax = axs[0]
    plot_timeseries(ax, x, ys, "", colors[tag])
    ymax = 5 * np.median(ys)
    ax.vlines(mu_median, 0, ymax, linestyle="--", color="grey")
    ax.text(
        mu_median * 1.1,
        0.8 * ymax,
        f"$\\tilde{{\mu}}_{{{tag}}}={mu_median}$",
        ha="left",
        va="bottom",
    )
    ax.set_xlim(0, xmax)
    ax.set_ylim(0, ymax)
    ax.set_xlabel("Week")

    # plot the 'data'
    ax = axs[1]
    # plot input data
    ax.plot(
        dates,
        trace.constant_data[tag].values[-len(dates):],
        marker="o",
        label="input",
        color=colors[tag],
    )
    # plot the convolution
    plot_timeseries(ax, dates, trace.posterior[f"risk_{tag}"], "convolved", colors[tag])
    format_x_axis(ax, dates, last=last)
    ax.set_ylim(0, 1)

    labels = {
        "C": "Cases $C$",
        "ICU": "ICU patients ${ICU}$",
        "H": "Hospitalisations $H$",
        "R": "Effective Reproduction Number $R$",
        "D": "Deaths $D$",
        "G": "Growth Multiplier $G$",
    }
    ax.set_title(labels[tag], x=0, y=1.1)


def convolution_figure(indicators, trace, dates, directory):
    # prepare plot
    fig, axs = plt.subplots(
        len(indicators), 2, figsize=(12, 3 * len(indicators)), width_ratios=[1, 2]
    )
    axs = axs.flatten()
    for i in range(len(indicators)):
        if i == len(indicators) - 1:
            last = True
        else:
            last = False
        plot_convolution(
            indicators[i], (axs[2 * i], axs[2 * i + 1]), last, trace, dates
        )
    # add vertical padding
    fig.subplots_adjust(hspace=0.6)
    # title
    if len(indicators) == 1:
        y = 1.5
    elif len(indicators) == 2:
        y = 1.16
    elif len(indicators) == 3:
        y = 1.1
    else:
        y = 1.05
    fig.suptitle("Perceived disease spread: memory kernel and convolution", y=y)

    # create custom legends
    ## convolved
    ax = axs[1]
    ### for median line and 94% CI
    convolved = lines.Line2D([], [], color="black", linewidth=3, label="convolved")
    input = lines.Line2D([], [], color="black", linewidth=1, marker="o", label="input")
    ### legend height
    if len(indicators) == 1:
        height = 1.5
    else:
        height = 1.7
        
    ### create legend
    legend1 = ax.legend(
        handles=[input, convolved], frameon=True, bbox_to_anchor=(1.1, height), ncol=2
    )
    ax.add_artist(legend1)
    ## median
    ax = axs[0]
    ### for median line and 94% CI
    median_line = lines.Line2D([], [], color="black", linewidth=3, label="median")
    ci_94 = patches.Patch(color="black", alpha=0.5, label="94% CI")
    ### create legend
    legend2 = ax.legend(
        handles=[median_line, ci_94], frameon=False, bbox_to_anchor=(1.4, height), ncol=2
    )
    ax.add_artist(legend2)

    # save figure
    fig.savefig(f"{directory}/convolution.png", bbox_inches="tight")
    fig.savefig(f"{directory}/convolution.pdf", bbox_inches="tight")


## plot Gamma distribution with inferred mean and standard deviation
def plot_gamma_kernel(trace_in, tag_in, indicators_in):
    fig, ax = plt.subplots(1, 1, figsize=(5, 4))

    # prepare
    mu_median, sigma_median = 0, 0
    for indicator in indicators_in:
        if mu_median < np.median(trace_in.posterior[f"mu_{indicator}"]):
            mu_median = np.median(trace_in.posterior[f"mu_{indicator}"])
            sigma_median = np.median(trace_in.posterior[f"sigma_{indicator}"])
    max_x = (2 + sigma_median) * mu_median
    x = np.linspace(0, max_x, 100)
    ys = []

    # plot
    for indicator in indicators_in:
        mu_median = np.median(trace_in.posterior[f"mu_{indicator}"])
        sigma_median = np.median(trace_in.posterior[f"sigma_{indicator}"])
        y = Gamma(
            x,
            mu=mu_median,
            sigma=sigma_median,
        )
        ys.append(y)
        ax.plot(x, y, linewidth=3, label=f"${indicator}$", color=colors[indicator])

    # format
    ax.set_xlabel("Week")
    ax.set_title("Inferred median\nGamma kernel")
    ax.set_xlim(0, max_x)
    ax.set_ylim(0, 1.1 * np.max(np.array(ys)))
    ax.legend()
    fig.tight_layout()

    fig.savefig(f"{tag_in}/gamma_kernel.png")
    fig.savefig(f"{tag_in}/gamma_kernel.pdf")


## plot temperature time series
def plot_temperature_timeseries(dates_in, trace_in, tag_in):
    fig, axs = plt.subplots(2, 1, figsize=(9, 9), sharex=True)

    # First plot
    ax = axs[0]
    plot_timeseries(
        ax,
        dates_in,
        trace_in.constant_data["max_Temp"],
        color_in=colors["T"],
        label_in="$T_2020$",
    )
    format_x_axis(ax, dates_in)
    ## set y label
    ax.set_ylabel("temperature [°C]")
    ## create custom legend
    ### for median line and 94% CI
    median_line = lines.Line2D([], [], color="black", linewidth=3, label="median")
    ci_94 = patches.Patch(color="black", alpha=0.5, label="94% CI")
    ### create legend
    ax.legend(handles=[median_line, ci_94], loc="lower right", frameon=False)

    # Second plot
    # ax = axs[1]
    # plot_timeseries(
    #     ax,
    #     dates_in,
    #     trace_in.posterior["T_star"],
    #     color_in=colors["T"],
    #     label_in="$T_*$",
    # )
    # format_x_axis(ax, dates_in)
    # # ## set y label
    # ax.set_ylabel("'go-out' temperature\n$T_*$ [°C]")
    # ## create custom legend
    # ### for median line and 94% CI
    # median_line = lines.Line2D([], [], color="black", linewidth=3, label="median")
    # ci_94 = patches.Patch(color="black", alpha=0.5, label="94% CI")
    # ### create legend
    # ax.legend(handles=[median_line, ci_94], loc="lower right", frameon=False)

    # lower plot
    ax = axs[1]
    plot_timeseries(
        ax,
        dates_in,
        trace_in.posterior["temperature_factor"],
        color_in=colors["T"],
        label_in="$Delta_temp$",
    )
    ax.set_ylim(0.75, 1.25)
    format_x_axis(ax, dates_in, last=True)
    # set y label
    ax.set_ylabel("temperature_factor")

    plt.subplots_adjust(hspace=0.1)

    # save figure
    fig.savefig(f"{tag_in}/temperature.png", bbox_inches="tight")
    fig.savefig(f"{tag_in}/temperature.pdf", bbox_inches="tight")

    ## plot daylight time series
def plot_daylight_timeseries(dates_in, trace_in, tag_in):
    fig, axs = plt.subplots(2, 1, figsize=(9, 9), sharex=True)

    # First plot
    ax = axs[0]
    plot_timeseries(
        ax,
        dates_in,
        trace_in.constant_data["daylight_data_in"],
        color_in=colors["L"],
        label_in="$Daylight$",
    )
    format_x_axis(ax, dates_in)
    ## set y label
    ax.set_ylabel("Daylight [hrs]")

    # Second plot
    # ax = axs[1]
    # plot_timeseries(
    #     ax,
    #     dates_in,
    #     trace_in.posterior["T_star"],
    #     color_in=colors["T"],
    #     label_in="$T_*$",
    # )
    # format_x_axis(ax, dates_in)
    # # ## set y label
    # ax.set_ylabel("'go-out' temperature\n$T_*$ [°C]")
    # ## create custom legend
    # ### for median line and 94% CI
    # median_line = lines.Line2D([], [], color="black", linewidth=3, label="median")
    # ci_94 = patches.Patch(color="black", alpha=0.5, label="94% CI")
    # ### create legend
    # ax.legend(handles=[median_line, ci_94], loc="lower right", frameon=False)

    # lower plot
    ax = axs[1]
    plot_timeseries(
        ax,
        dates_in,
        trace_in.posterior["daylight_factor"],
        color_in=colors["L"],
        label_in="Daylight factor",
    )
    ax.set_ylim(0.75, 1.25)
    format_x_axis(ax, dates_in, last=True)
    ## create custom legend
    ### for median line and 94% CI
    median_line = lines.Line2D([], [], color="black", linewidth=3, label="median")
    ci_94 = patches.Patch(color="black", alpha=0.5, label="94% CI")
    ### create legend
    ax.legend(handles=[median_line, ci_94], loc="lower right", frameon=False)

    # set y label
    ax.set_ylabel("daylight_factor")

    plt.subplots_adjust(hspace=0.1)

    # save figure
    fig.savefig(f"{tag_in}/daylight.png", bbox_inches="tight")
    fig.savefig(f"{tag_in}/daylight.pdf", bbox_inches="tight")


def plot_all_timeseries(
    dates_in,
    trace_in,
    tag_in,
    indicators_in,
    school_in=None,
    holiday_in=None,
    temperature_in=None,
    precipitation_in=None,
    daylight_in=None,
    pop_density_in=None,
    log=False,
):
    fig, axs = plt.subplots(
        3,
        1,
        figsize=(13, 17),
        sharex=True,
    )

    # middle plot
    ax = axs[0]
    labels = {
        "C": "new cases $d_C$",
        "logC": "log(new cases $d_C$)",
        "ICU": "ICU patients $d_{ICU}$",
        "logICU": "log(ICU patients $d_{ICU}$)",
        "H": "hospitalisations $d_H$",
        "logH": "log(hospitalisations $d_H$)",
        "R": "Reproduction Number $d_R$",
        "logR": "log(Reproduction Number $d_R$)",
        "D": "deaths $d_D$",
        "logD": "log(deaths $d_D$)",
        "G": "Growh Multiplier $d_G$",
    }
    ## plot disease indicators
    for indicator in indicators_in:
        plot_timeseries(
            ax,
            dates_in,
            trace_in.posterior[f"d_{indicator}"],
            color_in=colors[indicator],
            label_in=labels[indicator],
            alpha=0.2,
        )
        # daylight
    if daylight_in is not None:
       plot_timeseries(
           ax,
           dates_in,
           trace_in.posterior["daylight_factor"],
           color_in=colors["L"],
           label_in="daylight",
           alpha=0.2,
       )
    # school vacation
    if school_in is not None:
       plot_timeseries(
           ax,
           dates_in,
           trace_in.posterior["vacation_factor"],
           color_in=colors["v"],
           label_in="school vacation",
           alpha=0.2,
       )
    # public holidays
    if holiday_in is not None:
       plot_timeseries(
           ax,
           dates_in,
           trace_in.posterior["holiday_factor"],
           color_in=colors["h"],
           label_in="public holidays",
           alpha=0.2,
       )
    # temperature
    if temperature_in is not None:
       plot_timeseries(
           ax,
           dates_in,
           trace_in.posterior["temperature_factor"],
           color_in=colors["T"],
           label_in="temperature",
           alpha=0.2,
       )
    ## precipitation
    # if precipitation_in is not None:
    #     plot_timeseries(
    #         ax,
    #         dates_in,
    #         trace_in.posterior["precipitation_factor"],
    #         color_in=colors["p"],
    #         label_in="precipitation $p$",
    #         alpha=0.2,
    #     )
    ax.hlines(
        1,
        xmin=dates_in[0],
        xmax=dates_in[-1],
        color="grey",
        linestyle="--",
        linewidth=1,
    )
    format_x_axis(ax, dates_in)
    ## set y label
    ax.set_ylabel("Multiplicative impact on\nout-of-home duration")
    ax.legend(
        ncol=2,
        # bbox_to_anchor=(0.7, 2)
    )

    # middle plot
    ax = axs[1]
    plot_timeseries(
        ax,
        dates_in,
        trace_in.posterior["d_base"],
        color_in=colors["d"],
        label_in="base $d$",
        alpha=0.2,
    )
    format_x_axis(ax, dates_in, last=True)
    # set y label
    ax.set_ylabel("Out-of-home duration [h]")

    ## precipitation
    if pop_density_in is not None:
        plot_timeseries(
            ax,
            dates_in,
            trace_in.posterior["pop_density_factor"],
            color_in=colors["pop"],
            label_in="Pop density $pop$",
            alpha=0.2,
        )

    # lower plot
    ax = axs[2]
    ax.plot(
        dates_in,
        trace_in.observed_data["d"],
        label="input $d_{obs}$",
        color=colors["d_obs"],
        marker="o",
    )

    plot_timeseries(ax, dates_in, trace_in.posterior["m"], "inferred $d$", colors["d"])
    ax.legend(
        ncol=2,
        # bbox_to_anchor=(1.1, -0.4)
    )
    format_x_axis(ax, dates_in, last=True)
    # set y label
    ax.set_ylabel("Out-of-home duration [h]")

    # plt.subplots_adjust(hspace=0.1)
    fig.tight_layout()

    # save figure
    fig.savefig(f"{tag_in}/timeseries.png", bbox_inches="tight")
    fig.savefig(f"{tag_in}/timeseries.pdf", bbox_inches="tight")


# plot distribution for single indicator models
def plot_distributions(model_in, trace_in, tag_in, indicators_in, temperature_in, daylight_in):
    # --- base parameters ---
    if len(indicators_in) == 0:
        fig, axs = plt.subplots(1, 5, figsize=(13, 2))
    if len(indicators_in) == 1:
        fig, axs = plt.subplots(2, 5, figsize=(13, 5))
    elif len(indicators_in) == 2:
        fig, axs = plt.subplots(3, 5, figsize=(13, 8))
    elif len(indicators_in) == 3:
        fig, axs = plt.subplots(4, 5, figsize=(13, 10))
    elif len(indicators_in) == 4:
        fig, axs = plt.subplots(4, 5, figsize=(13, 10))
    elif len(indicators_in) == 5:
        fig, axs = plt.subplots(5, 5, figsize=(13, 12))

    # flatten axes
    axs = axs.flatten()

    cov19.plot.distribution( 
        model_in, trace_in, "d_factor", dist_math="d_{base}", ax=axs[0]
    )

    cov19.plot.distribution( 
        model_in, trace_in, "theta_v", dist_math="\\theta_{v}", ax=axs[1]
    )

    cov19.plot.distribution( 
        model_in, trace_in, "theta_h", dist_math="\\theta_{h}", ax=axs[2]
    )

    cov19.plot.distribution( 
        model_in, trace_in, "sigma_model", dist_math="\\sigma_{model}", ax=axs[3]
    )

    # disease
    i = 5
    for indicator in indicators_in:
        cov19.plot.distribution(
            model_in, trace_in, f"z1_{indicator}", dist_math=f"z1_{{{indicator}}}", ax=axs[i]
        )
        cov19.plot.distribution(
            model_in, trace_in, f"z2_{indicator}", dist_math=f"z2_{{{indicator}}}", ax=axs[i+1]
        )
        cov19.plot.distribution(
        
            model_in,
            trace_in,
            f"mu_{indicator}",
            dist_math=f"\mu_{{{indicator}}}",
            ax=axs[i + 2],
        )
        cov19.plot.distribution(
        
            model_in,
            trace_in,
            f"sigma_{indicator}",
            dist_math=f"\sigma_{{{indicator}}}",
            ax=axs[i + 3],
        )
        cov19.plot.distribution(
        
            model_in,
            trace_in,
            f"alpha_{indicator}",
            dist_math=f"\\alpha_{{{indicator}}}",
            ax=axs[i + 4],
        )
        i += 5

    fig.savefig(f"{tag_in}/distributions.png", dpi=300, bbox_inches="tight")
    fig.savefig(f"{tag_in}/distributions.pdf", dpi=300, bbox_inches="tight")

    # --- temperature ---
    if temperature_in:
        fig, axs = plt.subplots(1, 3, figsize=(13, 2))
        axs = axs.flatten()
        #cov19.plot.distribution(model_in, trace_in, "z_T", dist_math="z_{T}", ax=axs[0])
    
        cov19.plot.distribution(model_in, trace_in, "amplitude", dist_math="amplitude", ax=axs[0])

        cov19.plot.distribution(model_in, trace_in, "offset", dist_math="offset", ax=axs[1])
    
        cov19.plot.distribution(model_in, trace_in, "shift", dist_math="shift", ax=axs[2])

        #cov19.plot.distribution(model_in, trace_in, "slope", dist_math="slope", ax=axs[3])

        #cov19.plot.distribution(model_in, trace_in, "theta_w", dist_math="theta_w", ax=axs[4])

        #cov19.plot.distribution(model_in, trace_in, "theta_w_up", dist_math="theta_w", ax=axs[5])
        #cov19.plot.distribution(model_in, trace_in, "a_rho", dist_math="a_\\rho", ax=axs[4])
    
        fig.savefig(
            f"{tag_in}/distributions_temperature.png",
            dpi=300,
            bbox_inches="tight",
        )
        fig.savefig(
            f"{tag_in}/distributions_temperature.pdf",
            dpi=300,
            bbox_inches="tight",
        )
    # --- daylight ---
    if daylight_in:
        fig, axs = plt.subplots(1, 2, figsize=(13, 2))
        axs = axs.flatten()
        #cov19.plot.distribution(model_in, trace_in, "z_T", dist_math="z_{T}", ax=axs[0])
    
        cov19.plot.distribution(model_in, trace_in, "alpha_day", dist_math="alpha_day", ax=axs[0])

        cov19.plot.distribution(model_in, trace_in, "beta_day", dist_math="beta_day", ax=axs[1])
    
        #cov19.plot.distribution(model_in, trace_in, "shift", dist_math="shift", ax=axs[2])

        #cov19.plot.distribution(model_in, trace_in, "slope", dist_math="slope", ax=axs[3])

        #cov19.plot.distribution(model_in, trace_in, "theta_w", dist_math="theta_w", ax=axs[4])

        #cov19.plot.distribution(model_in, trace_in, "theta_w_up", dist_math="theta_w", ax=axs[5])
        #cov19.plot.distribution(model_in, trace_in, "a_rho", dist_math="a_\\rho", ax=axs[4])
    
        fig.savefig(
            f"{tag_in}/distributions_daylight.png",
            dpi=300,
            bbox_inches="tight",
        )
        fig.savefig(
            f"{tag_in}/distributions_daylight.pdf",
            dpi=300,
            bbox_inches="tight",
        )
    
    ## plot temperature time series
def plot_disease_timeseries(dates_in, trace_in, tag_in, indicators, disease_data, disease_data_raw):
    fig, axs = plt.subplots(3, 1, figsize=(9, 15), sharex=True)
    
    labels = {
        "C": "new cases $d_C$",
        "logC": "log(new cases $d_C$)",
        "ICU": "ICU patients $d_{ICU}$",
        "logICU": "log(ICU patients $d_{ICU}$)",
        "H": "hospitalisations $d_H$",
        "logH": "log(hospitalisations $d_H$)",
        "R": "Reproduction Number $d_R$",
        "logR": "log(Reproduction Number $d_R$)",
        "D": "deaths $d_D$",
        "logD": "log(deaths $d_D$)",
        "G": "Growh Multiplier $d_G$",
    }

    for indicator in indicators:
        disease_raw_2020 = disease_data_raw[f"{indicator}"][disease_data_raw[f"{indicator}"].index.isin(dates_in)] 
        # First plot
        ax = axs[0]
        plot_timeseries(
            ax,
            dates_in,
            disease_raw_2020,
            color_in=colors[indicator],
            label_in=labels[indicator],
        )
        format_x_axis(ax, dates_in)
        ## set y label
        ax.set_ylabel("Disease Indicator (raw)")

        disease_2020 = disease_data[f"{indicator}"][disease_data[f"{indicator}"].index.isin(dates_in)] 
        # Second plot
        ax = axs[1]
        plot_timeseries(
            ax,
            dates_in,
            disease_2020,
            color_in=colors[indicator],
            label_in=labels[indicator],
        )
        format_x_axis(ax, dates_in)
        ## set y label
        ax.set_ylabel("Disease Indicator (transformed)")

        # lower plot
        ax = axs[2] 
        plot_timeseries(
            ax,
            dates_in,
            trace_in.posterior[f"d_{indicator}"],
            color_in=colors[indicator],
            label_in=labels[indicator],
            alpha=0.2,
        )
        ax.set_ylim(0.4, 0.75)
        format_x_axis(ax, dates_in, last=True)
        # set y label
        ax.set_ylabel("Disease factor")
        ## create custom legend
        ### for median line and 94% CI
        median_line = lines.Line2D([], [], color="black", linewidth=3, label="median")
        ci_94 = patches.Patch(color="black", alpha=0.5, label="94% CI")
        ### create legend
        ax.legend(handles=[median_line, ci_94], loc="lower right", frameon=False)

        plt.subplots_adjust(hspace=0.1)

        # save figure
        fig.savefig(f"{tag_in}/diseaseIndicator.png", bbox_inches="tight")
        fig.savefig(f"{tag_in}/diseaseIndicator.pdf", bbox_inches="tight")

def plot_chains(trace_in, tag_in):
    def plot(trace_in, tag_in, kind_in):
        axes = az.plot_trace(trace_in, compact=True, kind=kind_in)
        fig = axes.ravel()[0].figure
        for ax in axes.ravel():
            ax.set_xlabel("")
        # fig.suptitle(kind_in)
        fig.subplots_adjust(hspace=0.7, wspace=0.2)
        fig.savefig(f"{tag_in}/{kind_in}.png", dpi=300, bbox_inches="tight")
        fig.savefig(f"{tag_in}/{kind_in}.pdf", dpi=300, bbox_inches="tight")

    plot(trace_in, tag_in, "trace")
    plot(trace_in, tag_in, "rank_bars")


def analysis_figures(
    model_in, trace_in, tag_in, dates_in, indicators_in, school_in, holiday_in, temperature_in, precipitation_in, daylight_in, pop_density_in, disease_data_in, disease_data_raw_in
):
    utils.make_dir(tag_in)

    if indicators_in:
        # convolution_figure(indicators_in, trace_in, dates_in, tag_in)
        plot_gamma_kernel(trace_in, tag_in, indicators_in)
        plot_gamma_parameters(trace_in, indicators_in, tag_in)
        plot_disease_timeseries(dates_in, trace_in, tag_in, indicators_in, disease_data_in, disease_data_raw_in)
    plot_distributions(model_in, trace_in, tag_in, indicators_in, temperature_in, daylight_in)
    if temperature_in:
        plot_temperature_timeseries(dates_in, trace_in, tag_in)
    if daylight_in:
        plot_daylight_timeseries(dates_in, trace_in, tag_in)
    plot_all_timeseries(
        dates_in,
        trace_in,
        tag_in,
        indicators_in, 
        school_in,
        holiday_in,
        temperature_in,
        precipitation_in,
        daylight_in,
        pop_density_in
    )
    plot_chains(trace_in, tag_in)
