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




## PLOT VACATION
school_vacations_germany_weekly <- read.csv("/Users/sydney/git/mobility_inference/data/school_vacations/school_vacations_germany_weekly.csv")
school_vacations_germany_weekly <- school_vacations_germany_weekly %>% filter(federalState == "Berlin")
school_vacations_germany_weekly$date <- as.Date(school_vacations_germany_weekly$date)

upper_plot <- ggplot(school_vacations_germany_weekly %>% filter(date < "2021-01-01"), aes(x = date, y = schoolVacation)) +
  geom_point(size = 2, show.legend = FALSE,  col = "#1b9e77") +
  theme(legend.position = "bottom", legend.title = element_blank()) +
  scale_x_date(date_breaks = "1 month", date_labels = "%d/%b") +
  theme_minimal() +
  # theme(axis.ticks.x = element_line(), 
  #       axis.ticks.y = element_line(),
  #       axis.ticks.length = unit(5, "pt"), 
  #       text = element_text(size = 20)) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) +
  theme(legend.text = element_blank(), legend.title = element_blank()) +
  theme(axis.ticks.y = element_line(), 
        axis.ticks.x = element_line(), 
        text = element_text(size = 20), 
        axis.ticks.length = unit(5, "pt"), 
        axis.title.x=element_blank(),
        axis.text.x=element_blank()) +
  ylab("#School Vacation \n Days - 2020")


theta <-0.8
school_vacations_germany_weekly <- school_vacations_germany_weekly %>% mutate(vacTransformed1 = (theta-1)/7*schoolVacation +1)

theta <- 0.9
school_vacations_germany_weekly <- school_vacations_germany_weekly %>% mutate(vacTransformed2 = (theta-1)/7*schoolVacation +1)


theta <- 0.95
school_vacations_germany_weekly <- school_vacations_germany_weekly %>% mutate(vacTransformed3 = (theta-1)/7*schoolVacation +1)

lower_plot <- ggplot(school_vacations_germany_weekly %>% filter(date < "2021-01-01")) +
  geom_point(aes(x=date, y = vacTransformed1, color = "theta = 0.8"), size = 3) +
  geom_point(aes(x=date, y = vacTransformed2, color = "theta = 0.9"), size = 3) +
  geom_point(aes(x=date, y = vacTransformed3, color = "theta = 0.95"), size = 3) +
  theme(legend.position = "bottom", legend.title = element_blank()) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b") +
  theme_minimal() +
  # theme(axis.ticks.x = element_line(), 
  #       axis.ticks.y = element_line(),
  #       axis.ticks.length = unit(5, "pt"), 
  #       text = element_text(size = 20)) +
  theme_minimal() +
  theme(legend.position = "bottom", legend.title=element_blank()) +
  theme(axis.ticks.y = element_line(), 
        axis.ticks.x = element_line(), 
        text = element_text(size = 20), 
        axis.ticks.length = unit(5, "pt"), 
        axis.title.x=element_blank()) +
  ylab("Transformed School Vacation")

plotBoth <- arrangeGrob(upper_plot, lower_plot, nrow = 2)
ggsave("VacationPlot.pdf", plotBoth, dpi = 500, h = 7.5, w = 10)
ggsave("VacationPlot.png", plotBoth, dpi = 500, h = 7.5, w = 10)
