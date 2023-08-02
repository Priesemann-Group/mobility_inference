import numpy as np
import pandas as pd
import xarray as xr
import scipy.stats as stats

import covid19_inference.covid19_inference as cov19


# --- Utils ---
def _cut_off_before_monday(df):
    while df.index[0].dayofweek != 0:
        df = df[1:]
    return df


## weekly average placed on Sunday
def weekly_formatting(df_in, dates_in):
    df = _cut_off_before_monday(df_in)
    df = df.resample("7D").mean()
    df.index = df.index + pd.Timedelta(days=6)
    return df.filter(items=dates_in, axis=0)


## transform data: logistic of z-score
def transform_data(df_in):
    df = stats.zscore(df_in)
    return 1 / (1 + np.exp(-df))


## transform NPI index data with range 0-3 to range 0-1
def normalise_index(df_in):
    df = df_in / 3
    return df


def get_NPI_data(filename_in, dates_in, stay_home=True):
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
    delta = df2020_in[label_in].values - df2022_in[label_in].values
    if label_in == "prcp":
        delta = -delta
    return delta


## calculate average between the years
def return_averages(df1_in, df2_in, label_in):
    average = (df1_in[label_in].values + df2_in[label_in].values) / 2
    return average


def german_month_to_num(month):
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


def get_weekly_kurzarbeit(df_in, dates_in, year_in):
    # create new df with mobility_dates_2020 as index and Anzahl Kurzarbeitende of the corresponding month as column
    df_out = pd.DataFrame(index=dates_in, columns=["Anzahl Kurzarbeitende"])
    # now assign for each week the number of Kurzarbeitende of the month corresponding to the week
    for week in df_out.index:
        # get value of 'Anzahl Kurzarbeitende' in df for column 'month' week.month and 'year' 2020
        value = df_in.loc[
            (df_in["month"] == week.month) & (df_in["year"] == year_in),
            "Anzahl Kurzarbeitende",
        ].values[0]
        df_out.loc[week, "Anzahl Kurzarbeitende"] = value
    return df_out


# --- Get data ---
## Out of home duration
def get_out_of_home_duration():
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


## Kurzarbeit
def get_kurzarbeit(dates_2020_in, dates_2022_in):
    df = pd.read_csv("data/kurzarbeit.csv", sep=";")
    df["year"] = df["Berichtsmonat"].str[-4:]
    df["month"] = df["Berichtsmonat"].str[:-5]

    ### turn month names into numbers with german_month_to_num function
    df["month"] = df["month"].apply(german_month_to_num)

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
def get_R(dates_in):
    path_R = "data/R/Germany/R_eff_Germany.csv"
    R_df = pd.read_csv(path_R, index_col=1, parse_dates=True)

    ### weekly average placed on Sunday
    df = weekly_formatting(R_df, dates_in)
    df = transform_data(df["R_eff median"])
    R_data = df.to_xarray()
    return R_data


## OWID
def get_owid():
    cov19.data_retrieval.set_data_dir("/data.nst/eiftekhar/covid19/")
    owid = cov19.data_retrieval.OWD()
    owid.download_all_available_data()
    return owid


### cases
def get_C(owid_in, dates_2020_in):
    case_data = owid_in._filter(
        value="new_cases_smoothed_per_million",
        country="Germany",
    )
    case_data = weekly_formatting(case_data, dates_2020_in)
    case_data = transform_data(case_data).to_xarray()
    return case_data


### ICU
def get_ICU(owid_in, dates_2020_in):
    ICU_data = owid_in._filter(
        value="icu_patients_per_million",
        country="Germany",
    )
    ICU_data = weekly_formatting(ICU_data, dates_2020_in)
    ICU_data = transform_data(ICU_data).to_xarray()
    return ICU_data


### hospitalisations
def get_H(owid_in, dates_2020_in):
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
    stay_at_home_2020 = get_NPI_data("data/NPIs/stay-at-home-covid.csv", dates_2020_in)
    stay_at_home_2020 = normalise_index(stay_at_home_2020)
    stay_at_home_2020 = stay_at_home_2020["stay_home_requirements"].to_xarray()
    return stay_at_home_2020


def get_school_closures(dates_2020_in):
    school_closures_2020 = get_NPI_data(
        "data/NPIs/school-closures-covid.csv", dates_2020_in
    )
    school_closures_2020 = normalise_index(school_closures_2020)
    school_closures_2020 = school_closures_2020["school_closures"].to_xarray()
    return school_closures_2020


## Weather
def get_weather_dfs(dates_2020_in, dates_2022_in):
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
    weather_df_2020, weather_df_2022 = get_weather_dfs(dates_2020_in, dates_2022_in)
    delta_tmax = return_differences(weather_df_2020, weather_df_2022, "tmax")
    delta_tmax = xr.DataArray(
        delta_tmax, dims="date", coords={"date": dates_2020_in}, name="delta_tmax"
    )
    return delta_tmax


### calculate average between the years
def get_avg_T(dates_2020_in, dates_2022_in):
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
    weather_df_2020, weather_df_2022 = get_weather_dfs(dates_2020_in, dates_2022_in)
    delta_prcp = return_differences(weather_df_2020, weather_df_2022, "prcp")
    delta_prcp = xr.DataArray(
        delta_prcp, dims="date", coords={"date": dates_2020_in}, name="delta_prcp"
    )
    return delta_prcp
