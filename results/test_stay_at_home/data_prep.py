import numpy as np
import pandas as pd
import xarray as xr
import scipy.stats as stats
import datetime

import covid19_inference.covid19_inference as cov19


# --- Utils ---
def population_string_to_number(string_in):
    """Converts a string with a number and a unit to an integer.

    Parameters:
        string_in (str): string with a number and a unit
    Returns:
        int: number without unit"""
    string = string_in.replace("\xa0", "")
    return int(string)


def _cut_off_before_monday(df):
    """Cut off data before Monday.

    Args:
        df (pd.DataFrame): Dataframe with dates as index.
    Returns:
        pd.DataFrame: Dataframe with dates as index.
    """
    while df.index[0].dayofweek != 0:
        df = df[1:]
    return df


## weekly average placed on Sunday
def weekly_formatting(df_in, dates_in):
    """
    Args:
        df_in (pd.DataFrame): Dataframe with dates as index.
        dates_in (array or list): List of dates to be included in the output.
    Returns:
        pd.DataFrame: Dataframe with dates as index.
    """
    # cut off data before Monday
    df = _cut_off_before_monday(df_in)
    # resample to weekly average
    df = df.resample("7D").mean()
    # shift reference data from Monday to Sunday of the week
    df.index = df.index + pd.Timedelta(days=6)

    return df.filter(items=dates_in, axis=0)


## transform data: logistic of z-score
def transform_data(df_in):
    """
    Args:
        df_in (pd.DataFrame): Data.
    Returns:
        pd.DataFrame: Transformed data.
    """
    df = stats.zscore(df_in)
    return 1 / (1 + np.exp(-df))


## transform NPI index data with range 0-3 to range 0-1
def normalise_index(df_in):
    """
    Args:
        df_in (pd.DataFrame): Data.
    Returns:
        pd.DataFrame: Normalised data.
    """
    df = df_in / 3
    return df


def get_NPI_data(filename_in, dates_in, stay_home=True):
    """Get NPI data download from OWID based on OxCGRT.
    Args:
        filename_in (str): Path to file.
        dates_in (array or list): List of dates to be included in the output.
        stay_home (bool): If True, set all values between dates "2020-10-22" and "2020-11-01" to 1.
    Returns:
        pd.DataFrame: Dataframe with dates as index.
    """
    df = pd.read_csv(filename_in, index_col=2, parse_dates=True)
    df = df[df["Entity"] == "Germany"]
    # from 22.10.20 to 01.11.20 it is still just a recommendation not a requirement
    # (see https://github.com/OxCGRT/covid-policy-dataset/blob/main/data/OxCGRT_fullwithnotes_national_2020_v1.csv)
    # set all values between dates "2020-10-22" and "2020-11-01" to 1
    if stay_home:
        df.loc["2020-10-22":"2020-11-01", "stay_home_requirements"] = 1
    df = weekly_formatting(df, dates_in)
    return df


## calculate differences between the years
def return_differences(df2020_in, df2022_in, label_in):
    """
    Args:
        df2020_in (pd.DataFrame): Dataframe with dates as index.
        df2022_in (pd.DataFrame): Dataframe with dates as index.
        label_in (str): Get negative difference if data is precipitation.
    Returns:
        Array: Difference of time series.
    """
    delta = df2020_in[label_in].values - df2022_in[label_in].values
    if label_in == "prcp":
        delta = -delta
    return delta


## calculate average between the years
def return_averages(df1_in, df2_in, label_in):
    """
    Args:
        df1_in (pd.DataFrame): Dataframe with dates as index.
        df2_in (pd.DataFrame): Dataframe with dates as index.
        label_in (str): Column name of data of interest.
    Returns:
        Array: Average of time series.
    """
    average = (df1_in[label_in].values + df2_in[label_in].values) / 2
    return average


## for Kurzarbeit
def german_month_to_num(month):
    """Convert month name to number.
    Args:
        month (str): Month name in German.
    Returns:
        int: Month number.
    """
    german_months = [
        "Januar",
        "Februar",
        "März",
        "April",
        "Mai",
        "Juni",
        "Juli",
        "August",
        "September",
        "Oktober",
        "November",
        "Dezember",
    ]
    return german_months.index(month) + 1


def parse_month(date_str):
    """Parse month from date string.

    Args:
        date_str (str): Date as string in format "Month Year", e.g. "Januar 2020".
    Returns:
        int: Month number.
    """

    strings = date_str.split(" ")
    month = german_month_to_num(strings[0])
    return month


def parse_year(date_str):
    """Parse year from date string.

    Args:
        date_str (str): Date as string in format "Month Year", e.g. "Januar 2020".
    Returns:
        int: Year.
    """

    strings = date_str.split(" ")
    year = int(strings[1])
    return year


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


## Home office


# --- Get data ---
## Out of home duration
def get_out_of_home_duration():
    """
    Returns:
        Xarray: Out-of-home duration data for 2020.
        Xarray: Baseline out-of-home duration data.
        Array of np.datetime64: Considered dates of 2020.
        Array of np.datetime64: Considered dates of 2022.
    """
    path_mobility = "data/mobility/mobilityData_OverviewBL_weekly.csv"
    mobility_df = pd.read_csv(
        path_mobility, parse_dates=True, index_col=0, delimiter=";"
    )
    mobility_df = mobility_df[mobility_df["BundeslandID"] == "Deutschland"]
    mobility_df["week"] = mobility_df.index.isocalendar().week

    ### get dates
    mobility_dates = mobility_df.index.values
    dates_2020 = mobility_dates[mobility_dates < np.datetime64("2020-12-20")]
    mobility_dates_2020 = dates_2020[dates_2020 > np.datetime64("2020-03-29")]
    mobility_dates_2022 = mobility_dates[mobility_dates < np.datetime64("2022-12-20")]
    mobility_dates_2022_shortened = mobility_dates_2022[-len(mobility_dates_2020) :]

    ### get out of home duration data
    mobility_df_2020 = mobility_df.filter(items=mobility_dates_2020, axis=0)
    mobility_data_2020 = mobility_df_2020["outOfHomeDuration"].to_xarray()

    baseline_mobility_df = pd.read_csv(
        "data/mobility/baseline_mobility.csv", parse_dates=True, index_col=0
    )
    baseline_mobility_df = baseline_mobility_df.filter(
        items=mobility_dates_2022_shortened, axis=0
    )
    ## replace index by mobility_dates_2020
    baseline_mobility_df.index = mobility_dates_2020
    ## rename index to "date"
    baseline_mobility_df.index.name = "date"
    baseline_mobility = baseline_mobility_df["outOfHomeDuration"].to_xarray()

    return (
        mobility_data_2020,
        baseline_mobility,
        mobility_dates_2020,
        mobility_dates_2022_shortened,
    )


## Home office
def get_home_office_infas(dates_2020_in):
    """Get weekly data of home office rate from infas.
    Source: Corona Datenplattform (2021): Themenreport 02, Homeoffice im Verlauf der Corona-Pandemie, Ausgabe Juli 2021, Bonn.
    (Exact data is not publicly available for free.)

    Args:
        dates_2020_in (array or list): List of considered dates in 2020.
    Returns:
        Pandas data frame: Weekly home office percent data.
    """
    df = pd.read_csv("data/home_office/home_office_infas.csv", sep="\t")

    # parse to proper dates
    def str_to_date(date_str):
        """Convert string to date.

        Args:
            date_str (str): Date as string in format " %b %y", e.g. " Jan 20".
        Returns:
            datetime: Date.
        """
        return datetime.datetime.strptime(date_str, " %b %y")

    df["date"] = df["Month"].apply(str_to_date)
    df["year"] = df["date"].apply(lambda x: x.year)
    df["month"] = df["date"].apply(lambda x: x.month)

    # filter for 2020 data
    df_2020 = df[df["year"] == 2020]

    # make weekly data out of monthly data
    column_name = "WFH_rate"
    df_2020 = pd.DataFrame(index=dates_2020_in, columns=[column_name])
    for week in df_2020.index:
        value = df.loc[(df["month"] == week.month), column_name].values[0]
        df_2020.loc[week, column_name] = value

    return df_2020


## Kurzarbeit
def get_kurzarbeit(dates_2020_in):
    """Get weekly data of difference in fraction of Kurzarbeitende.
    Source: Statistik der Bundesagentur für Arbeit
        Tabellen, Realisierte Kurzarbeit (hochgerechnet) (Monatszahlen), Nürnberg, August 2023
        http://statistik.arbeitsagentur.de

    Args:
        dates_2020_in (array or list): List of considered dates in 2020.
    Returns:
        Xarray: Difference in Kurzarbeit between 2020 and 2022 as fraction of population.
    """

    df = pd.read_csv("data/kurzarbeit/IAB_kurzarbeit.csv", sep="\t")
    df["month"] = df["Datum"].apply(parse_month)
    df["year"] = df["Datum"].apply(parse_year)

    # get 2020 data
    df_2020 = df[df["year"] == 2020]
    # get 2022 data
    df_2022 = df[df["year"] == 2022]
    # calculate the difference between 2020 and 2022
    delta_kurzarbeit = (
        df_2020["Kurzarbeiterquote"].values - df_2022["Kurzarbeiterquote"].values
    )

    # make weekly data out of monthly data
    column_name = "Differenz Kurzarbeiteranteil"
    df_diff = pd.DataFrame(index=df_2020["month"])
    df_diff[column_name] = delta_kurzarbeit / 100
    df_out = pd.DataFrame(index=dates_2020_in, columns=[column_name])
    for week in df_out.index:
        value = df_diff.loc[(df_diff.index == week.month), column_name].values[0]
        df_out.loc[week, column_name] = round(value, 3)
    df_out[column_name] = df_out[column_name].astype(float)

    # to xarray
    array = df_out.to_xarray()
    array = array.rename_dims({"index": "date"})

    return df_out[column_name].values


## Kurzarbeit and home office
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


## R
def get_R(dates=None):
    """Get weekly R_eff data from the RKI Nowcasting data set.

    Args:
        dates (array or list): List of dates to be included in the output.
    Returns:
        Xarray: Weekly R data.
    """
    path_R = "data/R/Germany/RKI_Nowcasting.csv"
    R_df = pd.read_csv(path_R, index_col=0, parse_dates=True)

    if dates is None:
        dates = pd.date_range(start="2020-03-06", end="2020-12-19", freq="W-SUN").values

    ### weekly average placed on Sunday
    df = weekly_formatting(R_df, dates)

    df = transform_data(df["PS_7_Tage_R_Wert"])
    R_data = df.to_xarray()
    return R_data


def get_R_inferred(dates=None):
    """Get weekly R_eff data.
    As get_R, but using own inferred R_eff data.
    """
    path_R = "data/R/Germany/R_eff_Germany.csv"
    R_df = pd.read_csv(path_R, index_col=1, parse_dates=True)

    if dates is None:
        dates = pd.date_range(start="2020-02-27", end="2020-12-19", freq="W-SUN").values

    ### weekly average placed on Sunday
    df = weekly_formatting(R_df, dates)

    df = transform_data(df["R_eff median"])
    R_data = df.to_xarray()
    return R_data


## OWID
def get_owid():
    """Get OWID data set.

    Returns:
        OWID data retrieval object. (See cov19 module.)
    """
    cov19.data_retrieval.set_data_dir("/data.nst/eiftekhar/covid19/")
    owid = cov19.data_retrieval.OWD()
    owid.download_all_available_data()
    return owid


### cases
def get_C(owid_in, dates_2020_in):
    """Get weekly case data from OWID data set.

    Args:
        owid_in (OWID data retrieval object): OWID data retrieval object.
        dates_2020_in (array or list): List of considered dates in 2020.
    Returns:
        Xarray: Weekly case data.
    """
    case_data = owid_in._filter(
        value="new_cases_smoothed_per_million",
        country="Germany",
    )
    case_data = weekly_formatting(case_data, dates_2020_in)
    case_data = transform_data(case_data).to_xarray()
    return case_data


### ICU
def get_ICU(owid_in, dates_2020_in):
    """Get weekly ICU data from OWID data set.

    Args:
        owid_in (OWID data retrieval object): OWID data retrieval object.
        dates_2020_in (array or list): List of considered dates in 2020.
    Returns:
        Xarray: Weekly ICU data.
    """
    ICU_data = owid_in._filter(
        value="icu_patients_per_million",
        country="Germany",
    )
    ICU_data = weekly_formatting(ICU_data, dates_2020_in)
    ICU_data = transform_data(ICU_data).to_xarray()
    return ICU_data


### hospitalisations
def get_H(owid_in, dates_2020_in):
    """Get weekly hospitalisation data from OWID data set.

    Args:
        owid_in (OWID data retrieval object): OWID data retrieval object.
        dates_2020_in (array or list): List of considered dates in 2020.
    Returns:
        Xarray: Weekly hospitalisation data."""

    H_data = owid_in._filter(
        value="weekly_hosp_admissions_per_million",
        country="Germany",
    )
    H_data = weekly_formatting(H_data, dates_2020_in)
    H_data = transform_data(H_data).to_xarray()
    return H_data


## NPI
### stay at home orders
def get_S(dates_2020_in):
    df = pd.read_csv("data/NPIs/StayAtHomeOrders - Werte.csv")

    # iterate through every row of the data frame to make date column
    for index, row in df.iterrows():
        # create date object from Day, Month, Year columns
        date = datetime.date(row["Year"], row["Month"], row["Day"])
        # make date to pandas datetime format
        date = pd.to_datetime(date)
        # add date object to new column
        df.loc[index, "Date"] = date

    # create empty dataframe with dates as index
    df_new = pd.DataFrame(index=df["Date"].values)

    # only get columns with values
    for column_name in df.columns.values:
        if column_name[:5] == "Value":
            _, state = column_name.split(" ")
            df_new[state] = df[column_name].values

    population = pd.read_csv("data/population_bundesland.csv", sep=";", index_col=0)
    population["Einwohner"] = population["Einwohner"].apply(population_string_to_number)

    weighted_averages = []

    for index, row in df_new.iterrows():
        value = 0
        for column in df_new.columns.values:
            value += population.loc[column]["Einwohner"] * row[column]
        value /= population["Einwohner"].sum()
        weighted_averages.append(value)

    # add new row to dataframe
    df_new["stay_at_home_orders"] = weighted_averages

    # filter rows for dates_2020_in
    df_new = df_new[df_new.index.isin(dates_2020_in)]

    # make xarray out of column
    return df_new["stay_at_home_orders"].to_xarray()


def get_S_OxCGRT(dates_2020_in):
    """Get weekly stay at home order data from Oxford data set.

    Args:
        dates_2020_in (array or list): List of considered dates in 2020.
    Returns:
        Xarray: Weekly stay at home order data.
    """
    stay_at_home_2020 = get_NPI_data("data/NPIs/stay-at-home-covid.csv", dates_2020_in)
    stay_at_home_2020 = normalise_index(stay_at_home_2020)
    stay_at_home_2020 = stay_at_home_2020["stay_home_requirements"].to_xarray()
    return stay_at_home_2020


### NOT NEED ANYMORE
def get_school_closures(dates_2020_in):
    """Get weekly school closure data from Oxford data set.

    Args:
        dates_2020_in (array or list): List of considered dates in 2020.
    Returns:
        Xarray: Weekly school closure data.
    """
    school_closures_2020 = get_NPI_data(
        "data/NPIs/school-closures-covid.csv", dates_2020_in
    )
    school_closures_2020 = normalise_index(school_closures_2020)
    school_closures_2020 = school_closures_2020["school_closures"].to_xarray()
    return school_closures_2020


## Weather
def get_weather_dfs(dates_2020_in, dates_2022_in):
    """Get weather data frames.

    Args:
        dates_2020_in (array or list): List of considered dates in 2020.
        dates_2022_in (array or list): List of considered dates in 2022.
    Returns:
        Data frame: Weather data frame for 2020.
        Data frame: Weather data frame for 2022.
    """

    weather_df = pd.read_csv(
        "data/weather/weatherData2020and2022.csv", parse_dates=True, index_col=0
    )

    ### filter for mobility_dates_2020
    weather_df_2020 = weather_df[weather_df.index.isin(dates_2020_in)]
    weather_df_2022 = weather_df[weather_df.index.isin(dates_2022_in)]

    return weather_df_2020, weather_df_2022


### Temperature
#### calculate differences between the years
def get_delta_T(dates_2020_in, dates_2022_in):
    """Get weekly average of maximum temperature difference between 2020 and 2022.

    Args:
        dates_2020_in (array or list): List of considered dates in 2020.
        dates_2022_in (array or list): List of considered dates in 2022.
    Returns:
        Xarray: Weekly temperature difference data.
    """

    weather_df_2020, weather_df_2022 = get_weather_dfs(dates_2020_in, dates_2022_in)
    delta_tmax = return_differences(weather_df_2020, weather_df_2022, "tmax")
    delta_tmax = xr.DataArray(
        delta_tmax, dims="date", coords={"date": dates_2020_in}, name="delta_tmax"
    )
    return delta_tmax


### calculate average between the years
def get_avg_T(dates_2020_in, dates_2022_in):
    """Get weekly average of maximum temperature between 2020 and 2022.

    Args:
        dates_2020_in (array or list): List of considered dates in 2020.
        dates_2022_in (array or list): List of considered dates in 2022.
    Returns:
        Xarray: Weekly average temperature data.
    """

    weather_df_2020, weather_df_2022 = get_weather_dfs(dates_2020_in, dates_2022_in)
    average_tmax = return_averages(weather_df_2020, weather_df_2022, "tmax")
    average_tmax = xr.DataArray(
        average_tmax,
        dims="date",
        coords={"date": dates_2020_in},
        name="average_tmax",
    )
    return average_tmax


### Precipitation
#### calculate differences between the years
def get_delta_prcp(dates_2020_in, dates_2022_in):
    """Get weekly average of precipitation difference between 2020 and 2022.

    Args:
        dates_2020_in (array or list): List of considered dates in 2020.
        dates_2022_in (array or list): List of considered dates in 2022.
    Returns:
        Xarray: Weekly precipitation difference data.
    """

    weather_df_2020, weather_df_2022 = get_weather_dfs(dates_2020_in, dates_2022_in)
    delta_prcp = return_differences(weather_df_2020, weather_df_2022, "prcp")
    delta_prcp = xr.DataArray(
        delta_prcp, dims="date", coords={"date": dates_2020_in}, name="delta_prcp"
    )
    return delta_prcp
