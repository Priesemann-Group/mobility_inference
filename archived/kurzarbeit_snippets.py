# NOT IN USE ANYMORE
def get_total_kurzarbeit():
    """Get total data of number of Kurzarbeitende from IAB.

    Returns:
        pd.DataFrame: Dataframe with dates as index.
    """
    df = pd.read_csv("data/home_office_kurzarbeit/kurzarbeit.csv", sep=";")
    df["year"] = df["Berichtsmonat"].str[-4:]
    df["month"] = df["Berichtsmonat"].str[:-5]

    ### turn month names into numbers with german_month_to_num function
    df["month"] = df["month"].apply(german_month_to_num)

    return df


# NOT IN USE ANYMORE
def get_weekly_kurzarbeit(df_in, dates_in, year_in):
    """Get weekly data of number of Kurzarbeitende.

    Args:
        df_in (pd.DataFrame): Dataframe with dates as index.
        dates_in (array or list): List of dates to be included in the output.
        year_in (str): Year of interest.
    Returns:
        pd.DataFrame: Dataframe with dates as index.
    """
    keys = {"2020": "Kurzarbeitende korrigiert", "2022": "Anzahl Kurzarbeitende"}
    # create new df with mobility_dates_2020 as index and Anzahl Kurzarbeitende of the corresponding month as column
    df_out = pd.DataFrame(index=dates_in, columns=["Anzahl Kurzarbeitende"])
    # now assign for each week the number of Kurzarbeitende of the month corresponding to the week
    for week in df_out.index:
        # get value of 'Anzahl Kurzarbeitende' in df for column 'month' week.month and 'year' 2020
        value = df_in.loc[
            (df_in["month"] == week.month) & (df_in["year"] == year_in),
            keys[year_in],
        ].values[0]
        df_out.loc[week, "Anzahl Kurzarbeitende"] = value
    return df_out

# NOT IN USE ANYMORE
def get_home_office_kurzarbeit(dates_in):
    """Get weekly data of percent of people in home office or Kurzarbeit.
    Source: Corona Datenplattform (2021): Themenreport 02, Homeoffice im Verlauf der Corona-Pandemie, Ausgabe Juli 2021, Bonn.

    Args:
        dates_in (array or list): List of dates to be included in the output.
    Returns:
        pd.DataFrame: Dataframe with dates as index.
    """
    df = pd.read_csv("data/home_office_kurzarbeit/home_office_kurzarbeit.csv")
    # get only 2020 data: filter for month < 13
    df = df[df["month"] < 13]

    # make weekly data out of daily data
    df_out = pd.DataFrame(index=dates_in, columns=["percent"])
    for week in df_out.index:
        value = df.loc[(df["month"] == week.month), "percent"].values[0]
        df_out.loc[week, "percent"] = value

    return df_out


## NOT IN USE ANYMORE | Kurzarbeit and home office
def get_people_home(dates_2020_in, dates_2022_in):
    """Get weekly data of additinal people at home in 2020 due to home office or Kurzarbeit.

    Args:
        dates_2020_in (array or list): List of considered dates in 2020.
        dates_2022_in (array or list): List of considered dates in 2022.
    Returns:
        Xarray: Difference in Kurzarbeit between 2020 and 2022 as fraction of population.
    """
    ### fraction of people in Kurzarbeit in 2022
    #### people in Kurzarbeit in 2022
    df = get_total_kurzarbeit()
    df_kurzarbeit_2022 = get_weekly_kurzarbeit(df, dates_2022_in, "2022")
    #### normalize by population
    population = 83237124
    kurzarbeit_2022 = df_kurzarbeit_2022["Anzahl Kurzarbeitende"].values / population

    ### fraction of people in home office in 2022
    ### source: https://www.destatis.de/DE/Presse/Pressemitteilungen/Zahl-der-Woche/2023/PD23_28_p002.html#:~:text=24%2C2%20%25%20aller%20Erwerbst%C3%A4tigen%20in,Statistische%20Bundesamt%20(Destatis)%20mitteilt.
    home_office_2022 = 0.24

    ### fraction of people in home office or Kurzarbeit in 2020
    df_home_office_kurzarbeit_2020 = get_home_office_kurzarbeit(dates_2020_in)
    values_2020 = df_home_office_kurzarbeit_2020["percent"].values / 100

    ### get difference between 2020 and 2022 as fraction of population
    home_diff = values_2020 - kurzarbeit_2022 - home_office_2022

    ### make xarray of KA_diff with mobility_dates_2020 as index
    diff_xr = xr.DataArray(home_diff, coords=[dates_2020_in], dims=["date"])
    return diff_xr


## NOT IN USE ANYMORE | Kurzarbeit
def get_OLD_kurzarbeit(dates_2020_in, dates_2022_in):
    """Get weekly data of difference in number of Kurzarbeitende.

    Args:
        dates_2020_in (array or list): List of considered dates in 2020.
        dates_2022_in (array or list): List of considered dates in 2022.
    Returns:
        Xarray: Difference in Kurzarbeit between 2020 and 2022 as fraction of population.
    """
    df = get_total_kurzarbeit()
    df_kurzarbeit_2020 = get_weekly_kurzarbeit(df, dates_2020_in, "2020")
    df_kurzarbeit_2022 = get_weekly_kurzarbeit(df, dates_2022_in, "2022")

    ### get difference between 2020 and 2022 as fraction of population
    population = 83237124
    KA_2020 = df_kurzarbeit_2020["Anzahl Kurzarbeitende"].values
    KA_2022 = df_kurzarbeit_2022["Anzahl Kurzarbeitende"].values
    KA_diff = (KA_2020 - KA_2022) / population

    ### make xarray of KA_diff with mobility_dates_2020 as index
    KA_diff_xr = xr.DataArray(KA_diff, coords=[dates_2020_in], dims=["date"])
    return KA_diff_xr



## NOT IN USE ANYMORE | plot Gamma distribution with inferred mean and standard deviation
def plot_gamma_kernel_kurzarbeit(trace_in, tag_in):
    fig, ax = plt.subplots(1, 1, figsize=(5, 4))

    # prepare
    max_x = 4
    x = np.linspace(0, max_x, 100)
    ys = []

    # plot
    y = cov19.model._utility.tt_gamma(
        x,
        mu=np.median(trace_in.posterior[f"mu_K"]),
        sigma=np.median(trace_in.posterior[f"sigma_K"]),
    ).eval()
    ys.append(y)
    ax.plot(x, y, linewidth=3, color=colors["K"])

    # format
    ax.set_xlabel("Month")
    ax.set_title("Inferred median Gamma\nkernel for Kurzarbeit")
    ax.set_xlim(0, max_x)
    ax.set_ylim(0, 1.1 * np.max(np.array(ys)))
    fig.tight_layout()

    fig.savefig(f"{tag_in}/gamma_kernel_kurzarbeit.png")
    fig.savefig(f"{tag_in}/gamma_kernel_kurzarbeit.pdf")


## NOT IN USE ANYMORE
def correct_for_OLD_kurzarbeit(
    kurzarbeit_data_in, dates_2020, dates_2022_in, m_base_data
):
    """Adjusts baseline out-of-hone duration for short-time work changes.

    Args:
        kurzarbeit_data_in: Short-time work data (pd.DataFrame)
        dates_2020: 2020 dates (pd.DatetimeIndex)
        dates_2022_in: 2022 dates (pd.DatetimeIndex)
        m_base_data: Baseline mobility (pm.ConstantData)

    Returns:
        Adjusted baseline mobility (pymc variable)
    """

    ## be aware that the time series goes from present to past
    kurzarbeit = kurzarbeit_data_in["Anzahl Kurzarbeitende"].values

    ## delay / advance kurzarbeit to correct reporting delay
    mu_K = pm.LogNormal("mu_K", mu=np.log(1), tau=10)
    sigma_K = pm.LogNormal("sigma_K", mu=np.log(0.6), tau=6)
    advanced_kurzarbeit = cov19.model.delay_cases(
        cases=kurzarbeit,
        delay_kernel="gamma",
        median_delay=mu_K,
        scale_delay=sigma_K,
        len_input_arr=len(kurzarbeit),
        len_output_arr=len(kurzarbeit),
        diff_input_output=0,
    )
    kurzarbeit_data_in["Kurzarbeitende korrigiert"] = advanced_kurzarbeit.eval()

    ## get weekly data for 2020 and 2022
    df_kurzarbeit_2020 = data_prep.get_weekly_kurzarbeit(
        kurzarbeit_data_in, dates_2020, "2020"
    )
    df_kurzarbeit_2022 = data_prep.get_weekly_kurzarbeit(
        kurzarbeit_data_in, dates_2022_in, "2022"
    )

    ## get difference between 2020 and 2022 as fraction of population
    population = 83237124
    KA_2020 = df_kurzarbeit_2020["Anzahl Kurzarbeitende"].values
    KA_2022 = df_kurzarbeit_2022["Anzahl Kurzarbeitende"].values
    KA_diff = (KA_2020 - KA_2022) / population

    ## make xarray of KA_diff with mobility_dates_2020 as index
    KA_diff_xr = xr.DataArray(KA_diff, coords=[dates_2020], dims=["date"])
    KA_diff_xr = pm.ConstantData("Kurzarbeit", KA_diff_xr)

    ## correct baseline out-of-home duration
    delta_o = pm.LogNormal("delta_o", mu=np.log(5), tau=10)
    m = pm.Deterministic("o_*", m_base_data - delta_o * KA_diff_xr)

    return m



# NOT IN USE ANYMORE | Home office and Kurzarbeit
def correct_for_home_office_and_kurzarbeit(ho_ka_data_in, m_base_data):
    """Adjusts baseline out-of-hone duration for short-time work changes.

    Args:
        ho_ka_data_in: Home office and short-time work data (Xarray.DataArray)
        m_base_data: Baseline mobility (pm.ConstantData)

    Returns:
        Adjusted baseline mobility (pymc variable)
    """
    ho_ka_data = pm.ConstantData("HO_KA", ho_ka_data_in)
    ## correct baseline out-of-home duration
    delta_o = pm.LogNormal("delta_o", mu=np.log(8), tau=10)
    m = pm.Deterministic("o_*", m_base_data - delta_o * ho_ka_data)

    return m