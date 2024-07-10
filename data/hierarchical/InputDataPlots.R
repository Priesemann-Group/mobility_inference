library(tidyverse)
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

data <- read_csv("/Users/sydney/git/mobility_inference/data/hierarchical/allVariablesHierarchicalModel.csv")

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
ggplot(data) +
#ggplot(data %>% filter(federalState == "Berlin")) +
  geom_point(aes(x=date, y=tmax, color = federalState), size = 2) +
  geom_line(aes(x=date, y=tmax, color=federalState), alpha = 0.3)+
  theme_minimal() +
  theme(text = element_text(size = 20), legend.position = "bottom", legend.title = element_blank()) +
  scale_color_manual(values = palette()) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b") +
  xlab("2020") +
  ylab("Tmax [C°]")

ggsave("InputTemperature.pdf", dpi = 500, w = 12, h = 12)
ggsave("InputTemperature.png", dpi = 500, w = 12, h = 12)

#ggsave("InputTemperatureBerlin.pdf", dpi = 500, w = 12, h = 4)
#ggsave("InputTemperatureBerlin.png", dpi = 500, w = 12, h = 4)

## PRECIPITATION
ggplot(data) +
#ggplot(data %>% filter(federalState == "Berlin")) +
  geom_point(aes(x=date, y=prcp, color = federalState), size = 2) +
  geom_line(aes(x=date, y=prcp, color=federalState), alpha = 0.3)+
  theme_minimal() +
  theme(text = element_text(size = 20), legend.position = "bottom", legend.title = element_blank()) +
  scale_color_manual(values = palette()) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b") +
  xlab("2020") +
  ylab("Precipitation [mm]")

ggsave("InputPrecipitation.pdf", dpi = 500, w = 12, h = 12)
ggsave("InputPrecipitation.png", dpi = 500, w = 12, h = 12)

#ggsave("InputPrecipitationBerlin.pdf", dpi = 500, w = 12, h = 4)
#ggsave("InputPrecipitationBerlin.png", dpi = 500, w = 12, h = 4)

## OUT OF HOME DURATION
ggplot(data) +
#ggplot(data %>% filter(federalState == "Berlin")) +
  geom_point(aes(x=date, y=outOfHomeDuration, color = federalState), size =2) +
  geom_line(aes(x=date, y=outOfHomeDuration, color=federalState), alpha = 0.3)+
  theme_minimal() +
  theme(text = element_text(size = 20), legend.position = "bottom", legend.title = element_blank()) +
  scale_color_manual(values = palette()) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b") +
  xlab("2020") +
  ylab("Out-of-home duration [h]")

ggsave("InputOutOfHomeDuration.pdf", dpi = 500, w = 12, h = 9)
ggsave("InputOutOfHomeDuration.png", dpi = 500, w = 12, h = 9)

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
  geom_point(aes(x=date, y=schoolVacation, color = federalState), size = 3) +
  theme_minimal() +
  theme(text = element_text(size = 20), legend.position = "none", legend.title = element_blank(), strip.text = element_blank()) +
  scale_color_manual(values = palette()) +
  facet_grid(vars(federalState)) +
  theme(panel.spacing = unit(0.4, "cm", data = NULL)) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b") +
  ylab("Days Off School") +
  xlab("")

p3 <- ggplot(data %>% filter(federalState == chosenFedState)) +
  geom_point(aes(x=date, y=pubHoliday, color = federalState), size = 3) +
  theme_minimal() +
  theme(text = element_text(size = 20), legend.position = "none", legend.title = element_blank(), strip.text = element_blank()) +
  scale_color_manual(values = palette()) +
  facet_grid(vars(federalState)) +
  theme(panel.spacing = unit(0.5, "cm", data = NULL)) +
  scale_y_continuous(breaks=c(0,1,2))+
  scale_x_date(date_breaks = "1 month", date_labels = "%b") +
  ylab("Public Holidays") +
  xlab("")

p4 <- ggplot(data %>% filter(federalState == chosenFedState)) +
  geom_point(aes(x=date, y=tmax, color = federalState), size = 3) +
  theme_minimal() +
  theme(text = element_text(size = 20), legend.position = "none", legend.title = element_blank()) +
  scale_color_manual(values = palette()) +
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
  geom_point(aes(x=date, y=daylight, color = federalState), size =3) +
  theme_minimal() +
  theme(text = element_text(size = 20), legend.position = "none", legend.title = element_blank()) +
  scale_color_manual(values = palette()) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b") +
  xlab("2020") +
  ylab("Daylight [h]")

p <- arrangeGrob(p1, p2, p3, p4, p5,p6, nrow = 2)
ggsave("InputDataBerlin.pdf", p, dpi=500, w = 15, h = 6.5)
ggsave("InputDataBerlin.png", p, dpi=500, w = 15, h = 6.5)
