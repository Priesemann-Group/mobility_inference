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


def get_NPI_data(filename_in, dates_in):
    df = pd.read_csv(filename_in, index_col=2, parse_dates=True)
    df = df[df["Entity"] == "Germany"]
    return weekly_formatting(df, dates_in)
