##Boxplots over time

model <- "2025-07-02_400LK_exp_UsedForPostprocessing"
model <- "2025-08-20_400_notest"

diseaseFactor <- read_csv(paste0("/Users/sydney/git/mobility_inference/results/", model, "/d_C.csv"))
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
diseaseFactor <- diseaseFactor %>% select(index, Date, value) %>% mutate(Type = "Cases")
diseaseFactor$Date <- as.Date(diseaseFactor$Date)

temperatureFactor <- read_csv(paste0("/Users/sydney/git/mobility_inference/results/", model, "/temperature_factor.csv"))
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
temperatureFactor <- temperatureFactor %>% select(index, Date, value) %>% mutate(Type = "Temperature")
temperatureFactor$Date <- as.Date(temperatureFactor$Date)

vacationFactor <- read_csv(paste0("/Users/sydney/git/mobility_inference/results/", model, "/vacation_factor.csv"))
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
vacationFactor <- vacationFactor %>% select(index, Date, value) %>% mutate(Type = "School vacation")
vacationFactor$Date <- as.Date(vacationFactor$Date)

holidayFactor <- read_csv(paste0("/Users/sydney/git/mobility_inference/results/", model, "/holiday_factor.csv"))
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
holidayFactor <- holidayFactor %>% select(index, Date, value) %>% mutate(Type = "Public holiday")
holidayFactor$Date <- as.Date(holidayFactor$Date)

colors <- c("Cases" = "#5254a3", "Temperature" = "#637939", "School vacation" = "#8c6d31", "Public holidays" = "#843c39")

ggplot() +
  geom_boxplot(data = diseaseFactor, aes(x=Date, y = value, group = Date, color = "Cases"), fill = "#5254a3", alpha = 0.4, linewidth = 1) +
  geom_boxplot(data = temperatureFactor, aes(x=Date, y = value, group = Date, color = "Temperature"), fill = "#637939", alpha = 0.4, linewidth = 1) +
  geom_boxplot(data = vacationFactor, aes(x=Date, y = value, group = Date, color = "School vacation"), fill = "#8c6d31", alpha = 0.4, linewidth = 1) +
  geom_boxplot(data = holidayFactor, aes(x=Date, y = value, group = Date, color = "Public holidays"), fill = "#843c39", alpha = 0.4, linewidth = 1) +
  theme_minimal() +
  theme(text = element_text(size = 43)) +
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
  scale_x_date(breaks = seq(as.Date("2020-04-01"), as.Date("2021-02-01"), by = "2 month"), date_labels = "%d/%b/%y", expand = c(0, 0)) + 
  theme(legend.position = "bottom", legend.title = element_blank()) +
  theme(axis.ticks.x = element_line(),
        axis.ticks.y = element_line(),
        axis.ticks.length = unit(10, "pt"),
        axis.minor.ticks.length.x = unit(7, "pt"),
        #axis.minor.ticks.x = element_line(color = "#000000"),
        axis.line = element_line()) +
  ylab("Multiplicative Impact on\nOut-of-home Duration") +
  scale_color_manual(values = colors)

ggsave("DistributionMultiplicativeImpacts_Fig3.pdf", dpi = 500, w = 18, h = 9)
ggsave("DistributionMultiplicativeImpacts_Fig3.png", dpi = 500, w = 18, h = 9)

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
