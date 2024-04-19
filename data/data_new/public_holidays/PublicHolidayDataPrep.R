
#Population data comes from https://www.destatis.de/DE/Themen/Gesellschaft-Umwelt/Bevoelkerung/Bevoelkerungsstand/Tabellen/bevoelkerung-nichtdeutsch-laender.html
population <- c(11280257, 13369393, 3755251, 2573135, 684864, 1892122, 6391360, 1628378, 8140242, 18139116, 4158150, 992666, 4086152, 2186643, 2953270, 2126836)

#Read in holiday data on federate state level
public_holidays <- read_csv("/Users/sydney/git/mobility_inference/data/data_new/public_holidays/public_holidays_fedStates_daily_tidy.csv")

#Compute population-weighted average
public_holidays_germany_daily <- public_holidays %>% group_by(date) %>% summarise(germany = weighted.mean(PubHoliday))

colnames(public_holidays_germany_daily) <- c("date", "pubHoliday")

public_holidays_germany_daily <- public_holidays_germany_daily %>% mutate(year = year(date)) %>%
  mutate(week = isoweek(date))
public_holidays_germany_weekly <- public_holidays_germany_daily %>% group_by(year, week) %>% summarise(date = max(date), pubHoliday = sum(pubHoliday))

public_holidays_germany_weekly <- public_holidays_germany_weekly %>% ungroup()
public_holidays_germany_weekly <- public_holidays_germany_weekly %>% select(date, pubHoliday)
write_csv(public_holidays_germany_weekly, "public_holidays_germany_weekly.csv")


public_holidays_germany_daily <- public_holidays_germany_daily %>% ungroup()
public_holidays_germany_daily <- public_holidays_germany_daily %>% select(date, pubHoliday)
write_csv(public_holidays_germany_daily, "public_holidays_germany_daily.csv")

#Set up data set that contains German + federal state data
#Weekly data
public_holidays_germany_weekly <- public_holidays_germany_weekly %>% mutate(Bundesland = "Deutschland")
public_holidays_weekly <- public_holidays %>% mutate(year = year(date)) %>%
  mutate(week = isoweek(date))
public_holidays_weekly <- public_holidays_weekly %>% group_by(year, week, Bundesland) %>% summarise(date = max(date), pubHoliday = sum(PubHoliday)) %>%
  ungroup()
public_holidays_weekly <- public_holidays_weekly %>% select(c("date", "Bundesland", "pubHoliday"))
public_holidays_weekly <- rbind(public_holidays_weekly, public_holidays_germany_weekly)

write_csv(public_holidays_weekly, "public_holidays_germany_weekly.csv")

#Daily data
public_holidays_germany_daily <- public_holidays_germany_daily %>% mutate(Bundesland = "Deutschland")
colnames(public_holidays) <- c("date", "Bundesland", "pubHoliday")
public_holidays <- rbind(public_holidays, public_holidays_germany_daily)
write_csv(public_holidays_weekly, "public_holidays_germany_daily.csv")
