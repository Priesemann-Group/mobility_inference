import trace
import numpy as np
import arviz as az
import xarray as xr
import datetime
import pandas as pd
import warnings

import matplotlib.pyplot as plt

plt.rcParams.update({"font.size": 20})
from matplotlib import lines, patches
from matplotlib import colormaps
from matplotlib.dates import DateFormatter

# to import FormatStrFormatter
#import matplotlib.ticker as ticker

import covid19_inference as cov19
#import covid19_inference.plot as cov19utils
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
    "D": (0.803921568627451, 0.807843141254902, 0.9294117647058824, 1),
    "logD": (0.803921568627451, 0.807843141254902, 0.9294117647058824, 1),
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
def plot_gamma_kernel(trace_in, tag_in, indicators_in, chosen_model):
    if chosen_model == "BEHHHB":
        federalStates = (
       "Berlin", "Bremen", "Hamburg")
    if chosen_model == "fedStates":
        federalStates = (
       "Baden-Württemberg", "Bayern", "Berlin", "Brandenburg", "Bremen",
       "Hamburg", "Hessen", "Mecklenburg-Vorpommern", "Niedersachsen",
       "Nordrhein-Westfalen", "Rheinland-Pfalz", "Saarland", "Sachsen",
       "Sachsen-Anhalt", "Schleswig-Holstein", "Thüringen")
    if chosen_model == "cities":  
        federalStates = [
       "Berlin", "Bremen", "Hamburg", "München", "Stuttgart", "Köln", "Frankfurt", "Düsseldorf", "Leipzig", "Bonn"]
    if chosen_model == "cities_MeckPomm":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin", "Vorpommern-Greifswald", "Ludwigslust-Parchim", "Nordwestmecklenburg", "Mecklenburgische Seenplatte", "Rostock", "Vorpommern-Rügen",
       "Nordsachsen", "Meißen", "Bautzen", "Görlitz", "Mittelsachsen", "Chemnitz", "Zwickau", "Vogtlandkreis", "Erzgebirgskreis", "Potsdam", "Frankfurt am Main"]
    if chosen_model == "large":
        federalStates = [
                    "Berlin", "Bremen", "Hamburg", "Stuttgart", "München", "Köln",
                    "Frankfurt am Main", "Düsseldorf", "Leipzig", "Essen", "Dortmund", "Dresden", "Nürnberg", "Hannover", "Duisburg", "Wuppertal", "Karlsruhe", "Bielefeld", "Erfurt", "Kiel",
                    "Rostock", "Mecklenburgische Seenplatte", "Vorpommern-Rügen", "Nordwestmecklenburg", "Vorpommern-Greifswald", "Ludwigslust-Parchim",
                    "Nordsachsen", "Meißen", "Bautzen", "Görlitz", "Mittelsachsen", "Chemnitz", "Zwickau", "Vogtlandkreis", "Erzgebirgskreis", "Potsdam",
                    "Altmarkkreis Salzwedel", "Anhalt-Bitterfeld", "Ravensburg", "Burgenlandkreis", "Dessau-Roßlau", "Halle (Saale)", "Harz", "Braunschweig", "Magdeburg", "Wolfsburg", "Saalekreis", "Salzlandkreis", "Stendal", "Wittenberg",
                    "Flensburg", "Lübeck", "Neumünster", "Dithmarschen", "Herzogtum Lauenburg", "Nordfriesland", "Ostholstein", "Pinneberg", "Plön", "Rendsburg-Eckernförde",      
                    "Schleswig-Flensburg", "Steinburg", "Salzgitter", "Gifhorn", "Goslar", "Helmstedt", "Göttingen", "Diepholz",                   
                    "Hildesheim", "Holzminden", "Schaumburg", "Celle", "Cuxhaven", "Lüneburg", "Osterholz", "Rotenburg (Wümme)",          
                    "Heidekreis", "Stade", "Uelzen", "Delmenhorst", "Emden", "Osnabrück", "Wilhelmshaven", "Aurich",                     
                    "Cloppenburg", "Emsland", "Friesland", "Leer", "Oldenburg", "Wittmund", "Bremerhaven", "Krefeld",                    
                    "Mönchengladbach", "Mülheim an der Ruhr", "Remscheid"         
        ]
    if chosen_model == "cities_non_hierarchical":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin"]
    if chosen_model == "countieswithproblems":
        federalStates = [
            "Berlin", "Bremen", "Hamburg", "Stuttgart", "München", "Köln",
            "Frankfurt am Main", "Düsseldorf", "Leipzig", "Essen", "Dortmund", "Dresden", "Nürnberg", "Hannover", "Duisburg", 
            "Helmstedt", "Holzminden", "Schaumburg", "Delemhorst", "Wilhelmshaven", "Emsland", "Leer", "Oldenburg", "Bremerhaven"
        ]
        
    for i, c in enumerate(federalStates):
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
            #mu_median = np.median(trace_in.posterior[f"mu_{indicator}"])
            if chosen_model == "cities_non_hierarchical":
                trace_filtered = trace_in.posterior[f"mu_{indicator}"][:,:,i]
            else:    
                trace_filtered = trace_in.posterior[f"mu_{indicator}"][:,:,i]
            y_first =  trace_filtered
            mu_median = np.median(trace_filtered)
            #sigma_median = np.median(trace_in.posterior[f"sigma_{indicator}"]) 
            if chosen_model == "cities_non_hierarchical":
                trace_filtered_2 = trace_in.posterior[f"sigma_{indicator}"][:,:,i]
            else:
                trace_filtered_2 = trace_in.posterior[f"sigma_{indicator}"][:,:,i]
            
            sigma_median = np.median(trace_filtered_2)
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

        plotnamepng= f"{tag_in}/" + c + "-gamma_kernel.png"
        plotnamepdf = f"{tag_in}/" + c + "-gamma_kernel.pdf"
        fig.savefig(plotnamepng, bbox_inches="tight")
        fig.savefig(plotnamepdf, bbox_inches="tight")


## plot temperature time series
def plot_temperature_timeseries(dates_in, trace_in, tag_in, indicators, chosen_model, incl2024):
    if chosen_model == "BEHHHB":
        federalStates = (
       "Berlin", "Bremen", "Hamburg")
    if chosen_model == "fedStates":
        federalStates = (
       "Baden-Württemberg", "Bayern", "Berlin", "Brandenburg", "Bremen",
       "Hamburg", "Hessen", "Mecklenburg-Vorpommern", "Niedersachsen",
       "Nordrhein-Westfalen", "Rheinland-Pfalz", "Saarland", "Sachsen",
       "Sachsen-Anhalt", "Schleswig-Holstein", "Thüringen")
    if chosen_model == "cities":  
        federalStates = [
        "Berlin", "Bremen", "Hamburg", "München", "Stuttgart", "Köln", "Frankfurt", "Düsseldorf", "Leipzig", "Bonn"]
    if chosen_model == "cities_MeckPomm":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin", "Vorpommern-Greifswald", "Ludwigslust-Parchim", "Nordwestmecklenburg", "Mecklenburgische Seenplatte", "Rostock", "Vorpommern-Rügen",
       "Nordsachsen", "Meißen", "Bautzen", "Görlitz", "Mittelsachsen", "Chemnitz", "Zwickau", "Vogtlandkreis", "Erzgebirgskreis", "Potsdam", "Frankfurt am Main"]
    if chosen_model == "large":
        federalStates = [
                    "Berlin", "Bremen", "Hamburg", "Stuttgart", "München", "Köln",
                    "Frankfurt am Main", "Düsseldorf", "Leipzig", "Essen", "Dortmund", "Dresden", "Nürnberg", "Hannover", "Duisburg", "Wuppertal", "Karlsruhe", "Bielefeld", "Erfurt", "Kiel",
                    "Rostock", "Mecklenburgische Seenplatte", "Vorpommern-Rügen", "Nordwestmecklenburg", "Vorpommern-Greifswald", "Ludwigslust-Parchim",
                    "Nordsachsen", "Meißen", "Bautzen", "Görlitz", "Mittelsachsen", "Chemnitz", "Zwickau", "Vogtlandkreis", "Erzgebirgskreis", "Potsdam",
                    "Altmarkkreis Salzwedel", "Anhalt-Bitterfeld", "Ravensburg", "Burgenlandkreis", "Dessau-Roßlau", "Halle (Saale)", "Harz", "Braunschweig", "Magdeburg", "Wolfsburg", "Saalekreis", "Salzlandkreis", "Stendal", "Wittenberg",
                    "Flensburg", "Lübeck", "Neumünster", "Dithmarschen", "Herzogtum Lauenburg", "Nordfriesland", "Ostholstein", "Pinneberg", "Plön", "Rendsburg-Eckernförde",      
                    "Schleswig-Flensburg", "Steinburg", "Salzgitter", "Gifhorn", "Goslar", "Helmstedt", "Göttingen", "Diepholz",                   
                    "Hildesheim", "Holzminden", "Schaumburg", "Celle", "Cuxhaven", "Lüneburg", "Osterholz", "Rotenburg (Wümme)",          
                    "Heidekreis", "Stade", "Uelzen", "Delmenhorst", "Emden", "Osnabrück", "Wilhelmshaven", "Aurich",                     
                    "Cloppenburg", "Emsland", "Friesland", "Leer", "Oldenburg", "Wittmund", "Bremerhaven", "Krefeld",                    
                    "Mönchengladbach", "Mülheim an der Ruhr", "Remscheid"         
        ]
    if chosen_model == "cities_non_hierarchical":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin"]
    if chosen_model == "countieswithproblems":
        federalStates = [
            "Berlin", "Bremen", "Hamburg", "Stuttgart", "München", "Köln",
            "Frankfurt am Main", "Düsseldorf", "Leipzig", "Essen", "Dortmund", "Dresden", "Nürnberg", "Hannover", "Duisburg", 
            "Helmstedt", "Holzminden", "Schaumburg", "Delemhorst", "Wilhelmshaven", "Emsland", "Leer", "Oldenburg", "Bremerhaven"
        ]
        
    if incl2024:          
        years = (2020, 2023)
    else:
        years = [2020]
    for year in years:
        if year == 2020:
            dates_filtered = dates_in[dates_in < np.datetime64("2021-03-01")]
            dates = np.unique(dates_filtered)
        if year == 2023:
            dates_filtered = dates_in[dates_in > np.datetime64("2022-12-31")]
            dates = np.unique(dates_filtered)

        # First plot
        for i, c in enumerate(federalStates):
            fig, axs = plt.subplots(2, 1, figsize=(9, 9), sharex=True)
            axs = axs.ravel()
            ax = axs[0]

            if year == 2020:
                if chosen_model == "cities_non_hierarchical":
                    if indicators[0] == 'C':
                        y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_C<56)&(trace_in.constant_data.fedState_idx==i))
                    if indicators[0] == 'R':
                        y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_R<56)&(trace_in.constant_data.fedState_idx==i))
                    if indicators[0] == 'H':
                        y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_H<56)&(trace_in.constant_data.fedState_idx==i))
                else:
                    if indicators[0] == 'C':
                        y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_C<56)&(trace_in.constant_data.fedState_idx==i))
                    if indicators[0] == 'R':
                        y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_R<56)&(trace_in.constant_data.fedState_idx==i))
                    if indicators[0] == 'H':
                        y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_H<56)&(trace_in.constant_data.fedState_idx==i))
            if year == 2023:
                if chosen_model == "cities_non_hierarchical":
                    if indicators[0] == 'C':
                        y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_C>=56)&(trace_in.constant_data.fedState_idx==i))
                    if indicators[0] == 'R':
                        y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_R>=56)&(trace_in.constant_data.fedState_idx==i))
                    if indicators[0] == 'H':
                        y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_H>=56)&(trace_in.constant_data.fedState_idx==i))
                else:
                    if indicators[0] == 'C':
                        y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_C>=56)&(trace_in.constant_data.fedState_idx==i))
                    if indicators[0] == 'R':
                        y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_R>=56)&(trace_in.constant_data.fedState_idx==i))
                    if indicators[0] == 'H':
                        y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_H>=56)&(trace_in.constant_data.fedState_idx==i))
            y = y_first.dropna(dim="obs_id", how = "all")
            #dates = np.unique(dates_in)
            
            plot_timeseries(
                ax,
                dates,
                y,
                color_in=colors["T"],
                label_in="$T_2020$",
            )
            format_x_axis(ax, dates)
            ## set y label
            ax.set_ylabel("temperature [°C]")
            ## create custom legend
            ### for median line and 94% CI
            median_line = lines.Line2D([], [], color="black", linewidth=3, label="median")
            ci_94 = patches.Patch(color="black", alpha=0.5, label="94% CI")
            ### create legend
            ax.legend(handles=[median_line, ci_94], loc="lower right", frameon=False)
            ax.set_title(c)

            #lower plot
            ax = axs[1]
            if year == 2020:
                if indicators[0] == 'C':
                    y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_C<56)&(trace_in.constant_data.fedState_idx==i))
                if indicators[0] == 'R':
                    y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_R<56)&(trace_in.constant_data.fedState_idx==i))
                if indicators[0] == 'H':
                    y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_H<56)&(trace_in.constant_data.fedState_idx==i))
            if year == 2023:
                if indicators[0] == 'C':
                    y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_C>=56)&(trace_in.constant_data.fedState_idx==i))
                if indicators[0] == 'R':
                    y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_R>=56)&(trace_in.constant_data.fedState_idx==i))
                if indicators[0] == 'H':
                    y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_H>=56)&(trace_in.constant_data.fedState_idx==i))
            y = y_first.dropna(dim="obs_id", how = "all")
            plot_timeseries(
                ax,
                dates,
                y,
                color_in=colors["T"],
                label_in="$Delta_temp$",
            )
            ax.set_ylim(0.75, 1.25)
            date_form = DateFormatter("%m/%d")
            ax.xaxis.set_major_formatter(date_form)
            # set y label
            ax.set_ylabel("temperature_factor")

            plt.subplots_adjust(hspace=0.1)
            
            # save figure
            plotnamepng= f"{tag_in}/" + c + str(year) + "-temperature.png"
            plotnamepdf = f"{tag_in}/" + c + str(year) + "-temperature.pdf"
            fig.savefig(plotnamepng, bbox_inches="tight")
            fig.savefig(plotnamepdf, bbox_inches="tight")

    ## plot daylight time series
def plot_daylight_timeseries(dates_in, trace_in, tag_in, indicators, chosen_model, incl2024):
    if chosen_model == "BEHHHB":
        federalStates = (  
        "Berlin", "Bremen", "Hamburg")
    if chosen_model == "fedStates":
        federalStates = (  
        "Baden-Württemberg", "Bayern", "Berlin", "Brandenburg", "Bremen",
       "Hamburg", "Hessen", "Mecklenburg-Vorpommern", "Niedersachsen",
       "Nordrhein-Westfalen", "Rheinland-Pfalz", "Saarland", "Sachsen",
       "Sachsen-Anhalt", "Schleswig-Holstein", "Thüringen")
    if chosen_model == "cities":  
        federalStates = [
        "Berlin", "Bremen", "Hamburg", "München", "Stuttgart", "Köln", "Frankfurt", "Düsseldorf", "Leipzig", "Bonn"]
    if chosen_model == "cities_MeckPomm":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin", "Vorpommern-Greifswald", "Ludwigslust-Parchim", "Nordwestmecklenburg", "Mecklenburgische Seenplatte", "Rostock", "Vorpommern-Rügen",
       "Nordsachsen", "Meißen", "Bautzen", "Görlitz", "Mittelsachsen", "Chemnitz", "Zwickau", "Vogtlandkreis", "Erzgebirgskreis", "Potsdam", "Frankfurt am Main"]
    if chosen_model == "large":
        federalStates = [
                    "Berlin", "Bremen", "Hamburg", "Stuttgart", "München", "Köln",
                    "Frankfurt am Main", "Düsseldorf", "Leipzig", "Essen", "Dortmund", "Dresden", "Nürnberg", "Hannover", "Duisburg", "Wuppertal", "Karlsruhe", "Bielefeld", "Erfurt", "Kiel",
                    "Rostock", "Mecklenburgische Seenplatte", "Vorpommern-Rügen", "Nordwestmecklenburg", "Vorpommern-Greifswald", "Ludwigslust-Parchim",
                    "Nordsachsen", "Meißen", "Bautzen", "Görlitz", "Mittelsachsen", "Chemnitz", "Zwickau", "Vogtlandkreis", "Erzgebirgskreis", "Potsdam",
                    "Altmarkkreis Salzwedel", "Anhalt-Bitterfeld", "Ravensburg", "Burgenlandkreis", "Dessau-Roßlau", "Halle (Saale)", "Harz", "Braunschweig", "Magdeburg", "Wolfsburg", "Saalekreis", "Salzlandkreis", "Stendal", "Wittenberg",
                    "Flensburg", "Lübeck", "Neumünster", "Dithmarschen", "Herzogtum Lauenburg", "Nordfriesland", "Ostholstein", "Pinneberg", "Plön", "Rendsburg-Eckernförde",      
                    "Schleswig-Flensburg", "Steinburg", "Salzgitter", "Gifhorn", "Goslar", "Helmstedt", "Göttingen", "Diepholz",                   
                    "Hildesheim", "Holzminden", "Schaumburg", "Celle", "Cuxhaven", "Lüneburg", "Osterholz", "Rotenburg (Wümme)",          
                    "Heidekreis", "Stade", "Uelzen", "Delmenhorst", "Emden", "Osnabrück", "Wilhelmshaven", "Aurich",                     
                    "Cloppenburg", "Emsland", "Friesland", "Leer", "Oldenburg", "Wittmund", "Bremerhaven", "Krefeld",                    
                    "Mönchengladbach", "Mülheim an der Ruhr", "Remscheid"         
        ]
    if chosen_model == "cities_non_hierarchical":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin"]
    if chosen_model == "countieswithproblems":
        federalStates = [
            "Berlin", "Bremen", "Hamburg", "Stuttgart", "München", "Köln",
            "Frankfurt am Main", "Düsseldorf", "Leipzig", "Essen", "Dortmund", "Dresden", "Nürnberg", "Hannover", "Duisburg", 
            "Helmstedt", "Holzminden", "Schaumburg", "Delemhorst", "Wilhelmshaven", "Emsland", "Leer", "Oldenburg", "Bremerhaven"
        ]   
         
    if incl2024:
        years = (2020, 2023)
    else:
        years = [2020]
    for year in years:
        if year == 2020:
            dates_filtered = dates_in[dates_in < np.datetime64("2021-03-01")]
            dates = np.unique(dates_filtered)
        if year == 2023:
            dates_filtered = dates_in[dates_in > np.datetime64("2022-12-31")]
            dates = np.unique(dates_filtered)

        for i, c in enumerate(federalStates):
            fig, axs = plt.subplots(2, 1, figsize=(9, 9), sharex=True)
            axs = axs.ravel()
            # First plot
            ax = axs[0]

            if year == 2020:
                if indicators[0] == 'C':
                    y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_C<52)&(trace_in.constant_data.fedState_idx==i))
                if indicators[0] == 'R':
                    y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_R<52)&(trace_in.constant_data.fedState_idx==i))
                if indicators[0] == 'H':
                    y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_H<52)&(trace_in.constant_data.fedState_idx==i))
            if year == 2023:
                if indicators[0] == 'C':
                    y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_C>=52)&(trace_in.constant_data.fedState_idx==i))
                if indicators[0] == 'R':
                    y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_R>=52)&(trace_in.constant_data.fedState_idx==i))                   
                if indicators[0] == 'H':
                    y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_H>=52)&(trace_in.constant_data.fedState_idx==i))
            y = y_first.dropna(dim="obs_id", how="all")

            plot_timeseries(
                ax,
                dates,
                y,
                color_in=colors["L"],
                label_in="$Daylight$",
            )
            format_x_axis(ax, dates)
            ## set y label
            ax.set_ylabel("Daylight [hrs]")
            ax.set_title(c)

            # lower plot
            ax = axs[1]
            if year == 2020:
                if indicators[0] == 'C':
                    y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_C<52)&(trace_in.constant_data.fedState_idx==i))
                if indicators[0] == 'R':
                    y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_R<52)&(trace_in.constant_data.fedState_idx==i))
                if indicators[0] == 'H':
                    y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_H<52)&(trace_in.constant_data.fedState_idx==i))
            if year == 2023:
                if indicators[0] == 'C':
                    y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_C>=52)&(trace_in.constant_data.fedState_idx==i))
                if indicators[0] == 'R':
                    y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_R>=52)&(trace_in.constant_data.fedState_idx==i))                    
                if indicators[0] == 'H':
                    y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_H>=52)&(trace_in.constant_data.fedState_idx==i))
            y = y_first.dropna(dim="obs_id", how = "all")

            plot_timeseries(
                ax,
                dates,
                y,
                color_in=colors["L"],
                label_in="Daylight factor",
            )
            ax.set_ylim(0.75, 1.25)
            date_form = DateFormatter("%m/%d")
            ax.xaxis.set_major_formatter(date_form)
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
            plotnamepng= f"{tag_in}/" + c + str(year) + "-daylight.png"
            plotnamepdf = f"{tag_in}/" + c + str(year) + "-daylight.pdf"
            fig.savefig(plotnamepng, bbox_inches="tight")
            fig.savefig(plotnamepdf, bbox_inches="tight")

 ## plot daylight time series
def plot_indicator_timeseries(dates_in, trace_in, tag_in, indicators_in, chosen_model):
    if chosen_model == "BEHHHB":
        federalStates = (  
        "Berlin", "Bremen", "Hamburg")
    if chosen_model == "fedStates":
        federalStates = (  
        "Baden-Württemberg", "Bayern", "Berlin", "Brandenburg", "Bremen",
       "Hamburg", "Hessen", "Mecklenburg-Vorpommern", "Niedersachsen",
       "Nordrhein-Westfalen", "Rheinland-Pfalz", "Saarland", "Sachsen",
       "Sachsen-Anhalt", "Schleswig-Holstein", "Thüringen")
    if chosen_model == "cities":  
        federalStates = [
        "Berlin", "Bremen", "Hamburg", "München", "Stuttgart", "Köln", "Frankfurt", "Düsseldorf", "Leipzig", "Bonn"]
    if chosen_model == "cities_MeckPomm":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin", "Vorpommern-Greifswald", "Ludwigslust-Parchim", "Nordwestmecklenburg", "Mecklenburgische Seenplatte", "Rostock", "Vorpommern-Rügen",
       "Nordsachsen", "Meißen", "Bautzen", "Görlitz", "Mittelsachsen", "Chemnitz", "Zwickau", "Vogtlandkreis", "Erzgebirgskreis", "Potsdam", "Frankfurt am Main"]
    if chosen_model == "large":
        federalStates = [
                    "Berlin", "Bremen", "Hamburg", "Stuttgart", "München", "Köln",
                    "Frankfurt am Main", "Düsseldorf", "Leipzig", "Essen", "Dortmund", "Dresden", "Nürnberg", "Hannover", "Duisburg", "Wuppertal", "Karlsruhe", "Bielefeld", "Erfurt", "Kiel",
                    "Rostock", "Mecklenburgische Seenplatte", "Vorpommern-Rügen", "Nordwestmecklenburg", "Vorpommern-Greifswald", "Ludwigslust-Parchim",
                    "Nordsachsen", "Meißen", "Bautzen", "Görlitz", "Mittelsachsen", "Chemnitz", "Zwickau", "Vogtlandkreis", "Erzgebirgskreis", "Potsdam",
                    "Altmarkkreis Salzwedel", "Anhalt-Bitterfeld", "Ravensburg", "Burgenlandkreis", "Dessau-Roßlau", "Halle (Saale)", "Harz", "Braunschweig", "Magdeburg", "Wolfsburg", "Saalekreis", "Salzlandkreis", "Stendal", "Wittenberg",
                    "Flensburg", "Lübeck", "Neumünster", "Dithmarschen", "Herzogtum Lauenburg", "Nordfriesland", "Ostholstein", "Pinneberg", "Plön", "Rendsburg-Eckernförde",      
                    "Schleswig-Flensburg", "Steinburg", "Salzgitter", "Gifhorn", "Goslar", "Helmstedt", "Göttingen", "Diepholz",                   
                    "Hildesheim", "Holzminden", "Schaumburg", "Celle", "Cuxhaven", "Lüneburg", "Osterholz", "Rotenburg (Wümme)",          
                    "Heidekreis", "Stade", "Uelzen", "Delmenhorst", "Emden", "Osnabrück", "Wilhelmshaven", "Aurich",                     
                    "Cloppenburg", "Emsland", "Friesland", "Leer", "Oldenburg", "Wittmund", "Bremerhaven", "Krefeld",                    
                    "Mönchengladbach", "Mülheim an der Ruhr", "Remscheid"         
        ]
    if chosen_model == "cities_non_hierarchical":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin"]
    if chosen_model == "countieswithproblems":
        federalStates = [
            "Berlin", "Bremen", "Hamburg", "Stuttgart", "München", "Köln",
            "Frankfurt am Main", "Düsseldorf", "Leipzig", "Essen", "Dortmund", "Dresden", "Nürnberg", "Hannover", "Duisburg", 
            "Helmstedt", "Holzminden", "Schaumburg", "Delemhorst", "Wilhelmshaven", "Emsland", "Leer", "Oldenburg", "Bremerhaven"
        ]  
          
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
    
    for indicator in indicators_in:
        for i, c in enumerate(federalStates):
            fig, axs = plt.subplots(2, 1, figsize=(9, 9), sharex=True)
            axs = axs.ravel()
            # First plot
            ax = axs[0]
            y_first = trace_in.constant_data.C.where((trace_in.constant_data.counter_C<52)&(trace_in.constant_data.fedState_idx==i))
            y = y_first.dropna(dim="obs_id", how = "all")
            dates = np.unique(dates_in)
            plot_timeseries(
                ax,
                dates,
                y,
                color_in=colors[indicator],
                label_in=labels[indicator],
            )
            format_x_axis(ax, dates_in)
            ## set y label
            ax.set_ylabel("Normalized Disease Data")
            ax.set_title(c)

            # lower plot
            ax = axs[1]
            y_first = trace_in.posterior.d_C.where(trace_in.constant_data.fedState_idx==i)
            y = y_first.dropna(dim="obs_id", how = "all")
            dates = np.unique(dates_in)
            plot_timeseries(
                ax,
                dates,
                y,
                color_in=colors[indicator],
                label_in=labels[indicator],
            )
            ax.set_ylim(0.5, 1.25)
            date_form = DateFormatter("%m/%d")
            ax.xaxis.set_major_formatter(date_form)
            ## create custom legend
            ### for median line and 94% CI
            median_line = lines.Line2D([], [], color="black", linewidth=3, label="median")
            ci_94 = patches.Patch(color="black", alpha=0.5, label="94% CI")
            ### create legend
            ax.legend(handles=[median_line, ci_94], loc="upper right", frameon=False)

            # set y label
            ax.set_ylabel("disease_factor")

            plt.subplots_adjust(hspace=0.1)

            # save figure
            plotnamepng= f"{tag_in}/" + c + "-" + indicator + "-indicator.png"
            plotnamepdf = f"{tag_in}/" + c + "-" + indicator + "-indicator.pdf"
            fig.savefig(plotnamepng, bbox_inches="tight")
            fig.savefig(plotnamepdf, bbox_inches="tight")


def plot_all_timeseries(
    chosen_model,
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
    incl2024=True
):
    if chosen_model == "BEHHHB":
        federalStates = ("Berlin", "Bremen", "Hamburg")
    if chosen_model == "fedStates":
        federalStates = (
       "Baden-Württemberg", "Bayern", "Berlin", "Brandenburg", "Bremen",
       "Hamburg", "Hessen", "Mecklenburg-Vorpommern", "Niedersachsen",
       "Nordrhein-Westfalen", "Rheinland-Pfalz", "Saarland", "Sachsen",
       "Sachsen-Anhalt", "Schleswig-Holstein", "Thüringen")
    if chosen_model == "cities":  
        federalStates = [
        "Berlin", "Bremen", "Hamburg", "München", "Stuttgart", "Köln", "Frankfurt", "Düsseldorf", "Leipzig", "Bonn"]
    if chosen_model == "cities_MeckPomm":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin", "Vorpommern-Greifswald", "Ludwigslust-Parchim", "Nordwestmecklenburg", "Mecklenburgische Seenplatte", "Rostock", "Vorpommern-Rügen",
       "Nordsachsen", "Meißen", "Bautzen", "Görlitz", "Mittelsachsen", "Chemnitz", "Zwickau", "Vogtlandkreis", "Erzgebirgskreis", "Potsdam", "Frankfurt am Main"]
    if chosen_model == "large":
        federalStates = [
                    "Berlin", "Bremen", "Hamburg", "Stuttgart", "München", "Köln",
                    "Frankfurt am Main", "Düsseldorf", "Leipzig", "Essen", "Dortmund", "Dresden", "Nürnberg", "Hannover", "Duisburg", "Wuppertal", "Karlsruhe", "Bielefeld", "Erfurt", "Kiel",
                    "Rostock", "Mecklenburgische Seenplatte", "Vorpommern-Rügen", "Nordwestmecklenburg", "Vorpommern-Greifswald", "Ludwigslust-Parchim",
                    "Nordsachsen", "Meißen", "Bautzen", "Görlitz", "Mittelsachsen", "Chemnitz", "Zwickau", "Vogtlandkreis", "Erzgebirgskreis", "Potsdam",
                    "Altmarkkreis Salzwedel", "Anhalt-Bitterfeld", "Ravensburg", "Burgenlandkreis", "Dessau-Roßlau", "Halle (Saale)", "Harz", "Braunschweig", "Magdeburg", "Wolfsburg", "Saalekreis", "Salzlandkreis", "Stendal", "Wittenberg",
                    "Flensburg", "Lübeck", "Neumünster", "Dithmarschen", "Herzogtum Lauenburg", "Nordfriesland", "Ostholstein", "Pinneberg", "Plön", "Rendsburg-Eckernförde",      
                    "Schleswig-Flensburg", "Steinburg", "Salzgitter", "Gifhorn", "Goslar", "Helmstedt", "Göttingen", "Diepholz",                   
                    "Hildesheim", "Holzminden", "Schaumburg", "Celle", "Cuxhaven", "Lüneburg", "Osterholz", "Rotenburg (Wümme)",          
                    "Heidekreis", "Stade", "Uelzen", "Delmenhorst", "Emden", "Osnabrück", "Wilhelmshaven", "Aurich",                     
                    "Cloppenburg", "Emsland", "Friesland", "Leer", "Oldenburg", "Wittmund", "Bremerhaven", "Krefeld",                    
                    "Mönchengladbach", "Mülheim an der Ruhr", "Remscheid"         
        ]
    if chosen_model == "cities_non_hierarchical":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin"]
    if chosen_model == "countieswithproblems":
        federalStates = [
            "Berlin", "Bremen", "Hamburg", "Stuttgart", "München", "Köln",
            "Frankfurt am Main", "Düsseldorf", "Leipzig", "Essen", "Dortmund", "Dresden", "Nürnberg", "Hannover", "Duisburg", 
            "Helmstedt", "Holzminden", "Schaumburg", "Delemhorst", "Wilhelmshaven", "Emsland", "Leer", "Oldenburg", "Bremerhaven"
        ]  
              
    for i, c in enumerate(federalStates):
        # upper plot
        fig, axs = plt.subplots(4, 1, figsize=(13, 24), sharex=True)
        axs = axs.ravel()

        if incl2024:
            years = (2020, 2023)
        else:
            years = [2020]
        for year in years:
            if year == 2020:
                dates_filtered = dates_in[dates_in < np.datetime64("2021-03-01")]
                dates = np.unique(dates_filtered)
            if year == 2023:
                dates_filtered = dates_in[dates_in > np.datetime64("2022-12-31")]
                dates = np.unique(dates_filtered)

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
            for indicator in indicators_in: 
            # daylight
                if daylight_in is not None:
                    if chosen_model == "cities_non_hierarchical":
                        if year == 2020:
                            if indicator == "C":
                                y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_C<52)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_R<52)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_H<52)&(trace_in.constant_data.fedState_idx==i))
                        if year == 2023:
                            if indicator == "C":
                                y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_C>=52)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_R>=52)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_H>=52)&(trace_in.constant_data.fedState_idx==i))
                    else:
                        if year == 2020:
                            if indicator == "C":
                                y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_C<52)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_R<52)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_H<52)&(trace_in.constant_data.fedState_idx==i))
                        if year == 2023:
                            if indicator == "C":
                                y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_C>=52)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_R>=52)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_H>=52)&(trace_in.constant_data.fedState_idx==i))
                    y = y_first.dropna(dim="obs_id", how = "all")
                    plot_timeseries(
                        ax,
                        dates,
                        y,
                        color_in=colors["L"],
                        label_in="daylight",
                        alpha=0.2
                )
                # school vacation
                if school_in is not None:
                    if chosen_model == "cities_non_hierarchical":
                        if year == 2020:
                            if indicator == "C":
                                y_first = trace_in.constant_data.vacation_data_in.where((trace_in.constant_data.counter_C<56)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.vacation_data_in.where((trace_in.constant_data.counter_R<56)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.vacation_data_in.where((trace_in.constant_data.counter_H<56)&(trace_in.constant_data.fedState_idx==i))
                        if year == 2023:
                            if indicator == "C":
                                y_first = trace_in.constant_data.vacation_data_in.where((trace_in.constant_data.counter_C>=56)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.vacation_data_in.where((trace_in.constant_data.counter_R>=56)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.vacation_data_in.where((trace_in.constant_data.counter_H>=56)&(trace_in.constant_data.fedState_idx==i))
                    else:
                        if year == 2020:
                            if indicator == "C":
                                y_first = trace_in.constant_data.vacation_data_in.where((trace_in.constant_data.counter_C<56)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.vacation_data_in.where((trace_in.constant_data.counter_R<56)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.vacation_data_in.where((trace_in.constant_data.counter_H<56)&(trace_in.constant_data.fedState_idx==i))
                        if year == 2023:
                            if indicator == "C":
                                y_first = trace_in.constant_data.vacation_data_in.where((trace_in.constant_data.counter_C>=56)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.vacation_data_in.where((trace_in.constant_data.counter_R>=56)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.vacation_data_in.where((trace_in.constant_data.counter_H>=56)&(trace_in.constant_data.fedState_idx==i))
                    y = y_first.dropna(dim="obs_id", how="all")
                    plot_timeseries(
                        ax,
                        dates,
                        y,
                        color_in=colors["v"],
                        label_in="school vacation",
                        alpha=0.2
                )
                # public holidays
                if holiday_in is not None:
                    if chosen_model == "cities_non_hierarchical":
                        if year == 2020:
                            if indicator == "C":
                                y_first = trace_in.constant_data.holiday_data_in.where((trace_in.constant_data.counter_C<56)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.holiday_data_in.where((trace_in.constant_data.counter_R<56)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.holiday_data_in.where((trace_in.constant_data.counter_H<56)&(trace_in.constant_data.fedState_idx==i))
                        if year == 2023:
                            if indicator == "C":
                                y_first = trace_in.constant_data.holiday_data_in.where((trace_in.constant_data.counter_C>=56)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.holiday_data_in.where((trace_in.constant_data.counter_R>=56)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.holiday_data_in.where((trace_in.constant_data.counter_H>=56)&(trace_in.constant_data.fedState_idx==i))
                    else:
                        if year == 2020:
                            if indicator == "C":
                                y_first = trace_in.constant_data.holiday_data_in.where((trace_in.constant_data.counter_C<56)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.holiday_data_in.where((trace_in.constant_data.counter_R<56)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.holiday_data_in.where((trace_in.constant_data.counter_H<56)&(trace_in.constant_data.fedState_idx==i))
                        if year == 2023:
                            if indicator == "C":
                                y_first = trace_in.constant_data.holiday_data_in.where((trace_in.constant_data.counter_C>=56)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.holiday_data_in.where((trace_in.constant_data.counter_R>=56)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.holiday_data_in.where((trace_in.constant_data.counter_H>=56)&(trace_in.constant_data.fedState_idx==i))
                    y = y_first.dropna(dim="obs_id", how = "all")
                    plot_timeseries(
                        ax,
                        dates,
                        y,
                        color_in=colors["h"],
                        label_in="public holidays",
                        alpha=0.2
                )
                # temperature
                if temperature_in is not None:
                    if chosen_model == "cities_non_hierarchical":
                        if year == 2020:
                            if indicator == "C":
                                y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_C<56)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_R<56)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_H<56)&(trace_in.constant_data.fedState_idx==i))
                        if year == 2023:
                            if indicator == "C":
                                y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_C>=56)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_R>=56)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_H>=56)&(trace_in.constant_data.fedState_idx==i))
                    else:
                        if year == 2020:
                            if indicator == "C":
                                y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_C<56)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_R<56)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_H<56)&(trace_in.constant_data.fedState_idx==i))
                        if year == 2023:
                            if indicator == "C":
                                y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_C>=56)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_R>=56)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_H>=56)&(trace_in.constant_data.fedState_idx==i))
                    y = y_first.dropna(dim="obs_id", how = "all")
                    plot_timeseries(
                        ax,
                        dates,
                        y,
                        color_in=colors["T"],
                        label_in="temperature",
                        alpha=0.2
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
                xmin=dates[0],
                xmax=dates[-1],
                color="grey",
                linestyle="--",
                linewidth=1,
            )
            format_x_axis(ax, dates)
            ## set y label
            ax.set_ylabel("Data (Dayl (hrs), Temp (C°), \nVac (Counter), PubHol (Counter))")
            ax.legend(
                ncol=2,
                # bbox_to_anchor=(0.7, 2)
            )
            
            #2nd plot
            ax = axs[1]
            
            ## plot disease indicators
            for indicator in indicators_in:
                if chosen_model == "cities_non_hierarchical":
                    if year == 2020:
                        if indicator == "C":
                            y_first = trace_in.constant_data.C.where((trace_in.constant_data.counter_C_long<52)&(trace_in.constant_data.fedState_idx_long==i))
                        if indicator == "R":
                            y_first = trace_in.constant_data.R.where((trace_in.constant_data.counter_R<52)&(trace_in.constant_data.fedState_idx==i))
                        if indicator == "H":
                            y_first = trace_in.constant_data.H.where((trace_in.constant_data.counter_H<52)&(trace_in.constant_data.fedState_idx==i))
                    if year == 2023:
                        if indicator == "C":
                            y_first = trace_in.constant_data.C.where((trace_in.constant_data.counter_C==10000000)&(trace_in.constant_data.fedState_idx==i))
                        if indicator == "R":
                            y_first = trace_in.constant_data.R.where((trace_in.constant_data.counter_R>=52)&(trace_in.constant_data.fedState_idx==i))
                        if indicator == "H":
                            y_first = trace_in.constant_data.H.where((trace_in.constant_data.counter_H>=52)&(trace_in.constant_data.fedState_idx==i))
                else:
                    if year == 2020:
                        if indicator == "C":
                            y_first = trace_in.constant_data.C.where((trace_in.constant_data.counter_C_long>3)&(trace_in.constant_data.counter_C_long<56)&(trace_in.constant_data.fedState_idx_long==i))
                        if indicator == "R":
                            y_first = trace_in.constant_data.R.where((trace_in.constant_data.counter_C_long>3)&(trace_in.constant_data.counter_R_long<56)&(trace_in.constant_data.fedState_idx_long==i))
                        if indicator == "H":
                            y_first = trace_in.constant_data.H.where((trace_in.constant_data.counter_C_long>3)&(trace_in.constant_data.counter_H_long<56)&(trace_in.constant_data.fedState_idx_long==i))
                    if year == 2023:
                        if indicator == "C":
                            y_first = trace_in.constant_data.C.where((trace_in.constant_data.counter_C_long>3)&(trace_in.constant_data.counter_C_long>=56)&(trace_in.constant_data.fedState_idx_long==i))
                        if indicator == "R":
                            y_first = trace_in.constant_data.R.where((trace_in.constant_data.counter_C_long>3)&(trace_in.constant_data.counter_R_long>=56)&(trace_in.constant_data.fedState_idx_long==i))
                        if indicator == "H":
                            y_first = trace_in.constant_data.H.where((trace_in.constant_data.counter_C_long>3)&(trace_in.constant_data.counter_H_long>=56)&(trace_in.constant_data.fedState_idx_long==i))
                y = y_first.dropna(dim="obs_id_long", how = "any")
                plot_timeseries(
                    ax,
                    dates,
                    y,
                    color_in=colors[indicator],
                    label_in=labels[indicator],
                    alpha=0.2,
                )
            format_x_axis(ax, dates)
            ## set y label
            ax.set_ylabel("Normalized Disease Indicator")
            ax.legend(
                ncol=2,
                # bbox_to_anchor=(0.7, 2)
            )

            #3rd plot
            ax = axs[2]
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
                if year == 2020:
                    if indicator == "C":
                        y_first = trace_in.posterior.d_C.where((trace_in.constant_data.counter_C<56)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.posterior.d_R.where((trace_in.constant_data.counter_R<56)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.d_H.where((trace_in.constant_data.counter_H<56)&(trace_in.constant_data.fedState_idx==i))
                if year == 2023:
                    if indicator == "C":
                        y_first = trace_in.posterior.d_C.where((trace_in.constant_data.counter_C>=56)&(trace_in.constant_data.fedState_idx==1))
                    if indicator == "R":
                        y_first = trace_in.posterior.d_R.where((trace_in.constant_data.counter_R>=56)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.d_H.where((trace_in.constant_data.counter_H>=56)&(trace_in.constant_data.fedState_idx==i))
                y = y_first.dropna(dim="obs_id", how = "all")
                plot_timeseries(
                    ax,
                    dates,
                    y,
                    color_in=colors[indicator],
                    label_in=labels[indicator],
                    alpha=0.2,
                )
                # daylight
            if daylight_in is not None:
                if year == 2020:
                    if indicator == "C":
                        y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_C<52)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_R<52)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_H<52)&(trace_in.constant_data.fedState_idx==i))
                if year == 2023:
                    if indicator == "C":
                        y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_C>=52)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_R>=52)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_H>=52)&(trace_in.constant_data.fedState_idx==i))
                y = y_first.dropna(dim="obs_id", how = "all")
                plot_timeseries(
                    ax,
                    dates,
                    y,
                    color_in=colors["L"],
                    label_in="daylight",
                    alpha=0.2,
                )
            # school vacation
            if school_in is not None:
                if year == 2020:
                    if indicator == "C":
                        y_first = trace_in.posterior.vacation_factor.where((trace_in.constant_data.counter_C<56)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.posterior.vacation_factor.where((trace_in.constant_data.counter_R<56)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.vacation_factor.where((trace_in.constant_data.counter_H<56)&(trace_in.constant_data.fedState_idx==i))
                if year == 2023:
                    if indicator == "C":
                        y_first = trace_in.posterior.vacation_factor.where((trace_in.constant_data.counter_C>=56)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.posterior.vacation_factor.where((trace_in.constant_data.counter_R>=56)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.vacation_factor.where((trace_in.constant_data.counter_H>=56)&(trace_in.constant_data.fedState_idx==i))
                y = y_first.dropna(dim="obs_id", how = "all")
                plot_timeseries(
                    ax,
                    dates,
                    y,
                    color_in=colors["v"],
                    label_in="school vacation",
                    alpha=0.2,
                )
            # public holidays
            if holiday_in is not None:
                if year == 2020:
                    #trace_filtered = trace_in.sel(fedState = i)
                    if indicator == "C":
                        y_first = trace_in.posterior.holiday_factor.where((trace_in.constant_data.counter_C<56)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.posterior.holiday_factor.where((trace_in.constant_data.counter_R<56)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.holiday_factor.where((trace_in.constant_data.counter_H<56)&(trace_in.constant_data.fedState_idx==i))
                if year == 2023:
                    if indicator == "C":
                        y_first = trace_in.posterior.holiday_factor.where((trace_in.constant_data.counter_C>=56)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.posterior.holiday_factor.where((trace_in.constant_data.counter_R>=56)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.holiday_factor.where((trace_in.constant_data.counter_H>=56)&(trace_in.constant_data.fedState_idx==i))
                y = y_first.dropna(dim="obs_id", how = "all")
                plot_timeseries(
                    ax,
                    dates,
                    y,
                    color_in=colors["h"],
                    label_in="public holidays",
                    alpha=0.2,
                )
            # temperature
            if temperature_in is not None:
                if year == 2020:
                    if indicator == "C":
                        y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_C<56)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_R<56)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_H<56)&(trace_in.constant_data.fedState_idx==i))
                if year == 2023:
                    if indicator == "C":
                        y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_C>=56)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_R>=56)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_H>=56)&(trace_in.constant_data.fedState_idx==i))
                y = y_first.dropna(dim="obs_id", how = "all")
                plot_timeseries(
                    ax,
                    dates,
                    y,
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
                xmin=dates[0],
                xmax=dates[-1],
                color="grey",
                linestyle="--",
                linewidth=1,
            )
            date_form = DateFormatter("%m/%d")
            ax.xaxis.set_major_formatter(date_form)
            ## set y label
            ax.set_ylabel("Multiplicative impact on\nout-of-home duration")
            # ax.legend(
            # ncol=2,
            # # bbox_to_anchor=(0.7, 2)
            # )
            ax.set_title(c)

            # lower plot
            ax = axs[3]
            if year == 2020:
                if indicator == "C":
                    y_first = trace_in.observed_data.d.where((trace_in.constant_data.counter_C<56)&(trace_in.constant_data.fedState_idx==i))
                if indicator == "R":
                    y_first = trace_in.observed_data.d.where((trace_in.constant_data.counter_R<56)&(trace_in.constant_data.fedState_idx==i))
                if indicator == "H":
                    y_first = trace_in.observed_data.d.where((trace_in.constant_data.counter_H<56)&(trace_in.constant_data.fedState_idx==i))
            if year == 2023:
                if indicator == "C":
                    y_first = trace_in.observed_data.d.where((trace_in.constant_data.counter_C>=56)&(trace_in.constant_data.fedState_idx==i))
                if indicator == "R":
                    y_first = trace_in.observed_data.d.where((trace_in.constant_data.counter_R>=56)&(trace_in.constant_data.fedState_idx==i))
                if indicator == "H":
                    y_first = trace_in.observed_data.d.where((trace_in.constant_data.counter_H>=56)&(trace_in.constant_data.fedState_idx==i))
            y = y_first.dropna(dim="obs_id", how = "all")
            ax.plot(
                dates,
                y,
                label="input $d_{obs}$",
                color=colors["d_obs"],
                marker="o",
            )

            if year == 2020:
                if indicator == "C":
                    y_first = trace_in.posterior.m.where((trace_in.constant_data.counter_C<56)&(trace_in.constant_data.fedState_idx==i))
                if indicator == "R":
                    y_first = trace_in.posterior.m.where((trace_in.constant_data.counter_R<56)&(trace_in.constant_data.fedState_idx==i))
                if indicator == "H":
                    y_first = trace_in.posterior.m.where((trace_in.constant_data.counter_H<56)&(trace_in.constant_data.fedState_idx==i))
            if year == 2023:
                if indicator == "C":
                    y_first = trace_in.posterior.m.where((trace_in.constant_data.counter_C>=56)&(trace_in.constant_data.fedState_idx==i))
                if indicator == "R":
                    y_first = trace_in.posterior.m.where((trace_in.constant_data.counter_R>=56)&(trace_in.constant_data.fedState_idx==i))
                if indicator == "H":
                    y_first = trace_in.posterior.m.where((trace_in.constant_data.counter_H>=56)&(trace_in.constant_data.fedState_idx==i))
            y = y_first.dropna(dim="obs_id", how = "all")
            plot_timeseries(ax, dates, y, "inferred $d$", colors["d"])
            # ax.legend(
            #     ncol=2,
            #     # bbox_to_anchor=(1.1, -0.4)
            # )
            date_form = DateFormatter("%m/%d")
            ax.xaxis.set_major_formatter(date_form)
            # set y label
            ax.set_ylabel("Out-of-home duration [h]")

            plt.subplots_adjust(hspace=0.1)
            #fig.tight_layout()

            # save figure
            plotnamepng= f"{tag_in}/" + c + str(year) + "-timeseries.png"
            plotnamepdf = f"{tag_in}/" + c + str(year) + "-timeseries.pdf"
            fig.savefig(plotnamepng, bbox_inches="tight")
            fig.savefig(plotnamepdf, bbox_inches="tight")


# plot distribution for single indicator models
def plot_distributions(model_in, trace_in, tag_in, indicators_in, temperature_in, daylight_in, school_in, holiday_in, indicators, chosen_model, fedState_in):
    if chosen_model == "BEHHHB":
        federalStates = ("Berlin", "Bremen", "Hamburg")
    if chosen_model == "fedStates":
        federalStates = (
            "Baden-Württemberg", "Bayern", "Berlin", "Brandenburg", "Bremen",
            "Hamburg", "Hessen", "Mecklenburg-Vorpommern", "Niedersachsen",
            "Nordrhein-Westfalen", "Rheinland-Pfalz", "Saarland", "Sachsen",
            "Sachsen-Anhalt", "Schleswig-Holstein", "Thüringen")
    if chosen_model == "cities":  
        federalStates = [
        "Berlin", "Bremen", "Hamburg", "München", "Stuttgart", "Köln", "Frankfurt", "Düsseldorf", "Leipzig", "Bonn"]
    if chosen_model == "cities_MeckPomm":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin", "Vorpommern-Greifswald", "Ludwigslust-Parchim", "Nordwestmecklenburg", "Mecklenburgische Seenplatte", "Rostock", "Vorpommern-Rügen",
       "Nordsachsen", "Meißen", "Bautzen", "Görlitz", "Mittelsachsen", "Chemnitz", "Zwickau", "Vogtlandkreis", "Erzgebirgskreis", "Potsdam", "Frankfurt am Main"]
    if chosen_model == "large":
        federalStates = [
                    "Berlin", "Bremen", "Hamburg", "Stuttgart", "München", "Köln",
                    "Frankfurt am Main", "Düsseldorf", "Leipzig", "Essen", "Dortmund", "Dresden", "Nürnberg", "Hannover", "Duisburg", "Wuppertal", "Karlsruhe", "Bielefeld", "Erfurt", "Kiel",
                    "Rostock", "Mecklenburgische Seenplatte", "Vorpommern-Rügen", "Nordwestmecklenburg", "Vorpommern-Greifswald", "Ludwigslust-Parchim",
                    "Nordsachsen", "Meißen", "Bautzen", "Görlitz", "Mittelsachsen", "Chemnitz", "Zwickau", "Vogtlandkreis", "Erzgebirgskreis", "Potsdam",
                    "Altmarkkreis Salzwedel", "Anhalt-Bitterfeld", "Ravensburg", "Burgenlandkreis", "Dessau-Roßlau", "Halle (Saale)", "Harz", "Braunschweig", "Magdeburg", "Wolfsburg", "Saalekreis", "Salzlandkreis", "Stendal", "Wittenberg",
                    "Flensburg", "Lübeck", "Neumünster", "Dithmarschen", "Herzogtum Lauenburg", "Nordfriesland", "Ostholstein", "Pinneberg", "Plön", "Rendsburg-Eckernförde",      
                    "Schleswig-Flensburg", "Steinburg", "Salzgitter", "Gifhorn", "Goslar", "Helmstedt", "Göttingen", "Diepholz",                   
                    "Hildesheim", "Holzminden", "Schaumburg", "Celle", "Cuxhaven", "Lüneburg", "Osterholz", "Rotenburg (Wümme)",          
                    "Heidekreis", "Stade", "Uelzen", "Delmenhorst", "Emden", "Osnabrück", "Wilhelmshaven", "Aurich",                     
                    "Cloppenburg", "Emsland", "Friesland", "Leer", "Oldenburg", "Wittmund", "Bremerhaven", "Krefeld",                    
                    "Mönchengladbach", "Mülheim an der Ruhr", "Remscheid"         
        ]
    if chosen_model == "cities_non_hierarchical":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin"]
        
    for i, c in enumerate(federalStates):
            # --- base parameters ---
        if len(indicators_in) == 0:
            fig, axs = plt.subplots(1, 8, figsize=(18, 3))
        if len(indicators_in) == 1:
            fig, axs = plt.subplots(2, 10, figsize=(25, 10))
        elif len(indicators_in) == 2:
            fig, axs = plt.subplots(3, 8, figsize=(18, 9))
        elif len(indicators_in) == 3:
            fig, axs = plt.subplots(4, 8, figsize=(18, 12))
        elif len(indicators_in) == 4:
            fig, axs = plt.subplots(4, 8, figsize=(18, 15))
        elif len(indicators_in) == 5:
            fig, axs = plt.subplots(5, 8, figsize=(18, 18))
        
        # flatten axes
        axs = axs.flatten()

        cov19.plot.distribution( 
            model_in, trace_in.sel(fedState=i), "d_factor", dist_math="d_factor", ax=axs[0]
        )
        cov19.plot.distribution( 
            model_in, trace_in.sel(fedState=i), "d_factor2024", dist_math="d_factor", ax=axs[1]
        )

        if school_in:
            cov19.plot.distribution( 
                model_in, trace_in.sel(fedState=i), "theta_v", dist_math="\\theta_{v}", ax=axs[2]
            )
            cov19.plot.distribution( 
                model_in, trace_in, "mu_vac", dist_math="mu_vac", ax=axs[3]
            )
        if holiday_in:
            cov19.plot.distribution( 
                model_in, trace_in.sel(fedState=i), "theta_h", dist_math="\\theta_{h}", ax=axs[4]
            )
            cov19.plot.distribution( 
                model_in, trace_in, "mu_hol", dist_math="mu_hol", ax=axs[5]
            )
        
        cov19.plot.distribution( 
            model_in, trace_in, "sigma_model", dist_math="\\sigma_{model}", ax=axs[6]
        )
        
        if temperature_in:
            cov19.plot.distribution( 
                model_in, trace_in.sel(fedState=i), "amplitude_temperature", dist_math="amplitude_temperature", ax=axs[7]
            )
            cov19.plot.distribution( 
                model_in, trace_in, "mu_amp_temp", dist_math="mu_amp_temp", ax=axs[8]
            )
            
            cov19.plot.distribution( 
                model_in, trace_in.sel(fedState=i), "shift_temperature", dist_math="shift_temperature", ax=axs[9]
            )
            cov19.plot.distribution( 
                model_in, trace_in, "mu_shift_temp", dist_math="mu_shift_temp", ax=axs[10]
            )
            
            cov19.plot.distribution( 
                model_in, trace_in.sel(fedState=i), "slope_temperature", dist_math="slope_temperature", ax=axs[11]
            )
            cov19.plot.distribution( 
                model_in, trace_in, "mu_slope_temp", dist_math="mu_slope_temp", ax=axs[12]
            )

    # disease
        j = 13
        for indicator in indicators_in:
            cov19.plot.distribution( 
            model_in, trace_in.sel(fedState=i), f"mu_{indicator}", dist_math=f"mu_{{{indicator}}}", ax=axs[j]
            )
            cov19.plot.distribution( 
            model_in, trace_in, f"mu_gamma_{indicator}", dist_math=f"mu_gamma_{{{indicator}}}", ax=axs[j+1]
            )
            cov19.plot.distribution( 
            model_in, trace_in.sel(fedState=i), f"sigma_{indicator}", dist_math=f"sigma_{{{indicator}}}", ax=axs[j+2]
            )
            cov19.plot.distribution(
                model_in, trace_in.sel(fedState=i), f"multiplicator_{indicator}", dist_math=f"multiplicator_{{{indicator}}}", ax=axs[j+3]
            )
            cov19.plot.distribution(
                model_in, trace_in, f"mu_multiplicator_{indicator}", dist_math=f"mu_multiplicator_{{{indicator}}}", ax=axs[j+4]
            )
            # cov19.plot.distribution(
            #     model_in, trace_in.sel(fedState=i), f"shift_{indicator}", dist_math=f"shift_{{{indicator}}}", ax=axs[i+3]
            # )
            cov19.plot.distribution(
                model_in, trace_in.sel(fedState=i), f"slope_{indicator}", dist_math=f"slope_{{{indicator}}}", ax=axs[j+5]
            )
            cov19.plot.distribution(
                model_in, trace_in, f"mu_slope_{indicator}", dist_math=f"mu_slope_{{{indicator}}}", ax=axs[j+6]
            )
            # cov19.plot.distribution(
            #     model_in, trace_in.sel(fedState=i), f"intercept_{indicator}", dist_math=f"intercept_{{{indicator}}}", ax=axs[j+7]
            # )
            # cov19.plot.distribution(
            #     model_in, trace_in, f"mu_intercept_{indicator}", dist_math=f"mu_intercept_{{{indicator}}}", ax=axs[j+8]
            # )
            i += 8

        plotnamepng= f"{tag_in}/" + c + "-distributions.png"
        plotnamepdf = f"{tag_in}/" + c + "-distributions.pdf"

        fig.savefig(plotnamepng, dpi=300, bbox_inches="tight")
        fig.savefig(plotnamepdf, dpi=300, bbox_inches="tight")
    for indicator in indicators:
        axes = az.plot_forest(trace_in,
                           kind='forestplot',
                           var_names=[f"slope_{indicator}", f"multiplicator_{indicator}", f"intercept_{indicator}"],
                           filter_vars="regex",
                           combined=True,
                           figsize=(4, len(federalStates)))
        axes[0].set_title('Estimated Disease parameters')
        figure = axes.ravel()[0].figure

        figure.savefig(
                    f"{tag_in}/" + f"{indicator}" + "_distributions.png",
                    dpi=300,
                    bbox_inches="tight",
        )
    # --- School vacation and holdiays --- 
    if school_in:
        if holiday_in: 
            axes = az.plot_forest(trace_in,
                           kind='forestplot',
                           var_names=["theta_v", "theta_h"],
                           filter_vars="regex",
                           combined=True,
                           figsize=(4, 4))
            axes[0].set_title('Estimated School Vac./Pub Holiday parameters')
            figure = axes.ravel()[0].figure

            figure.savefig(
                    f"{tag_in}/" + "SchoolPubHol_distributions.png",
                    dpi=300,
                    bbox_inches="tight",
            )

    # --- temperature ---
    if temperature_in:
        # for i, c in enumerate(federalStates):
        #     fig, axs = plt.subplots(1, 4, figsize=(12, 3))
        #     axs = axs.flatten()
        
        #     cov19.plot.distribution(model_in, trace_in.sel(fedState=i), "amplitude_temperature", nSamples_prior=100, dist_math="amplitude-temp", ax=axs[0])

        #     cov19.plot.distribution(model_in, trace_in.sel(fedState=i), "intercept_temperature", dist_math="intercept-temp", ax=axs[1])
        
        #     cov19.plot.distribution(model_in, trace_in.sel(fedState=i), "shift_temperature", dist_math="shift-temp", ax=axs[2])

        #     cov19.plot.distribution(model_in, trace_in.sel(fedState=i), "slope_temperature", dist_math="slope-temp", ax=axs[3])

        #     # save figure
        #     plotnamepng= f"{tag_in}/" + c + "-distributions_temperature.png"
        #     plotnamepdf = f"{tag_in}/" + c + "-distributions_temperature.pdf"

        #     fig.savefig(
        #         plotnamepng,
        #         dpi=300,
        #         bbox_inches="tight",
        #     )
        #     fig.savefig(
        #         plotnamepdf,
        #         dpi=300,
        #         bbox_inches="tight",
        # )

        axes = az.plot_forest(trace_in,
                           kind='forestplot',
                           var_names=["temperature$"],
                           filter_vars="regex",
                           combined=True,
                           figsize=(4, 4))
        axes[0].set_title('Estimated temperature parameters')
        figure = axes.ravel()[0].figure

        figure.savefig(
                    f"{tag_in}/" + "temperature_distributions.png",
                    dpi=300,
                    bbox_inches="tight",
        )

    # # --- daylight ---
    if daylight_in:
        # for i, c in enumerate(federalStates):
        #     fig, axs = plt.subplots(1, 4, figsize=(12, 3))
        #     axs = axs.flatten()
        #     #cov19.plot.distribution(model_in, trace_in, "z_T", dist_math="z_{T}", ax=axs[0])
        
        #     cov19.plot.distribution(model_in, trace_in.sel(fedState=i), "amplitude_daylight", dist_math="amplitude-day", ax=axs[0])

        #     cov19.plot.distribution(model_in, trace_in.sel(fedState=i), "shift_daylight", dist_math="shift-day", ax=axs[1])
            
        #     cov19.plot.distribution(model_in, trace_in.sel(fedState=i), "intercept_daylight", dist_math="intercept-day", ax=axs[2])

        #     cov19.plot.distribution(model_in, trace_in.sel(fedState=i), "slope_daylight", dist_math="slope-day", ax=axs[3])
        
        #     plotnamepng= f"{tag_in}/" + c + "-distributions_daylight.png"
        #     plotnamepdf = f"{tag_in}/" + c + "-distributions_daylight.pdf"

        #     fig.savefig(
        #         plotnamepng,
        #         dpi=300,
        #         bbox_inches="tight",
        #     )
        #     fig.savefig(
        #         plotnamepdf,
        #         dpi=300,
        #         bbox_inches="tight",
        #     )

        axes = az.plot_forest(trace_in,
                           kind='forestplot',
                           var_names=["daylight$"],
                           filter_vars="regex",
                           combined=True,
                           figsize=(4, 4))
        axes[0].set_title('Estimated daylight parameters')
        figure = axes.ravel()[0].figure

        figure.savefig(
                    f"{tag_in}/" + "daylight_distributions.png",
                    dpi=300,
                    bbox_inches="tight",
        )
    
    ## plot temperature time series
def plot_disease_timeseries(dates_in, trace_in, tag_in, indicators, disease_data, disease_data_raw, chosen_model):
    if chosen_model == "BEHHHB":
        federalStates = (
       "Berlin", "Bremen", "Hamburg")
    if chosen_model == "fedStates":
        federalStates = (
       "Baden-Württemberg", "Bayern", "Berlin", "Brandenburg", "Bremen",
       "Hamburg", "Hessen", "Mecklenburg-Vorpommern", "Niedersachsen",
       "Nordrhein-Westfalen", "Rheinland-Pfalz", "Saarland", "Sachsen",
       "Sachsen-Anhalt", "Schleswig-Holstein", "Thüringen")
    if chosen_model == "cities":  
        federalStates = [
        "Berlin", "Bremen", "Hamburg", "München", "Stuttgart", "Köln", "Frankfurt", "Düsseldorf", "Leipzig", "Bonn"]
    if chosen_model == "cities_MeckPomm":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin", "Vorpommern-Greifswald", "Ludwigslust-Parchim", "Nordwestmecklenburg", "Mecklenburgische Seenplatte", "Rostock", "Vorpommern-Rügen",
       "Nordsachsen", "Meißen", "Bautzen", "Görlitz", "Mittelsachsen", "Chemnitz", "Zwickau", "Vogtlandkreis", "Erzgebirgskreis", "Potsdam", "Frankfurt am Main"]
    if chosen_model == "large":
        federalStates = [
                    "Berlin", "Bremen", "Hamburg", "Stuttgart", "München", "Köln",
                    "Frankfurt am Main", "Düsseldorf", "Leipzig", "Essen", "Dortmund", "Dresden", "Nürnberg", "Hannover", "Duisburg", "Wuppertal", "Karlsruhe", "Bielefeld", "Erfurt", "Kiel",
                    "Rostock", "Mecklenburgische Seenplatte", "Vorpommern-Rügen", "Nordwestmecklenburg", "Vorpommern-Greifswald", "Ludwigslust-Parchim",
                    "Nordsachsen", "Meißen", "Bautzen", "Görlitz", "Mittelsachsen", "Chemnitz", "Zwickau", "Vogtlandkreis", "Erzgebirgskreis", "Potsdam",
                    "Altmarkkreis Salzwedel", "Anhalt-Bitterfeld", "Ravensburg", "Burgenlandkreis", "Dessau-Roßlau", "Halle (Saale)", "Harz", "Braunschweig", "Magdeburg", "Wolfsburg", "Saalekreis", "Salzlandkreis", "Stendal", "Wittenberg",
                    "Flensburg", "Lübeck", "Neumünster", "Dithmarschen", "Herzogtum Lauenburg", "Nordfriesland", "Ostholstein", "Pinneberg", "Plön", "Rendsburg-Eckernförde",      
                    "Schleswig-Flensburg", "Steinburg", "Salzgitter", "Gifhorn", "Goslar", "Helmstedt", "Göttingen", "Diepholz",                   
                    "Hildesheim", "Holzminden", "Schaumburg", "Celle", "Cuxhaven", "Lüneburg", "Osterholz", "Rotenburg (Wümme)",          
                    "Heidekreis", "Stade", "Uelzen", "Delmenhorst", "Emden", "Osnabrück", "Wilhelmshaven", "Aurich",                     
                    "Cloppenburg", "Emsland", "Friesland", "Leer", "Oldenburg", "Wittmund", "Bremerhaven", "Krefeld",                    
                    "Mönchengladbach", "Mülheim an der Ruhr", "Remscheid"         
        ]
    if chosen_model == "cities_non_hierarchical":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin"]
      

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

    dates_x = dates_in[dates_in < np.datetime64("2021-03-01")]
    #dates = dates_x[dates_x > np.datetime64("2020-03-28")]
    dates_plot_long = np.unique(dates_x)

    dates = dates_x[dates_x > np.datetime64("2020-03-01")]
    dates_plot = np.unique(dates)


    for indicator in indicators:
        for i, c in enumerate(federalStates):
            fig, axs = plt.subplots(4, 1, figsize=(9, 20), sharex=True)
            axs = axs.ravel()
            ax = axs[0]
            if indicator == "C":
                y_first = trace_in.constant_data.C.where((trace_in.constant_data.counter_C_long>3)&(trace_in.constant_data.counter_C_long<56)&(trace_in.constant_data.fedState_idx_long==i))
            if indicator == "R":
                y_first = trace_in.constant_data.R.where((trace_in.constant_data.counter_C_long>3)&(trace_in.constant_data.counter_R_long<56)&(trace_in.constant_data.fedState_idx_long==i))
            if indicator == "H":
                y_first = trace_in.constant_data.H.where((trace_in.constant_data.counter_C_long>3)&(trace_in.constant_data.counter_H_long<56)&(trace_in.constant_data.fedState_idx_long==i))
            y = y_first.dropna(dim="obs_id_long", how = "any")
            plot_timeseries(
                ax,
                dates_plot,
                y,
                color_in=colors[indicator],
                label_in=labels[indicator],
            )
            format_x_axis(ax, dates_plot)
            ## set y label
            ax.set_ylabel("Disease Indicator \n(transformed)")

            ax = axs[1]
            if indicator == "C":
                y_first = trace_in.posterior.risk_C.where((trace_in.constant_data.counter_C<56)&(trace_in.constant_data.fedState_idx==i))
            if indicator == "R":
                y_first = trace_in.posterior.risk_R.where((trace_in.constant_data.counter_R<56)&(trace_in.constant_data.fedState_idx==i))
            if indicator == "H":
                y_first = trace_in.posterior.risk_H.where((trace_in.constant_data.counter_H<56)&(trace_in.constant_data.fedState_idx==i))
            y = y_first.dropna(dim="obs_id", how = "any")
            plot_timeseries(
                ax,
                dates_plot,
                y,
                color_in=colors[indicator],
                label_in=labels[indicator],
            )
            format_x_axis(ax, dates_plot)
            ## set y label
            ax.set_ylabel("Disease Indicator \n(convolved))")

            ax = axs[2] 
            if indicator == "C":
                y_first = trace_in.posterior.factor_C.where((trace_in.constant_data.counter_C<56)&(trace_in.constant_data.fedState_idx==i))
            if indicator == "R":
                y_first = trace_in.posterior.factor_R.where((trace_in.constant_data.counter_R<56)&(trace_in.constant_data.fedState_idx==i))
            if indicator == "H":
                y_first = trace_in.posterior.factor_H.where((trace_in.constant_data.counter_H<56)&(trace_in.constant_data.fedState_idx==i))
            y = y_first.dropna(dim="obs_id", how = "all")
            #dates = np.unique(dates_in)
            plot_timeseries(
                ax,
                dates_plot,
                y,
                color_in=colors[indicator],
                label_in=labels[indicator],
                alpha=0.2,
            )
            ax.set_ylim(-10, 10)
            format_x_axis(ax, dates_plot)
            # set y label
            ax.set_ylabel("Scaling \n Factor")

            # lower plot
            ax = axs[3] 
            if indicator == "C":
                y_first = trace_in.posterior.d_C.where((trace_in.constant_data.counter_C<56)&(trace_in.constant_data.fedState_idx==i))
            if indicator == "R":
                y_first = trace_in.posterior.d_R.where((trace_in.constant_data.counter_R<56)&(trace_in.constant_data.fedState_idx==i))
            if indicator == "H":  
                y_first = trace_in.posterior.d_H.where((trace_in.constant_data.counter_H<56)&(trace_in.constant_data.fedState_idx==i))          
            y = y_first.dropna(dim="obs_id", how = "all")
            #dates = np.unique(dates_in)
            plot_timeseries(
                ax,
                dates_plot,
                y,
                color_in=colors[indicator],
                label_in=labels[indicator],
                alpha=0.2,
            )
            ax.set_ylim(0.0, 1.2)
            format_x_axis(ax, dates_plot, last=True)
            # set y label
            ax.set_ylabel("Disease factor")
            ## create custom legend
            ### for median line and 94% CI
            median_line = lines.Line2D([], [], color="black", linewidth=3, label="median")
            ci_94 = patches.Patch(color="black", alpha=0.5, label="94% CI")
            ### create legend
            ax.legend(handles=[median_line, ci_94], loc="lower right", frameon=False)
            
            date_form = DateFormatter("%m/%d")
            ax.xaxis.set_major_formatter(date_form)
        
            plt.subplots_adjust(hspace=0.1)

            # save figure
            plotnamepng= f"{tag_in}/" + c + indicator + "-diseaseIndicator.png"
            plotnamepdf = f"{tag_in}/" + c + indicator + "-diseaseIndicator.pdf"
            fig.savefig(plotnamepng, bbox_inches="tight")
            fig.savefig(plotnamepdf, bbox_inches="tight")


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
    model_in, trace_in, tag_in, dates_in, dates_in_long, indicators_in, school_in, holiday_in, temperature_in, precipitation_in, daylight_in, pop_density_in, disease_data_in, disease_data_raw_in, fedState_in, chosen_model, incl2024
):
    utils.make_dir(tag_in)
    if indicators_in:
       convolution_figure(indicators_in, trace_in, dates_in, tag_in)
       plot_gamma_kernel(trace_in, tag_in, indicators_in, chosen_model)
      #plot_gamma_parameters(trace_in, indicators_in, tag_in)
       plot_disease_timeseries(dates_in_long, trace_in, tag_in, indicators_in, disease_data_in, disease_data_raw_in, chosen_model)
       plot_distributions(model_in, trace_in, tag_in, indicators_in, temperature_in, daylight_in, school_in, holiday_in, indicators_in, chosen_model, fedState_in)
    if temperature_in:
        plot_temperature_timeseries(dates_in, trace_in, tag_in, indicators_in, chosen_model, incl2024)
    if daylight_in:
        plot_daylight_timeseries(dates_in, trace_in, tag_in, indicators_in, chosen_model, incl2024)
    #plot_indicator_timeseries(dates_in, trace_in, tag_in, indicators_in, chosen_model)
    plot_all_timeseries(
        chosen_model,
        dates_in,
        trace_in,
        tag_in,
        indicators_in, 
        school_in,
        holiday_in,
        temperature_in,
        precipitation_in,
        daylight_in,
        pop_density_in,
        incl2024
    )
    plot_chains(trace_in, tag_in)