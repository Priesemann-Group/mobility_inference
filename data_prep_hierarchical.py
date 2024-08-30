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
    df = stats.zscore(df_in)

    return (df - min(df))/(max(df)-min(df))


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
def get_out_of_home_duration(chosen_model):
    """
    Returns:
        Xarray: Out-of-home duration data for 2020.
        Xarray: Baseline out-of-home duration data.
    """
    if chosen_model == "BEHHHB":
        path_mobility = "./data/input_data_hierarchical/inputDataBerlinHHHB.csv"
        baseline_mobility = [8] * 89 * 3
    else:
        path_mobility = "./data/input_data_hierarchical/allVariablesHierarchicalModel.csv"
        baseline_mobility = [8] * 89 * 16
    mobility_df = pd.read_csv(
        path_mobility, parse_dates=True, index_col=0
    )
    #mobility_df = mobility_df[mobility_df["BundeslandID"] == "Deutschland"]
    #mobility_df["week"] = mobility_df.index.isocalendar().week

    ### get dates
    mobility_dates = mobility_df.index.values

    #dates_2020 = mobility_dates[mobility_dates < np.datetime64("2020-12-20")]
    #mobility_dates_2020 = dates_2020[dates_2020 > np.datetime64("2020-03-29")]
    #mobility_dates_2022 = mobility_dates[mobility_dates < np.datetime64("2022-12-20")]
    #mobility_dates_2022_shortened = mobility_dates_2022[-len(mobility_dates_2020) :]

    ### get out of home duration data
    #mobility_df_2020 = mobility_df.filter(items=mobility_dates_2020, axis=0)
    mobility_data_2020 = mobility_df["outOfHomeDuration"].to_xarray()

    return (
        mobility_data_2020,
        baseline_mobility,
        mobility_dates
    )

## Out of home duration
def get_out_of_home_duration_long(chosen_model):
    """
    Returns:
        Xarray: Out-of-home duration data for 2020.
        Xarray: Baseline out-of-home duration data.
    """
    if chosen_model == "BEHHHB":
        path_mobility = "./data/input_data_hierarchical/inputDataBerlinHHHB_long.csv"
        baseline_mobility = [8] * 92 * 3
    else:
        path_mobility = "./data/input_data_hierarchical/allVariablesHierarchicalModel_long.csv"
        baseline_mobility = [8] * 92 * 16
    mobility_df = pd.read_csv(
        path_mobility, parse_dates=True, index_col=0
    )
    #mobility_df = mobility_df[mobility_df["BundeslandID"] == "Deutschland"]
    #mobility_df["week"] = mobility_df.index.isocalendar().week

    ### get dates
    mobility_dates = mobility_df.index.values

    #dates_2020 = mobility_dates[mobility_dates < np.datetime64("2020-12-20")]
    #mobility_dates_2020 = dates_2020[dates_2020 > np.datetime64("2020-03-29")]
    #mobility_dates_2022 = mobility_dates[mobility_dates < np.datetime64("2022-12-20")]
    #mobility_dates_2022_shortened = mobility_dates_2022[-len(mobility_dates_2020) :]

    ### get out of home duration data
    #mobility_df_2020 = mobility_df.filter(items=mobility_dates_2020, axis=0)
    mobility_data_2020 = mobility_df["outOfHomeDuration"].to_xarray()

    return (
        mobility_data_2020,
        baseline_mobility,
        mobility_dates
    )

## R
def get_R_raw(chosen_model):
    """Get weekly R_eff data based on cov19 repo

    Args:
        None
    Returns:
        Xarray: Weekly R data.

    """
    if chosen_model == "BEHHHB":
        path_R = "./data/input_data_hierarchical/inputDataBerlinHHHB_long.csv"
    else:
        path_R = "./data/input_data_hierarchical/allVariablesHierarchicalModel_long.csv"
    R_df = pd.read_csv(path_R, index_col=0, parse_dates=True)

    #df = transform_data(df["PS_7_Tage_R_Wert"])
    R_data = R_df["Reffective"].to_xarray()
    return R_data

def get_logR_raw(R_raw):

    logR = np.log10(R_raw)

    return logR

def get_R_transformed(R_raw, chosen_model):

    """Get normalized, weekly R_eff data based on cov19 repo

    Args:
        None
    Returns:
        Xarray: Weekly R data.

    """
    if chosen_model == "BEHHHB":
        path_R = "./data/input_data_hierarchical/inputDataBerlinHHHB_long.csv"
    else: 
        path_R = "./data/input_data_hierarchical/allVariablesHierarchicalModel_long.csv"
    R_df = pd.read_csv(path_R, index_col=0, parse_dates=True)

    #df = transform_data(df["PS_7_Tage_R_Wert"])
    R_transformed = R_df["Reffective"].to_xarray()
    return R_transformed

def get_logR_transformed(logR):

    logR_transformed = transform_data(logR)

    return logR_transformed

### Cases
def get_C_raw(chosen_model):
    """Get weekly case data from preprocessed data.

    Args:
        None 
    Returns:
       Xarray: 7-Day Cases Incidence/100,000 

    """
    if chosen_model == "BEHHHB":
        path_cases = "./data/input_data_hierarchical/inputDataBerlinHHHB_long.csv"
    else:
        path_cases = "./data/input_data_hierarchical/allVariablesHierarchicalModel_long.csv"
    cases_df = pd.read_csv(path_cases, index_col=0, parse_dates=True)

    #case_data = cases_df[["fedState","Infection_Incidence", "timeCounter"]]
    case_data = cases_df["Infection_Incidence"].to_xarray()

    return case_data

def get_logC_raw(chosen_model):
    """Get log(weekly case data) from preprocessed data.

    Args:
       Xarray: 7-Day Cases Incidence/100,000
    Returns:
       Xarray: log_10(7-Day Cases Incidence/100,000)

    """
    if chosen_model == "BEHHHB":
        path_cases = "./data/input_data_hierarchical/inputDataBerlinHHHB.csv"
    else:
        path_cases = "./data/input_data_hierarchical/allVariablesHierarchicalModel.csv"
    cases_df = pd.read_csv(path_cases, index_col=0, parse_dates=True)

    case_data = cases_df["logInfection_Incidence"].to_xarray()

    return case_data

def get_C_transformed(chosen_model):
    """Get normalized (standardized + mapped to [0,1]) weekly case data from preprocessed data.

    Args:
        None
    Returns:
        Xarray: Normalized 7-Day Cases Incidence/100,000.

    """
    if chosen_model == "BEHHHB":
        path_cases = "./data/input_data_hierarchical/inputDataBerlinHHHB_long.csv"
    else:
        path_cases = "./data/input_data_hierarchical/allVariablesHierarchicalModel_long.csv"
    cases_df = pd.read_csv(path_cases, index_col=0, parse_dates=True)

    case_data = cases_df["Infection_Incidence_Norm"].to_xarray()
   
    #case_data = cases_df[["fedState","Infection_Incidence_Norm", "timeCounter"]]
   
    return case_data

def get_logC_transformed (chosen_model):

    if chosen_model == "BEHHHB":
        path_cases = "./data/input_data_hierarchical/inputDataBerlinHHHB.csv"
    else:
        path_cases = "./data/input_data_hierarchical/allVariablesHierarchicalModel.csv"
    cases_df = pd.read_csv(path_cases, index_col=0, parse_dates=True)

    case_data = cases_df["logInfection_Incidence_Norm"].to_xarray()
   
    return case_data

### ICU TODO : FOR NOW, ICU NOT PART OF HIERARCHICAL MODEL
# def get_ICU_raw(owid_in, dates_2020_in=None):
#     """Get weekly ICU data from OWID data set.

#     Args:
#         owid_in (OWID data retrieval object): OWID data retrieval object.
#         dates_2020_in (array or list): List of considered dates in 2020.
#     Returns:
#         Xarray: Weekly ICU data.
#     """
#     ICU_data = owid_in._filter(
#         value="icu_patients_per_million",
#         country="Germany",
#     )
#     if dates_2020_in is None:
#         dates_2020_in = get_disease_dates(ICU=True)
#     ICU_data = weekly_formatting(ICU_data, dates_2020_in)
#     ICU_data = ICU_data.to_xarray()
#     return ICU_data

# def get_logICU_raw(ICU_data, dates_2020_in=None):

#     logICU_raw = np.log10(ICU_data)

#     return logICU_raw

# def get_ICU_transformed(ICU_data, dates_2020_in=None):
#     """Get weekly ICU data from OWID data set.

#     Args:
#         TODO
#     Returns:
#         Xarray: TODO
#     """

#     ICU_data = transform_data(ICU_data)
    
#     return ICU_data

# def get_logICU_transformed(logICU_raw, dates_2020_in=None):

#     logICU_transformed = transform_data(logICU_raw)

#     return logICU_transformed

### Hospitalisations
def get_H_raw(chosen_model):
    """Get weekly hospitalisation data from preprocessed data set.

    Args:
        None
    Returns:
        Xarray: 7-Day Hospital Incidence/100,000.
        
    """

    if chosen_model == "BEHHHB":
        path_hospital= "./data/input_data_hierarchical/inputDataBerlinHHHB_long.csv"
    else:    
        path_hospital = "./data/input_data_hierarchical/allVariablesHierarchicalModel_long.csv"
    hospital_df = pd.read_csv(path_hospital, index_col=0, parse_dates=True)

    hospital_data = hospital_df["Hospital_Incidence"].to_xarray()

    return hospital_data

def get_logH_raw(chosen_model):
    """Get log(weekly hospitalisation data) from preprocessed data set.

    Args:
        Xarray: 7-Day Hospital Incidence/100,000.
    Returns:
        Xarray: log_10(7-Day Hospital Incidence/100,000).
        
    """
    if chosen_model == "BEHHHB":
        path_hospital = "./data/input_data_hierarchical/inputDataBerlinHHHB_long.csv"
    else:
        path_hospital = "./data/input_data_hierarchical/allVariablesHierarchicalModel_long.csv"
    hospital_df = pd.read_csv(path_hospital, index_col=0, parse_dates=True)

    hospital_data = hospital_df["logHospital_Incidence"].to_xarray()

    return hospital_data

def get_H_transformed(chosen_model):
    """Get normalized (standardized + mapped to [0,1]) weekly hospitalisation data from preprocessed data set.

    Args:
        None
    Returns:
        Xarray: Normalized 7-Day Hospital Incidence/100,000.
        
    """
    if chosen_model == "BEHHHB":
        path_hospital = "./data/input_data_hierarchical/inputDataBerlinHHHB_long.csv"
    else:
        path_hospital = "./data/input_data_hierarchical/allVariablesHierarchicalModel_long.csv"
    H_df = pd.read_csv(path_hospital, index_col=0, parse_dates=True)

    H_data = H_df["Hospital_Incidence_Norm"].to_xarray()
    
    return H_data

def get_logH_transformed(chosen_model):

    if chosen_model == "BEHHHB":
        path_hospital = "./data/input_data_hierarchical/inputDataBerlinHHHB.csv"
    else:
        path_hospital = "./data/input_data_hierarchical/allVariablesHierarchicalModel.csv"
    H_df = pd.read_csv(path_hospital, index_col=0, parse_dates=True)

    H_data = H_df["logHospital_Incidence_Norm"].to_xarray()
    
    return H_data

def get_D_raw(chosen_model):
    """Get weekly death data from preprocessed data set.

    Args:
        None
    Returns:
        Xarray: 7-Day Death Incidence/100,000.
        
    """
    if chosen_model == "BEHHHB":
        path_death = "./data/input_data_hierarchical/inputDataBerlinHHHB.csv"
    else:
        path_death = "./data/input_data_hierarchical/allVariablesHierarchicalModel.csv"
    D_df = pd.read_csv(path_death, index_col=0, parse_dates=True)

    D_data = D_df["Death_Incidence"].to_xarray()
    
    return D_data

def get_logD_raw(chosen_model):
    """Get log(weekly hospitalisation data) from preprocessed data set.

    Args:
        Xarray: 7-Day Death Incidence/100,000
    Returns:
        Xarray: log_10(7-Day Death Incidence/100,000).
        
    """
    if chosen_model == "BEHHHB":
        path_death = "./data/input_data_hierarchical/inputDataBerlinHHHB.csv"
    else:
        path_death = "./data/input_data_hierarchical/allVariablesHierarchicalModel.csv"
    D_df = pd.read_csv(path_death, index_col=0, parse_dates=True)

    D_data = D_df["logDeath_Incidence"].to_xarray()
    
    return D_data

def get_D_transformed(chosen_model):
    """Get normalized (standardized + mapped to [0,1]) weekly death data from preprocessed data set.

    Args:
        None.
    Returns:
        Xarray: Normalized 7-Day Death Incidence/100,000.
        
    """
    if chosen_model == "BEHHHB":
        path_death = "./data/input_data_hierarchical/inputDataBerlinHHHB.csv"
    else:
        path_death = "./data/input_data_hierarchical/allVariablesHierarchicalModel.csv"
    D_df = pd.read_csv(path_death, index_col=0, parse_dates=True)

    D_data = D_df["Death_Incidence_Norm"].to_xarray()

    return D_data

def get_logD_transformed(chosen_model):
    if chosen_model == "BEHHHB":
        path_death = "./data/input_data_hierarchical/inputDataBerlinHHHB.csv"
    else:
        path_death = "./data/input_data_hierarchical/allVariablesHierarchicalModel.csv"
    D_df = pd.read_csv(path_death, index_col=0, parse_dates=True)

    D_data = D_df["logDeath_Incidence_Norm"].to_xarray()

    return D_data


## School

def get_school_vacations(chosen_model):
    """Get weekly no. of school vacation days from preprocessed data set.

    Args:
        None
    Returns:
        Xarray: School vacation data.
        
    """
    if chosen_model == "BEHHHB":
        path_school = "./data/input_data_hierarchical/inputDataBerlinHHHB.csv"
    else:
        path_school = "./data/input_data_hierarchical/allVariablesHierarchicalModel.csv"
    school_df = pd.read_csv(path_school, index_col=0, parse_dates=True)

    school_data = school_df["schoolVacation"].to_xarray()

    return  school_data

## Public holidays

def get_pub_holidays(chosen_model):
    """Get weekly no. of public holidays data from preprocessed data set.

    Args:
        None
    Returns:
        Xarray: Public holiday data.
        
    """

    if chosen_model == "BEHHHB":
        path_pubHol = "./data/input_data_hierarchical/inputDataBerlinHHHB.csv"
    else:
        path_pubHol = "./data/input_data_hierarchical/allVariablesHierarchicalModel.csv"
    pubHol_df = pd.read_csv(path_pubHol, index_col=0, parse_dates=True)

    pubHolidays_data  = pubHol_df["pubHoliday"].to_xarray()

    return  pubHolidays_data  

def get_counter(chosen_model):
    """counter since start of pandemic.

    Args:
        None

        
    """

    if chosen_model == "BEHHHB":
        path_counter = "./data/input_data_hierarchical/inputDataBerlinHHHB.csv"
    else:
        path_counter = "./data/input_data_hierarchical/allVariablesHierarchicalModel.csv"
    counter_df = pd.read_csv(path_counter, index_col=0, parse_dates=True)

    counter_data  = counter_df["timeCounter"].to_xarray()

    return  counter_data 

def get_counter_long(chosen_model):
    """counter since start of pandemic.

    Args:
        None

        
    """

    if chosen_model == "BEHHHB":
        path_counter = "./data/input_data_hierarchical/inputDataBerlinHHHB_long.csv"
    else:
        path_counter = "./data/input_data_hierarchical/allVariablesHierarchicalModel_long.csv"
    counter_df = pd.read_csv(path_counter, index_col=0, parse_dates=True)

    counter_data  = counter_df["timeCounter"].to_xarray()

    return  counter_data  

## Precipitation

def get_precipitation(chosen_model):
    """Get weekly precipitation data from preprocessed data set.

    Args:
        None
    Returns:
        Xarray: Weekly precipitation (in mm).
        
    """
    if chosen_model == "BEHHHB":
        path_prcp = "./data/input_data_hierarchical/inputDataBerlinHHHB.csv"
    else:    
        path_prcp = "./data/input_data_hierarchical/allVariablesHierarchicalModel.csv"
    precipitation_df = pd.read_csv(path_prcp, index_col=0, parse_dates=True)

    precipitation_data  = precipitation_df["prcp"].to_xarray()

    return  precipitation_data  

## Temperature

def get_temperature(chosen_model):
    """Get weekly average temperature data from preprocessed data set.

    Args:
        None
    Returns:
        Xarray: Max Temp.
        
    """

    if chosen_model == "BEHHHB":
        path_temp = "./data/input_data_hierarchical/inputDataBerlinHHHB.csv"
    else:
        path_temp = "./data/input_data_hierarchical/allVariablesHierarchicalModel.csv"
    temp_df = pd.read_csv(path_temp, index_col=0, parse_dates=True)

    temperature_data  = temp_df["tmax"].to_xarray()

    return  temperature_data

# def get_avg_temperature(dates_2020_in):

#     avg_temperature_df = pd.read_csv("/Users/sydney/git/mobility_inference/data/weather/TenYearAvgTemp.csv", parse_dates=True, index_col=0)

#     ### filter for mobility_dates_2020
#     avg_temperature_df_2020 = avg_temperature_df[avg_temperature_df.index.isin(dates_2020_in)]

#     avg_temperature_2020 = avg_temperature_df_2020["tenyearmeantmax"].to_xarray()

#     delta_temperature = get_temperature(dates_2020_in) -  avg_temperature_2020

#     return  delta_temperature  

## Daylight

def get_daylight(chosen_model):
    """Get weekly average of daylight data from preprocessed data set.

    Args:
        None
    Returns:
        Xarray: Daylight [hrs].
        
    """
    if chosen_model == "BEHHHB":
        path_daylight = "./data/input_data_hierarchical/inputDataBerlinHHHB.csv"
    else:
        path_daylight = "./data/input_data_hierarchical/allVariablesHierarchicalModel.csv"
    daylight_df = pd.read_csv(path_daylight, index_col=0, parse_dates=True)

    daylight_data  = daylight_df["daylight"].to_xarray()

    return daylight_data

## Population density

def get_pop_density(chosen_model):
    """Get population density from preprocessed data set.

    Args:
        None
    Returns:
        Xarray: Population density [pop/km^2].
        
    """

    if chosen_model == "BEHHHB":
        pop_density_df = pd.read_csv("./data/input_data_hierarchical/inputDataBerlinHHHB.csv", parse_dates=True, index_col=0)
    else:
        pop_density_df = pd.read_csv("./data/input_data_hierarchical/allVariablesHierarchicalModel.csv", parse_dates=True, index_col=0)

    pop_density = pop_density_df["EinwohnerInnenJeKm2"].to_xarray()

    return pop_density

## Federal states

def get_federal_states(chosen_model):
    """Get index-array

    Args:
        None.
    Returns:
        Xarray: Names of federal states.
        
    """
    if chosen_model == "BEHHHB":
        path_fedStates = "./data/input_data_hierarchical/inputDataBerlinHHHB.csv"
    else:    
        path_fedStates = "./data/input_data_hierarchical/allVariablesHierarchicalModel.csv"
    fedStates_df = pd.read_csv(path_fedStates)

    fedStates_df.federalState = fedStates_df.federalState.map(str.strip)

    fedState, fed_States = fedStates_df.federalState.factorize()

    obs_id = fedStates_df.index

    return fedState, fed_States, obs_id

def get_federal_states_long(chosen_model):
    """Get index-array

    Args:
        None.
    Returns:
        Xarray: Names of federal states.
        
    """
    if chosen_model == "BEHHHB":
        path_fedStates = "./data/input_data_hierarchical/inputDataBerlinHHHB_long.csv"
    else:    
        path_fedStates = "./data/input_data_hierarchical/allVariablesHierarchicalModel_long.csv"
    fedStates_df = pd.read_csv(path_fedStates)

    fedStates_df.federalState = fedStates_df.federalState.map(str.strip)

    fedState, fed_States = fedStates_df.federalState.factorize()

    obs_id = fedStates_df.index

    return fedState, fed_States, obs_id

def get_index_long(chosen_model):
    """
    Args:
       
    Returns:

    """
    if chosen_model == "BEHHHB":
        path_cases = "./data/input_data_hierarchical/inputDataBerlinHHHB_long.csv"
    else:
        path_cases = "./data/input_data_hierarchical/allVariablesHierarchicalModel_long.csv"
    cases_df = pd.read_csv(path_cases)

    cases_df.federalState = cases_df.federalState.map(str.strip)

    fedState, fed_States = cases_df.federalState.factorize()

    obs_id_long = cases_df.index

    return obs_id_long