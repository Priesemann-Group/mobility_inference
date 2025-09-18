library(corrplot)
library(tidyverse)
library(readxl)
library(here)

here()

# Regression Analysis -----------------------------------------------------

#Data Preprocessing -------------------------------------------------------

source("Postprocessing_Clean.R")

model <- "fourhundred"

consideredWave <- "firstwave"

run <- "2025-07-02_400LK_exp_UsedForPostprocessing"

outcomeVariable <- "slope"

disFac_post <- postprocessing_clean(model, consideredWave, run, outcomeVariable)

# my_comparisons <- list(c("Grosse Grossstadt", "Kleine Grossstadt"),
#                        c("Kleine Grossstadt", "Städtische Kreise"),
#                        c("Städtische Kreise", "Ländlicher Kreis mit Verdichtungsansätzen"),
#                        c("Ländlicher Kreis mit Verdichtungsansätzen", "Dünn besiedelt ländlicher Kreis"))
my_comparisons <- list(c("Large City", "Small City"),
                       c("Small City", "Town"),
                       c("Town", "Medium Rural"),
                       c("Medium Rural", "Rural"))
symnum.args <- list(cutpoints = c(0, 0.0001, 0.001, 0.01, 0.05, Inf), symbols = c("****", "***", "**", "*", "ns"))

manual_scale <- c("#D4B2CC", "#D385AC",  "#A56693", "#66507A", "#2D204C")

boxplot <- ggplot(disFac_post %>% filter(!is.na(group_eng)), aes(x= group_eng, y=value)) +
  geom_boxplot(aes(color = group_eng), lwd=1.5)+
  stat_compare_means(comparisons = my_comparisons, symnum.args = symnum.args, method = "t.test", size = 5) +
  theme_minimal() +
  guides(color=guide_legend(nrow=5,byrow=TRUE)) +
  theme(legend.position = "bottom") +
  ylab("Initial Reduction Strength") +
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
incomeDf <- incomeDf %>% select(Land, Gebietseinheit, `2022`)
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

# Voter turnout, unemployment, elderly ------------------------------------

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
voterturnout <- voterturnout %>% select(c(Kreisname, wahl_beteil, alq, bev_ue65, kbetr_u3))
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

# Voted right wing, average age, employment rate

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

valuetoplotRed <- disFac_post %>% select(c(value, Inhabitantsperkm2, IncomePerson2022, unemploymentQuota, `Employment Rate`, `Average Age`, peopleover65, childrenbelow3inprimarycare, voterTurnout, `Voted for Parting Government`, `Voted for Incoming Government`))

# Regression Analysis
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


#Forward Selection
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

#Population Density leads to the largest adj. R^2 (~ 0.36)
#We continue with the model RegressionPopDens and add the other variables one by one
#Two Variables Models
RegressionDensIncome <- lm(value ~ Inhabitantsperkm2 + IncomePerson2022, data = valuetoplotRed)
summary(RegressionDensIncome)
AIC(RegressionDensIncome)
BIC(RegressionDensIncome)
RegressionDensUnemployment <- lm(value ~ Inhabitantsperkm2 + unemploymentQuota, data = valuetoplotRed)
summary(RegressionDensUnemployment)
AIC(RegressionDensUnemployment)
BIC(RegressionDensUnemployment)
RegressionDensEmployment <- lm(value ~ Inhabitantsperkm2 + `Employment Rate`, data = valuetoplotRed)
summary(RegressionDensEmployment)
AIC(RegressionDensEmployment)
BIC(RegressionDensEmployment)
RegressionDensAvgAge <- lm(value ~ Inhabitantsperkm2 + `Average Age`, data = valuetoplotRed)
summary(RegressionDensAvgAge)
AIC(RegressionDensAvgAge)
BIC(RegressionDensAvgAge)
RegressionDens65 <- lm(value ~ Inhabitantsperkm2 + peopleover65, data = valuetoplotRed)
summary(RegressionDens65)
AIC(RegressionDens65)
BIC(RegressionDens65)
RegressionDensChildren <- lm(value ~ Inhabitantsperkm2 + childrenbelow3inprimarycare, data = valuetoplotRed)
summary(RegressionDensChildren)
AIC(RegressionDensChildren)
BIC(RegressionDensChildren)
RegressionDensVoter <- lm(value ~ Inhabitantsperkm2 + voterTurnout, data = valuetoplotRed)
summary(RegressionDensVoter)
AIC(RegressionDensVoter)
BIC(RegressionDensVoter)
RegressionDensParting <- lm(value ~ Inhabitantsperkm2 + `Voted for Parting Government`, data = valuetoplotRed)
summary(RegressionDensParting)
AIC(RegressionDensParting)
BIC(RegressionDensParting)
RegressionDensIncoming <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government`, data = valuetoplotRed)
summary(RegressionDensIncoming)
AIC(RegressionDensIncoming)
BIC(RegressionDensIncoming)