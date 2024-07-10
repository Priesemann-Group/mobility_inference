
library(readxl)


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


# Mobility Data -----------------------------------------------------------

mobility_data <- read_delim("https://svn.vsp.tu-berlin.de/repos/public-svn/matsim/scenarios/countries/de/episim/mobilityData/landkreise/LK_mobilityData_weekly.csv") %>%
  dplyr::rowwise() %>%
  mutate(Landkreis = str_remove(Landkreis, "Landkreis ")) %>%
  mutate(Landkreis = str_remove(Landkreis, "Kreis "))
colnames(mobility_data)[2] <- "LK_Name" 
mobility_data$date <- as.character(paste0(substring(mobility_data$date, 1, 4),  "-", substring(mobility_data$date, 5, 6), "-", substring(mobility_data$date, 7, 8)))
mobility_data$date <- as.Date(mobility_data$date)
mobility_data <- mobility_data %>% filter(LK_Name != "Eisenach") %>% filter(LK_Name != "Deutschland")

mobility_data <- left_join(mobility_data, LK)

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


