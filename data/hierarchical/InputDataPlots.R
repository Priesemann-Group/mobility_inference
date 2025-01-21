library(tidyverse)
library(gridExtra)
library(ggiraphExtra)
library(gridExtra)
library(ggiraphExtra)

#https://lospec.com/palette-list/nanner-jam
palette <- function() {
  c("#352b40",
    "#653d48",
    "#933f45",
    "#b25e46",
    "#cc925e",
    "#dacb80",
    "#f0e9c9",
    "#76c379",
    "#508d76",
    "#535c89",
    "#7b99c8",
    "#99d4e6",
    "#be7979",
    "#d8b1a1",
    "#7d6e6e",
    "#c2b5a9")
} 

#https://lospec.com/palette-list/arq16
palette <- function() {
  c("#311b92",
    "#ffd19d",
    "#7d3ebf",
    "#aeb5bd",
    "#4d80c9",
    "#e93841",
    "#AC001E",
    "#511e43",
    "#054494",
    "#f1892d",
    "#823e2c",
    "#ffa9a9",
    "#5ae150",
    "#ffe947",
    "#eb6c82",
    "#1e8a4c"
)
}

data <- read_csv("/Users/sydney/git/mobility_inference/data/input_data_hierarchical/inputDataBEHBHHCGNMUCSTUTTMeckpomm.csv")

data$federalState <- factor(data$federalState, levels = c("Baden-Württemberg", "Bayern", "Berlin", "Brandenburg", "Bremen", "Hamburg", "Hessen",
                                                          "Mecklenburg-Vorpommern", "Niedersachsen", "Nordrhein-Westfalen", "Rheinland-Pfalz",
                                                          "Saarland", "Sachsen", "Sachsen-Anhalt", "Schleswig-Holstein", "Thüringen"))

## SCHOOL VACATIONS
ggplot(data) +
#ggplot(data %>% filter(federalState == "Berlin")) +
  geom_point(aes(x=date, y=schoolVacation, color = federalState)) +
  theme_minimal() +
  theme(text = element_text(size = 14), legend.position = "bottom", legend.title = element_blank(), strip.text = element_blank()) +
  scale_color_manual(values = palette()) +
  facet_grid(vars(federalState)) +
  theme(panel.spacing = unit(0.4, "cm", data = NULL)) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b") +
  xlab("2020") +
  ylab("Days Off School")

ggsave("InputDataSchools.pdf", dpi = 500, w = 9, h = 15)
ggsave("InputDataSchools.png", dpi = 500, w = 9, h = 15)

#ggsave("InputDataSchoolsBerlin.pdf", dpi = 500, w = 9, h = 3)
#ggsave("InputDataSchoolsBerlin.png", dpi = 500, w = 9, h = 3)

## PUBLIC HOLIDAYS
ggplot(data) +
#ggplot(data %>% filter(federalState == "Berlin")) +
  geom_point(aes(x=date, y=pubHoliday, color = federalState)) +
  theme_minimal() +
  theme(text = element_text(size = 14), legend.position = "bottom", legend.title = element_blank(), strip.text = element_blank()) +
  scale_color_manual(values = palette()) +
  facet_grid(vars(federalState)) +
  theme(panel.spacing = unit(0.5, "cm", data = NULL)) +
  scale_y_continuous(breaks=c(0,1,2))+
  scale_x_date(date_breaks = "1 month", date_labels = "%b") +
  xlab("2020") +
  ylab("Public Holidays")

ggsave("InputPublicHolidays.pdf", dpi = 500, w = 9, h = 15)
ggsave("InputPublicHolidays.png", dpi = 500, w = 9, h = 15)

# ggsave("InputPublicHolidaysBerlin.pdf", dpi = 500, w = 9, h = 3)
# ggsave("InputPublicHolidaysBerlin.png", dpi = 500, w = 9, h = 3)

## TEMPERATURE

temp <- data %>% mutate(year = year(date)) %>% 
  mutate(year = case_when(year == 2021 ~ 2020, .default = year)) %>%
  group_by(date) %>% 
  summarise(year = year, lci = quantile(tmax, probs =0.025)[[1]], uci = quantile(tmax, probs =0.975)[[1]], tmax = mean(tmax)) %>%
  distinct()

left <- ggplot(temp  %>% filter(date < "2021-03-01")) +
#ggplot(data %>% filter(federalState == "Berlin")) +
  geom_line(aes(x=date, y=tmax), color = "#bd9e39", size = 2)+
  geom_ribbon(aes(ymin = lci, ymax = uci, x = date), alpha = 0.15, fill = "#bd9e39")+ 
  theme_minimal() +
  theme(text = element_text(size = 40), legend.position = "bottom", legend.title = element_blank()) +
  scale_x_date(date_breaks = "2 months", date_labels = "%m/%Y") +
  xlab("Date") +
  ylab("Tmax (C°)") +
  theme(legend.position = "none", legend.title = element_blank()) +
  theme(axis.ticks.x = element_line(),
        axis.ticks.y = element_line(),
        axis.ticks.length = unit(12, "pt")) +
  theme(plot.title = element_text(hjust = 0.5)) 

right <- ggplot(temp  %>% filter(date > "2023-01-01")) +
  #ggplot(data %>% filter(federalState == "Berlin")) +
  geom_line(aes(x=date, y=tmax), color = "#bd9e39", size = 2)+
  geom_ribbon(aes(ymin = lci, ymax = uci, x = date), alpha = 0.15, fill = "#bd9e39")+ 
  theme_minimal() +
  theme(text = element_text(size = 40), legend.position = "bottom", legend.title = element_blank()) +
  scale_x_date(date_breaks = "2 months", date_labels = "%m/%Y") +
  xlab("Date") +
  ylab("Tmax (C°)") +
  theme(legend.position = "none", legend.title = element_blank()) +
  theme(axis.ticks.x = element_line(),
        axis.ticks.y = element_line(),
        axis.ticks.length = unit(12, "pt")) +
  theme(plot.title = element_text(hjust = 0.5)) 

ggarrange(left, ggparagraph(text="   ", face = "italic", size = 14, color = "black"), right, labels = c("A", "", "B"), nrow = 1, ncol = 3,  align = "v", font.label = list(size = 37), widths = c(1,0.05,1))

ggsave("InputTemperature.pdf", dpi = 500, w = 27, h = 9)
ggsave("InputTemperature.png", dpi = 500, w = 27, h = 9)

#ggsave("InputTemperatureBerlin.pdf", dpi = 500, w = 12, h = 4)
#ggsave("InputTemperatureBerlin.png", dpi = 500, w = 12, h = 4)

## DAYLIGHT

daylightdf <- data %>% mutate(year = year(date)) %>% 
  mutate(year = case_when(year == 2021 ~ 2020, .default = year)) %>%
  group_by(date) %>% 
  summarise(year = year, lci = quantile(daylight, probs =0.025)[[1]], uci = quantile(daylight, probs =0.975)[[1]], daylight = mean(daylight)) %>%
  distinct()

left <- ggplot(daylightdf  %>% filter(date < "2021-03-01")) +
  #ggplot(data %>% filter(federalState == "Berlin")) +
  geom_line(aes(x=date, y=daylight), color = "#ad494a", size = 2)+
  geom_ribbon(aes(ymin = lci, ymax = uci, x = date), alpha = 0.15, fill = "#ad494a")+ 
  theme_minimal() +
  theme(text = element_text(size = 40), legend.position = "bottom", legend.title = element_blank()) +
  scale_x_date(date_breaks = "2 months", date_labels = "%m/%Y") +
  xlab("Date") +
  ylab("Daylight (hrs)") +
  theme(legend.position = "none", legend.title = element_blank()) +
  theme(axis.ticks.x = element_line(),
        axis.ticks.y = element_line(),
        axis.ticks.length = unit(12, "pt")) +
  theme(plot.title = element_text(hjust = 0.5)) 

right <- ggplot(daylightdf  %>% filter(date > "2023-01-01")) +
  geom_line(aes(x=date, y=daylight), color = "#ad494a", size = 2)+
  geom_ribbon(aes(ymin = lci, ymax = uci, x = date), alpha = 0.15, fill = "#ad494a")+ 
  theme_minimal() +
  theme(text = element_text(size = 40), legend.position = "bottom", legend.title = element_blank()) +
  scale_x_date(date_breaks = "2 months", date_labels = "%m/%Y") +
  xlab("Date") +
  ylab("Daylight (hrs)") +
  theme(legend.position = "none", legend.title = element_blank()) +
  theme(axis.ticks.x = element_line(),
        axis.ticks.y = element_line(),
        axis.ticks.length = unit(12, "pt")) +
  theme(plot.title = element_text(hjust = 0.5)) 

ggarrange(left, ggparagraph(text="   ", face = "italic", size = 14, color = "black"), right, labels = c("A", "", "B"), nrow = 1, ncol = 3,  align = "v", font.label = list(size = 37), widths = c(1,0.05,1))

ggsave("InputDaylight.pdf", dpi = 500, w = 27, h = 9)
ggsave("InputDaylight.png", dpi = 500, w = 27, h = 9)

#ggsave("InputTemperatureBerlin.pdf", dpi = 500, w = 12, h = 4)
#ggsave("InputTemperatureBerlin.png", dpi = 500, w = 12, h = 4)


## PRECIPITATION

prcp <- data %>% filter(!is.na(prcp)) %>% mutate(year = year(date)) %>% 
  mutate(year = case_when(year == 2021 ~ 2020, .default = year)) %>%
  group_by(date) %>% 
  summarise(year = year, lci = quantile(prcp, probs =0.025)[[1]], uci = quantile(prcp, probs =0.975)[[1]], prcp = mean(prcp)) %>%
  distinct()

left <- ggplot(prcp %>% filter(date < "2021-03-01")) +
  geom_line(aes(x=date, y=prcp), color = "#bd9e39", size = 2) +
  geom_ribbon(aes(ymin = lci, ymax = uci, x = date), alpha = 0.15, fill = "#bd9e39")+ 
  theme_minimal() +
  theme(text = element_text(size = 40), legend.position = "bottom", legend.title = element_blank()) +
  scale_x_date(date_breaks = "2 months", date_labels = "%m/%Y") +
  scale_y_continuous(limits = c(0, 13), breaks = c(0,2,4,6,8,10,12)) +
  xlab("Date") +
  ylab("Precipitation (mm)") +
  theme(legend.position = "none", legend.title = element_blank()) +
  theme(axis.ticks.x = element_line(),
        axis.ticks.y = element_line(),
        axis.ticks.length = unit(12, "pt")) +
  theme(plot.title = element_text(hjust = 0.5)) 

right <- ggplot(prcp %>% filter(date > "2023-01-01")) +
  geom_line(aes(x=date, y=prcp), color = "#bd9e39", size = 2) +
  geom_ribbon(aes(ymin = lci, ymax = uci, x = date), alpha = 0.15, fill = "#bd9e39")+ 
  theme_minimal() +
  theme(text = element_text(size = 40), legend.position = "bottom", legend.title = element_blank()) +
  scale_x_date(date_breaks = "2 months", date_labels = "%m/%Y") +
  scale_y_continuous(limits = c(0, 13), breaks = c(0,2,4,6,8,10,12)) +
  xlab("Date") +
  ylab("Precipitation (mm)") +
  theme(legend.position = "none", legend.title = element_blank()) +
  theme(axis.ticks.x = element_line(),
        axis.ticks.y = element_line(),
        axis.ticks.length = unit(12, "pt")) +
  theme(plot.title = element_text(hjust = 0.5)) 

ggarrange(left, ggparagraph(text="   ", face = "italic", size = 14, color = "black"), right, labels = c("A", "", "B"), nrow = 1, ncol = 3,  align = "v", font.label = list(size = 37), widths = c(1,0.05,1))

ggsave("InputPrecipitation.pdf", dpi = 500, w = 27, h = 9)
ggsave("InputPrecipitation.png", dpi = 500, w = 27, h = 9)

#ggsave("InputPrecipitationBerlin.pdf", dpi = 500, w = 12, h = 4)
#ggsave("InputPrecipitationBerlin.png", dpi = 500, w = 12, h = 4)

outOfHome <- data %>% mutate(year = year(date)) %>% 
  mutate(year = case_when(year == 2021 ~ 2020, .default = year)) %>%
  group_by(date) %>% 
  summarise(year = year, lci = quantile(outOfHomeDuration, probs =0.025)[[1]], uci = quantile(outOfHomeDuration, probs =0.975)[[1]], outOfHomeDuration = mean(outOfHomeDuration)) %>%
  distinct()

## OUT OF HOME DURATION
left <- ggplot(outOfHome %>% filter(date < "2021-03-01")) +
  #ggplot(data %>% filter(federalState == "Berlin")) +
  #geom_point(aes(x=date, y=outOfHomeDuration), size =2) +
  geom_line(aes(x=date, y=outOfHomeDuration), color = "#a55194", size = 2)+
  geom_ribbon(aes(ymin = lci, ymax = uci, x = date), alpha = 0.15, fill = "#a55194")+
  theme_minimal() +
  theme(text = element_text(size = 40), legend.position = "bottom", legend.title = element_blank()) +
  scale_x_date(date_breaks = "2 months", date_labels = "%m/%Y") +
  xlab("Date") +
  ylab("Out-of-home\nDuration (hours)") +
  scale_y_continuous(limits=c(4, 9.5), breaks = c(4,5,6,7,8,9)) +
  theme(legend.position = "none", legend.title = element_blank()) +
  theme(axis.ticks.x = element_line(),
        axis.ticks.y = element_line(),
        axis.ticks.length = unit(12, "pt")) +
  theme(plot.title = element_text(hjust = 0.5)) 

right <- ggplot(outOfHome %>% filter(date > "2023-01-01")) +
#ggplot(data %>% filter(federalState == "Berlin")) +
  #geom_point(aes(x=date, y=outOfHomeDuration), size =2) +
  geom_line(aes(x=date, y=outOfHomeDuration), size = 2, color = "#a55194")+
  geom_ribbon(aes(ymin = lci, ymax = uci, x = date), alpha = 0.15, fill = "#a55194")+
  theme_minimal() +
  theme(text = element_text(size = 40), legend.position = "bottom", legend.title = element_blank()) +
  scale_color_manual(values = palette()) +
  xlab("Date") +
  scale_x_date(date_breaks = "2 months", date_labels = "%m/%Y") +
  ylab("Out-of-home\nDuration (hours)") +
  scale_y_continuous(limits=c(4, 9.5), breaks = c(4,5,6,7,8,9)) +
  theme(legend.position = "none", legend.title = element_blank()) +
  theme(axis.ticks.x = element_line(),
        axis.ticks.y = element_line(),
        axis.ticks.length = unit(12, "pt")) +
  theme(plot.title = element_text(hjust = 0.5)) 

ggarrange(left, ggparagraph(text="   ", face = "italic", size = 14, color = "black"), right, labels = c("A", "", "B"), nrow = 1, ncol = 3,  align = "v", font.label = list(size = 37), widths = c(1,0.05,1))

ggsave("InputOutOfHomeDuration.pdf", dpi = 500, w = 27, h = 9)
ggsave("InputOutOfHomeDuration.png", dpi = 500, w = 27, h = 9)

#ggsave("InputOutOfHomeDurationBerlin.pdf", dpi = 500, w = 12, h = 6)
#ggsave("InputOutOfHomeDurationBerlin.png", dpi = 500, w = 12, h = 6)


## CASES INCIDENCDE
ggplot(data) +
#ggplot(data %>% filter(federalState == "Berlin")) +
  geom_point(aes(x=date, y=Infection_Incidence, color = federalState), size = 2) +
  geom_line(aes(x=date, y=Infection_Incidence, color=federalState), alpha = 0.3)+
  theme_minimal() +
  theme(text = element_text(size = 20), legend.position = "bottom", legend.title = element_blank()) +
  scale_color_manual(values = palette()) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b") +
  xlab("2020") +
  ylab("New Weekly Cases/100,000") +
  scale_y_log10()

ggsave("InputCases.pdf", dpi = 500, w = 12, h = 6)
ggsave("InputCases.png", dpi = 500, w = 12, h = 6)

#ggsave("InputCasesBerlin.pdf", dpi = 500, w = 12, h = 5)
#ggsave("InputCasesBerlin.png", dpi = 500, w = 12, h = 5)

## HOSPITAL INCIDENCDE
ggplot(data) +
#ggplot(data %>% filter(federalState == "Berlin")) +
  geom_point(aes(x=date, y=Hospital_Incidence, color = federalState)) +
  geom_line(aes(x=date, y=Hospital_Incidence, color=federalState), alpha = 0.3)+
  theme_minimal() +
  theme(text = element_text(size = 20), legend.position = "bottom", legend.title = element_blank()) +
  scale_color_manual(values = palette()) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b") +
  xlab("2020") +
  ylab("New Hospital Cases/100,000") +
  scale_y_log10()

ggsave("InputHospitals.pdf", dpi = 500, w = 12, h = 6)
ggsave("InputHospitals.png", dpi = 500, w = 12, h = 6)

#ggsave("InputHospitalsBerlin.pdf", dpi = 500, w = 12, h = 5)
#ggsave("InputHospitalsBerlin.png", dpi = 500, w = 12, h = 5)

## DEATH INCIDENCE
ggplot(data) +
#ggplot(data %>% filter(federalState =="Berlin")) +
  geom_point(aes(x=date, y=Death_Incidence, color = federalState)) +
  geom_line(aes(x=date, y=Death_Incidence, color=federalState), alpha = 0.3)+
  theme_minimal() +
  theme(text = element_text(size = 20), legend.position = "bottom", legend.title = element_blank()) +
  scale_color_manual(values = palette()) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b") +
  xlab("2020") +
  ylab("New Deaths/100,000") + 
  scale_y_log10()

ggsave("InputDeaths.pdf", dpi = 500, w = 12, h = 6)
ggsave("InputDeaths.png", dpi = 500, w = 12, h = 6)

#ggsave("InputDeathsBerlin.pdf", dpi = 500, w = 12, h = 5)
#ggsave("InputDeathsBerlin.png", dpi = 500, w = 12, h = 5)



# 6-Panel Plot for One Federal State --------------------------------------

chosenFedState <- "Berlin"

p1 <- ggplot(data %>% filter(federalState == chosenFedState)) +
  geom_point(aes(x=date, y=outOfHomeDuration, color = federalState), size = 3) +
  theme_minimal() +
  theme(text = element_text(size = 20), legend.position = "none", legend.title = element_blank()) +
  scale_color_manual(values = palette()) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b") +
  ylab("Out-of-home dur. [h]") +
  xlab("")

p2 <- ggplot(data %>% filter(federalState == chosenFedState)) +
  geom_point(aes(x=date, y=schoolVacation), color = "#311b92", size = 3) +
  theme_minimal() +
  theme(text = element_text(size = 30), legend.position = "none", legend.title = element_blank(), strip.text = element_blank()) +
  scale_color_manual(values = palette()) +
  facet_grid(vars(federalState)) +
  theme(panel.spacing = unit(0.4, "cm", data = NULL)) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b") +
  ylab("Days Off School") +
  xlab("")

data <- data %>% mutate(Theta0.95 = (0.95 - 1)/7 * schoolVacation + 1) %>% 
                  mutate(Theta0.90 = (0.90 - 1)/7 * schoolVacation + 1) %>% 
                  mutate(Theta0.85 = (0.85 - 1)/7 * schoolVacation + 1)

ggplot(data %>% filter(federalState == chosenFedState)) +
  geom_point(aes(x = date, y = Theta0.95, color = "Theta = 0.95"), size = 3) +
  geom_point(aes(x = date, y = Theta0.90, color = "Theta = 0.90"), size = 3) +
  geom_point(aes(x = date, y = Theta0.85, color = "Theta = 0.85"), size = 3) +
  theme_minimal() +
  theme(text = element_text(size = 30), legend.position = "bottom", legend.title = element_blank(), strip.text = element_blank()) +
  scale_color_manual(values = palette()) +
  facet_grid(vars(federalState)) +
  theme(panel.spacing = unit(0.5, "cm", data = NULL)) +
  #scale_y_continuous(breaks = c(0,1,2)) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b") +
  ylab("v(t)") +
  xlab("")

p3 <- ggplot(data %>% filter(federalState == chosenFedState)) +
  geom_point(aes(x = date, y = pubHoliday), color = "#311b92", size = 3) +
  theme_minimal() +
  theme(text = element_text(size = 30), legend.position = "none", legend.title = element_blank(), strip.text = element_blank()) +
  scale_color_manual(values = palette()) +
  facet_grid(vars(federalState)) +
  theme(panel.spacing = unit(0.5, "cm", data = NULL)) +
  scale_y_continuous(breaks = c(0,1,2)) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b") +
  ylab("Public Holidays") +
  xlab("")

data <- data %>% mutate(Theta0.95 = (0.95 - 1)/7 * pubHoliday + 1) %>% 
                  mutate(Theta0.90 = (0.90 - 1)/7 * pubHoliday + 1) %>% 
                  mutate(Theta0.97 = (0.97 - 1)/7 * pubHoliday + 1)

ggplot(data %>% filter(federalState == chosenFedState)) +
  geom_point(aes(x = date, y = Theta0.95, color = "Theta = 0.95"), size = 3) +
  geom_point(aes(x = date, y = Theta0.90, color = "Theta = 0.90"), size = 3) +
  geom_point(aes(x = date, y = Theta0.97, color = "Theta = 0.97"), size = 3) +
  theme_minimal() +
  theme(text = element_text(size = 30), legend.position = "bottom", legend.title = element_blank(), strip.text = element_blank()) +
  scale_color_manual(values = palette()) +
  facet_grid(vars(federalState)) +
  theme(panel.spacing = unit(0.5, "cm", data = NULL)) +
  #scale_y_continuous(breaks = c(0,1,2)) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b") +
  ylab("h(t)") +
  xlab("")


p4 <- ggplot(data %>% filter(federalState == chosenFedState)) +
  geom_point(aes(x=date, y=tmax), color = "#311b92", size = 3) +
  theme_minimal() +
  theme(text = element_text(size = 30), legend.position = "none", legend.title = element_blank()) +
  #scale_color_manual(values = palette()) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b") +
  xlab("2020") +
  ylab("Tmax [C°]")

p5 <- ggplot(data %>% filter(federalState == chosenFedState)) +
  geom_point(aes(x=date, y=prcp, color = federalState), size = 3) +
  theme_minimal() +
  theme(text = element_text(size = 20), legend.position = "none", legend.title = element_blank()) +
  scale_color_manual(values = palette()) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b") +
  xlab("2020") +
  ylab("Precipitation [mm]")

p6 <- ggplot(data %>% filter(federalState == chosenFedState)) +
  geom_point(aes(x=date, y=daylight), color = "#311b92", size =3) +
  theme_minimal() +
  theme(text = element_text(size = 30), legend.position = "none", legend.title = element_blank()) +
  #scale_color_manual(values = palette()) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b") +
  xlab("2020") +
  ylab("Daylight [h]")

p <- arrangeGrob(p1, p2, p3, p4, p5,p6, nrow = 2)
ggsave("InputDataBerlin.pdf", p, dpi=500, w = 15, h = 6.5)
ggsave("InputDataBerlin.png", p, dpi=500, w = 15, h = 6.5)
