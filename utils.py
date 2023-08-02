import numpy as np
import scipy.stats as stats
import pandas as pd


def _cut_off_before_monday(df):
    while df.index[0].dayofweek != 0:
        df = df[1:]
    return df


# weekly average placed on Sunday
def weekly_formatting(df_in, dates_in):
    df = _cut_off_before_monday(df_in)
    df = df.resample("7D").mean()
    df.index = df.index + pd.Timedelta(days=6)
    return df.filter(items=dates_in, axis=0)


# transform data: logistic of z-score
def transform_data(df_in):
    df = stats.zscore(df_in)
    return 1 / (1 + np.exp(-df))


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


# calculate differences between the years
def return_differences(df2020_in, df2022_in, label_in):
    delta = df2020_in[label_in].values - df2022_in[label_in].values
    if label_in == "prcp":
        delta = -delta
    return delta


# calculate average between the years
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
