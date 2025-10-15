#InputDataAnalysis
library(ggpubr)
library(tidyverse)
library(here)
library(ggpattern)
library(giscoR)
library(ggiraph)
library(readxl)

setwd("/Users/sydney/git/mobility_inference/data/input_data_hierarchical/")


# Out Of Home Duration ----------------------------------------------------

outOfHomeDuration <- read_csv("inputDataincl2024_fourhundred.csv")

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


test <- outOfHomeDuration %>% filter(date < as.Date("2020-06-01")) %>% group_by(LK_Name) %>% slice_min(outOfHomeDuration) #%>% ungroup() %>% count(date)


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
  geom_ribbon(aes(ymin = lowerperc, ymax = upperperc),fill = "#a55194", alpha = 0.3) + 
  geom_line(colour="#a55194", size = 3) +
  theme_minimal() +
  #theme(text = element_text(size = 50)) +
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
    axis.text = element_text(color = "black", size = 42),  # Axis labels
    axis.title = element_text(color = "black", size = 47),
    axis.title.x = element_text(margin = margin(t = 10)),  # top margin for x-axis title
    axis.title.y = element_text(margin = margin(r = 10)),
    legend.position = "none"
  ) +
  xlab("Date") +
  ylab("Out-of-home duration\n(hours)") +
  #guides(color=guide_legend(nrow=2,byrow=TRUE)) +
  ylim(3,9.5) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_x_date(breaks = seq(as.Date("2020-04-01"), as.Date("2021-02-01"), by = "3 month"), date_labels = "%d/%b/%y", expand = c(0, 0))

#ggarrange(mobilityA, mobilityB, labels = c("A", "B"), align="v", nrow = 1, ncol = 2, font.label = list(size = 37), legend = "bottom", widths = c(1,1), common.legend = TRUE)

ggsave("MobilityInput.pdf", mobilityA, dpi = 500, w = 18, bg = "white", h = 8)
ggsave("MobilityInput.png", mobilityA, dpi = 500, w = 18, bg = "white", h = 8)

# Temperature -------------------------------------------------------------

temperature <- read_csv("inputDataincl2024_fourhundred.csv")

temperature <- temperature %>% group_by(date) %>% summarise(lowerperc = quantile(tmax, 0.025), upperperc = quantile(tmax, 0.975), tmax = mean(tmax))

tempA <- ggplot(temperature %>% filter(date < "2021-03-01") %>% filter(date > "2020-03-01") , aes(x=date, y=tmax)) +
  geom_ribbon(aes(ymin = lowerperc, ymax = upperperc), fill = "#637939", alpha = 0.3) + 
  geom_line(colour="#637939", size = 3) +
  theme_minimal() +
  #theme(text = element_text(size = 45)) +
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
    axis.text = element_text(color = "black", size = 42),  # Axis labels
    axis.title = element_text(color = "black", size = 47),
    axis.title.x = element_text(margin = margin(t = 10)),  # top margin for x-axis title
    axis.title.y = element_text(margin = margin(r = 10)),
    legend.position = "none"
  ) +
  #scale_y_continuous(expand = c(0, 0)) +
  scale_x_date(breaks = seq(as.Date("2020-04-01"), as.Date("2021-02-01"), by = "3 month"), date_labels = "%d/%b/%y", expand = c(0, 0)) +
  ylim(-8,34)+
  xlab("Date") +
  ylab("Temperature (C°)") 

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

ggsave("InputTemperature.pdf", tempA, dpi = 500, w = 18, h = 8)
ggsave("InputTemperature.png", tempA, dpi = 500, w = 18, h = 8, bg = "white")

# School Holidays ---------------------------------------------------------

school <- read_csv("inputDataincl2024_fourhundred.csv")

school <- school %>% group_by(date) %>% summarise(lowerperc = quantile(schoolVacation, 0.025), upperperc = quantile(schoolVacation, 0.975), schoolVacation = mean(schoolVacation))

schoolA <- ggplot(school %>% filter(date < "2021-03-01") %>% filter(date > "2020-03-01"), aes(x=date, y=schoolVacation)) +
  geom_line(colour="#8c6d31", size = 3) +
  geom_ribbon(aes(ymin = lowerperc, ymax = upperperc), fill = "#8c6d31", alpha = 0.3) +
  theme_minimal() +
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
    axis.text = element_text(color = "black", size = 42),  # Axis labels
    axis.title = element_text(color = "black", size = 47),
    axis.title.x = element_text(margin = margin(t = 10)),  # top margin for x-axis title
    axis.title.y = element_text(margin = margin(r = 10)),
    legend.position = "none"
  ) +
  #scale_y_continuous(expand = c(0, 0)) +
  scale_x_date(breaks = seq(as.Date("2020-04-01"), as.Date("2021-02-01"), by = "3 month"), date_labels = "%d/%b/%y", expand = c(0, 0)) +
  xlab("Date") +
  ylab("Vacation days")

schoolB <- ggplot(school %>% filter(date < "2025-01-01") %>% filter(date > "2023-12-31"), aes(x=date, y=schoolVacation)) +
  geom_ribbon(aes(ymin = lowerperc, ymax = upperperc), fill = "#b5cf6b", alpha = 0.3) + 
  geom_line(colour="#637939", size = 2) +
  theme_minimal() +
  theme(text = element_text(size = 45)) +
  theme(legend.position = "bottom", legend.title = element_blank()) +
  theme(axis.ticks.x = element_line(),
        axis.ticks.y = element_line(),
        axis.ticks.length = unit(10, "pt"),
        axis.title.x = element_text(margin = margin(t = 50)),  # top margin for x-axis title
        axis.title.y = element_text(margin = margin(r = 20))) +
  xlab("Date") +
  ylab("Vacation\nDays") +
  scale_x_date(breaks = seq(as.Date("2024-01-01"), as.Date("2025-01-01"), by = "2 month"), date_labels = "%m/%y")

ggarrange(schoolA, schoolB, labels = c("A", "B"), align="v", nrow = 1, ncol = 2, font.label = list(size = 37), legend = "bottom", heights = c(1.5,0.08,1))

ggsave("InputSchools.pdf", schoolA, dpi = 500, w = 18, h = 8)
ggsave("InputSchools.png", schoolA, dpi = 500, w = 18, h = 8, bg = "white")

# Public Holidays ---------------------------------------------------------

pubhol <- read_csv("inputDataincl2024_fourhundred.csv")

pubhol <- pubhol %>% group_by(date) %>% summarise(lowerperc = quantile(pubHoliday, 0.025), upperperc = quantile(pubHoliday, 0.975), pubHoliday = mean(pubHoliday))

pubholA <- ggplot(pubhol %>% filter(date < "2021-03-01") %>% filter(date > "2020-03-01"), aes(x=date, y=pubHoliday)) +
  geom_ribbon(aes(ymin = lowerperc, ymax = upperperc), fill = "#843c39", alpha = 0.3) + 
  geom_line(colour="#843c39", size = 3) +
  theme_minimal() +
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
    axis.text = element_text(color = "black", size = 42),  # Axis labels
    axis.title = element_text(color = "black", size = 47),
    axis.title.x = element_text(margin = margin(t = 10)),  # top margin for x-axis title
    axis.title.y = element_text(margin = margin(r = 10)),
    legend.position = "none"
  ) +
  scale_x_date(breaks = seq(as.Date("2020-04-01"), as.Date("2021-02-01"), by = "3 month"), date_labels = "%d/%b/%y", expand = c(0, 0)) +
  xlab("Date") +
  ylab("Public holidays") 

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

ggsave("InputPubHol.png", pubholA, dpi = 500, w = 18, h = 8, bg = "white")
ggsave("InputPubHol.pdf", pubholA, dpi = 500, w = 18, h = 8, bg = "white")

# Cases -------------------------------------------------------------------

cases <- read_csv("inputData_fourhundred.csv")

cases_firstWave <- cases %>% filter(date < as.Date("2020-06-01")) %>% group_by(LK_Name) %>% summarise(wave90percentile = quantile(Infection_Incidence, 0.9), wave_height = max(Infection_Incidence), corresponding_value = date[which.max(Infection_Incidence)])   
quantile(cases_firstWave$wave_height)
mean(cases_firstWave$wave_height)

germany_districts <- gisco_get_nuts(
  year = "2021", 
  nuts_level = 3,
  epsg = 3035,
  country = 'Germany',
  cache = TRUE,
  update_cache = TRUE
) %>%
  # Nicer output
  as_tibble() %>% 
  mutate(NAME_LATN = case_when(NAME_LATN == "München, Landkreis" ~ "Landkreis München",
                               NAME_LATN ==  "Karlsruhe, Landkreis" ~ "Landkreis Karlsruhe",
                               NAME_LATN == "Leipzig" ~ "Landkreis Leipzig",
                               NAME_LATN == "Oldenburg (Oldenburg), Kreisfreie Stadt" ~ "Oldenburg",
                               NAME_LATN == "Oldenburg" ~ "Landkreis Oldenburg",
                               NAME_LATN == "Osnabrück, Landkreis" ~ "Landkreis Osnabrück",
                               NAME_LATN ==  "Augsburg, Landkreis" ~ "Landkreis Augsburg",
                               NAME_LATN ==  "Landshut, Landkreis" ~ "Landkreis Landshut",
                               NAME_LATN ==  "Regensburg, Landkreis" ~ "Landkreis Regensburg",
                               NAME_LATN ==  "Würzburg, Landkreis" ~ "Landkreis Würzburg",
                               NAME_LATN ==  "Schweinfurt, Landkreis" ~ "Landkreis Schweinfurt",
                               NAME_LATN ==  "Friesland (DE)" ~ "Friesland",
                               NAME_LATN == "Rhein-Kreis Neuss" ~ "Rhein-Neuss",
                               NAME_LATN == "Lindau (Bodensee)" ~ "Lindau",
                               NAME_LATN == "Cottbus, Kreisfreie Stadt" ~ "Cottbus - Chóśebuz",
                               NAME_LATN == "Nienburg (Weser)" ~ "Nienburg/Weser",
                               NAME_LATN ==  "Passau, Landkreis" ~ "Landkreis Passau",
                               NAME_LATN ==  "Hof, Landkreis" ~ "Landkreis Hof",
                               NAME_LATN ==  "Heilbronn, Landkreis" ~ "Landkreis Heilbronn",
                               NAME_LATN ==  "Fürth, Landkreis" ~ "Landkreis Fürth",
                               NAME_LATN ==  "Coburg, Landkreis" ~ "Landkreis Coburg",
                               NAME_LATN ==  "Bayreuth, Landkreis" ~ "Landkreis Bayreuth",
                               NAME_LATN ==  "Bamberg, Landkreis" ~ "Landkreis Bamberg",
                               NAME_LATN ==  "Ansbach, Landkreis" ~ "Landkreis Ansbach",
                               NAME_LATN ==  "Region Hannover" ~ "Hannover",
                               NAME_LATN == "Pfaffenhofen a. d. Ilm" ~ "Pfaffenhofen an der Ilm",
                               NAME_LATN == "Dillingen a.d. Donau" ~ "Dillingen an der Donau",
                               NAME_LATN ==  "Aschaffenburg, Landkreis" ~ "Landkreis Aschaffenburg",
                               NAME_LATN == "Wunsiedel i. Fichtelgebirge" ~ "Wunsiedel im Fichtelgebirge",
                               NAME_LATN == "Neustadt a. d. Waldnaab" ~ "Neustadt an der Waldnaab",
                               NAME_LATN == "Mühldorf a. Inn" ~ "Mühldorf am Inn",
                               NAME_LATN == "Weiden i. d. Opf, Kreisfreie Stadt" ~ "Weiden in der Oberpfalz",
                               NAME_LATN == "Neumarkt i. d. OPf." ~ "Neumarkt in der Oberpfalz",
                               NAME_LATN == "Neustadt a. d. Aisch-Bad Windsheim" ~ "Neustadt an der Aisch-Bad Windsheim",
                               NAME_LATN == "Altenkirchen (Westerwald)" ~ "Altenkirchen",
                               .default = NAME_LATN)) %>%
  janitor::clean_names() %>% dplyr::rowwise() %>%
  mutate(name_latn = str_split(name_latn, ",")[[1]][1]) %>%
  left_join(cases_firstWave, by = join_by(name_latn == LK_Name))
germany_districts$wave_height[germany_districts$name_latn == "Eisenach"] <- germany_districts$wave_height[germany_districts$name_latn == "Wartburgkreis"]
#pdf("Map_CasesFirstWave.pdf", width = 6, height = 9)
densityplot_left <-  germany_districts %>% mutate(wave90percentile = case_when(wave90percentile < 10 ~10, .default = wave90percentile)) %>%
  ggplot(aes(geometry = geometry)) +
  geom_sf(aes(fill = wave90percentile)) +
  scale_y_log10() +
  #ylim(1, 3) +
  theme_minimal() +
  xlab("") +
  ylab("") +
  #scale_fill_continuous(trans = "log", palette = "devon") + 
  scico::scale_fill_scico(palette = "devon", trans = "log10", limits = c(10, 1000), direction = -1) +
  geom_sf_interactive(
    fill = NA, 
    aes(
      data_id = nuts_id,
      tooltip = glue::glue('{nuts_name}')
    ),
    linewidth = 0.1
  ) +
  theme(legend.position = "bottom", text = element_text(size = 20), axis.text = element_blank(), axis.ticks = element_blank()) +
  guides(fill = guide_colourbar(
    title = "Peak incidence"
  )) +
  ggtitle("First wave") +
  coord_sf(expand = FALSE)

cases_secondWave <- cases %>% filter(date > as.Date("2020-09-01")) %>% group_by(LK_Name) %>% summarise(wave90percentile = quantile(Infection_Incidence, 0.9), wave_height = max(Infection_Incidence), corresponding_value = date[which.max(Infection_Incidence)]) 
quantile(cases_secondWave$wave_height)
mean(cases_secondWave$wave_height)

germany_districts <- gisco_get_nuts(
  year = "2021", 
  nuts_level = 3,
  epsg = 3035,
  country = 'Germany',
  cache = TRUE,
  update_cache = TRUE
) %>%
  # Nicer output
  as_tibble() %>% 
  mutate(NAME_LATN = case_when(NAME_LATN == "München, Landkreis" ~ "Landkreis München",
                               NAME_LATN ==  "Karlsruhe, Landkreis" ~ "Landkreis Karlsruhe",
                               NAME_LATN == "Leipzig" ~ "Landkreis Leipzig",
                               NAME_LATN == "Oldenburg (Oldenburg), Kreisfreie Stadt" ~ "Oldenburg",
                               NAME_LATN == "Oldenburg" ~ "Landkreis Oldenburg",
                               NAME_LATN == "Osnabrück, Landkreis" ~ "Landkreis Osnabrück",
                               NAME_LATN ==  "Augsburg, Landkreis" ~ "Landkreis Augsburg",
                               NAME_LATN ==  "Landshut, Landkreis" ~ "Landkreis Landshut",
                               NAME_LATN ==  "Regensburg, Landkreis" ~ "Landkreis Regensburg",
                               NAME_LATN ==  "Würzburg, Landkreis" ~ "Landkreis Würzburg",
                               NAME_LATN ==  "Schweinfurt, Landkreis" ~ "Landkreis Schweinfurt",
                               NAME_LATN ==  "Friesland (DE)" ~ "Friesland",
                               NAME_LATN == "Rhein-Kreis Neuss" ~ "Rhein-Neuss",
                               NAME_LATN == "Lindau (Bodensee)" ~ "Lindau",
                               NAME_LATN == "Cottbus, Kreisfreie Stadt" ~ "Cottbus - Chóśebuz",
                               NAME_LATN == "Nienburg (Weser)" ~ "Nienburg/Weser",
                               NAME_LATN ==  "Passau, Landkreis" ~ "Landkreis Passau",
                               NAME_LATN ==  "Hof, Landkreis" ~ "Landkreis Hof",
                               NAME_LATN ==  "Heilbronn, Landkreis" ~ "Landkreis Heilbronn",
                               NAME_LATN ==  "Fürth, Landkreis" ~ "Landkreis Fürth",
                               NAME_LATN ==  "Coburg, Landkreis" ~ "Landkreis Coburg",
                               NAME_LATN ==  "Bayreuth, Landkreis" ~ "Landkreis Bayreuth",
                               NAME_LATN ==  "Bamberg, Landkreis" ~ "Landkreis Bamberg",
                               NAME_LATN ==  "Ansbach, Landkreis" ~ "Landkreis Ansbach",
                               NAME_LATN ==  "Region Hannover" ~ "Hannover",
                               NAME_LATN == "Pfaffenhofen a. d. Ilm" ~ "Pfaffenhofen an der Ilm",
                               NAME_LATN == "Dillingen a.d. Donau" ~ "Dillingen an der Donau",
                               NAME_LATN ==  "Aschaffenburg, Landkreis" ~ "Landkreis Aschaffenburg",
                               NAME_LATN == "Wunsiedel i. Fichtelgebirge" ~ "Wunsiedel im Fichtelgebirge",
                               NAME_LATN == "Neustadt a. d. Waldnaab" ~ "Neustadt an der Waldnaab",
                               NAME_LATN == "Mühldorf a. Inn" ~ "Mühldorf am Inn",
                               NAME_LATN == "Weiden i. d. Opf, Kreisfreie Stadt" ~ "Weiden in der Oberpfalz",
                               NAME_LATN == "Neumarkt i. d. OPf." ~ "Neumarkt in der Oberpfalz",
                               NAME_LATN == "Neustadt a. d. Aisch-Bad Windsheim" ~ "Neustadt an der Aisch-Bad Windsheim",
                               NAME_LATN == "Altenkirchen (Westerwald)" ~ "Altenkirchen",
                               .default = NAME_LATN)) %>%
  janitor::clean_names() %>% dplyr::rowwise() %>%
  mutate(name_latn = str_split(name_latn, ",")[[1]][1]) %>%
  left_join(cases_secondWave, by = join_by(name_latn == LK_Name))
germany_districts$wave_height[germany_districts$name_latn == "Eisenach"] <- germany_districts$wave_height[germany_districts$name_latn == "Wartburgkreis"]
#pdf("Map_CasesSecondWave.pdf", width = 6, height = 9)
densityplot_right <-  germany_districts %>%
  ggplot(aes(geometry = geometry)) +
  geom_sf(aes(fill = wave90percentile)) +
  theme_minimal() +
  xlab("") +
  ylab("") +
  scico::scale_fill_scico(palette = "devon", trans = "log10", limits = c(10, 1000), direction = -1) +
  geom_sf_interactive(
    fill = NA, 
    aes(
      data_id = nuts_id,
      tooltip = glue::glue('{nuts_name}')
    ),
    linewidth = 0.1
  ) +
  theme(legend.position = "bottom", text = element_text(size = 20), axis.text = element_blank(), axis.ticks = element_blank()) +
  guides(fill = guide_colourbar(
    title = "Peak incidence"
  )) +
  ggtitle("Second wave") +
  coord_sf(expand = FALSE)

ggarrange(densityplot_left, densityplot_right, ncol = 2, labels = c("A", "B"), font.label = list(size = 30))
ggsave("MapPlotsCases_FirstandSecondWave.pdf", dpi = 500, h = 8, w = 16) 
ggsave("MapPlotsCases_FirstandSecondWave.png", dpi = 500, h = 8, w = 16) 


cases <- cases %>% group_by(date) %>% summarise(lowerperc = quantile(Infection_Incidence, 0.025), 
                                                upperperc = quantile(Infection_Incidence, 0.975), 
                                                Infection_Incidence = mean(Infection_Incidence))

casesA <- ggplot(cases %>% filter(date < "2021-03-01") %>% filter(date > "2020-03-01"), aes(x=date, y=Infection_Incidence)) +
  geom_ribbon(aes(ymin = lowerperc, ymax = upperperc), fill = "#5254a3", alpha = 0.3) + 
  geom_line(colour="#5254a3", size = 3) +
  theme_minimal() +
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
    axis.text = element_text(color = "black", size = 42),  # Axis labels
    axis.title = element_text(color = "black", size = 47),
    axis.title.x = element_text(margin = margin(t = 10)),  # top margin for x-axis title
    axis.title.y = element_text(margin = margin(r = 10)),
    legend.position = "none"
  ) +
  scale_x_date(breaks = seq(as.Date("2020-04-01"), as.Date("2021-02-01"), by = "3 month"), date_labels = "%d/%b/%y", expand = c(0, 0)) +
  xlab("Date") +
  ylab("Incidence") 



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

ggsave("InputCases2020.pdf", casesA, dpi = 500, w = 18, h = 8)
ggsave("InputCases2020.png", casesA, dpi = 500, w = 18, h = 8)

