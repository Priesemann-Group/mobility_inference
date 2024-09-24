
library(readxl)
library(tidyverse)
library(MMWRweek)

#chosen_model = "cities"
#chosen_model = "cities_non_hierarchical"

# LK Population, corresp. Fed State ---------------------------------------

LK <- read_xlsx("/Users/sydney/Downloads/04-kreise.xlsx", sheet = 2)
colnames(LK) <- c("LK_Id",
                  "Kreisfreie_Stadt",
                  "LK_Name",
                  "NUTS3",
                  "Area_in_km2",
                  "Population",
                  "Population_Male",
                  "Population_Female",
                  "Population_per_km2")
LK <- LK %>% filter(nchar(LK_Id) == 5)
LK <- LK %>% dplyr::rowwise() %>% mutate(LK_Name = str_split(LK_Name, ",")[[1]][1]) %>%
  mutate(LK_Name = case_when(LK_Name == "Mühldorf a.Inn" ~ "Mühldorf am Inn",
                             LK_Name == "Pfaffenhofen a.d.Ilm" ~ "Pfaffenhofen an der Ilm",
                             LK_Name == "Neumarkt i.d.OPf." ~ "Neumarkt in der Oberpfalz",
                             LK_Name == "Weiden i.d.OPf." ~ "Weiden in der Oberpfalz",
                             LK_Name == "Altenkirchen (Westerwald)" ~ "Altenkirchen",
                             LK_Name == "Nienburg (Weser)" ~ "Nienburg/Weser",
                             LK_Name == "Dillingen a.d.Donau" ~ "Dillingen an der Donau",
                             LK_Name == "Neustadt a.d.Waldnaab" ~ "Neustadt an der Waldnaab",
                             LK_Name == "Neustadt a.d.Aisch-Bad Windsheim" ~ "Neustadt an der Aisch-Bad Windsheim",
                             LK_Name == "Cottbus" ~ "Cottbus - Chóśebuz",
                             LK_Name == "Wunsiedel i.Fichtelgebirge" ~ "Wunsiedel im Fichtelgebirge",
                             LK_Name == "Lindau (Bodensee)" ~ "Lindau",
                             LK_Name == "Rhein-Kreis Neuss" ~ "Rhein-Neuss",
                             .default = as.character(LK_Name)))
LK <- LK %>% mutate(federalState = case_when(str_sub(LK_Id,1,2) == "01" ~ "Schleswig-Holstein",
                                         str_sub(LK_Id,1,2) == "02" ~ "Hamburg",
                                         str_sub(LK_Id,1,2) == "03" ~ "Niedersachsen",
                                         str_sub(LK_Id,1,2) == "04" ~ "Bremen",
                                         str_sub(LK_Id,1,2) == "05" ~ "Nordrhein-Westfalen",
                                         str_sub(LK_Id,1,2) == "06" ~ "Hessen",
                                         str_sub(LK_Id,1,2) == "07" ~ "Rheinland-Pfalz",
                                         str_sub(LK_Id,1,2) == "08" ~ "Baden-Württemberg",
                                         str_sub(LK_Id,1,2) == "09" ~ "Bayern",
                                         str_sub(LK_Id,1,2) == "10" ~ "Saarland",
                                         str_sub(LK_Id,1,2) == "11" ~ "Berlin",
                                         str_sub(LK_Id,1,2) == "12" ~ "Brandenburg",
                                         str_sub(LK_Id,1,2) == "13" ~ "Mecklenburg-Vorpommern",
                                         str_sub(LK_Id,1,2) == "14" ~ "Sachsen",
                                         str_sub(LK_Id,1,2) == "15" ~ "Sachsen-Anhalt",
                                         str_sub(LK_Id,1,2) == "16" ~ "Thüringen"
))

WeatherStations <- read_csv2("/Users/sydney/git/mobility_inference/data/weather/WeatherStations.csv")

LK <- left_join(LK, WeatherStations)

LK <- LK %>% filter(LK_Name %in% c("Berlin", "Bremen", "Hamburg", "Stuttgart", "München", "Köln"))

LK <- LK[-c(6:8),]

# Mobility Data -----------------------------------------------------------

mobility_data <- read_delim("https://svn.vsp.tu-berlin.de/repos/public-svn/matsim/scenarios/countries/de/episim/mobilityData/landkreise/LK_mobilityData_weekly.csv") %>%
  filter(Landkreis != "Landkreis München") %>%
  dplyr::rowwise() %>%
  mutate(Landkreis = str_remove(Landkreis, "Landkreis ")) %>%
  mutate(Landkreis = str_remove(Landkreis, "Kreis "))
colnames(mobility_data)[2] <- "LK_Name"
mobility_data$date <- as.character(paste0(substring(mobility_data$date, 1, 4),  "-", substring(mobility_data$date, 5, 6), "-", substring(mobility_data$date, 7, 8)))
mobility_data$date <- as.Date(mobility_data$date)
mobility_data <- mobility_data %>% filter(LK_Name != "Eisenach") %>% filter(LK_Name != "Deutschland")

mobility_data <- left_join(LK, mobility_data)

# Weather -----------------------------------------------------------------

WeatherStations <- read_csv2("/Users/sydney/git/mobility_inference/data/weather/WeatherStations.csv")

WeatherStations <- WeatherStations %>% filter(LK_Name %in% c("Berlin", "Bremen", "Hamburg", "Stuttgart", "München", "Köln"))

WeatherStations <- WeatherStations[-6,]

#Reading in weather data
#FOR NOW THIS IS NOT THE WEEKLY AVERAGE --> WORK IN PROGRESS
weather_data_all <- data.frame(matrix(nrow = 0, ncol = 5))
for (weatherId in unique(WeatherStations$Wetter_ID)) {
  if(!is.na(weatherId)){
    weather_data <- read_delim(paste0("https://bulk.meteostat.net/v2/daily/", weatherId, ".csv.gz"))
    colnames(weather_data) <- c("Date", "tavg", "tmin", "tmax", "prcp", "snow", "wdir", "wspd", "wpgt", "pres", "tsun")

    weather_data$Date <- as.Date(weather_data$Date)
    weather_data <- weather_data[, c("Date", "tmax", "tavg", "prcp")]
    weather_data$weather_station <- weatherId

    weather_data_all <- rbind(weather_data_all, weather_data)
  }
}

weather_data_all <- weather_data_all %>% filter(Date < as.Date("2024-01-01")) %>%
  filter(Date > as.Date("2020-01-01")) %>%
  mutate(week = isoweek(Date)) %>%
  mutate(year = year(Date)) %>%
  group_by(year, week, weather_station) %>%
  summarise(Wetter_ID = weather_station, Date = max(Date), tmax = mean(tmax), tavg = mean(tavg), prcp = mean(prcp)) %>%
  distinct() %>% ungroup %>% select(Wetter_ID, Date, tmax, tavg, prcp)

colnames(weather_data_all)[2] <- "date"

mobility_data <- left_join(mobility_data, weather_data_all)

# School vacations --------------------------------------------------------

schoolVacations <- read_csv("/Users/sydney/git/mobility_inference/data/school_vacations/school_vacations_germany_weekly.csv")
schoolVacations <- schoolVacations %>% filter(federalState != "Deutschland") %>%
  select(c(date, federalState, schoolVacation))

mobility_data <- left_join(mobility_data, schoolVacations)

# Public Holidays ---------------------------------------------------------

pubHolidays <- read_csv("/Users/sydney/git/mobility_inference/data/public_holidays/public_holidays_germany_weekly.csv")
colnames(pubHolidays)[2] <- "federalState"
pubHolidays <- pubHolidays %>% filter(federalState != "Deutschland")

mobility_data <- left_join(mobility_data, pubHolidays)


# Daylight ----------------------------------------------------------------

daylight <- read_csv("/Users/sydney/git/mobility_inference/data/daylight/DaylightFederalStatesWeekly.csv")


mobility_data <- left_join(mobility_data, daylight)

# Cases -------------------------------------------------------------------

cases <- read_csv("https://raw.githubusercontent.com/robert-koch-institut/COVID-19_7-Tage-Inzidenz_in_Deutschland/main/COVID-19-Faelle_7-Tage-Inzidenz_Landkreise.csv")

colnames(cases) <- c("date", "LK_Id", "Population", "Cumulative_Cases", "New_Cases", "Infection_Cases", "Infection_Incidence")

cases$date <- as.Date(cases$date)

cases <- cases %>% mutate(weekday = wday(date)) %>%
  filter(weekday == 1) %>% filter(date < as.Date("2024-01-01")) %>%
  select(date, LK_Id, Infection_Cases, Infection_Incidence) %>%
  mutate(Infection_Cases = case_when(Infection_Cases == 0 ~ 10^(-100),
                                     TRUE ~ as.numeric(as.character(Infection_Cases)))) %>%
  mutate(Infection_Incidence = case_when(Infection_Incidence == 0 ~ 10^(-100),
                                         TRUE ~ as.numeric(as.character(Infection_Incidence)))) %>%
  mutate(logInfection_Cases = log10(Infection_Cases), logInfection_Incidence = log10(Infection_Incidence))

cases <- cases %>% group_by(LK_Id) %>% mutate(Reffective = Infection_Incidence/lead(Infection_Incidence, 5)) %>%
  ungroup() %>% mutate(LK_Id = case_when(LK_Id == "11001" ~ "11000", .default = LK_Id))

mobility_data <- left_join(mobility_data, cases)

# Hospitalisations --------------------------------------------------------

hospitalizations <- read_csv("https://raw.githubusercontent.com/robert-koch-institut/COVID-19-Hospitalisierungen_in_Deutschland/master/Aktuell_Deutschland_COVID-19-Hospitalisierungen.csv")

colnames(hospitalizations) <- c("date", "federalState", "federalState_Id", "Agegroup", "Hospital_Cases", "Hospital_Incidence")

hospitalizations <- hospitalizations %>%
  filter(Agegroup == "00+") %>%
  select(date, federalState, federalState_Id, Hospital_Cases, Hospital_Incidence) %>%
  mutate(Hospital_Cases = case_when(Hospital_Cases == 0 ~ 10^(-100),
                                 TRUE ~ as.numeric(as.character(Hospital_Cases)))) %>%
  mutate(Hospital_Incidence = case_when(Hospital_Incidence == 0 ~ 10^(-100),
                                     TRUE ~ as.numeric(as.character(Hospital_Incidence)))) %>%
  mutate(logHospital_Cases=log10(Hospital_Cases), logHospital_Incidence = log10(Hospital_Incidence))

mobility_data <- left_join(mobility_data, hospitalizations)

# Deaths ------------------------------------------------------------------

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

mobility_data <- left_join(mobility_data, deaths)

#Only keep dates which are needed for the Bayesian inference
data2020 <- mobility_data %>% filter(date < "2021-03-01") %>% filter(date > "2020-03-01")

data2020 <- data2020 %>% mutate(Infection_Incidence = case_when(Infection_Incidence == 0 ~ 0.0001,
                                                                TRUE ~ as.numeric(as.character(Infection_Incidence)))) %>%
  mutate(Hospital_Cases = case_when(Hospital_Cases == 0 ~ 0.0001,
                                    TRUE ~ as.numeric(as.character(Hospital_Cases)))) %>%
  mutate(Hospital_Incidence = case_when(Hospital_Incidence == 0 ~ 0.0001,
                                        TRUE ~ as.numeric(as.character(Hospital_Incidence)))) %>%
  mutate(Death_Cases = case_when(Death_Cases == 0 ~ 0.001,
                                 TRUE ~ as.numeric(as.character(Death_Cases)))) %>%
  mutate(Death_Incidence = case_when(Death_Incidence == 0 ~ 0.001,
                                     TRUE ~ as.numeric(as.character(Death_Incidence))))


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

data2023 <- mobility_data %>% filter(date > "2023-01-01")

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
                                        TRUE ~ as.numeric(as.character(logDeath_Incidence))))
  #mutate(Reffective = case_when(date > "2022-12-31" ~ 0,
                                #TRUE ~ as.numeric(as.character(Reffective))))
chosen_model <- "cities"

if(chosen_model == "cities"){
dataFull <- dataFull %>% mutate(index = case_when(LK_Name == "Berlin" ~ 0,
                                                  LK_Name == "Bremen" ~ 1,
                                                  LK_Name == "Hamburg" ~ 2,
                                                  LK_Name == "München" ~ 3,
                                                  LK_Name == "Stuttgart" ~ 4,
                                                  LK_Name == "Köln" ~ 5,))
} else if(chosen_model == "cities_non_hierarchical"){
  dataFull <- dataFull %>% mutate(index = 0) 
}

dataFull <- dataFull %>% mutate(timeCounter = case_when(date == as.Date("2020-03-08") ~ 0,
                                                        date == as.Date("2020-03-15") ~ 1,
                                                        date == as.Date("2020-03-22") ~ 2,
                                                        date == as.Date("2020-03-29") ~ 3,
                                                        date == as.Date("2020-04-05") ~ 4,
                                                        date == as.Date("2020-04-12") ~ 5,
                                                        date == as.Date("2020-04-19") ~ 6,
                                                        date == as.Date("2020-04-26") ~ 7,
                                                        date == as.Date("2020-05-03") ~ 8,
                                                        date == as.Date("2020-05-10") ~ 9,
                                                        date == as.Date("2020-05-17") ~ 10,
                                                        date == as.Date("2020-05-24") ~ 11,
                                                        date == as.Date("2020-05-31") ~ 12,
                                                        date == as.Date("2020-06-07") ~ 13,
                                                        date == as.Date("2020-06-14") ~ 14,
                                                        date == as.Date("2020-06-21") ~ 15,
                                                        date == as.Date("2020-06-28") ~ 16,
                                                        date == as.Date("2020-07-05") ~ 17,
                                                        date == as.Date("2020-07-12") ~ 18,
                                                        date == as.Date("2020-07-19") ~ 19,
                                                        date == as.Date("2020-07-26") ~ 20,
                                                        date == as.Date("2020-08-02") ~ 21,
                                                        date == as.Date("2020-08-09") ~ 22,
                                                        date == as.Date("2020-08-16") ~ 23,
                                                        date == as.Date("2020-08-23") ~ 24,
                                                        date == as.Date("2020-08-30") ~ 25,
                                                        date == as.Date("2020-09-06") ~ 26,
                                                        date == as.Date("2020-09-13") ~ 27,
                                                        date == as.Date("2020-09-20") ~ 28,
                                                        date == as.Date("2020-09-27") ~ 29,
                                                        date == as.Date("2020-10-04") ~ 30,
                                                        date == as.Date("2020-10-11") ~ 31,
                                                        date == as.Date("2020-10-18") ~ 32,
                                                        date == as.Date("2020-10-25") ~ 33,
                                                        date == as.Date("2020-11-01") ~ 34,
                                                        date == as.Date("2020-11-08") ~ 35,
                                                        date == as.Date("2020-11-15") ~ 36,
                                                        date == as.Date("2020-11-22") ~ 37,
                                                        date == as.Date("2020-11-29") ~ 38,
                                                        date == as.Date("2020-12-06") ~ 39,
                                                        date == as.Date("2020-12-13") ~ 40,
                                                        date == as.Date("2020-12-20") ~ 41,
                                                        date == as.Date("2020-12-27") ~ 42,
                                                        date == as.Date("2021-01-03") ~ 43,
                                                        date == as.Date("2021-01-10") ~ 44,
                                                        date == as.Date("2021-01-17") ~ 45,
                                                        date == as.Date("2021-01-24") ~ 46,
                                                        date == as.Date("2021-01-31") ~ 47,
                                                        date == as.Date("2021-02-07") ~ 48,
                                                        date == as.Date("2021-02-14") ~ 49,
                                                        date == as.Date("2021-02-21") ~ 50,
                                                        date == as.Date("2021-02-28") ~ 51,
                                                        date > as.Date("2021-03-01") ~ 10^7))

dataFull <- dataFull %>% filter(date > "2020-03-01")

dataFull <- dataFull %>% mutate(Reffective_Norm = case_when(is.na(Reffective_Norm) ~ 0.00001,
                                                            Reffective_Norm == 0 ~ 0.00001,
                                                            .default = Reffective_Norm)) %>%
  mutate(Infection_Incidence_Norm = case_when(is.na(Infection_Incidence_Norm) ~ 0.00001,
                                              Infection_Incidence_Norm == 0 ~ 0.00001,
                                              .default = Infection_Incidence_Norm))



dataFull <- dataFull[,c(12,2:ncol(dataFull))]
dataFull <- dataFull[,-12]
dataFull <- dataFull %>% ungroup()

setwd("/Users/sydney/git/mobility_inference/data/input_data_hierarchical/")
write_delim(dataFull, "inputDataBEHBHHCGNMUCSTUTT_long.csv", delim = ",")
