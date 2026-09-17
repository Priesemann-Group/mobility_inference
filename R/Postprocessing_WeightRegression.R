library(corrplot)
library(tidyverse)
library(readxl)
library(here)

here()

# Regression Analysis -----------------------------------------------------

#Data Preprocessing -------------------------------------------------------

model <- "fourhundred"

consideredWave <- "firstwave"

#run <- "2025-06-17_1000halfnormal_secondzscale"
run <- "2025-07-02_400LK_exp_UsedForPostprocessing"

outcomeVariable <- "shareLocalIncidence"

source("Postprocessing_Clean.R")

disFac_post <- postprocessing_clean(model, consideredWave, run, outcomeVariable)

#valuetoplot$group <- factor(valuetoplot$group, levels = c("Grosse Grossstadt", "Kleine Grossstadt", "Städtische Kreise", "Ländlicher Kreis mit Verdichtungsansätzen", "Dünn besiedelt ländlicher Kreis"))
disFac_post$group_eng <- factor(disFac_post$group_eng, levels = c("Large City", "Small City", "Town", "Medium Rural", "Rural"))

my_comparisons <- list(c("Grosse Grossstadt", "Kleine Grossstadt"),
                       c("Kleine Grossstadt", "Städtische Kreise"),
                       c("Städtische Kreise", "Ländlicher Kreis mit Verdichtungsansätzen"),
                       c("Ländlicher Kreis mit Verdichtungsansätzen", "Dünn besiedelt ländlicher Kreis"))
my_comparisons <- list(c("Large City", "Small City"),
                       c("Small City", "Town"),
                       c("Town", "Medium Rural"),
                       c("Medium Rural", "Rural"))
symnum.args <- list(cutpoints = c(0, 0.0001, 0.001, 0.01, 0.05, Inf), symbols = c("****", "***", "**", "*", "ns"))

manual_scale <- c("#D4B2CC", "#D385AC",  "#A56693", "#66507A", "#2D204C")

boxplot <- ggplot(disFac_post %>% filter(!is.na(group_eng)) %>% filter(!is.na(value)), aes(x= group_eng, y=value)) +
  geom_boxplot(aes(color = group_eng), lwd=1.5)+
  stat_compare_means(comparisons = my_comparisons, symnum.args = symnum.args, method = "t.test", size = 5) +
  theme_minimal() +
  guides(color=guide_legend(nrow=5,byrow=TRUE)) +
  theme(legend.position = "bottom") +
  ylab("Weight of Local Incidence") +
  scale_color_manual(values= manual_scale) +
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.text.y=element_text(size = 17),
        axis.title.y=element_text(size = 20),
        legend.title = element_blank(),
        legend.text = element_text(size = 15),
        #axis.ticks.x = element_line(),
        axis.ticks.y = element_line(),
        axis.ticks.length = unit(10, "pt"), 
        axis.line = element_line())

ggsave(paste0("FirstAnalysisCountyTyp-", outcomeVariable, "-", run, ".pdf"), boxplot, dpi = 500, w = 7, h = 7)
ggsave(paste0("FirstAnalysisCountyTyp-", outcomeVariable, "-", run, ".png"), boxplot, dpi = 500, w = 7, h = 7)

# Spatial Plot ------------------------------------------------------------

if(model == "fedStates"){
  germany_districts <- gisco_get_nuts(
    year = "2021", 
    nuts_level = 1,
    epsg = 3035,
    country = 'Germany'
  ) %>% # Nicer output
    as_tibble() %>% 
    janitor::clean_names() %>% dplyr::rowwise() %>%
    mutate(name_latn = str_split(name_latn, ",")[[1]][1]) %>%
    left_join(min_first_wave, by = join_by(name_latn == LK_Name)) %>%
    mutate(diseaseFactor = case_when(nuts_name == "Leipzig" ~ NA, .default = diseaseFactor))
}else if(model %in% c("counties", "fourhundred")){
  germany_districts <- gisco_get_nuts(
    year = "2021", 
    nuts_level = 3,
    epsg = 3035,
    country = 'Germany',
    cache = TRUE,
    update_cache = TRUE
  ) %>%
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
                                 NAME_LATN ==  "Passau, Landkreis" ~ "Landkreis Passau",
                                 NAME_LATN ==  "Hof, Landkreis" ~ "Landkreis Hof",
                                 NAME_LATN ==  "Heilbronn, Landkreis" ~ "Landkreis Heilbronn",
                                 NAME_LATN ==  "Fürth, Landkreis" ~ "Landkreis Fürth",
                                 NAME_LATN ==  "Coburg, Landkreis" ~ "Landkreis Coburg",
                                 NAME_LATN ==  "Bayreuth, Landkreis" ~ "Landkreis Bayreuth",
                                 NAME_LATN ==  "Bamberg, Landkreis" ~ "Landkreis Bamberg",
                                 NAME_LATN ==  "Ansbach, Landkreis" ~ "Landkreis Ansbach",
                                 NAME_LATN ==  "Region Hannover" ~ "Hannover",
                                 NAME_LATN == "Dillingen a.d. Donau" ~ "Dillingen an der Donau",
                                 NAME_LATN ==  "Aschaffenburg, Landkreis" ~ "Landkreis Aschaffenburg",
                                 NAME_LATN == "Wunsiedel i. Fichtelgebirge" ~ "Wunsiedel im Fichtelgebirge",
                                 NAME_LATN == "Neustadt a. d. Waldnaab" ~ "Neustadt an der Waldnaab",
                                 NAME_LATN == "Mühldorf a. Inn" ~ "Mühldorf am Inn",
                                 NAME_LATN == "Weiden i. d. Opf, Kreisfreie Stadt" ~ "Weiden in der Oberpfalz",
                                 NAME_LATN == "Neumarkt i. d. OPf." ~ "Neumarkt in der Oberpfalz",
                                 NAME_LATN == "Neustadt a. d. Aisch-Bad Windsheim" ~ "Neustadt an der Aisch-Bad Windsheim",
                                 NAME_LATN == "Altenkirchen (Westerwald)" ~ "Altenkirchen",
                                 NAME_LATN == "Nienburg (Weser)" ~ "Nienburg/Weser",
                                 NAME_LATN == "Rhein-Kreis Neuss" ~ "Rhein-Neuss",
                                 NAME_LATN == "Cottbus, Kreisfreie Stadt" ~ "Cottbus - Chóśebuz",
                                 NAME_LATN == "Pfaffenhofen a. d. Ilm" ~ "Pfaffenhofen an der Ilm",
                                 NAME_LATN == "Lindau (Bodensee)" ~ "Lindau",
                                 NAME_LATN == "Friesland (DE)" ~ "Friesland",
                                 NAME_LATN == "Eisenach, Kreisfreie Stadt" ~ "Wartburgkreis",
                                 .default = NAME_LATN)) %>%
    #janitor::clean_names() %>%
    dplyr::rowwise() %>%
    mutate(NAME_LATN = str_split(NAME_LATN, ",")[[1]][1]) %>%
    left_join(disFac_post, by = join_by(NAME_LATN == LK_Name))
}


title <- "Weight of\nLocal Incidence"

germany_districts <- germany_districts %>% mutate(isna = case_when(is.na(value) ~ "NA", .default = "no"))

plot <- germany_districts %>% 
  ggplot(aes(geometry = geometry)) +
  geom_sf(aes(fill=value))+
  #ggpattern::geom_sf_pattern(aes(fill = value, pattern = isna, alpha = is.na(value)),
  #                 pattern_angle = 45,
  #                 pattern_density = 0.1,
  #                 pattern_spacing = 0.01,
  #                 pattern_key_scale_factor = 0.4, pattern_colour = "808080") +
  scico::scale_fill_scico(palette = "acton") +
  #scale_alpha_manual(values = c("TRUE" = 0, "FALSE" = 1), guide = NULL) +
  #geom_sf(fill = "white") +
  theme_minimal() +
  xlab("") +
  ylab("") +
  ggpattern::scale_pattern_manual(
    values = c(
      "NA" = 'stripe',
      "no" = 'none'
    )
  ) +
  geom_sf_interactive(
    fill = NA,
    aes(
      data_id = NUTS_ID,
      tooltip = glue::glue('{NUTS_NAME}')
    ),
    linewidth = 0.1
  ) +
  theme(text = element_text(size = 20), axis.text = element_blank(), axis.ticks = element_blank(), legend.position = "bottom") +
  guides(fill = guide_colourbar(
    title = title
  )) +
  coord_sf(expand = FALSE)

sharedplot <- ggarrange(boxplot, plot, labels = c("A", "B"), nrow = 1, ncol = 2,font.label = list(size = 30), heights = c(1,1), legend="bottom")

ggsave(paste0("SpatialAnalysis-", outcomeVariable, "-", run, ".pdf"), sharedplot, dpi = 500, h = 7, w = 15)
ggsave(paste0("SpatialAnalysis-", outcomeVariable, "-", run, ".png"), sharedplot, dpi = 500, h = 7, w = 15)


mean(disFac_post$value)
quantile(disFac_post$value)

# Population density 
# Data from https://www.destatis.de/DE/Themen/Laender-Regionen/Regionales/Gemeindeverzeichnis/Administrativ/04-kreise.html
popDensity <- read_xlsx("/Users/sydney/Downloads/04-kreise.xlsx", sheet = 2, skip = 4)
colnames(popDensity) <- c("LKNumber", "LKType", "LK_Name", "SomeNumber", "SomeOtherNumber", "Inhabitants", "InhabitantsMale", "InhabitantsFemale", "Inhabitantsperkm2")
popDensity <- popDensity %>% mutate(LK_Name = case_when((LK_Name == "Augsburg" & LKType == "Landkreis") ~ "Landkreis Augsburg",
                                                        (LK_Name == "Leipzig" & LKType == "Landkreis") ~ "Landkreis Leipzig",
                                                        (LK_Name == "Schweinfurt" & LKType == "Landkreis") ~ "Landkreis Schweinfurt",
                                                        (LK_Name == "Würzburg" & LKType == "Landkreis") ~ "Landkreis Würzburg",
                                                        (LK_Name == "Ansbach" & LKType == "Landkreis") ~ "Landkreis Ansbach",
                                                        (LK_Name =="Aschaffenburg" & LKType == "Landkreis") ~ "Landkreis Aschaffenburg",
                                                        (LK_Name == "Bamberg" & LKType == "Landkreis") ~ "Landkreis Bamberg", 
                                                        (LK_Name == "Bayreuth" & LKType == "Landkreis") ~ "Landkreis Bayreuth",
                                                        (LK_Name == "Kassel" & LKType == "Landkreis") ~ "Landkreis Kassel",
                                                        (LK_Name == "Rosenheim" & LKType == "Landkreis") ~ "Landkreis Rosenheim",
                                                        LK_Name == "Mühldorf a.Inn" ~ "Mühldorf am Inn",
                                                        LK_Name =="Oldenburg (Oldenburg), Stadt" ~ "Oldenburg",
                                                        (LK_Name == "Coburg" & LKType == "Landkreis") ~ "Landkreis Coburg",
                                                        (LK_Name == "Fürth" & LKType == "Landkreis") ~ "Landkreis Fürth",
                                                        (LK_Name == "Heilbronn" & LKType == "Landkreis") ~ "Landkreis Heilbronn",
                                                        (LK_Name == "Hof" & LKType == "Landkreis") ~ "Landkreis Hof",
                                                        (LK_Name == "Karlsruhe" & LKType == "Landkreis") ~ "Landkreis Karlsruhe",
                                                        (LK_Name == "Landshut" & LKType == "Landkreis") ~ "Landkreis Landshut",
                                                        (LK_Name == "München" & LKType == "Landkreis") ~ "Landkreis München",
                                                        (LK_Name == "Oldenburg" & LKType == "Landkreis") ~ "Landkreis Oldenburg",
                                                        (LK_Name == "Osnabrück" & LKType == "Landkreis") ~ "Landkreis Osnabrück",
                                                        (LK_Name == "Passau" & LKType == "Landkreis") ~ "Landkreis Passau",
                                                        (LK_Name == "Regensburg" & LKType == "Landkreis") ~ "Landkreis Regensburg",
                                                        LK_Name == "Altenkirchen (Westerwald)" ~ "Altenkirchen",
                                                        LK_Name == "Kassel, documenta-Stadt" ~ "Kassel",
                                                        LK_Name == "Neumarkt i.d.OPf." ~ "Neumarkt in der Oberpfalz",
                                                        LK_Name == "Neustadt a.d.Aisch-Bad Windsheim" ~ "Neustadt an der Aisch-Bad Windsheim",
                                                        LK_Name ==  "Neustadt a.d.Waldnaab" ~ "Neustadt an der Waldnaab",
                                                        LK_Name == "Weiden i.d.OPf." ~ "Weiden in der Oberpfalz",
                                                        LK_Name == "Wunsiedel i.Fichtelgebirge" ~ "Wunsiedel im Fichtelgebirge",
                                                        LK_Name == "Dillingen a.d.Donau" ~ "Dillingen an der Donau",
                                                        LK_Name == "Saarbrücken, Regionalverband" ~ "Regionalverband Saarbrücken",
                                                        LK_Name == "Rhein-Kreis Neuss" ~ "Rhein-Neuss",
                                                        LK_Name =="Nienburg (Weser)" ~ "Nienburg/Weser",
                                                        LK_Name == "Pirmasens, kreisfreie Stadt" ~ "Pirmasens",
                                                        LK_Name == "Region Hannover" ~ "Hannover",
                                                        LK_Name == "Kaiserslautern" ~ "Landkreis Kaiserslautern",
                                                        LK_Name == "Neumarkt i.d.OPf." ~ "Neumarkt in der Oberpfalz", 
                                                        LK_Name == "Cottbus, Stadt" ~ "Cottbus - Chóśebuz",
                                                        LK_Name == "Darmstadt, Wissenschaftsstadt" ~ "Darmstadt",
                                                        LK_Name == "Hagen, Stadt der FernUniversität" ~ "Hagen",
                                                        LK_Name == "Lindau (Bodensee)" ~ "Lindau",
                                                        LK_Name == 	"Pfaffenhofen a.d.Ilm" ~ "Pfaffenhofen an der Ilm",
                                                        LK_Name == "Solingen, Klingenstadt" ~ "Solingen",
                                                        .default = LK_Name))
popDensity$LK_Name <- str_replace(popDensity$LK_Name, ", Kreis$", "")
popDensity$LK_Name <- str_replace(popDensity$LK_Name, ", Stadt$", "")
popDensity$LK_Name <- str_replace(popDensity$LK_Name, ", Freie und Hansestadt$", "")
popDensity$LK_Name <- str_replace(popDensity$LK_Name, ", kreisfreie Stadt$", "")
popDensity$LK_Name <- str_replace(popDensity$LK_Name, ", Landeshauptstadt$", "")
popDensity$LK_Name <- str_replace(popDensity$LK_Name, ", Stadtkreis$", "")
popDensity$LK_Name <- str_replace(popDensity$LK_Name, ", Hansestadt$", "")

disFac_post <- left_join(disFac_post, popDensity)

# Income ------------------------------------------------------------------

# Data from
#https://www.statistikportal.de/de/vgrdl/ergebnisse-kreisebene/einkommen-kreise

incomeDf <- read_xlsx("/Users/sydney/Downloads/vgrdl_r2b3_bs2023.xlsx", sheet=13, skip = 4)
incomeDf <- incomeDf %>% dplyr::select(Land, Gebietseinheit, `2022`)
colnames(incomeDf) <- c("fedStateshort", "LK_Name", "IncomePerson2022")
incomeDf <- incomeDf %>% filter(LK_Name != "Bremen")
incomeDf <- incomeDf %>% mutate(LK_Name = case_when(
  LK_Name == "München, Landkreis" ~ "Landkreis München",
  LK_Name ==  "Karlsruhe, Landkreis" ~ "Landkreis Karlsruhe",
  LK_Name == "Leipzig, Landkreis" ~ "Landkreis Leipzig",
  LK_Name == "Oldenburg (Oldenburg), Kreisfreie Stadt" ~ "Oldenburg",
  LK_Name == "Oldenburg, Landkreis" ~ "Landkreis Oldenburg",
  LK_Name == "Osnabrück, Landkreis" ~ "Landkreis Osnabrück",
  LK_Name ==  "Augsburg, Landkreis" ~ "Landkreis Augsburg",
  LK_Name ==  "Landshut, Landkreis" ~ "Landkreis Landshut",
  LK_Name ==  "Rosenheim, Landkreis" ~ "Landkreis Rosenheim",
  LK_Name ==  "Regensburg, Landkreis" ~ "Landkreis Regensburg",
  LK_Name ==  "Kaiserslautern, Landkreis" ~ "Landkreis Kaiserslautern",
  LK_Name ==  "Würzburg, Landkreis" ~ "Landkreis Würzburg",
  LK_Name ==  "Aschaffenburg, Landkreis" ~ "Landkreis Aschaffenburg",
  LK_Name ==  "Schweinfurt, Landkreis" ~ "Landkreis Schweinfurt",
  LK_Name ==  "Passau, Landkreis" ~ "Landkreis Passau",
  LK_Name ==  "Hof, Landkreis" ~ "Landkreis Hof",
  LK_Name ==  "Heilbronn, Landkreis" ~ "Landkreis Heilbronn",
  LK_Name ==  "Fürth, Landkreis" ~ "Landkreis Fürth",
  LK_Name ==  "Coburg, Landkreis" ~ "Landkreis Coburg",
  LK_Name ==  "Bayreuth, Landkreis" ~ "Landkreis Bayreuth",
  LK_Name ==  "Bamberg, Landkreis" ~ "Landkreis Bamberg",
  LK_Name ==  "Ansbach, Landkreis" ~ "Landkreis Ansbach",
  LK_Name ==  "Region Hannover, Landkreis" ~ "Hannover",
  LK_Name == 	"Nienburg (Weser), Landkreis" ~ "Nienburg/Weser",
  LK_Name == "Rhein-Kreis Neuss, Kreis" ~ "Rhein-Neuss",
  LK_Name == "Kassel, Landkreis" ~ "Landkreis Kassel",
  LK_Name == "Kassel, documenta-Stadt, Kreisfreie Stadt" ~ "Kassel",
  LK_Name == "Altenkirchen (Westerwald), Landkreis" ~ "Altenkirchen",
  LK_Name == "Mühldorf a.Inn, Landkreis" ~ "Mühldorf am Inn",
  LK_Name == "Neumarkt i.d.OPf., Landkreis" ~ "Neumarkt in der Oberpfalz",
  LK_Name == "Neustadt a.d.Aisch-Bad Windsheim, Landkreis" ~ "Neustadt an der Aisch-Bad Windsheim",
  LK_Name ==  "Neustadt a.d.Waldnaab, Landkreis"~"Neustadt an der Waldnaab",
  LK_Name == "Waldshut, Landkreis" ~ "Waldshut",
  LK_Name == "Weiden i.d.OPf., Kreisfreie Stadt" ~ "Weiden in der Oberpfalz",
  LK_Name == "Wunsiedel i.Fichtelgebirge, Landkreis" ~ "Wunsiedel im Fichtelgebirge",
  LK_Name == "Dillingen a.d.Donau, Landkreis" ~ "Dillingen an der Donau",
  LK_Name == "Saarbrücken, Regionalverband" ~ "Regionalverband Saarbrücken",
  LK_Name == "Cottbus, Kreisfreie Stadt" ~ "Cottbus - Chóśebuz",
  LK_Name == "Darmstadt, Wissenschaftsstadt, Kreisfreie Stadt" ~ "Darmstadt",
  LK_Name == "Hagen, Stadt der FernUniversität" ~ "Hagen",
  LK_Name == "Lindau (Bodensee), Landkreis" ~ "Lindau",
  LK_Name == 	"Pfaffenhofen a.d.Ilm, Landkreis" ~ "Pfaffenhofen an der Ilm",
  LK_Name == "Solingen, Kreisfreie Stadt" ~ "Solingen",
  .default = LK_Name
))
incomeDf$LK_Name <- str_replace(incomeDf$LK_Name, ", Landkreis$", "")
#incomeDf$LK_Name <- str_replace(LKType$LK_Name, ", Regierungsbezirk$", "")
incomeDf$LK_Name <- str_replace(incomeDf$LK_Name, ", Stadtkreis$", "")
incomeDf$LK_Name <- str_replace(incomeDf$LK_Name, ", Kreisfreie Stadt$", "")
incomeDf$LK_Name <- str_replace(incomeDf$LK_Name, ", Kreis$", "")
incomeDf$LK_Name <- str_replace(incomeDf$LK_Name, ", Landeshauptstadt$", "")

incomeDf$LK_Name <- str_replace(incomeDf$LK_Name, ", Universitätsstadt$", "")
incomeDf$LK_Name <- str_replace(incomeDf$LK_Name, ", Hansestadt, Kreisfreie Stadt$", "")
incomeDf$LK_Name <- str_replace(incomeDf$LK_Name, ", Wissenschaftsstadt, Kreisfreie Stadt", "")
incomeDf$LK_Name <- str_replace(incomeDf$LK_Name, ", Hansestadt$", "")

# incomeDf <- incomeDf %>% mutate(discreteIncome = case_when(IncomePerson2022 < 25000 ~ "<25,000",
#                                                            IncomePerson2022 < 30000 ~ "25,000-30,000",
#                                                            IncomePerson2022 < 35000 ~ "30,000-35,000",
#                                                            IncomePerson2022 > 35000 ~ ">35,000"))

disFac_post <- left_join(disFac_post, incomeDf, by = c("LK_Name"))

# Voter turnout, unemploydisFac_post# Voter turnout, unemployment, elderly ------------------------------------

# Data from https://www.deutschlandatlas.bund.de/DE/Service/Downloads/downloads_node.html
voterturnout <- read_xlsx("/Users/sydney/Downloads/Deutschlandatlas-Daten.xlsx", sheet = 4)
voterturnout <- voterturnout %>% mutate(Kreisname = case_when(
  KRS1221 == "9671000" ~ "Landkreis Aschaffenburg",
  KRS1221 == "9472000" ~ "Landkreis Bayreuth",
  KRS1221 == "9679000" ~ "Landkreis Würzburg",
  KRS1221 == "9571000" ~ "Landkreis Ansbach",
  KRS1221 == "9471000" ~ "Landkreis Bamberg",
  KRS1221 == "9473000" ~ "Landkreis Coburg",
  KRS1221 == "9573000" ~ "Landkreis Fürth",
  KRS1221 == "9475000" ~ "Landkreis Hof",
  KRS1221 == "9274000" ~ "Landkreis Landshut",
  KRS1221 == "9275000" ~ "Landkreis Passau",
  KRS1221 == "9375000" ~ "Landkreis Regensburg",
  KRS1221 == "9772000" ~ "Landkreis Augsburg",
  KRS1221 == "9678000" ~ "Landkreis Schweinfurt",
  KRS1221 == "9187000" ~ "Landkreis Rosenheim",
  Kreisname == "Region Hannover" ~ "Hannover",
  Kreisname == "Mühldorf a.Inn" ~ "Mühldorf am Inn",
  Kreisname == "Kassel" ~ "Landkreis Kassel",
  Kreisname == "Kassel, documenta-Stadt" ~ "Kassel",
  Kreisname == "Kaiserslautern" ~ "Landkreis Kaiserslautern",
  Kreisname == "Neumarkt i.d.OPf." ~ "Neumarkt in der Oberpfalz",
  Kreisname == "Neustadt a.d.Aisch-Bad Windsheim" ~ "Neustadt an der Aisch-Bad Windsheim",
  Kreisname == "Neustadt a.d.Waldnaab" ~ "Neustadt an der Waldnaab",
  Kreisname == "Weiden i.d.OPf." ~ "Weiden in der Oberpfalz", 
  Kreisname == "Wunsiedel i.Fichtelgebirge" ~ "Wunsiedel im Fichtelgebirge",
  Kreisname == "Dillingen a.d.Donau" ~ "Dillingen an der Donau",
  Kreisname == "München" ~ "Landkreis München",
  Kreisname == "Leipzig" ~ "Landkreis Leipzig",
  Kreisname == "Oldenburg" ~ "Landkreis Oldenburg",
  Kreisname == "Oldenburg (Oldenburg), Stadt" ~ "Oldenburg",
  Kreisname == "Osnabrück" ~ "Landkreis Osnabrück",
  Kreisname == "Nienburg (Weser)" ~ "Nienburg/Weser",
  Kreisname == "Rhein-Kreis Neuss" ~ "Rhein-Neuss",
  Kreisname == "Altenkirchen (Westerwald)" ~ "Altenkirchen",
  Kreisname == "Heilbronn" ~ "Landkreis Heilbronn",
  Kreisname == "Karlsruhe" ~ "Landkreis Karlsruhe",
  Kreisname == "Cottbus, Stadt" ~ "Cottbus - Chóśebuz",
  Kreisname == "Darmstadt, Wissenschaftsstadt" ~ "Darmstadt",
  Kreisname == "Hagen, Stadt der FernUniversität" ~ "Hagen",
  Kreisname == "Lindau (Bodensee)" ~ "Lindau",
  Kreisname == 	"Pfaffenhofen a.d.Ilm" ~ "Pfaffenhofen an der Ilm",
  Kreisname == "Solingen, Klingenstadt" ~ "Solingen",
  .default = Kreisname
))
voterturnout <- voterturnout %>% dplyr::select(c(Kreisname, wahl_beteil, alq, bev_ue65, kbetr_u3))
colnames(voterturnout) <- c("LK_Name", "voterTurnout", "unemploymentQuota", "peopleover65", "childrenbelow3inprimarycare")
# voterturnout <- voterturnout %>% mutate(voterTurnoutDiscrete = case_when(voterTurnout < 65 ~ "[0%,65%)",
#                                                                          voterTurnout < 70 ~ "[65%,70%)",
#                                                                          voterTurnout < 75 ~ "[70%,75%)",
#                                                                          voterTurnout < 80 ~ "[75%,80%)",
#                                                                          voterTurnout < 85 ~ "[80%,85%)",
#                                                                          .default = "[85%,100%]"))
# voterturnout <- voterturnout %>% mutate(unemploymentQuotaDiscrete = case_when(unemploymentQuota < 3 ~ "[0%,3%)",
#                                                                               unemploymentQuota < 6 ~ "[3%,6%)",
#                                                                               unemploymentQuota < 9 ~ "[6%,9%)",
#                                                                               unemploymentQuota < 100 ~ "[9%,100%)"))
voterturnout$LK_Name <- str_replace(voterturnout$LK_Name, ", Kreis$", "")
voterturnout$LK_Name <- str_replace(voterturnout$LK_Name, ", Stadt$", "")
voterturnout$LK_Name <- str_replace(voterturnout$LK_Name, ", Freie und Hansestadt$", "")
voterturnout$LK_Name <- str_replace(voterturnout$LK_Name, ", kreisfreie Stadt$", "")
voterturnout$LK_Name <- str_replace(voterturnout$LK_Name, ", Landeshauptstadt$", "")
voterturnout$LK_Name <- str_replace(voterturnout$LK_Name, ", Stadtkreis$", "")
voterturnout$LK_Name <- str_replace(voterturnout$LK_Name, ", Hansestadt$", "")
disFac_post <- left_join(disFac_post, voterturnout)

# Voted parting government, voted incoming government, average age, employment rate

#Data from: regionalatlas.statistikportal.de
ZweitstimmeCdu <- read_delim("/Users/sydney/Downloads/ZweitstimmeCDU.csv", skip=2)
colnames(ZweitstimmeCdu)[3] <- "CDU"
ZweitstimmeSpd <- read_delim("/Users/sydney/Downloads/ZweitstimmeSPD.csv", skip=2)
colnames(ZweitstimmeSpd)[3] <- "SPD"
ZweitstimmeFdp <- read_delim("/Users/sydney/Downloads/ZweitstimmeFDP.csv", skip=2)
colnames(ZweitstimmeFdp)[3] <- "FDP"
ZweitstimmeGruen <- read_delim("/Users/sydney/Downloads/ZweitstimmeGruene.csv", skip=9)
colnames(ZweitstimmeGruen)[3] <- "GRUENE"
ZweitstimmeAfd <- read_delim("/Users/sydney/Downloads/ZweitstimmeAfd.csv", skip=2)
colnames(ZweitstimmeAfd)[3] <- "Afd"

Zweitstimme <- left_join(ZweitstimmeCdu, ZweitstimmeSpd)
Zweitstimme <- left_join(Zweitstimme, ZweitstimmeFdp)
Zweitstimme <- left_join(Zweitstimme, ZweitstimmeGruen)
Zweitstimme <- left_join(Zweitstimme, ZweitstimmeAfd)
Zweitstimme <- Zweitstimme %>% mutate(`Voted for Parting Government` = CDU + SPD) %>%
  mutate(`Voted for Incoming Government` = SPD + FDP + GRUENE)

AverageAge  <- read_delim("/Users/sydney/Downloads/AverageAge.csv", skip=2)
colnames(AverageAge)[3] <- "Average Age"
AverageAge <- AverageAge  %>% mutate(regionaleinheit = case_when(
  regionaleinheit == "Mühldorf a.Inn" ~ "Mühldorf a. Inn",
  regionaleinheit == "Pfaffenhofen a.d.Ilm" ~ "Pfaffenhofen a.d. Ilm",
  regionaleinheit == "Weiden i.d.OPf." ~ "Weiden i.d. OPf.",
  regionaleinheit == "Neumarkt i.d.OPf." ~ "Neumarkt i.d. OPf.",
  regionaleinheit == "Neustadt a.d.Waldnaab" ~ "Neustadt a.d. Waldnaab",
  regionaleinheit == "Wunsiedel i.Fichtelgebirge" ~ "Wunsiedel i. Fichtelgebirge",
  regionaleinheit == "Neustadt a.d.Aisch-Bad Windsheim" ~ "Neustadt a.d. Aisch-Bad Windsheim",
  regionaleinheit == "Dillingen a.d.Donau" ~ "Dillingen a.d. Donau",
  .default = regionaleinheit))

BeschaeftigtenQuote <- read_delim("/Users/sydney/Downloads/Beschaeftigtenquote.csv", skip=2)
colnames(BeschaeftigtenQuote)[3] <- "Employment Rate"
BeschaeftigtenQuote <- BeschaeftigtenQuote  %>% mutate(regionaleinheit = case_when(
  regionaleinheit == "Mühldorf a.Inn" ~ "Mühldorf a. Inn",
  regionaleinheit == "Pfaffenhofen a.d.Ilm" ~ "Pfaffenhofen a.d. Ilm",
  regionaleinheit == "Weiden i.d.OPf." ~ "Weiden i.d. OPf.",
  regionaleinheit == "Neumarkt i.d.OPf." ~ "Neumarkt i.d. OPf.",
  regionaleinheit == "Neustadt a.d.Waldnaab" ~ "Neustadt a.d. Waldnaab",
  regionaleinheit == "Wunsiedel i.Fichtelgebirge" ~ "Wunsiedel i. Fichtelgebirge",
  regionaleinheit == "Neustadt a.d.Aisch-Bad Windsheim" ~ "Neustadt a.d. Aisch-Bad Windsheim",
  regionaleinheit == "Dillingen a.d.Donau" ~ "Dillingen a.d. Donau",
  .default = regionaleinheit))

AfdAgeEmployment <- left_join(Zweitstimme, AverageAge)
AfdAgeEmployment <- left_join(AfdAgeEmployment, BeschaeftigtenQuote)

AfdAgeEmployment <- AfdAgeEmployment %>% mutate(regionaleinheit = case_when(regionaleinheit == "Aschaffenburg, Landkreis" ~ "Landkreis Aschaffenburg",
                                                                            regionaleinheit == "Bayreuth, Landkreis" ~ "Landkreis Bayreuth",
                                                                            regionaleinheit == "Würzburg, Landkreis" ~ "Landkreis Würzburg",
                                                                            regionaleinheit == "Ansbach, Landkreis" ~ "Landkreis Ansbach",
                                                                            regionaleinheit == "Bamberg, Landkreis" ~ "Landkreis Bamberg",
                                                                            regionaleinheit == "Coburg, Landkreis" ~ "Landkreis Coburg",
                                                                            regionaleinheit == "Fürth, Landkreis" ~ "Landkreis Fürth",
                                                                            regionaleinheit == "Hof, Landkreis" ~ "Landkreis Hof",
                                                                            regionaleinheit == "Kassel, Landkreis" ~ "Landkreis Kassel",
                                                                            regionaleinheit == "Landshut, Landkreis"  ~ "Landkreis Landshut",
                                                                            regionaleinheit == "Passau, Landkreis" ~ "Landkreis Passau",
                                                                            regionaleinheit == "Passau, Landkreis" ~ "Landkreis Regensburg",
                                                                            regionaleinheit == "Augsburg, Landkreis" ~ "Landkreis Augsburg",
                                                                            regionaleinheit == "Rostock, Landkreis" ~ "Landkreis Rostock", 
                                                                            regionaleinheit == "Regensburg, Landkreis" ~ "Landkreis Regensburg",
                                                                            regionaleinheit == "Schweinfurt, Landkreis" ~ "Landkreis Schweinfurt",
                                                                            regionaleinheit == "Rosenheim, Landkreis" ~ "Landkreis Rosenheim",
                                                                            regionaleinheit == "München, Landkreis" ~ "Landkreis München",
                                                                            regionaleinheit == "Karlsruhe, Landkreis" ~ "Landkreis Karlsruhe",
                                                                            regionaleinheit == "Heilbronn, Landkreis" ~ "Landkreis Heilbronn",
                                                                            regionaleinheit == "Leipzig, Landkreis" ~ "Landkreis Leipzig",
                                                                            regionaleinheit == "Mühldorf a. Inn" ~ "Mühldorf am Inn",
                                                                            regionaleinheit == "Kaiserslautern, Landkreis" ~ "Landkreis Kaiserslautern",
                                                                            regionaleinheit == "Neumarkt i.d. OPf." ~ "Neumarkt in der Oberpfalz",
                                                                            regionaleinheit == "Neustadt a.d. Aisch-Bad Windsheim" ~ "Neustadt an der Aisch-Bad Windsheim",
                                                                            regionaleinheit == "Neustadt a.d. Waldnaab" ~ "Neustadt an der Waldnaab",
                                                                            regionaleinheit == "Weiden i.d. OPf." ~ "Weiden in der Oberpfalz", 
                                                                            regionaleinheit == "Wunsiedel i. Fichtelgebirge" ~ "Wunsiedel im Fichtelgebirge",
                                                                            regionaleinheit == "Dillingen a.d. Donau" ~ "Dillingen an der Donau",
                                                                            regionaleinheit == "Oldenburg, Landkreis" ~ "Landkreis Oldenburg",
                                                                            regionaleinheit == "Oldenburg (Oldb)" ~ "Oldenburg",
                                                                            regionaleinheit == "Osnabrück, Landkreis" ~ "Landkreis Osnabrück",
                                                                            regionaleinheit == "Nienburg (Weser)" ~ "Nienburg/Weser",
                                                                            regionaleinheit == "Rhein-Kreis Neuss" ~ "Rhein-Neuss",
                                                                            regionaleinheit == "Altenkirchen (Westerwald)" ~ "Altenkirchen",
                                                                            regionaleinheit == "Region Hannover" ~ "Hannover",
                                                                            regionaleinheit == "Cottbus" ~ "Cottbus - Chóśebuz",
                                                                            regionaleinheit == "Darmstadt, Wissenschaftsstadt" ~ "Darmstadt",
                                                                            regionaleinheit == "Hagen, Stadt der FernUniversität" ~ "Hagen",
                                                                            regionaleinheit == "Lindau (Bodensee)" ~ "Lindau",
                                                                            regionaleinheit == 	"Pfaffenhofen a.d. Ilm" ~ "Pfaffenhofen an der Ilm",
                                                                            regionaleinheit == "Solingen, Klingenstadt" ~ "Solingen",
                                                                            .default = regionaleinheit))
colnames(AfdAgeEmployment)[2] <- "LK_Name"

disFac_post <- left_join(disFac_post, AfdAgeEmployment)

#Correlation matrix
valuetoplotRed <- disFac_post %>% dplyr::select(c(value, Inhabitantsperkm2, IncomePerson2022, unemploymentQuota, `Employment Rate`, `Average Age`, peopleover65, childrenbelow3inprimarycare, voterTurnout, `Voted for Parting Government`, `Voted for Incoming Government`))
colnames(valuetoplotRed) <- c("Weight", "Inhabitants per km2", "Income", "Unemployment Rate", "Employment Rate", "Average Age", "65+ year olds", "Small Children (< 3) in Childcare",  "Voter Turnout", "Voted for Parting Government", "Voted for Incoming Government")

#valuetoplotRed <- valuetoplotRed %>% select(c("Reaction Strength", "Inhabitants per km2", "Unemployment Rate", "Voter Turnout", "Income per Capita", "Small Children (< 3) in Childcare" ))
corrmat <- cor(valuetoplotRed) 
pdf(height = 10, width = 13, "CorrelationPlotNatvsLocal.pdf")
#pdf(height = 8, width = 13, "CorrelationPlotReduced.pdf")
corrplot(corrmat, method = "color", tl.col="black", type = "upper", tl.srt = 90, tl.cex = 1.6, cl.pos = "b", diag = FALSE, cl.ratio = 0.25, cl.cex=1.25, mar = c(0,0,1.5,1))
dev.off()

# Regression Analysis

valuetoplotRed <- disFac_post %>% dplyr::select(c(value, Inhabitantsperkm2, IncomePerson2022, unemploymentQuota, `Employment Rate`, `Average Age`, peopleover65, childrenbelow3inprimarycare, voterTurnout, `Voted for Parting Government`, `Voted for Incoming Government`))

# Scaling of Variables
valuetoplotRed <- valuetoplotRed %>% mutate(Inhabitantsperkm2 = scale(Inhabitantsperkm2)) %>%
  mutate(voterTurnout = scale(voterTurnout)) %>%
  mutate(IncomePerson2022 = scale(IncomePerson2022)) %>%
  mutate(unemploymentQuota = scale(unemploymentQuota)) %>%
  mutate(peopleover65 = scale(peopleover65, center = TRUE, scale = TRUE)) %>%
  mutate(childrenbelow3inprimarycare = scale(childrenbelow3inprimarycare)) %>%
  mutate(`Voted for Parting Government` = scale(`Voted for Parting Government`)) %>%
  mutate(`Voted for Incoming Government` = scale(`Voted for Incoming Government`)) %>%
  mutate(`Average Age` = scale(`Average Age`)) %>%
  mutate(`Employment Rate` = scale(`Employment Rate`))

# Exhaustive Search -------------------------------------------------------

#https://www.rdocumentation.org/packages/leaps/versions/3.2/topics/regsubsets
exhaustivesearch <- regsubsets(value ~ ., data=valuetoplotRed) # %>% dplyr::select(-predicted))
mod.summary <- summary(exhaustivesearch)
which.min(mod.summary$bic) # --> Uses SBC
which.max(mod.summary$adjr2)

# Exhaustive Search - Method 2 -------------------------------------------------------
bestsubset <- olsrr::ols_step_best_subset(lm(value ~ ., data=valuetoplotRed), metric = "adjr") #default metric = r2
subset_summary <- cbind(bestsubset$metrics[4], bestsubset$metrics[5], bestsubset$metrics[6], bestsubset$metrics[7], bestsubset$metrics[8], bestsubset$metrics[9], bestsubset$metrics[10], bestsubset$metrics[11],
                        bestsubset$metrics[12], bestsubset$metrics[13], bestsubset$metrics)
subset_summary <- round(subset_summary, 2)
write_csv(subset_summary, "metricsNatvsLocal.csv")
plot(bestsubset)

FinalModel <- lm(value ~ Inhabitantsperkm2 + `Average Age` + peopleover65 + childrenbelow3inprimarycare + voterTurnout, data = valuetoplotRed)
summary(FinalModel)

ggplot(subset_summary, aes(x=nrow, y = value)) +
  geom_point(color = "blue4", size = 3, shape = 1) +
  geom_line(color = "blue4") +
  scale_x_continuous(breaks = 1:10) +
  facet_wrap(~name, nrow = 2, scale = "free") + 
  theme_bw() + 
  ylab("") +
  xlab("") +
  theme(
    text = element_text(size = 22),  # Affects most text elements
    axis.text = element_text(size = 20),  # Axis labels
    axis.title = element_text(size = 24),  # Axis titles
    plot.title = element_text(size = 28),  # Plot title
    legend.text = element_text(size = 20),  # Legend text
    legend.title = element_text(size = 22)  # Legend title
  )

ggsave("MetricsWeight.pdf", w = 18, h = 6)

#Variance of inflation factor
library(car)
vif(FinalModel) #All between 1 and 5 --> Some sort of correlation, not large enough to wrrant adaptations


# Forward Selection -------------------------------------------------------

#One Variable Models
RegressionPopDens <- lm(value ~ Inhabitantsperkm2, data = valuetoplotRed)
summary(RegressionPopDens)
AIC(RegressionPopDens)
BIC(RegressionPopDens)
RegressionIncome <- lm(value ~ IncomePerson2022, data = valuetoplotRed)
summary(RegressionIncome)
AIC(RegressionIncome)
BIC(RegressionIncome)
RegressionUnemployment <- lm(value ~ unemploymentQuota, data = valuetoplotRed)
summary(RegressionUnemployment)
AIC(RegressionUnemployment)
BIC(RegressionUnemployment)
RegressionEmploymentRate <- lm(value ~ `Employment Rate`, data = valuetoplotRed)
summary(RegressionEmploymentRate)
AIC(RegressionEmploymentRate)
BIC(RegressionEmploymentRate)
RegressionAverageAge <- lm(value ~ `Average Age`, data = valuetoplotRed)
summary(RegressionAverageAge)
AIC(RegressionAverageAge)
BIC(RegressionAverageAge)
RegressionPeopleOver65 <- lm(value ~ peopleover65, data = valuetoplotRed)
summary(RegressionPeopleOver65)
AIC(RegressionPeopleOver65)
BIC(RegressionPeopleOver65)
RegressionChildrenInChildcare <- lm(value ~ childrenbelow3inprimarycare, data=valuetoplotRed)
summary(RegressionChildrenInChildcare)
AIC(RegressionChildrenInChildcare)
BIC(RegressionChildrenInChildcare)
RegressionVoter <- lm(value ~ voterTurnout, data = valuetoplotRed)
summary(RegressionVoter)
AIC(RegressionVoter)
BIC(RegressionVoter)
RegressionParting <- lm(value ~ `Voted for Parting Government`, data = valuetoplotRed)
summary(RegressionParting)
AIC(RegressionParting)
BIC(RegressionParting)
RegressionIncoming <- lm(value ~ `Voted for Incoming Government`, data = valuetoplotRed)
summary(RegressionIncoming)
AIC(RegressionIncoming)
BIC(RegressionIncoming)

#Two Variables Models
RegressionChildrenInChildcarePopDens <- lm(value ~ childrenbelow3inprimarycare + Inhabitantsperkm2, data=valuetoplotRed)
summary(RegressionChildrenInChildcarePopDens)
AIC(RegressionChildrenInChildcarePopDens)
BIC(RegressionChildrenInChildcarePopDens)
RegressionChildrenInChildcareIncome <- lm(value ~ childrenbelow3inprimarycare + IncomePerson2022, data=valuetoplotRed)
summary(RegressionChildrenInChildcareIncome)
AIC(RegressionChildrenInChildcareIncome)
BIC(RegressionChildrenInChildcareIncome)
RegressionChildrenInChildcareUnemployment <- lm(value ~ childrenbelow3inprimarycare + unemploymentQuota, data=valuetoplotRed)
summary(RegressionChildrenInChildcareUnemployment)
AIC(RegressionChildrenInChildcareUnemployment)
BIC(RegressionChildrenInChildcareUnemployment)
RegressionChildrenInChildcareEmploymentRate <- lm(value ~ childrenbelow3inprimarycare + `Employment Rate`, data=valuetoplotRed)
summary(RegressionChildrenInChildcareEmploymentRate)
AIC(RegressionChildrenInChildcareEmploymentRate)
BIC(RegressionChildrenInChildcareEmploymentRate)
RegressionChildrenInChildcareAge <- lm(value ~ childrenbelow3inprimarycare + `Average Age`, data=valuetoplotRed)
summary(RegressionChildrenInChildcareAge)
AIC(RegressionChildrenInChildcareAge)
BIC(RegressionChildrenInChildcareAge)
RegressionChildrenInChildcarePeopleOver65 <- lm(value ~ childrenbelow3inprimarycare + peopleover65, data=valuetoplotRed)
summary(RegressionChildrenInChildcarePeopleOver65)
AIC(RegressionChildrenInChildcarePeopleOver65)
BIC(RegressionChildrenInChildcarePeopleOver65)
RegressionChildrenInChildcareVoter <- lm(value ~ childrenbelow3inprimarycare + voterTurnout, data=valuetoplotRed)
summary(RegressionChildrenInChildcareVoter)
AIC(RegressionChildrenInChildcareVoter)
BIC(RegressionChildrenInChildcareVoter)
RegressionChildrenInChildcareParting <- lm(value ~ childrenbelow3inprimarycare + `Voted for Parting Government`, data=valuetoplotRed)
summary(RegressionChildrenInChildcareParting)
AIC(RegressionChildrenInChildcareParting)
BIC(RegressionChildrenInChildcareParting)
RegressionChildrenInChildcareIncoming <- lm(value ~ childrenbelow3inprimarycare + `Voted for Incoming Government`, data=valuetoplotRed)
summary(RegressionChildrenInChildcareIncoming)
AIC(RegressionChildrenInChildcareIncoming)
BIC(RegressionChildrenInChildcareIncoming)

#3 Variables Models
RegressionChildrenInChildcarePeopleOver65PopDens <- lm(value ~ childrenbelow3inprimarycare + peopleover65 + Inhabitantsperkm2, data=valuetoplotRed)
summary(RegressionChildrenInChildcarePeopleOver65PopDens)
AIC(RegressionChildrenInChildcarePeopleOver65PopDens)
BIC(RegressionChildrenInChildcarePeopleOver65PopDens)
RegressionChildrenInChildcarePeopleOver65Income <- lm(value ~ childrenbelow3inprimarycare + peopleover65 + IncomePerson2022, data=valuetoplotRed)
summary(RegressionChildrenInChildcarePeopleOver65Income)
AIC(RegressionChildrenInChildcarePeopleOver65Income)
BIC(RegressionChildrenInChildcarePeopleOver65Income)
RegressionChildrenInChildcarePeopleOver65Unemployment <- lm(value ~ childrenbelow3inprimarycare + peopleover65 + unemploymentQuota, data=valuetoplotRed)
summary(RegressionChildrenInChildcarePeopleOver65Unemployment)
AIC(RegressionChildrenInChildcarePeopleOver65Unemployment)
BIC(RegressionChildrenInChildcarePeopleOver65Unemployment)
RegressionChildrenInChildcarePeopleOver65EmploymentRate <- lm(value ~ childrenbelow3inprimarycare + peopleover65 + `Employment Rate`, data=valuetoplotRed)
summary(RegressionChildrenInChildcarePeopleOver65EmploymentRate)
AIC(RegressionChildrenInChildcarePeopleOver65EmploymentRate)
BIC(RegressionChildrenInChildcarePeopleOver65EmploymentRate)
RegressionChildrenInChildcarePeopleOver65Age <- lm(value ~ childrenbelow3inprimarycare + peopleover65 + `Average Age`, data=valuetoplotRed)
summary(RegressionChildrenInChildcarePeopleOver65Age)
AIC(RegressionChildrenInChildcarePeopleOver65Age)
BIC(RegressionChildrenInChildcarePeopleOver65Age)
RegressionChildrenInChildcarePeopleOver65Voter <- lm(value ~ childrenbelow3inprimarycare + peopleover65 + voterTurnout, data=valuetoplotRed)
summary(RegressionChildrenInChildcarePeopleOver65Voter)
AIC(RegressionChildrenInChildcarePeopleOver65Voter)
BIC(RegressionChildrenInChildcarePeopleOver65Voter)
RegressionChildrenInChildcarePeopleOver65Parting <- lm(value ~ childrenbelow3inprimarycare + peopleover65 + `Voted for Parting Government`, data=valuetoplotRed)
summary(RegressionChildrenInChildcarePeopleOver65Parting)
AIC(RegressionChildrenInChildcarePeopleOver65Parting)
BIC(RegressionChildrenInChildcarePeopleOver65Parting)
RegressionChildrenInChildcarePeopleOver65Incoming <- lm(value ~ childrenbelow3inprimarycare + peopleover65 + `Voted for Incoming Government`, data=valuetoplotRed)
summary(RegressionChildrenInChildcarePeopleOver65Incoming)
AIC(RegressionChildrenInChildcarePeopleOver65Incoming)
BIC(RegressionChildrenInChildcarePeopleOver65Incoming)

#4 Variables Models
RegressionChildrenInChildcarePeopleOver65AgePopDens <- lm(value ~ childrenbelow3inprimarycare + peopleover65 + `Average Age` + Inhabitantsperkm2, data=valuetoplotRed)
summary(RegressionChildrenInChildcarePeopleOver65AgePopDens)
AIC(RegressionChildrenInChildcarePeopleOver65AgePopDens)
BIC(RegressionChildrenInChildcarePeopleOver65AgePopDens)
RegressionChildrenInChildcarePeopleOver65AgeIncome <- lm(value ~ childrenbelow3inprimarycare + peopleover65 + `Average Age` + IncomePerson2022, data=valuetoplotRed)
summary(RegressionChildrenInChildcarePeopleOver65AgeIncome)
AIC(RegressionChildrenInChildcarePeopleOver65AgeIncome)
BIC(RegressionChildrenInChildcarePeopleOver65AgeIncome)
RegressionChildrenInChildcarePeopleOver65AgeUnemployment <- lm(value ~ childrenbelow3inprimarycare + peopleover65 + `Average Age` + unemploymentQuota, data=valuetoplotRed)
summary(RegressionChildrenInChildcarePeopleOver65AgeUnemployment)
AIC(RegressionChildrenInChildcarePeopleOver65AgeUnemployment)
BIC(RegressionChildrenInChildcarePeopleOver65AgeUnemployment)
RegressionChildrenInChildcarePeopleOver65AgeEmploymentRate <- lm(value ~ childrenbelow3inprimarycare + peopleover65 + `Average Age` + `Employment Rate`, data=valuetoplotRed)
summary(RegressionChildrenInChildcarePeopleOver65AgeEmploymentRate)
AIC(RegressionChildrenInChildcarePeopleOver65AgeEmploymentRate)
BIC(RegressionChildrenInChildcarePeopleOver65AgeEmploymentRate)
RegressionChildrenInChildcarePeopleOver65AgeVoter <- lm(value ~ childrenbelow3inprimarycare + peopleover65 + `Average Age` + voterTurnout , data=valuetoplotRed)
summary(RegressionChildrenInChildcarePeopleOver65AgeVoter)
AIC(RegressionChildrenInChildcarePeopleOver65AgeVoter)
BIC(RegressionChildrenInChildcarePeopleOver65AgeVoter)
RegressionChildrenInChildcarePeopleOver65AgeParting <- lm(value ~ childrenbelow3inprimarycare + peopleover65 + `Average Age`  + `Voted for Parting Government` , data=valuetoplotRed)
summary(RegressionChildrenInChildcarePeopleOver65AgeParting)
AIC(RegressionChildrenInChildcarePeopleOver65AgeParting)
BIC(RegressionChildrenInChildcarePeopleOver65AgeParting)
RegressionChildrenInChildcarePeopleOver65AgeIncoming <- lm(value ~ childrenbelow3inprimarycare + peopleover65 + `Average Age`  + `Voted for Incoming Government`, data=valuetoplotRed)
summary(RegressionChildrenInChildcarePeopleOver65AgeIncoming)
AIC(RegressionChildrenInChildcarePeopleOver65AgeIncoming)
BIC(RegressionChildrenInChildcarePeopleOver65AgeIncoming)

#5 Variables Models
RegressionChildrenInChildcarePeopleOver65AgePopDensIncome <- lm(value ~ childrenbelow3inprimarycare + peopleover65 + `Average Age` + Inhabitantsperkm2 + IncomePerson2022, data=valuetoplotRed)
summary(RegressionChildrenInChildcarePeopleOver65AgePopDensIncome)
AIC(RegressionChildrenInChildcarePeopleOver65AgePopDensIncome)
BIC(RegressionChildrenInChildcarePeopleOver65AgePopDensIncome)
RegressionChildrenInChildcarePeopleOver65AgePopDensUnemployment <- lm(value ~ childrenbelow3inprimarycare + peopleover65 + `Average Age` + Inhabitantsperkm2 + unemploymentQuota, data=valuetoplotRed)
summary(RegressionChildrenInChildcarePeopleOver65AgePopDensUnemployment)
AIC(RegressionChildrenInChildcarePeopleOver65AgePopDensUnemployment)
BIC(RegressionChildrenInChildcarePeopleOver65AgePopDensUnemployment)
RegressionChildrenInChildcarePeopleOver65AgePopDensEmploymentRate <- lm(value ~ childrenbelow3inprimarycare + peopleover65 + `Average Age` + Inhabitantsperkm2 + `Employment Rate`, data=valuetoplotRed)
summary(RegressionChildrenInChildcarePeopleOver65AgePopDensEmploymentRate)
AIC(RegressionChildrenInChildcarePeopleOver65AgePopDensEmploymentRate)
BIC(RegressionChildrenInChildcarePeopleOver65AgePopDensEmploymentRate)
RegressionChildrenInChildcarePeopleOver65AgePopDensVoter <- lm(value ~ childrenbelow3inprimarycare + peopleover65 + `Average Age` + Inhabitantsperkm2 + voterTurnout, data=valuetoplotRed)
summary(RegressionChildrenInChildcarePeopleOver65AgePopDensVoter)
AIC(RegressionChildrenInChildcarePeopleOver65AgePopDensVoter)
BIC(RegressionChildrenInChildcarePeopleOver65AgePopDensVoter)
RegressionChildrenInChildcarePeopleOver65AgePopDensParting <- lm(value ~ childrenbelow3inprimarycare + peopleover65 + `Average Age` + Inhabitantsperkm2 + `Voted for Parting Government`, data=valuetoplotRed)
summary(RegressionChildrenInChildcarePeopleOver65AgePopDensParting)
AIC(RegressionChildrenInChildcarePeopleOver65AgePopDensParting)
BIC(RegressionChildrenInChildcarePeopleOver65AgePopDensParting)
RegressionChildrenInChildcarePeopleOver65AgePopDensIncoming <- lm(value ~ childrenbelow3inprimarycare + peopleover65 + `Average Age` + Inhabitantsperkm2 + `Voted for Incoming Government`, data=valuetoplotRed)
summary(RegressionChildrenInChildcarePeopleOver65AgePopDensIncoming)
AIC(RegressionChildrenInChildcarePeopleOver65AgePopDensIncoming)
BIC(RegressionChildrenInChildcarePeopleOver65AgePopDensIncoming)

#Correlation coefficient
cor(valuetoplotRed$value, valuetoplotRed$childrenbelow3inprimarycare)
cor(valuetoplotRed$value, valuetoplotRed$peopleover65)
cor(valuetoplotRed$value, valuetoplotRed$`Average Age`)
cor(valuetoplotRed$value, valuetoplotRed$Inhabitantsperkm2)
cor(valuetoplotRed$value, valuetoplotRed$voterTurnout)

#6 Variables Models
RegressionChildrenInChildcarePeopleOver65AgePopDensVoterIncome <- lm(value ~ childrenbelow3inprimarycare + peopleover65 + `Average Age` + Inhabitantsperkm2 + voterTurnout + IncomePerson2022, data=valuetoplotRed)
summary(RegressionChildrenInChildcarePeopleOver65AgePopDensVoterIncome)
AIC(RegressionChildrenInChildcarePeopleOver65AgePopDensVoterIncome)
BIC(RegressionChildrenInChildcarePeopleOver65AgePopDensVoterIncome)
RegressionChildrenInChildcarePeopleOver65AgePopDensVoterUnemployment <- lm(value ~ childrenbelow3inprimarycare + peopleover65 + `Average Age` + Inhabitantsperkm2 + voterTurnout + unemploymentQuota, data=valuetoplotRed)
summary(RegressionChildrenInChildcarePeopleOver65AgePopDensVoterUnemployment)
AIC(RegressionChildrenInChildcarePeopleOver65AgePopDensVoterUnemployment)
BIC(RegressionChildrenInChildcarePeopleOver65AgePopDensVoterUnemployment)
RegressionChildrenInChildcarePeopleOver65AgePopDensVoterEmploymentRate <- lm(value ~ childrenbelow3inprimarycare + peopleover65 + `Average Age` + Inhabitantsperkm2 + voterTurnout + `Employment Rate`, data=valuetoplotRed)
summary(RegressionChildrenInChildcarePeopleOver65AgePopDensVoterEmploymentRate)
AIC(RegressionChildrenInChildcarePeopleOver65AgePopDensVoterEmploymentRate)
BIC(RegressionChildrenInChildcarePeopleOver65AgePopDensVoterEmploymentRate)
RegressionChildrenInChildcarePeopleOver65AgePopDensVoterParting <- lm(value ~ childrenbelow3inprimarycare + peopleover65 + `Average Age` + Inhabitantsperkm2 + voterTurnout+ `Voted for Parting Government`, data=valuetoplotRed)
summary(RegressionChildrenInChildcarePeopleOver65AgePopDensVoterParting)
AIC(RegressionChildrenInChildcarePeopleOver65AgePopDensVoterParting)
BIC(RegressionChildrenInChildcarePeopleOver65AgePopDensVoterParting)
RegressionChildrenInChildcarePeopleOver65AgePopDensVoterIncoming <- lm(value ~ childrenbelow3inprimarycare + peopleover65 + `Average Age` + Inhabitantsperkm2 + voterTurnout+ `Voted for Incoming Government`, data=valuetoplotRed)
summary(RegressionChildrenInChildcarePeopleOver65AgePopDensVoterIncoming)
AIC(RegressionChildrenInChildcarePeopleOver65AgePopDensVoterIncoming)
BIC(RegressionChildrenInChildcarePeopleOver65AgePopDensVoterIncoming)
