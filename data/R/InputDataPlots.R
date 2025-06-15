#InputDataAnalysis

library(tidyverse)
library(here)

setwd("/Users/sydney/git/mobility_inference/data/input_data_hierarchical/")


# Out Of Home Duration ----------------------------------------------------

outOfHomeDuration <- read_csv("inputDataincl2024_fourthhundred.csv")

#Groups from https://www.bbsr.bund.de/BBSR/DE/forschung/raumbeobachtung/Raumabgrenzungen/deutschland/kreise/siedlungsstrukturelle-kreistypen/kreistypen.html
LKType <- read_xlsx("/Users/sydney/Downloads/raumgliederungen-referenzen-2023.xlsx", sheet = 4)
LKType <- LKType %>% mutate(KRS_NAME = case_when(KRS_NAME == "Dillingen a.d.Donau" ~ "Dillingen an der Donau",
                                                 KRS_NAME == "Augsburg" ~ "Landkreis Augsburg",
                                                 KRS_NAME == "Leipzig" ~ "Landkreis Leipzig",
                                                 KRS_NAME == "Schweinfurt" ~ "Landkreis Schweinfurt",
                                                 KRS_NAME == "Würzburg" ~ "Landkreis Würzburg",
                                                 .default = KRS_NAME))
LKType$KRS_NAME <- str_replace(LKType$KRS_NAME, ", Stadt$", "")
LKType$KRS_NAME <- str_replace(LKType$KRS_NAME, ", Stadtkreis$", "")
LKType$KRS_NAME <- str_replace(LKType$KRS_NAME, ", Landeshauptstadt$", "")
LKType$KRS_NAME <- str_replace(LKType$KRS_NAME, ", Freie und Hansestadt$", "")
GrosseGrossstadt <- LKType %>% filter(KTD_NAME == "Große kreisfreie Großstadt")
KleineGrossstadt <- LKType %>% filter(KTD_NAME == "Kleine kreisfreie Großstadt")
StaedtischerKreis <- LKType %>% filter(KTD_NAME == "Städtischer Kreis")
LaendlicherKreis <- LKType %>% filter(KTD_NAME == "Dünn besiedelter ländlicher Kreis")
Verdichtungsansatz <- LKType %>% filter(KTD_NAME == "Ländlicher Kreis mit Verdichtungsansätzen")

outOfHomeDuration <- outOfHomeDuration %>% mutate(group = case_when(LK_Name %in% c("Berlin", "Hamburg", "Bremen") ~ "Stadtstaat",
                                                        LK_Name %in% GrosseGrossstadt$KRS_NAME ~ "Grosse Grossstadt",
                                                        LK_Name %in% KleineGrossstadt$KRS_NAME ~ "Kleine Grossstadt",
                                                        LK_Name %in% LaendlicherKreis$KRS_NAME ~ "Dünn besiedelt ländlicher Kreis",
                                                        LK_Name %in% StaedtischerKreis$KRS_NAME ~ "Städtische Kreise",
                                                        LK_Name %in% Verdichtungsansatz$KRS_NAME ~ "Ländlicher Kreis mit Verdichtungsansätzen")) %>%
  mutate(group_eng = case_when(group == "Stadtstaat" ~ "City State",
                               group == "Grosse Grossstadt" ~ "Large City",
                               group == "Kleine Grossstadt" ~ "Small City",
                               group == "Städtische Kreise" ~ "Suburban/Independent Town",
                               group == "Ländlicher Kreis mit Verdichtungsansätzen" ~ "Medium Rural",
                               group == "Dünn besiedelt ländlicher Kreis" ~ "Rural"))


#hexcodes from here https://martin-ueding.de/posts/matplotlib-colors-scales-as-hex-codes/#tab20b

outOfHomeDuration <- outOfHomeDuration %>% group_by(date) %>% summarise(lowerperc = quantile(outOfHomeDuration, 0.025), upperperc = quantile(outOfHomeDuration, 0.975), outOfHomeDuration = mean(outOfHomeDuration))
# 
# outOfHomeDuration$group_eng <- factor(outOfHomeDuration$group_eng, levels = c("Rural","Medium Rural", "Suburban/Independent Town", "Small City", "Large City", "City State"))
# 
# outOfHomeDuration <- outOfHomeDuration %>% mutate(group_reduced = case_when(group_eng == "Large City" ~ "City",
#                                                                             group_eng == "Small City" ~ "City",
#                                                                             .default = group_eng))
# 
# outOfHomeDuration$group_reduced <- factor(outOfHomeDuration$group_reduced, levels = c("Rural","Medium Rural", "Suburban/Independent Town", "City", "City State"))

mobilityA <- ggplot(outOfHomeDuration %>% filter(date < "2021-03-01") %>% filter(date > "2020-03-01"), aes(x=date, y=outOfHomeDuration)) +
  geom_ribbon(aes(ymin = lowerperc, ymax = upperperc),fill = "#7b4173", alpha = 0.3) + 
  geom_line(colour="#7b4173", size = 2) +
  theme_minimal() +
  theme(text = element_text(size = 55)) +
  theme(legend.position = "bottom", legend.title = element_blank()) +
  theme(axis.ticks.x = element_line(),
        axis.ticks.y = element_line(),
        axis.ticks.length = unit(10, "pt"),
        plot.margin = margin(l=0.2,r=0.5, unit ="cm")) +
  xlab("Date") +
  ylab("Out-Of-Home\nDuration (hours)") +
  #guides(color=guide_legend(nrow=2,byrow=TRUE)) +
  ylim(3,9.5) +
  scale_x_date(breaks = seq(as.Date("2020-03-01"), as.Date("2021-03-01"), by = "2 month"), date_labels = "%m/%y")

ggarrange(mobilityA, mobilityB, labels = c("A", "B"), align="v", nrow = 1, ncol = 2, font.label = list(size = 37), legend = "bottom", widths = c(1,1), common.legend = TRUE)

ggsave("MobilityInput.png", mobilityA, dpi = 500, w = 16.5, bg = "white", h = 8)

# Temperature -------------------------------------------------------------

temperature <- read_csv("inputDataincl2024_fourthhundred.csv")

temperature <- temperature %>% group_by(date) %>% summarise(lowerperc = quantile(tmax, 0.025), upperperc = quantile(tmax, 0.975), tmax = mean(tmax))

tempA <- ggplot(temperature %>% filter(date < "2021-03-01") %>% filter(date > "2020-03-01") , aes(x=date, y=tmax)) +
  geom_ribbon(aes(ymin = lowerperc, ymax = upperperc), fill = "#8c6d31", alpha = 0.3) + 
  geom_line(colour="#8c6d31", size = 3) +
  theme_minimal() +
  theme(text = element_text(size = 60)) +
  theme(legend.position = "bottom", legend.title = element_blank()) +
  theme(axis.ticks.x = element_line(),
        axis.ticks.y = element_line(),
        axis.ticks.length = unit(10, "pt"),
        plot.margin = margin (l=0.2, t = 0.3, r=1.3, unit = "cm"),
        axis.line = element_line()) +
  ylim(-10,32)+
  xlab("Date") +
  ylab("Tmax (C°)") +
  scale_x_date(breaks = seq(as.Date("2020-03-01"), as.Date("2021-03-01"), by = "3 month"), date_labels = "%m/%y")

tempB <- ggplot(temperature %>% filter(date < "2025-01-01") %>% filter(date > "2023-12-31") , aes(x=date, y=tmax)) +
  geom_ribbon(aes(ymin = lowerperc, ymax = upperperc), fill = "#8c6d31", alpha = 0.3) + 
  geom_line(colour="#8c6d31", size = 3) +
  theme_minimal() +
  theme(text = element_text(size = 45)) +
  theme(legend.position = "bottom", legend.title = element_blank()) +
  theme(axis.ticks.x = element_line(),
        axis.ticks.y = element_line(),
        axis.ticks.length = unit(10, "pt")) +
  xlab("Date") +
  ylim(-10,35)+
  ylab("Tmax (C°)") +
  scale_x_date(breaks = seq(as.Date("2024-01-01"), as.Date("2025-01-01"), by = "3 month"), date_labels = "%m/%y")

ggarrange(tempA, tempB, labels = c("A", "B"), align="v", nrow = 1, ncol = 2, font.label = list(size = 37), legend = "bottom", heights = c(1.5,0.08,1))

ggsave("InputTemperature.pdf", tempA, dpi = 500, w = 13, h = 8)
ggsave("InputTemperature.png", tempA, dpi = 500, w = 13, h = 8)

# School Holidays ---------------------------------------------------------

school <- read_csv("inputDataincl2024_fourthhundred.csv")

school <- school %>% group_by(date) %>% summarise(lowerperc = quantile(schoolVacation, 0.025), upperperc = quantile(schoolVacation, 0.975), schoolVacation = mean(schoolVacation))

schoolA <- ggplot(school %>% filter(date < "2021-03-01") %>% filter(date > "2020-03-01"), aes(x=date, y=schoolVacation)) +
  geom_ribbon(aes(ymin = lowerperc, ymax = upperperc), fill = "#637939", alpha = 0.3) + 
  geom_line(colour="#637939", size = 3) +
  theme_minimal() +
  theme(text = element_text(size = 60)) +
  theme(legend.position = "bottom", legend.title = element_blank()) +
  theme(axis.ticks.x = element_line(),
        axis.ticks.y = element_line(),
        axis.ticks.length = unit(10, "pt"),
        plot.margin = margin (l=0.2, t = 0.3, r=1.3, unit = "cm"),
        axis.line = element_line()) +
  xlab("Date") +
  ylab("Vacation\nDays") +
  scale_x_date(breaks = seq(as.Date("2020-03-01"), as.Date("2021-03-01"), by = "3 month"), date_labels = "%m/%y")

schoolB <- ggplot(school %>% filter(date < "2025-01-01") %>% filter(date > "2023-12-31"), aes(x=date, y=schoolVacation)) +
  geom_ribbon(aes(ymin = lowerperc, ymax = upperperc), fill = "#b5cf6b", alpha = 0.3) + 
  geom_line(colour="#637939", size = 2) +
  theme_minimal() +
  theme(text = element_text(size = 45)) +
  theme(legend.position = "bottom", legend.title = element_blank()) +
  theme(axis.ticks.x = element_line(),
        axis.ticks.y = element_line(),
        axis.ticks.length = unit(10, "pt")) +
  xlab("Date") +
  ylab("Vacation\nDays") +
  scale_x_date(breaks = seq(as.Date("2024-01-01"), as.Date("2025-01-01"), by = "2 month"), date_labels = "%m/%y")

ggarrange(schoolA, schoolB, labels = c("A", "B"), align="v", nrow = 1, ncol = 2, font.label = list(size = 37), legend = "bottom", heights = c(1.5,0.08,1))

ggsave("InputSchools.pdf", schoolA, dpi = 500, w = 13, h = 8)
ggsave("InputSchools.png", schoolA, dpi = 500, w = 13, h = 8)

# Public Holidays ---------------------------------------------------------

pubhol <- read_csv("inputDataincl2024_fourthhundred.csv")

pubhol <- pubhol %>% group_by(date) %>% summarise(lowerperc = quantile(pubHoliday, 0.025), upperperc = quantile(pubHoliday, 0.975), pubHoliday = mean(pubHoliday))

pubholA <- ggplot(pubhol %>% filter(date < "2021-03-01") %>% filter(date > "2020-03-01"), aes(x=date, y=pubHoliday)) +
  geom_ribbon(aes(ymin = lowerperc, ymax = upperperc), fill = "#8ca252", alpha = 0.3) + 
  geom_line(colour="#8ca252", size = 3) +
  theme_minimal() +
  theme(text = element_text(size = 70)) +
  theme(legend.position = "bottom", legend.title = element_blank()) +
  theme(axis.ticks.x = element_line(),
        axis.ticks.y = element_line(),
        axis.ticks.length = unit(10, "pt"),
        plot.margin = margin (l=0.2, t = 0.3, r=1.3, unit = "cm")) +
  xlab("Date") +
  ylab("Public\nHolidays") +
  scale_x_date(breaks = seq(as.Date("2020-03-01"), as.Date("2021-03-01"), by = "3 month"), date_labels = "%m/%y")

pubholB <- ggplot(pubhol %>% filter(date < "2025-01-01") %>% filter(date > "2023-12-31"), aes(x=date, y=pubHoliday)) +
  geom_ribbon(aes(ymin = lowerperc, ymax = upperperc), fill = "#cedb9c", alpha = 0.3) + 
  geom_line(colour="#b5cf6b", size = 2) +
  theme_minimal() +
  theme(text = element_text(size = 45)) +
  theme(legend.position = "bottom", legend.title = element_blank()) +
  theme(axis.ticks.x = element_line(),
        axis.ticks.y = element_line(),
        axis.ticks.length = unit(10, "pt")) +
  xlab("Date") +
  ylab("Public\nHolidays") +
  scale_x_date(breaks = seq(as.Date("2024-01-01"), as.Date("2025-01-01"), by = "2 month"), date_labels = "%m/%y")

ggarrange(pubholA, pubholB, labels = c("A", "B"), align="v", nrow = 1, ncol = 2, font.label = list(size = 37), legend = "bottom", heights = c(1.5,0.08,1))

ggsave("InputPubHol.png", pubholA, dpi = 500, w = 13, h = 8, bg = "white")


# Cases -------------------------------------------------------------------

cases <- read_csv("inputDataincl2024_fourthhundred.csv")

cases <- cases %>% group_by(date) %>% summarise(lowerperc = quantile(Infection_Incidence, 0.025), upperperc = quantile(Infection_Incidence, 0.975), Infection_Incidence = mean(Infection_Incidence))

casesA <- ggplot(cases %>% filter(date < "2021-03-01") %>% filter(date > "2020-03-01"), aes(x=date, y=Infection_Incidence)) +
  geom_ribbon(aes(ymin = lowerperc, ymax = upperperc), fill = "#5254a3", alpha = 0.3) + 
  geom_line(colour="#5254a3", size = 3) +
  theme_minimal() +
  theme(text = element_text(size = 70)) +
  theme(legend.position = "bottom", legend.title = element_blank()) +
  theme(axis.ticks.x = element_line(),
        axis.ticks.y = element_line(),
        axis.ticks.length = unit(10, "pt"),
        plot.margin = margin (l=0.2, t = 0.3, r=1.3, unit = "cm")) +
  xlab("Date") +
  ylab("7-Day-Incid.\nper 100,000") +
  scale_x_date(breaks = seq(as.Date("2020-03-01"), as.Date("2021-03-01"), by = "3 month"), date_labels = "%m/%y")

casesB <- ggplot(cases %>% filter(date < "2025-01-01") %>% filter(date > "2023-12-31"), aes(x=date, y=Infection_Incidence)) +
  geom_ribbon(aes(ymin = lowerperc, ymax = upperperc), fill = "#9c9ede", alpha = 0.3) + 
  geom_line(colour="#5254a3", size = 2) +
  theme_minimal() +
  theme(text = element_text(size = 45)) +
  theme(legend.position = "bottom", legend.title = element_blank()) +
  theme(axis.ticks.x = element_line(),
        axis.ticks.y = element_line(),
        axis.ticks.length = unit(10, "pt")) +
  xlab("Date") +
  ylab("7-Day-Incid.\nper 100,000") +
  scale_x_date(breaks = seq(as.Date("2024-01-01"), as.Date("2025-01-01"), by = "2 month"), date_labels = "%m/%y")

ggarrange(casesA, casesB, labels = c("A", "B"), align="v", nrow = 1, ncol = 2, font.label = list(size = 37), legend = "bottom", heights = c(1.5,0.08,1))

ggsave("InputCases2020.png", casesA, dpi = 500, w = 13, h = 8, bg = "white")
