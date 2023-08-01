import numpy as np
import matplotlib.pyplot as plt
import os

plt.rcParams.update({"font.size": 20})
from matplotlib import lines, patches
from matplotlib import colormaps

# to import FormatStrFormatter
import matplotlib.ticker as ticker

import covid19_inference.covid19_inference as cov19

colormap = colormaps["tab20b"]
colors = {
    # diseaes
    "R": colormap(0.0),
    "C": colormap(0.05),
    "ICU": colormap(0.1),
    "H": colormap(0.15),
    # stay-at-home order
    "S": colormap(0.2),
    # temperature
    "T": colormap(0.4),
    "delT": colormap(0.45),
    # pandemic fatigue
    "p": colormap(0.6),
    # out-of-home duration
    "m": colormap(0.8),
    "m_obs": colormap(0.85),
    "o_*": colormap(0.9),
    "m_base": colormap(0.95),
}


def concatenate_chains_and_draws(xarray_in):
    array = np.array(xarray_in)
    return array.reshape(-1, array.shape[-1])


def plot_timeseries(ax_in, x_in, xarray_in, label_in, color_in, alpha=0.5):
    array = concatenate_chains_and_draws(xarray_in)
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


def format_x_axis(ax_in, x_in, last=False):
    # choose number of x ticks
    n_xticks = 6
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
        ax_in.set_xlabel("Year 2020")
    else:
        # set x tick labels
        ax_in.set_xticklabels([])
    # set x limits
    ax_in.set_xlim(x_in[0], x_in[-1])


def create_figure_dir(tag_in):
    # We create a directory for the results.
    dir_name = "figures/" + tag_in
    ## We create the target directory if it does not exist yet
    if not os.path.exists(dir_name):
        os.mkdir(dir_name)
        print("Directory ", dir_name, " created.")
    else:
        print("Directory ", dir_name, " already exists.")


## plot Gamma distribution with inferred mean and standard deviation
def plot_gamma_kernel(trace_in, tag_in, indicators_in):
    fig, ax = plt.subplots(1, 1, figsize=(5, 4))

    # prepare
    max_x = 2
    x = np.linspace(0, max_x, 100)
    ys = []

    # plot
    for indicator in indicators_in:
        y = cov19.model._utility.tt_gamma(
            x,
            mu=np.median(trace_in.posterior[f"mu_{indicator}"]),
            sigma=np.median(trace_in.posterior[f"sigma_{indicator}"]),
        ).eval()
        ys.append(y)
        ax.plot(x, y, linewidth=3, label=f"${indicator}$", color=colors[indicator])

    # format
    ax.set_xlabel("Week")
    ax.set_title("Inferred median\nGamma kernel")
    ax.set_xlim(0, max_x)
    ax.set_ylim(0, 1.1 * np.max(np.array(ys)))
    ax.legend()
    fig.tight_layout()
    fig.savefig(f"figures/{tag_in}/gamma_kernel.png")
    fig.savefig(f"figures/{tag_in}/gamma_kernel.pdf")


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
    plot_timeseries(ax, dates_in, trace_in.posterior["r"], "$r$", colors["T"])
    ax.set_ylim(0, 1)
    format_x_axis(ax, dates_in, last=True)
    # set y label
    ax.set_ylabel("Relevance of\ntemperature difference $r$")

    plt.subplots_adjust(hspace=0.1)

    # save figure
    fig.savefig(f"figures/{tag_in}/temperature.png", bbox_inches="tight")
    fig.savefig(f"figures/{tag_in}/temperature.pdf", bbox_inches="tight")


## plot ood time series
def plot_out_of_home_duration_timeseries(dates_in, trace_in, tag_in, indicators_in):
    fig, axs = plt.subplots(
        2,
        1,
        figsize=(9, 11),
        sharex=True,
    )

    # upper plot
    ax = axs[0]
    labels = {
        "C": "cases $d_C$",
        "ICU": "ICU $d_{ICU}$",
        "H": "hospitalisations $d_H$",
        "R": "Effective Reproduction Number $d_R$",
    }
    for indicator in indicators_in:
        plot_timeseries(
            ax,
            dates_in,
            trace_in.posterior[f"d_{indicator}"],
            color_in=colors[indicator],
            label_in=labels[indicator],
            alpha=0.2,
        )
    plot_timeseries(
        ax,
        dates_in,
        trace_in.posterior["s"],
        color_in=colors["S"],
        label_in="stay-at-home order $s$",
        alpha=0.2,
    )
    # plot_timeseries(
    #     ax,
    #     dates_in,
    #     trace_in.posterior["p"],
    #     color_in=colors["p"],
    #     label_in="pandemic fatigue $p$",
    #     alpha=0.2,
    # )
    # plot_timeseries(
    #     ax,
    #     dates_in,
    #     trace_in.posterior["w"],
    #     color_in=colors["T"],  # maybe change later to blueish
    #     label_in="weather $w$",
    #     alpha=0.2,
    # )
    """ temperature
    plot_timeseries(
        ax,
        dates_in,
        trace_in.posterior["w"],
        color_in=colors["T"],
        label_in="temperature $w$",
        alpha=0.2,
    )
    """

    ax.hlines(
        1,
        xmin=dates_in[0],
        xmax=dates_in[-1],
        color="grey",
        linestyle="--",
        linewidth=1,
    )
    ## log scale y axis
    ax.set_yscale("log")
    ### format y ticks labels with one decimal
    ax.yaxis.set_major_formatter(ticker.FormatStrFormatter("%.1f"))
    ### no y ticks labels for minor ticks
    ax.yaxis.set_minor_formatter(ticker.NullFormatter())
    ### select y ticks
    ax.set_yticks([0.8, 1, 1.3])
    ### select minor y ticks
    ax.yaxis.set_minor_locator(ticker.FixedLocator([0.7, 0.9, 1.1, 1.2, 1.4, 1.5]))
    format_x_axis(ax, dates_in)
    ## set y label
    ax.set_ylabel("Modulation\non baseline\nout-of-home\nduration [log]")
    ## create custom legend
    ### for median line and 94% CI
    median_line = lines.Line2D([], [], color="black", linewidth=3, label="median")
    ci_94 = patches.Patch(color="black", alpha=0.5, label="94% CI")
    ### create legend
    legend2 = ax.legend(
        handles=[median_line, ci_94],
        loc="lower right",
        frameon=False,
        bbox_to_anchor=(1.15, 0.95),
    )
    ax.add_artist(legend2)

    legend1 = ax.legend(bbox_to_anchor=(0.7, 1.8))

    # lower plot
    ax = axs[1]
    ax.plot(
        dates_in,
        trace_in.constant_data["m_base"],
        label="baseline $o_{base}$",
        color=colors["m_base"],
        marker="o",
    )
    ax.plot(
        dates_in,
        trace_in.observed_data["likelihood"],
        label="input $o_{obs}$",
        color=colors["m_obs"],
        marker="o",
    )
    plot_timeseries(ax, dates_in, trace_in.posterior["m"], "inferred $o$", colors["m"])
    plot_timeseries(
        ax, dates_in, trace_in.posterior["o_*"], "inferred $o_*$", colors["o_*"]
    )
    ax.legend(ncol=2, bbox_to_anchor=(1.15, -0.4))
    format_x_axis(ax, dates_in, last=True)
    # set y label
    ax.set_ylabel("Out-of-home\nduration [h]")

    plt.subplots_adjust(hspace=0.1)
    fig.tight_layout()

    # save figure
    fig.savefig(f"figures/{tag_in}/out_of_home_duration.png", bbox_inches="tight")
    fig.savefig(f"figures/{tag_in}/out_of_home_duration.pdf", bbox_inches="tight")


# plot distribution for single indicator models
def plot_distributions(model_in, trace_in, tag_in, indicators_in):
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

    cov19.plot.distribution(
        model_in, trace_in, "delta_o", dist_math="\Delta o", ax=axs[0]
    )

    # pandemic fatigue
    ## linear
    # cov19.plot.distribution(model_in, trace_in, "p0", dist_math="p_0", ax=axs[0])
    # cov19.plot.distribution(model_in, trace_in, "r", dist_math="r", ax=axs[1])
    ## sigmoid
    # cov19.plot.distribution(
    #     model_in, trace_in, "del_t", dist_math="\Delta t", ax=axs[0]
    # )
    # cov19.plot.distribution(model_in, trace_in, "tau", dist_math=r"\tau", ax=axs[1])
    # cov19.plot.distribution(
    #     model_in, trace_in, "del_p", dist_math="\Delta p", ax=axs[2]
    # )

    # precipitation
    # cov19.plot.distribution(model_in, trace_in, "z_P", dist_math="z_P", ax=axs[3])

    # temperature
    """
    cov19.plot.distribution(model_in, trace_in, "z_T", dist_math="z_{T}", ax=axs[0])
    cov19.plot.distribution(model_in, trace_in, "amplitude", dist_math="a_T", ax=axs[1])
    cov19.plot.distribution(
        model_in, trace_in, "offset", dist_math="T_{*,max}", ax=axs[2]
    )
    cov19.plot.distribution(
        model_in, trace_in, "shift", dist_math="\Delta t", ax=axs[3]
    )
    cov19.plot.distribution(model_in, trace_in, "a_r", dist_math="a_r", ax=axs[4])
    """
    cov19.plot.distribution(
        model_in, trace_in, "sigma_model", dist_math="\sigma_{model}", ax=axs[4]
    )
    cov19.plot.distribution(model_in, trace_in, "z_S", dist_math="z_{S}", ax=axs[5])

    # disease
    i = 6
    for indicator in indicators_in:
        cov19.plot.distribution(
            model_in, trace_in, f"z_{indicator}", dist_math=f"z_{indicator}", ax=axs[i]
        )
        cov19.plot.distribution(
            model_in,
            trace_in,
            f"mu_{indicator}",
            dist_math=f"\mu_{indicator}",
            ax=axs[i + 1],
        )
        cov19.plot.distribution(
            model_in,
            trace_in,
            f"sigma_{indicator}",
            dist_math=f"\sigma_{indicator}",
            ax=axs[i + 2],
        )
        cov19.plot.distribution(
            model_in,
            trace_in,
            f"delta_{indicator}",
            dist_math=f"\delta_{indicator}",
            ax=axs[i + 3],
        )
        i += 4

    fig.savefig(f"figures/{tag_in}/distributions.png", dpi=300, bbox_inches="tight")
    fig.savefig(f"figures/{tag_in}/distributions.pdf", dpi=300, bbox_inches="tight")


def analysis_figures(model_in, trace_in, tag_in, dates_in, indicators_in):
    create_figure_dir(tag_in)

    plot_distributions(model_in, trace_in, tag_in, indicators_in)
    # plot_temperature_timeseries(dates_in, trace_in, tag_in)
    plot_gamma_kernel(trace_in, tag_in, indicators_in)
    plot_out_of_home_duration_timeseries(dates_in, trace_in, tag_in, indicators_in)
