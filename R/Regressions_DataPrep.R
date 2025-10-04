library(corrplot)
library(tidyverse)
library(readxl)
library(here)
library(lme4)
library(partR2)

here()

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

RegVariables <- popDensity

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

RegVariables <- left_join(RegVariables, incomeDf, by = c("LK_Name"))

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
voterturnout <- voterturnout %>% dplyr::select(c(Kreisname, wahl_beteil, alq, bev_18_65, bev_ue65, kbetr_u3))
colnames(voterturnout) <- c("LK_Name", "voterTurnout", "unemploymentQuota", "share1865", "peopleover65", "childrenbelow3inprimarycare")
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
RegVariables <- left_join(RegVariables, voterturnout)

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


#Gewerbeanteile
ForstFischerei <- read_delim("/Users/sydney/Downloads/ForstwirtschaftFischerei.csv", skip = 2)
colnames(ForstFischerei)[3] <- "ForstFischerei"
ProduzierendesGewerbe <- read_delim("/Users/sydney/Downloads/ProduzierendesGewerbe.csv", skip = 2)
colnames(ProduzierendesGewerbe)[3] <- "ProduzierendesGewerbe"
VerarbeitendesGewerbe <- read_delim("/Users/sydney/Downloads/VerarbeitendesGewerbe.csv", skip = 2)
colnames(VerarbeitendesGewerbe)[3] <- "VerarbeitendesGewerbe"
Baugewerbe <- read_delim("/Users/sydney/Downloads/Baugewerbe.csv", skip = 2)
colnames(Baugewerbe)[3] <- "Baugewerbe"
Dienstleistungsgewerbe <- read_delim("/Users/sydney/Downloads/Dienstleistungsgewerbe.csv", skip = 2)
colnames(Dienstleistungsgewerbe)[3] <- "Dienstleistungsgewerbe"
HandelVerkehrGastgewerbe <- read_delim("/Users/sydney/Downloads/HandelVerkehrGastgewerbe.csv", skip = 2)
colnames(HandelVerkehrGastgewerbe)[3] <- "HandelVerkehrGastgewerbe"
FinanzVersicherung <- read_delim("/Users/sydney/Downloads/FinanzVersicherung.csv", skip = 2)
colnames(FinanzVersicherung)[3] <- "FinanzVersicherung"
OeffentlichSonstigeDienstleistungen <- read_delim("/Users/sydney/Downloads/OeffentlichSonstigeDienstleistungen.csv", skip = 2)
colnames(OeffentlichSonstigeDienstleistungen)[3] <- "OeffentlichSonstigeDienstleistungen"

Gewerbe <- left_join(ForstFischerei, ProduzierendesGewerbe)
Gewerbe <- left_join(Gewerbe, VerarbeitendesGewerbe)
Gewerbe <- left_join(Gewerbe, Baugewerbe)
Gewerbe <- left_join(Gewerbe, Dienstleistungsgewerbe)
Gewerbe <- left_join(Gewerbe, HandelVerkehrGastgewerbe)
Gewerbe <- left_join(Gewerbe, FinanzVersicherung)
Gewerbe <- left_join(Gewerbe, OeffentlichSonstigeDienstleistungen)

Gewerbe <- Gewerbe  %>% mutate(regionaleinheit = case_when(
  regionaleinheit == "Mühldorf a.Inn" ~ "Mühldorf a. Inn",
  regionaleinheit == "Pfaffenhofen a.d.Ilm" ~ "Pfaffenhofen a.d. Ilm",
  regionaleinheit == "Weiden i.d.OPf." ~ "Weiden i.d. OPf.",
  regionaleinheit == "Neumarkt i.d.OPf." ~ "Neumarkt i.d. OPf.",
  regionaleinheit == "Neustadt a.d.Waldnaab" ~ "Neustadt a.d. Waldnaab",
  regionaleinheit == "Wunsiedel i.Fichtelgebirge" ~ "Wunsiedel i. Fichtelgebirge",
  regionaleinheit == "Neustadt a.d.Aisch-Bad Windsheim" ~ "Neustadt a.d. Aisch-Bad Windsheim",
  regionaleinheit == "Dillingen a.d.Donau" ~ "Dillingen a.d. Donau",
  .default = regionaleinheit))


# Detailed Analysis Arbeitslosenquote -------------------------------------

#Data downloaded from https://statistik.arbeitsagentur.de/SiteGlobals/Forms/Suche/Einzelheftsuche_Formular.html?nn=1610104&topic_f=gemeinde-arbeitslose-quoten
Alq2019 <- read_xlsx("/Users/sydney/Downloads/Arbeitslosenquote2019.xlsx", sheet = 4, skip = 10)
colnames(Alq2019)[1] <- "regionaleinheit"
colnames(Alq2019)[3] <- "Alq2019"
Alq2019 <- Alq2019 %>% dplyr::select(regionaleinheit, Alq2019)
Alq2020 <- read_xlsx("/Users/sydney/Downloads/Arbeitslosenquote2020.xlsx", sheet = 4, skip = 10)
colnames(Alq2020)[1] <- "regionaleinheit"
colnames(Alq2020)[3] <- "Alq2020"
Alq2020 <- Alq2020 %>% dplyr::select(regionaleinheit, Alq2020)
Alq2021 <- read_xlsx("/Users/sydney/Downloads/Arbeitslosenquote2021.xlsx", sheet = 4, skip = 10)
colnames(Alq2021)[1] <- "regionaleinheit"
colnames(Alq2021)[3] <- "Alq2021"
Alq2021 <- Alq2021 %>% dplyr::select(regionaleinheit, Alq2021)

#Data from https://statistik.arbeitsagentur.de/SiteGlobals/Forms/Suche/Einzelheftsuche_Formular.html?gtp=15084_list%253D4&regiontype_f=BA&topic_f=kurzarbeit
Kurz042020 <- read_xlsx("/Users/sydney/Downloads/KurzarbeitApril2020.xlsx", sheet = "Tab-08-KR-Anz-Betr-Pers", skip = 9)
colnames(Kurz042020)[1] <- "regionaleinheit"
colnames(Kurz042020)[6] <- "Kurz042020"
Kurz042020 <- Kurz042020%>% dplyr::select(regionaleinheit, Kurz042020)

Kurz052020 <- read_xlsx("/Users/sydney/Downloads/KurzarbeitMai2020.xlsx", sheet = "Tab-08-KR-Anz-Betr-Pers", skip = 12)
colnames(Kurz052020)[1] <- "regionaleinheit"
colnames(Kurz052020)[6] <- "Kurz052020"
Kurz052020 <- Kurz052020%>% dplyr::select(regionaleinheit, Kurz052020)

Alq2019 <- left_join(Alq2019, Alq2020)
Alq2019 <- left_join(Alq2019, Alq2021)
Alq2019 <- left_join(Alq2019, Kurz042020)
Alq2019 <- left_join(Alq2019, Kurz052020)
Alq2019$regionaleinheit <- substr(Alq2019$regionaleinheit, 7, nchar(Alq2019$regionaleinheit))

Alq2019 <- Alq2019 %>% mutate(regionaleinheit = case_when(
  regionaleinheit == "München" ~ "Landkreis München",
  regionaleinheit ==  "Karlsruhe" ~ "Landkreis Karlsruhe",
  regionaleinheit == "Leipzig" ~ "Landkreis Leipzig",
  regionaleinheit == "Oldenburg (Oldenburg), Stadt" ~ "Oldenburg",
  regionaleinheit == "Oldenburg" ~ "Landkreis Oldenburg",
  regionaleinheit == "Osnabrück" ~ "Landkreis Osnabrück",
  regionaleinheit ==  "Augsburg" ~ "Landkreis Augsburg",
  regionaleinheit ==  "Landshut" ~ "Landkreis Landshut",
  regionaleinheit ==  "Rosenheim" ~ "Landkreis Rosenheim",
  regionaleinheit ==  "Regensburg" ~ "Landkreis Regensburg",
  regionaleinheit ==  "Kaiserslautern" ~ "Landkreis Kaiserslautern",
  regionaleinheit ==  "Würzburg" ~ "Landkreis Würzburg",
  regionaleinheit ==  "Aschaffenburg" ~ "Landkreis Aschaffenburg",
  regionaleinheit ==  "Schweinfurt" ~ "Landkreis Schweinfurt",
  regionaleinheit ==  "Passau" ~ "Landkreis Passau",
  regionaleinheit ==  "Hof" ~ "Landkreis Hof",
  regionaleinheit ==  "Heilbronn" ~ "Landkreis Heilbronn",
  regionaleinheit ==  "Fürth" ~ "Landkreis Fürth",
  regionaleinheit ==  "Coburg" ~ "Landkreis Coburg",
  regionaleinheit ==  "Bayreuth" ~ "Landkreis Bayreuth",
  regionaleinheit ==  "Bamberg" ~ "Landkreis Bamberg",
  regionaleinheit ==  "Ansbach" ~ "Landkreis Ansbach",
  regionaleinheit ==  "Region Hannover" ~ "Hannover",
  regionaleinheit == 	"Nienburg (Weser)" ~ "Nienburg/Weser",
  regionaleinheit == "Rhein-Kreis Neuss" ~ "Rhein-Neuss",
  regionaleinheit == "Kassel" ~ "Landkreis Kassel",
  regionaleinheit == "Kassel, documenta-Stadt" ~ "Kassel",
  regionaleinheit == "Altenkirchen (Westerwald)" ~ "Altenkirchen",
  regionaleinheit == "Mühldorf a.Inn" ~ "Mühldorf am Inn",
  regionaleinheit == "Neumarkt i.d.OPf." ~ "Neumarkt in der Oberpfalz",
  regionaleinheit == "Neustadt a.d.Aisch-Bad Windsh." ~ "Neustadt an der Aisch-Bad Windsheim",
  regionaleinheit ==  "Neustadt a.d.Waldnaab"~"Neustadt an der Waldnaab",
  regionaleinheit == "Waldshut" ~ "Waldshut",
  regionaleinheit == "Weiden i.d.OPf., Stadt" ~ "Weiden in der Oberpfalz",
  regionaleinheit == "Wunsiedel i.Fichtelgebirge" ~ "Wunsiedel im Fichtelgebirge",
  regionaleinheit == "Dillingen a.d.Donau" ~ "Dillingen an der Donau",
  regionaleinheit == "Saarbrücken, Regionalverband" ~ "Regionalverband Saarbrücken",
  regionaleinheit == "Cottbus, Stadt" ~ "Cottbus - Chóśebuz",
  regionaleinheit == "Darmstadt, Wissenschaftsstadt, Kreisfreie Stadt" ~ "Darmstadt",
  regionaleinheit == "Hagen, Stadt der FernUniversität" ~ "Hagen",
  regionaleinheit == "Lindau (Bodensee)" ~ "Lindau",
  regionaleinheit == 	"Pfaffenhofen a.d.Ilm" ~ "Pfaffenhofen an der Ilm",
  regionaleinheit == "Solingen, Kreisfreie Stadt" ~ "Solingen",
  regionaleinheit == "Sächs. Schweiz-Osterzgebirge" ~ "Sächsische Schweiz-Osterzgebirge",
  .default = regionaleinheit
))

Alq2019$regionaleinheit <- str_replace(Alq2019$regionaleinheit, ", Stadtkreis$", "")
Alq2019$regionaleinheit <- str_replace(Alq2019$regionaleinheit, ", kreisfreie Stadt$", "")
Alq2019$regionaleinheit <- str_replace(Alq2019$regionaleinheit, ", kreisfr. Stadt$", "")
Alq2019$regionaleinheit <- str_replace(Alq2019$regionaleinheit, ", Kreis$", "")
Alq2019$regionaleinheit <- str_replace(Alq2019$regionaleinheit, ", Landeshauptstadt$", "")

Alq2019$regionaleinheit <- str_replace(Alq2019$regionaleinheit, ", Universitätsstadt$", "")
Alq2019$regionaleinheit <- str_replace(Alq2019$regionaleinheit, ", Hansestadt$", "")
Alq2019$regionaleinheit <- str_replace(Alq2019$regionaleinheit, ", Wissenschaftsstadt", "")
Alq2019$regionaleinheit <- str_replace(Alq2019$regionaleinheit, ", Hansestadt$", "")
Alq2019$regionaleinheit <- str_replace(Alq2019$regionaleinheit, ", Freie und Hansestadt$", "")
Alq2019$regionaleinheit <- str_replace(Alq2019$regionaleinheit, ", Stadt$", "")
Alq2019$regionaleinheit <- str_replace(Alq2019$regionaleinheit, ", Klingenstadt$", "")
Alq2019$regionaleinheit <- str_replace(Alq2019$regionaleinheit, ", Stadt der FernUniversi.$", "")
Alq2019$regionaleinheit <- str_replace(Alq2019$regionaleinheit, ", kr.f. St.$", "")
Alq2019$regionaleinheit <- str_replace(Alq2019$regionaleinheit, ",St.$", "")
Alq2019$regionaleinheit <- str_replace(Alq2019$regionaleinheit, ", St.$", "")

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
AfdAgeEmployment <- left_join(AfdAgeEmployment, Gewerbe)

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

AfdAgeEmployment <- left_join(AfdAgeEmployment, Alq2019)

colnames(AfdAgeEmployment)[2] <- "LK_Name"

RegVariables <- left_join(RegVariables, AfdAgeEmployment)

RegVariables$Kurz042020 <- as.numeric(RegVariables$Kurz042020)
RegVariables$Kurz052020 <- as.numeric(RegVariables$Kurz052020)
RegVariables <- RegVariables %>% mutate(Kurz042020Rel = Kurz042020/(Inhabitants*share1865/100)) %>% 
  mutate(Kurz052020Rel = Kurz052020/(Inhabitants*share1865/100)) %>% 
  mutate(Alq20192021Abs = (Alq2021 - Alq2019)) %>%
  mutate(Alq20192020Abs = (Alq2020 - Alq2019)) 

