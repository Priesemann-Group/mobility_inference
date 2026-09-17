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
incomeDf <- incomeDf %>% dplyr::select(Land, Gebietseinheit, `2020`)
colnames(incomeDf) <- c("fedStateshort", "LK_Name", "IncomePerson2020")
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

# Elderly, children in childcare ------------------------------------

#Used Deutschlandatlas from 2020
# https://www.deutschlandatlas.bund.de/SharedDocs/Downloads/DE/HA20/Deutschlandatlas_KRS1218_HA20.html

elderlySmallChildren <- read_csv2("/Users/sydney/Downloads/Deutschlandatlas2020.csv")
elderlySmallChildren <- elderlySmallChildren %>% mutate(Kreisname = case_when(
  KRS1218 == "9671000" ~ "Landkreis Aschaffenburg",
  KRS1218 == "9472000" ~ "Landkreis Bayreuth",
  KRS1218 == "9679000" ~ "Landkreis Würzburg",
  KRS1218 == "9571000" ~ "Landkreis Ansbach",
  KRS1218 == "9471000" ~ "Landkreis Bamberg",
  KRS1218 == "9473000" ~ "Landkreis Coburg",
  KRS1218 == "9573000" ~ "Landkreis Fürth",
  KRS1218 == "9475000" ~ "Landkreis Hof",
  KRS1218 == "9274000" ~ "Landkreis Landshut",
  KRS1218 == "9275000" ~ "Landkreis Passau",
  KRS1218 == "9375000" ~ "Landkreis Regensburg",
  KRS1218 == "9772000" ~ "Landkreis Augsburg",
  KRS1218 == "9678000" ~ "Landkreis Schweinfurt",
  KRS1218 == "9187000" ~ "Landkreis Rosenheim",
  KRS1218 == "8125000" ~ "Landkreis Heilbronn",
  KRS1218 == "8215000" ~ "Landkreis Karlsruhe",
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
  Kreisname == "Osnabr\xfcck" ~ "Landkreis Osnabrück",
  Kreisname == "Nienburg (Weser)" ~ "Nienburg/Weser",
  Kreisname == "Rhein-Kreis Neuss" ~ "Rhein-Neuss",
  Kreisname == "Altenkirchen (Westerwald)" ~ "Altenkirchen",
  Kreisname == "Cottbus, Stadt" ~ "Cottbus - Chóśebuz",
  Kreisname == "Darmstadt, Wissenschaftsstadt" ~ "Darmstadt",
  Kreisname == "Hagen, Stadt der FernUniversität" ~ "Hagen",
  Kreisname == "Lindau (Bodensee)" ~ "Lindau",
  Kreisname == 	"Pfaffenhofen a.d.Ilm" ~ "Pfaffenhofen an der Ilm",
  Kreisname == "Solingen, Klingenstadt" ~ "Solingen",
  Kreisname == "L\xfcbeck, Stadt" ~ "Lübeck",
  Kreisname == "Neum\xfcnster, Stadt" ~ "Neumünster",
  Kreisname == "Pl\xf6n" ~ "Plön",
  Kreisname == "Wolfenb\xfcttel" ~ "Wolfenbüttel",
  Kreisname == "G\xf6ttingen" ~ "Göttingen",
  Kreisname == "L\xfcchow-Dannenberg" ~ "Lüchow-Dannenberg",
  Kreisname == "L\xfcneburg" ~ "Lüneburg",
  Kreisname == "Rotenburg (W\xfcmme)" ~ "Rotenburg (Wümme)",
  Kreisname == "Osnabr\xfcck, Stadt" ~ "Osnabrück",
  Kreisname == "D\xfcsseldorf, Stadt" ~ "Düsseldorf",
  Kreisname == "M\xf6nchengladbach, Stadt" ~ "Mönchengladbach",
  Kreisname == "M\xfclheim an der Ruhr, Stadt" ~ "Mülheim an der Ruhr",
  Kreisname == "K\xf6ln, Stadt" ~ "Köln",
  Kreisname == "St\xe4dteregion Aachen" ~ "Städteregion Aachen",
  Kreisname == "D\xfcren" ~ "Düren",
  Kreisname == "M\xfcnster, Stadt" ~ "Münster",
  Kreisname == "G\xfctersloh" ~ "Gütersloh",
  Kreisname == "H\xf6xter" ~ "Höxter",
  Kreisname == "Minden-L\xfcbbecke" ~ "Minden-Lübbecke",
  Kreisname == "M\xe4rkischer Kreis" ~ "Märkischer Kreis",
  Kreisname ==  "Bergstra\xdfe" ~  "Bergstraße",
  Kreisname == "Gro\xdf-Gerau" ~ "Groß-Gerau",
  Kreisname == "Gie\xdfen" ~ "Gießen",
  Kreisname == "Werra-Mei\xdfner-Kreis" ~ "Werra-Meißner-Kreis",
  Kreisname == "Rhein-Hunsr\xfcck-Kreis" ~ "Rhein-Hunsrück-Kreis",
  Kreisname == "Neustadt an der Weinstra\xdfe, Stadt"  ~ "Neustadt an der Weinstraße",
  Kreisname == "Zweibr\xfccken, Stadt"  ~ "Zweibrücken",
  Kreisname == "Bad D\xfcrkheim" ~ "Bad Dürkheim",
  Kreisname ==  "S\xfcdliche Weinstra\xdfe" ~  "Südliche Weinstraße",
  Kreisname == "S\xfcdwestpfalz"  ~ "Südwestpfalz",
  Kreisname == "B\xf6blingen" ~ "Böblingen",
  Kreisname == "G\xf6ppingen" ~ "Göppingen",
  Kreisname == "Schw\xe4bisch Hall" ~ "Schwäbisch Hall",
  Kreisname == "L\xf6rrach" ~ "Lörrach",
  Kreisname == "T\xfcbingen" ~ "Tübingen",
  Kreisname == "M\xfcnchen, Stadt" ~ "München",
  Kreisname == "Weiden i.d.OPf., Stadt" ~ "Weiden in der Oberpfalz",
  Kreisname == "Alt\xf6tting" ~ "Altötting",
  Kreisname == "Bad T\xf6lz-Wolfratshausen" ~ "Bad Tölz-Wolfratshausen",
  Kreisname == "Eichst\xe4tt" ~   "Eichstätt",
  Kreisname == "F\xfcrstenfeldbruck" ~ "Fürstenfeldbruck",
  Kreisname == "M\xfchldorf a.Inn" ~ "Mühldorf am Inn",
  Kreisname == "M\xfcnchen" ~ "Landkreis München",
  Kreisname == "F\xfcrth, Stadt"  ~ "Fürth",
  Kreisname == "N\xfcrnberg, Stadt" ~ "Nürnberg",
  Kreisname == "Erlangen-H\xf6chstadt"  ~ "Erlangen-Höchstadt",
  Kreisname == "N\xfcrnberger Land" ~ "Nürnberger Land",
  Kreisname == "Wei\xdfenburg-Gunzenhausen" ~ "Weißenburg-Gunzenhausen",
  Kreisname == "W\xfcrzburg, Stadt"  ~ "Würzburg",
  Kreisname == "Rh\xf6n-Grabfeld" ~ "Rhön-Grabfeld",
  Kreisname == "Ha\xdfberge" ~ "Haßberge",
  Kreisname == "W\xfcrzburg" ~ "Landkreis Würzburg",
  Kreisname == "Kempten (Allg\xe4u), Stadt" ~ "Kempten (Allgäu)",
  Kreisname == "G\xfcnzburg" ~ "Günzburg",
  Kreisname ==  "Ostallg\xe4u" ~ "Ostallgäu",
  Kreisname ==  "Unterallg\xe4u"  ~ "Unterallgäu",
  Kreisname == "Oberallg\xe4u" ~ "Oberallgäu",
  Kreisname ==  "Regionalverband Saarbr\xfccken" ~ "Regionalverband Saarbrücken",
  Kreisname == "M\xe4rkisch-Oderland" ~ "Märkisch-Oderland",
  Kreisname ==  "Spree-Nei\xdfe" ~  "Spree-Neiße",
  Kreisname == "Teltow-Fl\xe4ming" ~ "Teltow-Fläming",
  Kreisname == "Vorpommern-R\xfcgen"  ~ "Vorpommern-Rügen",
  Kreisname ==  "G\xf6rlitz" ~ "Görlitz",
  Kreisname == "Mei\xdfen" ~ "Meißen",
  Kreisname == "S\xe4chsische Schweiz-Osterzgebirge" ~ "Sächsische Schweiz-Osterzgebirge",
  Kreisname == "Dessau-Ro\xdflau, Stadt" ~ "Dessau-Roßlau",
  Kreisname == "B\xf6rde" ~ "Börde",
  Kreisname == "Mansfeld-S\xfcdharz" ~ "Mansfeld-Südharz",
  Kreisname == "Kyffh\xe4userkreis" ~ "Kyffhäuserkreis",
  Kreisname == "S\xf6mmerda" ~ "Sömmerda",
  Kreisname == "Rendsburg-Eckernf\xf6rde" ~ "Rendsburg-Eckernförde",
  Kreisname == 	"Eifelkreis Bitburg-Pr\xfcm" ~ "Eifelkreis Bitburg-Prüm",
  .default = Kreisname
))

elderlySmallChildren <- elderlySmallChildren %>% dplyr::select(c(Kreisname, bev_18_65, bev_ue65, kbetr_u3))
colnames(elderlySmallChildren) <- c("LK_Name","share1865", "peopleover65", "childrenbelow3inprimarycare")
elderlySmallChildren$LK_Name <- str_replace(elderlySmallChildren$LK_Name, ", Kreis$", "")
elderlySmallChildren$LK_Name <- str_replace(elderlySmallChildren$LK_Name, ", Stadt$", "")
elderlySmallChildren$LK_Name <- str_replace(elderlySmallChildren$LK_Name, ", Freie und Hansestadt$", "")
elderlySmallChildren$LK_Name <- str_replace(elderlySmallChildren$LK_Name, ", kreisfreie Stadt$", "")
elderlySmallChildren$LK_Name <- str_replace(elderlySmallChildren$LK_Name, ", Landeshauptstadt$", "")
elderlySmallChildren$LK_Name <- str_replace(elderlySmallChildren$LK_Name, ", Stadtkreis$", "")
elderlySmallChildren$LK_Name <- str_replace(elderlySmallChildren$LK_Name, ", Hansestadt$", "")
RegVariables <- left_join(RegVariables, elderlySmallChildren)



# Election results --------------------------------------------------------


# Voter turnout -----------------------------------------------------------

#data from https://www.german-elections.com/election-data/
#Usage of unharmonized data

voterTurnout2017 <- read_delim("/Users/sydney/Downloads/VoterTurnout.txt")
voterTurnout2017 <- voterTurnout2017 %>% filter(year == 2017)
colnames(voterTurnout2017)[1] <- "schluessel"
colnames(voterTurnout2017)[10] <- "voterTurnout2017"
voterTurnout2017 <- voterTurnout2017 %>% select(c(schluessel, voterTurnout2017))

voterTurnout2021 <- read_delim("/Users/sydney/Downloads/VoterTurnout.txt")
voterTurnout2021 <- voterTurnout2021 %>% filter(year == 2021)
colnames(voterTurnout2021)[1] <- "schluessel"
colnames(voterTurnout2021)[10] <- "voterTurnout2021"
voterTurnout2021 <- voterTurnout2021 %>% select(c(schluessel, voterTurnout2021))

# Party votes -------------------------------------------------------------

#Data from: regionalatlas.statistikportal.de
#GENERAL ELECTION 2021
ZweitstimmeCdu2021 <- read_delim("/Users/sydney/Downloads/ZweitstimmeCDU.csv", skip=2)
colnames(ZweitstimmeCdu2021)[3] <- "CDU2021"
ZweitstimmeSpd2021 <- read_delim("/Users/sydney/Downloads/ZweitstimmeSPD.csv", skip=2)
colnames(ZweitstimmeSpd2021)[3] <- "SPD2021"
ZweitstimmeFdp2021 <- read_delim("/Users/sydney/Downloads/ZweitstimmeFDP.csv", skip=2)
colnames(ZweitstimmeFdp2021)[3] <- "FDP2021"
ZweitstimmeGruen2021 <- read_delim("/Users/sydney/Downloads/ZweitstimmeGruene.csv", skip=9)
colnames(ZweitstimmeGruen2021)[3] <- "GRUENE2021"
ZweitstimmeAfd2021 <- read_delim("/Users/sydney/Downloads/ZweitstimmeAfd.csv", skip=2)
colnames(ZweitstimmeAfd2021)[3] <- "Afd2021"
ZweitstimmeLinke2021 <- read_delim("/Users/sydney/Downloads/ZweitstimmeLinke.csv", skip=2)
colnames(ZweitstimmeLinke2021)[3] <- "Linke2021"

Zweitstimme <- left_join(ZweitstimmeCdu2021, ZweitstimmeSpd2021)
Zweitstimme <- left_join(Zweitstimme, ZweitstimmeFdp2021)
Zweitstimme <- left_join(Zweitstimme, ZweitstimmeGruen2021)
Zweitstimme <- left_join(Zweitstimme, ZweitstimmeAfd2021)
Zweitstimme <- left_join(Zweitstimme, ZweitstimmeLinke2021)
Zweitstimme <- left_join(Zweitstimme, voterTurnout2021)

#GENERAL ELECTION 2017
ZweitstimmeCdu2017 <- read_delim("/Users/sydney/Downloads/ZweitstimmeCDU2017.csv", skip=2)
colnames(ZweitstimmeCdu2017)[3] <- "CDU2017"
ZweitstimmeSpd2017 <- read_delim("/Users/sydney/Downloads/ZweitstimmeSPD2017.csv", skip=2)
colnames(ZweitstimmeSpd2017)[3] <- "SPD2017"
ZweitstimmeFdp2017 <- read_delim("/Users/sydney/Downloads/ZweitstimmeFDP2017.csv", skip=2)
colnames(ZweitstimmeFdp2017)[3] <- "FDP2017"
ZweitstimmeGruen2017 <- read_delim("/Users/sydney/Downloads/ZweitstimmeGruene2017.csv", skip=2)
colnames(ZweitstimmeGruen2017)[3] <- "GRUENE2017"
ZweitstimmeAfd2017 <- read_delim("/Users/sydney/Downloads/ZweitstimmeAfD2017.csv", skip=2)
colnames(ZweitstimmeAfd2017)[3] <- "Afd2017"
ZweitstimmeLinke2017 <- read_delim("/Users/sydney/Downloads/ZweitstimmeLinke2017.csv", skip=2)
colnames(ZweitstimmeLinke2017)[3] <- "Linke2017"

Zweitstimme <- left_join(Zweitstimme, ZweitstimmeCdu2017)
Zweitstimme <- left_join(Zweitstimme, ZweitstimmeSpd2017)
Zweitstimme <- left_join(Zweitstimme, ZweitstimmeFdp2017)
Zweitstimme <- left_join(Zweitstimme, ZweitstimmeGruen2017)
Zweitstimme <- left_join(Zweitstimme, ZweitstimmeAfd2017)
Zweitstimme <- left_join(Zweitstimme, ZweitstimmeLinke2017)
Zweitstimme <- left_join(Zweitstimme, voterTurnout2017)

Zweitstimme <- Zweitstimme %>% mutate(GRUENE2021 = case_when(regionaleinheit == "Regionalverband Saarbrücken" ~ 0.0, #Gruene Landesliste bei Bundestagswahl im Saarland nicht zugelassen --> Zweitstimme für Grüne nicht möglich
                                                         regionaleinheit == "Neunkirchen" ~ 0.0, 
                                                         regionaleinheit == "Saarlouis" ~ 0.0, 
                                                         regionaleinheit == "Merzig-Wadern" ~ 0.0, 
                                                         regionaleinheit == "Saarpfalz-Kreis" ~ 0.0, 
                                                         regionaleinheit == "St. Wendel" ~ 0.0,
                                                         .default = GRUENE2021))

Zweitstimme <- Zweitstimme %>% mutate(`Voted for Parting Government` = CDU2021 + SPD2021) %>%
  mutate(`Voted for Incoming Government` = SPD2021 + FDP2021 + GRUENE2021)


#Gewerbeanteile
ForstFischerei <- read_delim("/Users/sydney/Downloads/ForstwirtschaftFischerei2020.csv", skip = 2)
colnames(ForstFischerei)[3] <- "ForstFischerei"
ProduzierendesGewerbe <- read_delim("/Users/sydney/Downloads/ProduzierendesGewerbe2020.csv", skip = 2)
colnames(ProduzierendesGewerbe)[3] <- "ProduzierendesGewerbe"
VerarbeitendesGewerbe <- read_delim("/Users/sydney/Downloads/VerarbeitendesGewerbe2020.csv", skip = 2)
colnames(VerarbeitendesGewerbe)[3] <- "VerarbeitendesGewerbe"
Baugewerbe <- read_delim("/Users/sydney/Downloads/Baugewerbe.csv", skip = 2)
colnames(Baugewerbe)[3] <- "Baugewerbe"
Dienstleistungsgewerbe <- read_delim("/Users/sydney/Downloads/Dienstleistungsgewerbe2020.csv", skip = 2)
colnames(Dienstleistungsgewerbe)[3] <- "Dienstleistungsgewerbe"
HandelVerkehrGastgewerbe <- read_delim("/Users/sydney/Downloads/HandelVerkehrGastgewerbe2020.csv", skip = 2)
colnames(HandelVerkehrGastgewerbe)[3] <- "HandelVerkehrGastgewerbe"
FinanzVersicherung <- read_delim("/Users/sydney/Downloads/FinanzVersicherung2020.csv", skip = 2)
colnames(FinanzVersicherung)[3] <- "FinanzVersicherung"
OeffentlichSonstigeDienstleistungen <- read_delim("/Users/sydney/Downloads/OeffentlichSonstigeDienstleistungen2020.csv", skip = 2)
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

#Average age in 2020, from https://regionalatlas.statistikportal.de/
AverageAge  <- read_delim("/Users/sydney/Downloads/AverageAge2020.csv", skip=2)
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

#Beschaeftigungsquote Dec 2020, from https://statistik.arbeitsagentur.de/SiteGlobals/Forms/Suche/Einzelheftsuche_Formular.html?gtp=15084_list%253D2&topic_f=beschaeftigung-sozbe-bq-heft
BeschaeftigtenQuote <- read_delim("/Users/sydney/Downloads/Beschaeftigungsquote2020.csv", skip=9)
colnames(BeschaeftigtenQuote)[3] <- "EmploymentRate2020"
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

BeschaeftigtenQuote2021 <- read_delim("/Users/sydney/Downloads/Beschaeftigungsquote2021.csv", skip=2)
colnames(BeschaeftigtenQuote2021)[3] <- "EmploymentRate2021"
BeschaeftigtenQuote2021 <- BeschaeftigtenQuote2021  %>% mutate(regionaleinheit = case_when(
  regionaleinheit == "Mühldorf a.Inn" ~ "Mühldorf a. Inn",
  regionaleinheit == "Pfaffenhofen a.d.Ilm" ~ "Pfaffenhofen a.d. Ilm",
  regionaleinheit == "Weiden i.d.OPf." ~ "Weiden i.d. OPf.",
  regionaleinheit == "Neumarkt i.d.OPf." ~ "Neumarkt i.d. OPf.",
  regionaleinheit == "Neustadt a.d.Waldnaab" ~ "Neustadt a.d. Waldnaab",
  regionaleinheit == "Wunsiedel i.Fichtelgebirge" ~ "Wunsiedel i. Fichtelgebirge",
  regionaleinheit == "Neustadt a.d.Aisch-Bad Windsheim" ~ "Neustadt a.d. Aisch-Bad Windsheim",
  regionaleinheit == "Dillingen a.d.Donau" ~ "Dillingen a.d. Donau",
  .default = regionaleinheit))

BeschaeftigtenQuote <- left_join(BeschaeftigtenQuote, BeschaeftigtenQuote2021)

BeschaeftigtenQuote <- BeschaeftigtenQuote %>% mutate(EmploymentRate2020 = case_when(EmploymentRate2020 == 5555555555.0 ~ EmploymentRate2021, 
                                                                                     .default = EmploymentRate2020))


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

