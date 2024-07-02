library(tidyverse)
library(lubridate)
library(readxl)
library(httr)
library(gridExtra)
library(ggiraphExtra)
library(leaps)
library(stats)

#A note on the data frame weather_data_all produced by this script: One should be careful when using the values provided for the first and last week of the years 2020/2022.
#For example, the average for the first week of 2020 only takes into account 01/01/2020-01/05/2020, even though the week already starts on 12/30/2019.
#For us this is not an issue, as we only consider dates from March until mid-December. But, if anyone ever intends to use this for the full year, adaptations are necessary.

#Using R 4.2.2

#Looking at this on a federal state level, so here's a little reminder of the state's capitals. Weather IDs are taken from meteostat and were (for this exercise) extracted manually
# Baden-Württemberg (Hauptstadt: Stuttgart) 10737
# Bayern (München) 10865
# Berlin (Berlin) 10382
# Brandenburg (Potsdam) 10379
# Bremen (Bremen) 10224
# Hessen (Wiesbaden) 10633
# Mecklenburg-Vorpommern (Schwerin) 10162
# Niedersachsen (Hannover) 10338
# Nordrhein-Westfalen (Düsseldorf) 10400
# Rheinland-Pfalz (Mainz) D3137
# Saarland (Saarbrücken) D6217
# Sachsen (Dresden) D1051
# Sachsen-Anhalt (Magdeburg) 10361
# Schleswig-Holstein (Kiel) 10044
# Thüringen (Erfurt) 10554

#Setting up da data frame containing the states, the corresponding weather IDs and the inhabitants
dict_state_id <- data.frame(matrix(nrow = 0, ncol = 3))
colnames(dict_state_id) <- c("Bundesland", "ID", "EinwohnerInnen")
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Baden-Württemberg", 10738, 11124642)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Bayern", 10865, 13176989)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Berlin", 10382, 3677472)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Brandenburg", 10379, 2537868)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Bremen", 10224, 676463)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Hamburg", 10147, 1853935)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Hessen", 10633, 6295017)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Mecklenburg-Vorpommern", 10162, 1611160)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Niedersachsen", 10338, 8027031)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Nordrhein-Westfalen", 10400, 17924591)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Rheinland-Pfalz", "D3137", 4106485)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Saarland", "D6217", 982348)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Sachsen", "D1051", 4043002)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Sachsen-Anhalt", 10361, 2169253)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Schleswig-Holstein", 10044, 2922005)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Thüringen", 10554, 2108863)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Gesamt", 10382, 83237124) #Careful, for now, this means that ``overall German weather`` is equal to the weather in Berlin

#Reading in weather data
weather_data_all <- data.frame(matrix(nrow = 0, ncol = 5))
for (state in 1 : 17) {
ID <- dict_state_id[as.integer(state), 2]
weather_data <- read_delim(paste0("https://bulk.meteostat.net/daily/", ID, ".csv.gz"))
colnames(weather_data) <- c("Date", "tavg", "tmin", "tmax", "prcp", "snow", "wdir", "wspd", "wpgt", "pres", "tsun")

weather_data$Date <- as.Date(weather_data$Date)
weather_data <- weather_data[, c("Date", "tmax", "tavg", "prcp")]
weather_data$Bundesland <- dict_state_id[as.integer(state), 1]
weather_data$EinwohnerInnen <- dict_state_id[as.integer(state), 3]
weather_data$EinwohnerInnenRelativ <- as.integer(dict_state_id[as.integer(state), 3])/83237124


weather_data_all <- rbind(weather_data_all, weather_data)
}

#Turning daily data into weekly averages
weather_data_all <- filter(weather_data_all, Date < "2024-01-01") %>%
filter(Date > "2019-12-29") %>%
  mutate(week = isoweek(Date)) %>%
  mutate(year = year(Date)) %>%
  group_by(year, week, Bundesland) %>%
  summarise(Bundesland = Bundesland, Date = max(Date), tmax = mean(tmax), tavg = mean(tavg), prcp = mean(prcp), EinwohnerInnen, EinwohnerInnenRelativ) %>% distinct()

#Recall line 48: ``overall German weather'' == ``Berlin weather'' -> This needs to be adjusted -> We use a weighted average instead
for(date in unique(weather_data_all$Date)){
filtered <- filter(weather_data_all, Date == date) %>%
            filter(Bundesland != "Gesamt")

weather_data_all$tmax[weather_data_all$Date == date & weather_data_all$Bundesland == "Gesamt"] <- weighted.mean(filtered$tmax, filtered$EinwohnerInnenRelativ)
weather_data_all$tavg[weather_data_all$Date == date & weather_data_all$Bundesland == "Gesamt"] <- weighted.mean(filtered$tavg, filtered$EinwohnerInnenRelativ)
weather_data_all$prcp[weather_data_all$Date == date & weather_data_all$Bundesland == "Gesamt"] <- weighted.mean(filtered$prcp, filtered$EinwohnerInnenRelativ)
}

weather_data_all <- weather_data_all %>% ungroup() %>%
                    filter(Bundesland == "Gesamt") %>%
                    filter(year %in% c(2020, 2023)) %>%
                    select(Date, tmax, tavg, prcp)
