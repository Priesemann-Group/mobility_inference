##Boxplots over time
library(tidyverse)
library(smplot2)

#model <- "2025-07-02_400LK_exp_UsedForPostprocessing"
#model <- "2025-08-20_400_notest"
model <- "2025-09-14_400_cluster_expdecay_wideealpha"
#model <- "2026-05-26_2024_c"

diseaseFactor <- read_csv(paste0("/Users/sydney/git/mobility_inference/results/", model, "/d_C.csv"))
diseaseFactor <- read_csv(paste0("/Users/sydney/Desktop/BayesProjectMathcluster/", model, "/d_C.csv"))
diseaseFactor <- diseaseFactor %>% mutate(index = ceiling(seq_len(nrow(diseaseFactor)) / 52)-1)
colnames(diseaseFactor)[1] <- "rowNumberMinus1"
colnames(diseaseFactor)[2] <- "value"
diseaseFactor <- diseaseFactor %>% mutate(Date = case_when(rowNumberMinus1 %% 52 == 0 ~ "2020-03-08",
                                                           rowNumberMinus1 %% 52 == 1 ~ "2020-03-15",
                                                           rowNumberMinus1 %% 52 == 2 ~ "2020-03-22",
                                                           rowNumberMinus1 %% 52 == 3 ~ "2020-03-29",
                                                           rowNumberMinus1 %% 52 == 4 ~ "2020-04-05",
                                                           rowNumberMinus1 %% 52 == 5 ~ "2020-04-12",
                                                           rowNumberMinus1 %% 52 == 6 ~ "2020-04-19",
                                                           rowNumberMinus1 %% 52 == 7 ~ "2020-04-26",
                                                           rowNumberMinus1 %% 52 == 8 ~ "2020-05-03",
                                                           rowNumberMinus1 %% 52 == 9 ~ "2020-05-10",
                                                           rowNumberMinus1 %% 52 == 10 ~ "2020-05-17",
                                                           rowNumberMinus1 %% 52 == 11 ~ "2020-05-24",
                                                           rowNumberMinus1 %% 52 == 12 ~ "2020-05-31",
                                                           rowNumberMinus1 %% 52 == 13 ~ "2020-06-07",
                                                           rowNumberMinus1 %% 52 == 14 ~ "2020-06-14",
                                                           rowNumberMinus1 %% 52 == 15 ~ "2020-06-21",
                                                           rowNumberMinus1 %% 52 == 16 ~ "2020-06-28",
                                                           rowNumberMinus1 %% 52 == 17 ~ "2020-07-05",
                                                           rowNumberMinus1 %% 52 == 18 ~ "2020-07-12",
                                                           rowNumberMinus1 %% 52 == 19 ~ "2020-07-19",
                                                           rowNumberMinus1 %% 52 == 20 ~ "2020-07-26",
                                                           rowNumberMinus1 %% 52 == 21 ~ "2020-08-02",
                                                           rowNumberMinus1 %% 52 == 22 ~ "2020-08-09",
                                                           rowNumberMinus1 %% 52 == 23 ~ "2020-08-16",
                                                           rowNumberMinus1 %% 52 == 24 ~ "2020-08-23",
                                                           rowNumberMinus1 %% 52 == 25 ~ "2020-08-30",
                                                           rowNumberMinus1 %% 52 == 26 ~ "2020-09-06",
                                                           rowNumberMinus1 %% 52 == 27 ~ "2020-09-13",
                                                           rowNumberMinus1 %% 52 == 28 ~ "2020-09-20",
                                                           rowNumberMinus1 %% 52 == 29 ~ "2020-09-27",
                                                           rowNumberMinus1 %% 52 == 30 ~ "2020-10-04",
                                                           rowNumberMinus1 %% 52 == 31 ~ "2020-10-11",
                                                           rowNumberMinus1 %% 52 == 32 ~ "2020-10-18",
                                                           rowNumberMinus1 %% 52 == 33 ~ "2020-10-25",
                                                           rowNumberMinus1 %% 52 == 34 ~ "2020-11-01",
                                                           rowNumberMinus1 %% 52 == 35 ~ "2020-11-08",
                                                           rowNumberMinus1 %% 52 == 36 ~ "2020-11-15",
                                                           rowNumberMinus1 %% 52 == 37 ~ "2020-11-22",
                                                           rowNumberMinus1 %% 52 == 38 ~ "2020-11-29",
                                                           rowNumberMinus1 %% 52 == 39 ~ "2020-12-06",
                                                           rowNumberMinus1 %% 52 == 40 ~ "2020-12-13",
                                                           rowNumberMinus1 %% 52 == 41 ~ "2020-12-20",
                                                           rowNumberMinus1 %% 52 == 42 ~ "2020-12-27",
                                                           rowNumberMinus1 %% 52 == 43 ~ "2021-01-03",
                                                           rowNumberMinus1 %% 52 == 44 ~ "2021-01-10",
                                                           rowNumberMinus1 %% 52 == 45 ~ "2021-01-17",
                                                           rowNumberMinus1 %% 52 == 46 ~ "2021-01-24",
                                                           rowNumberMinus1 %% 52 == 47 ~ "2021-01-31",
                                                           rowNumberMinus1 %% 52 == 48 ~ "2021-02-07",
                                                           rowNumberMinus1 %% 52 == 49 ~ "2021-02-14",
                                                           rowNumberMinus1 %% 52 == 50 ~ "2021-02-21",
                                                           rowNumberMinus1 %% 52 == 51 ~ "2021-02-28"))
diseaseFactor <- diseaseFactor %>% select(index, Date, value) %>% mutate(Type = "Disease")
diseaseFactor$Date <- as.Date(diseaseFactor$Date)

temperatureFactor <- read_csv(paste0("/Users/sydney/git/mobility_inference/results/", model, "/temperature_factor.csv"))
temperatureFactor <- read_csv(paste0("/Users/sydney/Desktop/BayesProjectMathcluster/", model,  "/temperature_factor.csv"))
temperatureFactor <- temperatureFactor %>% mutate(index = ceiling(seq_len(nrow(temperatureFactor)) / 52)-1)
colnames(temperatureFactor)[1] <- "rowNumberMinus1"
colnames(temperatureFactor)[2] <- "value"
temperatureFactor <- temperatureFactor %>% mutate(Date = case_when(rowNumberMinus1 %% 52 == 0 ~ "2020-03-08",
                                                           rowNumberMinus1 %% 52 == 1 ~ "2020-03-15",
                                                           rowNumberMinus1 %% 52 == 2 ~ "2020-03-22",
                                                           rowNumberMinus1 %% 52 == 3 ~ "2020-03-29",
                                                           rowNumberMinus1 %% 52 == 4 ~ "2020-04-05",
                                                           rowNumberMinus1 %% 52 == 5 ~ "2020-04-12",
                                                           rowNumberMinus1 %% 52 == 6 ~ "2020-04-19",
                                                           rowNumberMinus1 %% 52 == 7 ~ "2020-04-26",
                                                           rowNumberMinus1 %% 52 == 8 ~ "2020-05-03",
                                                           rowNumberMinus1 %% 52 == 9 ~ "2020-05-10",
                                                           rowNumberMinus1 %% 52 == 10 ~ "2020-05-17",
                                                           rowNumberMinus1 %% 52 == 11 ~ "2020-05-24",
                                                           rowNumberMinus1 %% 52 == 12 ~ "2020-05-31",
                                                           rowNumberMinus1 %% 52 == 13 ~ "2020-06-07",
                                                           rowNumberMinus1 %% 52 == 14 ~ "2020-06-14",
                                                           rowNumberMinus1 %% 52 == 15 ~ "2020-06-21",
                                                           rowNumberMinus1 %% 52 == 16 ~ "2020-06-28",
                                                           rowNumberMinus1 %% 52 == 17 ~ "2020-07-05",
                                                           rowNumberMinus1 %% 52 == 18 ~ "2020-07-12",
                                                           rowNumberMinus1 %% 52 == 19 ~ "2020-07-19",
                                                           rowNumberMinus1 %% 52 == 20 ~ "2020-07-26",
                                                           rowNumberMinus1 %% 52 == 21 ~ "2020-08-02",
                                                           rowNumberMinus1 %% 52 == 22 ~ "2020-08-09",
                                                           rowNumberMinus1 %% 52 == 23 ~ "2020-08-16",
                                                           rowNumberMinus1 %% 52 == 24 ~ "2020-08-23",
                                                           rowNumberMinus1 %% 52 == 25 ~ "2020-08-30",
                                                           rowNumberMinus1 %% 52 == 26 ~ "2020-09-06",
                                                           rowNumberMinus1 %% 52 == 27 ~ "2020-09-13",
                                                           rowNumberMinus1 %% 52 == 28 ~ "2020-09-20",
                                                           rowNumberMinus1 %% 52 == 29 ~ "2020-09-27",
                                                           rowNumberMinus1 %% 52 == 30 ~ "2020-10-04",
                                                           rowNumberMinus1 %% 52 == 31 ~ "2020-10-11",
                                                           rowNumberMinus1 %% 52 == 32 ~ "2020-10-18",
                                                           rowNumberMinus1 %% 52 == 33 ~ "2020-10-25",
                                                           rowNumberMinus1 %% 52 == 34 ~ "2020-11-01",
                                                           rowNumberMinus1 %% 52 == 35 ~ "2020-11-08",
                                                           rowNumberMinus1 %% 52 == 36 ~ "2020-11-15",
                                                           rowNumberMinus1 %% 52 == 37 ~ "2020-11-22",
                                                           rowNumberMinus1 %% 52 == 38 ~ "2020-11-29",
                                                           rowNumberMinus1 %% 52 == 39 ~ "2020-12-06",
                                                           rowNumberMinus1 %% 52 == 40 ~ "2020-12-13",
                                                           rowNumberMinus1 %% 52 == 41 ~ "2020-12-20",
                                                           rowNumberMinus1 %% 52 == 42 ~ "2020-12-27",
                                                           rowNumberMinus1 %% 52 == 43 ~ "2021-01-03",
                                                           rowNumberMinus1 %% 52 == 44 ~ "2021-01-10",
                                                           rowNumberMinus1 %% 52 == 45 ~ "2021-01-17",
                                                           rowNumberMinus1 %% 52 == 46 ~ "2021-01-24",
                                                           rowNumberMinus1 %% 52 == 47 ~ "2021-01-31",
                                                           rowNumberMinus1 %% 52 == 48 ~ "2021-02-07",
                                                           rowNumberMinus1 %% 52 == 49 ~ "2021-02-14",
                                                           rowNumberMinus1 %% 52 == 50 ~ "2021-02-21",
                                                           rowNumberMinus1 %% 52 == 51 ~ "2021-02-28"))
temperatureFactor <- temperatureFactor %>% mutate(Date = case_when(rowNumberMinus1 %% 52 == 0 ~ "2024-01-07",
                                                                   rowNumberMinus1 %% 52 == 1 ~ "2024-01-14",
                                                                   rowNumberMinus1 %% 52 == 2 ~ "2024-01-21",
                                                                   rowNumberMinus1 %% 52 == 3 ~ "2024-01-28",
                                                                   rowNumberMinus1 %% 52 == 4 ~ "2024-02-04",
                                                                   rowNumberMinus1 %% 52 == 5 ~ "2024-02-11",
                                                                   rowNumberMinus1 %% 52 == 6 ~ "2024-02-18",
                                                                   rowNumberMinus1 %% 52 == 7 ~ "2024-02-25",
                                                                   rowNumberMinus1 %% 52 == 8 ~ "2024-03-03",
                                                                   rowNumberMinus1 %% 52 == 9 ~ "2024-03-10",
                                                                   rowNumberMinus1 %% 52 == 10 ~ "2024-03-17",
                                                                   rowNumberMinus1 %% 52 == 11 ~ "2024-03-24",
                                                                   rowNumberMinus1 %% 52 == 12 ~ "2024-03-31",
                                                                   rowNumberMinus1 %% 52 == 13 ~ "2024-04-07",
                                                                   rowNumberMinus1 %% 52 == 14 ~ "2024-04-14",
                                                                   rowNumberMinus1 %% 52 == 15 ~ "2024-04-21",
                                                                   rowNumberMinus1 %% 52 == 16 ~ "2024-04-28",
                                                                   rowNumberMinus1 %% 52 == 17 ~ "2024-05-05",
                                                                   rowNumberMinus1 %% 52 == 18 ~ "2024-05-12",
                                                                   rowNumberMinus1 %% 52 == 19 ~ "2024-05-19",
                                                                   rowNumberMinus1 %% 52 == 20 ~ "2024-05-26",
                                                                   rowNumberMinus1 %% 52 == 21 ~ "2024-06-02",
                                                                   rowNumberMinus1 %% 52 == 22 ~ "2024-06-09",
                                                                   rowNumberMinus1 %% 52 == 23 ~ "2024-06-16",
                                                                   rowNumberMinus1 %% 52 == 24 ~ "2024-06-23",
                                                                   rowNumberMinus1 %% 52 == 25 ~ "2024-06-30",
                                                                   rowNumberMinus1 %% 52 == 26 ~ "2024-07-07",
                                                                   rowNumberMinus1 %% 52 == 27 ~ "2024-07-14",
                                                                   rowNumberMinus1 %% 52 == 28 ~ "2024-07-21",
                                                                   rowNumberMinus1 %% 52 == 29 ~ "2024-07-28",
                                                                   rowNumberMinus1 %% 52 == 30 ~ "2024-08-04",
                                                                   rowNumberMinus1 %% 52 == 31 ~ "2024-08-11",
                                                                   rowNumberMinus1 %% 52 == 32 ~ "2024-08-18",
                                                                   rowNumberMinus1 %% 52 == 33 ~ "2024-08-25",
                                                                   rowNumberMinus1 %% 52 == 34 ~ "2024-09-01",
                                                                   rowNumberMinus1 %% 52 == 35 ~ "2024-09-08",
                                                                   rowNumberMinus1 %% 52 == 36 ~ "2024-09-15",
                                                                   rowNumberMinus1 %% 52 == 37 ~ "2024-09-22",
                                                                   rowNumberMinus1 %% 52 == 38 ~ "2024-09-29",
                                                                   rowNumberMinus1 %% 52 == 39 ~ "2024-10-06",
                                                                   rowNumberMinus1 %% 52 == 40 ~ "2024-10-13",
                                                                   rowNumberMinus1 %% 52 == 41 ~ "2024-10-20",
                                                                   rowNumberMinus1 %% 52 == 42 ~ "2024-10-27",
                                                                   rowNumberMinus1 %% 52 == 43 ~ "2024-11-03",
                                                                   rowNumberMinus1 %% 52 == 44 ~ "2024-11-10",
                                                                   rowNumberMinus1 %% 52 == 45 ~ "2024-11-17",
                                                                   rowNumberMinus1 %% 52 == 46 ~ "2024-11-24",
                                                                   rowNumberMinus1 %% 52 == 47 ~ "2024-12-01",
                                                                   rowNumberMinus1 %% 52 == 48 ~ "2024-12-08",
                                                                   rowNumberMinus1 %% 52 == 49 ~ "2024-12-15",
                                                                   rowNumberMinus1 %% 52 == 50 ~ "2024-12-22",
                                                                   rowNumberMinus1 %% 52 == 51 ~ "2024-12-29"))

temperatureFactor <- temperatureFactor %>% select(index, Date, value) %>% mutate(Type = "Temperature")
temperatureFactor$Date <- as.Date(temperatureFactor$Date)

vacationFactor <- read_csv(paste0("/Users/sydney/git/mobility_inference/results/", model, "/vacation_factor.csv"))
vacationFactor <- read_csv(paste0("/Users/sydney/Desktop/BayesProjectMathcluster/", model,  "/vacation_factor.csv"))
vacationFactor <- vacationFactor %>% mutate(index = ceiling(seq_len(nrow(vacationFactor)) / 52)-1)
colnames(vacationFactor)[1] <- "rowNumberMinus1"
colnames(vacationFactor)[2] <- "value"
vacationFactor <- vacationFactor %>% mutate(Date = case_when(rowNumberMinus1 %% 52 == 0 ~ "2020-03-08",
                                                                   rowNumberMinus1 %% 52 == 1 ~ "2020-03-15",
                                                                   rowNumberMinus1 %% 52 == 2 ~ "2020-03-22",
                                                                   rowNumberMinus1 %% 52 == 3 ~ "2020-03-29",
                                                                   rowNumberMinus1 %% 52 == 4 ~ "2020-04-05",
                                                                   rowNumberMinus1 %% 52 == 5 ~ "2020-04-12",
                                                                   rowNumberMinus1 %% 52 == 6 ~ "2020-04-19",
                                                                   rowNumberMinus1 %% 52 == 7 ~ "2020-04-26",
                                                                   rowNumberMinus1 %% 52 == 8 ~ "2020-05-03",
                                                                   rowNumberMinus1 %% 52 == 9 ~ "2020-05-10",
                                                                   rowNumberMinus1 %% 52 == 10 ~ "2020-05-17",
                                                                   rowNumberMinus1 %% 52 == 11 ~ "2020-05-24",
                                                                   rowNumberMinus1 %% 52 == 12 ~ "2020-05-31",
                                                                   rowNumberMinus1 %% 52 == 13 ~ "2020-06-07",
                                                                   rowNumberMinus1 %% 52 == 14 ~ "2020-06-14",
                                                                   rowNumberMinus1 %% 52 == 15 ~ "2020-06-21",
                                                                   rowNumberMinus1 %% 52 == 16 ~ "2020-06-28",
                                                                   rowNumberMinus1 %% 52 == 17 ~ "2020-07-05",
                                                                   rowNumberMinus1 %% 52 == 18 ~ "2020-07-12",
                                                                   rowNumberMinus1 %% 52 == 19 ~ "2020-07-19",
                                                                   rowNumberMinus1 %% 52 == 20 ~ "2020-07-26",
                                                                   rowNumberMinus1 %% 52 == 21 ~ "2020-08-02",
                                                                   rowNumberMinus1 %% 52 == 22 ~ "2020-08-09",
                                                                   rowNumberMinus1 %% 52 == 23 ~ "2020-08-16",
                                                                   rowNumberMinus1 %% 52 == 24 ~ "2020-08-23",
                                                                   rowNumberMinus1 %% 52 == 25 ~ "2020-08-30",
                                                                   rowNumberMinus1 %% 52 == 26 ~ "2020-09-06",
                                                                   rowNumberMinus1 %% 52 == 27 ~ "2020-09-13",
                                                                   rowNumberMinus1 %% 52 == 28 ~ "2020-09-20",
                                                                   rowNumberMinus1 %% 52 == 29 ~ "2020-09-27",
                                                                   rowNumberMinus1 %% 52 == 30 ~ "2020-10-04",
                                                                   rowNumberMinus1 %% 52 == 31 ~ "2020-10-11",
                                                                   rowNumberMinus1 %% 52 == 32 ~ "2020-10-18",
                                                                   rowNumberMinus1 %% 52 == 33 ~ "2020-10-25",
                                                                   rowNumberMinus1 %% 52 == 34 ~ "2020-11-01",
                                                                   rowNumberMinus1 %% 52 == 35 ~ "2020-11-08",
                                                                   rowNumberMinus1 %% 52 == 36 ~ "2020-11-15",
                                                                   rowNumberMinus1 %% 52 == 37 ~ "2020-11-22",
                                                                   rowNumberMinus1 %% 52 == 38 ~ "2020-11-29",
                                                                   rowNumberMinus1 %% 52 == 39 ~ "2020-12-06",
                                                                   rowNumberMinus1 %% 52 == 40 ~ "2020-12-13",
                                                                   rowNumberMinus1 %% 52 == 41 ~ "2020-12-20",
                                                                   rowNumberMinus1 %% 52 == 42 ~ "2020-12-27",
                                                                   rowNumberMinus1 %% 52 == 43 ~ "2021-01-03",
                                                                   rowNumberMinus1 %% 52 == 44 ~ "2021-01-10",
                                                                   rowNumberMinus1 %% 52 == 45 ~ "2021-01-17",
                                                                   rowNumberMinus1 %% 52 == 46 ~ "2021-01-24",
                                                                   rowNumberMinus1 %% 52 == 47 ~ "2021-01-31",
                                                                   rowNumberMinus1 %% 52 == 48 ~ "2021-02-07",
                                                                   rowNumberMinus1 %% 52 == 49 ~ "2021-02-14",
                                                                   rowNumberMinus1 %% 52 == 50 ~ "2021-02-21",
                                                                   rowNumberMinus1 %% 52 == 51 ~ "2021-02-28"))

vacationFactor <- vacationFactor %>% mutate(Date = case_when(rowNumberMinus1 %% 52 == 0 ~ "2024-01-07",
                                                                   rowNumberMinus1 %% 52 == 1 ~ "2024-01-14",
                                                                   rowNumberMinus1 %% 52 == 2 ~ "2024-01-21",
                                                                   rowNumberMinus1 %% 52 == 3 ~ "2024-01-28",
                                                                   rowNumberMinus1 %% 52 == 4 ~ "2024-02-04",
                                                                   rowNumberMinus1 %% 52 == 5 ~ "2024-02-11",
                                                                   rowNumberMinus1 %% 52 == 6 ~ "2024-02-18",
                                                                   rowNumberMinus1 %% 52 == 7 ~ "2024-02-25",
                                                                   rowNumberMinus1 %% 52 == 8 ~ "2024-03-03",
                                                                   rowNumberMinus1 %% 52 == 9 ~ "2024-03-10",
                                                                   rowNumberMinus1 %% 52 == 10 ~ "2024-03-17",
                                                                   rowNumberMinus1 %% 52 == 11 ~ "2024-03-24",
                                                                   rowNumberMinus1 %% 52 == 12 ~ "2024-03-31",
                                                                   rowNumberMinus1 %% 52 == 13 ~ "2024-04-07",
                                                                   rowNumberMinus1 %% 52 == 14 ~ "2024-04-14",
                                                                   rowNumberMinus1 %% 52 == 15 ~ "2024-04-21",
                                                                   rowNumberMinus1 %% 52 == 16 ~ "2024-04-28",
                                                                   rowNumberMinus1 %% 52 == 17 ~ "2024-05-05",
                                                                   rowNumberMinus1 %% 52 == 18 ~ "2024-05-12",
                                                                   rowNumberMinus1 %% 52 == 19 ~ "2024-05-19",
                                                                   rowNumberMinus1 %% 52 == 20 ~ "2024-05-26",
                                                                   rowNumberMinus1 %% 52 == 21 ~ "2024-06-02",
                                                                   rowNumberMinus1 %% 52 == 22 ~ "2024-06-09",
                                                                   rowNumberMinus1 %% 52 == 23 ~ "2024-06-16",
                                                                   rowNumberMinus1 %% 52 == 24 ~ "2024-06-23",
                                                                   rowNumberMinus1 %% 52 == 25 ~ "2024-06-30",
                                                                   rowNumberMinus1 %% 52 == 26 ~ "2024-07-07",
                                                                   rowNumberMinus1 %% 52 == 27 ~ "2024-07-14",
                                                                   rowNumberMinus1 %% 52 == 28 ~ "2024-07-21",
                                                                   rowNumberMinus1 %% 52 == 29 ~ "2024-07-28",
                                                                   rowNumberMinus1 %% 52 == 30 ~ "2024-08-04",
                                                                   rowNumberMinus1 %% 52 == 31 ~ "2024-08-11",
                                                                   rowNumberMinus1 %% 52 == 32 ~ "2024-08-18",
                                                                   rowNumberMinus1 %% 52 == 33 ~ "2024-08-25",
                                                                   rowNumberMinus1 %% 52 == 34 ~ "2024-09-01",
                                                                   rowNumberMinus1 %% 52 == 35 ~ "2024-09-08",
                                                                   rowNumberMinus1 %% 52 == 36 ~ "2024-09-15",
                                                                   rowNumberMinus1 %% 52 == 37 ~ "2024-09-22",
                                                                   rowNumberMinus1 %% 52 == 38 ~ "2024-09-29",
                                                                   rowNumberMinus1 %% 52 == 39 ~ "2024-10-06",
                                                                   rowNumberMinus1 %% 52 == 40 ~ "2024-10-13",
                                                                   rowNumberMinus1 %% 52 == 41 ~ "2024-10-20",
                                                                   rowNumberMinus1 %% 52 == 42 ~ "2024-10-27",
                                                                   rowNumberMinus1 %% 52 == 43 ~ "2024-11-03",
                                                                   rowNumberMinus1 %% 52 == 44 ~ "2024-11-10",
                                                                   rowNumberMinus1 %% 52 == 45 ~ "2024-11-17",
                                                                   rowNumberMinus1 %% 52 == 46 ~ "2024-11-24",
                                                                   rowNumberMinus1 %% 52 == 47 ~ "2024-12-01",
                                                                   rowNumberMinus1 %% 52 == 48 ~ "2024-12-08",
                                                                   rowNumberMinus1 %% 52 == 49 ~ "2024-12-15",
                                                                   rowNumberMinus1 %% 52 == 50 ~ "2024-12-22",
                                                                   rowNumberMinus1 %% 52 == 51 ~ "2024-12-29"))
vacationFactor <- vacationFactor %>% select(index, Date, value) %>% mutate(Type = "School vacation")
vacationFactor$Date <- as.Date(vacationFactor$Date)

holidayFactor <- read_csv(paste0("/Users/sydney/git/mobility_inference/results/", model, "/holiday_factor.csv"))
holidayFactor <- read_csv(paste0("/Users/sydney/Desktop/BayesProjectMathcluster/", model,  "/holiday_factor.csv"))
holidayFactor <- holidayFactor %>% mutate(index = ceiling(seq_len(nrow(holidayFactor)) / 52)-1)
colnames(holidayFactor)[1] <- "rowNumberMinus1"
colnames(holidayFactor)[2] <- "value"
holidayFactor <- holidayFactor %>% mutate(Date = case_when(rowNumberMinus1 %% 52 == 0 ~ "2020-03-08",
                                                             rowNumberMinus1 %% 52 == 1 ~ "2020-03-15",
                                                             rowNumberMinus1 %% 52 == 2 ~ "2020-03-22",
                                                             rowNumberMinus1 %% 52 == 3 ~ "2020-03-29",
                                                             rowNumberMinus1 %% 52 == 4 ~ "2020-04-05",
                                                             rowNumberMinus1 %% 52 == 5 ~ "2020-04-12",
                                                             rowNumberMinus1 %% 52 == 6 ~ "2020-04-19",
                                                             rowNumberMinus1 %% 52 == 7 ~ "2020-04-26",
                                                             rowNumberMinus1 %% 52 == 8 ~ "2020-05-03",
                                                             rowNumberMinus1 %% 52 == 9 ~ "2020-05-10",
                                                             rowNumberMinus1 %% 52 == 10 ~ "2020-05-17",
                                                             rowNumberMinus1 %% 52 == 11 ~ "2020-05-24",
                                                             rowNumberMinus1 %% 52 == 12 ~ "2020-05-31",
                                                             rowNumberMinus1 %% 52 == 13 ~ "2020-06-07",
                                                             rowNumberMinus1 %% 52 == 14 ~ "2020-06-14",
                                                             rowNumberMinus1 %% 52 == 15 ~ "2020-06-21",
                                                             rowNumberMinus1 %% 52 == 16 ~ "2020-06-28",
                                                             rowNumberMinus1 %% 52 == 17 ~ "2020-07-05",
                                                             rowNumberMinus1 %% 52 == 18 ~ "2020-07-12",
                                                             rowNumberMinus1 %% 52 == 19 ~ "2020-07-19",
                                                             rowNumberMinus1 %% 52 == 20 ~ "2020-07-26",
                                                             rowNumberMinus1 %% 52 == 21 ~ "2020-08-02",
                                                             rowNumberMinus1 %% 52 == 22 ~ "2020-08-09",
                                                             rowNumberMinus1 %% 52 == 23 ~ "2020-08-16",
                                                             rowNumberMinus1 %% 52 == 24 ~ "2020-08-23",
                                                             rowNumberMinus1 %% 52 == 25 ~ "2020-08-30",
                                                             rowNumberMinus1 %% 52 == 26 ~ "2020-09-06",
                                                             rowNumberMinus1 %% 52 == 27 ~ "2020-09-13",
                                                             rowNumberMinus1 %% 52 == 28 ~ "2020-09-20",
                                                             rowNumberMinus1 %% 52 == 29 ~ "2020-09-27",
                                                             rowNumberMinus1 %% 52 == 30 ~ "2020-10-04",
                                                             rowNumberMinus1 %% 52 == 31 ~ "2020-10-11",
                                                             rowNumberMinus1 %% 52 == 32 ~ "2020-10-18",
                                                             rowNumberMinus1 %% 52 == 33 ~ "2020-10-25",
                                                             rowNumberMinus1 %% 52 == 34 ~ "2020-11-01",
                                                             rowNumberMinus1 %% 52 == 35 ~ "2020-11-08",
                                                             rowNumberMinus1 %% 52 == 36 ~ "2020-11-15",
                                                             rowNumberMinus1 %% 52 == 37 ~ "2020-11-22",
                                                             rowNumberMinus1 %% 52 == 38 ~ "2020-11-29",
                                                             rowNumberMinus1 %% 52 == 39 ~ "2020-12-06",
                                                             rowNumberMinus1 %% 52 == 40 ~ "2020-12-13",
                                                             rowNumberMinus1 %% 52 == 41 ~ "2020-12-20",
                                                             rowNumberMinus1 %% 52 == 42 ~ "2020-12-27",
                                                             rowNumberMinus1 %% 52 == 43 ~ "2021-01-03",
                                                             rowNumberMinus1 %% 52 == 44 ~ "2021-01-10",
                                                             rowNumberMinus1 %% 52 == 45 ~ "2021-01-17",
                                                             rowNumberMinus1 %% 52 == 46 ~ "2021-01-24",
                                                             rowNumberMinus1 %% 52 == 47 ~ "2021-01-31",
                                                             rowNumberMinus1 %% 52 == 48 ~ "2021-02-07",
                                                             rowNumberMinus1 %% 52 == 49 ~ "2021-02-14",
                                                             rowNumberMinus1 %% 52 == 50 ~ "2021-02-21",
                                                             rowNumberMinus1 %% 52 == 51 ~ "2021-02-28"))

holidayFactor <- holidayFactor %>% mutate(Date = case_when(rowNumberMinus1 %% 52 == 0 ~ "2024-01-07",
                                                                   rowNumberMinus1 %% 52 == 1 ~ "2024-01-14",
                                                                   rowNumberMinus1 %% 52 == 2 ~ "2024-01-21",
                                                                   rowNumberMinus1 %% 52 == 3 ~ "2024-01-28",
                                                                   rowNumberMinus1 %% 52 == 4 ~ "2024-02-04",
                                                                   rowNumberMinus1 %% 52 == 5 ~ "2024-02-11",
                                                                   rowNumberMinus1 %% 52 == 6 ~ "2024-02-18",
                                                                   rowNumberMinus1 %% 52 == 7 ~ "2024-02-25",
                                                                   rowNumberMinus1 %% 52 == 8 ~ "2024-03-03",
                                                                   rowNumberMinus1 %% 52 == 9 ~ "2024-03-10",
                                                                   rowNumberMinus1 %% 52 == 10 ~ "2024-03-17",
                                                                   rowNumberMinus1 %% 52 == 11 ~ "2024-03-24",
                                                                   rowNumberMinus1 %% 52 == 12 ~ "2024-03-31",
                                                                   rowNumberMinus1 %% 52 == 13 ~ "2024-04-07",
                                                                   rowNumberMinus1 %% 52 == 14 ~ "2024-04-14",
                                                                   rowNumberMinus1 %% 52 == 15 ~ "2024-04-21",
                                                                   rowNumberMinus1 %% 52 == 16 ~ "2024-04-28",
                                                                   rowNumberMinus1 %% 52 == 17 ~ "2024-05-05",
                                                                   rowNumberMinus1 %% 52 == 18 ~ "2024-05-12",
                                                                   rowNumberMinus1 %% 52 == 19 ~ "2024-05-19",
                                                                   rowNumberMinus1 %% 52 == 20 ~ "2024-05-26",
                                                                   rowNumberMinus1 %% 52 == 21 ~ "2024-06-02",
                                                                   rowNumberMinus1 %% 52 == 22 ~ "2024-06-09",
                                                                   rowNumberMinus1 %% 52 == 23 ~ "2024-06-16",
                                                                   rowNumberMinus1 %% 52 == 24 ~ "2024-06-23",
                                                                   rowNumberMinus1 %% 52 == 25 ~ "2024-06-30",
                                                                   rowNumberMinus1 %% 52 == 26 ~ "2024-07-07",
                                                                   rowNumberMinus1 %% 52 == 27 ~ "2024-07-14",
                                                                   rowNumberMinus1 %% 52 == 28 ~ "2024-07-21",
                                                                   rowNumberMinus1 %% 52 == 29 ~ "2024-07-28",
                                                                   rowNumberMinus1 %% 52 == 30 ~ "2024-08-04",
                                                                   rowNumberMinus1 %% 52 == 31 ~ "2024-08-11",
                                                                   rowNumberMinus1 %% 52 == 32 ~ "2024-08-18",
                                                                   rowNumberMinus1 %% 52 == 33 ~ "2024-08-25",
                                                                   rowNumberMinus1 %% 52 == 34 ~ "2024-09-01",
                                                                   rowNumberMinus1 %% 52 == 35 ~ "2024-09-08",
                                                                   rowNumberMinus1 %% 52 == 36 ~ "2024-09-15",
                                                                   rowNumberMinus1 %% 52 == 37 ~ "2024-09-22",
                                                                   rowNumberMinus1 %% 52 == 38 ~ "2024-09-29",
                                                                   rowNumberMinus1 %% 52 == 39 ~ "2024-10-06",
                                                                   rowNumberMinus1 %% 52 == 40 ~ "2024-10-13",
                                                                   rowNumberMinus1 %% 52 == 41 ~ "2024-10-20",
                                                                   rowNumberMinus1 %% 52 == 42 ~ "2024-10-27",
                                                                   rowNumberMinus1 %% 52 == 43 ~ "2024-11-03",
                                                                   rowNumberMinus1 %% 52 == 44 ~ "2024-11-10",
                                                                   rowNumberMinus1 %% 52 == 45 ~ "2024-11-17",
                                                                   rowNumberMinus1 %% 52 == 46 ~ "2024-11-24",
                                                                   rowNumberMinus1 %% 52 == 47 ~ "2024-12-01",
                                                                   rowNumberMinus1 %% 52 == 48 ~ "2024-12-08",
                                                                   rowNumberMinus1 %% 52 == 49 ~ "2024-12-15",
                                                                   rowNumberMinus1 %% 52 == 50 ~ "2024-12-22",
                                                                   rowNumberMinus1 %% 52 == 51 ~ "2024-12-29"))
holidayFactor <- holidayFactor %>% select(index, Date, value) %>% mutate(Type = "Public holiday")
holidayFactor$Date <- as.Date(holidayFactor$Date)

# Boxplot Effect Sizes ----------------------------------------------------

temperatureFactorViolin <- temperatureFactor %>% #filter(Date %in% c(as.Date("2020-08-02"), as.Date("2021-01-03"))) %>%
                            pivot_wider(names_from = Date, values_from = value) %>%
                            #mutate(effect_size = `2020-08-02` - `2021-01-03`) %>% mutate(effect = "Temperature") %>%
                            mutate(effect_size = max(value) - min(value)) %>% mutate(effect = "Temperature") %>%
                            select(effect, effect_size, index)

temperatureFactorViolin <- temperatureFactor %>% group_by(index) %>% 
  summarise(value = max(value) - min(value)) %>%
  mutate(effect_size = value) %>%
  mutate(effect = "Temperature") %>%
  select(effect, effect_size, index)

# holidayFactorViolin <- holidayFactor %>% filter(Date == as.Date("2020-10-04")) %>%
#                                           mutate(effect_size = 1 - value) %>% 
#                                           mutate(effect = "Public\nholiday") %>%
#                                           select(effect, effect_size, index)

holidayFactorViolin <- holidayFactor %>% group_by(index) %>% 
  summarise(value = min(value)) %>%
  mutate(effect_size = 1 - value) %>%
  mutate(effect = "Public\nholiday") %>%
  select(effect, effect_size, index)

vacationFactorViolin <- vacationFactor %>% group_by(index) %>% 
  summarise(value = min(value)) %>%
  mutate(effect_size = 1 - value) %>%
  mutate(effect = "School\nvacation") %>%
  select(effect, effect_size, index)

diseaseFactor1stWaveViolin <- diseaseFactor1stWave %>% 
  mutate(effect_size = 1 - value) %>% 
  mutate(effect = "Disease\n1st wave") %>%
  select(effect, effect_size, index)

diseaseFactor2ndWaveViolin <- diseaseFactor2ndWave %>% 
  mutate(effect_size = 1 - value) %>% 
  mutate(effect = "Disease\n2nd wave\na") %>%
  select(effect, effect_size, index)


ViolinplotDF <- rbind(temperatureFactorViolin, vacationFactorViolin)
quantile(temperatureFactorViolin$effect_size)
quantile(vacationFactorViolin$effect_size)
ViolinplotDF <- rbind(ViolinplotDF, holidayFactorViolin)
quantile(holidayFactorViolin$effect_size)
ViolinplotDF <- rbind(ViolinplotDF, diseaseFactor1stWaveViolin)
quantile(diseaseFactor1stWaveViolin$effect_size)
ViolinplotDF <- rbind(ViolinplotDF, diseaseFactor2ndWaveViolin)
quantile(diseaseFactor2ndWaveViolin$effect_size)

colors <- c("Disease\n1st wave" = "#5254a3", "Disease\n2nd wave\na" = "#5254a3", "Temperature" = "#637939", "School\nvacation" = "#8c6d31", "Public\nholiday" = "#843c39")

ViolinplotDF$effect <- factor(ViolinplotDF$effect, levels = c("Disease\n1st wave", "Disease\n2nd wave\na", "Temperature", "School\nvacation", "Public\nholiday"))

ViolinplotDF$effect_size <- 100 * ViolinplotDF$effect_size

boxplotseffectsize <- ggplot(ViolinplotDF, aes(x=effect, y=effect_size, color = effect, fill = effect)) +
  #geom_boxplot(alpha = 0.4, linewidth = 1) +
  sm_raincloud(aes(stat = median_cl), 
               point.params = list(size = 5, shape = 21, alpha = 0.6, position = sdamr::position_jitternudge(
                 nudge.x = -0.12,
                 jitter.width = 0.1, jitter.height = 0.01      
               )), 
               boxplot.params =  list(alpha = 0.0, width = 0.0, notch = FALSE), 
               violin.params = list(width = 1.4,  scale = "width", alpha = 0.6, adjust = 1.2),
               sep_level = 2)+
  coord_cartesian(ylim = c(min(ViolinplotDF$effect_size), max(ViolinplotDF$effect_size))) +
  #stat_compare_means(comparisons = my_comparisons, label.y = c(0.8,0.85, 0.9, 0.95), symnum.args = list(cutpoints = c(0, 0.01, 0.05, 0.1, Inf), symbols = c("***", "**", "*", "ns")), bracket.size=1, size = 8) +
  theme_minimal() +
  ylab("Maximal impact on\nout-of-home duration (%)") +
  theme(text = element_text(size = 35)) +
  scale_color_manual(values= colors) +
  scale_fill_manual(values= colors) +
  theme(legend.position = "bottom", legend.title = element_blank()) +
  theme(
    # Remove grid lines
    panel.grid = element_blank(),
    
    # Add a box around the plot
    axis.line.x.bottom = element_line(color = "black"),
    axis.line.y.left = element_line(color = "black"),
    
    # Remove the default panel background
    panel.background = element_blank(),
    
    # Optional: adjust axis appearance to be more matplotlib-like
    axis.ticks = element_line(color = "black"),
    axis.ticks.length = unit(12, "pt"),
    #text = element_text(size = 22),  # Affects most text elements
    axis.text = element_text(color = "black"),  # Axis labels
    #axis.text.x = element_text(angle = 90),
    axis.title = element_text(color = "black"),
    legend.position = "none",     # Remove axis labels
  ) +
  xlab("")

# Boxplots across time ----------------------------------------------------

colors <- c("Disease" = "#5254a3", "Temperature" = "#637939", "School vacation" = "#8c6d31", "Public holiday" = "#843c39")

panel_across_districts <- ggplot() +
  geom_boxplot(data = diseaseFactor, aes(x=Date, y = value, group = Date, color = "Disease"), fill = "#5254a3", alpha = 0.4, linewidth = 1.2) +
  geom_boxplot(data = temperatureFactor, aes(x=Date, y = value, group = Date, color = "Temperature"), fill = "#637939", alpha = 0.4, linewidth = 1.2) +
  geom_boxplot(data = vacationFactor, aes(x=Date, y = value, group = Date, color = "School vacation"), fill = "#8c6d31", alpha = 0.4, linewidth = 1.2) +
  geom_boxplot(data = holidayFactor, aes(x=Date, y = value, group = Date, color = "Public holiday"), fill = "#843c39", alpha = 0.4, linewidth = 1.2) +
  theme_minimal() +
  theme(text = element_text(size = 35)) +
  theme(legend.position = "bottom", legend.title = element_blank()) +
  # theme(axis.ticks.x = element_line(),
  #       axis.ticks.y = element_line(),
  #       axis.ticks.length = unit(10, "pt"),
  #       plot.margin = margin (l=0.2, t = 0.3, r=1.3, unit = "cm"),
  #       axis.line = element_line()) +
  theme(
    # Remove grid lines
    panel.grid = element_blank(),
    
    # Add a box around the plot
    axis.line.x.bottom = element_line(color = "black"),
    axis.line.y.left = element_line(color = "black"),
    #panel.border = element_rect(color = "black", fill = NA, size = 0.5),
    
    # Remove the default panel background
    panel.background = element_blank(),
    
    # Optional: adjust axis appearance to be more matplotlib-like
    axis.ticks = element_line(color = "black"),
    axis.ticks.length = unit(10, "pt"),
    #text = element_text(size = 22),  # Affects most text elements
    axis.text = element_text(color = "black"),  # Axis labels
    axis.title = element_text(color = "black"),
    legend.position = "none"
  ) +
  scale_x_date(breaks = seq(as.Date("2020-04-01"), as.Date("2024-12-29"), by = "3 month"), date_labels = "%d/%b/%y", expand = c(0, 0)) + 
  theme(legend.position = "bottom", legend.title = element_blank()) +
  theme(axis.ticks.x = element_line(),
        axis.ticks.y = element_line(),
        axis.ticks.length = unit(12, "pt"),
        axis.minor.ticks.length.x = unit(7, "pt"),
        #axis.minor.ticks.x = element_line(color = "#000000"),
        axis.line = element_line()) +
  ylab("Multiplicative impact on\nout-of-home duration") +
  scale_color_manual(values = colors)

ggsave("DistributionMultiplicativeImpacts_Fig3.pdf", dpi = 500, w = 18, h = 9)
ggsave("DistributionMultiplicativeImpacts_Fig3.png", dpi = 500, w = 18, h = 9)

ggarrange(ggarrange(panel_across_districts, boxplotseffectsize, ncol = 2, labels = c("A", "B"), font.label = list(size = 30), widths = c(0.6, 0.4)), 
          nrow = 1)


ggsave("DistributionMultiplicativeImpacts_Fig3_Only2024.pdf", dpi = 500, w = 21, h = 8)

# 1st Wave Analysis -------------------------------------------------------
#Influence of Case Numbers
diseaseFactor1stWave <- diseaseFactor %>% filter(Date < as.Date("2020-06-01"))

diseaseFactor1stWave <- diseaseFactor1stWave %>% group_by(index) %>% slice_min(value, n = 1) 

diseaseFactor1stWave %>% ungroup() %>% count(Date)

diseaseFactor1stWave %>% ungroup() %>% 
  group_by(Date) %>% 
  summarise(min = min(value), max = max(value), median = median(value), mean = mean(value), IQR25 = quantile(value, .25), IQR75 = quantile(value, .75))
#Influence of Temperature
temperatureFactor1stWave <- temperatureFactor %>% filter(Date < as.Date("2020-06-01"))
temperatureFactorDecrease <- temperatureFactor %>% filter(Date < as.Date("2020-04-12"))
temperatureFactorDecrease <- temperatureFactorDecrease %>% group_by(index) %>% slice_min(value, n = 1) 
temperatureFactorDecrease%>% ungroup() %>% count(Date)
temperatureFactorDecrease %>% group_by(Date) %>% summarise(min = min(value), max = max(value), median = median(value), mean = mean(value), IQR25 = quantile(value, .25), IQR75 = quantile(value, .75))

temperatureFactorIncrease <- temperatureFactor1stWave %>% filter(Date > as.Date("2020-04-12"))
temperatureFactorIncrease <- temperatureFactorIncrease %>% group_by(index) %>% slice_max(value, n = 1) 
temperatureFactorIncrease %>% ungroup() %>% count(Date)
temperatureFactorIncrease %>% group_by(Date) %>% summarise(min = min(value), max = max(value), median = median(value), mean = mean(value), IQR25 = quantile(value, .25), IQR75 = quantile(value, .75))
#Influence of Schools
vacationFactor1stWave <- vacationFactor %>% filter(Date < as.Date("2020-06-01"))
vacationFactor1stWave <- vacationFactor1stWave %>% group_by(index) %>% slice_min(value, n = 1) 
vacationFactor1stWave %>% ungroup() %>% count(Date)
vacationFactor1stWave %>% group_by(Date) %>% summarise(min = min(value), max = max(value), median = median(value), mean = mean(value), IQR25 = quantile(value, .25), IQR75 = quantile(value, .75))

#Influence of Vacations
holidayFactor1stWave <- holidayFactor %>% filter(Date < as.Date("2020-06-01"))
holidayFactor1stWave <- holidayFactor1stWave %>% group_by(index) %>% slice_min(value, n = 1) 
holidayFactor1stWave %>% ungroup() %>% count(Date)
holidayFactor1stWave %>% group_by(Date) %>% summarise(min = min(value), max = max(value), median = median(value), mean = mean(value), IQR25 = quantile(value, .25), IQR75 = quantile(value, .75))

# 2nd Wave Analysis -------------------------------------------------------
#Influence of Case Numbers
diseaseFactor2ndWave <- diseaseFactor %>% filter(Date > as.Date("2020-09-01"))

diseaseFactor2ndWave <- diseaseFactor2ndWave %>% group_by(index) %>% slice_min(value, n = 1) 

diseaseFactor2ndWave %>% ungroup() %>% count(Date)

diseaseFactor2ndWave %>% ungroup() %>% 
  group_by(Date) %>% 
  summarise(min = min(value), max = max(value), median = median(value), mean = mean(value), IQR25 = quantile(value, .25), IQR75 = quantile(value, .75))
#Influence of Temperature
temperatureFactor2ndWave <- temperatureFactor %>% filter(Date > as.Date("2020-10-01"))
temperatureFactor2ndWaveDecrease <- temperatureFactor2ndWave %>% group_by(index) %>% slice_min(value, n = 1) 
temperatureFactor2ndWaveDecrease %>% ungroup() %>% count(Date)
temperatureFactor2ndWaveDecrease %>% group_by(Date) %>% summarise(min = min(value), max = max(value), median = median(value), mean = mean(value), IQR25 = quantile(value, .25), IQR75 = quantile(value, .75))

temperatureFactor2ndWaveIncrease <- temperatureFactor2ndWave %>% group_by(index) %>% slice_max(value, n = 1) 
temperatureFactor2ndWaveIncrease %>% ungroup() %>% count(Date)
temperatureFactor2ndWaveIncrease %>% group_by(Date) %>% summarise(min = min(value), max = max(value), median = median(value), mean = mean(value), IQR25 = quantile(value, .25), IQR75 = quantile(value, .75))


#Influence of Schools
vacationFactor2ndWave <- vacationFactor %>% filter(Date > as.Date("2020-10-01"))
vacationFactor2ndWave <- vacationFactor2ndWave %>% group_by(index) %>% slice_min(value, n = 1) 
vacationFactor2ndWave %>% ungroup() %>% count(Date)
vacationFactor2ndWave %>% group_by(Date) %>% summarise(min = min(value), max = max(value), median = median(value), mean = mean(value), IQR25 = quantile(value, .25), IQR75 = quantile(value, .75))

#Influence of Vacations
holidayFactor2ndWave <- holidayFactor %>% filter(Date > as.Date("2020-10-01"))
holidayFactor2ndWave <- holidayFactor2ndWave %>% group_by(index) %>% slice_min(value, n = 1) 
holidayFactor2ndWave %>% ungroup() %>% count(Date)
holidayFactor2ndWave %>% group_by(Date) %>% summarise(min = min(value), max = max(value), median = median(value), mean = mean(value), IQR25 = quantile(value, .25), IQR75 = quantile(value, .75))


# Boxplot Weights ---------------------------------------------------------

model <- "fourhundred"

consideredWave <- "firstwave"

outcomeVariable <- "shareLocalIncidence"
run <- "2025-09-14_400_cluster_expdecay_wideealpha"

source("Postprocessing_Clean.R")

disFac_post <- postprocessing_clean(model, consideredWave, run, outcomeVariable)

disFac_post <- disFac_post %>% mutate(group_eng = case_when(group_eng == "Large City" ~ "Large\ncity",
                                                            group_eng == "Small City" ~ "Small\ncity",
                                                            group_eng == "Town" ~ "Subur./\nindependent\ntown",
                                                            group_eng == "Medium Rural" ~ "Medium\nrural",
                                                            .default = group_eng))

disFac_post$group_eng <- factor(disFac_post$group_eng, levels = c("Large\ncity", "Small\ncity", "Subur./\nindependent\ntown", "Medium\nrural", "Rural"))

my_comparisons <- list(c("Large\ncity", "Small\ncity"),
                       c("Small\ncity", "Subur./\nindependent\ntown"),
                       c("Subur./\nindependent\ntown", "Medium\nrural"),
                       c("Medium\nrural", "Rural"))

manual_scale <- c("#D4B2CC", "#D385AC",  "#A56693", "#66507A", "#2D204C")

disFac_post %>% anova_test(value ~ group_eng)

weight_across_districts <- ggplot(disFac_post, aes(x=group_eng, y=value, color = group_eng, fill = group_eng)) +
  #sm_raincloud(aes(stat=median_cl, x=group_eng, y=value), size = 1.2, color= "#393b79") +
  sm_raincloud(aes(stat = median_cl), 
               point.params = list(size = 5, shape = 21, alpha = 0.6, position = sdamr::position_jitternudge(
                 nudge.x = -0.12,
                 jitter.width = 0.1, jitter.height = 0.01      
               )), 
               boxplot.params =  list(alpha = 0.0, width = 0.0, notch = FALSE), 
               violin.params = list(width = 1.4, scale = "width", alpha = 0.6),
               shape = 21, sep_level = 2)+
  stat_compare_means(comparisons = my_comparisons, label.y = c(0.8,0.85, 0.9, 0.95), symnum.args = list(cutpoints = c(0, 0.01, 0.05, 0.1, Inf), symbols = c("***", "**", "*", "ns")), bracket.size=1, size = 8) +
  theme_minimal() +
  ylab("Weight local incidence") +
  theme(text = element_text(size = 35)) +
  scale_color_manual(values= manual_scale) +
  scale_fill_manual(values= manual_scale) +
  theme(legend.position = "bottom", legend.title = element_blank()) +
  # theme(axis.ticks.x = element_line(),
  #       axis.ticks.y = element_line(),
  #       axis.ticks.length = unit(10, "pt"),
  #       plot.margin = margin (l=0.2, t = 0.3, r=1.3, unit = "cm"),
  #       axis.line = element_line()) +
  theme(
    # Remove grid lines
    panel.grid = element_blank(),
    
    # Add a box around the plot
    axis.line.x.bottom = element_line(color = "black"),
    axis.line.y.left = element_line(color = "black"),
    #panel.border = element_rect(color = "black", fill = NA, size = 0.5),
    
    # Remove the default panel background
    panel.background = element_blank(),
    
    # Optional: adjust axis appearance to be more matplotlib-like
    axis.ticks = element_line(color = "black"),
    axis.ticks.length = unit(12, "pt"),
    #text = element_text(size = 22),  # Affects most text elements
    axis.text = element_text(color = "black"),  # Axis labels
    #axis.text.x = element_text(angle = 90),
    axis.title = element_text(color = "black"),
    legend.position = "none",     # Remove axis labels
    #axis.text.x = element_blank(),     # Remove x-axis tick labels
    #axis.ticks.x = element_blank() 
  ) +
  xlab("")



# Kernel plot -------------------------------------------------------------

mu <- read_csv("/Users/sydney/git/mobility_inference/results/2025-09-14_400_cluster_expdecay_wideealpha/mu_gamma_C.csv")
colnames(mu) <- c("district", "mu")
sigma <- read_csv("/Users/sydney/git/mobility_inference/results/2025-09-14_400_cluster_expdecay_wideealpha/sigma_gamma_C.csv")
colnames(sigma) <- c("district", "sigma")

df <- left_join(mu,sigma)
df <- df %>% mutate(alpha = mu^2 / (sigma^2 + 1e-8))
df <- df %>% mutate(beta = mu / (sigma^2 + 1e-8))

df <- df %>% mutate(mean = alpha/beta)

x = seq(0.001,10000.001,0.1)

result <- df %>%
  group_by(district) %>%
  reframe(
    x = x,
    y = beta^alpha * x^(alpha - 1) * exp(-beta * x),
  )

#result$y[is.nan(result$y)] <- 0
#result$y[is.infinite(result$y)] <- 0
#result <- result %>% filter(x!=0)

result <- result %>% group_by(district) %>% mutate(y_new = y/sum(y+1e-8))

result <- result %>% group_by(x) %>% summarise(mean = mean(y_new), lower = quantile(y_new, 0.1), upper = quantile(y_new, 0.9))

kernel <- ggplot(result) +
  geom_line(aes(x=x, y = mean, size = 2)) + 
  geom_ribbon(aes(x=x, ymin=lower, ymax=upper, alpha = 1, size = 3)) +
  theme_minimal() +
  theme(text = element_text(size = 35)) +
  theme(
      # Remove grid lines
      panel.grid = element_blank(),
      
      # Add a box around the plot
      axis.line.x.bottom = element_line(color = "black"),
      axis.line.y.left = element_line(color = "black"),
      #panel.border = element_rect(color = "black", fill = NA, size = 0.5),
      
      # Remove the default panel background
      panel.background = element_blank(),
      
      # Optional: adjust axis appearance to be more matplotlib-like
      axis.ticks = element_line(color = "black"),
      axis.ticks.length = unit(12, "pt"),
      #text = element_text(size = 22),  # Affects most text elements
      axis.text = element_text(color = "black"),  # Axis labels
      #axis.text.x = element_text(angle = 90),
      axis.title = element_text(color = "black"),
      legend.position = "none",     # Remove axis labels
      #axis.text.x = element_blank(),     # Remove x-axis tick labels
      #axis.ticks.x = element_blank() 
    ) +
  xlab("Time (weeks)") +
  xlim(c(0,60)) +
  ylab("Delay kernel density")

# 1. Ensure x is sorted
result <- result[order(result$x), ]
# 2. Normalize y so it integrates to 1 (if not already a proper density)
result$mean <- result$mean / sum(result$mean)
# 3. Compute cumulative distribution
result$cumulative <- cumsum(result$mean)
# 4. Find the median (where cumulative reaches 0.5)
median_value <- approx(x = result$cumulative, y = result$x, xout = 0.5)$y
mean_value <- sum(result$x * result$mean)

ggarrange(ggarrange(panel_across_districts, kernel, ncol = 2, labels = c("A", "B"), font.label = list(size = 37), widths = c(0.7, 0.3)), 
          ggarrange(boxplotseffectsize, weight_across_districts, ncol = 2, labels = c("C", "D"), font.label = list(size = 37)), 
          nrow = 2, font.label = list(size = 37))

ggsave("WeightTrial.pdf", weight_across_districts, dpi = 500, w = 15, h = 12)

ggsave("DistributionMultiplicativeImpacts_Fig3.pdf", dpi = 500, w = 24, h = 15)
ggsave("DistributionMultiplicativeImpacts_Fig3.png", dpi = 500, w = 21, h = 15)
