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
    "Cnat": colormap(0.0),
    "C": colormap(0.1),
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
    "d": colormap(0.85),
    "d_obs": colormap(0.8),
    "d_*": colormap(0.9),
    "d_base": colormap(0.8),
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


def format_x_axis(ax_in, x_in, last=False, n_xticks=8, year=2020):
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
        #ax_in.set_xticklabels(xticklabels)
        ax_in.xaxis.set_major_formatter(DateFormatter("%m/%d"))
        #ax_in.set_xlabel(f"Year {year}")
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
        federalStates = [
       "Baden-Württemberg", "Bayern", "Berlin", "Brandenburg", "Bremen",
       "Hamburg", "Hessen", "Mecklenburg-Vorpommern", "Niedersachsen",
       "Nordrhein-Westfalen", "Rheinland-Pfalz", "Saarland", "Sachsen",
       "Sachsen-Anhalt", "Schleswig-Holstein", "Thüringen"]
    if chosen_model == "fedStates_nat":
        federalStates = [
       "Baden-Württemberg", "Bayern", "Berlin", "Brandenburg", "Bremen",
       "Hamburg", "Hessen", "Mecklenburg-Vorpommern", "Niedersachsen",
       "Nordrhein-Westfalen", "Rheinland-Pfalz", "Saarland", "Sachsen",
       "Sachsen-Anhalt", "Schleswig-Holstein", "Thüringen"]
    if chosen_model == "cities":  
        federalStates = [
        "Berlin","Bielefeld","Bonn","Braunschweig","Bremen","Chemnitz",         
        "Dortmund","Dresden","Duisburg","Düsseldorf","Erfurt","Essen",            
        "Frankfurt am Main" "Halle (Saale)","Hamburg","Hannover","Karlsruhe","Kiel",             
        "Krefeld","Köln","Leipzig","Lübeck","Magdeburg","Mönchengladbach",  
        "München","Münster","Nürnberg","Oldenburg","Potsdam","Rostock",          
        "Stuttgart","Wiesbaden","Wuppertal"]
    if chosen_model == "cities_MeckPomm":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin", "Vorpommern-Greifswald", "Ludwigslust-Parchim", "Nordwestmecklenburg", "Mecklenburgische Seenplatte", "Rostock", "Vorpommern-Rügen",
       "Nordsachsen", "Meißen", "Bautzen", "Görlitz", "Mittelsachsen", "Chemnitz", "Zwickau", "Vogtlandkreis", "Erzgebirgskreis", "Potsdam", "Frankfurt am Main"]
    if chosen_model == "large":
        federalStates = ["Ahrweiler", "Alb-Donau-Kreis", "Altmarkkreis Salzwedel",             
        "Altötting", "Alzey-Worms", "Amberg",
        "Amberg-Sulzbach", "Anhalt-Bitterfeld" , "Aurich",                             
        "Bad Dürkheim", "Bad Kissingen", "Bad Kreuznach",                      
        "Baden-Baden",  "Bautzen",  "Berchtesgadener Land",               
        "Berlin", "Bernkastel-Wittlich", "Bielefeld",                          
        "Birkenfeld", "Böblingen","Bodenseekreis",                      
        "Bonn", "Borken", "Braunschweig",                       
        "Breisgau-Hochschwarzwald", "Bremen",  "Bremerhaven",                        
        "Burgenlandkreis", "Calw", "Celle",                              
        "Chemnitz", "Cloppenburg", "Cochem-Zell",                        
        "Coesfeld", "Cuxhaven",  "Dachau",                             
        "Darmstadt-Dieburg", "Deggendorf", "Delmenhorst",                        
        "Dessau-Roßlau", "Diepholz", "Dillingen an der Donau",             
        "Dingolfing-Landau", "Dithmarschen", "Donau-Ries",                         
        "Donnersbergkreis", "Dortmund","Dresden",                           
        "Duisburg",  "Düren", "Düsseldorf",                         
        "Ebersberg", "Eichstätt", "Eifelkreis Bitburg-Prüm",            
        "Elbe-Elster", "Emden", "Emmendingen",                        
        "Emsland", "Ennepe-Ruhr-Kreis", "Enzkreis",                           
        "Erding", "Erfurt", "Erlangen",                           
        "Erlangen-Höchstadt", "Erzgebirgskreis", "Essen",                              
        "Esslingen", "Euskirchen", "Flensburg",                          
        "Forchheim", "Frankfurt am Main", "Freiburg im Breisgau",               
        "Freising", "Freudenstadt", "Freyung-Grafenau",                   
        "Friesland", "Fulda", "Fürstenfeldbruck",                   
        "Garmisch-Partenkirchen",  "Gießen", "Gifhorn",                            
        "Görlitz", "Goslar", "Göttingen",                          
        "Günzburg", "Gütersloh", "Halle (Saale)",                      
        "Hamburg", "Hannover", "Harz",                               
        "Haßberge", "Heidekreis", "Heidenheim",                         
        "Heinsberg", "Helmstedt", "Herford",                            
        "Hersfeld-Rotenburg", "Herzogtum Lauenburg", "Hildesheim",                         
        "Hochsauerlandkreis", "Hohenlohekreis", "Holzminden",                         
        "Höxter", "Ingolstadt", "Karlsruhe",                          
        "Kaufbeuren", "Kempten (Allgäu)", "Kiel",                               
        "Kitzingen", "Kleve", "Köln",                               
        "Konstanz",  "Krefeld", "Kronach",                            
        "Lahn-Dill-Kreis", "Landsberg am Lech", "Leer",                               
        "Leipzig", "Leverkusen","Limburg-Weilburg",                   
        "Lippe", "Lörrach","Lübeck",                             
        "Ludwigsburg", "Ludwigslust-Parchim", "Lüneburg",                           
        "Magdeburg", "Main-Kinzig-Kreis", "Main-Spessart",                      
        "Mainz-Bingen", "Mannheim", "Marburg-Biedenkopf",                 
        "Märkisch-Oderland",  "Märkischer Kreis", "Mecklenburgische Seenplatte",        
        "Meißen", "Memmingen", "Merzig-Wadern",                      
        "Mettmann", "Miesbach", "Miltenberg",                         
        "Minden-Lübbecke", "Mittelsachsen", "Mönchengladbach",                    
        "Mühldorf am Inn", "Mülheim an der Ruhr", "München",                            
        "Münster", "Neckar-Odenwald-Kreis", "Neuburg-Schrobenhausen",             
        "Neumarkt in der Oberpfalz", "Neumünster", "Neunkirchen",                        
        "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab", "Neuwied",                            
        "Nordfriesland", "Nordsachsen", "Nordwestmecklenburg",
        "Nürnberg", "Oberallgäu", "Oberbergischer Kreis",               
        "Oberspreewald-Lausitz", "Odenwaldkreis", "Offenbach",                         
        "Offenbach am Main", "Oldenburg", "Olpe",                               
        "Ortenaukreis", "Osnabrück", "Ostalbkreis",                        
        "Osterholz", "Ostholstein", "Ostprignitz-Ruppin",                 
        "Paderborn", "Pforzheim", "Pinneberg",                          
        "Plön", "Potsdam", "Potsdam-Mittelmark",                 
        "Prignitz",  "Rastatt", "Ravensburg",                         
        "Recklinghausen", "Regen",  "Regionalverband Saarbrücken",        
        "Remscheid", "Rendsburg-Eckernförde", "Reutlingen",                         
        "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rhein-Neuss",                        
        "Rhein-Sieg-Kreis",  "Rostock", "Rotenburg (Wümme)",                  
        "Roth", "Rottal-Inn", "Rottweil",                           
        "Saalekreis", "Saarlouis",   "Salzgitter",                         
        "Salzlandkreis",  "Schaumburg", "Schleswig-Flensburg",                
        "Schwalm-Eder-Kreis", "Schwandorf", "Schwarzwald-Baar-Kreis",             
        "Schwerin", "Siegen-Wittgenstein","Sigmaringen",                        
        "Soest", "Spree-Neiße", "Stade",                              
        "Städteregion Aachen", "Steinburg", "Steinfurt",                          
        "Stendal", "Straubing", "Straubing-Bogen",                    
        "Stuttgart", "Südliche Weinstraße", "Südwestpfalz",                       
        "Teltow-Fläming", "Tirschenreuth", "Traunstein",                         
        "Trier-Saarburg", "Tuttlingen",  "Uckermark",                          
        "Uelzen", "Ulm", "Unna",                               
        "Viersen", "Vogelsbergkreis","Vogtlandkreis",                      
        "Vorpommern-Greifswald", "Vorpommern-Rügen", "Waldeck-Frankenberg",                
        "Waldshut", "Warendorf", "Weiden in der Oberpfalz",            
        "Weilheim-Schongau","Weißenburg-Gunzenhausen","Wiesbaden" ,                         
        "Wilhelmshaven", "Wittenberg", "Wittmund",                           
        "Wolfsburg", "Wunsiedel im Fichtelgebirge", "Wuppertal",                          
        "Zollernalbkreis", "Zwickau"  
        ]
    if chosen_model == "firsthundred":
        federalStates = ["Aurich","Bielefeld","Bonn","Borken","Braunschweig","Bremen","Bremerhaven",          
        "Celle","Cloppenburg", "Coesfeld", "Cuxhaven", "Delmenhorst", "Diepholz", "Dithmarschen",         
        "Duisburg","Düren", "Düsseldorf", "Emden", "Emsland", "Essen","Euskirchen",           
        "Flensburg","Friesland", "Gifhorn", "Goslar", "Göttingen", "Gütersloh", "Hamburg",              
        "Hameln-Pyrmont","Hannover", "Harburg", "Heidekreis", "Heinsberg", "Helmstedt", "Herford",              
        "Herzogtum Lauenburg","Hildesheim", "Holzminden", "Kiel", "Kleve", "Krefeld", "Köln",                 
        "Landkreis Oldenburg","Landkreis Osnabrück","Leer",  "Leverkusen", "Lübeck", "Lüchow-Dannenberg", "Lüneburg",             
        "Mettmann","Mönchengladbach","Mülheim an der Ruhr", "Münster", "Neumünster", "NienburgWeser", "Nordfriesland",        
        "Oberbergischer Kreis","Oldenburg" , "Osnabrück", "Osterholz", "Ostholstein", "Pinneberg", "Plön",                 
        "Recklinghausen", "Remscheid","Rendsburg-Eckernförde", "Rhein-Neuss", "Rhein-Sieg-Kreis", "Rotenburg (Wümme)", "Salzgitter",           
        "Schaumburg", "Schleswig-Flensburg","Segeberg", "Stade", "Steinburg", "Steinfurt", "Städteregion Aachen",  
        "Uelzen", "Viersen", "Warendorf", "Wilhelmshaven", "Wittmund", "Wolfsburg", "Wuppertal"]
    if chosen_model == "secondhundred":
        federalStates = ["Ahrweiler",   "Altenkirchen",  "Alzey-Worms",  "Bad Dürkheim" , "Bad Kreuznach" , "Baden-Baden",
                         "Bernkastel-Wittlich", "Birkenfeld",  "Böblingen", "Cochem-Zell", "Darmstadt-Dieburg", "Donnersbergkreis", "Dortmund",  "Eifelkreis Bitburg-Prüm",  "Ennepe-Ruhr-Kreis", "Esslingen",  
                         "Frankenthal (Pfalz)",  "Frankfurt am Main", "Fulda",  "Gießen", "Groß-Gerau", "Heidenheim",  "Heilbronn", 
                         "Hersfeld-Rotenburg", "Hochsauerlandkreis", "Hochtaunuskreis",   "Hohenlohekreis", "Höxter", "Kaiserslautern", "Karlsruhe", "Kassel", "Koblenz",   "Lahn-Dill-Kreis", "Landau in der Pfalz",  "Landkreis Heilbronn", "Landkreis Karlsruhe",
                         "Limburg-Weilburg",  "Lippe",  "Ludwigsburg" ,  "Main-Kinzig-Kreis", "Main-Tauber-Kreis", "Mainz",   "Mainz-Bingen",  "Mannheim",  "Marburg-Biedenkopf", "Mayen-Koblenz", "Minden-Lübbecke", "Märkischer Kreis",
                         "Neckar-Odenwald-Kreis", "Neustadt an der Weinstraße",  "Neuwied", "Odenwaldkreis", "Offenbach",                  "Offenbach am Main",  "Olpe", "Ostalbkreis", "Paderborn", "Pforzheim", "Pirmasens",  "Rastatt", "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rheingau-Taunus-Kreis", "Schwalm-Eder-Kreis",
                         "Schwäbisch Hall", "Siegen-Wittgenstein", "Soest" , "Speyer" ,  "Stuttgart", "Südliche Weinstraße", "Südwestpfalz",              "Trier",   "Trier-Saarburg",  "Unna",  "Vogelsbergkreis", "Waldeck-Frankenberg", "Werra-Meißner-Kreis",  "Westerwaldkreis", "Wiesbaden",  "Worms", "Zweibrücken"]
    if chosen_model == "thirdhundred":
        federalStates = ["Alb-Donau-Kreis",  "Altötting", "Amberg", "Amberg-Sulzbach",  "Ansbach", "Aschaffenburg", "Bad Kissingen", "Bamberg",  "Bayreuth", "Berchtesgadener Land", "Biberach", "Bodenseekreis", "Breisgau-Hochschwarzwald", "Calw", "Cham",                               
        "Coburg", "Dachau", "Deggendorf", "Dingolfing-Landau",  "Ebersberg", "Eichstätt", "Emmendingen",  "Enzkreis", "Erding", "Erlangen",  "Erlangen-Höchstadt", "Forchheim", "Freiburg im Breisgau", "Freising", "Freudenstadt", "Freyung-Grafenau", "Fürstenfeldbruck", "Fürth", "Garmisch-Partenkirchen", "Haßberge", "Hof", "Ingolstadt", "Kelheim", "Kitzingen", "Konstanz",  "Kronach", "Landkreis Ansbach", "Landkreis Aschaffenburg", "Landkreis Bamberg",  "Landkreis Bayreuth", "Landkreis Coburg",                    "Landkreis Fürth", "Landkreis Hof", "Landkreis Landshut", "Landkreis München", "Landkreis Passau", "Landkreis Regensburg", "Landsberg am Lech",  "Landshut",                           
        "Lörrach", "Miesbach", "Mühldorf am Inn", "München",  "Neuburg-Schrobenhausen", "Neumarkt in der Oberpfalz", "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab",  "Nürnberg",  "Nürnberger Land",  "Ortenaukreis",  "Passau",                             
        "Ravensburg", "Regen",  "Regensburg", "Reutlingen",  "Rhön-Grabfeld", "Rosenheim", "Roth",  "Rottal-Inn", "Rottweil",
        "Schwabach", "Schwandorf",  "Schwarzwald-Baar-Kreis", "Schweinfurt", "Sigmaringen", "Straubing", "Straubing-Bogen",  "Tirschenreuth", "Traunstein",                         
        "Tuttlingen",  "Ulm",  "Waldshut ", 
        "Weiden in der Oberpfalz", "Weilheim-Schongau",  "Weißenburg-Gunzenhausen",            
        "Wunsiedel im Fichtelgebirge", "Würzburg", "Zollernalbkreis"]    
    if chosen_model == "fourthhundred":
        federalStates = ["Altenburger Land",   "Altmarkkreis Salzwedel",   "Anhalt-Bitterfeld",  "Augsburg",                        
        "Bautzen",  "Berlin",   "Börde", "Brandenburg an der Havel",        
        "Burgenlandkreis",  "Chemnitz",  "Dahme-Spreewald", "Dessau-Roßlau",                   
        "Dillingen an der Donau", "Donau-Ries",  "Dresden", "Eichsfeld",                       
        "Elbe-Elster",  "Erfurt", "Erzgebirgskreis",  "Frankfurt (Oder)",                
        "Gera",  "Görlitz", "Gotha",  "Greiz",                           
        "Günzburg",    "Halle (Saale)",  "Harz",  "Hildburghausen",                  
        "Ilm-Kreis", "Jena",  "Jerichower Land", "Kaufbeuren",                      
        "Kempten (Allgäu)",  "Landkreis Augsburg",  "Landkreis Leipzig",   "Landkreis Rostock",               
        "Landkreis Schweinfurt" , "Landkreis Würzburg" , "Leipzig",  "Ludwigslust-Parchim",             
        "Magdeburg",  "Main-Spessart",  "Märkisch-Oderland",  "Mecklenburgische Seenplatte",     
        "Meißen",   "Memmingen",     "Merzig-Wadern", "Miltenberg",                      
        "Mittelsachsen",  "Neu-Ulm", "Neunkirchen",  "Nordsachsen",                     
        "Nordwestmecklenburg",  "Oberallgäu",   "Oberhavel",   "Oberspreewald-Lausitz",           
        "Oder-Spree",   "Ostprignitz-Ruppin", "Potsdam",  "Potsdam-Mittelmark",              
        "Prignitz",  "Regionalverband Saarbrücken", "Rostock",  "Saale-Orla-Kreis",                
        "Saalekreis",  "Saalfeld-Rudolstadt" , "Saarlouis" ,  "Sächsische Schweiz-Osterzgebirge",
        "Salzlandkreis",   "Schmalkalden-Meiningen",  "Schwerin",  "Sömmerda",                        
        "Sonneberg",  "Spree-Neiße",  "Stendal",  "Suhl",                            
        "Teltow-Fläming",  "Uckermark",  "Unstrut-Hainich-Kreis",  "Vogtlandkreis",                   
        "Vorpommern-Greifswald", "Vorpommern-Rügen",  "Wartburgkreis",  "Weimar",                          
        "Weimarer Land",   "Wittenberg",  "Zwickau"]     
    if chosen_model == "firstsecondhundred":
        federalStates = ["Aurich","Bielefeld","Bonn","Borken","Braunschweig","Bremen","Bremerhaven",          
        "Celle","Cloppenburg", "Coesfeld", "Cuxhaven", "Delmenhorst", "Diepholz", "Dithmarschen",         
        "Duisburg","Düren", "Düsseldorf", "Emden", "Emsland", "Essen","Euskirchen",           
        "Flensburg","Friesland", "Gifhorn", "Goslar", "Göttingen", "Gütersloh", "Hamburg",              
        "Hameln-Pyrmont","Hannover", "Harburg", "Heidekreis", "Heinsberg", "Helmstedt", "Herford",              
        "Herzogtum Lauenburg","Hildesheim", "Holzminden", "Kiel", "Kleve", "Krefeld", "Köln",                 
        "Landkreis Oldenburg","Landkreis Osnabrück","Leer",  "Leverkusen", "Lübeck", "Lüchow-Dannenberg", "Lüneburg",             
        "Mettmann","Mönchengladbach","Mülheim an der Ruhr", "Münster", "Neumünster", "NienburgWeser", "Nordfriesland",        
        "Oberbergischer Kreis","Oldenburg" , "Osnabrück", "Osterholz", "Ostholstein", "Pinneberg", "Plön",                 
        "Recklinghausen", "Remscheid","Rendsburg-Eckernförde", "Rhein-Neuss", "Rhein-Sieg-Kreis", "Rotenburg (Wümme)", "Salzgitter",           
        "Schaumburg", "Schleswig-Flensburg","Segeberg", "Stade", "Steinburg", "Steinfurt", "Städteregion Aachen",  
        "Uelzen", "Viersen", "Warendorf", "Wilhelmshaven", "Wittmund", "Wolfsburg", "Wuppertal",
        "Ahrweiler",   "Altenkirchen",  "Alzey-Worms",  "Bad Dürkheim" , "Bad Kreuznach" , "Baden-Baden",
        "Bernkastel-Wittlich", "Birkenfeld",  "Böblingen", "Cochem-Zell", "Darmstadt-Dieburg", "Donnersbergkreis", "Dortmund",  "Eifelkreis Bitburg-Prüm",  "Ennepe-Ruhr-Kreis", "Esslingen",  
        "Frankenthal (Pfalz)",  "Frankfurt am Main", "Fulda",  "Gießen", "Groß-Gerau", "Heidenheim",  "Heilbronn", 
        "Hersfeld-Rotenburg", "Hochsauerlandkreis", "Hochtaunuskreis",   "Hohenlohekreis", "Höxter", "Kaiserslautern", "Karlsruhe", "Kassel", "Koblenz",   "Lahn-Dill-Kreis", "Landau in der Pfalz",  "Landkreis Heilbronn", "Landkreis Karlsruhe",
        "Limburg-Weilburg",  "Lippe",  "Ludwigsburg" ,  "Main-Kinzig-Kreis", "Main-Tauber-Kreis", "Mainz",   "Mainz-Bingen",  "Mannheim",  "Marburg-Biedenkopf", "Mayen-Koblenz", "Minden-Lübbecke", "Märkischer Kreis",
        "Neckar-Odenwald-Kreis", "Neustadt an der Weinstraße",  "Neuwied", "Odenwaldkreis", "Offenbach", "Offenbach am Main",  "Olpe", "Ostalbkreis", "Paderborn", "Pforzheim", "Pirmasens",  "Rastatt", "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rheingau-Taunus-Kreis", "Schwalm-Eder-Kreis",
        "Schwäbisch Hall", "Siegen-Wittgenstein", "Soest" , "Speyer" ,  "Stuttgart", "Südliche Weinstraße", "Südwestpfalz", "Trier",   "Trier-Saarburg",  "Unna",  "Vogelsbergkreis", "Waldeck-Frankenberg", "Werra-Meißner-Kreis",  "Westerwaldkreis", "Wiesbaden",  "Worms", "Zweibrücken"
        ]
    if chosen_model == "thirdfourthhundred":
        federalStates = ["Alb-Donau-Kreis",  "Altötting", "Amberg", "Amberg-Sulzbach",  "Ansbach", "Aschaffenburg", "Bad Kissingen", "Bamberg",  "Bayreuth", "Berchtesgadener Land", "Biberach", "Bodenseekreis", "Breisgau-Hochschwarzwald", "Calw", "Cham",                               
        "Coburg", "Dachau", "Deggendorf", "Dingolfing-Landau",  "Ebersberg", "Eichstätt", "Emmendingen",  "Enzkreis", "Erding", "Erlangen",  "Erlangen-Höchstadt", "Forchheim", "Freiburg im Breisgau", "Freising", "Freudenstadt", "Freyung-Grafenau", "Fürstenfeldbruck", "Fürth", "Garmisch-Partenkirchen", "Haßberge", "Hof", "Ingolstadt", "Kelheim", "Kitzingen", "Konstanz",  "Kronach", "Landkreis Ansbach", "Landkreis Aschaffenburg", "Landkreis Bamberg",  "Landkreis Bayreuth", "Landkreis Coburg", "Landkreis Fürth", "Landkreis Hof", "Landkreis Landshut", "Landkreis München", "Landkreis Passau", "Landkreis Regensburg", "Landsberg am Lech",  "Landshut",                           
        "Lörrach", "Miesbach", "Mühldorf am Inn", "München",  "Neuburg-Schrobenhausen", "Neumarkt in der Oberpfalz", "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab",  "Nürnberg",  "Nürnberger Land",  "Ortenaukreis",  "Passau",                             
        "Ravensburg", "Regen",  "Regensburg", "Reutlingen",  "Rhön-Grabfeld", "Rosenheim", "Roth",  "Rottal-Inn", "Rottweil",
        "Schwabach", "Schwandorf",  "Schwarzwald-Baar-Kreis", "Schweinfurt",  "Sigmaringen", "Straubing", "Straubing-Bogen",  "Tirschenreuth", "Traunstein",                         
        "Tuttlingen",  "Ulm",  "Waldshut ", 
        "Weiden in der Oberpfalz", "Weilheim-Schongau",  "Weißenburg-Gunzenhausen",            
        "Wunsiedel im Fichtelgebirge", "Würzburg", "Zollernalbkreis",
        "Altenburger Land",   "Altmarkkreis Salzwedel",   "Anhalt-Bitterfeld",  "Augsburg",                        
        "Bautzen",  "Berlin",   "Börde", "Brandenburg an der Havel",        
        "Burgenlandkreis",  "Chemnitz",  "Dahme-Spreewald", "Dessau-Roßlau",                   
        "Dillingen an der Donau", "Donau-Ries",  "Dresden", "Eichsfeld",                       
        "Elbe-Elster",  "Erfurt", "Erzgebirgskreis",  "Frankfurt (Oder)",                
        "Gera",  "Görlitz", "Gotha",  "Greiz",                           
        "Günzburg",    "Halle (Saale)",  "Harz",  "Hildburghausen",                  
        "Ilm-Kreis", "Jena",  "Jerichower Land", "Kaufbeuren",                      
        "Kempten (Allgäu)",  "Landkreis Augsburg",  "Landkreis Leipzig",   "Landkreis Rostock",               
        "Landkreis Schweinfurt" , "Landkreis Würzburg" , "Leipzig",  "Ludwigslust-Parchim",             
        "Magdeburg",  "Main-Spessart",  "Märkisch-Oderland",  "Mecklenburgische Seenplatte",     
        "Meißen",   "Memmingen",     "Merzig-Wadern", "Miltenberg",                      
        "Mittelsachsen",  "Neu-Ulm", "Neunkirchen",  "Nordsachsen",                     
        "Nordwestmecklenburg",  "Oberallgäu",   "Oberhavel",   "Oberspreewald-Lausitz",           
        "Oder-Spree",   "Ostprignitz-Ruppin", "Potsdam",  "Potsdam-Mittelmark",              
        "Prignitz",  "Regionalverband Saarbrücken", "Rostock",  "Saale-Orla-Kreis",                
        "Saalekreis",  "Saalfeld-Rudolstadt" , "Saarlouis" ,  "Sächsische Schweiz-Osterzgebirge",
        "Salzlandkreis",   "Schmalkalden-Meiningen",  "Schwerin",  "Sömmerda",                        
        "Sonneberg",  "Spree-Neiße",  "Stendal",  "Suhl",                            
        "Teltow-Fläming",  "Uckermark",  "Unstrut-Hainich-Kreis",  "Vogtlandkreis",                   
        "Vorpommern-Greifswald", "Vorpommern-Rügen",  "Wartburgkreis",  "Weimar",                          
        "Weimarer Land",   "Wittenberg",  "Zwickau"] 
    if chosen_model == "fourhundred":
        federalStates = ["Aurich","Bielefeld","Bonn","Borken","Braunschweig","Bremen","Bremerhaven",          
        "Celle","Cloppenburg", "Coesfeld", "Cuxhaven", "Delmenhorst", "Diepholz", "Dithmarschen",         
        "Duisburg","Düren", "Düsseldorf", "Emden", "Emsland", "Essen","Euskirchen",           
        "Flensburg","Friesland", "Gifhorn", "Goslar", "Göttingen", "Gütersloh", "Hamburg",              
        "Hameln-Pyrmont","Hannover", "Harburg", "Heidekreis", "Heinsberg", "Helmstedt", "Herford",              
        "Herzogtum Lauenburg","Hildesheim", "Holzminden", "Kiel", "Kleve", "Krefeld", "Köln",                 
        "Landkreis Oldenburg","Landkreis Osnabrück","Leer",  "Leverkusen", "Lübeck", "Lüchow-Dannenberg", "Lüneburg",             
        "Mettmann","Mönchengladbach","Mülheim an der Ruhr", "Münster", "Neumünster", "NienburgWeser", "Nordfriesland",        
        "Oberbergischer Kreis","Oldenburg" , "Osnabrück", "Osterholz", "Ostholstein", "Pinneberg", "Plön",                 
        "Recklinghausen", "Remscheid","Rendsburg-Eckernförde", "Rhein-Neuss", "Rhein-Sieg-Kreis", "Rotenburg (Wümme)", "Salzgitter",           
        "Schaumburg", "Schleswig-Flensburg","Segeberg", "Stade", "Steinburg", "Steinfurt", "Städteregion Aachen",  
        "Uelzen", "Viersen", "Warendorf", "Wilhelmshaven", "Wittmund", "Wolfsburg", "Wuppertal",
        "Ahrweiler",   "Altenkirchen",  "Alzey-Worms",  "Bad Dürkheim" , "Bad Kreuznach" , "Baden-Baden",
        "Bernkastel-Wittlich", "Birkenfeld",  "Böblingen", "Cochem-Zell", "Darmstadt-Dieburg", "Donnersbergkreis", "Dortmund",  "Eifelkreis Bitburg-Prüm",  "Ennepe-Ruhr-Kreis", "Esslingen",  
        "Frankenthal (Pfalz)",  "Frankfurt am Main", "Fulda",  "Gießen", "Groß-Gerau", "Heidenheim",  "Heilbronn", 
        "Hersfeld-Rotenburg", "Hochsauerlandkreis", "Hochtaunuskreis",   "Hohenlohekreis", "Höxter", "Kaiserslautern", "Karlsruhe", "Kassel", "Koblenz",   "Lahn-Dill-Kreis", "Landau in der Pfalz",  "Landkreis Heilbronn", "Landkreis Karlsruhe",
        "Limburg-Weilburg",  "Lippe",  "Ludwigsburg" ,  "Main-Kinzig-Kreis", "Main-Tauber-Kreis", "Mainz",   "Mainz-Bingen",  "Mannheim",  "Marburg-Biedenkopf", "Mayen-Koblenz", "Minden-Lübbecke", "Märkischer Kreis",
        "Neckar-Odenwald-Kreis", "Neustadt an der Weinstraße",  "Neuwied", "Odenwaldkreis", "Offenbach", "Offenbach am Main",  "Olpe", "Ostalbkreis", "Paderborn", "Pforzheim", "Pirmasens",  "Rastatt", "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rheingau-Taunus-Kreis", "Schwalm-Eder-Kreis",
        "Schwäbisch Hall", "Siegen-Wittgenstein", "Soest" , "Speyer" ,  "Stuttgart", "Südliche Weinstraße", "Südwestpfalz", "Trier",   "Trier-Saarburg",  "Unna",  "Vogelsbergkreis", "Waldeck-Frankenberg", "Werra-Meißner-Kreis",  "Westerwaldkreis", "Wiesbaden",  "Worms", "Zweibrücken",
        "Alb-Donau-Kreis",  "Altötting", "Amberg", "Amberg-Sulzbach",  "Ansbach", "Aschaffenburg", "Bad Kissingen", "Bamberg",  "Bayreuth", "Berchtesgadener Land", "Biberach", "Bodenseekreis", "Breisgau-Hochschwarzwald", "Calw", "Cham",                               
        "Coburg", "Dachau", "Deggendorf", "Dingolfing-Landau",  "Ebersberg", "Eichstätt", "Emmendingen",  "Enzkreis", "Erding", "Erlangen",  "Erlangen-Höchstadt", "Forchheim", "Freiburg im Breisgau", "Freising", "Freudenstadt", "Freyung-Grafenau", "Fürstenfeldbruck", "Fürth", "Garmisch-Partenkirchen", "Haßberge", "Hof", "Ingolstadt", "Kelheim", "Kitzingen", "Konstanz",  "Kronach", "Landkreis Ansbach", "Landkreis Aschaffenburg", "Landkreis Bamberg",  "Landkreis Bayreuth", "Landkreis Coburg", "Landkreis Fürth", "Landkreis Hof", "Landkreis Landshut", "Landkreis München", "Landkreis Passau", "Landkreis Regensburg", "Landsberg am Lech",  "Landshut",                           
        "Lörrach", "Miesbach", "Mühldorf am Inn", "München",  "Neuburg-Schrobenhausen", "Neumarkt in der Oberpfalz", "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab",  "Nürnberg",  "Nürnberger Land",  "Ortenaukreis",  "Passau",                             
        "Ravensburg", "Regen",  "Regensburg", "Reutlingen",  "Rhön-Grabfeld", "Rosenheim", "Roth",  "Rottal-Inn", "Rottweil",
        "Schwabach", "Schwandorf",  "Schwarzwald-Baar-Kreis", "Schweinfurt",  "Sigmaringen", "Straubing", "Straubing-Bogen",  "Tirschenreuth", "Traunstein",                         
        "Tuttlingen",  "Ulm",  "Waldshut ", 
        "Weiden in der Oberpfalz", "Weilheim-Schongau",  "Weißenburg-Gunzenhausen",            
        "Wunsiedel im Fichtelgebirge", "Würzburg", "Zollernalbkreis",
        "Altenburger Land",   "Altmarkkreis Salzwedel",   "Anhalt-Bitterfeld",  "Augsburg",                        
        "Bautzen",  "Berlin",   "Börde", "Brandenburg an der Havel",        
        "Burgenlandkreis",  "Chemnitz",  "Dahme-Spreewald", "Dessau-Roßlau",                   
        "Dillingen an der Donau", "Donau-Ries",  "Dresden", "Eichsfeld",                       
        "Elbe-Elster",  "Erfurt", "Erzgebirgskreis",  "Frankfurt (Oder)",                
        "Gera",  "Görlitz", "Gotha",  "Greiz",                           
        "Günzburg",    "Halle (Saale)",  "Harz",  "Hildburghausen",                  
        "Ilm-Kreis", "Jena",  "Jerichower Land", "Kaufbeuren",                      
        "Kempten (Allgäu)",  "Landkreis Augsburg",  "Landkreis Leipzig",   "Landkreis Rostock",               
        "Landkreis Schweinfurt" , "Landkreis Würzburg" , "Leipzig",  "Ludwigslust-Parchim",             
        "Magdeburg",  "Main-Spessart",  "Märkisch-Oderland",  "Mecklenburgische Seenplatte",     
        "Meißen",   "Memmingen",     "Merzig-Wadern", "Miltenberg",                      
        "Mittelsachsen",  "Neu-Ulm", "Neunkirchen",  "Nordsachsen",                     
        "Nordwestmecklenburg",  "Oberallgäu",   "Oberhavel",   "Oberspreewald-Lausitz",           
        "Oder-Spree",   "Ostprignitz-Ruppin", "Potsdam",  "Potsdam-Mittelmark",              
        "Prignitz",  "Regionalverband Saarbrücken", "Rostock",  "Saale-Orla-Kreis",                
        "Saalekreis",  "Saalfeld-Rudolstadt" , "Saarlouis" ,  "Sächsische Schweiz-Osterzgebirge",
        "Salzlandkreis",   "Schmalkalden-Meiningen",  "Schwerin",  "Sömmerda",                        
        "Sonneberg",  "Spree-Neiße",  "Stendal",  "Suhl",                            
        "Teltow-Fläming",  "Uckermark",  "Unstrut-Hainich-Kreis",  "Vogtlandkreis",                   
        "Vorpommern-Greifswald", "Vorpommern-Rügen",  "Wartburgkreis",  "Weimar",                          
        "Weimarer Land",   "Wittenberg",  "Zwickau"
        ]
    if chosen_model == "cities_non_hierarchical":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin"]
    if chosen_model == "countieswithproblems":
        federalStates = [
            "Berlin", "Bremen", "Hamburg", "Stuttgart", "München", "Köln",              
            "Frankfurt am Main", "Düsseldorf", "Leipzig", "Essen", "Dortmund", "Dresden",          
            "Nürnberg", "Duisburg", "Helmstedt", "Holzminden", "Schaumburg", "Delmenhorst",      
            "Wilhelmshaven", "Emsland", "Leer", "Oldenburg", "Bremerhaven"
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
    if chosen_model == "fedStates_nat":
        federalStates = (
       "Baden-Württemberg", "Bayern", "Berlin", "Brandenburg", "Bremen",
       "Hamburg", "Hessen", "Mecklenburg-Vorpommern", "Niedersachsen",
       "Nordrhein-Westfalen", "Rheinland-Pfalz", "Saarland", "Sachsen",
       "Sachsen-Anhalt", "Schleswig-Holstein", "Thüringen")
    if chosen_model == "cities":  
        federalStates = [
        "Berlin","Bielefeld","Bonn","Braunschweig","Bremen","Chemnitz",         
        "Dortmund","Dresden","Duisburg","Düsseldorf","Erfurt","Essen",            
        "Frankfurt am Main" "Halle (Saale)","Hamburg","Hannover","Karlsruhe","Kiel",             
        "Krefeld","Köln","Leipzig","Lübeck","Magdeburg","Mönchengladbach",  
        "München","Münster","Nürnberg","Oldenburg","Potsdam","Rostock",          
        "Stuttgart","Wiesbaden","Wuppertal"]
    if chosen_model == "cities_MeckPomm":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin", "Vorpommern-Greifswald", "Ludwigslust-Parchim", "Nordwestmecklenburg", "Mecklenburgische Seenplatte", "Rostock", "Vorpommern-Rügen",
       "Nordsachsen", "Meißen", "Bautzen", "Görlitz", "Mittelsachsen", "Chemnitz", "Zwickau", "Vogtlandkreis", "Erzgebirgskreis", "Potsdam", "Frankfurt am Main"]
    if chosen_model == "large":
        federalStates = ["Ahrweiler", "Alb-Donau-Kreis", "Altmarkkreis Salzwedel",             
        "Altötting", "Alzey-Worms", "Amberg",
        "Amberg-Sulzbach", "Anhalt-Bitterfeld" , "Aurich",                             
        "Bad Dürkheim", "Bad Kissingen", "Bad Kreuznach",                      
        "Baden-Baden",  "Bautzen",  "Berchtesgadener Land",               
        "Berlin", "Bernkastel-Wittlich", "Bielefeld",                          
        "Birkenfeld", "Böblingen","Bodenseekreis",                      
        "Bonn", "Borken", "Braunschweig",                       
        "Breisgau-Hochschwarzwald", "Bremen",  "Bremerhaven",                        
        "Burgenlandkreis", "Calw", "Celle",                              
        "Chemnitz", "Cloppenburg", "Cochem-Zell",                        
        "Coesfeld", "Cuxhaven",  "Dachau",                             
        "Darmstadt-Dieburg", "Deggendorf", "Delmenhorst",                        
        "Dessau-Roßlau", "Diepholz", "Dillingen an der Donau",             
        "Dingolfing-Landau", "Dithmarschen", "Donau-Ries",                         
        "Donnersbergkreis", "Dortmund","Dresden",                           
        "Duisburg",  "Düren", "Düsseldorf",                         
        "Ebersberg", "Eichstätt", "Eifelkreis Bitburg-Prüm",            
        "Elbe-Elster", "Emden", "Emmendingen",                        
        "Emsland", "Ennepe-Ruhr-Kreis", "Enzkreis",                           
        "Erding", "Erfurt", "Erlangen",                           
        "Erlangen-Höchstadt", "Erzgebirgskreis", "Essen",                              
        "Esslingen", "Euskirchen", "Flensburg",                          
        "Forchheim", "Frankfurt am Main", "Freiburg im Breisgau",               
        "Freising", "Freudenstadt", "Freyung-Grafenau",                   
        "Friesland", "Fulda", "Fürstenfeldbruck",                   
        "Garmisch-Partenkirchen",  "Gießen", "Gifhorn",                            
        "Görlitz", "Goslar", "Göttingen",                          
        "Günzburg", "Gütersloh", "Halle (Saale)",                      
        "Hamburg", "Hannover", "Harz",                               
        "Haßberge", "Heidekreis", "Heidenheim",                         
        "Heinsberg", "Helmstedt", "Herford",                            
        "Hersfeld-Rotenburg", "Herzogtum Lauenburg", "Hildesheim",                         
        "Hochsauerlandkreis", "Hohenlohekreis", "Holzminden",                         
        "Höxter", "Ingolstadt", "Karlsruhe",                          
        "Kaufbeuren", "Kempten (Allgäu)", "Kiel",                               
        "Kitzingen", "Kleve", "Köln",                               
        "Konstanz",  "Krefeld", "Kronach",                            
        "Lahn-Dill-Kreis", "Landsberg am Lech", "Leer",                               
        "Leipzig", "Leverkusen","Limburg-Weilburg",                   
        "Lippe", "Lörrach","Lübeck",                             
        "Ludwigsburg", "Ludwigslust-Parchim", "Lüneburg",                           
        "Magdeburg", "Main-Kinzig-Kreis", "Main-Spessart",                      
        "Mainz-Bingen", "Mannheim", "Marburg-Biedenkopf",                 
        "Märkisch-Oderland",  "Märkischer Kreis", "Mecklenburgische Seenplatte",        
        "Meißen", "Memmingen", "Merzig-Wadern",                      
        "Mettmann", "Miesbach", "Miltenberg",                         
        "Minden-Lübbecke", "Mittelsachsen", "Mönchengladbach",                    
        "Mühldorf am Inn", "Mülheim an der Ruhr", "München",                            
        "Münster", "Neckar-Odenwald-Kreis", "Neuburg-Schrobenhausen",             
        "Neumarkt in der Oberpfalz", "Neumünster", "Neunkirchen",                        
        "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab", "Neuwied",                            
        "Nordfriesland", "Nordsachsen", "Nordwestmecklenburg",
        "Nürnberg", "Oberallgäu", "Oberbergischer Kreis",               
        "Oberspreewald-Lausitz", "Odenwaldkreis", "Offenbach",                         
        "Offenbach am Main", "Oldenburg", "Olpe",                               
        "Ortenaukreis", "Osnabrück", "Ostalbkreis",                        
        "Osterholz", "Ostholstein", "Ostprignitz-Ruppin",                 
        "Paderborn", "Pforzheim", "Pinneberg",                          
        "Plön", "Potsdam", "Potsdam-Mittelmark",                 
        "Prignitz",  "Rastatt", "Ravensburg",                         
        "Recklinghausen", "Regen",  "Regionalverband Saarbrücken",        
        "Remscheid", "Rendsburg-Eckernförde", "Reutlingen",                         
        "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rhein-Neuss",                        
        "Rhein-Sieg-Kreis",  "Rostock", "Rotenburg (Wümme)",                  
        "Roth", "Rottal-Inn", "Rottweil",                           
        "Saalekreis", "Saarlouis",   "Salzgitter",                         
        "Salzlandkreis",  "Schaumburg", "Schleswig-Flensburg",                
        "Schwalm-Eder-Kreis", "Schwandorf", "Schwarzwald-Baar-Kreis",             
        "Schwerin", "Siegen-Wittgenstein","Sigmaringen",                        
        "Soest", "Spree-Neiße", "Stade",                              
        "Städteregion Aachen", "Steinburg", "Steinfurt",                          
        "Stendal", "Straubing", "Straubing-Bogen",                    
        "Stuttgart", "Südliche Weinstraße", "Südwestpfalz",                       
        "Teltow-Fläming", "Tirschenreuth", "Traunstein",                         
        "Trier-Saarburg", "Tuttlingen",  "Uckermark",                          
        "Uelzen", "Ulm", "Unna",                               
        "Viersen", "Vogelsbergkreis","Vogtlandkreis",                      
        "Vorpommern-Greifswald", "Vorpommern-Rügen", "Waldeck-Frankenberg",                
        "Waldshut", "Warendorf", "Weiden in der Oberpfalz",            
        "Weilheim-Schongau","Weißenburg-Gunzenhausen","Wiesbaden" ,                         
        "Wilhelmshaven", "Wittenberg", "Wittmund",                           
        "Wolfsburg", "Wunsiedel im Fichtelgebirge", "Wuppertal",                          
        "Zollernalbkreis", "Zwickau"  
        ]
    if chosen_model == "firsthundred":
        federalStates = ["Aurich","Bielefeld","Bonn","Borken","Braunschweig","Bremen","Bremerhaven",          
        "Celle","Cloppenburg", "Coesfeld", "Cuxhaven", "Delmenhorst", "Diepholz", "Dithmarschen",         
        "Duisburg","Düren", "Düsseldorf", "Emden", "Emsland", "Essen","Euskirchen",           
        "Flensburg","Friesland", "Gifhorn", "Goslar", "Göttingen", "Gütersloh", "Hamburg",              
        "Hameln-Pyrmont","Hannover", "Harburg", "Heidekreis", "Heinsberg", "Helmstedt", "Herford",              
        "Herzogtum Lauenburg","Hildesheim", "Holzminden", "Kiel", "Kleve", "Krefeld", "Köln",                 
        "Landkreis Oldenburg","Landkreis Osnabrück","Leer",  "Leverkusen", "Lübeck", "Lüchow-Dannenberg", "Lüneburg",             
        "Mettmann","Mönchengladbach","Mülheim an der Ruhr", "Münster", "Neumünster", "NienburgWeser", "Nordfriesland",        
        "Oberbergischer Kreis","Oldenburg" , "Osnabrück", "Osterholz", "Ostholstein", "Pinneberg", "Plön",                 
        "Recklinghausen", "Remscheid","Rendsburg-Eckernförde", "Rhein-Neuss", "Rhein-Sieg-Kreis", "Rotenburg (Wümme)", "Salzgitter",           
        "Schaumburg", "Schleswig-Flensburg","Segeberg", "Stade", "Steinburg", "Steinfurt", "Städteregion Aachen",  
        "Uelzen", "Viersen", "Warendorf", "Wilhelmshaven", "Wittmund", "Wolfsburg", "Wuppertal"]
    if chosen_model == "secondhundred":
        federalStates = ["Ahrweiler",   "Altenkirchen",  "Alzey-Worms",  "Bad Dürkheim" , "Bad Kreuznach" , "Baden-Baden",
                         "Bernkastel-Wittlich", "Birkenfeld",  "Böblingen", "Cochem-Zell", "Darmstadt-Dieburg", "Donnersbergkreis", "Dortmund",  "Eifelkreis Bitburg-Prüm",  "Ennepe-Ruhr-Kreis", "Esslingen",  
                         "Frankenthal (Pfalz)",  "Frankfurt am Main", "Fulda",  "Gießen", "Groß-Gerau", "Heidenheim",  "Heilbronn", 
                         "Hersfeld-Rotenburg", "Hochsauerlandkreis", "Hochtaunuskreis",   "Hohenlohekreis", "Höxter", "Kaiserslautern", "Karlsruhe", "Kassel", "Koblenz",   "Lahn-Dill-Kreis", "Landau in der Pfalz",  "Landkreis Heilbronn", "Landkreis Karlsruhe",
                         "Limburg-Weilburg",  "Lippe",  "Ludwigsburg" ,  "Main-Kinzig-Kreis", "Main-Tauber-Kreis", "Mainz",   "Mainz-Bingen",  "Mannheim",  "Marburg-Biedenkopf", "Mayen-Koblenz", "Minden-Lübbecke", "Märkischer Kreis",
                         "Neckar-Odenwald-Kreis", "Neustadt an der Weinstraße",  "Neuwied", "Odenwaldkreis", "Offenbach",                  "Offenbach am Main",  "Olpe", "Ostalbkreis", "Paderborn", "Pforzheim", "Pirmasens",  "Rastatt", "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rheingau-Taunus-Kreis", "Schwalm-Eder-Kreis",
                         "Schwäbisch Hall", "Siegen-Wittgenstein", "Soest" , "Speyer" ,  "Stuttgart", "Südliche Weinstraße", "Südwestpfalz",              "Trier",   "Trier-Saarburg",  "Unna",  "Vogelsbergkreis", "Waldeck-Frankenberg", "Werra-Meißner-Kreis",  "Westerwaldkreis", "Wiesbaden",  "Worms", "Zweibrücken"]
    if chosen_model == "thirdhundred":
        federalStates = ["Alb-Donau-Kreis",  "Altötting", "Amberg", "Amberg-Sulzbach",  "Ansbach",                             "Aschaffenburg", "Bad Kissingen", "Bamberg",  "Bayreuth", "Berchtesgadener Land",                "Biberach", "Bodenseekreis", "Breisgau-Hochschwarzwald", "Calw", "Cham",                               
        "Coburg", "Dachau", "Deggendorf", "Dingolfing-Landau",  "Ebersberg",                           "Eichstätt", "Emmendingen",  "Enzkreis", "Erding", "Erlangen",  "Erlangen-Höchstadt",                  "Forchheim", "Freiburg im Breisgau", "Freising", "Freudenstadt", "Freyung-Grafenau",                    "Fürstenfeldbruck", "Fürth", "Garmisch-Partenkirchen", "Haßberge", "Hof", "Ingolstadt",                          "Kelheim", "Kitzingen", "Konstanz",  "Kronach", "Landkreis Ansbach", "Landkreis Aschaffenburg", "Landkreis Bamberg",  "Landkreis Bayreuth", "Landkreis Coburg",                    "Landkreis Fürth", "Landkreis Hof", "Landkreis Landshut", "Landkreis München",                   "Landkreis Passau", "Landkreis Regensburg", "Landsberg am Lech",  "Landshut",                           
        "Lörrach", "Miesbach", "Mühldorf am Inn", "München",  "Neuburg-Schrobenhausen",              "Neumarkt in der Oberpfalz", "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab",  "Nürnberg",  "Nürnberger Land",  "Ortenaukreis",  "Passau",                             
        "Ravensburg", "Regen",  "Regensburg", "Reutlingen",  "Rhön-Grabfeld",                       "Rosenheim", "Roth",  "Rottal-Inn", "Rottweil",
        "Schwabach", "Schwandorf",  "Schwarzwald-Baar-Kreis", "Schweinfurt",                         "Sigmaringen", "Straubing", "Straubing-Bogen",  "Tirschenreuth", "Traunstein",                         
        "Tuttlingen",  "Ulm",  "Waldshut ", 
        "Weiden in der Oberpfalz", "Weilheim-Schongau",  "Weißenburg-Gunzenhausen",            
        "Wunsiedel im Fichtelgebirge", "Würzburg", "Zollernalbkreis"]    
    if chosen_model == "fourthhundred":
        federalStates = ["Altenburger Land",   "Altmarkkreis Salzwedel",   "Anhalt-Bitterfeld",  "Augsburg",                        
        "Bautzen",  "Berlin",   "Börde", "Brandenburg an der Havel",        
        "Burgenlandkreis",  "Chemnitz",  "Dahme-Spreewald", "Dessau-Roßlau",                   
        "Dillingen an der Donau", "Donau-Ries",  "Dresden", "Eichsfeld",                       
        "Elbe-Elster",  "Erfurt", "Erzgebirgskreis",  "Frankfurt (Oder)",                
        "Gera",  "Görlitz", "Gotha",  "Greiz",                           
        "Günzburg",    "Halle (Saale)",  "Harz",  "Hildburghausen",                  
        "Ilm-Kreis", "Jena",  "Jerichower Land", "Kaufbeuren",                      
        "Kempten (Allgäu)",  "Landkreis Augsburg",  "Landkreis Leipzig",   "Landkreis Rostock",               
        "Landkreis Schweinfurt" , "Landkreis Würzburg" , "Leipzig",  "Ludwigslust-Parchim",             
        "Magdeburg",  "Main-Spessart",  "Märkisch-Oderland",  "Mecklenburgische Seenplatte",     
        "Meißen",   "Memmingen",     "Merzig-Wadern", "Miltenberg",                      
        "Mittelsachsen",  "Neu-Ulm", "Neunkirchen",  "Nordsachsen",                     
        "Nordwestmecklenburg",  "Oberallgäu",   "Oberhavel",   "Oberspreewald-Lausitz",           
        "Oder-Spree",   "Ostprignitz-Ruppin", "Potsdam",  "Potsdam-Mittelmark",              
        "Prignitz",  "Regionalverband Saarbrücken", "Rostock",  "Saale-Orla-Kreis",                
        "Saalekreis",  "Saalfeld-Rudolstadt" , "Saarlouis" ,  "Sächsische Schweiz-Osterzgebirge",
        "Salzlandkreis",   "Schmalkalden-Meiningen",  "Schwerin",  "Sömmerda",                        
        "Sonneberg",  "Spree-Neiße",  "Stendal",  "Suhl",                            
        "Teltow-Fläming",  "Uckermark",  "Unstrut-Hainich-Kreis",  "Vogtlandkreis",                   
        "Vorpommern-Greifswald", "Vorpommern-Rügen",  "Wartburgkreis",  "Weimar",                          
        "Weimarer Land",   "Wittenberg",  "Zwickau"]
    if chosen_model == "firstsecondhundred":
        federalStates = ["Aurich","Bielefeld","Bonn","Borken","Braunschweig","Bremen","Bremerhaven",          
        "Celle","Cloppenburg", "Coesfeld", "Cuxhaven", "Delmenhorst", "Diepholz", "Dithmarschen",         
        "Duisburg","Düren", "Düsseldorf", "Emden", "Emsland", "Essen","Euskirchen",           
        "Flensburg","Friesland", "Gifhorn", "Goslar", "Göttingen", "Gütersloh", "Hamburg",              
        "Hameln-Pyrmont","Hannover", "Harburg", "Heidekreis", "Heinsberg", "Helmstedt", "Herford",              
        "Herzogtum Lauenburg","Hildesheim", "Holzminden", "Kiel", "Kleve", "Krefeld", "Köln",                 
        "Landkreis Oldenburg","Landkreis Osnabrück","Leer",  "Leverkusen", "Lübeck", "Lüchow-Dannenberg", "Lüneburg",             
        "Mettmann","Mönchengladbach","Mülheim an der Ruhr", "Münster", "Neumünster", "NienburgWeser", "Nordfriesland",        
        "Oberbergischer Kreis","Oldenburg" , "Osnabrück", "Osterholz", "Ostholstein", "Pinneberg", "Plön",                 
        "Recklinghausen", "Remscheid","Rendsburg-Eckernförde", "Rhein-Neuss", "Rhein-Sieg-Kreis", "Rotenburg (Wümme)", "Salzgitter",           
        "Schaumburg", "Schleswig-Flensburg","Segeberg", "Stade", "Steinburg", "Steinfurt", "Städteregion Aachen",  
        "Uelzen", "Viersen", "Warendorf", "Wilhelmshaven", "Wittmund", "Wolfsburg", "Wuppertal",
        "Ahrweiler",   "Altenkirchen",  "Alzey-Worms",  "Bad Dürkheim" , "Bad Kreuznach" , "Baden-Baden",
        "Bernkastel-Wittlich", "Birkenfeld",  "Böblingen", "Cochem-Zell", "Darmstadt-Dieburg", "Donnersbergkreis", "Dortmund",  "Eifelkreis Bitburg-Prüm",  "Ennepe-Ruhr-Kreis", "Esslingen",  
        "Frankenthal (Pfalz)",  "Frankfurt am Main", "Fulda",  "Gießen", "Groß-Gerau", "Heidenheim",  "Heilbronn", 
        "Hersfeld-Rotenburg", "Hochsauerlandkreis", "Hochtaunuskreis",   "Hohenlohekreis", "Höxter", "Kaiserslautern", "Karlsruhe", "Kassel", "Koblenz",   "Lahn-Dill-Kreis", "Landau in der Pfalz",  "Landkreis Heilbronn", "Landkreis Karlsruhe",
        "Limburg-Weilburg",  "Lippe",  "Ludwigsburg" ,  "Main-Kinzig-Kreis", "Main-Tauber-Kreis", "Mainz",   "Mainz-Bingen",  "Mannheim",  "Marburg-Biedenkopf", "Mayen-Koblenz", "Minden-Lübbecke", "Märkischer Kreis",
        "Neckar-Odenwald-Kreis", "Neustadt an der Weinstraße",  "Neuwied", "Odenwaldkreis", "Offenbach", "Offenbach am Main",  "Olpe", "Ostalbkreis", "Paderborn", "Pforzheim", "Pirmasens",  "Rastatt", "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rheingau-Taunus-Kreis", "Schwalm-Eder-Kreis",
        "Schwäbisch Hall", "Siegen-Wittgenstein", "Soest" , "Speyer" ,  "Stuttgart", "Südliche Weinstraße", "Südwestpfalz", "Trier",   "Trier-Saarburg",  "Unna",  "Vogelsbergkreis", "Waldeck-Frankenberg", "Werra-Meißner-Kreis",  "Westerwaldkreis", "Wiesbaden",  "Worms", "Zweibrücken"
        ]
    if chosen_model == "thirdfourthhundred":
        federalStates = ["Alb-Donau-Kreis",  "Altötting", "Amberg", "Amberg-Sulzbach",  "Ansbach", "Aschaffenburg", "Bad Kissingen", "Bamberg",  "Bayreuth", "Berchtesgadener Land", "Biberach", "Bodenseekreis", "Breisgau-Hochschwarzwald", "Calw", "Cham",                               
        "Coburg", "Dachau", "Deggendorf", "Dingolfing-Landau",  "Ebersberg", "Eichstätt", "Emmendingen",  "Enzkreis", "Erding", "Erlangen",  "Erlangen-Höchstadt", "Forchheim", "Freiburg im Breisgau", "Freising", "Freudenstadt", "Freyung-Grafenau", "Fürstenfeldbruck", "Fürth", "Garmisch-Partenkirchen", "Haßberge", "Hof", "Ingolstadt", "Kelheim", "Kitzingen", "Konstanz",  "Kronach", "Landkreis Ansbach", "Landkreis Aschaffenburg", "Landkreis Bamberg",  "Landkreis Bayreuth", "Landkreis Coburg", "Landkreis Fürth", "Landkreis Hof", "Landkreis Landshut", "Landkreis München", "Landkreis Passau", "Landkreis Regensburg", "Landsberg am Lech",  "Landshut",                           
        "Lörrach", "Miesbach", "Mühldorf am Inn", "München",  "Neuburg-Schrobenhausen", "Neumarkt in der Oberpfalz", "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab",  "Nürnberg",  "Nürnberger Land",  "Ortenaukreis",  "Passau",                             
        "Ravensburg", "Regen",  "Regensburg", "Reutlingen",  "Rhön-Grabfeld", "Rosenheim", "Roth",  "Rottal-Inn", "Rottweil",
        "Schwabach", "Schwandorf",  "Schwarzwald-Baar-Kreis", "Schweinfurt",  "Sigmaringen", "Straubing", "Straubing-Bogen",  "Tirschenreuth", "Traunstein",                         
        "Tuttlingen",  "Ulm",  "Waldshut ", 
        "Weiden in der Oberpfalz", "Weilheim-Schongau",  "Weißenburg-Gunzenhausen",            
        "Wunsiedel im Fichtelgebirge", "Würzburg", "Zollernalbkreis",
        "Altenburger Land",   "Altmarkkreis Salzwedel",   "Anhalt-Bitterfeld",  "Augsburg",                        
        "Bautzen",  "Berlin",   "Börde", "Brandenburg an der Havel",        
        "Burgenlandkreis",  "Chemnitz",  "Dahme-Spreewald", "Dessau-Roßlau",                   
        "Dillingen an der Donau", "Donau-Ries",  "Dresden", "Eichsfeld",                       
        "Elbe-Elster",  "Erfurt", "Erzgebirgskreis",  "Frankfurt (Oder)",                
        "Gera",  "Görlitz", "Gotha",  "Greiz",                           
        "Günzburg",    "Halle (Saale)",  "Harz",  "Hildburghausen",                  
        "Ilm-Kreis", "Jena",  "Jerichower Land", "Kaufbeuren",                      
        "Kempten (Allgäu)",  "Landkreis Augsburg",  "Landkreis Leipzig",   "Landkreis Rostock",               
        "Landkreis Schweinfurt" , "Landkreis Würzburg" , "Leipzig",  "Ludwigslust-Parchim",             
        "Magdeburg",  "Main-Spessart",  "Märkisch-Oderland",  "Mecklenburgische Seenplatte",     
        "Meißen",   "Memmingen",     "Merzig-Wadern", "Miltenberg",                      
        "Mittelsachsen",  "Neu-Ulm", "Neunkirchen",  "Nordsachsen",                     
        "Nordwestmecklenburg",  "Oberallgäu",   "Oberhavel",   "Oberspreewald-Lausitz",           
        "Oder-Spree",   "Ostprignitz-Ruppin", "Potsdam",  "Potsdam-Mittelmark",              
        "Prignitz",  "Regionalverband Saarbrücken", "Rostock",  "Saale-Orla-Kreis",                
        "Saalekreis",  "Saalfeld-Rudolstadt" , "Saarlouis" ,  "Sächsische Schweiz-Osterzgebirge",
        "Salzlandkreis",   "Schmalkalden-Meiningen",  "Schwerin",  "Sömmerda",                        
        "Sonneberg",  "Spree-Neiße",  "Stendal",  "Suhl",                            
        "Teltow-Fläming",  "Uckermark",  "Unstrut-Hainich-Kreis",  "Vogtlandkreis",                   
        "Vorpommern-Greifswald", "Vorpommern-Rügen",  "Wartburgkreis",  "Weimar",                          
        "Weimarer Land",   "Wittenberg",  "Zwickau"] 
    if chosen_model == "fourhundred":
        federalStates = ["Aurich","Bielefeld","Bonn","Borken","Braunschweig","Bremen","Bremerhaven",          
        "Celle","Cloppenburg", "Coesfeld", "Cuxhaven", "Delmenhorst", "Diepholz", "Dithmarschen",         
        "Duisburg","Düren", "Düsseldorf", "Emden", "Emsland", "Essen","Euskirchen",           
        "Flensburg","Friesland", "Gifhorn", "Goslar", "Göttingen", "Gütersloh", "Hamburg",              
        "Hameln-Pyrmont","Hannover", "Harburg", "Heidekreis", "Heinsberg", "Helmstedt", "Herford",              
        "Herzogtum Lauenburg","Hildesheim", "Holzminden", "Kiel", "Kleve", "Krefeld", "Köln",                 
        "Landkreis Oldenburg","Landkreis Osnabrück","Leer",  "Leverkusen", "Lübeck", "Lüchow-Dannenberg", "Lüneburg",             
        "Mettmann","Mönchengladbach","Mülheim an der Ruhr", "Münster", "Neumünster", "NienburgWeser", "Nordfriesland",        
        "Oberbergischer Kreis","Oldenburg" , "Osnabrück", "Osterholz", "Ostholstein", "Pinneberg", "Plön",                 
        "Recklinghausen", "Remscheid","Rendsburg-Eckernförde", "Rhein-Neuss", "Rhein-Sieg-Kreis", "Rotenburg (Wümme)", "Salzgitter",           
        "Schaumburg", "Schleswig-Flensburg","Segeberg", "Stade", "Steinburg", "Steinfurt", "Städteregion Aachen",  
        "Uelzen", "Viersen", "Warendorf", "Wilhelmshaven", "Wittmund", "Wolfsburg", "Wuppertal",
        "Ahrweiler",   "Altenkirchen",  "Alzey-Worms",  "Bad Dürkheim" , "Bad Kreuznach" , "Baden-Baden",
        "Bernkastel-Wittlich", "Birkenfeld",  "Böblingen", "Cochem-Zell", "Darmstadt-Dieburg", "Donnersbergkreis", "Dortmund",  "Eifelkreis Bitburg-Prüm",  "Ennepe-Ruhr-Kreis", "Esslingen",  
        "Frankenthal (Pfalz)",  "Frankfurt am Main", "Fulda",  "Gießen", "Groß-Gerau", "Heidenheim",  "Heilbronn", 
        "Hersfeld-Rotenburg", "Hochsauerlandkreis", "Hochtaunuskreis",   "Hohenlohekreis", "Höxter", "Kaiserslautern", "Karlsruhe", "Kassel", "Koblenz",   "Lahn-Dill-Kreis", "Landau in der Pfalz",  "Landkreis Heilbronn", "Landkreis Karlsruhe",
        "Limburg-Weilburg",  "Lippe",  "Ludwigsburg" ,  "Main-Kinzig-Kreis", "Main-Tauber-Kreis", "Mainz",   "Mainz-Bingen",  "Mannheim",  "Marburg-Biedenkopf", "Mayen-Koblenz", "Minden-Lübbecke", "Märkischer Kreis",
        "Neckar-Odenwald-Kreis", "Neustadt an der Weinstraße",  "Neuwied", "Odenwaldkreis", "Offenbach", "Offenbach am Main",  "Olpe", "Ostalbkreis", "Paderborn", "Pforzheim", "Pirmasens",  "Rastatt", "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rheingau-Taunus-Kreis", "Schwalm-Eder-Kreis",
        "Schwäbisch Hall", "Siegen-Wittgenstein", "Soest" , "Speyer" ,  "Stuttgart", "Südliche Weinstraße", "Südwestpfalz", "Trier",   "Trier-Saarburg",  "Unna",  "Vogelsbergkreis", "Waldeck-Frankenberg", "Werra-Meißner-Kreis",  "Westerwaldkreis", "Wiesbaden",  "Worms", "Zweibrücken",
        "Alb-Donau-Kreis",  "Altötting", "Amberg", "Amberg-Sulzbach",  "Ansbach", "Aschaffenburg", "Bad Kissingen", "Bamberg",  "Bayreuth", "Berchtesgadener Land", "Biberach", "Bodenseekreis", "Breisgau-Hochschwarzwald", "Calw", "Cham",                               
        "Coburg", "Dachau", "Deggendorf", "Dingolfing-Landau",  "Ebersberg", "Eichstätt", "Emmendingen",  "Enzkreis", "Erding", "Erlangen",  "Erlangen-Höchstadt", "Forchheim", "Freiburg im Breisgau", "Freising", "Freudenstadt", "Freyung-Grafenau", "Fürstenfeldbruck", "Fürth", "Garmisch-Partenkirchen", "Haßberge", "Hof", "Ingolstadt", "Kelheim", "Kitzingen", "Konstanz",  "Kronach", "Landkreis Ansbach", "Landkreis Aschaffenburg", "Landkreis Bamberg",  "Landkreis Bayreuth", "Landkreis Coburg", "Landkreis Fürth", "Landkreis Hof", "Landkreis Landshut", "Landkreis München", "Landkreis Passau", "Landkreis Regensburg", "Landsberg am Lech",  "Landshut",                           
        "Lörrach", "Miesbach", "Mühldorf am Inn", "München",  "Neuburg-Schrobenhausen", "Neumarkt in der Oberpfalz", "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab",  "Nürnberg",  "Nürnberger Land",  "Ortenaukreis",  "Passau",                             
        "Ravensburg", "Regen",  "Regensburg", "Reutlingen",  "Rhön-Grabfeld", "Rosenheim", "Roth",  "Rottal-Inn", "Rottweil",
        "Schwabach", "Schwandorf",  "Schwarzwald-Baar-Kreis", "Schweinfurt",  "Sigmaringen", "Straubing", "Straubing-Bogen",  "Tirschenreuth", "Traunstein",                         
        "Tuttlingen",  "Ulm",  "Waldshut ", 
        "Weiden in der Oberpfalz", "Weilheim-Schongau",  "Weißenburg-Gunzenhausen",            
        "Wunsiedel im Fichtelgebirge", "Würzburg", "Zollernalbkreis",
        "Altenburger Land",   "Altmarkkreis Salzwedel",   "Anhalt-Bitterfeld",  "Augsburg",                        
        "Bautzen",  "Berlin",   "Börde", "Brandenburg an der Havel",        
        "Burgenlandkreis",  "Chemnitz",  "Dahme-Spreewald", "Dessau-Roßlau",                   
        "Dillingen an der Donau", "Donau-Ries",  "Dresden", "Eichsfeld",                       
        "Elbe-Elster",  "Erfurt", "Erzgebirgskreis",  "Frankfurt (Oder)",                
        "Gera",  "Görlitz", "Gotha",  "Greiz",                           
        "Günzburg",    "Halle (Saale)",  "Harz",  "Hildburghausen",                  
        "Ilm-Kreis", "Jena",  "Jerichower Land", "Kaufbeuren",                      
        "Kempten (Allgäu)",  "Landkreis Augsburg",  "Landkreis Leipzig",   "Landkreis Rostock",               
        "Landkreis Schweinfurt" , "Landkreis Würzburg" , "Leipzig",  "Ludwigslust-Parchim",             
        "Magdeburg",  "Main-Spessart",  "Märkisch-Oderland",  "Mecklenburgische Seenplatte",     
        "Meißen",   "Memmingen",     "Merzig-Wadern", "Miltenberg",                      
        "Mittelsachsen",  "Neu-Ulm", "Neunkirchen",  "Nordsachsen",                     
        "Nordwestmecklenburg",  "Oberallgäu",   "Oberhavel",   "Oberspreewald-Lausitz",           
        "Oder-Spree",   "Ostprignitz-Ruppin", "Potsdam",  "Potsdam-Mittelmark",              
        "Prignitz",  "Regionalverband Saarbrücken", "Rostock",  "Saale-Orla-Kreis",                
        "Saalekreis",  "Saalfeld-Rudolstadt" , "Saarlouis" ,  "Sächsische Schweiz-Osterzgebirge",
        "Salzlandkreis",   "Schmalkalden-Meiningen",  "Schwerin",  "Sömmerda",                        
        "Sonneberg",  "Spree-Neiße",  "Stendal",  "Suhl",                            
        "Teltow-Fläming",  "Uckermark",  "Unstrut-Hainich-Kreis",  "Vogtlandkreis",                   
        "Vorpommern-Greifswald", "Vorpommern-Rügen",  "Wartburgkreis",  "Weimar",                          
        "Weimarer Land",   "Wittenberg",  "Zwickau"
        ]
    if chosen_model == "cities_non_hierarchical":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin"]
    if chosen_model == "countieswithproblems":
        federalStates = [
            "Berlin", "Bremen", "Hamburg", "Stuttgart", "München", "Köln",              
            "Frankfurt am Main", "Düsseldorf", "Leipzig", "Essen", "Dortmund", "Dresden",          
            "Nürnberg", "Duisburg", "Helmstedt", "Holzminden", "Schaumburg", "Delmenhorst",      
            "Wilhelmshaven", "Emsland", "Leer", "Oldenburg", "Bremerhaven"
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
                        y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
                    if indicators[0] == 'R':
                        y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                    if indicators[0] == 'H':
                        y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
                else:
                    if indicators[0] == 'C':
                        y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
                    if indicators[0] == 'R':
                        y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                    if indicators[0] == 'H':
                        y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
            if year == 2023:
                if chosen_model == "cities_non_hierarchical":
                    if indicators[0] == 'C':
                        y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_C>=61)&(trace_in.constant_data.fedState_idx==i))
                    if indicators[0] == 'R':
                        y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))
                    if indicators[0] == 'H':
                        y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
                else:
                    if indicators[0] == 'C':
                        y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_C>=61)&(trace_in.constant_data.fedState_idx==i))
                    if indicators[0] == 'R':
                        y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))
                    if indicators[0] == 'H':
                        y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
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
            ax.set_ylabel("Temperature (°C)")
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
                    y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
                if indicators[0] == 'R':
                    y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                if indicators[0] == 'H':
                    y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
            if year == 2023:
                if indicators[0] == 'C':
                    y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_C>=61)&(trace_in.constant_data.fedState_idx==i))
                if indicators[0] == 'R':
                    y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))
                if indicators[0] == 'H':
                    y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
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
            ax.set_ylabel("Temperature_factor")

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
    if chosen_model == "fedStates_nat":
        federalStates = (
       "Baden-Württemberg", "Bayern", "Berlin", "Brandenburg", "Bremen",
       "Hamburg", "Hessen", "Mecklenburg-Vorpommern", "Niedersachsen",
       "Nordrhein-Westfalen", "Rheinland-Pfalz", "Saarland", "Sachsen",
       "Sachsen-Anhalt", "Schleswig-Holstein", "Thüringen")
    if chosen_model == "cities":  
        federalStates = [
        "Berlin","Bielefeld","Bonn","Braunschweig","Bremen","Chemnitz",         
        "Dortmund","Dresden","Duisburg","Düsseldorf","Erfurt","Essen",            
        "Frankfurt am Main" "Halle (Saale)","Hamburg","Hannover","Karlsruhe","Kiel",             
        "Krefeld","Köln","Leipzig","Lübeck","Magdeburg","Mönchengladbach",  
        "München","Münster","Nürnberg","Oldenburg","Potsdam","Rostock",          
        "Stuttgart","Wiesbaden","Wuppertal"]
    if chosen_model == "cities_MeckPomm":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin", "Vorpommern-Greifswald", "Ludwigslust-Parchim", "Nordwestmecklenburg", "Mecklenburgische Seenplatte", "Rostock", "Vorpommern-Rügen",
       "Nordsachsen", "Meißen", "Bautzen", "Görlitz", "Mittelsachsen", "Chemnitz", "Zwickau", "Vogtlandkreis", "Erzgebirgskreis", "Potsdam", "Frankfurt am Main"]
    if chosen_model == "firsthundred":
        federalStates = ["Aurich","Bielefeld","Bonn","Borken","Braunschweig","Bremen","Bremerhaven",          
        "Celle","Cloppenburg", "Coesfeld", "Cuxhaven", "Delmenhorst", "Diepholz", "Dithmarschen",         
        "Duisburg","Düren", "Düsseldorf", "Emden", "Emsland", "Essen","Euskirchen",           
        "Flensburg","Friesland", "Gifhorn", "Goslar", "Göttingen", "Gütersloh", "Hamburg",              
        "Hameln-Pyrmont","Hannover", "Harburg", "Heidekreis", "Heinsberg", "Helmstedt", "Herford",              
        "Herzogtum Lauenburg","Hildesheim", "Holzminden", "Kiel", "Kleve", "Krefeld", "Köln",                 
        "Landkreis Oldenburg","Landkreis Osnabrück","Leer",  "Leverkusen", "Lübeck", "Lüchow-Dannenberg", "Lüneburg",             
        "Mettmann","Mönchengladbach","Mülheim an der Ruhr", "Münster", "Neumünster", "NienburgWeser", "Nordfriesland",        
        "Oberbergischer Kreis","Oldenburg" , "Osnabrück", "Osterholz", "Ostholstein", "Pinneberg", "Plön",                 
        "Recklinghausen", "Remscheid","Rendsburg-Eckernförde", "Rhein-Neuss", "Rhein-Sieg-Kreis", "Rotenburg (Wümme)", "Salzgitter",           
        "Schaumburg", "Schleswig-Flensburg","Segeberg", "Stade", "Steinburg", "Steinfurt", "Städteregion Aachen",  
        "Uelzen", "Viersen", "Warendorf", "Wilhelmshaven", "Wittmund", "Wolfsburg", "Wuppertal"]
    if chosen_model == "secondhundred":
        federalStates = ["Ahrweiler",   "Altenkirchen",  "Alzey-Worms",  "Bad Dürkheim" , "Bad Kreuznach" , "Baden-Baden",
                         "Bernkastel-Wittlich", "Birkenfeld",  "Böblingen", "Cochem-Zell", "Darmstadt-Dieburg", "Donnersbergkreis", "Dortmund",  "Eifelkreis Bitburg-Prüm",  "Ennepe-Ruhr-Kreis", "Esslingen",  
                         "Frankenthal (Pfalz)",  "Frankfurt am Main", "Fulda",  "Gießen", "Groß-Gerau", "Heidenheim",  "Heilbronn", 
                         "Hersfeld-Rotenburg", "Hochsauerlandkreis", "Hochtaunuskreis",   "Hohenlohekreis", "Höxter", "Kaiserslautern", "Karlsruhe", "Kassel", "Koblenz",   "Lahn-Dill-Kreis", "Landau in der Pfalz",  "Landkreis Heilbronn", "Landkreis Karlsruhe",
                         "Limburg-Weilburg",  "Lippe",  "Ludwigsburg" ,  "Main-Kinzig-Kreis", "Main-Tauber-Kreis", "Mainz",   "Mainz-Bingen",  "Mannheim",  "Marburg-Biedenkopf", "Mayen-Koblenz", "Minden-Lübbecke", "Märkischer Kreis",
                         "Neckar-Odenwald-Kreis", "Neustadt an der Weinstraße",  "Neuwied", "Odenwaldkreis", "Offenbach",                  "Offenbach am Main",  "Olpe", "Ostalbkreis", "Paderborn", "Pforzheim", "Pirmasens",  "Rastatt", "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rheingau-Taunus-Kreis", "Schwalm-Eder-Kreis",
                         "Schwäbisch Hall", "Siegen-Wittgenstein", "Soest" , "Speyer" ,  "Stuttgart", "Südliche Weinstraße", "Südwestpfalz",              "Trier",   "Trier-Saarburg",  "Unna",  "Vogelsbergkreis", "Waldeck-Frankenberg", "Werra-Meißner-Kreis",  "Westerwaldkreis", "Wiesbaden",  "Worms", "Zweibrücken"]
    if chosen_model == "thirdhundred":
        federalStates = ["Alb-Donau-Kreis",  "Altötting", "Amberg", "Amberg-Sulzbach",  "Ansbach",                             "Aschaffenburg", "Bad Kissingen", "Bamberg",  "Bayreuth", "Berchtesgadener Land",                "Biberach", "Bodenseekreis", "Breisgau-Hochschwarzwald", "Calw", "Cham",                               
        "Coburg", "Dachau", "Deggendorf", "Dingolfing-Landau",  "Ebersberg",                           "Eichstätt", "Emmendingen",  "Enzkreis", "Erding", "Erlangen",  "Erlangen-Höchstadt",                  "Forchheim", "Freiburg im Breisgau", "Freising", "Freudenstadt", "Freyung-Grafenau",                    "Fürstenfeldbruck", "Fürth", "Garmisch-Partenkirchen", "Haßberge", "Hof", "Ingolstadt",                          "Kelheim", "Kitzingen", "Konstanz",  "Kronach", "Landkreis Ansbach", "Landkreis Aschaffenburg", "Landkreis Bamberg",  "Landkreis Bayreuth", "Landkreis Coburg",                    "Landkreis Fürth", "Landkreis Hof", "Landkreis Landshut", "Landkreis München",                   "Landkreis Passau", "Landkreis Regensburg", "Landsberg am Lech",  "Landshut",                           
        "Lörrach", "Miesbach", "Mühldorf am Inn", "München",  "Neuburg-Schrobenhausen",              "Neumarkt in der Oberpfalz", "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab",  "Nürnberg",  "Nürnberger Land",  "Ortenaukreis",  "Passau",                             
        "Ravensburg", "Regen",  "Regensburg", "Reutlingen",  "Rhön-Grabfeld",                       "Rosenheim", "Roth",  "Rottal-Inn", "Rottweil",
        "Schwabach", "Schwandorf",  "Schwarzwald-Baar-Kreis", "Schweinfurt",                         "Sigmaringen", "Straubing", "Straubing-Bogen",  "Tirschenreuth", "Traunstein",                         
        "Tuttlingen",  "Ulm",  "Waldshut ", 
        "Weiden in der Oberpfalz", "Weilheim-Schongau",  "Weißenburg-Gunzenhausen",            
        "Wunsiedel im Fichtelgebirge", "Würzburg", "Zollernalbkreis"]    
    if chosen_model == "fourthhundred":
        federalStates = ["Altenburger Land",   "Altmarkkreis Salzwedel",   "Anhalt-Bitterfeld",  "Augsburg",                        
        "Bautzen",  "Berlin",   "Börde", "Brandenburg an der Havel",        
        "Burgenlandkreis",  "Chemnitz",  "Dahme-Spreewald", "Dessau-Roßlau",                   
        "Dillingen an der Donau", "Donau-Ries",  "Dresden", "Eichsfeld",                       
        "Elbe-Elster",  "Erfurt", "Erzgebirgskreis",  "Frankfurt (Oder)",                
        "Gera",  "Görlitz", "Gotha",  "Greiz",                           
        "Günzburg",    "Halle (Saale)",  "Harz",  "Hildburghausen",                  
        "Ilm-Kreis", "Jena",  "Jerichower Land", "Kaufbeuren",                      
        "Kempten (Allgäu)",  "Landkreis Augsburg",  "Landkreis Leipzig",   "Landkreis Rostock",               
        "Landkreis Schweinfurt" , "Landkreis Würzburg" , "Leipzig",  "Ludwigslust-Parchim",             
        "Magdeburg",  "Main-Spessart",  "Märkisch-Oderland",  "Mecklenburgische Seenplatte",     
        "Meißen",   "Memmingen",     "Merzig-Wadern", "Miltenberg",                      
        "Mittelsachsen",  "Neu-Ulm", "Neunkirchen",  "Nordsachsen",                     
        "Nordwestmecklenburg",  "Oberallgäu",   "Oberhavel",   "Oberspreewald-Lausitz",           
        "Oder-Spree",   "Ostprignitz-Ruppin", "Potsdam",  "Potsdam-Mittelmark",              
        "Prignitz",  "Regionalverband Saarbrücken", "Rostock",  "Saale-Orla-Kreis",                
        "Saalekreis",  "Saalfeld-Rudolstadt" , "Saarlouis" ,  "Sächsische Schweiz-Osterzgebirge",
        "Salzlandkreis",   "Schmalkalden-Meiningen",  "Schwerin",  "Sömmerda",                        
        "Sonneberg",  "Spree-Neiße",  "Stendal",  "Suhl",                            
        "Teltow-Fläming",  "Uckermark",  "Unstrut-Hainich-Kreis",  "Vogtlandkreis",                   
        "Vorpommern-Greifswald", "Vorpommern-Rügen",  "Wartburgkreis",  "Weimar",                          
        "Weimarer Land",   "Wittenberg",  "Zwickau"]
    if chosen_model == "firstsecondhundred":
        federalStates = ["Aurich","Bielefeld","Bonn","Borken","Braunschweig","Bremen","Bremerhaven",          
        "Celle","Cloppenburg", "Coesfeld", "Cuxhaven", "Delmenhorst", "Diepholz", "Dithmarschen",         
        "Duisburg","Düren", "Düsseldorf", "Emden", "Emsland", "Essen","Euskirchen",           
        "Flensburg","Friesland", "Gifhorn", "Goslar", "Göttingen", "Gütersloh", "Hamburg",              
        "Hameln-Pyrmont","Hannover", "Harburg", "Heidekreis", "Heinsberg", "Helmstedt", "Herford",              
        "Herzogtum Lauenburg","Hildesheim", "Holzminden", "Kiel", "Kleve", "Krefeld", "Köln",                 
        "Landkreis Oldenburg","Landkreis Osnabrück","Leer",  "Leverkusen", "Lübeck", "Lüchow-Dannenberg", "Lüneburg",             
        "Mettmann","Mönchengladbach","Mülheim an der Ruhr", "Münster", "Neumünster", "NienburgWeser", "Nordfriesland",        
        "Oberbergischer Kreis","Oldenburg" , "Osnabrück", "Osterholz", "Ostholstein", "Pinneberg", "Plön",                 
        "Recklinghausen", "Remscheid","Rendsburg-Eckernförde", "Rhein-Neuss", "Rhein-Sieg-Kreis", "Rotenburg (Wümme)", "Salzgitter",           
        "Schaumburg", "Schleswig-Flensburg","Segeberg", "Stade", "Steinburg", "Steinfurt", "Städteregion Aachen",  
        "Uelzen", "Viersen", "Warendorf", "Wilhelmshaven", "Wittmund", "Wolfsburg", "Wuppertal",
        "Ahrweiler",   "Altenkirchen",  "Alzey-Worms",  "Bad Dürkheim" , "Bad Kreuznach" , "Baden-Baden",
        "Bernkastel-Wittlich", "Birkenfeld",  "Böblingen", "Cochem-Zell", "Darmstadt-Dieburg", "Donnersbergkreis", "Dortmund",  "Eifelkreis Bitburg-Prüm",  "Ennepe-Ruhr-Kreis", "Esslingen",  
        "Frankenthal (Pfalz)",  "Frankfurt am Main", "Fulda",  "Gießen", "Groß-Gerau", "Heidenheim",  "Heilbronn", 
        "Hersfeld-Rotenburg", "Hochsauerlandkreis", "Hochtaunuskreis",   "Hohenlohekreis", "Höxter", "Kaiserslautern", "Karlsruhe", "Kassel", "Koblenz",   "Lahn-Dill-Kreis", "Landau in der Pfalz",  "Landkreis Heilbronn", "Landkreis Karlsruhe",
        "Limburg-Weilburg",  "Lippe",  "Ludwigsburg" ,  "Main-Kinzig-Kreis", "Main-Tauber-Kreis", "Mainz",   "Mainz-Bingen",  "Mannheim",  "Marburg-Biedenkopf", "Mayen-Koblenz", "Minden-Lübbecke", "Märkischer Kreis",
        "Neckar-Odenwald-Kreis", "Neustadt an der Weinstraße",  "Neuwied", "Odenwaldkreis", "Offenbach", "Offenbach am Main",  "Olpe", "Ostalbkreis", "Paderborn", "Pforzheim", "Pirmasens",  "Rastatt", "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rheingau-Taunus-Kreis", "Schwalm-Eder-Kreis",
        "Schwäbisch Hall", "Siegen-Wittgenstein", "Soest" , "Speyer" ,  "Stuttgart", "Südliche Weinstraße", "Südwestpfalz", "Trier",   "Trier-Saarburg",  "Unna",  "Vogelsbergkreis", "Waldeck-Frankenberg", "Werra-Meißner-Kreis",  "Westerwaldkreis", "Wiesbaden",  "Worms", "Zweibrücken"
        ]
    if chosen_model == "thirdfourthhundred":
        federalStates = ["Alb-Donau-Kreis",  "Altötting", "Amberg", "Amberg-Sulzbach",  "Ansbach", "Aschaffenburg", "Bad Kissingen", "Bamberg",  "Bayreuth", "Berchtesgadener Land", "Biberach", "Bodenseekreis", "Breisgau-Hochschwarzwald", "Calw", "Cham",                               
        "Coburg", "Dachau", "Deggendorf", "Dingolfing-Landau",  "Ebersberg", "Eichstätt", "Emmendingen",  "Enzkreis", "Erding", "Erlangen",  "Erlangen-Höchstadt", "Forchheim", "Freiburg im Breisgau", "Freising", "Freudenstadt", "Freyung-Grafenau", "Fürstenfeldbruck", "Fürth", "Garmisch-Partenkirchen", "Haßberge", "Hof", "Ingolstadt", "Kelheim", "Kitzingen", "Konstanz",  "Kronach", "Landkreis Ansbach", "Landkreis Aschaffenburg", "Landkreis Bamberg",  "Landkreis Bayreuth", "Landkreis Coburg", "Landkreis Fürth", "Landkreis Hof", "Landkreis Landshut", "Landkreis München", "Landkreis Passau", "Landkreis Regensburg", "Landsberg am Lech",  "Landshut",                           
        "Lörrach", "Miesbach", "Mühldorf am Inn", "München",  "Neuburg-Schrobenhausen", "Neumarkt in der Oberpfalz", "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab",  "Nürnberg",  "Nürnberger Land",  "Ortenaukreis",  "Passau",                             
        "Ravensburg", "Regen",  "Regensburg", "Reutlingen",  "Rhön-Grabfeld", "Rosenheim", "Roth",  "Rottal-Inn", "Rottweil",
        "Schwabach", "Schwandorf",  "Schwarzwald-Baar-Kreis", "Schweinfurt",  "Sigmaringen", "Straubing", "Straubing-Bogen",  "Tirschenreuth", "Traunstein",                         
        "Tuttlingen",  "Ulm",  "Waldshut ", 
        "Weiden in der Oberpfalz", "Weilheim-Schongau",  "Weißenburg-Gunzenhausen",            
        "Wunsiedel im Fichtelgebirge", "Würzburg", "Zollernalbkreis",
        "Altenburger Land",   "Altmarkkreis Salzwedel",   "Anhalt-Bitterfeld",  "Augsburg",                        
        "Bautzen",  "Berlin",   "Börde", "Brandenburg an der Havel",        
        "Burgenlandkreis",  "Chemnitz",  "Dahme-Spreewald", "Dessau-Roßlau",                   
        "Dillingen an der Donau", "Donau-Ries",  "Dresden", "Eichsfeld",                       
        "Elbe-Elster",  "Erfurt", "Erzgebirgskreis",  "Frankfurt (Oder)",                
        "Gera",  "Görlitz", "Gotha",  "Greiz",                           
        "Günzburg",    "Halle (Saale)",  "Harz",  "Hildburghausen",                  
        "Ilm-Kreis", "Jena",  "Jerichower Land", "Kaufbeuren",                      
        "Kempten (Allgäu)",  "Landkreis Augsburg",  "Landkreis Leipzig",   "Landkreis Rostock",               
        "Landkreis Schweinfurt" , "Landkreis Würzburg" , "Leipzig",  "Ludwigslust-Parchim",             
        "Magdeburg",  "Main-Spessart",  "Märkisch-Oderland",  "Mecklenburgische Seenplatte",     
        "Meißen",   "Memmingen",     "Merzig-Wadern", "Miltenberg",                      
        "Mittelsachsen",  "Neu-Ulm", "Neunkirchen",  "Nordsachsen",                     
        "Nordwestmecklenburg",  "Oberallgäu",   "Oberhavel",   "Oberspreewald-Lausitz",           
        "Oder-Spree",   "Ostprignitz-Ruppin", "Potsdam",  "Potsdam-Mittelmark",              
        "Prignitz",  "Regionalverband Saarbrücken", "Rostock",  "Saale-Orla-Kreis",                
        "Saalekreis",  "Saalfeld-Rudolstadt" , "Saarlouis" ,  "Sächsische Schweiz-Osterzgebirge",
        "Salzlandkreis",   "Schmalkalden-Meiningen",  "Schwerin",  "Sömmerda",                        
        "Sonneberg",  "Spree-Neiße",  "Stendal",  "Suhl",                            
        "Teltow-Fläming",  "Uckermark",  "Unstrut-Hainich-Kreis",  "Vogtlandkreis",                   
        "Vorpommern-Greifswald", "Vorpommern-Rügen",  "Wartburgkreis",  "Weimar",                          
        "Weimarer Land",   "Wittenberg",  "Zwickau"] 
    if chosen_model == "fourhundred":
        federalStates = ["Aurich","Bielefeld","Bonn","Borken","Braunschweig","Bremen","Bremerhaven",          
        "Celle","Cloppenburg", "Coesfeld", "Cuxhaven", "Delmenhorst", "Diepholz", "Dithmarschen",         
        "Duisburg","Düren", "Düsseldorf", "Emden", "Emsland", "Essen","Euskirchen",           
        "Flensburg","Friesland", "Gifhorn", "Goslar", "Göttingen", "Gütersloh", "Hamburg",              
        "Hameln-Pyrmont","Hannover", "Harburg", "Heidekreis", "Heinsberg", "Helmstedt", "Herford",              
        "Herzogtum Lauenburg","Hildesheim", "Holzminden", "Kiel", "Kleve", "Krefeld", "Köln",                 
        "Landkreis Oldenburg","Landkreis Osnabrück","Leer",  "Leverkusen", "Lübeck", "Lüchow-Dannenberg", "Lüneburg",             
        "Mettmann","Mönchengladbach","Mülheim an der Ruhr", "Münster", "Neumünster", "NienburgWeser", "Nordfriesland",        
        "Oberbergischer Kreis","Oldenburg" , "Osnabrück", "Osterholz", "Ostholstein", "Pinneberg", "Plön",                 
        "Recklinghausen", "Remscheid","Rendsburg-Eckernförde", "Rhein-Neuss", "Rhein-Sieg-Kreis", "Rotenburg (Wümme)", "Salzgitter",           
        "Schaumburg", "Schleswig-Flensburg","Segeberg", "Stade", "Steinburg", "Steinfurt", "Städteregion Aachen",  
        "Uelzen", "Viersen", "Warendorf", "Wilhelmshaven", "Wittmund", "Wolfsburg", "Wuppertal",
        "Ahrweiler",   "Altenkirchen",  "Alzey-Worms",  "Bad Dürkheim" , "Bad Kreuznach" , "Baden-Baden",
        "Bernkastel-Wittlich", "Birkenfeld",  "Böblingen", "Cochem-Zell", "Darmstadt-Dieburg", "Donnersbergkreis", "Dortmund",  "Eifelkreis Bitburg-Prüm",  "Ennepe-Ruhr-Kreis", "Esslingen",  
        "Frankenthal (Pfalz)",  "Frankfurt am Main", "Fulda",  "Gießen", "Groß-Gerau", "Heidenheim",  "Heilbronn", 
        "Hersfeld-Rotenburg", "Hochsauerlandkreis", "Hochtaunuskreis",   "Hohenlohekreis", "Höxter", "Kaiserslautern", "Karlsruhe", "Kassel", "Koblenz",   "Lahn-Dill-Kreis", "Landau in der Pfalz",  "Landkreis Heilbronn", "Landkreis Karlsruhe",
        "Limburg-Weilburg",  "Lippe",  "Ludwigsburg" ,  "Main-Kinzig-Kreis", "Main-Tauber-Kreis", "Mainz",   "Mainz-Bingen",  "Mannheim",  "Marburg-Biedenkopf", "Mayen-Koblenz", "Minden-Lübbecke", "Märkischer Kreis",
        "Neckar-Odenwald-Kreis", "Neustadt an der Weinstraße",  "Neuwied", "Odenwaldkreis", "Offenbach", "Offenbach am Main",  "Olpe", "Ostalbkreis", "Paderborn", "Pforzheim", "Pirmasens",  "Rastatt", "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rheingau-Taunus-Kreis", "Schwalm-Eder-Kreis",
        "Schwäbisch Hall", "Siegen-Wittgenstein", "Soest" , "Speyer" ,  "Stuttgart", "Südliche Weinstraße", "Südwestpfalz", "Trier",   "Trier-Saarburg",  "Unna",  "Vogelsbergkreis", "Waldeck-Frankenberg", "Werra-Meißner-Kreis",  "Westerwaldkreis", "Wiesbaden",  "Worms", "Zweibrücken",
        "Alb-Donau-Kreis",  "Altötting", "Amberg", "Amberg-Sulzbach",  "Ansbach", "Aschaffenburg", "Bad Kissingen", "Bamberg",  "Bayreuth", "Berchtesgadener Land", "Biberach", "Bodenseekreis", "Breisgau-Hochschwarzwald", "Calw", "Cham",                               
        "Coburg", "Dachau", "Deggendorf", "Dingolfing-Landau",  "Ebersberg", "Eichstätt", "Emmendingen",  "Enzkreis", "Erding", "Erlangen",  "Erlangen-Höchstadt", "Forchheim", "Freiburg im Breisgau", "Freising", "Freudenstadt", "Freyung-Grafenau", "Fürstenfeldbruck", "Fürth", "Garmisch-Partenkirchen", "Haßberge", "Hof", "Ingolstadt", "Kelheim", "Kitzingen", "Konstanz",  "Kronach", "Landkreis Ansbach", "Landkreis Aschaffenburg", "Landkreis Bamberg",  "Landkreis Bayreuth", "Landkreis Coburg", "Landkreis Fürth", "Landkreis Hof", "Landkreis Landshut", "Landkreis München", "Landkreis Passau", "Landkreis Regensburg", "Landsberg am Lech",  "Landshut",                           
        "Lörrach", "Miesbach", "Mühldorf am Inn", "München",  "Neuburg-Schrobenhausen", "Neumarkt in der Oberpfalz", "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab",  "Nürnberg",  "Nürnberger Land",  "Ortenaukreis",  "Passau",                             
        "Ravensburg", "Regen",  "Regensburg", "Reutlingen",  "Rhön-Grabfeld", "Rosenheim", "Roth",  "Rottal-Inn", "Rottweil",
        "Schwabach", "Schwandorf",  "Schwarzwald-Baar-Kreis", "Schweinfurt",  "Sigmaringen", "Straubing", "Straubing-Bogen",  "Tirschenreuth", "Traunstein",                         
        "Tuttlingen",  "Ulm",  "Waldshut ", 
        "Weiden in der Oberpfalz", "Weilheim-Schongau",  "Weißenburg-Gunzenhausen",            
        "Wunsiedel im Fichtelgebirge", "Würzburg", "Zollernalbkreis",
        "Altenburger Land",   "Altmarkkreis Salzwedel",   "Anhalt-Bitterfeld",  "Augsburg",                        
        "Bautzen",  "Berlin",   "Börde", "Brandenburg an der Havel",        
        "Burgenlandkreis",  "Chemnitz",  "Dahme-Spreewald", "Dessau-Roßlau",                   
        "Dillingen an der Donau", "Donau-Ries",  "Dresden", "Eichsfeld",                       
        "Elbe-Elster",  "Erfurt", "Erzgebirgskreis",  "Frankfurt (Oder)",                
        "Gera",  "Görlitz", "Gotha",  "Greiz",                           
        "Günzburg",    "Halle (Saale)",  "Harz",  "Hildburghausen",                  
        "Ilm-Kreis", "Jena",  "Jerichower Land", "Kaufbeuren",                      
        "Kempten (Allgäu)",  "Landkreis Augsburg",  "Landkreis Leipzig",   "Landkreis Rostock",               
        "Landkreis Schweinfurt" , "Landkreis Würzburg" , "Leipzig",  "Ludwigslust-Parchim",             
        "Magdeburg",  "Main-Spessart",  "Märkisch-Oderland",  "Mecklenburgische Seenplatte",     
        "Meißen",   "Memmingen",     "Merzig-Wadern", "Miltenberg",                      
        "Mittelsachsen",  "Neu-Ulm", "Neunkirchen",  "Nordsachsen",                     
        "Nordwestmecklenburg",  "Oberallgäu",   "Oberhavel",   "Oberspreewald-Lausitz",           
        "Oder-Spree",   "Ostprignitz-Ruppin", "Potsdam",  "Potsdam-Mittelmark",              
        "Prignitz",  "Regionalverband Saarbrücken", "Rostock",  "Saale-Orla-Kreis",                
        "Saalekreis",  "Saalfeld-Rudolstadt" , "Saarlouis" ,  "Sächsische Schweiz-Osterzgebirge",
        "Salzlandkreis",   "Schmalkalden-Meiningen",  "Schwerin",  "Sömmerda",                        
        "Sonneberg",  "Spree-Neiße",  "Stendal",  "Suhl",                            
        "Teltow-Fläming",  "Uckermark",  "Unstrut-Hainich-Kreis",  "Vogtlandkreis",                   
        "Vorpommern-Greifswald", "Vorpommern-Rügen",  "Wartburgkreis",  "Weimar",                          
        "Weimarer Land",   "Wittenberg",  "Zwickau"
        ]
    if chosen_model == "large":
        federalStates = ["Ahrweiler", "Alb-Donau-Kreis", "Altmarkkreis Salzwedel",             
        "Altötting", "Alzey-Worms", "Amberg",
        "Amberg-Sulzbach", "Anhalt-Bitterfeld" , "Aurich",                             
        "Bad Dürkheim", "Bad Kissingen", "Bad Kreuznach",                      
        "Baden-Baden",  "Bautzen",  "Berchtesgadener Land",               
        "Berlin", "Bernkastel-Wittlich", "Bielefeld",                          
        "Birkenfeld", "Böblingen","Bodenseekreis",                      
        "Bonn", "Borken", "Braunschweig",                       
        "Breisgau-Hochschwarzwald", "Bremen",  "Bremerhaven",                        
        "Burgenlandkreis", "Calw", "Celle",                              
        "Chemnitz", "Cloppenburg", "Cochem-Zell",                        
        "Coesfeld", "Cuxhaven",  "Dachau",                             
        "Darmstadt-Dieburg", "Deggendorf", "Delmenhorst",                        
        "Dessau-Roßlau", "Diepholz", "Dillingen an der Donau",             
        "Dingolfing-Landau", "Dithmarschen", "Donau-Ries",                         
        "Donnersbergkreis", "Dortmund","Dresden",                           
        "Duisburg",  "Düren", "Düsseldorf",                         
        "Ebersberg", "Eichstätt", "Eifelkreis Bitburg-Prüm",            
        "Elbe-Elster", "Emden", "Emmendingen",                        
        "Emsland", "Ennepe-Ruhr-Kreis", "Enzkreis",                           
        "Erding", "Erfurt", "Erlangen",                           
        "Erlangen-Höchstadt", "Erzgebirgskreis", "Essen",                              
        "Esslingen", "Euskirchen", "Flensburg",                          
        "Forchheim", "Frankfurt am Main", "Freiburg im Breisgau",               
        "Freising", "Freudenstadt", "Freyung-Grafenau",                   
        "Friesland", "Fulda", "Fürstenfeldbruck",                   
        "Garmisch-Partenkirchen",  "Gießen", "Gifhorn",                            
        "Görlitz", "Goslar", "Göttingen",                          
        "Günzburg", "Gütersloh", "Halle (Saale)",                      
        "Hamburg", "Hannover", "Harz",                               
        "Haßberge", "Heidekreis", "Heidenheim",                         
        "Heinsberg", "Helmstedt", "Herford",                            
        "Hersfeld-Rotenburg", "Herzogtum Lauenburg", "Hildesheim",                         
        "Hochsauerlandkreis", "Hohenlohekreis", "Holzminden",                         
        "Höxter", "Ingolstadt", "Karlsruhe",                          
        "Kaufbeuren", "Kempten (Allgäu)", "Kiel",                               
        "Kitzingen", "Kleve", "Köln",                               
        "Konstanz",  "Krefeld", "Kronach",                            
        "Lahn-Dill-Kreis", "Landsberg am Lech", "Leer",                               
        "Leipzig", "Leverkusen","Limburg-Weilburg",                   
        "Lippe", "Lörrach","Lübeck",                             
        "Ludwigsburg", "Ludwigslust-Parchim", "Lüneburg",                           
        "Magdeburg", "Main-Kinzig-Kreis", "Main-Spessart",                      
        "Mainz-Bingen", "Mannheim", "Marburg-Biedenkopf",                 
        "Märkisch-Oderland",  "Märkischer Kreis", "Mecklenburgische Seenplatte",        
        "Meißen", "Memmingen", "Merzig-Wadern",                      
        "Mettmann", "Miesbach", "Miltenberg",                         
        "Minden-Lübbecke", "Mittelsachsen", "Mönchengladbach",                    
        "Mühldorf am Inn", "Mülheim an der Ruhr", "München",                            
        "Münster", "Neckar-Odenwald-Kreis", "Neuburg-Schrobenhausen",             
        "Neumarkt in der Oberpfalz", "Neumünster", "Neunkirchen",                        
        "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab", "Neuwied",                            
        "Nordfriesland", "Nordsachsen", "Nordwestmecklenburg",
        "Nürnberg", "Oberallgäu", "Oberbergischer Kreis",               
        "Oberspreewald-Lausitz", "Odenwaldkreis", "Offenbach",                         
        "Offenbach am Main", "Oldenburg", "Olpe",                               
        "Ortenaukreis", "Osnabrück", "Ostalbkreis",                        
        "Osterholz", "Ostholstein", "Ostprignitz-Ruppin",                 
        "Paderborn", "Pforzheim", "Pinneberg",                          
        "Plön", "Potsdam", "Potsdam-Mittelmark",                 
        "Prignitz",  "Rastatt", "Ravensburg",                         
        "Recklinghausen", "Regen",  "Regionalverband Saarbrücken",        
        "Remscheid", "Rendsburg-Eckernförde", "Reutlingen",                         
        "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rhein-Neuss",                        
        "Rhein-Sieg-Kreis",  "Rostock", "Rotenburg (Wümme)",                  
        "Roth", "Rottal-Inn", "Rottweil",                           
        "Saalekreis", "Saarlouis",   "Salzgitter",                         
        "Salzlandkreis",  "Schaumburg", "Schleswig-Flensburg",                
        "Schwalm-Eder-Kreis", "Schwandorf", "Schwarzwald-Baar-Kreis",             
        "Schwerin", "Siegen-Wittgenstein","Sigmaringen",                        
        "Soest", "Spree-Neiße", "Stade",                              
        "Städteregion Aachen", "Steinburg", "Steinfurt",                          
        "Stendal", "Straubing", "Straubing-Bogen",                    
        "Stuttgart", "Südliche Weinstraße", "Südwestpfalz",                       
        "Teltow-Fläming", "Tirschenreuth", "Traunstein",                         
        "Trier-Saarburg", "Tuttlingen",  "Uckermark",                          
        "Uelzen", "Ulm", "Unna",                               
        "Viersen", "Vogelsbergkreis","Vogtlandkreis",                      
        "Vorpommern-Greifswald", "Vorpommern-Rügen", "Waldeck-Frankenberg",                
        "Waldshut", "Warendorf", "Weiden in der Oberpfalz",            
        "Weilheim-Schongau","Weißenburg-Gunzenhausen","Wiesbaden" ,                         
        "Wilhelmshaven", "Wittenberg", "Wittmund",                           
        "Wolfsburg", "Wunsiedel im Fichtelgebirge", "Wuppertal",                          
        "Zollernalbkreis", "Zwickau"  
        ]
    if chosen_model == "cities_non_hierarchical":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin"]
    if chosen_model == "countieswithproblems":
        federalStates = [
            "Berlin", "Bremen", "Hamburg", "Stuttgart", "München", "Köln",              
            "Frankfurt am Main", "Düsseldorf", "Leipzig", "Essen", "Dortmund", "Dresden",          
            "Nürnberg", "Duisburg", "Helmstedt", "Holzminden", "Schaumburg", "Delmenhorst",      
            "Wilhelmshaven", "Emsland", "Leer", "Oldenburg", "Bremerhaven"
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
                    y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
                if indicators[0] == 'R':
                    y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                if indicators[0] == 'H':
                    y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
            if year == 2023:
                if indicators[0] == 'C':
                    y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_C>=61)&(trace_in.constant_data.fedState_idx==i))
                if indicators[0] == 'R':
                    y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))                   
                if indicators[0] == 'H':
                    y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
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
                    y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
                if indicators[0] == 'R':
                    y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                if indicators[0] == 'H':
                    y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
            if year == 2023:
                if indicators[0] == 'C':
                    y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_C>=61)&(trace_in.constant_data.fedState_idx==i))
                if indicators[0] == 'R':
                    y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))                    
                if indicators[0] == 'H':
                    y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
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
        federalStates = [  
        "Baden-Württemberg", "Bayern", "Berlin", "Brandenburg", "Bremen",
       "Hamburg", "Hessen", "Mecklenburg-Vorpommern", "Niedersachsen",
       "Nordrhein-Westfalen", "Rheinland-Pfalz", "Saarland", "Sachsen",
       "Sachsen-Anhalt", "Schleswig-Holstein", "Thüringen"]
    if chosen_model == "fedStates_nat":
        federalStates = [
       "Baden-Württemberg", "Bayern", "Berlin", "Brandenburg", "Bremen",
       "Hamburg", "Hessen", "Mecklenburg-Vorpommern", "Niedersachsen",
       "Nordrhein-Westfalen", "Rheinland-Pfalz", "Saarland", "Sachsen",
       "Sachsen-Anhalt", "Schleswig-Holstein", "Thüringen"]
    if chosen_model == "cities":  
        federalStates = [
        "Berlin","Bielefeld","Bonn","Braunschweig","Bremen","Chemnitz",         
        "Dortmund","Dresden","Duisburg","Düsseldorf","Erfurt","Essen",            
        "Frankfurt am Main" "Halle (Saale)","Hamburg","Hannover","Karlsruhe","Kiel",             
        "Krefeld","Köln","Leipzig","Lübeck","Magdeburg","Mönchengladbach",  
        "München","Münster","Nürnberg","Oldenburg","Potsdam","Rostock",          
        "Stuttgart","Wiesbaden","Wuppertal"]
    if chosen_model == "cities_MeckPomm":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin", "Vorpommern-Greifswald", "Ludwigslust-Parchim", "Nordwestmecklenburg", "Mecklenburgische Seenplatte", "Rostock", "Vorpommern-Rügen",
       "Nordsachsen", "Meißen", "Bautzen", "Görlitz", "Mittelsachsen", "Chemnitz", "Zwickau", "Vogtlandkreis", "Erzgebirgskreis", "Potsdam", "Frankfurt am Main"]
    if chosen_model == "firsthundred":
        federalStates = ["Aurich","Bielefeld","Bonn","Borken","Braunschweig","Bremen","Bremerhaven",          
        "Celle","Cloppenburg", "Coesfeld", "Cuxhaven", "Delmenhorst", "Diepholz", "Dithmarschen",         
        "Duisburg","Düren", "Düsseldorf", "Emden", "Emsland", "Essen","Euskirchen",           
        "Flensburg","Friesland", "Gifhorn", "Goslar", "Göttingen", "Gütersloh", "Hamburg",              
        "Hameln-Pyrmont","Hannover", "Harburg", "Heidekreis", "Heinsberg", "Helmstedt", "Herford",              
        "Herzogtum Lauenburg","Hildesheim", "Holzminden", "Kiel", "Kleve", "Krefeld", "Köln",                 
        "Landkreis Oldenburg","Landkreis Osnabrück","Leer",  "Leverkusen", "Lübeck", "Lüchow-Dannenberg", "Lüneburg",             
        "Mettmann","Mönchengladbach","Mülheim an der Ruhr", "Münster", "Neumünster", "NienburgWeser", "Nordfriesland",        
        "Oberbergischer Kreis","Oldenburg" , "Osnabrück", "Osterholz", "Ostholstein", "Pinneberg", "Plön",                 
        "Recklinghausen", "Remscheid","Rendsburg-Eckernförde", "Rhein-Neuss", "Rhein-Sieg-Kreis", "Rotenburg (Wümme)", "Salzgitter",           
        "Schaumburg", "Schleswig-Flensburg","Segeberg", "Stade", "Steinburg", "Steinfurt", "Städteregion Aachen",  
        "Uelzen", "Viersen", "Warendorf", "Wilhelmshaven", "Wittmund", "Wolfsburg", "Wuppertal"]
    if chosen_model == "secondhundred":
        federalStates = ["Ahrweiler",   "Altenkirchen",  "Alzey-Worms",  "Bad Dürkheim" , "Bad Kreuznach" , "Baden-Baden",
                         "Bernkastel-Wittlich", "Birkenfeld",  "Böblingen", "Cochem-Zell", "Darmstadt-Dieburg", "Donnersbergkreis", "Dortmund",  "Eifelkreis Bitburg-Prüm",  "Ennepe-Ruhr-Kreis", "Esslingen",  
                         "Frankenthal (Pfalz)",  "Frankfurt am Main", "Fulda",  "Gießen", "Groß-Gerau", "Heidenheim",  "Heilbronn", 
                         "Hersfeld-Rotenburg", "Hochsauerlandkreis", "Hochtaunuskreis",   "Hohenlohekreis", "Höxter", "Kaiserslautern", "Karlsruhe", "Kassel", "Koblenz",   "Lahn-Dill-Kreis", "Landau in der Pfalz",  "Landkreis Heilbronn", "Landkreis Karlsruhe",
                         "Limburg-Weilburg",  "Lippe",  "Ludwigsburg" ,  "Main-Kinzig-Kreis", "Main-Tauber-Kreis", "Mainz",   "Mainz-Bingen",  "Mannheim",  "Marburg-Biedenkopf", "Mayen-Koblenz", "Minden-Lübbecke", "Märkischer Kreis",
                         "Neckar-Odenwald-Kreis", "Neustadt an der Weinstraße",  "Neuwied", "Odenwaldkreis", "Offenbach",                  "Offenbach am Main",  "Olpe", "Ostalbkreis", "Paderborn", "Pforzheim", "Pirmasens",  "Rastatt", "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rheingau-Taunus-Kreis", "Schwalm-Eder-Kreis",
                         "Schwäbisch Hall", "Siegen-Wittgenstein", "Soest" , "Speyer" ,  "Stuttgart", "Südliche Weinstraße", "Südwestpfalz",              "Trier",   "Trier-Saarburg",  "Unna",  "Vogelsbergkreis", "Waldeck-Frankenberg", "Werra-Meißner-Kreis",  "Westerwaldkreis", "Wiesbaden",  "Worms", "Zweibrücken"]
    if chosen_model == "thirdhundred":
        federalStates = ["Alb-Donau-Kreis",  "Altötting", "Amberg", "Amberg-Sulzbach",  "Ansbach",                             "Aschaffenburg", "Bad Kissingen", "Bamberg",  "Bayreuth", "Berchtesgadener Land",                "Biberach", "Bodenseekreis", "Breisgau-Hochschwarzwald", "Calw", "Cham",                               
        "Coburg", "Dachau", "Deggendorf", "Dingolfing-Landau",  "Ebersberg",                           "Eichstätt", "Emmendingen",  "Enzkreis", "Erding", "Erlangen",  "Erlangen-Höchstadt",                  "Forchheim", "Freiburg im Breisgau", "Freising", "Freudenstadt", "Freyung-Grafenau",                    "Fürstenfeldbruck", "Fürth", "Garmisch-Partenkirchen", "Haßberge", "Hof", "Ingolstadt",                          "Kelheim", "Kitzingen", "Konstanz",  "Kronach", "Landkreis Ansbach", "Landkreis Aschaffenburg", "Landkreis Bamberg",  "Landkreis Bayreuth", "Landkreis Coburg",                    "Landkreis Fürth", "Landkreis Hof", "Landkreis Landshut", "Landkreis München",                   "Landkreis Passau", "Landkreis Regensburg", "Landsberg am Lech",  "Landshut",                           
        "Lörrach", "Miesbach", "Mühldorf am Inn", "München",  "Neuburg-Schrobenhausen",              "Neumarkt in der Oberpfalz", "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab",  "Nürnberg",  "Nürnberger Land",  "Ortenaukreis",  "Passau",                             
        "Ravensburg", "Regen",  "Regensburg", "Reutlingen",  "Rhön-Grabfeld",                       "Rosenheim", "Roth",  "Rottal-Inn", "Rottweil",
        "Schwabach", "Schwandorf",  "Schwarzwald-Baar-Kreis", "Schweinfurt",                         "Sigmaringen", "Straubing", "Straubing-Bogen",  "Tirschenreuth", "Traunstein",                         
        "Tuttlingen",  "Ulm",  "Waldshut ", 
        "Weiden in der Oberpfalz", "Weilheim-Schongau",  "Weißenburg-Gunzenhausen",            
        "Wunsiedel im Fichtelgebirge", "Würzburg", "Zollernalbkreis"]    
    if chosen_model == "fourthhundred":
        federalStates = ["Altenburger Land",   "Altmarkkreis Salzwedel",   "Anhalt-Bitterfeld",  "Augsburg",                        
        "Bautzen",  "Berlin",   "Börde", "Brandenburg an der Havel",        
        "Burgenlandkreis",  "Chemnitz",  "Dahme-Spreewald", "Dessau-Roßlau",                   
        "Dillingen an der Donau", "Donau-Ries",  "Dresden", "Eichsfeld",                       
        "Elbe-Elster",  "Erfurt", "Erzgebirgskreis",  "Frankfurt (Oder)",                
        "Gera",  "Görlitz", "Gotha",  "Greiz",                           
        "Günzburg",    "Halle (Saale)",  "Harz",  "Hildburghausen",                  
        "Ilm-Kreis", "Jena",  "Jerichower Land", "Kaufbeuren",                      
        "Kempten (Allgäu)",  "Landkreis Augsburg",  "Landkreis Leipzig",   "Landkreis Rostock",               
        "Landkreis Schweinfurt" , "Landkreis Würzburg" , "Leipzig",  "Ludwigslust-Parchim",             
        "Magdeburg",  "Main-Spessart",  "Märkisch-Oderland",  "Mecklenburgische Seenplatte",     
        "Meißen",   "Memmingen",     "Merzig-Wadern", "Miltenberg",                      
        "Mittelsachsen",  "Neu-Ulm", "Neunkirchen",  "Nordsachsen",                     
        "Nordwestmecklenburg",  "Oberallgäu",   "Oberhavel",   "Oberspreewald-Lausitz",           
        "Oder-Spree",   "Ostprignitz-Ruppin", "Potsdam",  "Potsdam-Mittelmark",              
        "Prignitz",  "Regionalverband Saarbrücken", "Rostock",  "Saale-Orla-Kreis",                
        "Saalekreis",  "Saalfeld-Rudolstadt" , "Saarlouis" ,  "Sächsische Schweiz-Osterzgebirge",
        "Salzlandkreis",   "Schmalkalden-Meiningen",  "Schwerin",  "Sömmerda",                        
        "Sonneberg",  "Spree-Neiße",  "Stendal",  "Suhl",                            
        "Teltow-Fläming",  "Uckermark",  "Unstrut-Hainich-Kreis",  "Vogtlandkreis",                   
        "Vorpommern-Greifswald", "Vorpommern-Rügen",  "Wartburgkreis",  "Weimar",                          
        "Weimarer Land",   "Wittenberg",  "Zwickau"]
    if chosen_model == "firstsecondhundred":
        federalStates = ["Aurich","Bielefeld","Bonn","Borken","Braunschweig","Bremen","Bremerhaven",          
        "Celle","Cloppenburg", "Coesfeld", "Cuxhaven", "Delmenhorst", "Diepholz", "Dithmarschen",         
        "Duisburg","Düren", "Düsseldorf", "Emden", "Emsland", "Essen","Euskirchen",           
        "Flensburg","Friesland", "Gifhorn", "Goslar", "Göttingen", "Gütersloh", "Hamburg",              
        "Hameln-Pyrmont","Hannover", "Harburg", "Heidekreis", "Heinsberg", "Helmstedt", "Herford",              
        "Herzogtum Lauenburg","Hildesheim", "Holzminden", "Kiel", "Kleve", "Krefeld", "Köln",                 
        "Landkreis Oldenburg","Landkreis Osnabrück","Leer",  "Leverkusen", "Lübeck", "Lüchow-Dannenberg", "Lüneburg",             
        "Mettmann","Mönchengladbach","Mülheim an der Ruhr", "Münster", "Neumünster", "NienburgWeser", "Nordfriesland",        
        "Oberbergischer Kreis","Oldenburg" , "Osnabrück", "Osterholz", "Ostholstein", "Pinneberg", "Plön",                 
        "Recklinghausen", "Remscheid","Rendsburg-Eckernförde", "Rhein-Neuss", "Rhein-Sieg-Kreis", "Rotenburg (Wümme)", "Salzgitter",           
        "Schaumburg", "Schleswig-Flensburg","Segeberg", "Stade", "Steinburg", "Steinfurt", "Städteregion Aachen",  
        "Uelzen", "Viersen", "Warendorf", "Wilhelmshaven", "Wittmund", "Wolfsburg", "Wuppertal",
        "Ahrweiler",   "Altenkirchen",  "Alzey-Worms",  "Bad Dürkheim" , "Bad Kreuznach" , "Baden-Baden",
        "Bernkastel-Wittlich", "Birkenfeld",  "Böblingen", "Cochem-Zell", "Darmstadt-Dieburg", "Donnersbergkreis", "Dortmund",  "Eifelkreis Bitburg-Prüm",  "Ennepe-Ruhr-Kreis", "Esslingen",  
        "Frankenthal (Pfalz)",  "Frankfurt am Main", "Fulda",  "Gießen", "Groß-Gerau", "Heidenheim",  "Heilbronn", 
        "Hersfeld-Rotenburg", "Hochsauerlandkreis", "Hochtaunuskreis",   "Hohenlohekreis", "Höxter", "Kaiserslautern", "Karlsruhe", "Kassel", "Koblenz",   "Lahn-Dill-Kreis", "Landau in der Pfalz",  "Landkreis Heilbronn", "Landkreis Karlsruhe",
        "Limburg-Weilburg",  "Lippe",  "Ludwigsburg" ,  "Main-Kinzig-Kreis", "Main-Tauber-Kreis", "Mainz",   "Mainz-Bingen",  "Mannheim",  "Marburg-Biedenkopf", "Mayen-Koblenz", "Minden-Lübbecke", "Märkischer Kreis",
        "Neckar-Odenwald-Kreis", "Neustadt an der Weinstraße",  "Neuwied", "Odenwaldkreis", "Offenbach", "Offenbach am Main",  "Olpe", "Ostalbkreis", "Paderborn", "Pforzheim", "Pirmasens",  "Rastatt", "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rheingau-Taunus-Kreis", "Schwalm-Eder-Kreis",
        "Schwäbisch Hall", "Siegen-Wittgenstein", "Soest" , "Speyer" ,  "Stuttgart", "Südliche Weinstraße", "Südwestpfalz", "Trier",   "Trier-Saarburg",  "Unna",  "Vogelsbergkreis", "Waldeck-Frankenberg", "Werra-Meißner-Kreis",  "Westerwaldkreis", "Wiesbaden",  "Worms", "Zweibrücken"
        ]
    if chosen_model == "thirdfourthhundred":
        federalStates = ["Alb-Donau-Kreis",  "Altötting", "Amberg", "Amberg-Sulzbach",  "Ansbach", "Aschaffenburg", "Bad Kissingen", "Bamberg",  "Bayreuth", "Berchtesgadener Land", "Biberach", "Bodenseekreis", "Breisgau-Hochschwarzwald", "Calw", "Cham",                               
        "Coburg", "Dachau", "Deggendorf", "Dingolfing-Landau",  "Ebersberg", "Eichstätt", "Emmendingen",  "Enzkreis", "Erding", "Erlangen",  "Erlangen-Höchstadt", "Forchheim", "Freiburg im Breisgau", "Freising", "Freudenstadt", "Freyung-Grafenau", "Fürstenfeldbruck", "Fürth", "Garmisch-Partenkirchen", "Haßberge", "Hof", "Ingolstadt", "Kelheim", "Kitzingen", "Konstanz",  "Kronach", "Landkreis Ansbach", "Landkreis Aschaffenburg", "Landkreis Bamberg",  "Landkreis Bayreuth", "Landkreis Coburg", "Landkreis Fürth", "Landkreis Hof", "Landkreis Landshut", "Landkreis München", "Landkreis Passau", "Landkreis Regensburg", "Landsberg am Lech",  "Landshut",                           
        "Lörrach", "Miesbach", "Mühldorf am Inn", "München",  "Neuburg-Schrobenhausen", "Neumarkt in der Oberpfalz", "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab",  "Nürnberg",  "Nürnberger Land",  "Ortenaukreis",  "Passau",                             
        "Ravensburg", "Regen",  "Regensburg", "Reutlingen",  "Rhön-Grabfeld", "Rosenheim", "Roth",  "Rottal-Inn", "Rottweil",
        "Schwabach", "Schwandorf",  "Schwarzwald-Baar-Kreis", "Schweinfurt",  "Sigmaringen", "Straubing", "Straubing-Bogen",  "Tirschenreuth", "Traunstein",                         
        "Tuttlingen",  "Ulm",  "Waldshut ", 
        "Weiden in der Oberpfalz", "Weilheim-Schongau",  "Weißenburg-Gunzenhausen",            
        "Wunsiedel im Fichtelgebirge", "Würzburg", "Zollernalbkreis",
        "Altenburger Land",   "Altmarkkreis Salzwedel",   "Anhalt-Bitterfeld",  "Augsburg",                        
        "Bautzen",  "Berlin",   "Börde", "Brandenburg an der Havel",        
        "Burgenlandkreis",  "Chemnitz",  "Dahme-Spreewald", "Dessau-Roßlau",                   
        "Dillingen an der Donau", "Donau-Ries",  "Dresden", "Eichsfeld",                       
        "Elbe-Elster",  "Erfurt", "Erzgebirgskreis",  "Frankfurt (Oder)",                
        "Gera",  "Görlitz", "Gotha",  "Greiz",                           
        "Günzburg",    "Halle (Saale)",  "Harz",  "Hildburghausen",                  
        "Ilm-Kreis", "Jena",  "Jerichower Land", "Kaufbeuren",                      
        "Kempten (Allgäu)",  "Landkreis Augsburg",  "Landkreis Leipzig",   "Landkreis Rostock",               
        "Landkreis Schweinfurt" , "Landkreis Würzburg" , "Leipzig",  "Ludwigslust-Parchim",             
        "Magdeburg",  "Main-Spessart",  "Märkisch-Oderland",  "Mecklenburgische Seenplatte",     
        "Meißen",   "Memmingen",     "Merzig-Wadern", "Miltenberg",                      
        "Mittelsachsen",  "Neu-Ulm", "Neunkirchen",  "Nordsachsen",                     
        "Nordwestmecklenburg",  "Oberallgäu",   "Oberhavel",   "Oberspreewald-Lausitz",           
        "Oder-Spree",   "Ostprignitz-Ruppin", "Potsdam",  "Potsdam-Mittelmark",              
        "Prignitz",  "Regionalverband Saarbrücken", "Rostock",  "Saale-Orla-Kreis",                
        "Saalekreis",  "Saalfeld-Rudolstadt" , "Saarlouis" ,  "Sächsische Schweiz-Osterzgebirge",
        "Salzlandkreis",   "Schmalkalden-Meiningen",  "Schwerin",  "Sömmerda",                        
        "Sonneberg",  "Spree-Neiße",  "Stendal",  "Suhl",                            
        "Teltow-Fläming",  "Uckermark",  "Unstrut-Hainich-Kreis",  "Vogtlandkreis",                   
        "Vorpommern-Greifswald", "Vorpommern-Rügen",  "Wartburgkreis",  "Weimar",                          
        "Weimarer Land",   "Wittenberg",  "Zwickau"] 
    if chosen_model == "fourhundred":
        federalStates = ["Aurich","Bielefeld","Bonn","Borken","Braunschweig","Bremen","Bremerhaven",          
        "Celle","Cloppenburg", "Coesfeld", "Cuxhaven", "Delmenhorst", "Diepholz", "Dithmarschen",         
        "Duisburg","Düren", "Düsseldorf", "Emden", "Emsland", "Essen","Euskirchen",           
        "Flensburg","Friesland", "Gifhorn", "Goslar", "Göttingen", "Gütersloh", "Hamburg",              
        "Hameln-Pyrmont","Hannover", "Harburg", "Heidekreis", "Heinsberg", "Helmstedt", "Herford",              
        "Herzogtum Lauenburg","Hildesheim", "Holzminden", "Kiel", "Kleve", "Krefeld", "Köln",                 
        "Landkreis Oldenburg","Landkreis Osnabrück","Leer",  "Leverkusen", "Lübeck", "Lüchow-Dannenberg", "Lüneburg",             
        "Mettmann","Mönchengladbach","Mülheim an der Ruhr", "Münster", "Neumünster", "NienburgWeser", "Nordfriesland",        
        "Oberbergischer Kreis","Oldenburg" , "Osnabrück", "Osterholz", "Ostholstein", "Pinneberg", "Plön",                 
        "Recklinghausen", "Remscheid","Rendsburg-Eckernförde", "Rhein-Neuss", "Rhein-Sieg-Kreis", "Rotenburg (Wümme)", "Salzgitter",           
        "Schaumburg", "Schleswig-Flensburg","Segeberg", "Stade", "Steinburg", "Steinfurt", "Städteregion Aachen",  
        "Uelzen", "Viersen", "Warendorf", "Wilhelmshaven", "Wittmund", "Wolfsburg", "Wuppertal",
        "Ahrweiler",   "Altenkirchen",  "Alzey-Worms",  "Bad Dürkheim" , "Bad Kreuznach" , "Baden-Baden",
        "Bernkastel-Wittlich", "Birkenfeld",  "Böblingen", "Cochem-Zell", "Darmstadt-Dieburg", "Donnersbergkreis", "Dortmund",  "Eifelkreis Bitburg-Prüm",  "Ennepe-Ruhr-Kreis", "Esslingen",  
        "Frankenthal (Pfalz)",  "Frankfurt am Main", "Fulda",  "Gießen", "Groß-Gerau", "Heidenheim",  "Heilbronn", 
        "Hersfeld-Rotenburg", "Hochsauerlandkreis", "Hochtaunuskreis",   "Hohenlohekreis", "Höxter", "Kaiserslautern", "Karlsruhe", "Kassel", "Koblenz",   "Lahn-Dill-Kreis", "Landau in der Pfalz",  "Landkreis Heilbronn", "Landkreis Karlsruhe",
        "Limburg-Weilburg",  "Lippe",  "Ludwigsburg" ,  "Main-Kinzig-Kreis", "Main-Tauber-Kreis", "Mainz",   "Mainz-Bingen",  "Mannheim",  "Marburg-Biedenkopf", "Mayen-Koblenz", "Minden-Lübbecke", "Märkischer Kreis",
        "Neckar-Odenwald-Kreis", "Neustadt an der Weinstraße",  "Neuwied", "Odenwaldkreis", "Offenbach", "Offenbach am Main",  "Olpe", "Ostalbkreis", "Paderborn", "Pforzheim", "Pirmasens",  "Rastatt", "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rheingau-Taunus-Kreis", "Schwalm-Eder-Kreis",
        "Schwäbisch Hall", "Siegen-Wittgenstein", "Soest" , "Speyer" ,  "Stuttgart", "Südliche Weinstraße", "Südwestpfalz", "Trier",   "Trier-Saarburg",  "Unna",  "Vogelsbergkreis", "Waldeck-Frankenberg", "Werra-Meißner-Kreis",  "Westerwaldkreis", "Wiesbaden",  "Worms", "Zweibrücken",
        "Alb-Donau-Kreis",  "Altötting", "Amberg", "Amberg-Sulzbach",  "Ansbach", "Aschaffenburg", "Bad Kissingen", "Bamberg",  "Bayreuth", "Berchtesgadener Land", "Biberach", "Bodenseekreis", "Breisgau-Hochschwarzwald", "Calw", "Cham",                               
        "Coburg", "Dachau", "Deggendorf", "Dingolfing-Landau",  "Ebersberg", "Eichstätt", "Emmendingen",  "Enzkreis", "Erding", "Erlangen",  "Erlangen-Höchstadt", "Forchheim", "Freiburg im Breisgau", "Freising", "Freudenstadt", "Freyung-Grafenau", "Fürstenfeldbruck", "Fürth", "Garmisch-Partenkirchen", "Haßberge", "Hof", "Ingolstadt", "Kelheim", "Kitzingen", "Konstanz",  "Kronach", "Landkreis Ansbach", "Landkreis Aschaffenburg", "Landkreis Bamberg",  "Landkreis Bayreuth", "Landkreis Coburg", "Landkreis Fürth", "Landkreis Hof", "Landkreis Landshut", "Landkreis München", "Landkreis Passau", "Landkreis Regensburg", "Landsberg am Lech",  "Landshut",                           
        "Lörrach", "Miesbach", "Mühldorf am Inn", "München",  "Neuburg-Schrobenhausen", "Neumarkt in der Oberpfalz", "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab",  "Nürnberg",  "Nürnberger Land",  "Ortenaukreis",  "Passau",                             
        "Ravensburg", "Regen",  "Regensburg", "Reutlingen",  "Rhön-Grabfeld", "Rosenheim", "Roth",  "Rottal-Inn", "Rottweil",
        "Schwabach", "Schwandorf",  "Schwarzwald-Baar-Kreis", "Schweinfurt",  "Sigmaringen", "Straubing", "Straubing-Bogen",  "Tirschenreuth", "Traunstein",                         
        "Tuttlingen",  "Ulm",  "Waldshut ", 
        "Weiden in der Oberpfalz", "Weilheim-Schongau",  "Weißenburg-Gunzenhausen",            
        "Wunsiedel im Fichtelgebirge", "Würzburg", "Zollernalbkreis",
        "Altenburger Land",   "Altmarkkreis Salzwedel",   "Anhalt-Bitterfeld",  "Augsburg",                        
        "Bautzen",  "Berlin",   "Börde", "Brandenburg an der Havel",        
        "Burgenlandkreis",  "Chemnitz",  "Dahme-Spreewald", "Dessau-Roßlau",                   
        "Dillingen an der Donau", "Donau-Ries",  "Dresden", "Eichsfeld",                       
        "Elbe-Elster",  "Erfurt", "Erzgebirgskreis",  "Frankfurt (Oder)",                
        "Gera",  "Görlitz", "Gotha",  "Greiz",                           
        "Günzburg",    "Halle (Saale)",  "Harz",  "Hildburghausen",                  
        "Ilm-Kreis", "Jena",  "Jerichower Land", "Kaufbeuren",                      
        "Kempten (Allgäu)",  "Landkreis Augsburg",  "Landkreis Leipzig",   "Landkreis Rostock",               
        "Landkreis Schweinfurt" , "Landkreis Würzburg" , "Leipzig",  "Ludwigslust-Parchim",             
        "Magdeburg",  "Main-Spessart",  "Märkisch-Oderland",  "Mecklenburgische Seenplatte",     
        "Meißen",   "Memmingen",     "Merzig-Wadern", "Miltenberg",                      
        "Mittelsachsen",  "Neu-Ulm", "Neunkirchen",  "Nordsachsen",                     
        "Nordwestmecklenburg",  "Oberallgäu",   "Oberhavel",   "Oberspreewald-Lausitz",           
        "Oder-Spree",   "Ostprignitz-Ruppin", "Potsdam",  "Potsdam-Mittelmark",              
        "Prignitz",  "Regionalverband Saarbrücken", "Rostock",  "Saale-Orla-Kreis",                
        "Saalekreis",  "Saalfeld-Rudolstadt" , "Saarlouis" ,  "Sächsische Schweiz-Osterzgebirge",
        "Salzlandkreis",   "Schmalkalden-Meiningen",  "Schwerin",  "Sömmerda",                        
        "Sonneberg",  "Spree-Neiße",  "Stendal",  "Suhl",                            
        "Teltow-Fläming",  "Uckermark",  "Unstrut-Hainich-Kreis",  "Vogtlandkreis",                   
        "Vorpommern-Greifswald", "Vorpommern-Rügen",  "Wartburgkreis",  "Weimar",                          
        "Weimarer Land",   "Wittenberg",  "Zwickau"
        ]
    if chosen_model == "large":
        federalStates = ["Ahrweiler", "Alb-Donau-Kreis", "Altmarkkreis Salzwedel",             
        "Altötting", "Alzey-Worms", "Amberg",
        "Amberg-Sulzbach", "Anhalt-Bitterfeld" , "Aurich",                             
        "Bad Dürkheim", "Bad Kissingen", "Bad Kreuznach",                      
        "Baden-Baden",  "Bautzen",  "Berchtesgadener Land",               
        "Berlin", "Bernkastel-Wittlich", "Bielefeld",                          
        "Birkenfeld", "Böblingen","Bodenseekreis",                      
        "Bonn", "Borken", "Braunschweig",                       
        "Breisgau-Hochschwarzwald", "Bremen",  "Bremerhaven",                        
        "Burgenlandkreis", "Calw", "Celle",                              
        "Chemnitz", "Cloppenburg", "Cochem-Zell",                        
        "Coesfeld", "Cuxhaven",  "Dachau",                             
        "Darmstadt-Dieburg", "Deggendorf", "Delmenhorst",                        
        "Dessau-Roßlau", "Diepholz", "Dillingen an der Donau",             
        "Dingolfing-Landau", "Dithmarschen", "Donau-Ries",                         
        "Donnersbergkreis", "Dortmund","Dresden",                           
        "Duisburg",  "Düren", "Düsseldorf",                         
        "Ebersberg", "Eichstätt", "Eifelkreis Bitburg-Prüm",            
        "Elbe-Elster", "Emden", "Emmendingen",                        
        "Emsland", "Ennepe-Ruhr-Kreis", "Enzkreis",                           
        "Erding", "Erfurt", "Erlangen",                           
        "Erlangen-Höchstadt", "Erzgebirgskreis", "Essen",                              
        "Esslingen", "Euskirchen", "Flensburg",                          
        "Forchheim", "Frankfurt am Main", "Freiburg im Breisgau",               
        "Freising", "Freudenstadt", "Freyung-Grafenau",                   
        "Friesland", "Fulda", "Fürstenfeldbruck",                   
        "Garmisch-Partenkirchen",  "Gießen", "Gifhorn",                            
        "Görlitz", "Goslar", "Göttingen",                          
        "Günzburg", "Gütersloh", "Halle (Saale)",                      
        "Hamburg", "Hannover", "Harz",                               
        "Haßberge", "Heidekreis", "Heidenheim",                         
        "Heinsberg", "Helmstedt", "Herford",                            
        "Hersfeld-Rotenburg", "Herzogtum Lauenburg", "Hildesheim",                         
        "Hochsauerlandkreis", "Hohenlohekreis", "Holzminden",                         
        "Höxter", "Ingolstadt", "Karlsruhe",                          
        "Kaufbeuren", "Kempten (Allgäu)", "Kiel",                               
        "Kitzingen", "Kleve", "Köln",                               
        "Konstanz",  "Krefeld", "Kronach",                            
        "Lahn-Dill-Kreis", "Landsberg am Lech", "Leer",                               
        "Leipzig", "Leverkusen","Limburg-Weilburg",                   
        "Lippe", "Lörrach","Lübeck",                             
        "Ludwigsburg", "Ludwigslust-Parchim", "Lüneburg",                           
        "Magdeburg", "Main-Kinzig-Kreis", "Main-Spessart",                      
        "Mainz-Bingen", "Mannheim", "Marburg-Biedenkopf",                 
        "Märkisch-Oderland",  "Märkischer Kreis", "Mecklenburgische Seenplatte",        
        "Meißen", "Memmingen", "Merzig-Wadern",                      
        "Mettmann", "Miesbach", "Miltenberg",                         
        "Minden-Lübbecke", "Mittelsachsen", "Mönchengladbach",                    
        "Mühldorf am Inn", "Mülheim an der Ruhr", "München",                            
        "Münster", "Neckar-Odenwald-Kreis", "Neuburg-Schrobenhausen",             
        "Neumarkt in der Oberpfalz", "Neumünster", "Neunkirchen",                        
        "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab", "Neuwied",                            
        "Nordfriesland", "Nordsachsen", "Nordwestmecklenburg",
        "Nürnberg", "Oberallgäu", "Oberbergischer Kreis",               
        "Oberspreewald-Lausitz", "Odenwaldkreis", "Offenbach",                         
        "Offenbach am Main", "Oldenburg", "Olpe",                               
        "Ortenaukreis", "Osnabrück", "Ostalbkreis",                        
        "Osterholz", "Ostholstein", "Ostprignitz-Ruppin",                 
        "Paderborn", "Pforzheim", "Pinneberg",                          
        "Plön", "Potsdam", "Potsdam-Mittelmark",                 
        "Prignitz",  "Rastatt", "Ravensburg",                         
        "Recklinghausen", "Regen",  "Regionalverband Saarbrücken",        
        "Remscheid", "Rendsburg-Eckernförde", "Reutlingen",                         
        "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rhein-Neuss",                        
        "Rhein-Sieg-Kreis",  "Rostock", "Rotenburg (Wümme)",                  
        "Roth", "Rottal-Inn", "Rottweil",                           
        "Saalekreis", "Saarlouis",   "Salzgitter",                         
        "Salzlandkreis",  "Schaumburg", "Schleswig-Flensburg",                
        "Schwalm-Eder-Kreis", "Schwandorf", "Schwarzwald-Baar-Kreis",             
        "Schwerin", "Siegen-Wittgenstein","Sigmaringen",                        
        "Soest", "Spree-Neiße", "Stade",                              
        "Städteregion Aachen", "Steinburg", "Steinfurt",                          
        "Stendal", "Straubing", "Straubing-Bogen",                    
        "Stuttgart", "Südliche Weinstraße", "Südwestpfalz",                       
        "Teltow-Fläming", "Tirschenreuth", "Traunstein",                         
        "Trier-Saarburg", "Tuttlingen",  "Uckermark",                          
        "Uelzen", "Ulm", "Unna",                               
        "Viersen", "Vogelsbergkreis","Vogtlandkreis",                      
        "Vorpommern-Greifswald", "Vorpommern-Rügen", "Waldeck-Frankenberg",                
        "Waldshut", "Warendorf", "Weiden in der Oberpfalz",            
        "Weilheim-Schongau","Weißenburg-Gunzenhausen","Wiesbaden" ,                         
        "Wilhelmshaven", "Wittenberg", "Wittmund",                           
        "Wolfsburg", "Wunsiedel im Fichtelgebirge", "Wuppertal",                          
        "Zollernalbkreis", "Zwickau"  
        ]
    if chosen_model == "cities_non_hierarchical":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin"]
    if chosen_model == "countieswithproblems":
        federalStates = [
            "Berlin", "Bremen", "Hamburg", "Stuttgart", "München", "Köln",              
            "Frankfurt am Main", "Düsseldorf", "Leipzig", "Essen", "Dortmund", "Dresden",          
            "Nürnberg", "Duisburg", "Helmstedt", "Holzminden", "Schaumburg", "Delmenhorst",      
            "Wilhelmshaven", "Emsland", "Leer", "Oldenburg", "Bremerhaven"
        ]
          
    labels = {
            "C": "new cases $d_C$",
            "Cnat": "Cases",
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
    
    dates_filtered = dates_in[dates_in < np.datetime64("2021-03-01")]
    dates_filtered2 = dates_filtered[dates_filtered > np.datetime64("2020-03-01")]
    
    for indicator in indicators_in:
        for i, c in enumerate(federalStates):
            fig, axs = plt.subplots(2, 1, figsize=(9, 9), sharex=True)
            axs = axs.ravel()
            # # First plot
            ax = axs[0]
            y_first = trace_in.constant_data.C.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
            y = y_first.dropna(dim="obs_id", how = "all")
            dates = np.unique(dates_filtered2)
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

def plot_timeseriesPaper(
    chosen_model,
    dates_in,
    trace_in,
    tag_in,
    indicators_in,
    incl2024,
    plus_nat_incidence,
    school_in=None,
    holiday_in=None,
    temperature_in=None,
    precipitation_in=None,
    daylight_in=None,
    pop_density_in=None,
    log=False,
):
    if chosen_model == "BEHHHB":
        federalStates = ("Berlin", "Bremen", "Hamburg")
    if chosen_model == "fedStates":
        federalStates = (
       "Baden-Württemberg", "Bayern", "Berlin", "Brandenburg", "Bremen",
       "Hamburg", "Hessen", "Mecklenburg-Vorpommern", "Niedersachsen",
       "Nordrhein-Westfalen", "Rheinland-Pfalz", "Saarland", "Sachsen",
       "Sachsen-Anhalt", "Schleswig-Holstein", "Thüringen")
    if chosen_model == "fedStates_nat":
        federalStates = [
       "Baden-Württemberg", "Bayern", "Berlin", "Brandenburg", "Bremen",
       "Hamburg", "Hessen", "Mecklenburg-Vorpommern", "Niedersachsen",
       "Nordrhein-Westfalen", "Rheinland-Pfalz", "Saarland", "Sachsen",
       "Sachsen-Anhalt", "Schleswig-Holstein", "Thüringen"]
    if chosen_model == "cities":  
        federalStates = [
        "Berlin","Bielefeld","Bonn","Braunschweig","Bremen","Chemnitz",         
        "Dortmund","Dresden","Duisburg","Düsseldorf","Erfurt","Essen",            
        "Frankfurt am Main" "Halle (Saale)","Hamburg","Hannover","Karlsruhe","Kiel",             
        "Krefeld","Köln","Leipzig","Lübeck","Magdeburg","Mönchengladbach",  
        "München","Münster","Nürnberg","Oldenburg","Potsdam","Rostock",          
        "Stuttgart","Wiesbaden","Wuppertal"]
    if chosen_model == "cities_MeckPomm":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin", "Vorpommern-Greifswald", "Ludwigslust-Parchim", "Nordwestmecklenburg", "Mecklenburgische Seenplatte", "Rostock", "Vorpommern-Rügen",
       "Nordsachsen", "Meißen", "Bautzen", "Görlitz", "Mittelsachsen", "Chemnitz", "Zwickau", "Vogtlandkreis", "Erzgebirgskreis", "Potsdam", "Frankfurt am Main"]
    if chosen_model == "firsthundred":
        federalStates = ["Aurich","Bielefeld","Bonn","Borken","Braunschweig","Bremen","Bremerhaven",          
        "Celle","Cloppenburg", "Coesfeld", "Cuxhaven", "Delmenhorst", "Diepholz", "Dithmarschen",         
        "Duisburg","Düren", "Düsseldorf", "Emden", "Emsland", "Essen","Euskirchen",           
        "Flensburg","Friesland", "Gifhorn", "Goslar", "Göttingen", "Gütersloh", "Hamburg",              
        "Hameln-Pyrmont","Hannover", "Harburg", "Heidekreis", "Heinsberg", "Helmstedt", "Herford",              
        "Herzogtum Lauenburg","Hildesheim", "Holzminden", "Kiel", "Kleve", "Krefeld", "Köln",                 
        "Landkreis Oldenburg","Landkreis Osnabrück","Leer",  "Leverkusen", "Lübeck", "Lüchow-Dannenberg", "Lüneburg",             
        "Mettmann","Mönchengladbach","Mülheim an der Ruhr", "Münster", "Neumünster", "NienburgWeser", "Nordfriesland",        
        "Oberbergischer Kreis","Oldenburg" , "Osnabrück", "Osterholz", "Ostholstein", "Pinneberg", "Plön",                 
        "Recklinghausen", "Remscheid","Rendsburg-Eckernförde", "Rhein-Neuss", "Rhein-Sieg-Kreis", "Rotenburg (Wümme)", "Salzgitter",           
        "Schaumburg", "Schleswig-Flensburg","Segeberg", "Stade", "Steinburg", "Steinfurt", "Städteregion Aachen",  
        "Uelzen", "Viersen", "Warendorf", "Wilhelmshaven", "Wittmund", "Wolfsburg", "Wuppertal"]
    if chosen_model == "secondhundred":
        federalStates = ["Ahrweiler",   "Altenkirchen",  "Alzey-Worms",  "Bad Dürkheim" , "Bad Kreuznach" , "Baden-Baden",
                         "Bernkastel-Wittlich", "Birkenfeld",  "Böblingen", "Cochem-Zell", "Darmstadt-Dieburg", "Donnersbergkreis", "Dortmund",  "Eifelkreis Bitburg-Prüm",  "Ennepe-Ruhr-Kreis", "Esslingen",  
                         "Frankenthal (Pfalz)",  "Frankfurt am Main", "Fulda",  "Gießen", "Groß-Gerau", "Heidenheim",  "Heilbronn", 
                         "Hersfeld-Rotenburg", "Hochsauerlandkreis", "Hochtaunuskreis",   "Hohenlohekreis", "Höxter", "Kaiserslautern", "Karlsruhe", "Kassel", "Koblenz",   "Lahn-Dill-Kreis", "Landau in der Pfalz",  "Landkreis Heilbronn", "Landkreis Karlsruhe",
                         "Limburg-Weilburg",  "Lippe",  "Ludwigsburg" ,  "Main-Kinzig-Kreis", "Main-Tauber-Kreis", "Mainz",   "Mainz-Bingen",  "Mannheim",  "Marburg-Biedenkopf", "Mayen-Koblenz", "Minden-Lübbecke", "Märkischer Kreis",
                         "Neckar-Odenwald-Kreis", "Neustadt an der Weinstraße",  "Neuwied", "Odenwaldkreis", "Offenbach",                  "Offenbach am Main",  "Olpe", "Ostalbkreis", "Paderborn", "Pforzheim", "Pirmasens",  "Rastatt", "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rheingau-Taunus-Kreis", "Schwalm-Eder-Kreis",
                         "Schwäbisch Hall", "Siegen-Wittgenstein", "Soest" , "Speyer" ,  "Stuttgart", "Südliche Weinstraße", "Südwestpfalz",              "Trier",   "Trier-Saarburg",  "Unna",  "Vogelsbergkreis", "Waldeck-Frankenberg", "Werra-Meißner-Kreis",  "Westerwaldkreis", "Wiesbaden",  "Worms", "Zweibrücken"]
    if chosen_model == "thirdhundred":
        federalStates = ["Alb-Donau-Kreis",  "Altötting", "Amberg", "Amberg-Sulzbach",  "Ansbach", "Aschaffenburg", "Bad Kissingen", "Bamberg",  "Bayreuth", "Berchtesgadener Land", "Biberach", "Bodenseekreis", "Breisgau-Hochschwarzwald", "Calw", "Cham",                               
        "Coburg", "Dachau", "Deggendorf", "Dingolfing-Landau",  "Ebersberg", "Eichstätt", "Emmendingen",  "Enzkreis", "Erding", "Erlangen",  "Erlangen-Höchstadt", "Forchheim", "Freiburg im Breisgau", "Freising", "Freudenstadt", "Freyung-Grafenau", "Fürstenfeldbruck", "Fürth", "Garmisch-Partenkirchen", "Haßberge", "Hof", "Ingolstadt", "Kelheim", "Kitzingen", "Konstanz",  "Kronach", "Landkreis Ansbach", "Landkreis Aschaffenburg", "Landkreis Bamberg",  "Landkreis Bayreuth", "Landkreis Coburg", "Landkreis Fürth", "Landkreis Hof", "Landkreis Landshut", "Landkreis München", "Landkreis Passau", "Landkreis Regensburg", "Landsberg am Lech",  "Landshut",                           
        "Lörrach", "Miesbach", "Mühldorf am Inn", "München",  "Neuburg-Schrobenhausen", "Neumarkt in der Oberpfalz", "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab",  "Nürnberg",  "Nürnberger Land",  "Ortenaukreis",  "Passau",                             
        "Ravensburg", "Regen",  "Regensburg", "Reutlingen",  "Rhön-Grabfeld", "Rosenheim", "Roth",  "Rottal-Inn", "Rottweil",
        "Schwabach", "Schwandorf",  "Schwarzwald-Baar-Kreis", "Schweinfurt",  "Sigmaringen", "Straubing", "Straubing-Bogen",  "Tirschenreuth", "Traunstein",                         
        "Tuttlingen",  "Ulm",  "Waldshut ", 
        "Weiden in der Oberpfalz", "Weilheim-Schongau",  "Weißenburg-Gunzenhausen",            
        "Wunsiedel im Fichtelgebirge", "Würzburg", "Zollernalbkreis"]    
    if chosen_model == "fourthhundred":
        federalStates = ["Altenburger Land",   "Altmarkkreis Salzwedel",   "Anhalt-Bitterfeld",  "Augsburg",                        
        "Bautzen",  "Berlin",   "Börde", "Brandenburg an der Havel",        
        "Burgenlandkreis",  "Chemnitz",  "Dahme-Spreewald", "Dessau-Roßlau",                   
        "Dillingen an der Donau", "Donau-Ries",  "Dresden", "Eichsfeld",                       
        "Elbe-Elster",  "Erfurt", "Erzgebirgskreis",  "Frankfurt (Oder)",                
        "Gera",  "Görlitz", "Gotha",  "Greiz",                           
        "Günzburg",    "Halle (Saale)",  "Harz",  "Hildburghausen",                  
        "Ilm-Kreis", "Jena",  "Jerichower Land", "Kaufbeuren",                      
        "Kempten (Allgäu)",  "Landkreis Augsburg",  "Landkreis Leipzig",   "Landkreis Rostock",               
        "Landkreis Schweinfurt" , "Landkreis Würzburg" , "Leipzig",  "Ludwigslust-Parchim",             
        "Magdeburg",  "Main-Spessart",  "Märkisch-Oderland",  "Mecklenburgische Seenplatte",     
        "Meißen",   "Memmingen",     "Merzig-Wadern", "Miltenberg",                      
        "Mittelsachsen",  "Neu-Ulm", "Neunkirchen",  "Nordsachsen",                     
        "Nordwestmecklenburg",  "Oberallgäu",   "Oberhavel",   "Oberspreewald-Lausitz",           
        "Oder-Spree",   "Ostprignitz-Ruppin", "Potsdam",  "Potsdam-Mittelmark",              
        "Prignitz",  "Regionalverband Saarbrücken", "Rostock",  "Saale-Orla-Kreis",                
        "Saalekreis",  "Saalfeld-Rudolstadt" , "Saarlouis" ,  "Sächsische Schweiz-Osterzgebirge",
        "Salzlandkreis",   "Schmalkalden-Meiningen",  "Schwerin",  "Sömmerda",                        
        "Sonneberg",  "Spree-Neiße",  "Stendal",  "Suhl",                            
        "Teltow-Fläming",  "Uckermark",  "Unstrut-Hainich-Kreis",  "Vogtlandkreis",                   
        "Vorpommern-Greifswald", "Vorpommern-Rügen",  "Wartburgkreis",  "Weimar",                          
        "Weimarer Land",   "Wittenberg",  "Zwickau"]
    if chosen_model == "firstsecondhundred":
        federalStates = ["Aurich","Bielefeld","Bonn","Borken","Braunschweig","Bremen","Bremerhaven",          
        "Celle","Cloppenburg", "Coesfeld", "Cuxhaven", "Delmenhorst", "Diepholz", "Dithmarschen",         
        "Duisburg","Düren", "Düsseldorf", "Emden", "Emsland", "Essen","Euskirchen",           
        "Flensburg","Friesland", "Gifhorn", "Goslar", "Göttingen", "Gütersloh", "Hamburg",              
        "Hameln-Pyrmont","Hannover", "Harburg", "Heidekreis", "Heinsberg", "Helmstedt", "Herford",              
        "Herzogtum Lauenburg","Hildesheim", "Holzminden", "Kiel", "Kleve", "Krefeld", "Köln",                 
        "Landkreis Oldenburg","Landkreis Osnabrück","Leer",  "Leverkusen", "Lübeck", "Lüchow-Dannenberg", "Lüneburg",             
        "Mettmann","Mönchengladbach","Mülheim an der Ruhr", "Münster", "Neumünster", "NienburgWeser", "Nordfriesland",        
        "Oberbergischer Kreis","Oldenburg" , "Osnabrück", "Osterholz", "Ostholstein", "Pinneberg", "Plön",                 
        "Recklinghausen", "Remscheid","Rendsburg-Eckernförde", "Rhein-Neuss", "Rhein-Sieg-Kreis", "Rotenburg (Wümme)", "Salzgitter",           
        "Schaumburg", "Schleswig-Flensburg","Segeberg", "Stade", "Steinburg", "Steinfurt", "Städteregion Aachen",  
        "Uelzen", "Viersen", "Warendorf", "Wilhelmshaven", "Wittmund", "Wolfsburg", "Wuppertal",
        "Ahrweiler",   "Altenkirchen",  "Alzey-Worms",  "Bad Dürkheim" , "Bad Kreuznach" , "Baden-Baden",
        "Bernkastel-Wittlich", "Birkenfeld",  "Böblingen", "Cochem-Zell", "Darmstadt-Dieburg", "Donnersbergkreis", "Dortmund",  "Eifelkreis Bitburg-Prüm",  "Ennepe-Ruhr-Kreis", "Esslingen",  
        "Frankenthal (Pfalz)",  "Frankfurt am Main", "Fulda",  "Gießen", "Groß-Gerau", "Heidenheim",  "Heilbronn", 
        "Hersfeld-Rotenburg", "Hochsauerlandkreis", "Hochtaunuskreis",   "Hohenlohekreis", "Höxter", "Kaiserslautern", "Karlsruhe", "Kassel", "Koblenz",   "Lahn-Dill-Kreis", "Landau in der Pfalz",  "Landkreis Heilbronn", "Landkreis Karlsruhe",
        "Limburg-Weilburg",  "Lippe",  "Ludwigsburg" ,  "Main-Kinzig-Kreis", "Main-Tauber-Kreis", "Mainz",   "Mainz-Bingen",  "Mannheim",  "Marburg-Biedenkopf", "Mayen-Koblenz", "Minden-Lübbecke", "Märkischer Kreis",
        "Neckar-Odenwald-Kreis", "Neustadt an der Weinstraße",  "Neuwied", "Odenwaldkreis", "Offenbach", "Offenbach am Main",  "Olpe", "Ostalbkreis", "Paderborn", "Pforzheim", "Pirmasens",  "Rastatt", "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rheingau-Taunus-Kreis", "Schwalm-Eder-Kreis",
        "Schwäbisch Hall", "Siegen-Wittgenstein", "Soest" , "Speyer" ,  "Stuttgart", "Südliche Weinstraße", "Südwestpfalz", "Trier",   "Trier-Saarburg",  "Unna",  "Vogelsbergkreis", "Waldeck-Frankenberg", "Werra-Meißner-Kreis",  "Westerwaldkreis", "Wiesbaden",  "Worms", "Zweibrücken"
        ]
    if chosen_model == "thirdfourthhundred":
        federalStates = ["Alb-Donau-Kreis",  "Altötting", "Amberg", "Amberg-Sulzbach",  "Ansbach", "Aschaffenburg", "Bad Kissingen", "Bamberg",  "Bayreuth", "Berchtesgadener Land", "Biberach", "Bodenseekreis", "Breisgau-Hochschwarzwald", "Calw", "Cham",                               
        "Coburg", "Dachau", "Deggendorf", "Dingolfing-Landau",  "Ebersberg", "Eichstätt", "Emmendingen",  "Enzkreis", "Erding", "Erlangen",  "Erlangen-Höchstadt", "Forchheim", "Freiburg im Breisgau", "Freising", "Freudenstadt", "Freyung-Grafenau", "Fürstenfeldbruck", "Fürth", "Garmisch-Partenkirchen", "Haßberge", "Hof", "Ingolstadt", "Kelheim", "Kitzingen", "Konstanz",  "Kronach", "Landkreis Ansbach", "Landkreis Aschaffenburg", "Landkreis Bamberg",  "Landkreis Bayreuth", "Landkreis Coburg", "Landkreis Fürth", "Landkreis Hof", "Landkreis Landshut", "Landkreis München", "Landkreis Passau", "Landkreis Regensburg", "Landsberg am Lech",  "Landshut",                           
        "Lörrach", "Miesbach", "Mühldorf am Inn", "München",  "Neuburg-Schrobenhausen", "Neumarkt in der Oberpfalz", "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab",  "Nürnberg",  "Nürnberger Land",  "Ortenaukreis",  "Passau",                             
        "Ravensburg", "Regen",  "Regensburg", "Reutlingen",  "Rhön-Grabfeld", "Rosenheim", "Roth",  "Rottal-Inn", "Rottweil",
        "Schwabach", "Schwandorf",  "Schwarzwald-Baar-Kreis", "Schweinfurt",  "Sigmaringen", "Straubing", "Straubing-Bogen",  "Tirschenreuth", "Traunstein",                         
        "Tuttlingen",  "Ulm",  "Waldshut ", 
        "Weiden in der Oberpfalz", "Weilheim-Schongau",  "Weißenburg-Gunzenhausen",            
        "Wunsiedel im Fichtelgebirge", "Würzburg", "Zollernalbkreis",
        "Altenburger Land",   "Altmarkkreis Salzwedel",   "Anhalt-Bitterfeld",  "Augsburg",                        
        "Bautzen",  "Berlin",   "Börde", "Brandenburg an der Havel",        
        "Burgenlandkreis",  "Chemnitz",  "Dahme-Spreewald", "Dessau-Roßlau",                   
        "Dillingen an der Donau", "Donau-Ries",  "Dresden", "Eichsfeld",                       
        "Elbe-Elster",  "Erfurt", "Erzgebirgskreis",  "Frankfurt (Oder)",                
        "Gera",  "Görlitz", "Gotha",  "Greiz",                           
        "Günzburg",    "Halle (Saale)",  "Harz",  "Hildburghausen",                  
        "Ilm-Kreis", "Jena",  "Jerichower Land", "Kaufbeuren",                      
        "Kempten (Allgäu)",  "Landkreis Augsburg",  "Landkreis Leipzig",   "Landkreis Rostock",               
        "Landkreis Schweinfurt" , "Landkreis Würzburg" , "Leipzig",  "Ludwigslust-Parchim",             
        "Magdeburg",  "Main-Spessart",  "Märkisch-Oderland",  "Mecklenburgische Seenplatte",     
        "Meißen",   "Memmingen",     "Merzig-Wadern", "Miltenberg",                      
        "Mittelsachsen",  "Neu-Ulm", "Neunkirchen",  "Nordsachsen",                     
        "Nordwestmecklenburg",  "Oberallgäu",   "Oberhavel",   "Oberspreewald-Lausitz",           
        "Oder-Spree",   "Ostprignitz-Ruppin", "Potsdam",  "Potsdam-Mittelmark",              
        "Prignitz",  "Regionalverband Saarbrücken", "Rostock",  "Saale-Orla-Kreis",                
        "Saalekreis",  "Saalfeld-Rudolstadt" , "Saarlouis" ,  "Sächsische Schweiz-Osterzgebirge",
        "Salzlandkreis",   "Schmalkalden-Meiningen",  "Schwerin",  "Sömmerda",                        
        "Sonneberg",  "Spree-Neiße",  "Stendal",  "Suhl",                            
        "Teltow-Fläming",  "Uckermark",  "Unstrut-Hainich-Kreis",  "Vogtlandkreis",                   
        "Vorpommern-Greifswald", "Vorpommern-Rügen",  "Wartburgkreis",  "Weimar",                          
        "Weimarer Land",   "Wittenberg",  "Zwickau"] 
    if chosen_model == "fourhundred":
        federalStates = ["Aurich","Bielefeld","Bonn","Borken","Braunschweig","Bremen","Bremerhaven",          
        "Celle","Cloppenburg", "Coesfeld", "Cuxhaven", "Delmenhorst", "Diepholz", "Dithmarschen",         
        "Duisburg","Düren", "Düsseldorf", "Emden", "Emsland", "Essen","Euskirchen",           
        "Flensburg","Friesland", "Gifhorn", "Goslar", "Göttingen", "Gütersloh", "Hamburg",              
        "Hameln-Pyrmont","Hannover", "Harburg", "Heidekreis", "Heinsberg", "Helmstedt", "Herford",              
        "Herzogtum Lauenburg","Hildesheim", "Holzminden", "Kiel", "Kleve", "Krefeld", "Köln",                 
        "Landkreis Oldenburg","Landkreis Osnabrück","Leer",  "Leverkusen", "Lübeck", "Lüchow-Dannenberg", "Lüneburg",             
        "Mettmann","Mönchengladbach","Mülheim an der Ruhr", "Münster", "Neumünster", "NienburgWeser", "Nordfriesland",        
        "Oberbergischer Kreis","Oldenburg" , "Osnabrück", "Osterholz", "Ostholstein", "Pinneberg", "Plön",                 
        "Recklinghausen", "Remscheid","Rendsburg-Eckernförde", "Rhein-Neuss", "Rhein-Sieg-Kreis", "Rotenburg (Wümme)", "Salzgitter",           
        "Schaumburg", "Schleswig-Flensburg","Segeberg", "Stade", "Steinburg", "Steinfurt", "Städteregion Aachen",  
        "Uelzen", "Viersen", "Warendorf", "Wilhelmshaven", "Wittmund", "Wolfsburg", "Wuppertal",
        "Ahrweiler",   "Altenkirchen",  "Alzey-Worms",  "Bad Dürkheim" , "Bad Kreuznach" , "Baden-Baden",
        "Bernkastel-Wittlich", "Birkenfeld",  "Böblingen", "Cochem-Zell", "Darmstadt-Dieburg", "Donnersbergkreis", "Dortmund",  "Eifelkreis Bitburg-Prüm",  "Ennepe-Ruhr-Kreis", "Esslingen",  
        "Frankenthal (Pfalz)",  "Frankfurt am Main", "Fulda",  "Gießen", "Groß-Gerau", "Heidenheim",  "Heilbronn", 
        "Hersfeld-Rotenburg", "Hochsauerlandkreis", "Hochtaunuskreis",   "Hohenlohekreis", "Höxter", "Kaiserslautern", "Karlsruhe", "Kassel", "Koblenz",   "Lahn-Dill-Kreis", "Landau in der Pfalz",  "Landkreis Heilbronn", "Landkreis Karlsruhe",
        "Limburg-Weilburg",  "Lippe",  "Ludwigsburg" ,  "Main-Kinzig-Kreis", "Main-Tauber-Kreis", "Mainz",   "Mainz-Bingen",  "Mannheim",  "Marburg-Biedenkopf", "Mayen-Koblenz", "Minden-Lübbecke", "Märkischer Kreis",
        "Neckar-Odenwald-Kreis", "Neustadt an der Weinstraße",  "Neuwied", "Odenwaldkreis", "Offenbach", "Offenbach am Main",  "Olpe", "Ostalbkreis", "Paderborn", "Pforzheim", "Pirmasens",  "Rastatt", "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rheingau-Taunus-Kreis", "Schwalm-Eder-Kreis",
        "Schwäbisch Hall", "Siegen-Wittgenstein", "Soest" , "Speyer" ,  "Stuttgart", "Südliche Weinstraße", "Südwestpfalz", "Trier",   "Trier-Saarburg",  "Unna",  "Vogelsbergkreis", "Waldeck-Frankenberg", "Werra-Meißner-Kreis",  "Westerwaldkreis", "Wiesbaden",  "Worms", "Zweibrücken",
        "Alb-Donau-Kreis",  "Altötting", "Amberg", "Amberg-Sulzbach",  "Ansbach", "Aschaffenburg", "Bad Kissingen", "Bamberg",  "Bayreuth", "Berchtesgadener Land", "Biberach", "Bodenseekreis", "Breisgau-Hochschwarzwald", "Calw", "Cham",                               
        "Coburg", "Dachau", "Deggendorf", "Dingolfing-Landau",  "Ebersberg", "Eichstätt", "Emmendingen",  "Enzkreis", "Erding", "Erlangen",  "Erlangen-Höchstadt", "Forchheim", "Freiburg im Breisgau", "Freising", "Freudenstadt", "Freyung-Grafenau", "Fürstenfeldbruck", "Fürth", "Garmisch-Partenkirchen", "Haßberge", "Hof", "Ingolstadt", "Kelheim", "Kitzingen", "Konstanz",  "Kronach", "Landkreis Ansbach", "Landkreis Aschaffenburg", "Landkreis Bamberg",  "Landkreis Bayreuth", "Landkreis Coburg", "Landkreis Fürth", "Landkreis Hof", "Landkreis Landshut", "Landkreis München", "Landkreis Passau", "Landkreis Regensburg", "Landsberg am Lech",  "Landshut",                           
        "Lörrach", "Miesbach", "Mühldorf am Inn", "München",  "Neuburg-Schrobenhausen", "Neumarkt in der Oberpfalz", "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab",  "Nürnberg",  "Nürnberger Land",  "Ortenaukreis",  "Passau",                             
        "Ravensburg", "Regen",  "Regensburg", "Reutlingen",  "Rhön-Grabfeld", "Rosenheim", "Roth",  "Rottal-Inn", "Rottweil",
        "Schwabach", "Schwandorf",  "Schwarzwald-Baar-Kreis", "Schweinfurt",  "Sigmaringen", "Straubing", "Straubing-Bogen",  "Tirschenreuth", "Traunstein",                         
        "Tuttlingen",  "Ulm",  "Waldshut ", 
        "Weiden in der Oberpfalz", "Weilheim-Schongau",  "Weißenburg-Gunzenhausen",            
        "Wunsiedel im Fichtelgebirge", "Würzburg", "Zollernalbkreis",
        "Altenburger Land",   "Altmarkkreis Salzwedel",   "Anhalt-Bitterfeld",  "Augsburg",                        
        "Bautzen",  "Berlin",   "Börde", "Brandenburg an der Havel",        
        "Burgenlandkreis",  "Chemnitz",  "Dahme-Spreewald", "Dessau-Roßlau",                   
        "Dillingen an der Donau", "Donau-Ries",  "Dresden", "Eichsfeld",                       
        "Elbe-Elster",  "Erfurt", "Erzgebirgskreis",  "Frankfurt (Oder)",                
        "Gera",  "Görlitz", "Gotha",  "Greiz",                           
        "Günzburg",    "Halle (Saale)",  "Harz",  "Hildburghausen",                  
        "Ilm-Kreis", "Jena",  "Jerichower Land", "Kaufbeuren",                      
        "Kempten (Allgäu)",  "Landkreis Augsburg",  "Landkreis Leipzig",   "Landkreis Rostock",               
        "Landkreis Schweinfurt" , "Landkreis Würzburg" , "Leipzig",  "Ludwigslust-Parchim",             
        "Magdeburg",  "Main-Spessart",  "Märkisch-Oderland",  "Mecklenburgische Seenplatte",     
        "Meißen",   "Memmingen",     "Merzig-Wadern", "Miltenberg",                      
        "Mittelsachsen",  "Neu-Ulm", "Neunkirchen",  "Nordsachsen",                     
        "Nordwestmecklenburg",  "Oberallgäu",   "Oberhavel",   "Oberspreewald-Lausitz",           
        "Oder-Spree",   "Ostprignitz-Ruppin", "Potsdam",  "Potsdam-Mittelmark",              
        "Prignitz",  "Regionalverband Saarbrücken", "Rostock",  "Saale-Orla-Kreis",                
        "Saalekreis",  "Saalfeld-Rudolstadt" , "Saarlouis" ,  "Sächsische Schweiz-Osterzgebirge",
        "Salzlandkreis",   "Schmalkalden-Meiningen",  "Schwerin",  "Sömmerda",                        
        "Sonneberg",  "Spree-Neiße",  "Stendal",  "Suhl",                            
        "Teltow-Fläming",  "Uckermark",  "Unstrut-Hainich-Kreis",  "Vogtlandkreis",                   
        "Vorpommern-Greifswald", "Vorpommern-Rügen",  "Wartburgkreis",  "Weimar",                          
        "Weimarer Land",   "Wittenberg",  "Zwickau"
        ]
    if chosen_model == "cities_non_hierarchical":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin"]
    if chosen_model == "countieswithproblems":
        federalStates = [
            "Berlin", "Bremen", "Hamburg", "Stuttgart", "München", "Köln",              
            "Frankfurt am Main", "Düsseldorf", "Leipzig", "Essen", "Dortmund", "Dresden",          
            "Nürnberg", "Duisburg", "Helmstedt", "Holzminden", "Schaumburg", "Delmenhorst",      
            "Wilhelmshaven", "Emsland", "Leer", "Oldenburg", "Bremerhaven"
        ]
                
    for i, c in enumerate(federalStates):
        # upper plot
        fig, axs = plt.subplots(1, 2, figsize=(36, 6), sharex=True)
        axs = axs.ravel()

        if incl2024 == True:
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

            # Left plot
            ax = axs[0]
            
            labels = {
                "C": "new cases $d_C$",
                "Cnat": "Cases",
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
                if year == 2020:
                    if indicator == "C":
                        y_first = trace_in.observed_data.d.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.observed_data.d.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.observed_data.d.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
                if year == 2023:
                    if indicator == "C":
                        y_first = trace_in.observed_data.d.where((trace_in.constant_data.counter_C>=61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.observed_data.d.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.observed_data.d.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
                y = y_first.dropna(dim="obs_id", how = "all")
                ax.plot(
                    dates,
                    y,
                    label="Observed out-of-home duration",
                    color=colors["d_obs"],
                    marker="o",
                    linestyle='None',
                )

                if year == 2020:
                    if indicator == "C":
                        y_first = trace_in.posterior.m.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.posterior.m.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.m.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
                if year == 2023:
                    if indicator == "C":
                        y_first = trace_in.posterior.m.where((trace_in.constant_data.counter_C>=61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.posterior.m.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.m.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
                y = y_first.dropna(dim="obs_id", how = "all")
                plot_timeseries(ax, dates, y, "Inferred out-of-home duration", colors["d"])
                ax.legend(
                     loc='lower right',
                     ncol=1,
                #     # bbox_to_anchor=(1.1, -0.4)
                )
                date_form = DateFormatter("%m/%d")
                ax.xaxis.set_major_formatter(date_form)
                # set y label
                ax.set_ylabel("Out-of-home duration (h)")
                
            ax = axs[1]

            ## plot disease indicators
            for indicator in indicators_in:
                if year == 2020:
                    if indicator == "C":
                        y_first = trace_in.posterior.d_C.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.posterior.d_R.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.d_H.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
                if year == 2023:
                    if indicator == "C":
                        y_first = trace_in.posterior.d_C.where((trace_in.constant_data.counter_C>=61)&(trace_in.constant_data.fedState_idx==1))
                    if indicator == "R":
                        y_first = trace_in.posterior.d_R.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.d_H.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
                y = y_first.dropna(dim="obs_id", how = "all")
                plot_timeseries(
                    ax,
                    dates,
                    y,
                    color_in=colors["Cnat"],
                    label_in=labels["Cnat"],
                    alpha=0.2,
                )
                
            if plus_nat_incidence == True: 
                for indicator in indicators_in:
                    if year == 2020:
                        if indicator == "C":
                            y_first = trace_in.posterior.d_C_nat.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
                        if indicator == "R":
                            y_first = trace_in.posterior.d_R_nat.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                        if indicator == "H":
                            y_first = trace_in.posterior.d_H_nat.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
                    if year == 2023:
                        if indicator == "C":
                            y_first = trace_in.posterior.d_C_nat.where((trace_in.constant_data.counter_C>=61)&(trace_in.constant_data.fedState_idx==1))
                        if indicator == "R":
                            y_first = trace_in.posterior.d_R_nat.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))
                        if indicator == "H":
                            y_first = trace_in.posterior.d_H_nat.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
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
                        y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
                if year == 2023:
                    if indicator == "C":
                        y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_C>=61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
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
                        y_first = trace_in.posterior.vacation_factor.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.posterior.vacation_factor.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.vacation_factor.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
                if year == 2023:
                    if indicator == "C":
                        y_first = trace_in.posterior.vacation_factor.where((trace_in.constant_data.counter_C>=61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.posterior.vacation_factor.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.vacation_factor.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
                y = y_first.dropna(dim="obs_id", how = "all")
                plot_timeseries(
                    ax,
                    dates,
                    y,
                    color_in=colors["v"],
                    label_in="School vacation",
                    alpha=0.2,
                )
            # public holidays
            if holiday_in is not None:
                if year == 2020:
                    #trace_filtered = trace_in.sel(fedState = i)
                    if indicator == "C":
                        y_first = trace_in.posterior.holiday_factor.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.posterior.holiday_factor.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.holiday_factor.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
                if year == 2023:
                    if indicator == "C":
                        y_first = trace_in.posterior.holiday_factor.where((trace_in.constant_data.counter_C>=61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.posterior.holiday_factor.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.holiday_factor.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
                y = y_first.dropna(dim="obs_id", how = "all")
                plot_timeseries(
                    ax,
                    dates,
                    y,
                    color_in=colors["h"],
                    label_in="Public holidays",
                    alpha=0.2,
                )
            # temperature
            if temperature_in is not None:
                if year == 2020:
                    if indicator == "C":
                        y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
                if year == 2023:
                    if indicator == "C":
                        y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_C>=61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
                y = y_first.dropna(dim="obs_id", how = "all")
                plot_timeseries(
                    ax,
                    dates,
                    y,
                    color_in=colors["T"],
                    label_in="Temperature",
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
            ax.autoscale_view(tight=True)
            ax.margins(x=0)
            ax.set_xlim(min(dates), max(dates))
            
            ## set y label
            ax.set_ylabel("Multiplicative impact on\nout-of-home duration")
            ax.legend(
             ncol=2,
             loc='lower right',
            # # bbox_to_anchor=(0.7, 2)
             )
            ax.margins(x=0)
            #format_x_axis(ax, dates, last = True)
            #ax.set_title(c)

            # save figure
            plotnamepng= f"{tag_in}/" + c + str(year) + "-timeseriesPaper.png"
            plotnamepdf = f"{tag_in}/" + c + str(year) + "-timeseriesPaper.pdf"
            fig.savefig(plotnamepng, bbox_inches="tight")
            fig.savefig(plotnamepdf, bbox_inches="tight")

def plot_all_timeseries(
    chosen_model,
    dates_in,
    trace_in,
    tag_in,
    indicators_in,
    incl2024,
    plus_nat_incidence,
    school_in=None,
    holiday_in=None,
    temperature_in=None,
    precipitation_in=None,
    daylight_in=None,
    pop_density_in=None,
    log=False,
):
    if chosen_model == "BEHHHB":
        federalStates = ("Berlin", "Bremen", "Hamburg")
    if chosen_model == "fedStates":
        federalStates = (
       "Baden-Württemberg", "Bayern", "Berlin", "Brandenburg", "Bremen",
       "Hamburg", "Hessen", "Mecklenburg-Vorpommern", "Niedersachsen",
       "Nordrhein-Westfalen", "Rheinland-Pfalz", "Saarland", "Sachsen",
       "Sachsen-Anhalt", "Schleswig-Holstein", "Thüringen")
    if chosen_model == "fedStates_nat":
        federalStates = [
       "Baden-Württemberg", "Bayern", "Berlin", "Brandenburg", "Bremen",
       "Hamburg", "Hessen", "Mecklenburg-Vorpommern", "Niedersachsen",
       "Nordrhein-Westfalen", "Rheinland-Pfalz", "Saarland", "Sachsen",
       "Sachsen-Anhalt", "Schleswig-Holstein", "Thüringen"]
    if chosen_model == "cities":  
        federalStates = [
        "Berlin","Bielefeld","Bonn","Braunschweig","Bremen","Chemnitz",         
        "Dortmund","Dresden","Duisburg","Düsseldorf","Erfurt","Essen",            
        "Frankfurt am Main" "Halle (Saale)","Hamburg","Hannover","Karlsruhe","Kiel",             
        "Krefeld","Köln","Leipzig","Lübeck","Magdeburg","Mönchengladbach",  
        "München","Münster","Nürnberg","Oldenburg","Potsdam","Rostock",          
        "Stuttgart","Wiesbaden","Wuppertal"]
    if chosen_model == "cities_MeckPomm":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin", "Vorpommern-Greifswald", "Ludwigslust-Parchim", "Nordwestmecklenburg", "Mecklenburgische Seenplatte", "Rostock", "Vorpommern-Rügen",
       "Nordsachsen", "Meißen", "Bautzen", "Görlitz", "Mittelsachsen", "Chemnitz", "Zwickau", "Vogtlandkreis", "Erzgebirgskreis", "Potsdam", "Frankfurt am Main"]
    if chosen_model == "firsthundred":
        federalStates = ["Aurich","Bielefeld","Bonn","Borken","Braunschweig","Bremen","Bremerhaven",          
        "Celle","Cloppenburg", "Coesfeld", "Cuxhaven", "Delmenhorst", "Diepholz", "Dithmarschen",         
        "Duisburg","Düren", "Düsseldorf", "Emden", "Emsland", "Essen","Euskirchen",           
        "Flensburg","Friesland", "Gifhorn", "Goslar", "Göttingen", "Gütersloh", "Hamburg",              
        "Hameln-Pyrmont","Hannover", "Harburg", "Heidekreis", "Heinsberg", "Helmstedt", "Herford",              
        "Herzogtum Lauenburg","Hildesheim", "Holzminden", "Kiel", "Kleve", "Krefeld", "Köln",                 
        "Landkreis Oldenburg","Landkreis Osnabrück","Leer",  "Leverkusen", "Lübeck", "Lüchow-Dannenberg", "Lüneburg",             
        "Mettmann","Mönchengladbach","Mülheim an der Ruhr", "Münster", "Neumünster", "NienburgWeser", "Nordfriesland",        
        "Oberbergischer Kreis","Oldenburg" , "Osnabrück", "Osterholz", "Ostholstein", "Pinneberg", "Plön",                 
        "Recklinghausen", "Remscheid","Rendsburg-Eckernförde", "Rhein-Neuss", "Rhein-Sieg-Kreis", "Rotenburg (Wümme)", "Salzgitter",           
        "Schaumburg", "Schleswig-Flensburg","Segeberg", "Stade", "Steinburg", "Steinfurt", "Städteregion Aachen",  
        "Uelzen", "Viersen", "Warendorf", "Wilhelmshaven", "Wittmund", "Wolfsburg", "Wuppertal"]
    if chosen_model == "secondhundred":
        federalStates = ["Ahrweiler",   "Altenkirchen",  "Alzey-Worms",  "Bad Dürkheim" , "Bad Kreuznach" , "Baden-Baden",
                         "Bernkastel-Wittlich", "Birkenfeld",  "Böblingen", "Cochem-Zell", "Darmstadt-Dieburg", "Donnersbergkreis", "Dortmund",  "Eifelkreis Bitburg-Prüm",  "Ennepe-Ruhr-Kreis", "Esslingen",  
                         "Frankenthal (Pfalz)",  "Frankfurt am Main", "Fulda",  "Gießen", "Groß-Gerau", "Heidenheim",  "Heilbronn", 
                         "Hersfeld-Rotenburg", "Hochsauerlandkreis", "Hochtaunuskreis",   "Hohenlohekreis", "Höxter", "Kaiserslautern", "Karlsruhe", "Kassel", "Koblenz",   "Lahn-Dill-Kreis", "Landau in der Pfalz",  "Landkreis Heilbronn", "Landkreis Karlsruhe",
                         "Limburg-Weilburg",  "Lippe",  "Ludwigsburg" ,  "Main-Kinzig-Kreis", "Main-Tauber-Kreis", "Mainz",   "Mainz-Bingen",  "Mannheim",  "Marburg-Biedenkopf", "Mayen-Koblenz", "Minden-Lübbecke", "Märkischer Kreis",
                         "Neckar-Odenwald-Kreis", "Neustadt an der Weinstraße",  "Neuwied", "Odenwaldkreis", "Offenbach",                  "Offenbach am Main",  "Olpe", "Ostalbkreis", "Paderborn", "Pforzheim", "Pirmasens",  "Rastatt", "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rheingau-Taunus-Kreis", "Schwalm-Eder-Kreis",
                         "Schwäbisch Hall", "Siegen-Wittgenstein", "Soest" , "Speyer" ,  "Stuttgart", "Südliche Weinstraße", "Südwestpfalz",              "Trier",   "Trier-Saarburg",  "Unna",  "Vogelsbergkreis", "Waldeck-Frankenberg", "Werra-Meißner-Kreis",  "Westerwaldkreis", "Wiesbaden",  "Worms", "Zweibrücken"]
    if chosen_model == "thirdhundred":
        federalStates = ["Alb-Donau-Kreis",  "Altötting", "Amberg", "Amberg-Sulzbach",  "Ansbach", "Aschaffenburg", "Bad Kissingen", "Bamberg",  "Bayreuth", "Berchtesgadener Land", "Biberach", "Bodenseekreis", "Breisgau-Hochschwarzwald", "Calw", "Cham",                               
        "Coburg", "Dachau", "Deggendorf", "Dingolfing-Landau",  "Ebersberg", "Eichstätt", "Emmendingen",  "Enzkreis", "Erding", "Erlangen",  "Erlangen-Höchstadt", "Forchheim", "Freiburg im Breisgau", "Freising", "Freudenstadt", "Freyung-Grafenau", "Fürstenfeldbruck", "Fürth", "Garmisch-Partenkirchen", "Haßberge", "Hof", "Ingolstadt", "Kelheim", "Kitzingen", "Konstanz",  "Kronach", "Landkreis Ansbach", "Landkreis Aschaffenburg", "Landkreis Bamberg",  "Landkreis Bayreuth", "Landkreis Coburg", "Landkreis Fürth", "Landkreis Hof", "Landkreis Landshut", "Landkreis München", "Landkreis Passau", "Landkreis Regensburg", "Landsberg am Lech",  "Landshut",                           
        "Lörrach", "Miesbach", "Mühldorf am Inn", "München",  "Neuburg-Schrobenhausen", "Neumarkt in der Oberpfalz", "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab",  "Nürnberg",  "Nürnberger Land",  "Ortenaukreis",  "Passau",                             
        "Ravensburg", "Regen",  "Regensburg", "Reutlingen",  "Rhön-Grabfeld", "Rosenheim", "Roth",  "Rottal-Inn", "Rottweil",
        "Schwabach", "Schwandorf",  "Schwarzwald-Baar-Kreis", "Schweinfurt",  "Sigmaringen", "Straubing", "Straubing-Bogen",  "Tirschenreuth", "Traunstein",                         
        "Tuttlingen",  "Ulm",  "Waldshut ", 
        "Weiden in der Oberpfalz", "Weilheim-Schongau",  "Weißenburg-Gunzenhausen",            
        "Wunsiedel im Fichtelgebirge", "Würzburg", "Zollernalbkreis"]    
    if chosen_model == "fourthhundred":
        federalStates = ["Altenburger Land",   "Altmarkkreis Salzwedel",   "Anhalt-Bitterfeld",  "Augsburg",                        
        "Bautzen",  "Berlin",   "Börde", "Brandenburg an der Havel",        
        "Burgenlandkreis",  "Chemnitz",  "Dahme-Spreewald", "Dessau-Roßlau",                   
        "Dillingen an der Donau", "Donau-Ries",  "Dresden", "Eichsfeld",                       
        "Elbe-Elster",  "Erfurt", "Erzgebirgskreis",  "Frankfurt (Oder)",                
        "Gera",  "Görlitz", "Gotha",  "Greiz",                           
        "Günzburg",    "Halle (Saale)",  "Harz",  "Hildburghausen",                  
        "Ilm-Kreis", "Jena",  "Jerichower Land", "Kaufbeuren",                      
        "Kempten (Allgäu)",  "Landkreis Augsburg",  "Landkreis Leipzig",   "Landkreis Rostock",               
        "Landkreis Schweinfurt" , "Landkreis Würzburg" , "Leipzig",  "Ludwigslust-Parchim",             
        "Magdeburg",  "Main-Spessart",  "Märkisch-Oderland",  "Mecklenburgische Seenplatte",     
        "Meißen",   "Memmingen",     "Merzig-Wadern", "Miltenberg",                      
        "Mittelsachsen",  "Neu-Ulm", "Neunkirchen",  "Nordsachsen",                     
        "Nordwestmecklenburg",  "Oberallgäu",   "Oberhavel",   "Oberspreewald-Lausitz",           
        "Oder-Spree",   "Ostprignitz-Ruppin", "Potsdam",  "Potsdam-Mittelmark",              
        "Prignitz",  "Regionalverband Saarbrücken", "Rostock",  "Saale-Orla-Kreis",                
        "Saalekreis",  "Saalfeld-Rudolstadt" , "Saarlouis" ,  "Sächsische Schweiz-Osterzgebirge",
        "Salzlandkreis",   "Schmalkalden-Meiningen",  "Schwerin",  "Sömmerda",                        
        "Sonneberg",  "Spree-Neiße",  "Stendal",  "Suhl",                            
        "Teltow-Fläming",  "Uckermark",  "Unstrut-Hainich-Kreis",  "Vogtlandkreis",                   
        "Vorpommern-Greifswald", "Vorpommern-Rügen",  "Wartburgkreis",  "Weimar",                          
        "Weimarer Land",   "Wittenberg",  "Zwickau"]
    if chosen_model == "firstsecondhundred":
        federalStates = ["Aurich","Bielefeld","Bonn","Borken","Braunschweig","Bremen","Bremerhaven",          
        "Celle","Cloppenburg", "Coesfeld", "Cuxhaven", "Delmenhorst", "Diepholz", "Dithmarschen",         
        "Duisburg","Düren", "Düsseldorf", "Emden", "Emsland", "Essen","Euskirchen",           
        "Flensburg","Friesland", "Gifhorn", "Goslar", "Göttingen", "Gütersloh", "Hamburg",              
        "Hameln-Pyrmont","Hannover", "Harburg", "Heidekreis", "Heinsberg", "Helmstedt", "Herford",              
        "Herzogtum Lauenburg","Hildesheim", "Holzminden", "Kiel", "Kleve", "Krefeld", "Köln",                 
        "Landkreis Oldenburg","Landkreis Osnabrück","Leer",  "Leverkusen", "Lübeck", "Lüchow-Dannenberg", "Lüneburg",             
        "Mettmann","Mönchengladbach","Mülheim an der Ruhr", "Münster", "Neumünster", "NienburgWeser", "Nordfriesland",        
        "Oberbergischer Kreis","Oldenburg" , "Osnabrück", "Osterholz", "Ostholstein", "Pinneberg", "Plön",                 
        "Recklinghausen", "Remscheid","Rendsburg-Eckernförde", "Rhein-Neuss", "Rhein-Sieg-Kreis", "Rotenburg (Wümme)", "Salzgitter",           
        "Schaumburg", "Schleswig-Flensburg","Segeberg", "Stade", "Steinburg", "Steinfurt", "Städteregion Aachen",  
        "Uelzen", "Viersen", "Warendorf", "Wilhelmshaven", "Wittmund", "Wolfsburg", "Wuppertal",
        "Ahrweiler",   "Altenkirchen",  "Alzey-Worms",  "Bad Dürkheim" , "Bad Kreuznach" , "Baden-Baden",
        "Bernkastel-Wittlich", "Birkenfeld",  "Böblingen", "Cochem-Zell", "Darmstadt-Dieburg", "Donnersbergkreis", "Dortmund",  "Eifelkreis Bitburg-Prüm",  "Ennepe-Ruhr-Kreis", "Esslingen",  
        "Frankenthal (Pfalz)",  "Frankfurt am Main", "Fulda",  "Gießen", "Groß-Gerau", "Heidenheim",  "Heilbronn", 
        "Hersfeld-Rotenburg", "Hochsauerlandkreis", "Hochtaunuskreis",   "Hohenlohekreis", "Höxter", "Kaiserslautern", "Karlsruhe", "Kassel", "Koblenz",   "Lahn-Dill-Kreis", "Landau in der Pfalz",  "Landkreis Heilbronn", "Landkreis Karlsruhe",
        "Limburg-Weilburg",  "Lippe",  "Ludwigsburg" ,  "Main-Kinzig-Kreis", "Main-Tauber-Kreis", "Mainz",   "Mainz-Bingen",  "Mannheim",  "Marburg-Biedenkopf", "Mayen-Koblenz", "Minden-Lübbecke", "Märkischer Kreis",
        "Neckar-Odenwald-Kreis", "Neustadt an der Weinstraße",  "Neuwied", "Odenwaldkreis", "Offenbach", "Offenbach am Main",  "Olpe", "Ostalbkreis", "Paderborn", "Pforzheim", "Pirmasens",  "Rastatt", "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rheingau-Taunus-Kreis", "Schwalm-Eder-Kreis",
        "Schwäbisch Hall", "Siegen-Wittgenstein", "Soest" , "Speyer" ,  "Stuttgart", "Südliche Weinstraße", "Südwestpfalz", "Trier",   "Trier-Saarburg",  "Unna",  "Vogelsbergkreis", "Waldeck-Frankenberg", "Werra-Meißner-Kreis",  "Westerwaldkreis", "Wiesbaden",  "Worms", "Zweibrücken"
        ]
    if chosen_model == "thirdfourthhundred":
        federalStates = ["Alb-Donau-Kreis",  "Altötting", "Amberg", "Amberg-Sulzbach",  "Ansbach", "Aschaffenburg", "Bad Kissingen", "Bamberg",  "Bayreuth", "Berchtesgadener Land", "Biberach", "Bodenseekreis", "Breisgau-Hochschwarzwald", "Calw", "Cham",                               
        "Coburg", "Dachau", "Deggendorf", "Dingolfing-Landau",  "Ebersberg", "Eichstätt", "Emmendingen",  "Enzkreis", "Erding", "Erlangen",  "Erlangen-Höchstadt", "Forchheim", "Freiburg im Breisgau", "Freising", "Freudenstadt", "Freyung-Grafenau", "Fürstenfeldbruck", "Fürth", "Garmisch-Partenkirchen", "Haßberge", "Hof", "Ingolstadt", "Kelheim", "Kitzingen", "Konstanz",  "Kronach", "Landkreis Ansbach", "Landkreis Aschaffenburg", "Landkreis Bamberg",  "Landkreis Bayreuth", "Landkreis Coburg", "Landkreis Fürth", "Landkreis Hof", "Landkreis Landshut", "Landkreis München", "Landkreis Passau", "Landkreis Regensburg", "Landsberg am Lech",  "Landshut",                           
        "Lörrach", "Miesbach", "Mühldorf am Inn", "München",  "Neuburg-Schrobenhausen", "Neumarkt in der Oberpfalz", "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab",  "Nürnberg",  "Nürnberger Land",  "Ortenaukreis",  "Passau",                             
        "Ravensburg", "Regen",  "Regensburg", "Reutlingen",  "Rhön-Grabfeld", "Rosenheim", "Roth",  "Rottal-Inn", "Rottweil",
        "Schwabach", "Schwandorf",  "Schwarzwald-Baar-Kreis", "Schweinfurt",  "Sigmaringen", "Straubing", "Straubing-Bogen",  "Tirschenreuth", "Traunstein",                         
        "Tuttlingen",  "Ulm",  "Waldshut ", 
        "Weiden in der Oberpfalz", "Weilheim-Schongau",  "Weißenburg-Gunzenhausen",            
        "Wunsiedel im Fichtelgebirge", "Würzburg", "Zollernalbkreis",
        "Altenburger Land",   "Altmarkkreis Salzwedel",   "Anhalt-Bitterfeld",  "Augsburg",                        
        "Bautzen",  "Berlin",   "Börde", "Brandenburg an der Havel",        
        "Burgenlandkreis",  "Chemnitz",  "Dahme-Spreewald", "Dessau-Roßlau",                   
        "Dillingen an der Donau", "Donau-Ries",  "Dresden", "Eichsfeld",                       
        "Elbe-Elster",  "Erfurt", "Erzgebirgskreis",  "Frankfurt (Oder)",                
        "Gera",  "Görlitz", "Gotha",  "Greiz",                           
        "Günzburg",    "Halle (Saale)",  "Harz",  "Hildburghausen",                  
        "Ilm-Kreis", "Jena",  "Jerichower Land", "Kaufbeuren",                      
        "Kempten (Allgäu)",  "Landkreis Augsburg",  "Landkreis Leipzig",   "Landkreis Rostock",               
        "Landkreis Schweinfurt" , "Landkreis Würzburg" , "Leipzig",  "Ludwigslust-Parchim",             
        "Magdeburg",  "Main-Spessart",  "Märkisch-Oderland",  "Mecklenburgische Seenplatte",     
        "Meißen",   "Memmingen",     "Merzig-Wadern", "Miltenberg",                      
        "Mittelsachsen",  "Neu-Ulm", "Neunkirchen",  "Nordsachsen",                     
        "Nordwestmecklenburg",  "Oberallgäu",   "Oberhavel",   "Oberspreewald-Lausitz",           
        "Oder-Spree",   "Ostprignitz-Ruppin", "Potsdam",  "Potsdam-Mittelmark",              
        "Prignitz",  "Regionalverband Saarbrücken", "Rostock",  "Saale-Orla-Kreis",                
        "Saalekreis",  "Saalfeld-Rudolstadt" , "Saarlouis" ,  "Sächsische Schweiz-Osterzgebirge",
        "Salzlandkreis",   "Schmalkalden-Meiningen",  "Schwerin",  "Sömmerda",                        
        "Sonneberg",  "Spree-Neiße",  "Stendal",  "Suhl",                            
        "Teltow-Fläming",  "Uckermark",  "Unstrut-Hainich-Kreis",  "Vogtlandkreis",                   
        "Vorpommern-Greifswald", "Vorpommern-Rügen",  "Wartburgkreis",  "Weimar",                          
        "Weimarer Land",   "Wittenberg",  "Zwickau"] 
    if chosen_model == "fourhundred":
        federalStates = ["Aurich","Bielefeld","Bonn","Borken","Braunschweig","Bremen","Bremerhaven",          
        "Celle","Cloppenburg", "Coesfeld", "Cuxhaven", "Delmenhorst", "Diepholz", "Dithmarschen",         
        "Duisburg","Düren", "Düsseldorf", "Emden", "Emsland", "Essen","Euskirchen",           
        "Flensburg","Friesland", "Gifhorn", "Goslar", "Göttingen", "Gütersloh", "Hamburg",              
        "Hameln-Pyrmont","Hannover", "Harburg", "Heidekreis", "Heinsberg", "Helmstedt", "Herford",              
        "Herzogtum Lauenburg","Hildesheim", "Holzminden", "Kiel", "Kleve", "Krefeld", "Köln",                 
        "Landkreis Oldenburg","Landkreis Osnabrück","Leer",  "Leverkusen", "Lübeck", "Lüchow-Dannenberg", "Lüneburg",             
        "Mettmann","Mönchengladbach","Mülheim an der Ruhr", "Münster", "Neumünster", "NienburgWeser", "Nordfriesland",        
        "Oberbergischer Kreis","Oldenburg" , "Osnabrück", "Osterholz", "Ostholstein", "Pinneberg", "Plön",                 
        "Recklinghausen", "Remscheid","Rendsburg-Eckernförde", "Rhein-Neuss", "Rhein-Sieg-Kreis", "Rotenburg (Wümme)", "Salzgitter",           
        "Schaumburg", "Schleswig-Flensburg","Segeberg", "Stade", "Steinburg", "Steinfurt", "Städteregion Aachen",  
        "Uelzen", "Viersen", "Warendorf", "Wilhelmshaven", "Wittmund", "Wolfsburg", "Wuppertal",
        "Ahrweiler",   "Altenkirchen",  "Alzey-Worms",  "Bad Dürkheim" , "Bad Kreuznach" , "Baden-Baden",
        "Bernkastel-Wittlich", "Birkenfeld",  "Böblingen", "Cochem-Zell", "Darmstadt-Dieburg", "Donnersbergkreis", "Dortmund",  "Eifelkreis Bitburg-Prüm",  "Ennepe-Ruhr-Kreis", "Esslingen",  
        "Frankenthal (Pfalz)",  "Frankfurt am Main", "Fulda",  "Gießen", "Groß-Gerau", "Heidenheim",  "Heilbronn", 
        "Hersfeld-Rotenburg", "Hochsauerlandkreis", "Hochtaunuskreis",   "Hohenlohekreis", "Höxter", "Kaiserslautern", "Karlsruhe", "Kassel", "Koblenz",   "Lahn-Dill-Kreis", "Landau in der Pfalz",  "Landkreis Heilbronn", "Landkreis Karlsruhe",
        "Limburg-Weilburg",  "Lippe",  "Ludwigsburg" ,  "Main-Kinzig-Kreis", "Main-Tauber-Kreis", "Mainz",   "Mainz-Bingen",  "Mannheim",  "Marburg-Biedenkopf", "Mayen-Koblenz", "Minden-Lübbecke", "Märkischer Kreis",
        "Neckar-Odenwald-Kreis", "Neustadt an der Weinstraße",  "Neuwied", "Odenwaldkreis", "Offenbach", "Offenbach am Main",  "Olpe", "Ostalbkreis", "Paderborn", "Pforzheim", "Pirmasens",  "Rastatt", "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rheingau-Taunus-Kreis", "Schwalm-Eder-Kreis",
        "Schwäbisch Hall", "Siegen-Wittgenstein", "Soest" , "Speyer" ,  "Stuttgart", "Südliche Weinstraße", "Südwestpfalz", "Trier",   "Trier-Saarburg",  "Unna",  "Vogelsbergkreis", "Waldeck-Frankenberg", "Werra-Meißner-Kreis",  "Westerwaldkreis", "Wiesbaden",  "Worms", "Zweibrücken",
        "Alb-Donau-Kreis",  "Altötting", "Amberg", "Amberg-Sulzbach",  "Ansbach", "Aschaffenburg", "Bad Kissingen", "Bamberg",  "Bayreuth", "Berchtesgadener Land", "Biberach", "Bodenseekreis", "Breisgau-Hochschwarzwald", "Calw", "Cham",                               
        "Coburg", "Dachau", "Deggendorf", "Dingolfing-Landau",  "Ebersberg", "Eichstätt", "Emmendingen",  "Enzkreis", "Erding", "Erlangen",  "Erlangen-Höchstadt", "Forchheim", "Freiburg im Breisgau", "Freising", "Freudenstadt", "Freyung-Grafenau", "Fürstenfeldbruck", "Fürth", "Garmisch-Partenkirchen", "Haßberge", "Hof", "Ingolstadt", "Kelheim", "Kitzingen", "Konstanz",  "Kronach", "Landkreis Ansbach", "Landkreis Aschaffenburg", "Landkreis Bamberg",  "Landkreis Bayreuth", "Landkreis Coburg", "Landkreis Fürth", "Landkreis Hof", "Landkreis Landshut", "Landkreis München", "Landkreis Passau", "Landkreis Regensburg", "Landsberg am Lech",  "Landshut",                           
        "Lörrach", "Miesbach", "Mühldorf am Inn", "München",  "Neuburg-Schrobenhausen", "Neumarkt in der Oberpfalz", "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab",  "Nürnberg",  "Nürnberger Land",  "Ortenaukreis",  "Passau",                             
        "Ravensburg", "Regen",  "Regensburg", "Reutlingen",  "Rhön-Grabfeld", "Rosenheim", "Roth",  "Rottal-Inn", "Rottweil",
        "Schwabach", "Schwandorf",  "Schwarzwald-Baar-Kreis", "Schweinfurt",  "Sigmaringen", "Straubing", "Straubing-Bogen",  "Tirschenreuth", "Traunstein",                         
        "Tuttlingen",  "Ulm",  "Waldshut ", 
        "Weiden in der Oberpfalz", "Weilheim-Schongau",  "Weißenburg-Gunzenhausen",            
        "Wunsiedel im Fichtelgebirge", "Würzburg", "Zollernalbkreis",
        "Altenburger Land",   "Altmarkkreis Salzwedel",   "Anhalt-Bitterfeld",  "Augsburg",                        
        "Bautzen",  "Berlin",   "Börde", "Brandenburg an der Havel",        
        "Burgenlandkreis",  "Chemnitz",  "Dahme-Spreewald", "Dessau-Roßlau",                   
        "Dillingen an der Donau", "Donau-Ries",  "Dresden", "Eichsfeld",                       
        "Elbe-Elster",  "Erfurt", "Erzgebirgskreis",  "Frankfurt (Oder)",                
        "Gera",  "Görlitz", "Gotha",  "Greiz",                           
        "Günzburg",    "Halle (Saale)",  "Harz",  "Hildburghausen",                  
        "Ilm-Kreis", "Jena",  "Jerichower Land", "Kaufbeuren",                      
        "Kempten (Allgäu)",  "Landkreis Augsburg",  "Landkreis Leipzig",   "Landkreis Rostock",               
        "Landkreis Schweinfurt" , "Landkreis Würzburg" , "Leipzig",  "Ludwigslust-Parchim",             
        "Magdeburg",  "Main-Spessart",  "Märkisch-Oderland",  "Mecklenburgische Seenplatte",     
        "Meißen",   "Memmingen",     "Merzig-Wadern", "Miltenberg",                      
        "Mittelsachsen",  "Neu-Ulm", "Neunkirchen",  "Nordsachsen",                     
        "Nordwestmecklenburg",  "Oberallgäu",   "Oberhavel",   "Oberspreewald-Lausitz",           
        "Oder-Spree",   "Ostprignitz-Ruppin", "Potsdam",  "Potsdam-Mittelmark",              
        "Prignitz",  "Regionalverband Saarbrücken", "Rostock",  "Saale-Orla-Kreis",                
        "Saalekreis",  "Saalfeld-Rudolstadt" , "Saarlouis" ,  "Sächsische Schweiz-Osterzgebirge",
        "Salzlandkreis",   "Schmalkalden-Meiningen",  "Schwerin",  "Sömmerda",                        
        "Sonneberg",  "Spree-Neiße",  "Stendal",  "Suhl",                            
        "Teltow-Fläming",  "Uckermark",  "Unstrut-Hainich-Kreis",  "Vogtlandkreis",                   
        "Vorpommern-Greifswald", "Vorpommern-Rügen",  "Wartburgkreis",  "Weimar",                          
        "Weimarer Land",   "Wittenberg",  "Zwickau"
        ]
    if chosen_model == "cities_non_hierarchical":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin"]
    if chosen_model == "countieswithproblems":
        federalStates = [
            "Berlin", "Bremen", "Hamburg", "Stuttgart", "München", "Köln",              
            "Frankfurt am Main", "Düsseldorf", "Leipzig", "Essen", "Dortmund", "Dresden",          
            "Nürnberg", "Duisburg", "Helmstedt", "Holzminden", "Schaumburg", "Delmenhorst",      
            "Wilhelmshaven", "Emsland", "Leer", "Oldenburg", "Bremerhaven"
        ]
              
    for i, c in enumerate(federalStates):
        # upper plot
        fig, axs = plt.subplots(4, 1, figsize=(13, 24), sharex=True)
        axs = axs.ravel()

        if incl2024 == True:
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
            "Cnat": "new national cases",
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
                                y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
                        if year == 2023:
                            if indicator == "C":
                                y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_C>=61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
                    else:
                        if year == 2020:
                            if indicator == "C":
                                y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
                        if year == 2023:
                            if indicator == "C":
                                y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_C>=61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.daylight_data_in.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
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
                                y_first = trace_in.constant_data.vacation_data_in.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.vacation_data_in.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.vacation_data_in.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
                        if year == 2023:
                            if indicator == "C":
                                y_first = trace_in.constant_data.vacation_data_in.where((trace_in.constant_data.counter_C>=61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.vacation_data_in.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.vacation_data_in.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
                    else:
                        if year == 2020:
                            if indicator == "C":
                                y_first = trace_in.constant_data.vacation_data_in.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.vacation_data_in.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.vacation_data_in.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
                        if year == 2023:
                            if indicator == "C":
                                y_first = trace_in.constant_data.vacation_data_in.where((trace_in.constant_data.counter_C>=61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.vacation_data_in.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.vacation_data_in.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
                    y = y_first.dropna(dim="obs_id", how="all")
                    plot_timeseries(
                        ax,
                        dates,
                        y,
                        color_in=colors["v"],
                        label_in="School vacation",
                        alpha=0.2
                )
                # public holidays
                if holiday_in is not None:
                    if chosen_model == "cities_non_hierarchical":
                        if year == 2020:
                            if indicator == "C":
                                y_first = trace_in.constant_data.holiday_data_in.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.holiday_data_in.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.holiday_data_in.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
                        if year == 2023:
                            if indicator == "C":
                                y_first = trace_in.constant_data.holiday_data_in.where((trace_in.constant_data.counter_C>=61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.holiday_data_in.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.holiday_data_in.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
                    else:
                        if year == 2020:
                            if indicator == "C":
                                y_first = trace_in.constant_data.holiday_data_in.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.holiday_data_in.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.holiday_data_in.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
                        if year == 2023:
                            if indicator == "C":
                                y_first = trace_in.constant_data.holiday_data_in.where((trace_in.constant_data.counter_C>=61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.holiday_data_in.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.holiday_data_in.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
                    y = y_first.dropna(dim="obs_id", how = "all")
                    plot_timeseries(
                        ax,
                        dates,
                        y,
                        color_in=colors["h"],
                        label_in="Public holidays",
                        alpha=0.2
                )
                # temperature
                if temperature_in is not None:
                    if chosen_model == "cities_non_hierarchical":
                        if year == 2020:
                            if indicator == "C":
                                y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
                        if year == 2023:
                            if indicator == "C":
                                y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_C>=61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
                    else:
                        if year == 2020:
                            if indicator == "C":
                                y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
                        if year == 2023:
                            if indicator == "C":
                                y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_C>=61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "R":
                                y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))
                            if indicator == "H":
                                y_first = trace_in.constant_data.max_Temp.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
                    y = y_first.dropna(dim="obs_id", how = "all")
                    plot_timeseries(
                        ax,
                        dates,
                        y,
                        color_in=colors["T"],
                        label_in="Temperature",
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
            
            # # plot disease indicators
            for indicator in indicators_in:
                if chosen_model == "cities_non_hierarchical":
                    if year == 2020:
                        if indicator == "C":
                            y_first = trace_in.constant_data.C.where((trace_in.constant_data.counter_C_long<61)&(trace_in.constant_data.fedState_idx_long==i))
                        if indicator == "R":
                            y_first = trace_in.constant_data.R.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                        if indicator == "H":
                            y_first = trace_in.constant_data.H.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
                    if year == 2023:
                        if indicator == "C":
                            y_first = trace_in.constant_data.C.where((trace_in.constant_data.counter_C==10000000)&(trace_in.constant_data.fedState_idx==i))
                        if indicator == "R":
                            y_first = trace_in.constant_data.R.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))
                        if indicator == "H":
                            y_first = trace_in.constant_data.H.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
                else:
                    if year == 2020:
                        if indicator == "C":
                            y_first = trace_in.constant_data.C.where((trace_in.constant_data.counter_C_long>8)&(trace_in.constant_data.counter_C_long<61)&(trace_in.constant_data.fedState_idx_long==i))
                        if indicator == "R":
                            y_first = trace_in.constant_data.R.where((trace_in.constant_data.counter_C_long>8)&(trace_in.constant_data.counter_R_long<61)&(trace_in.constant_data.fedState_idx_long==i))
                        if indicator == "H":
                            y_first = trace_in.constant_data.H.where((trace_in.constant_data.counter_C_long>8)&(trace_in.constant_data.counter_H_long<61)&(trace_in.constant_data.fedState_idx_long==i))
                    if year == 2023:
                        if indicator == "C":
                            y_first = trace_in.constant_data.C.where((trace_in.constant_data.counter_C_long>8)&(trace_in.constant_data.counter_C_long>=61)&(trace_in.constant_data.fedState_idx_long==i))
                        if indicator == "R":
                            y_first = trace_in.constant_data.R.where((trace_in.constant_data.counter_C_long>8)&(trace_in.constant_data.counter_R_long>=61)&(trace_in.constant_data.fedState_idx_long==i))
                        if indicator == "H":
                            y_first = trace_in.constant_data.H.where((trace_in.constant_data.counter_C_long>8)&(trace_in.constant_data.counter_H_long>=61)&(trace_in.constant_data.fedState_idx_long==i))
                y = y_first.dropna(dim="obs_id_long", how = "any")
                plot_timeseries(
                    ax,
                    dates,
                    y,
                    color_in=colors[indicator],
                    label_in=labels[indicator],
                    alpha=0.2,
                )

            for indicator in indicators_in:
                if year == 2020:
                    if indicator == "C":
                        y_first = trace_in.constant_data.C_nat.where((trace_in.constant_data.counter_C_long>8)&(trace_in.constant_data.counter_C_long<61)&(trace_in.constant_data.fedState_idx_long==i))
                    if indicator == "R":
                        y_first = trace_in.constant_data.R_nat.where((trace_in.constant_data.counter_C_long>8)&(trace_in.constant_data.counter_R_long<61)&(trace_in.constant_data.fedState_idx_long==i))
                    if indicator == "H":
                        y_first = trace_in.constant_data.H_nat.where((trace_in.constant_data.counter_C_long>8)&(trace_in.constant_data.counter_H_long<61)&(trace_in.constant_data.fedState_idx_long==i))
                if year == 2023:
                    if indicator == "C":
                        y_first = trace_in.constant_data.C_nat.where((trace_in.constant_data.counter_C_long>8)&(trace_in.constant_data.counter_C_long>=61)&(trace_in.constant_data.fedState_idx_long==i))
                    if indicator == "R":
                        y_first = trace_in.constant_data.R_nat.where((trace_in.constant_data.counter_C_long>8)&(trace_in.constant_data.counter_R_long>=61)&(trace_in.constant_data.fedState_idx_long==i))
                    if indicator == "H":
                        y_first = trace_in.constant_data.H_nat.where((trace_in.constant_data.counter_C_long>8)&(trace_in.constant_data.counter_H_long>=61)&(trace_in.constant_data.fedState_idx_long==i))
                y = y_first.dropna(dim="obs_id_long", how = "any")
                plot_timeseries(
                    ax,
                    dates,
                    y,
                    color_in=colors["Cnat"],
                    label_in=labels["Cnat"],
                    alpha=0.2,
                )
                
            format_x_axis(ax, dates)
            ## set y label
            ax.set_ylabel("Normalized Disease Indicator")
            ax.legend(
                ncol=2,
                # bbox_to_anchor=(0.7, 2)
            )
            ax = axs[2]
            #3rd plot
            labels = {
                "C": "new cases $d_C$",
                "Cnat": "new national cases",
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
                        y_first = trace_in.posterior.d_C.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.posterior.d_R.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.d_H.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
                if year == 2023:
                    if indicator == "C":
                        y_first = trace_in.posterior.d_C.where((trace_in.constant_data.counter_C>=61)&(trace_in.constant_data.fedState_idx==1))
                    if indicator == "R":
                        y_first = trace_in.posterior.d_R.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.d_H.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
                y = y_first.dropna(dim="obs_id", how = "all")
                plot_timeseries(
                    ax,
                    dates,
                    y,
                    color_in=colors["Cnat"],
                    label_in=labels["Cnat"],
                    alpha=0.2,
                )
                
            if plus_nat_incidence == True: 
                for indicator in indicators_in:
                    if year == 2020:
                        if indicator == "C":
                            y_first = trace_in.posterior.d_C_nat.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
                        if indicator == "R":
                            y_first = trace_in.posterior.d_R_nat.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                        if indicator == "H":
                            y_first = trace_in.posterior.d_H_nat.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
                    if year == 2023:
                        if indicator == "C":
                            y_first = trace_in.posterior.d_C_nat.where((trace_in.constant_data.counter_C>=61)&(trace_in.constant_data.fedState_idx==1))
                        if indicator == "R":
                            y_first = trace_in.posterior.d_R_nat.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))
                        if indicator == "H":
                            y_first = trace_in.posterior.d_H_nat.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
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
                        y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
                if year == 2023:
                    if indicator == "C":
                        y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_C>=61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.daylight_factor.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
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
                        y_first = trace_in.posterior.vacation_factor.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.posterior.vacation_factor.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.vacation_factor.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
                if year == 2023:
                    if indicator == "C":
                        y_first = trace_in.posterior.vacation_factor.where((trace_in.constant_data.counter_C>=61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.posterior.vacation_factor.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.vacation_factor.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
                y = y_first.dropna(dim="obs_id", how = "all")
                plot_timeseries(
                    ax,
                    dates,
                    y,
                    color_in=colors["v"],
                    label_in="School vacation",
                    alpha=0.2,
                )
            # public holidays
            if holiday_in is not None:
                if year == 2020:
                    #trace_filtered = trace_in.sel(fedState = i)
                    if indicator == "C":
                        y_first = trace_in.posterior.holiday_factor.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.posterior.holiday_factor.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.holiday_factor.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
                if year == 2023:
                    if indicator == "C":
                        y_first = trace_in.posterior.holiday_factor.where((trace_in.constant_data.counter_C>=61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.posterior.holiday_factor.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.holiday_factor.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
                y = y_first.dropna(dim="obs_id", how = "all")
                plot_timeseries(
                    ax,
                    dates,
                    y,
                    color_in=colors["h"],
                    label_in="Public holidays",
                    alpha=0.2,
                )
            # temperature
            if temperature_in is not None:
                if year == 2020:
                    if indicator == "C":
                        y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
                if year == 2023:
                    if indicator == "C":
                        y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_C>=61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "R":
                        y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))
                    if indicator == "H":
                        y_first = trace_in.posterior.temperature_factor.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
                y = y_first.dropna(dim="obs_id", how = "all")
                plot_timeseries(
                    ax,
                    dates,
                    y,
                    color_in=colors["T"],
                    label_in="Temperature",
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
                    y_first = trace_in.observed_data.d.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
                if indicator == "R":
                    y_first = trace_in.observed_data.d.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                if indicator == "H":
                    y_first = trace_in.observed_data.d.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
            if year == 2023:
                if indicator == "C":
                    y_first = trace_in.observed_data.d.where((trace_in.constant_data.counter_C>=61)&(trace_in.constant_data.fedState_idx==i))
                if indicator == "R":
                    y_first = trace_in.observed_data.d.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))
                if indicator == "H":
                    y_first = trace_in.observed_data.d.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
            y = y_first.dropna(dim="obs_id", how = "all")
            ax.plot(
                dates,
                y,
                label="Observed out-of-home duration",
                color=colors["d_obs"],
                marker="o",
            )

            if year == 2020:
                if indicator == "C":
                    y_first = trace_in.posterior.m.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
                if indicator == "R":
                    y_first = trace_in.posterior.m.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
                if indicator == "H":
                    y_first = trace_in.posterior.m.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
            if year == 2023:
                if indicator == "C":
                    y_first = trace_in.posterior.m.where((trace_in.constant_data.counter_C>=61)&(trace_in.constant_data.fedState_idx==i))
                if indicator == "R":
                    y_first = trace_in.posterior.m.where((trace_in.constant_data.counter_R>=61)&(trace_in.constant_data.fedState_idx==i))
                if indicator == "H":
                    y_first = trace_in.posterior.m.where((trace_in.constant_data.counter_H>=61)&(trace_in.constant_data.fedState_idx==i))
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
    if chosen_model == "fedStates_nat":
        federalStates = (
       "Baden-Württemberg", "Bayern", "Berlin", "Brandenburg", "Bremen",
       "Hamburg", "Hessen", "Mecklenburg-Vorpommern", "Niedersachsen",
       "Nordrhein-Westfalen", "Rheinland-Pfalz", "Saarland", "Sachsen",
       "Sachsen-Anhalt", "Schleswig-Holstein", "Thüringen")
    if chosen_model == "cities":  
        federalStates = [
        "Berlin","Bielefeld","Bonn","Braunschweig","Bremen","Chemnitz",         
        "Dortmund","Dresden","Duisburg","Düsseldorf","Erfurt","Essen",            
        "Frankfurt am Main" "Halle (Saale)","Hamburg","Hannover","Karlsruhe","Kiel",             
        "Krefeld","Köln","Leipzig","Lübeck","Magdeburg","Mönchengladbach",  
        "München","Münster","Nürnberg","Oldenburg","Potsdam","Rostock",          
        "Stuttgart","Wiesbaden","Wuppertal"]
    if chosen_model == "firsthundred":
        federalStates = ["Aurich","Bielefeld","Bonn","Borken","Braunschweig","Bremen","Bremerhaven",          
        "Celle","Cloppenburg", "Coesfeld", "Cuxhaven", "Delmenhorst", "Diepholz", "Dithmarschen",         
        "Duisburg","Düren", "Düsseldorf", "Emden", "Emsland", "Essen","Euskirchen",           
        "Flensburg","Friesland", "Gifhorn", "Goslar", "Göttingen", "Gütersloh", "Hamburg",              
        "Hameln-Pyrmont","Hannover", "Harburg", "Heidekreis", "Heinsberg", "Helmstedt", "Herford",              
        "Herzogtum Lauenburg","Hildesheim", "Holzminden", "Kiel", "Kleve", "Krefeld", "Köln",                 
        "Landkreis Oldenburg","Landkreis Osnabrück","Leer",  "Leverkusen", "Lübeck", "Lüchow-Dannenberg", "Lüneburg",             
        "Mettmann","Mönchengladbach","Mülheim an der Ruhr", "Münster", "Neumünster", "NienburgWeser", "Nordfriesland",        
        "Oberbergischer Kreis","Oldenburg" , "Osnabrück", "Osterholz", "Ostholstein", "Pinneberg", "Plön",                 
        "Recklinghausen", "Remscheid","Rendsburg-Eckernförde", "Rhein-Neuss", "Rhein-Sieg-Kreis", "Rotenburg (Wümme)", "Salzgitter",           
        "Schaumburg", "Schleswig-Flensburg","Segeberg", "Stade", "Steinburg", "Steinfurt", "Städteregion Aachen",  
        "Uelzen", "Viersen", "Warendorf", "Wilhelmshaven", "Wittmund", "Wolfsburg", "Wuppertal"]
    if chosen_model == "secondhundred":
        federalStates = ["Ahrweiler",   "Altenkirchen",  "Alzey-Worms",  "Bad Dürkheim" , "Bad Kreuznach" , "Baden-Baden",
                         "Bernkastel-Wittlich", "Birkenfeld",  "Böblingen", "Cochem-Zell", "Darmstadt-Dieburg", "Donnersbergkreis", "Dortmund",  "Eifelkreis Bitburg-Prüm",  "Ennepe-Ruhr-Kreis", "Esslingen",  
                         "Frankenthal (Pfalz)",  "Frankfurt am Main", "Fulda",  "Gießen", "Groß-Gerau", "Heidenheim",  "Heilbronn", 
                         "Hersfeld-Rotenburg", "Hochsauerlandkreis", "Hochtaunuskreis",   "Hohenlohekreis", "Höxter", "Kaiserslautern", "Karlsruhe", "Kassel", "Koblenz",   "Lahn-Dill-Kreis", "Landau in der Pfalz",  "Landkreis Heilbronn", "Landkreis Karlsruhe",
                         "Limburg-Weilburg",  "Lippe",  "Ludwigsburg" ,  "Main-Kinzig-Kreis", "Main-Tauber-Kreis", "Mainz",   "Mainz-Bingen",  "Mannheim",  "Marburg-Biedenkopf", "Mayen-Koblenz", "Minden-Lübbecke", "Märkischer Kreis",
                         "Neckar-Odenwald-Kreis", "Neustadt an der Weinstraße",  "Neuwied", "Odenwaldkreis", "Offenbach",                  "Offenbach am Main",  "Olpe", "Ostalbkreis", "Paderborn", "Pforzheim", "Pirmasens",  "Rastatt", "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rheingau-Taunus-Kreis", "Schwalm-Eder-Kreis",
                         "Schwäbisch Hall", "Siegen-Wittgenstein", "Soest" , "Speyer" ,  "Stuttgart", "Südliche Weinstraße", "Südwestpfalz",              "Trier",   "Trier-Saarburg",  "Unna",  "Vogelsbergkreis", "Waldeck-Frankenberg", "Werra-Meißner-Kreis",  "Westerwaldkreis", "Wiesbaden",  "Worms", "Zweibrücken"]
    if chosen_model == "thirdhundred":
        federalStates = ["Alb-Donau-Kreis",  "Altötting", "Amberg", "Amberg-Sulzbach",  "Ansbach", "Aschaffenburg", "Bad Kissingen", "Bamberg",  "Bayreuth", "Berchtesgadener Land", "Biberach", "Bodenseekreis", "Breisgau-Hochschwarzwald", "Calw", "Cham",                               
        "Coburg", "Dachau", "Deggendorf", "Dingolfing-Landau",  "Ebersberg", "Eichstätt", "Emmendingen",  "Enzkreis", "Erding", "Erlangen",  "Erlangen-Höchstadt", "Forchheim", "Freiburg im Breisgau", "Freising", "Freudenstadt", "Freyung-Grafenau", "Fürstenfeldbruck", "Fürth", "Garmisch-Partenkirchen", "Haßberge", "Hof", "Ingolstadt", "Kelheim", "Kitzingen", "Konstanz",  "Kronach", "Landkreis Ansbach", "Landkreis Aschaffenburg", "Landkreis Bamberg",  "Landkreis Bayreuth", "Landkreis Coburg", "Landkreis Fürth", "Landkreis Hof", "Landkreis Landshut", "Landkreis München", "Landkreis Passau", "Landkreis Regensburg", "Landsberg am Lech",  "Landshut",                           
        "Lörrach", "Miesbach", "Mühldorf am Inn", "München",  "Neuburg-Schrobenhausen", "Neumarkt in der Oberpfalz", "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab",  "Nürnberg",  "Nürnberger Land",  "Ortenaukreis",  "Passau",                             
        "Ravensburg", "Regen",  "Regensburg", "Reutlingen",  "Rhön-Grabfeld", "Rosenheim", "Roth",  "Rottal-Inn", "Rottweil",
        "Schwabach", "Schwandorf",  "Schwarzwald-Baar-Kreis", "Schweinfurt",  "Sigmaringen", "Straubing", "Straubing-Bogen",  "Tirschenreuth", "Traunstein",                         
        "Tuttlingen",  "Ulm",  "Waldshut ", 
        "Weiden in der Oberpfalz", "Weilheim-Schongau",  "Weißenburg-Gunzenhausen",            
        "Wunsiedel im Fichtelgebirge", "Würzburg", "Zollernalbkreis"]   
    if chosen_model == "fourthhundred":
        federalStates = ["Altenburger Land",   "Altmarkkreis Salzwedel",   "Anhalt-Bitterfeld",  "Augsburg",                        
        "Bautzen",  "Berlin",   "Börde", "Brandenburg an der Havel",        
        "Burgenlandkreis",  "Chemnitz",  "Dahme-Spreewald", "Dessau-Roßlau",                   
        "Dillingen an der Donau", "Donau-Ries",  "Dresden", "Eichsfeld",                       
        "Elbe-Elster",  "Erfurt", "Erzgebirgskreis",  "Frankfurt (Oder)",                
        "Gera",  "Görlitz", "Gotha",  "Greiz",                           
        "Günzburg",    "Halle (Saale)",  "Harz",  "Hildburghausen",                  
        "Ilm-Kreis", "Jena",  "Jerichower Land", "Kaufbeuren",                      
        "Kempten (Allgäu)",  "Landkreis Augsburg",  "Landkreis Leipzig",   "Landkreis Rostock",               
        "Landkreis Schweinfurt" , "Landkreis Würzburg" , "Leipzig",  "Ludwigslust-Parchim",             
        "Magdeburg",  "Main-Spessart",  "Märkisch-Oderland",  "Mecklenburgische Seenplatte",     
        "Meißen",   "Memmingen",     "Merzig-Wadern", "Miltenberg",                      
        "Mittelsachsen",  "Neu-Ulm", "Neunkirchen",  "Nordsachsen",                     
        "Nordwestmecklenburg",  "Oberallgäu",   "Oberhavel",   "Oberspreewald-Lausitz",           
        "Oder-Spree",   "Ostprignitz-Ruppin", "Potsdam",  "Potsdam-Mittelmark",              
        "Prignitz",  "Regionalverband Saarbrücken", "Rostock",  "Saale-Orla-Kreis",                
        "Saalekreis",  "Saalfeld-Rudolstadt" , "Saarlouis" ,  "Sächsische Schweiz-Osterzgebirge",
        "Salzlandkreis",   "Schmalkalden-Meiningen",  "Schwerin",  "Sömmerda",                        
        "Sonneberg",  "Spree-Neiße",  "Stendal",  "Suhl",                            
        "Teltow-Fläming",  "Uckermark",  "Unstrut-Hainich-Kreis",  "Vogtlandkreis",                   
        "Vorpommern-Greifswald", "Vorpommern-Rügen",  "Wartburgkreis",  "Weimar",                          
        "Weimarer Land",   "Wittenberg",  "Zwickau"]
    if chosen_model == "firstsecondhundred":
        federalStates = ["Aurich","Bielefeld","Bonn","Borken","Braunschweig","Bremen","Bremerhaven",          
        "Celle","Cloppenburg", "Coesfeld", "Cuxhaven", "Delmenhorst", "Diepholz", "Dithmarschen",         
        "Duisburg","Düren", "Düsseldorf", "Emden", "Emsland", "Essen","Euskirchen",           
        "Flensburg","Friesland", "Gifhorn", "Goslar", "Göttingen", "Gütersloh", "Hamburg",              
        "Hameln-Pyrmont","Hannover", "Harburg", "Heidekreis", "Heinsberg", "Helmstedt", "Herford",              
        "Herzogtum Lauenburg","Hildesheim", "Holzminden", "Kiel", "Kleve", "Krefeld", "Köln",                 
        "Landkreis Oldenburg","Landkreis Osnabrück","Leer",  "Leverkusen", "Lübeck", "Lüchow-Dannenberg", "Lüneburg",             
        "Mettmann","Mönchengladbach","Mülheim an der Ruhr", "Münster", "Neumünster", "NienburgWeser", "Nordfriesland",        
        "Oberbergischer Kreis","Oldenburg" , "Osnabrück", "Osterholz", "Ostholstein", "Pinneberg", "Plön",                 
        "Recklinghausen", "Remscheid","Rendsburg-Eckernförde", "Rhein-Neuss", "Rhein-Sieg-Kreis", "Rotenburg (Wümme)", "Salzgitter",           
        "Schaumburg", "Schleswig-Flensburg","Segeberg", "Stade", "Steinburg", "Steinfurt", "Städteregion Aachen",  
        "Uelzen", "Viersen", "Warendorf", "Wilhelmshaven", "Wittmund", "Wolfsburg", "Wuppertal",
        "Ahrweiler",   "Altenkirchen",  "Alzey-Worms",  "Bad Dürkheim" , "Bad Kreuznach" , "Baden-Baden",
        "Bernkastel-Wittlich", "Birkenfeld",  "Böblingen", "Cochem-Zell", "Darmstadt-Dieburg", "Donnersbergkreis", "Dortmund",  "Eifelkreis Bitburg-Prüm",  "Ennepe-Ruhr-Kreis", "Esslingen",  
        "Frankenthal (Pfalz)",  "Frankfurt am Main", "Fulda",  "Gießen", "Groß-Gerau", "Heidenheim",  "Heilbronn", 
        "Hersfeld-Rotenburg", "Hochsauerlandkreis", "Hochtaunuskreis",   "Hohenlohekreis", "Höxter", "Kaiserslautern", "Karlsruhe", "Kassel", "Koblenz",   "Lahn-Dill-Kreis", "Landau in der Pfalz",  "Landkreis Heilbronn", "Landkreis Karlsruhe",
        "Limburg-Weilburg",  "Lippe",  "Ludwigsburg" ,  "Main-Kinzig-Kreis", "Main-Tauber-Kreis", "Mainz",   "Mainz-Bingen",  "Mannheim",  "Marburg-Biedenkopf", "Mayen-Koblenz", "Minden-Lübbecke", "Märkischer Kreis",
        "Neckar-Odenwald-Kreis", "Neustadt an der Weinstraße",  "Neuwied", "Odenwaldkreis", "Offenbach", "Offenbach am Main",  "Olpe", "Ostalbkreis", "Paderborn", "Pforzheim", "Pirmasens",  "Rastatt", "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rheingau-Taunus-Kreis", "Schwalm-Eder-Kreis",
        "Schwäbisch Hall", "Siegen-Wittgenstein", "Soest" , "Speyer" ,  "Stuttgart", "Südliche Weinstraße", "Südwestpfalz", "Trier",   "Trier-Saarburg",  "Unna",  "Vogelsbergkreis", "Waldeck-Frankenberg", "Werra-Meißner-Kreis",  "Westerwaldkreis", "Wiesbaden",  "Worms", "Zweibrücken"
        ]
    if chosen_model == "thirdfourthhundred":
        federalStates = ["Alb-Donau-Kreis",  "Altötting", "Amberg", "Amberg-Sulzbach",  "Ansbach", "Aschaffenburg", "Bad Kissingen", "Bamberg",  "Bayreuth", "Berchtesgadener Land", "Biberach", "Bodenseekreis", "Breisgau-Hochschwarzwald", "Calw", "Cham",                               
        "Coburg", "Dachau", "Deggendorf", "Dingolfing-Landau",  "Ebersberg", "Eichstätt", "Emmendingen",  "Enzkreis", "Erding", "Erlangen",  "Erlangen-Höchstadt", "Forchheim", "Freiburg im Breisgau", "Freising", "Freudenstadt", "Freyung-Grafenau", "Fürstenfeldbruck", "Fürth", "Garmisch-Partenkirchen", "Haßberge", "Hof", "Ingolstadt", "Kelheim", "Kitzingen", "Konstanz",  "Kronach", "Landkreis Ansbach", "Landkreis Aschaffenburg", "Landkreis Bamberg",  "Landkreis Bayreuth", "Landkreis Coburg", "Landkreis Fürth", "Landkreis Hof", "Landkreis Landshut", "Landkreis München", "Landkreis Passau", "Landkreis Regensburg", "Landsberg am Lech",  "Landshut",                           
        "Lörrach", "Miesbach", "Mühldorf am Inn", "München",  "Neuburg-Schrobenhausen", "Neumarkt in der Oberpfalz", "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab",  "Nürnberg",  "Nürnberger Land",  "Ortenaukreis",  "Passau",                             
        "Ravensburg", "Regen",  "Regensburg", "Reutlingen",  "Rhön-Grabfeld", "Rosenheim", "Roth",  "Rottal-Inn", "Rottweil",
        "Schwabach", "Schwandorf",  "Schwarzwald-Baar-Kreis", "Schweinfurt",  "Sigmaringen", "Straubing", "Straubing-Bogen",  "Tirschenreuth", "Traunstein",                         
        "Tuttlingen",  "Ulm",  "Waldshut ", 
        "Weiden in der Oberpfalz", "Weilheim-Schongau",  "Weißenburg-Gunzenhausen",            
        "Wunsiedel im Fichtelgebirge", "Würzburg", "Zollernalbkreis",
        "Altenburger Land",   "Altmarkkreis Salzwedel",   "Anhalt-Bitterfeld",  "Augsburg",                        
        "Bautzen",  "Berlin",   "Börde", "Brandenburg an der Havel",        
        "Burgenlandkreis",  "Chemnitz",  "Dahme-Spreewald", "Dessau-Roßlau",                   
        "Dillingen an der Donau", "Donau-Ries",  "Dresden", "Eichsfeld",                       
        "Elbe-Elster",  "Erfurt", "Erzgebirgskreis",  "Frankfurt (Oder)",                
        "Gera",  "Görlitz", "Gotha",  "Greiz",                           
        "Günzburg",    "Halle (Saale)",  "Harz",  "Hildburghausen",                  
        "Ilm-Kreis", "Jena",  "Jerichower Land", "Kaufbeuren",                      
        "Kempten (Allgäu)",  "Landkreis Augsburg",  "Landkreis Leipzig",   "Landkreis Rostock",               
        "Landkreis Schweinfurt" , "Landkreis Würzburg" , "Leipzig",  "Ludwigslust-Parchim",             
        "Magdeburg",  "Main-Spessart",  "Märkisch-Oderland",  "Mecklenburgische Seenplatte",     
        "Meißen",   "Memmingen",     "Merzig-Wadern", "Miltenberg",                      
        "Mittelsachsen",  "Neu-Ulm", "Neunkirchen",  "Nordsachsen",                     
        "Nordwestmecklenburg",  "Oberallgäu",   "Oberhavel",   "Oberspreewald-Lausitz",           
        "Oder-Spree",   "Ostprignitz-Ruppin", "Potsdam",  "Potsdam-Mittelmark",              
        "Prignitz",  "Regionalverband Saarbrücken", "Rostock",  "Saale-Orla-Kreis",                
        "Saalekreis",  "Saalfeld-Rudolstadt" , "Saarlouis" ,  "Sächsische Schweiz-Osterzgebirge",
        "Salzlandkreis",   "Schmalkalden-Meiningen",  "Schwerin",  "Sömmerda",                        
        "Sonneberg",  "Spree-Neiße",  "Stendal",  "Suhl",                            
        "Teltow-Fläming",  "Uckermark",  "Unstrut-Hainich-Kreis",  "Vogtlandkreis",                   
        "Vorpommern-Greifswald", "Vorpommern-Rügen",  "Wartburgkreis",  "Weimar",                          
        "Weimarer Land",   "Wittenberg",  "Zwickau"] 
    if chosen_model == "fourhundred":
        federalStates = ["Aurich","Bielefeld","Bonn","Borken","Braunschweig","Bremen","Bremerhaven",          
        "Celle","Cloppenburg", "Coesfeld", "Cuxhaven", "Delmenhorst", "Diepholz", "Dithmarschen",         
        "Duisburg","Düren", "Düsseldorf", "Emden", "Emsland", "Essen","Euskirchen",           
        "Flensburg","Friesland", "Gifhorn", "Goslar", "Göttingen", "Gütersloh", "Hamburg",              
        "Hameln-Pyrmont","Hannover", "Harburg", "Heidekreis", "Heinsberg", "Helmstedt", "Herford",              
        "Herzogtum Lauenburg","Hildesheim", "Holzminden", "Kiel", "Kleve", "Krefeld", "Köln",                 
        "Landkreis Oldenburg","Landkreis Osnabrück","Leer",  "Leverkusen", "Lübeck", "Lüchow-Dannenberg", "Lüneburg",             
        "Mettmann","Mönchengladbach","Mülheim an der Ruhr", "Münster", "Neumünster", "NienburgWeser", "Nordfriesland",        
        "Oberbergischer Kreis","Oldenburg" , "Osnabrück", "Osterholz", "Ostholstein", "Pinneberg", "Plön",                 
        "Recklinghausen", "Remscheid","Rendsburg-Eckernförde", "Rhein-Neuss", "Rhein-Sieg-Kreis", "Rotenburg (Wümme)", "Salzgitter",           
        "Schaumburg", "Schleswig-Flensburg","Segeberg", "Stade", "Steinburg", "Steinfurt", "Städteregion Aachen",  
        "Uelzen", "Viersen", "Warendorf", "Wilhelmshaven", "Wittmund", "Wolfsburg", "Wuppertal",
        "Ahrweiler",   "Altenkirchen",  "Alzey-Worms",  "Bad Dürkheim" , "Bad Kreuznach" , "Baden-Baden",
        "Bernkastel-Wittlich", "Birkenfeld",  "Böblingen", "Cochem-Zell", "Darmstadt-Dieburg", "Donnersbergkreis", "Dortmund",  "Eifelkreis Bitburg-Prüm",  "Ennepe-Ruhr-Kreis", "Esslingen",  
        "Frankenthal (Pfalz)",  "Frankfurt am Main", "Fulda",  "Gießen", "Groß-Gerau", "Heidenheim",  "Heilbronn", 
        "Hersfeld-Rotenburg", "Hochsauerlandkreis", "Hochtaunuskreis",   "Hohenlohekreis", "Höxter", "Kaiserslautern", "Karlsruhe", "Kassel", "Koblenz",   "Lahn-Dill-Kreis", "Landau in der Pfalz",  "Landkreis Heilbronn", "Landkreis Karlsruhe",
        "Limburg-Weilburg",  "Lippe",  "Ludwigsburg" ,  "Main-Kinzig-Kreis", "Main-Tauber-Kreis", "Mainz",   "Mainz-Bingen",  "Mannheim",  "Marburg-Biedenkopf", "Mayen-Koblenz", "Minden-Lübbecke", "Märkischer Kreis",
        "Neckar-Odenwald-Kreis", "Neustadt an der Weinstraße",  "Neuwied", "Odenwaldkreis", "Offenbach", "Offenbach am Main",  "Olpe", "Ostalbkreis", "Paderborn", "Pforzheim", "Pirmasens",  "Rastatt", "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rheingau-Taunus-Kreis", "Schwalm-Eder-Kreis",
        "Schwäbisch Hall", "Siegen-Wittgenstein", "Soest" , "Speyer" ,  "Stuttgart", "Südliche Weinstraße", "Südwestpfalz", "Trier",   "Trier-Saarburg",  "Unna",  "Vogelsbergkreis", "Waldeck-Frankenberg", "Werra-Meißner-Kreis",  "Westerwaldkreis", "Wiesbaden",  "Worms", "Zweibrücken",
        "Alb-Donau-Kreis",  "Altötting", "Amberg", "Amberg-Sulzbach",  "Ansbach", "Aschaffenburg", "Bad Kissingen", "Bamberg",  "Bayreuth", "Berchtesgadener Land", "Biberach", "Bodenseekreis", "Breisgau-Hochschwarzwald", "Calw", "Cham",                               
        "Coburg", "Dachau", "Deggendorf", "Dingolfing-Landau",  "Ebersberg", "Eichstätt", "Emmendingen",  "Enzkreis", "Erding", "Erlangen",  "Erlangen-Höchstadt", "Forchheim", "Freiburg im Breisgau", "Freising", "Freudenstadt", "Freyung-Grafenau", "Fürstenfeldbruck", "Fürth", "Garmisch-Partenkirchen", "Haßberge", "Hof", "Ingolstadt", "Kelheim", "Kitzingen", "Konstanz",  "Kronach", "Landkreis Ansbach", "Landkreis Aschaffenburg", "Landkreis Bamberg",  "Landkreis Bayreuth", "Landkreis Coburg", "Landkreis Fürth", "Landkreis Hof", "Landkreis Landshut", "Landkreis München", "Landkreis Passau", "Landkreis Regensburg", "Landsberg am Lech",  "Landshut",                           
        "Lörrach", "Miesbach", "Mühldorf am Inn", "München",  "Neuburg-Schrobenhausen", "Neumarkt in der Oberpfalz", "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab",  "Nürnberg",  "Nürnberger Land",  "Ortenaukreis",  "Passau",                             
        "Ravensburg", "Regen",  "Regensburg", "Reutlingen",  "Rhön-Grabfeld", "Rosenheim", "Roth",  "Rottal-Inn", "Rottweil",
        "Schwabach", "Schwandorf",  "Schwarzwald-Baar-Kreis", "Schweinfurt",  "Sigmaringen", "Straubing", "Straubing-Bogen",  "Tirschenreuth", "Traunstein",                         
        "Tuttlingen",  "Ulm",  "Waldshut ", 
        "Weiden in der Oberpfalz", "Weilheim-Schongau",  "Weißenburg-Gunzenhausen",            
        "Wunsiedel im Fichtelgebirge", "Würzburg", "Zollernalbkreis",
        "Altenburger Land",   "Altmarkkreis Salzwedel",   "Anhalt-Bitterfeld",  "Augsburg",                        
        "Bautzen",  "Berlin",   "Börde", "Brandenburg an der Havel",        
        "Burgenlandkreis",  "Chemnitz",  "Dahme-Spreewald", "Dessau-Roßlau",                   
        "Dillingen an der Donau", "Donau-Ries",  "Dresden", "Eichsfeld",                       
        "Elbe-Elster",  "Erfurt", "Erzgebirgskreis",  "Frankfurt (Oder)",                
        "Gera",  "Görlitz", "Gotha",  "Greiz",                           
        "Günzburg",    "Halle (Saale)",  "Harz",  "Hildburghausen",                  
        "Ilm-Kreis", "Jena",  "Jerichower Land", "Kaufbeuren",                      
        "Kempten (Allgäu)",  "Landkreis Augsburg",  "Landkreis Leipzig",   "Landkreis Rostock",               
        "Landkreis Schweinfurt" , "Landkreis Würzburg" , "Leipzig",  "Ludwigslust-Parchim",             
        "Magdeburg",  "Main-Spessart",  "Märkisch-Oderland",  "Mecklenburgische Seenplatte",     
        "Meißen",   "Memmingen",     "Merzig-Wadern", "Miltenberg",                      
        "Mittelsachsen",  "Neu-Ulm", "Neunkirchen",  "Nordsachsen",                     
        "Nordwestmecklenburg",  "Oberallgäu",   "Oberhavel",   "Oberspreewald-Lausitz",           
        "Oder-Spree",   "Ostprignitz-Ruppin", "Potsdam",  "Potsdam-Mittelmark",              
        "Prignitz",  "Regionalverband Saarbrücken", "Rostock",  "Saale-Orla-Kreis",                
        "Saalekreis",  "Saalfeld-Rudolstadt" , "Saarlouis" ,  "Sächsische Schweiz-Osterzgebirge",
        "Salzlandkreis",   "Schmalkalden-Meiningen",  "Schwerin",  "Sömmerda",                        
        "Sonneberg",  "Spree-Neiße",  "Stendal",  "Suhl",                            
        "Teltow-Fläming",  "Uckermark",  "Unstrut-Hainich-Kreis",  "Vogtlandkreis",                   
        "Vorpommern-Greifswald", "Vorpommern-Rügen",  "Wartburgkreis",  "Weimar",                          
        "Weimarer Land",   "Wittenberg",  "Zwickau"
        ]
    if chosen_model == "fourhundred":
        federalStates = ["Aurich","Bielefeld","Bonn","Borken","Braunschweig","Bremen","Bremerhaven",          
        "Celle","Cloppenburg", "Coesfeld", "Cuxhaven", "Delmenhorst", "Diepholz", "Dithmarschen",         
        "Duisburg","Düren", "Düsseldorf", "Emden", "Emsland", "Essen","Euskirchen",           
        "Flensburg","Friesland", "Gifhorn", "Goslar", "Göttingen", "Gütersloh", "Hamburg",              
        "Hameln-Pyrmont","Hannover", "Harburg", "Heidekreis", "Heinsberg", "Helmstedt", "Herford",              
        "Herzogtum Lauenburg","Hildesheim", "Holzminden", "Kiel", "Kleve", "Krefeld", "Köln",                 
        "Landkreis Oldenburg","Landkreis Osnabrück","Leer",  "Leverkusen", "Lübeck", "Lüchow-Dannenberg", "Lüneburg",             
        "Mettmann","Mönchengladbach","Mülheim an der Ruhr", "Münster", "Neumünster", "NienburgWeser", "Nordfriesland",        
        "Oberbergischer Kreis","Oldenburg" , "Osnabrück", "Osterholz", "Ostholstein", "Pinneberg", "Plön",                 
        "Recklinghausen", "Remscheid","Rendsburg-Eckernförde", "Rhein-Neuss", "Rhein-Sieg-Kreis", "Rotenburg (Wümme)", "Salzgitter",           
        "Schaumburg", "Schleswig-Flensburg","Segeberg", "Stade", "Steinburg", "Steinfurt", "Städteregion Aachen",  
        "Uelzen", "Viersen", "Warendorf", "Wilhelmshaven", "Wittmund", "Wolfsburg", "Wuppertal",
        "Ahrweiler",   "Altenkirchen",  "Alzey-Worms",  "Bad Dürkheim" , "Bad Kreuznach" , "Baden-Baden",
        "Bernkastel-Wittlich", "Birkenfeld",  "Böblingen", "Cochem-Zell", "Darmstadt-Dieburg", "Donnersbergkreis", "Dortmund",  "Eifelkreis Bitburg-Prüm",  "Ennepe-Ruhr-Kreis", "Esslingen",  
        "Frankenthal (Pfalz)",  "Frankfurt am Main", "Fulda",  "Gießen", "Groß-Gerau", "Heidenheim",  "Heilbronn", 
        "Hersfeld-Rotenburg", "Hochsauerlandkreis", "Hochtaunuskreis",   "Hohenlohekreis", "Höxter", "Kaiserslautern", "Karlsruhe", "Kassel", "Koblenz",   "Lahn-Dill-Kreis", "Landau in der Pfalz",  "Landkreis Heilbronn", "Landkreis Karlsruhe",
        "Limburg-Weilburg",  "Lippe",  "Ludwigsburg" ,  "Main-Kinzig-Kreis", "Main-Tauber-Kreis", "Mainz",   "Mainz-Bingen",  "Mannheim",  "Marburg-Biedenkopf", "Mayen-Koblenz", "Minden-Lübbecke", "Märkischer Kreis",
        "Neckar-Odenwald-Kreis", "Neustadt an der Weinstraße",  "Neuwied", "Odenwaldkreis", "Offenbach", "Offenbach am Main",  "Olpe", "Ostalbkreis", "Paderborn", "Pforzheim", "Pirmasens",  "Rastatt", "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rheingau-Taunus-Kreis", "Schwalm-Eder-Kreis",
        "Schwäbisch Hall", "Siegen-Wittgenstein", "Soest" , "Speyer" ,  "Stuttgart", "Südliche Weinstraße", "Südwestpfalz", "Trier",   "Trier-Saarburg",  "Unna",  "Vogelsbergkreis", "Waldeck-Frankenberg", "Werra-Meißner-Kreis",  "Westerwaldkreis", "Wiesbaden",  "Worms", "Zweibrücken",
        "Alb-Donau-Kreis",  "Altötting", "Amberg", "Amberg-Sulzbach",  "Ansbach", "Aschaffenburg", "Bad Kissingen", "Bamberg",  "Bayreuth", "Berchtesgadener Land", "Biberach", "Bodenseekreis", "Breisgau-Hochschwarzwald", "Calw", "Cham",                               
        "Coburg", "Dachau", "Deggendorf", "Dingolfing-Landau",  "Ebersberg", "Eichstätt", "Emmendingen",  "Enzkreis", "Erding", "Erlangen",  "Erlangen-Höchstadt", "Forchheim", "Freiburg im Breisgau", "Freising", "Freudenstadt", "Freyung-Grafenau", "Fürstenfeldbruck", "Fürth", "Garmisch-Partenkirchen", "Haßberge", "Hof", "Ingolstadt", "Kelheim", "Kitzingen", "Konstanz",  "Kronach", "Landkreis Ansbach", "Landkreis Aschaffenburg", "Landkreis Bamberg",  "Landkreis Bayreuth", "Landkreis Coburg", "Landkreis Fürth", "Landkreis Hof", "Landkreis Landshut", "Landkreis München", "Landkreis Passau", "Landkreis Regensburg", "Landsberg am Lech",  "Landshut",                           
        "Lörrach", "Miesbach", "Mühldorf am Inn", "München",  "Neuburg-Schrobenhausen", "Neumarkt in der Oberpfalz", "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab",  "Nürnberg",  "Nürnberger Land",  "Ortenaukreis",  "Passau",                             
        "Ravensburg", "Regen",  "Regensburg", "Reutlingen",  "Rhön-Grabfeld", "Rosenheim", "Roth",  "Rottal-Inn", "Rottweil",
        "Schwabach", "Schwandorf",  "Schwarzwald-Baar-Kreis", "Schweinfurt",  "Sigmaringen", "Straubing", "Straubing-Bogen",  "Tirschenreuth", "Traunstein",                         
        "Tuttlingen",  "Ulm",  "Waldshut ", 
        "Weiden in der Oberpfalz", "Weilheim-Schongau",  "Weißenburg-Gunzenhausen",            
        "Wunsiedel im Fichtelgebirge", "Würzburg", "Zollernalbkreis",
        "Altenburger Land",   "Altmarkkreis Salzwedel",   "Anhalt-Bitterfeld",  "Augsburg",                        
        "Bautzen",  "Berlin",   "Börde", "Brandenburg an der Havel",        
        "Burgenlandkreis",  "Chemnitz",  "Dahme-Spreewald", "Dessau-Roßlau",                   
        "Dillingen an der Donau", "Donau-Ries",  "Dresden", "Eichsfeld",                       
        "Elbe-Elster",  "Erfurt", "Erzgebirgskreis",  "Frankfurt (Oder)",                
        "Gera",  "Görlitz", "Gotha",  "Greiz",                           
        "Günzburg",    "Halle (Saale)",  "Harz",  "Hildburghausen",                  
        "Ilm-Kreis", "Jena",  "Jerichower Land", "Kaufbeuren",                      
        "Kempten (Allgäu)",  "Landkreis Augsburg",  "Landkreis Leipzig",   "Landkreis Rostock",               
        "Landkreis Schweinfurt" , "Landkreis Würzburg" , "Leipzig",  "Ludwigslust-Parchim",             
        "Magdeburg",  "Main-Spessart",  "Märkisch-Oderland",  "Mecklenburgische Seenplatte",     
        "Meißen",   "Memmingen",     "Merzig-Wadern", "Miltenberg",                      
        "Mittelsachsen",  "Neu-Ulm", "Neunkirchen",  "Nordsachsen",                     
        "Nordwestmecklenburg",  "Oberallgäu",   "Oberhavel",   "Oberspreewald-Lausitz",           
        "Oder-Spree",   "Ostprignitz-Ruppin", "Potsdam",  "Potsdam-Mittelmark",              
        "Prignitz",  "Regionalverband Saarbrücken", "Rostock",  "Saale-Orla-Kreis",                
        "Saalekreis",  "Saalfeld-Rudolstadt" , "Saarlouis" ,  "Sächsische Schweiz-Osterzgebirge",
        "Salzlandkreis",   "Schmalkalden-Meiningen",  "Schwerin",  "Sömmerda",                        
        "Sonneberg",  "Spree-Neiße",  "Stendal",  "Suhl",                            
        "Teltow-Fläming",  "Uckermark",  "Unstrut-Hainich-Kreis",  "Vogtlandkreis",                   
        "Vorpommern-Greifswald", "Vorpommern-Rügen",  "Wartburgkreis",  "Weimar",                          
        "Weimarer Land",   "Wittenberg",  "Zwickau"
        ]
    if chosen_model == "cities_MeckPomm":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin", "Vorpommern-Greifswald", "Ludwigslust-Parchim", "Nordwestmecklenburg", "Mecklenburgische Seenplatte", "Rostock", "Vorpommern-Rügen",
       "Nordsachsen", "Meißen", "Bautzen", "Görlitz", "Mittelsachsen", "Chemnitz", "Zwickau", "Vogtlandkreis", "Erzgebirgskreis", "Potsdam", "Frankfurt am Main"]
    if chosen_model == "large":
        federalStates = ["Ahrweiler", "Alb-Donau-Kreis", "Altmarkkreis Salzwedel",             
        "Altötting", "Alzey-Worms", "Amberg",
        "Amberg-Sulzbach", "Anhalt-Bitterfeld" , "Aurich",                             
        "Bad Dürkheim", "Bad Kissingen", "Bad Kreuznach",                      
        "Baden-Baden",  "Bautzen",  "Berchtesgadener Land",               
        "Berlin", "Bernkastel-Wittlich", "Bielefeld",                          
        "Birkenfeld", "Böblingen","Bodenseekreis",                      
        "Bonn", "Borken", "Braunschweig",                       
        "Breisgau-Hochschwarzwald", "Bremen",  "Bremerhaven",                        
        "Burgenlandkreis", "Calw", "Celle",                              
        "Chemnitz", "Cloppenburg", "Cochem-Zell",                        
        "Coesfeld", "Cuxhaven",  "Dachau",                             
        "Darmstadt-Dieburg", "Deggendorf", "Delmenhorst",                        
        "Dessau-Roßlau", "Diepholz", "Dillingen an der Donau",             
        "Dingolfing-Landau", "Dithmarschen", "Donau-Ries",                         
        "Donnersbergkreis", "Dortmund","Dresden",                           
        "Duisburg",  "Düren", "Düsseldorf",                         
        "Ebersberg", "Eichstätt", "Eifelkreis Bitburg-Prüm",            
        "Elbe-Elster", "Emden", "Emmendingen",                        
        "Emsland", "Ennepe-Ruhr-Kreis", "Enzkreis",                           
        "Erding", "Erfurt", "Erlangen",                           
        "Erlangen-Höchstadt", "Erzgebirgskreis", "Essen",                              
        "Esslingen", "Euskirchen", "Flensburg",                          
        "Forchheim", "Frankfurt am Main", "Freiburg im Breisgau",               
        "Freising", "Freudenstadt", "Freyung-Grafenau",                   
        "Friesland", "Fulda", "Fürstenfeldbruck",                   
        "Garmisch-Partenkirchen",  "Gießen", "Gifhorn",                            
        "Görlitz", "Goslar", "Göttingen",                          
        "Günzburg", "Gütersloh", "Halle (Saale)",                      
        "Hamburg", "Hannover", "Harz",                               
        "Haßberge", "Heidekreis", "Heidenheim",                         
        "Heinsberg", "Helmstedt", "Herford",                            
        "Hersfeld-Rotenburg", "Herzogtum Lauenburg", "Hildesheim",                         
        "Hochsauerlandkreis", "Hohenlohekreis", "Holzminden",                         
        "Höxter", "Ingolstadt", "Karlsruhe",                          
        "Kaufbeuren", "Kempten (Allgäu)", "Kiel",                               
        "Kitzingen", "Kleve", "Köln",                               
        "Konstanz",  "Krefeld", "Kronach",                            
        "Lahn-Dill-Kreis", "Landsberg am Lech", "Leer",                               
        "Leipzig", "Leverkusen","Limburg-Weilburg",                   
        "Lippe", "Lörrach","Lübeck",                             
        "Ludwigsburg", "Ludwigslust-Parchim", "Lüneburg",                           
        "Magdeburg", "Main-Kinzig-Kreis", "Main-Spessart",                      
        "Mainz-Bingen", "Mannheim", "Marburg-Biedenkopf",                 
        "Märkisch-Oderland",  "Märkischer Kreis", "Mecklenburgische Seenplatte",        
        "Meißen", "Memmingen", "Merzig-Wadern",                      
        "Mettmann", "Miesbach", "Miltenberg",                         
        "Minden-Lübbecke", "Mittelsachsen", "Mönchengladbach",                    
        "Mühldorf am Inn", "Mülheim an der Ruhr", "München",                            
        "Münster", "Neckar-Odenwald-Kreis", "Neuburg-Schrobenhausen",             
        "Neumarkt in der Oberpfalz", "Neumünster", "Neunkirchen",                        
        "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab", "Neuwied",                            
        "Nordfriesland", "Nordsachsen", "Nordwestmecklenburg",
        "Nürnberg", "Oberallgäu", "Oberbergischer Kreis",               
        "Oberspreewald-Lausitz", "Odenwaldkreis", "Offenbach",                         
        "Offenbach am Main", "Oldenburg", "Olpe",                               
        "Ortenaukreis", "Osnabrück", "Ostalbkreis",                        
        "Osterholz", "Ostholstein", "Ostprignitz-Ruppin",                 
        "Paderborn", "Pforzheim", "Pinneberg",                          
        "Plön", "Potsdam", "Potsdam-Mittelmark",                 
        "Prignitz",  "Rastatt", "Ravensburg",                         
        "Recklinghausen", "Regen",  "Regionalverband Saarbrücken",        
        "Remscheid", "Rendsburg-Eckernförde", "Reutlingen",                         
        "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rhein-Neuss",                        
        "Rhein-Sieg-Kreis",  "Rostock", "Rotenburg (Wümme)",                  
        "Roth", "Rottal-Inn", "Rottweil",                           
        "Saalekreis", "Saarlouis",   "Salzgitter",                         
        "Salzlandkreis",  "Schaumburg", "Schleswig-Flensburg",                
        "Schwalm-Eder-Kreis", "Schwandorf", "Schwarzwald-Baar-Kreis",             
        "Schwerin", "Siegen-Wittgenstein","Sigmaringen",                        
        "Soest", "Spree-Neiße", "Stade",                              
        "Städteregion Aachen", "Steinburg", "Steinfurt",                          
        "Stendal", "Straubing", "Straubing-Bogen",                    
        "Stuttgart", "Südliche Weinstraße", "Südwestpfalz",                       
        "Teltow-Fläming", "Tirschenreuth", "Traunstein",                         
        "Trier-Saarburg", "Tuttlingen",  "Uckermark",                          
        "Uelzen", "Ulm", "Unna",                               
        "Viersen", "Vogelsbergkreis","Vogtlandkreis",                      
        "Vorpommern-Greifswald", "Vorpommern-Rügen", "Waldeck-Frankenberg",                
        "Waldshut", "Warendorf", "Weiden in der Oberpfalz",            
        "Weilheim-Schongau","Weißenburg-Gunzenhausen","Wiesbaden" ,                         
        "Wilhelmshaven", "Wittenberg", "Wittmund",                           
        "Wolfsburg", "Wunsiedel im Fichtelgebirge", "Wuppertal",                          
        "Zollernalbkreis", "Zwickau"  
        ]
    if chosen_model == "cities_non_hierarchical":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin"]
    if chosen_model == "countieswithproblems":
        federalStates = [
            "Berlin", "Bremen", "Hamburg", "Stuttgart", "München", "Köln",              
            "Frankfurt am Main", "Düsseldorf", "Leipzig", "Essen", "Dortmund", "Dresden",          
            "Nürnberg", "Duisburg", "Helmstedt", "Holzminden", "Schaumburg", "Delmenhorst",      
            "Wilhelmshaven", "Emsland", "Leer", "Oldenburg", "Bremerhaven"
        ]
        
    for i, c in enumerate(federalStates):
            # --- base parameters ---
        if len(indicators_in) == 0:
            fig, axs = plt.subplots(1, 8, figsize=(18, 3))
        if len(indicators_in) == 1:
            fig, axs = plt.subplots(2, 12, figsize=(30, 10))
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

        if school_in:
            cov19.plot.distribution( 
                model_in, trace_in.sel(fedState=i), "theta_v", dist_math="\\theta_{v}", ax=axs[1]
            )
            cov19.plot.distribution( 
                model_in, trace_in, "mu_vac", dist_math="mu_vac", ax=axs[2]
            )
        if holiday_in:
            cov19.plot.distribution( 
                model_in, trace_in.sel(fedState=i), "theta_h", dist_math="\\theta_{h}", ax=axs[3]
            )
            cov19.plot.distribution( 
                model_in, trace_in, "mu_hol", dist_math="\\mu_{hol}", ax=axs[4]
            )
        
        cov19.plot.distribution( 
            model_in, trace_in, "sigma_model", dist_math="\\sigma_{model}", ax=axs[5]
        )
        
        if temperature_in:
            cov19.plot.distribution( 
                model_in, trace_in.sel(fedState=i), "amplitude_temperature", dist_math="amplitude_{temperature}", ax=axs[6]
            )
            cov19.plot.distribution( 
                model_in, trace_in, "mu_amp_temp", dist_math="\\mu_amp_{temp}", ax=axs[7]
            )
            
            cov19.plot.distribution( 
                model_in, trace_in.sel(fedState=i), "shift_temperature", dist_math="shift_{temperature}", ax=axs[8]
            )
            cov19.plot.distribution( 
                model_in, trace_in, "mu_shift_temp", dist_math="\\mu_shift_{temp}", ax=axs[9]
            )
            
            cov19.plot.distribution( 
                model_in, trace_in.sel(fedState=i), "slope_temperature", dist_math="slope_{temperature}", ax=axs[10]
            )
            cov19.plot.distribution( 
                model_in, trace_in, "mu_slope_temp", dist_math="\\mu_slope_{temp}", ax=axs[11]
            )

    # disease
        j = 12
        for indicator in indicators_in:
            cov19.plot.distribution( 
                model_in, trace_in, "mu_incidence_weight_param_sigma", dist_math="mu_incidence_weight_param_sigma", ax=axs[j]
            )
            
            cov19.plot.distribution( 
                model_in, trace_in.sel(incidence_weight_dim_1=i), "incidence_weight", dist_math="incidence_weight", ax=axs[j+1]
            )
            
            cov19.plot.distribution( 
            model_in, trace_in.sel(fedState=i), f"mu_{indicator}", dist_math=f"mu_{indicator}", ax=axs[j+2]
            )
            cov19.plot.distribution( 
            model_in, trace_in.sel(fedState=i), f"mu_gamma_log_{indicator}", dist_math=f"mu_gamma_log_{indicator}", ax=axs[j+3]
            )
            cov19.plot.distribution( 
            model_in, trace_in, f"mu_gamma_{indicator}", dist_math=f"mu_gamma_{{{indicator}}}", ax=axs[j+4]
            )
            cov19.plot.distribution( 
            model_in, trace_in, f"sigma_gamma_{indicator}", dist_math=f"sigma_gamma_{indicator}", ax=axs[j+5]
            )
            cov19.plot.distribution(
                model_in, trace_in.sel(fedState=i), f"multiplicator_{indicator}", dist_math=f"multiplicator_{{{indicator}}}", ax=axs[j+6]
            )
            cov19.plot.distribution(
                model_in, trace_in, f"mu_multiplicator_{indicator}", dist_math=f"mu_multiplicator_{{{indicator}}}", ax=axs[j+7]
            )
            # cov19.plot.distribution(
            #     model_in, trace_in.sel(fedState=i), f"shift_{indicator}", dist_math=f"shift_{{{indicator}}}", ax=axs[i+3]
            # )
            cov19.plot.distribution(
                model_in, trace_in.sel(fedState=i), f"slope_{indicator}", dist_math=f"slope_{{{indicator}}}", ax=axs[j+8]
            )
            cov19.plot.distribution(
                model_in, trace_in, f"mu_slope_{indicator}", dist_math=f"mu_slope_{{{indicator}}}", ax=axs[j+9]
            )
            cov19.plot.distribution(
                model_in, trace_in, f"sigma_slope_{indicator}", dist_math=f"sigma_slope_{indicator}", ax=axs[j+10]
            )
            
            # cov19.plot.distribution(
            #     model_in, trace_in.sel(fedState=i), f"intercept_{indicator}", dist_math=f"intercept_{{{indicator}}}", ax=axs[j+7]
            # )
            # cov19.plot.distribution(
            #     model_in, trace_in, f"mu_intercept_{indicator}", dist_math=f"mu_intercept_{{{indicator}}}", ax=axs[j+8]
            # )
            i += 10

        plotnamepng= f"{tag_in}/" + c + "-distributions.png"
        plotnamepdf = f"{tag_in}/" + c + "-distributions.pdf"

        fig.savefig(plotnamepng, dpi=300, bbox_inches="tight")
        fig.savefig(plotnamepdf, dpi=300, bbox_inches="tight")
    # for indicator in indicators:
    #     axes = az.plot_forest(trace_in,
    #                        kind='forestplot',
    #                        var_names=[f"slope_{indicator}", f"multiplicator_{indicator}", f"intercept_{indicator}"],
    #                        filter_vars="regex",
    #                        combined=True,
    #                        figsize=(4, len(federalStates)))
    #     axes[0].set_title('Estimated Disease parameters')
    #     figure = axes.ravel()[0].figure

    #     figure.savefig(
    #                 f"{tag_in}/" + f"{indicator}" + "_distributions.png",
    #                 dpi=300,
    #                 bbox_inches="tight",
    #     )
    # # --- School vacation and holdiays --- 
    # if school_in:
    #     if holiday_in: 
    #         axes = az.plot_forest(trace_in,
    #                        kind='forestplot',
    #                        var_names=["theta_v", "theta_h"],
    #                        filter_vars="regex",
    #                        combined=True,
    #                        figsize=(4, 4))
    #         axes[0].set_title('Estimated School Vac./Pub Holiday parameters')
    #         figure = axes.ravel()[0].figure

    #         figure.savefig(
    #                 f"{tag_in}/" + "SchoolPubHol_distributions.png",
    #                 dpi=300,
    #                 bbox_inches="tight",
    #         )

    # # --- temperature ---
    # if temperature_in:
    #     # for i, c in enumerate(federalStates):
    #     #     fig, axs = plt.subplots(1, 4, figsize=(12, 3))
    #     #     axs = axs.flatten()
        
    #     #     cov19.plot.distribution(model_in, trace_in.sel(fedState=i), "amplitude_temperature", nSamples_prior=100, dist_math="amplitude-temp", ax=axs[0])

    #     #     cov19.plot.distribution(model_in, trace_in.sel(fedState=i), "intercept_temperature", dist_math="intercept-temp", ax=axs[1])
        
    #     #     cov19.plot.distribution(model_in, trace_in.sel(fedState=i), "shift_temperature", dist_math="shift-temp", ax=axs[2])

    #     #     cov19.plot.distribution(model_in, trace_in.sel(fedState=i), "slope_temperature", dist_math="slope-temp", ax=axs[3])

    #     #     # save figure
    #     #     plotnamepng= f"{tag_in}/" + c + "-distributions_temperature.png"
    #     #     plotnamepdf = f"{tag_in}/" + c + "-distributions_temperature.pdf"

    #     #     fig.savefig(
    #     #         plotnamepng,
    #     #         dpi=300,
    #     #         bbox_inches="tight",
    #     #     )
    #     #     fig.savefig(
    #     #         plotnamepdf,
    #     #         dpi=300,
    #     #         bbox_inches="tight",
    #     # )

    #     axes = az.plot_forest(trace_in,
    #                        kind='forestplot',
    #                        var_names=["temperature$"],
    #                        filter_vars="regex",
    #                        combined=True,
    #                        figsize=(4, 4))
    #     axes[0].set_title('Estimated temperature parameters')
    #     figure = axes.ravel()[0].figure

    #     figure.savefig(
    #                 f"{tag_in}/" + "temperature_distributions.png",
    #                 dpi=300,
    #                 bbox_inches="tight",
    #     )

    # # # --- daylight ---
    # if daylight_in:
    #     # for i, c in enumerate(federalStates):
    #     #     fig, axs = plt.subplots(1, 4, figsize=(12, 3))
    #     #     axs = axs.flatten()
    #     #     #cov19.plot.distribution(model_in, trace_in, "z_T", dist_math="z_{T}", ax=axs[0])
        
    #     #     cov19.plot.distribution(model_in, trace_in.sel(fedState=i), "amplitude_daylight", dist_math="amplitude-day", ax=axs[0])

    #     #     cov19.plot.distribution(model_in, trace_in.sel(fedState=i), "shift_daylight", dist_math="shift-day", ax=axs[1])
            
    #     #     cov19.plot.distribution(model_in, trace_in.sel(fedState=i), "intercept_daylight", dist_math="intercept-day", ax=axs[2])

    #     #     cov19.plot.distribution(model_in, trace_in.sel(fedState=i), "slope_daylight", dist_math="slope-day", ax=axs[3])
        
    #     #     plotnamepng= f"{tag_in}/" + c + "-distributions_daylight.png"
    #     #     plotnamepdf = f"{tag_in}/" + c + "-distributions_daylight.pdf"

    #     #     fig.savefig(
    #     #         plotnamepng,
    #     #         dpi=300,
    #     #         bbox_inches="tight",
    #     #     )
    #     #     fig.savefig(
    #     #         plotnamepdf,
    #     #         dpi=300,
    #     #         bbox_inches="tight",
    #     #     )

    #     axes = az.plot_forest(trace_in,
    #                        kind='forestplot',
    #                        var_names=["daylight$"],
    #                        filter_vars="regex",
    #                        combined=True,
    #                        figsize=(4, 4))
    #     axes[0].set_title('Estimated daylight parameters')
    #     figure = axes.ravel()[0].figure

    #     figure.savefig(
    #                 f"{tag_in}/" + "daylight_distributions.png",
    #                 dpi=300,
    #                 bbox_inches="tight",
    #     )
    
    ## plot temperature time series
def plot_disease_timeseries(dates_in, trace_in, tag_in, indicators, disease_data, disease_data_raw, chosen_model, mix_incidence):
    if chosen_model == "BEHHHB":
        federalStates = (
       "Berlin", "Bremen", "Hamburg")
    if chosen_model == "fedStates":
        federalStates = [
       "Baden-Württemberg", "Bayern", "Berlin", "Brandenburg", "Bremen",
       "Hamburg", "Hessen", "Mecklenburg-Vorpommern", "Niedersachsen",
       "Nordrhein-Westfalen", "Rheinland-Pfalz", "Saarland", "Sachsen",
       "Sachsen-Anhalt", "Schleswig-Holstein", "Thüringen"]
    if chosen_model == "fedStates_nat":
        federalStates = [
       "Baden-Württemberg", "Bayern", "Berlin", "Brandenburg", "Bremen",
       "Hamburg", "Hessen", "Mecklenburg-Vorpommern", "Niedersachsen",
       "Nordrhein-Westfalen", "Rheinland-Pfalz", "Saarland", "Sachsen",
       "Sachsen-Anhalt", "Schleswig-Holstein", "Thüringen"]
    if chosen_model == "firsthundred":
        federalStates = ["Aurich","Bielefeld","Bonn","Borken","Braunschweig","Bremen","Bremerhaven",          
        "Celle","Cloppenburg", "Coesfeld", "Cuxhaven", "Delmenhorst", "Diepholz", "Dithmarschen",         
        "Duisburg","Düren", "Düsseldorf", "Emden", "Emsland", "Essen","Euskirchen",           
        "Flensburg","Friesland", "Gifhorn", "Goslar", "Göttingen", "Gütersloh", "Hamburg",              
        "Hameln-Pyrmont","Hannover", "Harburg", "Heidekreis", "Heinsberg", "Helmstedt", "Herford",              
        "Herzogtum Lauenburg","Hildesheim", "Holzminden", "Kiel", "Kleve", "Krefeld", "Köln",                 
        "Landkreis Oldenburg","Landkreis Osnabrück","Leer",  "Leverkusen", "Lübeck", "Lüchow-Dannenberg", "Lüneburg",             
        "Mettmann","Mönchengladbach","Mülheim an der Ruhr", "Münster", "Neumünster", "NienburgWeser", "Nordfriesland",        
        "Oberbergischer Kreis","Oldenburg" , "Osnabrück", "Osterholz", "Ostholstein", "Pinneberg", "Plön",                 
        "Recklinghausen", "Remscheid","Rendsburg-Eckernförde", "Rhein-Neuss", "Rhein-Sieg-Kreis", "Rotenburg (Wümme)", "Salzgitter",           
        "Schaumburg", "Schleswig-Flensburg","Segeberg", "Stade", "Steinburg", "Steinfurt", "Städteregion Aachen",  
        "Uelzen", "Viersen", "Warendorf", "Wilhelmshaven", "Wittmund", "Wolfsburg", "Wuppertal"]
    if chosen_model == "secondhundred":
        federalStates = ["Ahrweiler",   "Altenkirchen",  "Alzey-Worms",  "Bad Dürkheim" , "Bad Kreuznach" , "Baden-Baden",
                         "Bernkastel-Wittlich", "Birkenfeld",  "Böblingen", "Cochem-Zell", "Darmstadt-Dieburg", "Donnersbergkreis", "Dortmund",  "Eifelkreis Bitburg-Prüm",  "Ennepe-Ruhr-Kreis", "Esslingen",  
                         "Frankenthal (Pfalz)",  "Frankfurt am Main", "Fulda",  "Gießen", "Groß-Gerau", "Heidenheim",  "Heilbronn", 
                         "Hersfeld-Rotenburg", "Hochsauerlandkreis", "Hochtaunuskreis",   "Hohenlohekreis", "Höxter", "Kaiserslautern", "Karlsruhe", "Kassel", "Koblenz",   "Lahn-Dill-Kreis", "Landau in der Pfalz",  "Landkreis Heilbronn", "Landkreis Karlsruhe",
                         "Limburg-Weilburg",  "Lippe",  "Ludwigsburg" ,  "Main-Kinzig-Kreis", "Main-Tauber-Kreis", "Mainz",   "Mainz-Bingen",  "Mannheim",  "Marburg-Biedenkopf", "Mayen-Koblenz", "Minden-Lübbecke", "Märkischer Kreis",
                         "Neckar-Odenwald-Kreis", "Neustadt an der Weinstraße",  "Neuwied", "Odenwaldkreis", "Offenbach",                  "Offenbach am Main",  "Olpe", "Ostalbkreis", "Paderborn", "Pforzheim", "Pirmasens",  "Rastatt", "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rheingau-Taunus-Kreis", "Schwalm-Eder-Kreis",
                         "Schwäbisch Hall", "Siegen-Wittgenstein", "Soest" , "Speyer" ,  "Stuttgart", "Südliche Weinstraße", "Südwestpfalz",              "Trier",   "Trier-Saarburg",  "Unna",  "Vogelsbergkreis", "Waldeck-Frankenberg", "Werra-Meißner-Kreis",  "Westerwaldkreis", "Wiesbaden",  "Worms", "Zweibrücken"]
    if chosen_model == "thirdhundred":
        federalStates = ["Alb-Donau-Kreis",  "Altötting", "Amberg", "Amberg-Sulzbach",  "Ansbach", "Aschaffenburg", "Bad Kissingen", "Bamberg",  "Bayreuth", "Berchtesgadener Land", "Biberach", "Bodenseekreis", "Breisgau-Hochschwarzwald", "Calw", "Cham",                               
        "Coburg", "Dachau", "Deggendorf", "Dingolfing-Landau",  "Ebersberg", "Eichstätt", "Emmendingen",  "Enzkreis", "Erding", "Erlangen",  "Erlangen-Höchstadt", "Forchheim", "Freiburg im Breisgau", "Freising", "Freudenstadt", "Freyung-Grafenau", "Fürstenfeldbruck", "Fürth", "Garmisch-Partenkirchen", "Haßberge", "Hof", "Ingolstadt", "Kelheim", "Kitzingen", "Konstanz",  "Kronach", "Landkreis Ansbach", "Landkreis Aschaffenburg", "Landkreis Bamberg",  "Landkreis Bayreuth", "Landkreis Coburg", "Landkreis Fürth", "Landkreis Hof", "Landkreis Landshut", "Landkreis München", "Landkreis Passau", "Landkreis Regensburg", "Landsberg am Lech",  "Landshut",                           
        "Lörrach", "Miesbach", "Mühldorf am Inn", "München",  "Neuburg-Schrobenhausen", "Neumarkt in der Oberpfalz", "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab",  "Nürnberg",  "Nürnberger Land",  "Ortenaukreis",  "Passau",                             
        "Ravensburg", "Regen",  "Regensburg", "Reutlingen",  "Rhön-Grabfeld", "Rosenheim", "Roth",  "Rottal-Inn", "Rottweil",
        "Schwabach", "Schwandorf",  "Schwarzwald-Baar-Kreis", "Schweinfurt",  "Sigmaringen", "Straubing", "Straubing-Bogen",  "Tirschenreuth", "Traunstein",                         
        "Tuttlingen",  "Ulm",  "Waldshut ", 
        "Weiden in der Oberpfalz", "Weilheim-Schongau",  "Weißenburg-Gunzenhausen",            
        "Wunsiedel im Fichtelgebirge", "Würzburg", "Zollernalbkreis"]   
    if chosen_model == "fourthhundred":
        federalStates = ["Altenburger Land",   "Altmarkkreis Salzwedel",   "Anhalt-Bitterfeld",  "Augsburg",                        
        "Bautzen",  "Berlin",   "Börde", "Brandenburg an der Havel",        
        "Burgenlandkreis",  "Chemnitz",  "Dahme-Spreewald", "Dessau-Roßlau",                   
        "Dillingen an der Donau", "Donau-Ries",  "Dresden", "Eichsfeld",                       
        "Elbe-Elster",  "Erfurt", "Erzgebirgskreis",  "Frankfurt (Oder)",                
        "Gera",  "Görlitz", "Gotha",  "Greiz",                           
        "Günzburg",    "Halle (Saale)",  "Harz",  "Hildburghausen",                  
        "Ilm-Kreis", "Jena",  "Jerichower Land", "Kaufbeuren",                      
        "Kempten (Allgäu)",  "Landkreis Augsburg",  "Landkreis Leipzig",   "Landkreis Rostock",               
        "Landkreis Schweinfurt" , "Landkreis Würzburg" , "Leipzig",  "Ludwigslust-Parchim",             
        "Magdeburg",  "Main-Spessart",  "Märkisch-Oderland",  "Mecklenburgische Seenplatte",     
        "Meißen",   "Memmingen",     "Merzig-Wadern", "Miltenberg",                      
        "Mittelsachsen",  "Neu-Ulm", "Neunkirchen",  "Nordsachsen",                     
        "Nordwestmecklenburg",  "Oberallgäu",   "Oberhavel",   "Oberspreewald-Lausitz",           
        "Oder-Spree",   "Ostprignitz-Ruppin", "Potsdam",  "Potsdam-Mittelmark",              
        "Prignitz",  "Regionalverband Saarbrücken", "Rostock",  "Saale-Orla-Kreis",                
        "Saalekreis",  "Saalfeld-Rudolstadt" , "Saarlouis" ,  "Sächsische Schweiz-Osterzgebirge",
        "Salzlandkreis",   "Schmalkalden-Meiningen",  "Schwerin",  "Sömmerda",                        
        "Sonneberg",  "Spree-Neiße",  "Stendal",  "Suhl",                            
        "Teltow-Fläming",  "Uckermark",  "Unstrut-Hainich-Kreis",  "Vogtlandkreis",                   
        "Vorpommern-Greifswald", "Vorpommern-Rügen",  "Wartburgkreis",  "Weimar",                          
        "Weimarer Land",   "Wittenberg",  "Zwickau"]
    if chosen_model == "firstsecondhundred":
        federalStates = ["Aurich","Bielefeld","Bonn","Borken","Braunschweig","Bremen","Bremerhaven",          
        "Celle","Cloppenburg", "Coesfeld", "Cuxhaven", "Delmenhorst", "Diepholz", "Dithmarschen",         
        "Duisburg","Düren", "Düsseldorf", "Emden", "Emsland", "Essen","Euskirchen",           
        "Flensburg","Friesland", "Gifhorn", "Goslar", "Göttingen", "Gütersloh", "Hamburg",              
        "Hameln-Pyrmont","Hannover", "Harburg", "Heidekreis", "Heinsberg", "Helmstedt", "Herford",              
        "Herzogtum Lauenburg","Hildesheim", "Holzminden", "Kiel", "Kleve", "Krefeld", "Köln",                 
        "Landkreis Oldenburg","Landkreis Osnabrück","Leer",  "Leverkusen", "Lübeck", "Lüchow-Dannenberg", "Lüneburg",             
        "Mettmann","Mönchengladbach","Mülheim an der Ruhr", "Münster", "Neumünster", "NienburgWeser", "Nordfriesland",        
        "Oberbergischer Kreis","Oldenburg" , "Osnabrück", "Osterholz", "Ostholstein", "Pinneberg", "Plön",                 
        "Recklinghausen", "Remscheid","Rendsburg-Eckernförde", "Rhein-Neuss", "Rhein-Sieg-Kreis", "Rotenburg (Wümme)", "Salzgitter",           
        "Schaumburg", "Schleswig-Flensburg","Segeberg", "Stade", "Steinburg", "Steinfurt", "Städteregion Aachen",  
        "Uelzen", "Viersen", "Warendorf", "Wilhelmshaven", "Wittmund", "Wolfsburg", "Wuppertal",
        "Ahrweiler",   "Altenkirchen",  "Alzey-Worms",  "Bad Dürkheim" , "Bad Kreuznach" , "Baden-Baden",
        "Bernkastel-Wittlich", "Birkenfeld",  "Böblingen", "Cochem-Zell", "Darmstadt-Dieburg", "Donnersbergkreis", "Dortmund",  "Eifelkreis Bitburg-Prüm",  "Ennepe-Ruhr-Kreis", "Esslingen",  
        "Frankenthal (Pfalz)",  "Frankfurt am Main", "Fulda",  "Gießen", "Groß-Gerau", "Heidenheim",  "Heilbronn", 
        "Hersfeld-Rotenburg", "Hochsauerlandkreis", "Hochtaunuskreis",   "Hohenlohekreis", "Höxter", "Kaiserslautern", "Karlsruhe", "Kassel", "Koblenz",   "Lahn-Dill-Kreis", "Landau in der Pfalz",  "Landkreis Heilbronn", "Landkreis Karlsruhe",
        "Limburg-Weilburg",  "Lippe",  "Ludwigsburg" ,  "Main-Kinzig-Kreis", "Main-Tauber-Kreis", "Mainz",   "Mainz-Bingen",  "Mannheim",  "Marburg-Biedenkopf", "Mayen-Koblenz", "Minden-Lübbecke", "Märkischer Kreis",
        "Neckar-Odenwald-Kreis", "Neustadt an der Weinstraße",  "Neuwied", "Odenwaldkreis", "Offenbach", "Offenbach am Main",  "Olpe", "Ostalbkreis", "Paderborn", "Pforzheim", "Pirmasens",  "Rastatt", "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rheingau-Taunus-Kreis", "Schwalm-Eder-Kreis",
        "Schwäbisch Hall", "Siegen-Wittgenstein", "Soest" , "Speyer" ,  "Stuttgart", "Südliche Weinstraße", "Südwestpfalz", "Trier",   "Trier-Saarburg",  "Unna",  "Vogelsbergkreis", "Waldeck-Frankenberg", "Werra-Meißner-Kreis",  "Westerwaldkreis", "Wiesbaden",  "Worms", "Zweibrücken"
        ]
    if chosen_model == "thirdfourthhundred":
        federalStates = ["Alb-Donau-Kreis",  "Altötting", "Amberg", "Amberg-Sulzbach",  "Ansbach", "Aschaffenburg", "Bad Kissingen", "Bamberg",  "Bayreuth", "Berchtesgadener Land", "Biberach", "Bodenseekreis", "Breisgau-Hochschwarzwald", "Calw", "Cham",                               
        "Coburg", "Dachau", "Deggendorf", "Dingolfing-Landau",  "Ebersberg", "Eichstätt", "Emmendingen",  "Enzkreis", "Erding", "Erlangen",  "Erlangen-Höchstadt", "Forchheim", "Freiburg im Breisgau", "Freising", "Freudenstadt", "Freyung-Grafenau", "Fürstenfeldbruck", "Fürth", "Garmisch-Partenkirchen", "Haßberge", "Hof", "Ingolstadt", "Kelheim", "Kitzingen", "Konstanz",  "Kronach", "Landkreis Ansbach", "Landkreis Aschaffenburg", "Landkreis Bamberg",  "Landkreis Bayreuth", "Landkreis Coburg", "Landkreis Fürth", "Landkreis Hof", "Landkreis Landshut", "Landkreis München", "Landkreis Passau", "Landkreis Regensburg", "Landsberg am Lech",  "Landshut",                           
        "Lörrach", "Miesbach", "Mühldorf am Inn", "München",  "Neuburg-Schrobenhausen", "Neumarkt in der Oberpfalz", "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab",  "Nürnberg",  "Nürnberger Land",  "Ortenaukreis",  "Passau",                             
        "Ravensburg", "Regen",  "Regensburg", "Reutlingen",  "Rhön-Grabfeld", "Rosenheim", "Roth",  "Rottal-Inn", "Rottweil",
        "Schwabach", "Schwandorf",  "Schwarzwald-Baar-Kreis", "Schweinfurt",  "Sigmaringen", "Straubing", "Straubing-Bogen",  "Tirschenreuth", "Traunstein",                         
        "Tuttlingen",  "Ulm",  "Waldshut ", 
        "Weiden in der Oberpfalz", "Weilheim-Schongau",  "Weißenburg-Gunzenhausen",            
        "Wunsiedel im Fichtelgebirge", "Würzburg", "Zollernalbkreis",
        "Altenburger Land",   "Altmarkkreis Salzwedel",   "Anhalt-Bitterfeld",  "Augsburg",                        
        "Bautzen",  "Berlin",   "Börde", "Brandenburg an der Havel",        
        "Burgenlandkreis",  "Chemnitz",  "Dahme-Spreewald", "Dessau-Roßlau",                   
        "Dillingen an der Donau", "Donau-Ries",  "Dresden", "Eichsfeld",                       
        "Elbe-Elster",  "Erfurt", "Erzgebirgskreis",  "Frankfurt (Oder)",                
        "Gera",  "Görlitz", "Gotha",  "Greiz",                           
        "Günzburg",    "Halle (Saale)",  "Harz",  "Hildburghausen",                  
        "Ilm-Kreis", "Jena",  "Jerichower Land", "Kaufbeuren",                      
        "Kempten (Allgäu)",  "Landkreis Augsburg",  "Landkreis Leipzig",   "Landkreis Rostock",               
        "Landkreis Schweinfurt" , "Landkreis Würzburg" , "Leipzig",  "Ludwigslust-Parchim",             
        "Magdeburg",  "Main-Spessart",  "Märkisch-Oderland",  "Mecklenburgische Seenplatte",     
        "Meißen",   "Memmingen",     "Merzig-Wadern", "Miltenberg",                      
        "Mittelsachsen",  "Neu-Ulm", "Neunkirchen",  "Nordsachsen",                     
        "Nordwestmecklenburg",  "Oberallgäu",   "Oberhavel",   "Oberspreewald-Lausitz",           
        "Oder-Spree",   "Ostprignitz-Ruppin", "Potsdam",  "Potsdam-Mittelmark",              
        "Prignitz",  "Regionalverband Saarbrücken", "Rostock",  "Saale-Orla-Kreis",                
        "Saalekreis",  "Saalfeld-Rudolstadt" , "Saarlouis" ,  "Sächsische Schweiz-Osterzgebirge",
        "Salzlandkreis",   "Schmalkalden-Meiningen",  "Schwerin",  "Sömmerda",                        
        "Sonneberg",  "Spree-Neiße",  "Stendal",  "Suhl",                            
        "Teltow-Fläming",  "Uckermark",  "Unstrut-Hainich-Kreis",  "Vogtlandkreis",                   
        "Vorpommern-Greifswald", "Vorpommern-Rügen",  "Wartburgkreis",  "Weimar",                          
        "Weimarer Land",   "Wittenberg",  "Zwickau"] 
    if chosen_model == "fourhundred":
        federalStates = ["Aurich","Bielefeld","Bonn","Borken","Braunschweig","Bremen","Bremerhaven",          
        "Celle","Cloppenburg", "Coesfeld", "Cuxhaven", "Delmenhorst", "Diepholz", "Dithmarschen",         
        "Duisburg","Düren", "Düsseldorf", "Emden", "Emsland", "Essen","Euskirchen",           
        "Flensburg","Friesland", "Gifhorn", "Goslar", "Göttingen", "Gütersloh", "Hamburg",              
        "Hameln-Pyrmont","Hannover", "Harburg", "Heidekreis", "Heinsberg", "Helmstedt", "Herford",              
        "Herzogtum Lauenburg","Hildesheim", "Holzminden", "Kiel", "Kleve", "Krefeld", "Köln",                 
        "Landkreis Oldenburg","Landkreis Osnabrück","Leer",  "Leverkusen", "Lübeck", "Lüchow-Dannenberg", "Lüneburg",             
        "Mettmann","Mönchengladbach","Mülheim an der Ruhr", "Münster", "Neumünster", "NienburgWeser", "Nordfriesland",        
        "Oberbergischer Kreis","Oldenburg" , "Osnabrück", "Osterholz", "Ostholstein", "Pinneberg", "Plön",                 
        "Recklinghausen", "Remscheid","Rendsburg-Eckernförde", "Rhein-Neuss", "Rhein-Sieg-Kreis", "Rotenburg (Wümme)", "Salzgitter",           
        "Schaumburg", "Schleswig-Flensburg","Segeberg", "Stade", "Steinburg", "Steinfurt", "Städteregion Aachen",  
        "Uelzen", "Viersen", "Warendorf", "Wilhelmshaven", "Wittmund", "Wolfsburg", "Wuppertal",
        "Ahrweiler",   "Altenkirchen",  "Alzey-Worms",  "Bad Dürkheim" , "Bad Kreuznach" , "Baden-Baden",
        "Bernkastel-Wittlich", "Birkenfeld",  "Böblingen", "Cochem-Zell", "Darmstadt-Dieburg", "Donnersbergkreis", "Dortmund",  "Eifelkreis Bitburg-Prüm",  "Ennepe-Ruhr-Kreis", "Esslingen",  
        "Frankenthal (Pfalz)",  "Frankfurt am Main", "Fulda",  "Gießen", "Groß-Gerau", "Heidenheim",  "Heilbronn", 
        "Hersfeld-Rotenburg", "Hochsauerlandkreis", "Hochtaunuskreis",   "Hohenlohekreis", "Höxter", "Kaiserslautern", "Karlsruhe", "Kassel", "Koblenz",   "Lahn-Dill-Kreis", "Landau in der Pfalz",  "Landkreis Heilbronn", "Landkreis Karlsruhe",
        "Limburg-Weilburg",  "Lippe",  "Ludwigsburg" ,  "Main-Kinzig-Kreis", "Main-Tauber-Kreis", "Mainz",   "Mainz-Bingen",  "Mannheim",  "Marburg-Biedenkopf", "Mayen-Koblenz", "Minden-Lübbecke", "Märkischer Kreis",
        "Neckar-Odenwald-Kreis", "Neustadt an der Weinstraße",  "Neuwied", "Odenwaldkreis", "Offenbach", "Offenbach am Main",  "Olpe", "Ostalbkreis", "Paderborn", "Pforzheim", "Pirmasens",  "Rastatt", "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rheingau-Taunus-Kreis", "Schwalm-Eder-Kreis",
        "Schwäbisch Hall", "Siegen-Wittgenstein", "Soest" , "Speyer" ,  "Stuttgart", "Südliche Weinstraße", "Südwestpfalz", "Trier",   "Trier-Saarburg",  "Unna",  "Vogelsbergkreis", "Waldeck-Frankenberg", "Werra-Meißner-Kreis",  "Westerwaldkreis", "Wiesbaden",  "Worms", "Zweibrücken",
        "Alb-Donau-Kreis",  "Altötting", "Amberg", "Amberg-Sulzbach",  "Ansbach", "Aschaffenburg", "Bad Kissingen", "Bamberg",  "Bayreuth", "Berchtesgadener Land", "Biberach", "Bodenseekreis", "Breisgau-Hochschwarzwald", "Calw", "Cham",                               
        "Coburg", "Dachau", "Deggendorf", "Dingolfing-Landau",  "Ebersberg", "Eichstätt", "Emmendingen",  "Enzkreis", "Erding", "Erlangen",  "Erlangen-Höchstadt", "Forchheim", "Freiburg im Breisgau", "Freising", "Freudenstadt", "Freyung-Grafenau", "Fürstenfeldbruck", "Fürth", "Garmisch-Partenkirchen", "Haßberge", "Hof", "Ingolstadt", "Kelheim", "Kitzingen", "Konstanz",  "Kronach", "Landkreis Ansbach", "Landkreis Aschaffenburg", "Landkreis Bamberg",  "Landkreis Bayreuth", "Landkreis Coburg", "Landkreis Fürth", "Landkreis Hof", "Landkreis Landshut", "Landkreis München", "Landkreis Passau", "Landkreis Regensburg", "Landsberg am Lech",  "Landshut",                           
        "Lörrach", "Miesbach", "Mühldorf am Inn", "München",  "Neuburg-Schrobenhausen", "Neumarkt in der Oberpfalz", "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab",  "Nürnberg",  "Nürnberger Land",  "Ortenaukreis",  "Passau",                             
        "Ravensburg", "Regen",  "Regensburg", "Reutlingen",  "Rhön-Grabfeld", "Rosenheim", "Roth",  "Rottal-Inn", "Rottweil",
        "Schwabach", "Schwandorf",  "Schwarzwald-Baar-Kreis", "Schweinfurt",  "Sigmaringen", "Straubing", "Straubing-Bogen",  "Tirschenreuth", "Traunstein",                         
        "Tuttlingen",  "Ulm",  "Waldshut ", 
        "Weiden in der Oberpfalz", "Weilheim-Schongau",  "Weißenburg-Gunzenhausen",            
        "Wunsiedel im Fichtelgebirge", "Würzburg", "Zollernalbkreis",
        "Altenburger Land",   "Altmarkkreis Salzwedel",   "Anhalt-Bitterfeld",  "Augsburg",                        
        "Bautzen",  "Berlin",   "Börde", "Brandenburg an der Havel",        
        "Burgenlandkreis",  "Chemnitz",  "Dahme-Spreewald", "Dessau-Roßlau",                   
        "Dillingen an der Donau", "Donau-Ries",  "Dresden", "Eichsfeld",                       
        "Elbe-Elster",  "Erfurt", "Erzgebirgskreis",  "Frankfurt (Oder)",                
        "Gera",  "Görlitz", "Gotha",  "Greiz",                           
        "Günzburg",    "Halle (Saale)",  "Harz",  "Hildburghausen",                  
        "Ilm-Kreis", "Jena",  "Jerichower Land", "Kaufbeuren",                      
        "Kempten (Allgäu)",  "Landkreis Augsburg",  "Landkreis Leipzig",   "Landkreis Rostock",               
        "Landkreis Schweinfurt" , "Landkreis Würzburg" , "Leipzig",  "Ludwigslust-Parchim",             
        "Magdeburg",  "Main-Spessart",  "Märkisch-Oderland",  "Mecklenburgische Seenplatte",     
        "Meißen",   "Memmingen",     "Merzig-Wadern", "Miltenberg",                      
        "Mittelsachsen",  "Neu-Ulm", "Neunkirchen",  "Nordsachsen",                     
        "Nordwestmecklenburg",  "Oberallgäu",   "Oberhavel",   "Oberspreewald-Lausitz",           
        "Oder-Spree",   "Ostprignitz-Ruppin", "Potsdam",  "Potsdam-Mittelmark",              
        "Prignitz",  "Regionalverband Saarbrücken", "Rostock",  "Saale-Orla-Kreis",                
        "Saalekreis",  "Saalfeld-Rudolstadt" , "Saarlouis" ,  "Sächsische Schweiz-Osterzgebirge",
        "Salzlandkreis",   "Schmalkalden-Meiningen",  "Schwerin",  "Sömmerda",                        
        "Sonneberg",  "Spree-Neiße",  "Stendal",  "Suhl",                            
        "Teltow-Fläming",  "Uckermark",  "Unstrut-Hainich-Kreis",  "Vogtlandkreis",                   
        "Vorpommern-Greifswald", "Vorpommern-Rügen",  "Wartburgkreis",  "Weimar",                          
        "Weimarer Land",   "Wittenberg",  "Zwickau"
        ]
    if chosen_model == "cities":  
        federalStates = [
        "Berlin","Bielefeld","Bonn","Braunschweig","Bremen","Chemnitz",         
        "Dortmund","Dresden","Duisburg","Düsseldorf","Erfurt","Essen",            
        "Frankfurt am Main" "Halle (Saale)","Hamburg","Hannover","Karlsruhe","Kiel",             
        "Krefeld","Köln","Leipzig","Lübeck","Magdeburg","Mönchengladbach",  
        "München","Münster","Nürnberg","Oldenburg","Potsdam","Rostock",          
        "Stuttgart","Wiesbaden","Wuppertal"]
    if chosen_model == "cities_MeckPomm":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin", "Vorpommern-Greifswald", "Ludwigslust-Parchim", "Nordwestmecklenburg", "Mecklenburgische Seenplatte", "Rostock", "Vorpommern-Rügen",
       "Nordsachsen", "Meißen", "Bautzen", "Görlitz", "Mittelsachsen", "Chemnitz", "Zwickau", "Vogtlandkreis", "Erzgebirgskreis", "Potsdam", "Frankfurt am Main"]
    if chosen_model == "large":
        federalStates = ["Ahrweiler", "Alb-Donau-Kreis", "Altmarkkreis Salzwedel",             
        "Altötting", "Alzey-Worms", "Amberg",
        "Amberg-Sulzbach", "Anhalt-Bitterfeld" , "Aurich",                             
        "Bad Dürkheim", "Bad Kissingen", "Bad Kreuznach",                      
        "Baden-Baden",  "Bautzen",  "Berchtesgadener Land",               
        "Berlin", "Bernkastel-Wittlich", "Bielefeld",                          
        "Birkenfeld", "Böblingen","Bodenseekreis",                      
        "Bonn", "Borken", "Braunschweig",                       
        "Breisgau-Hochschwarzwald", "Bremen",  "Bremerhaven",                        
        "Burgenlandkreis", "Calw", "Celle",                              
        "Chemnitz", "Cloppenburg", "Cochem-Zell",                        
        "Coesfeld", "Cuxhaven",  "Dachau",                             
        "Darmstadt-Dieburg", "Deggendorf", "Delmenhorst",                        
        "Dessau-Roßlau", "Diepholz", "Dillingen an der Donau",             
        "Dingolfing-Landau", "Dithmarschen", "Donau-Ries",                         
        "Donnersbergkreis", "Dortmund","Dresden",                           
        "Duisburg",  "Düren", "Düsseldorf",                         
        "Ebersberg", "Eichstätt", "Eifelkreis Bitburg-Prüm",            
        "Elbe-Elster", "Emden", "Emmendingen",                        
        "Emsland", "Ennepe-Ruhr-Kreis", "Enzkreis",                           
        "Erding", "Erfurt", "Erlangen",                           
        "Erlangen-Höchstadt", "Erzgebirgskreis", "Essen",                              
        "Esslingen", "Euskirchen", "Flensburg",                          
        "Forchheim", "Frankfurt am Main", "Freiburg im Breisgau",               
        "Freising", "Freudenstadt", "Freyung-Grafenau",                   
        "Friesland", "Fulda", "Fürstenfeldbruck",                   
        "Garmisch-Partenkirchen",  "Gießen", "Gifhorn",                            
        "Görlitz", "Goslar", "Göttingen",                          
        "Günzburg", "Gütersloh", "Halle (Saale)",                      
        "Hamburg", "Hannover", "Harz",                               
        "Haßberge", "Heidekreis", "Heidenheim",                         
        "Heinsberg", "Helmstedt", "Herford",                            
        "Hersfeld-Rotenburg", "Herzogtum Lauenburg", "Hildesheim",                         
        "Hochsauerlandkreis", "Hohenlohekreis", "Holzminden",                         
        "Höxter", "Ingolstadt", "Karlsruhe",                          
        "Kaufbeuren", "Kempten (Allgäu)", "Kiel",                               
        "Kitzingen", "Kleve", "Köln",                               
        "Konstanz",  "Krefeld", "Kronach",                            
        "Lahn-Dill-Kreis", "Landsberg am Lech", "Leer",                               
        "Leipzig", "Leverkusen","Limburg-Weilburg",                   
        "Lippe", "Lörrach","Lübeck",                             
        "Ludwigsburg", "Ludwigslust-Parchim", "Lüneburg",                           
        "Magdeburg", "Main-Kinzig-Kreis", "Main-Spessart",                      
        "Mainz-Bingen", "Mannheim", "Marburg-Biedenkopf",                 
        "Märkisch-Oderland",  "Märkischer Kreis", "Mecklenburgische Seenplatte",        
        "Meißen", "Memmingen", "Merzig-Wadern",                      
        "Mettmann", "Miesbach", "Miltenberg",                         
        "Minden-Lübbecke", "Mittelsachsen", "Mönchengladbach",                    
        "Mühldorf am Inn", "Mülheim an der Ruhr", "München",                            
        "Münster", "Neckar-Odenwald-Kreis", "Neuburg-Schrobenhausen",             
        "Neumarkt in der Oberpfalz", "Neumünster", "Neunkirchen",                        
        "Neustadt an der Aisch-Bad Windsheim", "Neustadt an der Waldnaab", "Neuwied",                            
        "Nordfriesland", "Nordsachsen", "Nordwestmecklenburg",
        "Nürnberg", "Oberallgäu", "Oberbergischer Kreis",               
        "Oberspreewald-Lausitz", "Odenwaldkreis", "Offenbach",                         
        "Offenbach am Main", "Oldenburg", "Olpe",                               
        "Ortenaukreis", "Osnabrück", "Ostalbkreis",                        
        "Osterholz", "Ostholstein", "Ostprignitz-Ruppin",                 
        "Paderborn", "Pforzheim", "Pinneberg",                          
        "Plön", "Potsdam", "Potsdam-Mittelmark",                 
        "Prignitz",  "Rastatt", "Ravensburg",                         
        "Recklinghausen", "Regen",  "Regionalverband Saarbrücken",        
        "Remscheid", "Rendsburg-Eckernförde", "Reutlingen",                         
        "Rhein-Hunsrück-Kreis", "Rhein-Neckar-Kreis", "Rhein-Neuss",                        
        "Rhein-Sieg-Kreis",  "Rostock", "Rotenburg (Wümme)",                  
        "Roth", "Rottal-Inn", "Rottweil",                           
        "Saalekreis", "Saarlouis",   "Salzgitter",                         
        "Salzlandkreis",  "Schaumburg", "Schleswig-Flensburg",                
        "Schwalm-Eder-Kreis", "Schwandorf", "Schwarzwald-Baar-Kreis",             
        "Schwerin", "Siegen-Wittgenstein","Sigmaringen",                        
        "Soest", "Spree-Neiße", "Stade",                              
        "Städteregion Aachen", "Steinburg", "Steinfurt",                          
        "Stendal", "Straubing", "Straubing-Bogen",                    
        "Stuttgart", "Südliche Weinstraße", "Südwestpfalz",                       
        "Teltow-Fläming", "Tirschenreuth", "Traunstein",                         
        "Trier-Saarburg", "Tuttlingen",  "Uckermark",                          
        "Uelzen", "Ulm", "Unna",                               
        "Viersen", "Vogelsbergkreis","Vogtlandkreis",                      
        "Vorpommern-Greifswald", "Vorpommern-Rügen", "Waldeck-Frankenberg",                
        "Waldshut", "Warendorf", "Weiden in der Oberpfalz",            
        "Weilheim-Schongau","Weißenburg-Gunzenhausen","Wiesbaden" ,                         
        "Wilhelmshaven", "Wittenberg", "Wittmund",                           
        "Wolfsburg", "Wunsiedel im Fichtelgebirge", "Wuppertal",                          
        "Zollernalbkreis", "Zwickau"  
        ]
    if chosen_model == "countieswithproblems":
        federalStates = [
            "Berlin", "Bremen", "Hamburg", "Stuttgart", "München", "Köln",              
            "Frankfurt am Main", "Düsseldorf", "Leipzig", "Essen", "Dortmund", "Dresden",          
            "Nürnberg", "Duisburg", "Helmstedt", "Holzminden", "Schaumburg", "Delmenhorst",      
            "Wilhelmshaven", "Emsland", "Leer", "Oldenburg", "Bremerhaven"
        ]
    
    if chosen_model == "cities_non_hierarchical":  
        federalStates = [
       "Hamburg", "Bremen", "Köln", "Stuttgart", "München", "Berlin"]
      

    labels = {
        "C": "new cases $d_C$",
        "Cnat": "new national cases",
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
            if mix_incidence == True:
                fig, axs = plt.subplots(5, 1, figsize=(9, 25), sharex=False)                
            else:
                fig, axs = plt.subplots(4, 1, figsize=(9, 20), sharex=False)
            axs = axs.ravel()
            ax = axs[0]
            if indicator == "C":
                y_first = trace_in.constant_data.C.where((trace_in.constant_data.counter_C_long<61)&(trace_in.constant_data.fedState_idx_long==i))
            if indicator == "R":
                y_first = trace_in.constant_data.R.where((trace_in.constant_data.counter_R_long>8)&(trace_in.constant_data.counter_R_long<61)&(trace_in.constant_data.fedState_idx_long==i))
            if indicator == "H":
                y_first = trace_in.constant_data.H.where((trace_in.constant_data.counter_H_long>8)&(trace_in.constant_data.counter_H_long<61)&(trace_in.constant_data.fedState_idx_long==i))
            y = y_first.dropna(dim="obs_id_long", how = "any")
            plot_timeseries(
                ax,
                dates_plot_long,
                y,
                color_in=colors[indicator],
                label_in=labels[indicator],
            )
            
            if indicator == "C":
                y_first = trace_in.constant_data.C_nat.where((trace_in.constant_data.counter_C_long<61)&(trace_in.constant_data.fedState_idx_long==i))
            if indicator == "R":
                y_first = trace_in.constant_data.R_nat.where((trace_in.constant_data.counter_R_long>8)&(trace_in.constant_data.counter_R_long<61)&(trace_in.constant_data.fedState_idx_long==i))
            if indicator == "H":
                y_first = trace_in.constant_data.H_nat.where((trace_in.constant_data.counter_C_long>8)&(trace_in.constant_data.counter_H_long<61)&(trace_in.constant_data.fedState_idx_long==i))
            y = y_first.dropna(dim="obs_id_long", how = "any")
            plot_timeseries(
                ax,
                dates_plot_long,
                y,
                color_in=colors["Cnat"],
                label_in=labels["Cnat"],
            )
            
            format_x_axis(ax, dates_plot_long)
            ## set y label
            ax.set_ylabel("Disease Indicator \n(transformed)")
            ax.legend(
                ncol=2,
                #bbox_to_anchor=(0.7, 2)
            )
            
            date_form = DateFormatter("%m/%d")
            ax.xaxis.set_major_formatter(date_form)
            
            if mix_incidence == True:  
                ax=axs[1]
                y_first = trace_in.posterior.combined_incidence.where(trace_in.posterior.combined_incidence.combined_incidence_dim_1==i)
                y = y_first.dropna(dim="combined_incidence_dim_1", how = "any")
                y_test = y[:,:,:,0]
                plot_timeseries(
                    ax,
                    dates_plot_long,
                    y_test,
                    color_in=colors[indicator],
                    label_in=labels[indicator],
                )
                format_x_axis(ax, dates_plot_long)
                ## set y label
                ax.set_ylabel("Combined Incidence")

                date_form = DateFormatter("%m/%d")
                ax.xaxis.set_major_formatter(date_form)
            
            if mix_incidence == True:
                ax = axs[2]
            else:
                ax = axs[1]
            if indicator == "C":
                y_first = trace_in.posterior.risk_C.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
            if indicator == "R":
                y_first = trace_in.posterior.risk_R.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
            if indicator == "H":
                y_first = trace_in.posterior.risk_H.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
            y = y_first.dropna(dim="obs_id", how = "any")
            plot_timeseries(
                ax,
                dates_plot,
                y,
                color_in=colors[indicator],
                label_in=labels[indicator],
            )
            format_x_axis(ax, dates_plot_long)
            ## set y label
            ax.set_ylabel("Disease Indicator \n(convolved))")

            date_form = DateFormatter("%m/%d")
            ax.xaxis.set_major_formatter(date_form)
            
            if mix_incidence == True:
                ax = axs[3]
            else:
                ax = axs[2]
            if indicator == "C":
                y_first = trace_in.posterior.factor_C.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
            if indicator == "R":
                y_first = trace_in.posterior.factor_R.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
            if indicator == "H":
                y_first = trace_in.posterior.factor_H.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))
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
            format_x_axis(ax, dates_plot_long)
            # set y label
            ax.set_ylabel("Scaling \n Factor")
            
            date_form = DateFormatter("%m/%d")
            ax.xaxis.set_major_formatter(date_form)

            # # lower plot
            if mix_incidence:
                ax = axs[4]
            else:
                ax = axs[3] 
            if indicator == "C":
                y_first = trace_in.posterior.d_C.where((trace_in.constant_data.counter_C<61)&(trace_in.constant_data.fedState_idx==i))
            if indicator == "R":
                y_first = trace_in.posterior.d_R.where((trace_in.constant_data.counter_R<61)&(trace_in.constant_data.fedState_idx==i))
            if indicator == "H":  
                y_first = trace_in.posterior.d_H.where((trace_in.constant_data.counter_H<61)&(trace_in.constant_data.fedState_idx==i))          
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
            format_x_axis(ax, dates_plot_long, last=False)
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
        
            # plt.subplots_adjust(hspace=0.1)

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
    model_in, trace_in, tag_in, dates_in, dates_in_long, indicators_in, school_in, holiday_in, temperature_in, precipitation_in, daylight_in, pop_density_in, disease_data_in, disease_data_raw_in, fedState_in, chosen_model, incl2024, plus_nat_incidence, mix_incidence
):
    utils.make_dir(tag_in)
    #if indicators_in:
       #convolution_figure(indicators_in, trace_in, dates_in, tag_in)
    #    plot_gamma_kernel(trace_in, tag_in, indicators_in, chosen_model)
        #plot_gamma_parameters(trace_in, indicators_in, tag_in)
    #    plot_disease_timeseries(dates_in_long, trace_in, tag_in, indicators_in, disease_data_in, disease_data_raw_in, chosen_model, mix_incidence)
       #plot_distributions(model_in, trace_in, tag_in, indicators_in, temperature_in, daylight_in, school_in, holiday_in, indicators_in, chosen_model, fedState_in)
    #if temperature_in:
    #  plot_temperature_timeseries(dates_in, trace_in, tag_in, indicators_in, chosen_model, incl2024)
    #if daylight_in:
    #    plot_daylight_timeseries(dates_in, trace_in, tag_in, indicators_in, chosen_model, incl2024)
    #plot_indicator_timeseries(dates_in, trace_in, tag_in, indicators_in, chosen_model)
    plot_timeseriesPaper(
        chosen_model,
        dates_in,
        trace_in,
        tag_in,
        indicators_in, 
        incl2024,
        plus_nat_incidence,
        school_in,
        holiday_in,
        temperature_in,
        precipitation_in,
        daylight_in,
        pop_density_in
    )
    # plot_all_timeseries(
    #    chosen_model,
    #    dates_in,
    #    trace_in,
    #    tag_in,
    #    indicators_in, 
    #    incl2024,
    #    plus_nat_incidence,
    #    school_in,
    #    holiday_in,
    #    temperature_in,
    #    precipitation_in,
    #    daylight_in,
    #    pop_density_in
    #)
    # plot_chains(trace_in, tag_in)