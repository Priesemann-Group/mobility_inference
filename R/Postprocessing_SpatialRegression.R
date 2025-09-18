library(corrplot)
library(tidyverse)
library(readxl)
library(here)
library(lme4)
library(partR2)

here()

# Regression Analysis -----------------------------------------------------

#Data Preprocessing -------------------------------------------------------

model <- "fourhundred"

consideredWave <- "firstwave"

run <- "2025-07-02_400LK_exp_UsedForPostprocessing"

outcomeVariable <- "exponential"

source("Postprocessing_Clean.R")

disFac_post <- postprocessing_clean(model, consideredWave, run, outcomeVariable)

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

Zweitstimme <- Zweitstimme %>% mutate(GRUENE = case_when(regionaleinheit == "Regionalverband Saarbrücken" ~ 0.0, #Gruene Landesliste bei Bundestagswahl im Saarland nicht zugelassen --> Zweitstimme für Grüne nicht möglich
                                                         regionaleinheit == "Neunkirchen" ~ 0.0, 
                                                         regionaleinheit == "Saarlouis" ~ 0.0, 
                                                         regionaleinheit == "Merzig-Wadern" ~ 0.0, 
                                                         regionaleinheit == "Saarpfalz-Kreis" ~ 0.0, 
                                                         regionaleinheit == "St. Wendel" ~ 0.0,
                                                         .default = GRUENE))

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
#colnames(valuetoplotRed) <- c("Reaction Strength", "Inhabitants per km2", "Income", "Unemployment Rate", "Employment Rate", "Average Age", "65+ year olds", "Small Children (< 3) in Childcare",  "Voter Turnout", "Voted for Parting Government", "Voted for Incoming Government")

#valuetoplotRed <- valuetoplotRed %>% select(c("Reaction Strength", "Inhabitants per km2", "Voted for Incoming Government", "Small Children (< 3) in Childcare", "Voter Turnout", "Unemployment Rate", "Income"))
corrmat <- cor(valuetoplotRed)
#pdf(height = 10, width = 13, "CorrelationPlot.pdf")
#pdf(height = 8, width = 13, "CorrelationPlotReduced.pdf")
corrplot(corrmat, method = "color", tl.col="black", type = "upper", tl.srt = 90, tl.cex = 1.6, cl.pos = "b", diag = FALSE, cl.ratio = 0.25, cl.cex=1.25, mar = c(0,0,1.5,1))
dev.off()


# Regression Analysis -----------------------------------------------------

# Scaling of Independent Variables ----------------------------------------

valuetoplotRed <- valuetoplotRed %>% mutate(Inhabitantsperkm2 = scale(Inhabitantsperkm2)) %>%
                                      mutate(voterTurnout = scale(voterTurnout)) %>%
                                      mutate(IncomePerson2022 = scale(IncomePerson2022)) %>%
                                      mutate(unemploymentQuota = scale(unemploymentQuota)) %>%
                                      mutate(peopleover65 = scale(peopleover65)) %>%
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
                        bestsubset$metrics[12], bestsubset$metrics[13], bestsubset$metrics[14])
subset_summary <- round(subset_summary, 2)
write_csv(subset_summary, "metrics.csv")
plot(bestsubset)
#Largest R2 --> 8-10 Variables
#Largest Adj R2 --> 8 Variables
#Largest Pred R2 --> 6 Variables
#Smallest C(p) --> 6 Variables
#Smallest AIC --> 6 Variables
#Smallest SBIC --> 6 Variables
#SBC --> 4 Variables
#MSEP --> 8 Variable model
#FPE --> 6 Variable model
#HSP --> Equal
#APC --> 6 Variable model 

#Variance of inflation factor
library(car)
vif(RegressionDensIncomingChildcareVotesUnemploymentIncome) #All between 1 and 5 --> Some sort of correlation, not large enough to wrrant adaptations


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
#Unemployment is significant (<0.05) leads to the largest adj. R^2 (~ 0.37)
#We continue with this model
#Three Variables Models
RegressionDensIncomingIncome <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government`+ IncomePerson2022, data = valuetoplotRed)
summary(RegressionDensIncomingIncome)
AIC(RegressionDensIncomingIncome)
BIC(RegressionDensIncomingIncome)
RegressionDensIncomingUnmployment <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government` + unemploymentQuota , data = valuetoplotRed)
summary(RegressionDensIncomingUnmployment)
AIC(RegressionDensIncomingUnmployment)
BIC(RegressionDensIncomingUnmployment)
RegressionDensIncomingEmployment <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government` + `Employment Rate`, data = valuetoplotRed)
summary(RegressionDensIncomingEmployment)
AIC(RegressionDensIncomingEmployment)
BIC(RegressionDensIncomingEmployment)
RegressionDensIncomingAge <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government` + `Average Age`, data = valuetoplotRed)
summary(RegressionDensIncomingAge)
AIC(RegressionDensIncomingAge)
BIC(RegressionDensIncomingAge)
RegressionDensIncoming65 <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government` + peopleover65 , data = valuetoplotRed)
summary(RegressionDensIncoming65)
AIC(RegressionDensIncoming65)
BIC(RegressionDensIncoming65)
RegressionDensIncomingChildcare <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government`+ childrenbelow3inprimarycare, data = valuetoplotRed)
summary(RegressionDensIncomingChildcare)
AIC(RegressionDensIncomingChildcare)
BIC(RegressionDensIncomingChildcare)
RegressionDensIncomingVotes <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government` + voterTurnout, data = valuetoplotRed)
summary(RegressionDensIncomingVotes)
AIC(RegressionDensIncomingVotes)
BIC(RegressionDensIncomingVotes)
RegressionDensIncomingParting <- lm(value ~ Inhabitantsperkm2 +`Voted for Incoming Government` + `Voted for Parting Government`, data = valuetoplotRed)
summary(RegressionDensIncomingParting)
AIC(RegressionDensIncomingParting)
BIC(RegressionDensIncomingParting)


#children  is significant (p<0.01) and increases adj. R^2 by ~ 1%
#4 Variables models
RegressionDensIncomingChildcareIncome <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government`+ childrenbelow3inprimarycare + IncomePerson2022, data = valuetoplotRed)
summary(RegressionDensIncomingChildcareIncome)
AIC(RegressionDensIncomingChildcareIncome)
BIC(RegressionDensIncomingChildcareIncome)
RegressionDensIncomingChildcareUnemployment <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government`+ childrenbelow3inprimarycare + unemploymentQuota, data = valuetoplotRed)
summary(RegressionDensIncomingChildcareUnemployment)
AIC(RegressionDensIncomingChildcareUnemployment)
BIC(RegressionDensIncomingChildcareUnemployment)
RegressionDensIncomingChildcareEmployment <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government`+ childrenbelow3inprimarycare + `Employment Rate`, data = valuetoplotRed)
summary(RegressionDensIncomingChildcareEmployment)
AIC(RegressionDensIncomingChildcareEmployment)
BIC(RegressionDensIncomingChildcareEmployment)
RegressionDensIncomingChildcareAge <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government`+ childrenbelow3inprimarycare + `Average Age`, data = valuetoplotRed)
summary(RegressionDensIncomingChildcareAge)
AIC(RegressionDensIncomingChildcareAge)
BIC(RegressionDensIncomingChildcareAge)
RegressionDensIncomingChildcare65 <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government`+ childrenbelow3inprimarycare + peopleover65, data = valuetoplotRed)
summary(RegressionDensIncomingChildcare65)
AIC(RegressionDensIncomingChildcare65)
BIC(RegressionDensIncomingChildcare65)
RegressionDensIncomingChildcareVotes <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government`+ childrenbelow3inprimarycare + voterTurnout, data = valuetoplotRed)
summary(RegressionDensIncomingChildcareVotes)
AIC(RegressionDensIncomingChildcareVotes)
BIC(RegressionDensIncomingChildcareVotes)
RegressionDensIncomingChildcareParting <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government`+ childrenbelow3inprimarycare + `Voted for Parting Government`, data = valuetoplotRed)
summary(RegressionDensIncomingChildcareParting)
AIC(RegressionDensIncomingChildcareParting)
BIC(RegressionDensIncomingChildcareParting)


#5 Variables Models
RegressionDensIncomingChildcareVotesIncome <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government`+ childrenbelow3inprimarycare + voterTurnout + IncomePerson2022 , data = valuetoplotRed)
summary(RegressionDensIncomingChildcareVotesIncome)
AIC(RegressionDensIncomingChildcareVotesIncome)
BIC(RegressionDensIncomingChildcareVotesIncome)
RegressionDensIncomingChildcareVotesUnemployment <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government`+ childrenbelow3inprimarycare + voterTurnout + unemploymentQuota, data = valuetoplotRed)
summary(RegressionDensIncomingChildcareVotesUnemployment)
AIC(RegressionDensIncomingChildcareVotesUnemployment)
BIC(RegressionDensIncomingChildcareVotesUnemployment)
RegressionDensIncomingChildcareVotesEmployment <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government`+ childrenbelow3inprimarycare + voterTurnout + `Employment Rate`, data = valuetoplotRed)
summary(RegressionDensIncomingChildcareVotesEmployment)
AIC(RegressionDensIncomingChildcareVotesEmployment)
BIC(RegressionDensIncomingChildcareVotesEmployment)
RegressionDensIncomingChildcareVotesAge <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government`+ childrenbelow3inprimarycare + voterTurnout + `Average Age`, data = valuetoplotRed)
summary(RegressionDensIncomingChildcareVotesAge)
AIC(RegressionDensIncomingChildcareVotesAge)
BIC(RegressionDensIncomingChildcareVotesAge)
RegressionDensIncomingChildcareVotes65 <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government`+ childrenbelow3inprimarycare + voterTurnout + peopleover65, data = valuetoplotRed)
summary(RegressionDensIncomingChildcareVotes65)
AIC(RegressionDensIncomingChildcareVotes65)
BIC(RegressionDensIncomingChildcareVotes65)
RegressionDensIncomingChildcareVotesParting <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government`+ childrenbelow3inprimarycare + voterTurnout + `Voted for Parting Government`, data = valuetoplotRed)
summary(RegressionDensIncomingChildcareVotesParting)
AIC(RegressionDensIncomingChildcareVotesParting)
BIC(RegressionDensIncomingChildcareVotesParting)

#6 Variable Models
RegressionDensIncomingChildcareVotesUnemploymentIncome <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government`+ childrenbelow3inprimarycare + voterTurnout + unemploymentQuota + IncomePerson2022, data = valuetoplotRed)
summary(RegressionDensIncomingChildcareVotesUnemploymentIncome)
AIC(RegressionDensIncomingChildcareVotesUnemploymentIncome)
BIC(RegressionDensIncomingChildcareVotesUnemploymentIncome)
RegressionDensIncomingChildcareVotesUnemploymentEmployment <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government`+ childrenbelow3inprimarycare + voterTurnout + unemploymentQuota + `Employment Rate`, data = valuetoplotRed)
summary(RegressionDensIncomingChildcareVotesUnemploymentEmployment)
AIC(RegressionDensIncomingChildcareVotesUnemploymentEmployment)
BIC(RegressionDensIncomingChildcareVotesUnemploymentEmployment)
RegressionDensIncomingChildcareVotesUnemploymentAge <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government`+ childrenbelow3inprimarycare + voterTurnout + unemploymentQuota + `Average Age`, data = valuetoplotRed)
summary(RegressionDensIncomingChildcareVotesUnemploymentAge)
AIC(RegressionDensIncomingChildcareVotesUnemploymentAge)
BIC(RegressionDensIncomingChildcareVotesUnemploymentAge)
RegressionDensIncomingChildcareVotesUnemployment65 <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government`+ childrenbelow3inprimarycare + voterTurnout + unemploymentQuota + peopleover65, data = valuetoplotRed)
summary(RegressionDensIncomingChildcareVotesUnemployment65)
AIC(RegressionDensIncomingChildcareVotesUnemployment65)
BIC(RegressionDensIncomingChildcareVotesUnemployment65)
RegressionDensIncomingChildcareVotesUnemploymentParting <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government`+ childrenbelow3inprimarycare + voterTurnout + unemploymentQuota + `Voted for Parting Government`, data = valuetoplotRed)
summary(RegressionDensIncomingChildcareVotesUnemploymentParting)
AIC(RegressionDensIncomingChildcareVotesUnemploymentParting)
BIC(RegressionDensIncomingChildcareVotesUnemploymentParting)

#7 Variable Models
RegressionDensIncomingChildcareVotesUnemploymentIncomeEmployment <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government`+ childrenbelow3inprimarycare + voterTurnout + unemploymentQuota + IncomePerson2022 + `Employment Rate`, data = valuetoplotRed)
summary(RegressionDensIncomingChildcareVotesUnemploymentIncomeEmployment)
AIC(RegressionDensIncomingChildcareVotesUnemploymentIncomeEmployment)
BIC(RegressionDensIncomingChildcareVotesUnemploymentIncomeEmployment)
RegressionDensIncomingChildcareVotesUnemploymentIncomeAge <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government`+ childrenbelow3inprimarycare + voterTurnout + unemploymentQuota + IncomePerson2022 + `Average Age`, data = valuetoplotRed)
summary(RegressionDensIncomingChildcareVotesUnemploymentIncomeAge)
AIC(RegressionDensIncomingChildcareVotesUnemploymentIncomeAge)
BIC(RegressionDensIncomingChildcareVotesUnemploymentIncomeAge)
RegressionDensIncomingChildcareVotesUnemploymentIncome65 <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government`+ childrenbelow3inprimarycare + voterTurnout + unemploymentQuota + IncomePerson2022 + peopleover65, data = valuetoplotRed)
summary(RegressionDensIncomingChildcareVotesUnemploymentIncome65)
AIC(RegressionDensIncomingChildcareVotesUnemploymentIncome65)
BIC(RegressionDensIncomingChildcareVotesUnemploymentIncome65)
RegressionDensIncomingChildcareVotesUnemploymentIncomeParting <- lm(value ~ Inhabitantsperkm2 + `Voted for Incoming Government`+ childrenbelow3inprimarycare + voterTurnout + unemploymentQuota + IncomePerson2022 + `Voted for Parting Government`, data = valuetoplotRed)
summary(RegressionDensIncomingChildcareVotesUnemploymentIncomeParting)
AIC(RegressionDensIncomingChildcareVotesUnemploymentIncomeParting)
BIC(RegressionDensIncomingChildcareVotesUnemploymentIncomeParting)

#Final model contains 6 Variables
valuetoplotRed <- valuetoplotRed %>% mutate(predicted = predict(RegressionDensUnemploymentVotesIncomeChildcare))

#One Variable Models
forestplotDataOneVariable <- tibble::tibble(mean = c(RegressionPopDens$coefficients[2], RegressionUnemployment$coefficients[2],  RegressionEmploymentRate$coefficients[2], RegressionAverageAge$coefficients[2], RegressionPeopleOver65$coefficients[2], RegressionChildrenInChildcare$coefficients[2], RegressionIncome$coefficients[2], RegressionVoter$coefficients[2], RegressionParting$coefficients[2], RegressionIncoming$coefficients[2]),
                                            lower = c(confint(RegressionPopDens)[2,1], confint(RegressionUnemployment)[2,1], confint(RegressionEmploymentRate)[2,1], confint(RegressionAverageAge)[2,1], confint(RegressionPeopleOver65)[2,1], confint(RegressionChildrenInChildcare)[2,1], confint(RegressionIncome)[2,1], confint(RegressionVoter)[2,1], confint(RegressionParting)[2,1], confint(RegressionIncoming)[2,1]), 
                                            upper = c(confint(RegressionPopDens)[2,2], confint(RegressionUnemployment)[2,2], confint(RegressionEmploymentRate)[2,2], confint(RegressionAverageAge)[2,2], confint(RegressionPeopleOver65)[2,2], confint(RegressionChildrenInChildcare)[2,2], confint(RegressionIncome)[2,2], confint(RegressionVoter)[2,2], confint(RegressionParting)[2,2], confint(RegressionIncoming)[2,2]),
                                            variable = c("Inhabitants per km2", "Unemployment Rate", "Employment Rate", "Average Age", "65+ Year Olds", "Small Children (< 3) in Childcare", "Income per Capita", "Voter Turnout", "Voted For Parting Government", "Voted For Incoming Government"),
                                            adjr2 = c(round(summary(RegressionPopDens)$r.squared,2), round(summary(RegressionUnemployment)$r.squared,2), round(summary(RegressionEmploymentRate)$r.squared,2), round(summary(RegressionAverageAge)$r.squared,2), round(summary(RegressionPeopleOver65)$r.squared,2), round(summary(RegressionChildrenInChildcare)$r.squared,2),
                                                      round(summary(RegressionIncome)$r.squared,2),round(summary(RegressionVoter)$r.squared,2), round(summary(RegressionParting)$r.squared,2), round(summary(RegressionIncoming)$r.squared,2)),
                                            AIC = c(round(AIC(RegressionPopDens),0), round(AIC(RegressionUnemployment),0), round(AIC(RegressionEmploymentRate),0), round(AIC(RegressionAverageAge),0), round(AIC(RegressionPeopleOver65),0), round(AIC(RegressionChildrenInChildcare),0), round(AIC(RegressionIncome),0), round(AIC(RegressionVoter),0), round(AIC(RegressionParting),0), round(AIC(RegressionIncoming),0)),
                                            BIC = c(round(BIC(RegressionPopDens),0), round(BIC(RegressionUnemployment),0), round(BIC(RegressionEmploymentRate),0), round(BIC(RegressionAverageAge),0), round(BIC(RegressionPeopleOver65),0), round(BIC(RegressionChildrenInChildcare),0), round(BIC(RegressionIncome),0), round(BIC(RegressionVoter),0), round(BIC(RegressionParting),0), round(BIC(RegressionIncoming),0)),
                                            pvalue = c(if(round(summary(RegressionPopDens)$coefficients[,4][2],2) < 0.001){"<0.001"}else{round(summary(RegressionPopDens)$coefficients[,4][2],2)},
                                                       if(round(summary(RegressionUnemployment)$coefficients[,4][2],2) < 0.001){"<0.001"}else{round(summary(RegressionUnemployment)$coefficients[,4][2],2)},
                                                       if(round(summary(RegressionEmploymentRate)$coefficients[,4][2],2) < 0.001){"<0.001"}else{round(summary(RegressionEmploymentRate)$coefficients[,4][2],2)},
                                                       if(round(summary(RegressionAverageAge)$coefficients[,4][2],2) < 0.001){"<0.001"}else{round(summary(RegressionAverageAge)$coefficients[,4][2],2)},
                                                       if(round(summary(RegressionPeopleOver65)$coefficients[,4][2],2) < 0.001){"<0.001"}else{round(summary(RegressionPeopleOver65)$coefficients[,4][2],2)},
                                                       if(round(summary(RegressionChildrenInChildcare)$coefficients[,4][2],2) < 0.001){"<0.001"}else{round(summary(RegressionChildrenInChildcare)$coefficients[,4][2],2)},
                                                       if(round(summary(RegressionIncome)$coefficients[,4][2],2) < 0.001){"<0.001"}else{round(summary(RegressionIncome)$coefficients[,4][2],2)},
                                                       if(round(summary(RegressionVoter)$coefficients[,4][2],2) < 0.001){"<0.001"}else{round(summary(RegressionVoter)$coefficients[,4][2],2)},
                                                       if(round(summary(RegressionParting)$coefficients[,4][2],2) < 0.001){"<0.001"}else{round(summary(RegressionParting)$coefficients[,4][2],2)},
                                                       if(round(summary(RegressionIncoming)$coefficients[,4][2],2) < 0.001){"<0.001"}else{round(summary(RegressionIncoming)$coefficients[,4][2],2)}))
pdf("ForestplotOneVariable.pdf", width = 12, height = 4)
forestplotDataOneVariable %>%
  forestplot::forestplot(
    labeltext = c(variable, pvalue, adjr2, AIC, BIC),
    xlab = "Standardized Slope Y/sd(X)",
    txt_gp = fpTxtGp(ticks=gpar(cex=1.1), xlab=gpar(cex=1.1)),
    xticks = c(-50, -40, -30, -20, -10, 0, 10, 20,30,40,50,60,70),
  ) %>% 
  fp_set_style(box = "royalblue",
               line = "darkblue",
               summary = "royalblue") %>%
  fp_add_header(variable = c("Explanatory Variable"),
                pvalue = c("p-value"),
                adjr2 = c("Adj. R2"),
                AIC = c("AIC"),
                BIC = c("BIC")) %>%
  fp_set_zebra_style("#EFEFEF")
dev.off()

forestplotData <-tibble::tibble(mean = c(RegressionDensUnemploymentVotesIncomeChildcare$coefficients[2], RegressionDensUnemploymentVotesIncomeChildcare$coefficients[3], RegressionDensUnemploymentVotesIncomeChildcare$coefficients[4], RegressionDensUnemploymentVotesIncomeChildcare$coefficients[5], RegressionDensUnemploymentVotesIncomeChildcare$coefficients[6]),
                                lower = c(confint(RegressionDensUnemploymentVotesIncomeChildcare)[2,1], confint(RegressionDensUnemploymentVotesIncomeChildcare)[3,1], confint(RegressionDensUnemploymentVotesIncomeChildcare)[4,1], confint(RegressionDensUnemploymentVotesIncomeChildcare)[5,1], confint(RegressionDensUnemploymentVotesIncomeChildcare)[6,1]),
                                upper = c(confint(RegressionDensUnemploymentVotesIncomeChildcare)[2,2], confint(RegressionDensUnemploymentVotesIncomeChildcare)[3,2], confint(RegressionDensUnemploymentVotesIncomeChildcare)[4,2], confint(RegressionDensUnemploymentVotesIncomeChildcare)[5,2], confint(RegressionDensUnemploymentVotesIncomeChildcare)[6,2]),
                                variable = c("Inhabitants per km2", "Unemployment Rate", "Voter Turnout", "Income per Capita", "Small Children (< 3) in Childcare"))


pdf("ForestplotFinalModel.pdf", width = 5, height = 3)
forestplotData %>%
  forestplot::forestplot(
    labeltext = c(variable),
    xlab = "Standardized Slope Y/sd(X)",
    xticks = c(-50, -25, 0, 25, 50, 75),
    txt_gp = fpTxtGp(ticks=gpar(cex=1.1), xlab=gpar(cex=1.1))
  ) %>% 
  fp_set_style(box = "royalblue",
               line = "darkblue",
               summary = "royalblue") %>%
  fp_add_header(variable = c("Explanatory Variable")) %>%
  fp_set_zebra_style("#EFEFEF")
dev.off()

pdf("AddedVariableplots.pdf", width = 9, height = 3)
car::avPlots(RegressionDensVoterIncome, id = FALSE, layout = c(1,3), cex.lab=1.5, cex.axis=1.5)
dev.off()
#Spatial Plot of Input Variables

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
                               NAME_LATN == "Nienburg (Weser)" ~ "NienburgWeser",
                               .default = NAME_LATN)) %>%
  janitor::clean_names() %>% dplyr::rowwise() %>%
  mutate(name_latn = str_split(name_latn, ",")[[1]][1]) %>%
  left_join(valuetoplot, by = join_by(name_latn == LK_Name))

pdf("Map_PopDensity.pdf", width = 6, height = 9)
densityplot <- germany_districts %>%
  ggplot(aes(geometry = geometry)) +
  geom_sf_pattern(aes(fill = log10(Inhabitantsperkm2), pattern = isna, alpha = is.na(value)), pattern_fill = "#000000", pattern_density = 0.1,
                  pattern_spacing = 0.05, pattern_scale = 0.1
  ) +
  scico::scale_fill_scico(palette = "acton") +
  scale_alpha_manual(values = c("TRUE" = 0, "FALSE" = 1), guide = "none") +
  theme_minimal() +
  xlab("") +
  ylab("") +
  scale_pattern_manual(
    values = c(
      "NA" = 'stripe',
      "no" = 'none'
    )
  ) +
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
    title = "log10(Inhabitants\nper km2)",
  ), 
  pattern = "none") +
  coord_sf(expand = FALSE)
dev.off()
pdf("Map_voterTurnour.pdf", width = 6, height = 9)
map_voter <- germany_districts %>%
  ggplot(aes(geometry = geometry)) +
  geom_sf_pattern(aes(fill = voterTurnout, pattern = isna, alpha = is.na(value)), pattern_fill = "#000000", pattern_density = 0.1,
                  pattern_spacing = 0.05, pattern_scale = 0.1
  ) +
  scale_alpha_manual(values = c("TRUE" = 0, "FALSE" = 1), guide = "none") +
  theme_minimal() +
  xlab("") +
  ylab("") +
  scico::scale_fill_scico(palette = "acton") +
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
    title = "Voter Turnout\n(in percent)"
  ), pattern = "none") +
  scale_pattern_manual(
    values = c(
      "NA" = 'stripe',
      "no" = 'none'
    )
  ) +
  coord_sf(expand = FALSE)
dev.off()
pdf("Map_Income.pdf", width = 6, height = 9)
map_income <- germany_districts %>%
  ggplot(aes(geometry = geometry)) +
  geom_sf_pattern(aes(fill = IncomePerson2022, pattern = isna, alpha = is.na(value)), pattern_fill = "#000000", pattern_density = 0.1,
                  pattern_spacing = 0.05, pattern_scale = 0.1
  ) +
  scale_alpha_manual(values = c("TRUE" = 0, "FALSE" = 1), guide = "none") +
  theme_minimal() +
  xlab("") +
  ylab("") +
  scico::scale_fill_scico(palette = "acton") +
  geom_sf_interactive(
    fill = NA, 
    aes(
      data_id = nuts_id,
      tooltip = glue::glue('{nuts_name}')
    ),
    linewidth = 0.1
  ) +
  scale_pattern_manual(
    values = c(
      "NA" = 'stripe',
      "no" = 'none'
    )
  ) +
  theme(legend.position = "bottom", text = element_text(size = 20), axis.text = element_blank(), axis.ticks = element_blank()) +
  guides(fill = guide_colourbar(
    title = "Income\nper Capita"
  ), 
  pattern = "none") +
  coord_sf(expand = FALSE)
dev.off()

ggarrange(densityplot, map_voter, map_income, labels = c("A", "B", "C"), nrow = 1, ncol = 3,font.label = list(size = 37))
ggsave("Maps.pdf", dpi = 500, w = 24, h = 10)

# Weight Analysis ---------------------------------------------------------

CaseNumbers <- read_csv("https://raw.githubusercontent.com/robert-koch-institut/COVID-19_7-Tage-Inzidenz_in_Deutschland/main/COVID-19-Faelle_7-Tage-Inzidenz_Landkreise.csv")
CaseNumbers <- CaseNumbers %>% filter(Meldedatum < as.Date("2020-06-01"))
CaseNumbers <- CaseNumbers %>% group_by(Landkreis_id) %>% slice_max(`Inzidenz_7-Tage`) 
colnames(CaseNumbers)[1] <- "Date"
colnames(CaseNumbers)[2] <- "LKNumber"

valuetoplot <- left_join(valuetoplot, CaseNumbers)
valuetoplot <- valuetoplot %>% group_by(LKNumber) %>% slice_min(Date)

NationalCases <- read_csv("https://raw.githubusercontent.com/robert-koch-institut/COVID-19_7-Tage-Inzidenz_in_Deutschland/main/COVID-19-Faelle_7-Tage-Inzidenz_Deutschland.csv")
NationalCases <- NationalCases %>% filter(Altersgruppe == "00+")
colnames(NationalCases) <- c("Date", "Agegroup", "AgegroupSize", "Cases_Nat", "Cases_New_Nat", "Cases_7Days_Nat", "Incidence_7Days_Nat")

NationalCasesRed <- NationalCases %>% filter(Date < as.Date("2020-06-01")) %>% slice_max(Incidence_7Days_Nat)

valuetoplot <- left_join(valuetoplot, NationalCases)

valuetoplot <- valuetoplot %>% mutate(DifferenceNatLoc = `Inzidenz_7-Tage` - Incidence_7Days_Nat)
valuetoplot <- valuetoplot %>% mutate(Incidence_7Days_Nat_max = 43.8)
valuetoplot <- valuetoplot %>% mutate(DifferenceNatmaxLoc = `Inzidenz_7-Tage` - Incidence_7Days_Nat_max)

ggplot(valuetoplot) + 
  geom_point(aes(x = DifferenceNatmaxLoc, y = value)) +
  theme_minimal() +
  scale_x_log10()

ggplot(valuetoplot) + 
  geom_point(aes(x = `Inzidenz_7-Tage`, y = value)) +
  theme_minimal() +
  scale_x_log10()

ggplot(valuetoplot %>% filter(DifferenceNatmaxLoc < 200)) +
  geom_point(aes(x=DifferenceNatmaxLoc, y=value, color = group_eng))

valuetoplot$group_eng <- factor(valuetoplot$group_eng, levels = c("Large City", "Small City", "Suburban/Independent Town", "Medium Rural", "Rural"))

ggplot(valuetoplot) +
  geom_boxplot(aes( y=value)) +
  ylab("Weight of\nLocal Incidence") +
  theme_minimal() +
  theme(text = element_text(size = 25)) +
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank())

ggsave("Boxplot.pdf", dpi = 500, w = 4, h = 6) 