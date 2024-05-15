## Data prep for hierarchical bayesian model

library(tidyverse)
library(MMWRweek)

pubHolidays <- read_csv("/Users/sydney/git/mobility_inference/data/data_new/public_holidays/public_holidays_germany_weekly.csv")
colnames(pubHolidays)[2] <- "federalState"
pubHolidays <- pubHolidays %>% filter(federalState != "Deutschland")

schoolVacations <- read_csv("/Users/sydney/git/mobility_inference/data/data_new/school_vacations/school_vacations_germany_weekly.csv")
schoolVacations <- schoolVacations %>% filter(federalState != "Deutschland")

weather <- read_csv("/Users/sydney/git/mobility_inference/data/data_new/weather/tmax_tavg_prcp_fed.csv")
colnames(weather)[1] <- "date"
colnames(weather)[2] <- "federalState"
weather <- weather %>% filter(federalState != "Deutschland")

daylight <- read_csv("/Users/sydney/git/mobility_inference/data/data_new/daylight/DaylightWeek_FedStates.csv")

mobility <- read_delim("/Users/sydney/git/mobility_inference/data/mobility/archive/mobilityData_OverviewBL_weekly.csv", delim = ";")
colnames(mobility)[2] <- "federalState"
mobility$date <- as.character(paste0(substring(mobility$date, 1, 4),  "-", substring(mobility$date, 5, 6), "-", substring(mobility$date, 7, 8)))
mobility$date <- as.Date(mobility$date)

hospitals <- read_csv("https://raw.githubusercontent.com/robert-koch-institut/COVID-19-Hospitalisierungen_in_Deutschland/master/Aktuell_Deutschland_COVID-19-Hospitalisierungen.csv")
colnames(hospitals)[1] <- "date"
colnames(hospitals)[2] <- "federalState"
colnames(hospitals)[5] <- "Hospital_Cases"
colnames(hospitals)[6] <- "Hospital_Incidence"
hospitals <- hospitals %>% filter(Altersgruppe == "00+") %>%
             mutate(weekday = wday(date)) %>%
             filter(weekday == 1)
hospitals <- hospitals %>% select(date, federalState, Hospital_Cases, Hospital_Incidence)

cases <- read_csv("https://raw.githubusercontent.com/robert-koch-institut/COVID-19_7-Tage-Inzidenz_in_Deutschland/main/COVID-19-Faelle_7-Tage-Inzidenz_Bundeslaender.csv")
colnames(cases)[1] <- "date"
colnames(cases)[7] <- "Infection_Cases"
colnames(cases)[8] <- "Infection_Incidence"
cases <- cases %>% filter(Altersgruppe == "00+")
cases <- cases %>% mutate(federalState = case_when(Bundesland_id == "01" ~ "Schleswig-Holstein",
                                    Bundesland_id == "02" ~ "Hamburg",
                                    Bundesland_id == "03" ~ "Niedersachsen",
                                    Bundesland_id == "04" ~ "Bremen",
                                    Bundesland_id == "05" ~ "Nordrhein-Westfalen",
                                    Bundesland_id == "06" ~ "Hessen",
                                    Bundesland_id == "07" ~ "Rheinland-Pfalz",
                                    Bundesland_id == "08" ~ "Baden-Württemberg",
                                    Bundesland_id == "09" ~ "Bayern",
                                    Bundesland_id == "10" ~ "Saarland",
                                    Bundesland_id == "11" ~ "Berlin",
                                    Bundesland_id == "12" ~ "Brandenburg",
                                    Bundesland_id == "13" ~ "Mecklenburg-Vorpommern",
                                    Bundesland_id == "14" ~ "Sachsen",
                                    Bundesland_id == "15" ~ "Sachsen-Anhalt",
                                    Bundesland_id == "16" ~ "Thüringen"))
cases <- cases %>% mutate(weekday = wday(date)) %>%
  filter(weekday == 1)
cases <- cases %>% select(date, federalState, Infection_Cases, Infection_Incidence)

deaths <- read_csv("https://raw.githubusercontent.com/robert-koch-institut/COVID-19-Todesfaelle_in_Deutschland/main/COVID-19-Todesfaelle_Bundeslaender.csv")
deaths <- deaths %>% mutate(year = as.integer(substring(Datum, 1, 4)), week = as.integer(substring(Datum, 7,8))) %>% 
                    mutate(date = MMWRweek2Date(MMWRyear = year, MMWRweek = week)) %>% mutate(date = date + 7) ##MMWRweek sets the first day of a week equal to Sunday, for RKI: Sunday = last day of the week --> This necessitates the +7
colnames(deaths)[2] <- "federalState"
colnames(deaths)[4] <- "Death_Cases"
deaths <- deaths %>% mutate(EinwohnerInnen = case_when(federalState == "Baden-Württemberg" ~ 11280257,
                                                       federalState == "Bayern" ~ 13369393,
                                                       federalState == "Berlin" ~ 3755251,
                                                       federalState == "Brandenburg" ~ 2573135,
                                                       federalState == "Bremen" ~ 684864,
                                                       federalState == "Hamburg" ~ 1892122,
                                                       federalState == "Hessen" ~ 6391360,
                                                       federalState == "Mecklenburg-Vorpommern" ~ 1628378,
                                                       federalState == "Niedersachsen" ~ 8140242,
                                                       federalState == "Nordrhein-Westfalen" ~ 18139116,
                                                       federalState == "Rheinland-Pfalz" ~ 4159150,
                                                       federalState == "Saarland" ~ 992666,
                                                       federalState == "Sachsen" ~ 4086152,
                                                       federalState == "Sachsen-Anhalt" ~ 2186643,
                                                       federalState == "Schleswig-Holstein" ~ 2953270,
                                                       federalState == "Thüringen" ~ 2126846))
deaths <- deaths %>% mutate(Death_Incidence = Death_Cases/EinwohnerInnen*100000)
deaths <- deaths %>% select(date, federalState, Death_Cases, Death_Incidence)

R_eff_full <- data.frame()

for(directory in list.dirs("/Users/sydney/git/mobility_inference/data/R/Germany/R_eff_results")){
  if(directory != "/Users/sydney/git/mobility_inference/data/R/Germany/R_eff_results"){
    setwd(directory)
    file <- list.files(directory)[1]
    R_eff <- read_csv(file)
    fedState <- strsplit(directory, "/")[[1]][10]
    fedState <- strsplit(fedState, "_")[[1]][1]
    R_eff <- R_eff %>% mutate(federalState = fedState)
    R_eff_full <- rbind(R_eff_full, R_eff)
  }
}
colnames(R_eff_full)[3] <- "R_eff"
R_eff_full <- R_eff_full %>% mutate(week = isoweek(date), year = year(date)) %>%
  group_by(week, year, federalState) %>% summarise(Reffective = mean(R_eff), date = max(date)) %>% ungroup()
R_eff_full <- R_eff_full %>% select(date, federalState, Reffective)

#TODO: ICU DATA

dataFull <- left_join(pubHolidays, schoolVacations, by = c("federalState", "date"))
dataFull <- left_join(dataFull, weather, by = c("federalState", "date"))
dataFull <- left_join(dataFull, daylight, by = c("federalState", "date"))
dataFull <- left_join(dataFull, mobility, by = c("federalState", "date"))
dataFull <- left_join(dataFull, hospitals, by = c("federalState", "date"))
dataFull <- left_join(dataFull, cases, by = c("federalState", "date"))
dataFull <- left_join(dataFull, deaths, by = c("federalState", "date"))
dataFull <- dataFull %>% mutate(Death_Cases = ifelse(is.na(Death_Cases), 0, Death_Cases)) %>% 
  mutate(Death_Incidence = ifelse(is.na(Death_Incidence), 0, Death_Incidence))
dataFull <- left_join(dataFull, R_eff_full, by = c("federalState", "date"))

#NOTE: ICU incidence is availble on federal state level only from Aug 2021 onwards. Consequently, ICU data is for now ignored

#Only keep dates which are needed for the Bayesian inference
dataFull <- dataFull %>% filter(date > "2020-03-01") %>% filter(date < "2020-12-20")

#Zscore/Normalize data
dataFull <- dataFull %>% group_by(federalState) %>% mutate(Infection_Cases_Norm = (Infection_Cases-mean(Infection_Cases))/sd(Infection_Cases),
                                                           Infection_Incidence_Norm = (Infection_Incidence-mean(Infection_Incidence))/sd(Infection_Incidence),
                                                           Hospital_Cases_Norm = (Hospital_Cases-mean(Hospital_Cases))/sd(Hospital_Cases),
                                                           Hospital_Incidence_Norm = (Hospital_Incidence-mean(Hospital_Incidence))/sd(Hospital_Incidence),
                                                           Death_Cases_Norm = (Death_Cases-mean(Death_Cases))/sd(Death_Cases),
                                                           Death_Incidence_Norm = (Death_Incidence-mean(Death_Incidence))/sd(Death_Incidence),
                                                           Reffective_Norm = (Reffective-mean(Reffective))/sd(Reffective)) %>%
                                                  mutate(Infection_Cases_Norm = (Infection_Cases_Norm-min(Infection_Cases_Norm))/(max(Infection_Cases_Norm)-min(Infection_Cases_Norm)),
                                                         Infection_Incidence_Norm = (Infection_Incidence_Norm-min(Infection_Incidence_Norm))/(max(Infection_Incidence_Norm)-min(Infection_Incidence_Norm)),
                                                         Hospital_Cases_Norm = (Hospital_Cases_Norm-min(Hospital_Cases_Norm))/(max(Hospital_Cases_Norm)-min(Hospital_Cases_Norm)),
                                                         Hospital_Incidence_Norm = (Hospital_Incidence_Norm-min(Hospital_Incidence_Norm))/(max(Hospital_Incidence_Norm)-min(Hospital_Incidence_Norm)),
                                                         Death_Cases_Norm = (Death_Cases_Norm-min(Death_Cases_Norm))/(max(Death_Cases_Norm)-min(Death_Cases_Norm)),
                                                         Death_Incidence_Norm = (Death_Incidence_Norm-min(Death_Incidence_Norm))/(max(Death_Incidence_Norm)-min(Death_Incidence_Norm)),
                                                         Reffective_Norm = (Reffective_Norm-min(Reffective_Norm))/(max(Reffective_Norm)-min(Reffective_Norm)))


