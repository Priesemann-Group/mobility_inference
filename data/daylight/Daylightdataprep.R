library(httr)
library(jsonlite)
library(stringr)
library(tidyverse)

dict_state_id <- data.frame(matrix(nrow = 0, ncol = 4))
colnames(dict_state_id) <- c("Bundesland", "Hauptstadt", "latitude", "longitude")
# Note: The lat/lon of the capitals have been looked up manually
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Baden-Württemberg", "Stuttgart", 48.78, 9.18)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Bayern", "München", 48.13, 11.58)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Berlin", "Berlin", 52.52, 13.40)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Brandenburg", "Potsdam", 52.39, 13.06)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Bremen", "Bremen", 53.07, 8.81)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Hamburg", "Hamburg", 53.55, 9.99)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Hessen", "Wiesbaden", 50.08, 8.24)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Mecklenburg-Vorpommern", "Schwerin", 53.63, 11.41)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Niedersachsen", "Hannover", 52.37, 9.74)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Nordrhein-Westfalen", "Düsseldorf", 51.23, 6.78)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Rheinland-Pfalz", "Mainz", 49.99, 8.25)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Saarland", "Saarbrücken", 49.23, 7.00)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Sachsen", "Dresden", 51.05, 13.74)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Sachsen-Anhalt", "Magdeburg", 52.13, 11.62)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Schleswig-Holstein", "Kiel", 54.32, 10.14)
dict_state_id[nrow(dict_state_id) + 1, ] <- c("Thüringen", "Erfurt", 50.98, 11.03)

for(i in 1:nrow(dict_state_id)){
string <- paste0("https://archive-api.open-meteo.com/v1/archive?latitude=", dict_state_id[i,3,], "&longitude=", dict_state_id[i,4], "&start_date=2020-01-01&end_date=2021-01-01&daily=sunrise,sunset&timezone=Europe%2FBerlin")
res <- GET("https://archive-api.open-meteo.com/v1/archive?latitude=52.52&longitude=13.41&start_date=2020-01-01&end_date=2021-01-01&daily=sunrise,sunset&timezone=Europe%2FBerlin")
data <- fromJSON(rawToChar(res$content))
names(data)
data <- data.frame(data$daily$time, data$daily$sunrise, data$daily$sunset)
colnames(data) <- c("date", "sunrise", "sunset")
data <- data %>% mutate(sunrise = str_sub(sunrise, -5, -1)) %>% 
                  mutate(sunset = str_sub(sunset, -5, -1)) %>%
                  mutate(sunrise = as.POSIXct(sunrise, format = '%H:%M')) %>% 
                  mutate(sunset = as.POSIXct(sunset, format = '%H:%M')) %>%
                  mutate(daylight = sunset - sunrise) %>%
                  mutate(daylight = as.double(daylight))

write_csv(data, paste0("Daylight", dict_state_id[i,1], ".csv"))
}