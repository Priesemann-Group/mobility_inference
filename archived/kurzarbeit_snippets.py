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