import numpy as np
import arviz as az
import xarray as xr
import warnings

import matplotlib.pyplot as plt

plt.rcParams.update({"font.size": 20})
from matplotlib import lines, patches
from matplotlib import colormaps

# to import FormatStrFormatter
#import matplotlib.ticker as ticker

import covid19_inference.covid19_inference as cov19
import utils

colormap = colormaps["tab20b"]
colors = {
    # diseaes
    "R": colormap(0.0),
    "C": colormap(0.05),
    "ICU": colormap(0.15),
    "H": colormap(0.1),
    # NPI
    ## stay-at-home order
    "S": colormap(0.2),
    ## home office
    "h": colormap(0.25),
    ## kurzarbeit
    "K": colormap(0.35),
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
    "m": colormap(0.8),
    "m_obs": colormap(0.85),
    "o_*": colormap(0.9),
    "m_base": colormap(0.95),
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
    xticklabels = [x_in[i].strftime("%d %b") for i in xticks]
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

    # upper plot
    ax = axs[0]
    plot_timeseries(
        ax,
        dates_in,
        trace_in.posterior["T_star"],
        color_in=colors["T"],
        label_in="$T_*$",
    )
    format_x_axis(ax, dates_in)
    ## set y label
    ax.set_ylabel("'go-out' temperature\n$T_*$ [°C]")
    ## create custom legend
    ### for median line and 94% CI
    median_line = lines.Line2D([], [], color="black", linewidth=3, label="median")
    ci_94 = patches.Patch(color="black", alpha=0.5, label="94% CI")
    ### create legend
    ax.legend(handles=[median_line, ci_94], loc="lower right", frameon=False)

    # lower plot
    ax = axs[1]
    plot_timeseries(ax, dates_in, trace_in.posterior["rho"], "$\\rho$", colors["T"])
    ax.set_ylim(0, 1)
    format_x_axis(ax, dates_in, last=True)
    # set y label
    ax.set_ylabel("Relevance of\ntemperature difference $\\rho$")

    plt.subplots_adjust(hspace=0.1)

    # save figure
    fig.savefig(f"{tag_in}/temperature.png", bbox_inches="tight")
    fig.savefig(f"{tag_in}/temperature.pdf", bbox_inches="tight")


def plot_all_timeseries(
    dates_in,
    trace_in,
    tag_in,
    indicators_in,
    pandemic_fatigue_in,
    temperature_in,
    precipitation_in,
    log=False,
):
    fig, axs = plt.subplots(
        3,
        1,
        figsize=(13, 13),
        sharex=True,
    )

    # upper plot
    ax = axs[0]
    plot_timeseries(
        ax,
        dates_in,
        trace_in.posterior["k"],
        color_in=colors["K"],
        label_in="short-term work $k$",
    )
    plot_timeseries(
        ax,
        dates_in,
        trace_in.posterior["h"],
        color_in=colors["h"],
        label_in="home office $h$",
    )
    ax.hlines(
        0,
        xmin=dates_in[0],
        xmax=dates_in[-1],
        color="grey",
        linestyle="--",
        linewidth=1,
    )
    format_x_axis(ax, dates_in)
    ## set y label
    ax.set_ylabel("Subtractive impact on\nout-of-home duration")
    ## create custom legend
    ### for median line and 94% CI
    median_line = lines.Line2D([], [], color="black", linewidth=3, label="median")
    ci_94 = patches.Patch(color="black", alpha=0.5, label="94% CI")
    ### create legend
    legend2 = ax.legend(
        handles=[median_line, ci_94],
        frameon=False,
        loc="lower left",
        # bbox_to_anchor=(1.1, 0.95),
    )
    ax.add_artist(legend2)

    ax.legend(ncol=2)

    # middle plot
    ax = axs[1]
    labels = {
        "C": "new cases $d_C$",
        "ICU": "ICU patients $d_{ICU}$",
        "H": "hospitalisations $d_H$",
        "R": "Reproduction Number $d_R$",
    }
    ## plot s
    plot_timeseries(
        ax,
        dates_in,
        trace_in.posterior["s"],
        color_in=colors["S"],
        label_in="stay-at-home orders $s$",
        alpha=0.2,
    )
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
    ## pandemic fatigue
    if pandemic_fatigue_in == "linear" or pandemic_fatigue_in == "sigmoid":
        plot_timeseries(
            ax,
            dates_in,
            trace_in.posterior["f"],
            color_in=colors["f"],
            label_in="pandemic fatigue $f$",
            alpha=0.2,
        )
    ## temperature
    if temperature_in is not None:
        plot_timeseries(
            ax,
            dates_in,
            trace_in.posterior["theta"],
            color_in=colors["T"],
            label_in="temperature $\\theta$",
            alpha=0.2,
        )
    ## precipitation
    if precipitation_in is not None:
        plot_timeseries(
            ax,
            dates_in,
            trace_in.posterior["p"],
            color_in=colors["p"],
            label_in="precipitation $p$",
            alpha=0.2,
        )


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

    # lower plot
    ax = axs[2]
    ax.plot(
        dates_in,
        trace_in.constant_data["m_base"],
        label="baseline $o_{base}$",
        color=colors["m_base"],
        marker="o",
    )
    plot_timeseries(
        ax, dates_in, trace_in.posterior["o_*"], "inferred $o_*$", colors["o_*"]
    )
    ax.plot(
        dates_in,
        trace_in.observed_data["likelihood"],
        label="input $o_{obs}$",
        color=colors["m_obs"],
        marker="o",
    )
    plot_timeseries(ax, dates_in, trace_in.posterior["m"], "inferred $o$", colors["m"])
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
def plot_distributions(model_in, trace_in, tag_in, indicators_in, pandemic_fatigue_in):
    # --- base parameters ---
    if len(indicators_in) == 1:
        fig, axs = plt.subplots(2, 5, figsize=(13, 5))
    elif len(indicators_in) == 2:
        fig, axs = plt.subplots(3, 5, figsize=(13, 8))
    elif len(indicators_in) == 3:
        fig, axs = plt.subplots(4, 5, figsize=(13, 10))
    else:
        fig, axs = plt.subplots(4, 5, figsize=(13, 10))

    # flatten axes
    axs = axs.flatten()

    # kurzarbeit
    cov19.plot.distribution(
        model_in, trace_in, "delta_k", dist_math="\delta_k", ax=axs[0]
    )
    # home office
    cov19.plot.distribution(
        model_in, trace_in, "delta_h", dist_math="\delta_h", ax=axs[1]
    )

    cov19.plot.distribution(model_in, trace_in, "z_S", dist_math="z_{S}", ax=axs[2])
    cov19.plot.distribution(
        model_in, trace_in, "sigma_model", dist_math="\sigma_{model}", ax=axs[3]
    )

    # disease
    i = 4
    for indicator in indicators_in:
        cov19.plot.distribution(
            model_in, trace_in, f"z_{indicator}", dist_math=f"z_{{{indicator}}}", ax=axs[i]
        )
        cov19.plot.distribution(
            model_in,
            trace_in,
            f"mu_{indicator}",
            dist_math=f"\mu_{{{indicator}}}",
            ax=axs[i + 1],
        )
        cov19.plot.distribution(
            model_in,
            trace_in,
            f"sigma_{indicator}",
            dist_math=f"\sigma_{{{indicator}}}",
            ax=axs[i + 2],
        )
        cov19.plot.distribution(
            model_in,
            trace_in,
            f"alpha_{indicator}",
            dist_math=f"\\alpha_{{{indicator}}}",
            ax=axs[i + 3],
        )
        i += 4

    fig.savefig(f"{tag_in}/distributions.png", dpi=300, bbox_inches="tight")
    fig.savefig(f"{tag_in}/distributions.pdf", dpi=300, bbox_inches="tight")

    # --- pandemic fatigue ---
    if pandemic_fatigue_in == "linear":
        fig, axs = plt.subplots(1, 2, figsize=(5, 2))
        axs = axs.flatten()
        cov19.plot.distribution(model_in, trace_in, "f0", dist_math="f_0", ax=axs[0])
        cov19.plot.distribution(model_in, trace_in, "r", dist_math="r", ax=axs[1])
    elif pandemic_fatigue_in == "sigmoid":
        fig, axs = plt.subplots(1, 3, figsize=(8, 3))
        axs = axs.flatten()
        cov19.plot.distribution(
            model_in, trace_in, "del_t", dist_math="\Delta t", ax=axs[0]
        )
        cov19.plot.distribution(model_in, trace_in, "tau", dist_math=r"\tau", ax=axs[1])
        cov19.plot.distribution(
            model_in, trace_in, "del_f", dist_math="\Delta f", ax=axs[2]
        )
    if pandemic_fatigue_in == "linear" or pandemic_fatigue_in == "sigmoid":
        fig.savefig(
            f"{tag_in}/distributions_pandemic_fatigue.png",
            dpi=300,
            bbox_inches="tight",
        )
        fig.savefig(
            f"{tag_in}/distributions_pandemic_fatigue.pdf",
            dpi=300,
            bbox_inches="tight",
        )

    # --- temperature ---
    
    # temperature
    fig, axs = plt.subplots(1, 5, figsize=(13, 2))
    axs = axs.flatten()
    cov19.plot.distribution(model_in, trace_in, "z_T", dist_math="z_{T}", ax=axs[0])
    cov19.plot.distribution(model_in, trace_in, "amplitude", dist_math="a_T", ax=axs[1])
    cov19.plot.distribution(
        model_in, trace_in, "offset", dist_math="T_{*,max}", ax=axs[2]
    )
    cov19.plot.distribution(
        model_in, trace_in, "shift", dist_math="\Delta t", ax=axs[3]
    )
    cov19.plot.distribution(model_in, trace_in, "a_rho", dist_math="a_\\rho", ax=axs[4])
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
    model_in, trace_in, tag_in, dates_in, indicators_in, pandemic_fatigue_in, temperature_in, precipitation_in
):
    utils.make_dir(tag_in)

    if indicators_in:
        convolution_figure(indicators_in, trace_in, dates_in, tag_in)
    #     plot_gamma_kernel(trace_in, tag_in, indicators_in)
    # plot_distributions(model_in, trace_in, tag_in, indicators_in, pandemic_fatigue_in)
    # plot_temperature_timeseries(dates_in, trace_in, tag_in)
    # plot_gamma_parameters(trace_in, indicators_in, tag_in)
    # plot_all_timeseries(
    #     dates_in,
    #     trace_in,
    #     tag_in,
    #     indicators_in,
    #     pandemic_fatigue_in,
    #     temperature_in,
    #     precipitation_in,
    # )
    # plot_chains(trace_in, tag_in)
