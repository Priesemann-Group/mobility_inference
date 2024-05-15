#Population data comes from https://www.destatis.de/DE/Themen/Gesellschaft-Umwelt/Bevoelkerung/Bevoelkerungsstand/Tabellen/bevoelkerung-nichtdeutsch-laender.html
population <- c(11280257, 13369393, 3755251, 2573135, 684864, 1892122, 6391360, 1628378, 8140242, 18139116, 4158150, 992666, 4086152, 2186643, 2953270, 2126836)

#Read in holiday data on federate state level
school_vacations <- read_csv2("/Users/sydney/git/mobility_inference/data/holidays/school_holidays_2020.csv")
school_vacations <- school_vacations %>% pivot_longer(cols = `Baden-Württemberg`:Thüringen)
colnames(school_vacations) <- c("date", "federalState", "schoolVacation")

#Compute population-weighted average
school_vacations_germany_daily <- school_vacations %>% group_by(date) %>% summarise(germany = weighted.mean(schoolVacation))

colnames(school_vacations_germany_daily) <- c("date", "schoolVacation")

school_vacations_germany_daily <- school_vacations_germany_daily %>% mutate(year = year(date)) %>%
  mutate(week = isoweek(date))
school_vacations_germany_weekly <- school_vacations_germany_daily %>% group_by(year, week) %>% summarise(date = max(date), schoolVacation = sum(schoolVacation))

school_vacations_germany_weekly <- school_vacations_germany_weekly %>% ungroup()
school_vacations_germany_weekly <- school_vacations_germany_weekly %>% select(date, schoolVacation)
#write_csv(school_vacations_germany_weekly, "school_vacations_germany_weekly.csv")


school_vacations_germany_daily <- school_vacations_germany_daily %>% ungroup()
school_vacations_germany_daily <- school_vacations_germany_daily %>% select(date, schoolVacation)
#write_csv(school_vacations_germany_daily, "school_vacations_germany_daily.csv")

#Set up data set that contains German + federal state data
#Weekly data
school_vacations_germany_weekly <- school_vacations_germany_weekly %>% mutate(federalState = "Deutschland")
school_vacations_weekly <- school_vacations %>% mutate(year = year(date)) %>%
                                                mutate(week = isoweek(date))
school_vacations_weekly <- school_vacations_weekly %>% group_by(year, week, federalState) %>% summarise(date = max(date), schoolVacation = sum(schoolVacation)) %>%
                                                       ungroup()
school_vacations_weekly <- school_vacations_weekly %>% select(c("date", "federalState", "schoolVacation"))
school_vacations_weekly <- rbind(school_vacations_weekly, school_vacations_germany_weekly)

test <- data.frame()
for(fedState in unique(school_vacations_weekly$federalState)){
school_vacations_fedState <- school_vacations_weekly %>% filter(federalState == fedState)
school_vacations_fedState <- pivot_wider(school_vacations_fedState, names_from = date, values_from = schoolVacation)
test <- rbind(test, school_vacations_fedState)
}

write_csv(school_vacations_weekly, "school_vacations_germany_weekly.csv")

#Daily data
school_vacations_germany_daily <- school_vacations_germany_daily %>% mutate(federalState = "Deutschland")
school_vacations <- rbind(school_vacations, school_vacations_germany_daily)
write_csv(school_vacations_weekly, "school_vacations_germany_daily.csv")
