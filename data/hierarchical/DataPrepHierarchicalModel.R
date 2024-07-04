## Data prep for hierarchical bayesian model

library(tidyverse)
library(MMWRweek)

chosenModel <- c("Berlin", "Hamburg", "Bremen")
#chosenModel <- c("Baden-Württemberg", "Bayern", "Brandenburg", "Hessen", "Mecklenburg-Vorpommern", "Niedersachsen", "Nordrhein-Westfalen", "Rheinland-Pfalz", "Saarland", "Sachsen", "Sachsen-Anhalt", "Schleswig-Holstein", "Thüringen")

pubHolidays <- read_csv("/Users/sydney/git/mobility_inference/data/public_holidays/public_holidays_germany_weekly.csv")
colnames(pubHolidays)[2] <- "federalState"
pubHolidays <- pubHolidays %>% filter(federalState != "Deutschland")

schoolVacations <- read_csv("/Users/sydney/git/mobility_inference/data/school_vacations/school_vacations_germany_weekly.csv")
schoolVacations <- schoolVacations %>% filter(federalState != "Deutschland")

weather <- read_csv("/Users/sydney/git/mobility_inference/data/weather/tmax_tavg_prcp_fed.csv")
colnames(weather)[1] <- "date"
colnames(weather)[2] <- "federalState"
weather <- weather %>% filter(federalState != "Deutschland")

daylight <- read_csv("/Users/sydney/git/mobility_inference/data/daylight/DaylightWeek_FedStates.csv")

mobility <- read_delim("https://svn.vsp.tu-berlin.de/repos/public-svn/matsim/scenarios/countries/de/episim/mobilityData/bundeslaender/mobilityData_OverviewBL_weekly.csv", delim = ";")
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
hospitals <- hospitals %>% select(date, federalState, Hospital_Cases, Hospital_Incidence) %>%
                            mutate(Hospital_Cases = case_when(Hospital_Cases == 0 ~ 10^(-100),
                                                           TRUE ~ as.numeric(as.character(Hospital_Cases)))) %>%
                            mutate(Hospital_Incidence = case_when(Hospital_Incidence == 0 ~ 10^(-100),
                                                           TRUE ~ as.numeric(as.character(Hospital_Incidence)))) %>%
                            mutate(logHospital_Cases = log10(Hospital_Cases), logHospital_Incidence=log10(Hospital_Incidence))

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
cases <- cases %>% select(date, federalState, Infection_Cases, Infection_Incidence) %>%
                    mutate(Infection_Cases = case_when(Infection_Cases == 0 ~ 10^(-100),
                                                   TRUE ~ as.numeric(as.character(Infection_Cases)))) %>%
                    mutate(Infection_Incidence = case_when(Infection_Incidence == 0 ~ 10^(-100),
                                                   TRUE ~ as.numeric(as.character(Infection_Incidence)))) %>%
                    mutate(logInfection_Cases = log10(Infection_Cases), logInfection_Incidence = log10(Infection_Incidence))


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
deaths <- deaths %>% select(date, federalState, Death_Cases, Death_Incidence) %>%
                      mutate(Death_Cases = case_when(Death_Cases == 0 ~ 10^(-100),
                                                     TRUE ~ as.numeric(as.character(Death_Cases)))) %>%
                      mutate(Death_Incidence = case_when(Death_Incidence == 0 ~ 10^(-100),
                                 TRUE ~ as.numeric(as.character(Death_Incidence)))) %>%
                      mutate(logDeath_Cases=log10(Death_Cases), logDeath_Incidence = log10(Death_Incidence))

R_eff_full <- data.frame()

for(directory in list.dirs("/Users/sydney/git/mobility_inference/data/R/Germany/R_eff_results")){
  if(directory != "/Users/sydney/git/mobility_inference/data/R/Germany/R_eff_results"){
    setwd(directory)
    file <- list.files(directory)[1]
    R_eff <- read_csv("/Users/sydney/git/mobility_inference/data/R/Germany/RKI_Nowcasting.csv")
    fedState <- strsplit(directory, "/")[[1]][10]
    fedState <- strsplit(fedState, "_")[[1]][1]
    R_eff <- R_eff %>% mutate(federalState = fedState)
    R_eff_full <- rbind(R_eff_full, R_eff)
  }
}
colnames(R_eff_full)[8] <- "R_eff"
R_eff_full <- R_eff_full %>% mutate(week = isoweek(Datum), year = year(Datum)) %>%
  group_by(week, year, federalState) %>% summarise(Reffective = mean(R_eff), date = max(Datum)) %>% ungroup()
R_eff_full <- R_eff_full %>% select(date, federalState, Reffective)

#Merge different data frames
dataFull <- left_join(pubHolidays, schoolVacations, by = c("federalState", "date"))
dataFull <- dataFull %>% mutate(EinwohnerInnenJeKm2 = case_when(federalState == "Baden-Württemberg" ~ 310,
                                                                federalState == "Bayern" ~ 185,
                                                                federalState == "Nordrhein-Westfalen" ~ 526,
                                                                federalState == "Niedersachsen" ~ 167,
                                                                federalState == "Hessen" ~ 297,
                                                                federalState == "Rheinland-Pfalz" ~ 206,
                                                                federalState == "Sachsen" ~ 221,
                                                                federalState == "Berlin" ~ 4090,
                                                                federalState == "Schleswig-Holstein" ~ 183,
                                                                federalState == "Brandenburg" ~ 85,
                                                                federalState == "Sachsen-Anhalt" ~ 109,
                                                                federalState == "Thüringen" ~ 132,
                                                                federalState == "Hamburg" ~ 2438,
                                                                federalState == "Mecklenburg-Vorpommern" ~ 69,
                                                                federalState == "Saarland" ~ 385,
                                                                federalState == "Bremen" ~ 1629))
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

dataFull <- dataFull %>% mutate(index = case_when(federalState == "Schleswig-Holstein" ~ 0,
                                                  federalState == "Hamburg" ~ 1,
                                                  federalState == "Niedersachsen" ~ 2,
                                                  federalState == "Bremen" ~ 3,
                                                  federalState == "Nordrhein-Westfalen" ~ 4,
                                                  federalState == "Hessen" ~ 5,
                                                  federalState == "Rheinland-Pfalz" ~ 6,
                                                  federalState == "Baden-Württemnerg" ~ 7,
                                                  federalState == "Bayern" ~ 8,
                                                  federalState == "Saarland" ~ 9,
                                                  federalState == "Berlin" ~ 10,
                                                  federalState == "Brandenburg" ~ 11,
                                                  federalState == "Mecklenburg-Vorpommern" ~ 12,
                                                  federalState == "Sachsen" ~ 13,
                                                  federalState == "Sachsen-Anhalt" ~ 14,
                                                  federalState == "Thüringen" ~ 15))

#Only keep dates which are needed for the Bayesian inference
data2020 <- dataFull %>% filter(date < "2020-12-20") %>% 
                        filter(date > "2020-03-29")

#data2020 <- data2020 %>% mutate(Infection_Incidence = case_when(Infection_Incidence == 0 ~ 0.00001,
#                                                           TRUE ~ as.numeric(as.character(Infection_Incidence)))) %>%
#                        mutate(Hospital_Cases = case_when(Hospital_Cases == 0 ~ 0.00001,
#                                                           TRUE ~ as.numeric(as.character(Hospital_Cases)))) %>%
#                        mutate(Hospital_Incidence = case_when(Hospital_Incidence == 0 ~ 0.00001,
#                                                           TRUE ~ as.numeric(as.character(Hospital_Incidence)))) %>%
#                        mutate(Death_Cases = case_when(Death_Cases == 0 ~ 0.001,
#                                                            TRUE ~ as.numeric(as.character(Death_Cases)))) %>%
#                        mutate(Death_Incidence = case_when(Death_Incidence == 0 ~ 0.001,
#                                                            TRUE ~ as.numeric(as.character(Death_Incidence))))
                                          
                                          
#Zscore/Normalize data
data2020 <- data2020 %>% group_by(federalState) %>% mutate(Infection_Cases_Norm = (Infection_Cases-mean(Infection_Cases))/sd(Infection_Cases),
                                                           logInfection_Cases_Norm = (logInfection_Cases-mean(logInfection_Cases))/sd(logInfection_Cases),
                                                           Infection_Incidence_Norm = (Infection_Incidence-mean(Infection_Incidence))/sd(Infection_Incidence),
                                                           logInfection_Incidence_Norm = (logInfection_Incidence-mean(logInfection_Incidence))/sd(logInfection_Incidence),
                                                           Hospital_Cases_Norm = (Hospital_Cases-mean(Hospital_Cases))/sd(Hospital_Cases),
                                                           logHospital_Cases_Norm = (logHospital_Cases-mean(logHospital_Cases))/sd(logHospital_Cases),
                                                           Hospital_Incidence_Norm = (Hospital_Incidence-mean(Hospital_Incidence))/sd(Hospital_Incidence),
                                                           logHospital_Incidence_Norm = (logHospital_Incidence-mean(logHospital_Incidence))/sd(logHospital_Incidence),
                                                           Death_Cases_Norm = (Death_Cases-mean(Death_Cases))/sd(Death_Cases),
                                                           logDeath_Cases_Norm = (logDeath_Cases-mean(logDeath_Cases))/sd(logDeath_Cases),
                                                           Death_Incidence_Norm = (Death_Incidence-mean(Death_Incidence))/sd(Death_Incidence),
                                                           logDeath_Incidence_Norm = (logDeath_Incidence-mean(logDeath_Incidence))/sd(logDeath_Incidence),
                                                           Reffective_Norm = (Reffective-mean(Reffective))/sd(Reffective)) %>%
                                                  mutate(Infection_Cases_Norm = (Infection_Cases_Norm-min(Infection_Cases_Norm))/(max(Infection_Cases_Norm)-min(Infection_Cases_Norm)),
                                                         logInfection_Cases_Norm = (logInfection_Cases_Norm-min(logInfection_Cases_Norm))/(max(logInfection_Cases_Norm)-min(logInfection_Cases_Norm)),
                                                         Infection_Incidence_Norm = (Infection_Incidence_Norm-min(Infection_Incidence_Norm))/(max(Infection_Incidence_Norm)-min(Infection_Incidence_Norm)),
                                                         logInfection_Incidence_Norm = (logInfection_Incidence_Norm-min(logInfection_Incidence_Norm))/(max(logInfection_Incidence_Norm)-min(logInfection_Incidence_Norm)),
                                                         Hospital_Cases_Norm = (Hospital_Cases_Norm-min(Hospital_Cases_Norm))/(max(Hospital_Cases_Norm)-min(Hospital_Cases_Norm)),
                                                         logHospital_Cases_Norm = (logHospital_Cases_Norm-min(logHospital_Cases_Norm))/(max(logHospital_Cases_Norm)-min(logHospital_Cases_Norm)),
                                                         Hospital_Incidence_Norm = (Hospital_Incidence_Norm-min(Hospital_Incidence_Norm))/(max(Hospital_Incidence_Norm)-min(Hospital_Incidence_Norm)),
                                                         logHospital_Incidence_Norm = (logHospital_Incidence_Norm-min(logHospital_Incidence_Norm))/(max(logHospital_Incidence_Norm)-min(logHospital_Incidence_Norm)),
                                                         Death_Cases_Norm = (Death_Cases_Norm-min(Death_Cases_Norm))/(max(Death_Cases_Norm)-min(Death_Cases_Norm)),
                                                         logDeath_Cases_Norm = (logDeath_Cases_Norm-min(logDeath_Cases_Norm))/(max(logDeath_Cases_Norm)-min(logDeath_Cases_Norm)),
                                                         Death_Incidence_Norm = (Death_Incidence_Norm-min(Death_Incidence_Norm))/(max(Death_Incidence_Norm)-min(Death_Incidence_Norm)),
                                                         logDeath_Incidence_Norm = (logDeath_Incidence_Norm-min(logDeath_Incidence_Norm))/(max(logDeath_Incidence_Norm)-min(logDeath_Incidence_Norm)),
                                                         Reffective_Norm = (Reffective_Norm-min(Reffective_Norm))/(max(Reffective_Norm)-min(Reffective_Norm)))

data2023 <- dataFull %>% filter(date > "2022-12-31")

dataFull <- rbind(data2020, data2023)

# Setting disease indicator equal to 0 for 2023
dataFull <- dataFull %>% mutate(Hospital_Cases = case_when(date > "2022-12-31" ~ 0,
                                                           TRUE ~ as.numeric(as.character(Hospital_Cases)))) %>%
  mutate(Hospital_Incidence = case_when(date > "2022-12-31" ~ 0,
                                        TRUE ~ as.numeric(as.character(Hospital_Incidence)))) %>%
  mutate(logHospital_Cases = case_when(date > "2022-12-31" ~ 0,
                                       TRUE ~ as.numeric(as.character(logHospital_Cases)))) %>%
  mutate(logHospital_Incidence = case_when(date > "2022-12-31" ~ 0,
                                           TRUE ~ as.numeric(as.character(logHospital_Incidence)))) %>%
  mutate(Infection_Cases = case_when(date > "2022-12-31" ~ 0,
                                     TRUE ~ as.numeric(as.character(Infection_Cases)))) %>%
  mutate(Infection_Incidence= case_when(date > "2022-12-31" ~ 0,
                                        TRUE ~ as.numeric(as.character(Infection_Incidence)))) %>%
  mutate(logInfection_Cases = case_when(date > "2022-12-31" ~ 0,
                                        TRUE ~ as.numeric(as.character(logInfection_Cases)))) %>%
  mutate(logInfection_Incidence = case_when(date > "2022-12-31" ~ 0,
                                            TRUE ~ as.numeric(as.character(logInfection_Incidence)))) %>%
  mutate(Death_Cases = case_when(date > "2022-12-31" ~ 0,
                                 TRUE ~ as.numeric(as.character(Death_Cases)))) %>%
  mutate(Death_Incidence = case_when(date > "2022-12-31" ~ 0,
                                     TRUE ~ as.numeric(as.character(Death_Incidence)))) %>%
  mutate(logDeath_Cases = case_when(date > "2022-12-31" ~ 0,
                                    TRUE ~ as.numeric(as.character(logDeath_Cases)))) %>%
  mutate(logDeath_Incidence = case_when(date > "2022-12-31" ~ 0,
                                        TRUE ~ as.numeric(as.character(logDeath_Incidence)))) %>%
  mutate(Reffective = case_when(date > "2022-12-31" ~ 0,
                                TRUE ~ as.numeric(as.character(Reffective))))

dataFull <- dataFull %>% filter(federalState %in% chosenModel)

write_csv(dataFull, "inputDataBerlinHHHB.csv")
                          