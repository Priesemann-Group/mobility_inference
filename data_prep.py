from math import log10
import numpy as np
import pandas as pd
import xarray as xr
import scipy.stats as stats
import datetime

import covid19_inference as cov19


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
    #df = stats.zscore(df_in)
    df = (df_in - min(df_in))/(max(df_in)-min(df_in))

    return df


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
    """ Calculate difference between two time series: '2020 - 2022'.


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


## normalise data
def normalise(array_in):
    """Normalise data to range [-1,1].

    Args:
        array_in (array or list): Data.
    Returns:
        Array: Normalised data.
    """
    return array_in / np.max(array_in)


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
    """Get weekly data of home office rate from ifo.
    Source: ifo institute, December 2022.

    Args:
        dates_2020_in (array or list): List of considered dates in 2020.
    Returns:
        Pandas data frame: Weekly data of people in home office in percent.
    """

    def str_to_date(date_str):
        return datetime.datetime.strptime(date_str, " %m/%Y")

    df = pd.read_csv("data/home_office/home_office_ifo.csv", sep="\t")

    # apply str_to_date to the Date column
    df["date"] = df["Date"].apply(str_to_date)
    df["year"] = df["date"].apply(lambda x: x.year)
    df["month"] = df["date"].apply(lambda x: x.month)

    # filter for rows with year == 2022
    df_2022 = df[df["year"] == 2022]

    # identify which months are missing in df_2022 using the 'date' column
    missing_months = [
        month for month in range(1, 13) if month not in df_2022["month"].unique()
    ]

    # for every missing month in df_2022, create a new row with the missing month using .concat()
    for month in missing_months:
        df_2022 = pd.concat([df_2022, pd.DataFrame({"month": [month]})])

    # sort df_2020 by the 'date' column
    df_2022 = df_2022.sort_values(by="month")

    # for the 'Percent' column interpolate the missing values
    df_2022["Percent"] = df_2022["Percent"].interpolate()

    # make weekly data out of monthly data
    column_name = "Percent"
    df_out = pd.DataFrame(index=dates_2020_in, columns=[column_name])
    for week in df_out.index:
        value = df_2022.loc[(df_2022["month"] == week.month), column_name].values[0]
        df_out.loc[week, column_name] = value

    return df_out


def get_disease_dates(ICU=False):
    """Get dates for disease data.

    Returns:
        Array of np.datetime64: Maximum dates for 2020.
    """
    if ICU:
        start_date = "2020-03-22"
    else:
        start_date = "2020-03-06"
    return pd.date_range(start=start_date, end="2020-12-19", freq="W-SUN").values


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
    path_mobility = "/Users/sydney/git/mobility_inference/data/mobility/mobilityData_OverviewBL_weekly.csv"
    mobility_df = pd.read_csv(
        path_mobility, parse_dates=True, index_col=0, delimiter=";"
    )
    mobility_df = mobility_df[mobility_df["BundeslandID"] == "Deutschland"]
    mobility_df["week"] = mobility_df.index.isocalendar().week

    ### get dates
    mobility_dates = mobility_df.index.values
    dates_2020 = mobility_dates
    mobility_dates_2020 = dates_2020[dates_2020 > np.datetime64("2020-03-29")]
    mobility_dates_2023 = mobility_dates[mobility_dates > np.datetime64("2023-01-01")]
    mobility_dates_2022_shortened = mobility_dates_2023[-len(mobility_dates_2020) :]
        
    ### get out of home duration data
    mobility_df_2020 = mobility_df.filter(items=mobility_dates_2020, axis=0)
    mobility_data_2020 = mobility_df_2020["outOfHomeDuration"].to_xarray()

    baseline_mobility = [1] * mobility_data_2020.size

    return (
        mobility_data_2020,
        baseline_mobility,
        mobility_dates_2020,
        mobility_dates_2022_shortened,
    )

## R
def get_R_raw(dates=None):
    """Get weekly R_eff data from the RKI Nowcasting data set.

    Args:
        dates (array or list): List of dates to be included in the output.
    Returns:
        Xarray: Weekly R data.
    """
    path_R = "data/R/Germany/RKI_Nowcasting.csv"
    R_df = pd.read_csv(path_R, index_col=0, parse_dates=True)

    if dates is None:
        dates = get_disease_dates()

    ### weekly average placed on Sunday
    df = weekly_formatting(R_df, dates)

    #df = transform_data(df["PS_7_Tage_R_Wert"])
    R_data = df["PS_7_Tage_R_Wert"].to_xarray()

    for i in range(37, R_data.size):
        R_data[i] = 0

    return R_data

def get_logR_raw(R_raw, dates=None):

    logR = np.log10(R_raw)

    return logR

def get_R_transformed(R_raw, dates=None):

    R_transformed = transform_data(R_raw)

    return R_transformed

def get_logR_transformed(logR, dates=None):

    logR_transformed = transform_data(logR)

    return logR_transformed

def get_R_inferred(dates=None):
    """Get weekly R_eff data.
    As get_R, but using own inferred R_eff data.
    """
    path_R = "data/R/Germany/R_eff_Germany.csv"
    R_df = pd.read_csv(path_R, index_col=1, parse_dates=True)

    if dates is None:
        dates = get_disease_dates()

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
    cov19.data_retrieval.set_data_dir("Users/sydney/Desktop/data.nst/")
    owid = cov19.data_retrieval.OWD()
    owid.download_all_available_data()
    return owid


### Cases
def get_C_raw(owid_in, dates_2020=None):
    """Get weekly case data from OWID data set.

    Args:
        TODO owid_in (OWID data retrieval object): OWID data retrieval object.
        dates_2020_in (array or list): List of considered dates in 2020.
    Returns:
       TODO Xarray: Weekly case data.
    """
    case_data = owid_in._filter(
        value="new_cases_smoothed_per_million",
        country="Germany",
    )
    if dates_2020 is None:
        dates_2020 = get_disease_dates()
    case_data = weekly_formatting(case_data, dates_2020)
    case_data = case_data.to_xarray()

    for i in range(37, case_data.size):
        case_data[i] = 0
        
    return case_data

def get_logC_raw(case_data, dates_2020=None):

    logC_raw = np.log10(case_data)

    return logC_raw

def get_C_transformed(case_data, dates_2020=None):
    """Get weekly case data from OWID data set.

    Args:
        TODO
    Returns:
        TODO
    """

    case_data = transform_data(case_data)
   
    return case_data

def get_logC_transformed (logC_raw, dates_2020=None):
    
    logC_transformed = transform_data(logC_raw)

    return logC_transformed

### ICU
def get_ICU_raw(owid_in, dates_2020_in=None):
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
    if dates_2020_in is None:
        dates_2020_in = get_disease_dates(ICU=True)
    ICU_data = weekly_formatting(ICU_data, dates_2020_in)
    ICU_data = ICU_data.to_xarray()
    return ICU_data

def get_logICU_raw(ICU_data, dates_2020_in=None):

    logICU_raw = np.log10(ICU_data)

    return logICU_raw

def get_ICU_transformed(ICU_data, dates_2020_in=None):
    """Get weekly ICU data from OWID data set.

    Args:
        TODO
    Returns:
        Xarray: TODO
    """

    ICU_data = transform_data(ICU_data)
    
    return ICU_data

def get_logICU_transformed(logICU_raw, dates_2020_in=None):

    logICU_transformed = transform_data(logICU_raw)

    return logICU_transformed

### Hospitalisations
def get_H_raw(owid_in, dates_2020_in=None):
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
    if dates_2020_in is None:
        dates_2020_in = get_disease_dates()
    H_data = weekly_formatting(H_data, dates_2020_in)
    H_data = H_data.to_xarray()

    for i in range(37, H_data.size):
        H_data[i] = 0
    
    return H_data

def get_logH_raw(H_data, dates_2020_in=None):

    logH_raw = np.log10(H_data)

    return logH_raw

def get_H_transformed(H_raw, dates_2020_in=None):
    """Get weekly hospitalisation data from OWID data set.

    Args:
        owid_in (OWID data retrieval object): OWID data retrieval object.
        dates_2020_in (array or list): List of considered dates in 2020.
    Returns:
        Xarray: Weekly hospitalisation data."""
    
    H_data = transform_data(H_raw)
    
    return H_data

def get_logH_transformed(logH_raw, dates_2020_in=None):

    logH_transformed = transform_data(logH_raw)

    return logH_transformed

def get_D_raw(owid_in, dates_2020_in=None):
    """Get weekly death data from OWID data set.

    Args:
        owid_in (OWID data retrieval object): OWID data retrieval object.
        dates_2020_in (array or list): List of considered dates in 2020.
    Returns:
        Xarray: Weekly death data.
    """
    D_data = owid_in._filter(
        value="new_deaths_smoothed_per_million",
        country="Germany",
    )
    if dates_2020_in is None:
        dates_2020_in = get_disease_dates()
    D_data = weekly_formatting(D_data, dates_2020_in)
    D_data = D_data.to_xarray()

    for i in range(37, D_data.size):
        D_data[i] = 0
    
    return D_data

def get_logD_raw(D_data, dates_2020_in=None):

    logD_raw = np.log10(D_data)

    return logD_raw

def get_D_transformed(D_raw, dates_2020_in=None):
    """Get weekly death data from OWID data set.

    Args:
        owid_in (OWID data retrieval object): OWID data retrieval object.
        dates_2020_in (array or list): List of considered dates in 2020.
    Returns:
        Xarray: Weekly death data.
    """

    D_data = transform_data(D_raw)

    return D_data

def get_logD_transformed(logD_raw, dates_2020_in=None):

    logD_transformed = transform_data(logD_raw)

    return logD_transformed

# Growth Multiplier
def get_G_raw(dates_2020_in):
    growthmultiplier_df = pd.read_csv("data/incidence/IncidenceGrowthMultiplier.csv", parse_dates=True, index_col=0)

    ### filter for mobility_dates_2020
    growthmultiplier_df_2020 = growthmultiplier_df[growthmultiplier_df.index.isin(dates_2020_in)]
    growthmultiplier_df_2020 = growthmultiplier_df_2020[growthmultiplier_df_2020["Bundesland"] == "Deutschland"]

    growth_counter_2020 = growthmultiplier_df_2020["cOI"].to_xarray()

    return  growth_counter_2020

def get_G_transformed(G_raw, dates=None):

    growth_counter_2020 = transform_data(G_raw)

    return  growth_counter_2020

## School

def get_school_vacations(dates_2020_in):

    school_df = pd.read_csv("data/school_vacations/school_vacations_germany_weekly.csv", parse_dates=True, index_col=0)

    ### filter for mobility_dates_2020
    school_df_2020 = school_df[school_df.index.isin(dates_2020_in)]
    school_df_2020 = school_df_2020[school_df_2020["federalState"] == "Deutschland"]

    school_counter_2020 = school_df_2020["schoolVacation"].to_xarray()

    return  school_counter_2020 

## Public holidays

def get_pub_holidays(dates_2020_in):

    pubHolidays_df = pd.read_csv("data/public_holidays/public_holidays_germany_weekly.csv", parse_dates=True, index_col=0)

    ### filter for mobility_dates_2020
    pubHolidays_df_2020 = pubHolidays_df[pubHolidays_df.index.isin(dates_2020_in)]
    pubHolidays_df_2020 = pubHolidays_df_2020[pubHolidays_df_2020["Bundesland"] == "Deutschland"]

    pubHolidays_counter_2020 = pubHolidays_df_2020["pubHoliday"].to_xarray()

    return  pubHolidays_counter_2020  

## Precipitation

def get_precipitation(dates_2020_in):

    precipitation_df = pd.read_csv("/Users/sydney/git/mobility_inference/data/weather/tmax_tavg_prcp_fed.csv", parse_dates=True, index_col=0)

    ### filter for mobility_dates_2020
    precipitation_df_2020 = precipitation_df[precipitation_df.index.isin(dates_2020_in)]
    precipitation_df_2020 = precipitation_df_2020[precipitation_df_2020["country"] == "Deutschland"]
    
    precipitation_2020 = precipitation_df_2020["prcp"].to_xarray()

    return  precipitation_2020  

## Temperature

def get_temperature(dates_2020_in):

    temperature_df = pd.read_csv("/Users/sydney/git/mobility_inference/data/weather/tmax_tavg_prcp_nat.csv", parse_dates=True, index_col=0)
    ### filter for mobility_dates_2020
    temperature_df_2020 = temperature_df[temperature_df.index.isin(dates_2020_in)]
    temperature_df_2020 = temperature_df_2020[temperature_df_2020["country"] == "Deutschland"]

    temperature_2020 = temperature_df_2020["tmax"].to_xarray()

    return  temperature_2020

# def get_avg_temperature(dates_2020_in):

#     avg_temperature_df = pd.read_csv("/Users/sydney/git/mobility_inference/data/weather/TenYearAvgTemp.csv", parse_dates=True, index_col=0)

#     ### filter for mobility_dates_2020
#     avg_temperature_df_2020 = avg_temperature_df[avg_temperature_df.index.isin(dates_2020_in)]

#     avg_temperature_2020 = avg_temperature_df_2020["tenyearmeantmax"].to_xarray()

#     delta_temperature = get_temperature(dates_2020_in) -  avg_temperature_2020

#     return  delta_temperature  

## Daylight

def get_daylight(dates_2020_in):
    
    daylight_df = pd.read_csv("/Users/sydney/git/mobility_inference/data/daylight/DaylightGermanyweekly.csv", parse_dates=True, index_col=0)

    daylight_df_2020 = daylight_df[daylight_df.index.isin(dates_2020_in)]

    daylight_2020 = daylight_df_2020["daylight"].to_xarray()

    return daylight_2020

## Population density

def get_pop_density(dates_2020_in):

    pop_density_df = pd.read_csv("/Users/sydney/git/mobility_inference/data/population_density/einwohnerinnen_share_area_density_fednat.csv", parse_dates=True, index_col=0)

    pop_density_df_2020 = pop_density_df[pop_density_df.index.isin(dates_2020_in)]
    
    pop_density_row = pop_density_df_2020[pop_density_df_2020["country"] == "Deutschland"]

    pop_density = pop_density_row["EwinohnerInnenJeKm2"].to_xarray()

    return pop_density