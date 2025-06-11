# Regression Analysis -----------------------------------------------------

#Data Preprocessing -------------------------------------------------------

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
                                                        LK_Name == "Waldshut" ~ "Waldshut ",
                                                        LK_Name == "Weiden i.d.OPf." ~ "Weiden in der Oberpfalz",
                                                        LK_Name == "Wunsiedel i.Fichtelgebirge" ~ "Wunsiedel im Fichtelgebirge",
                                                        LK_Name == "Dillingen a.d.Donau" ~ "Dillingen an der Donau",
                                                        LK_Name == "Saarbrücken, Regionalverband" ~ "Regionalverband Saarbrücken",
                                                        LK_Name == "Rhein-Kreis Neuss" ~ "Rhein-Neuss",
                                                        LK_Name =="Nienburg (Weser)" ~ "NienburgWeser",
                                                        LK_Name == "Pirmasens, kreisfreie Stadt" ~ "Pirmasens",
                                                        LK_Name == "Region Hannover" ~ "Hannover",
                                                        LK_Name == "Kaiserslautern" ~ "Landkreis Kaiserslautern",
                                                        LK_Name == "Neumarkt i.d.OPf." ~ "Neumarkt in der Oberpfalz", .default = LK_Name))
popDensity$LK_Name <- str_replace(popDensity$LK_Name, ", Kreis$", "")
popDensity$LK_Name <- str_replace(popDensity$LK_Name, ", Stadt$", "")
popDensity$LK_Name <- str_replace(popDensity$LK_Name, ", Freie und Hansestadt$", "")
popDensity$LK_Name <- str_replace(popDensity$LK_Name, ", kreisfreie Stadt$", "")
popDensity$LK_Name <- str_replace(popDensity$LK_Name, ", Landeshauptstadt$", "")
popDensity$LK_Name <- str_replace(popDensity$LK_Name, ", Stadtkreis$", "")
popDensity$LK_Name <- str_replace(popDensity$LK_Name, ", Hansestadt$", "")

valuetoplot <- left_join(valuetoplot, popDensity)

# Income ------------------------------------------------------------------

# Data from
#https://www.statistikportal.de/de/vgrdl/ergebnisse-kreisebene/einkommen-kreise

incomeDf <- read_xlsx("/Users/sydney/Downloads/vgrdl_r2b3_bs2023.xlsx", sheet=13, skip = 4)
incomeDf <- incomeDf %>% select(Land, Gebietseinheit, `2022`)
colnames(incomeDf) <- c("fedStateshort", "LK_Name", "IncomePerson2022")
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
  LK_Name == 	"Nienburg (Weser), Landkreis" ~ "NienburgWeser",
  LK_Name == "Rhein-Kreis Neuss, Kreis" ~ "Rhein-Neuss",
  LK_Name == "Altenkirchen (Westerwald), Landkreis" ~ "Altenkirchen",
  LK_Name == "Mühldorf a.Inn, Landkreis" ~ "Mühldorf am Inn",
  LK_Name == "Neumarkt i.d.OPf., Landkreis" ~ "Neumarkt in der Oberpfalz",
  LK_Name == "Neustadt a.d.Aisch-Bad Windsheim, Landkreis" ~ "Neustadt an der Aisch-Bad Windsheim",
  LK_Name ==  "Neustadt a.d.Waldnaab, Landkreis"~"Neustadt an der Waldnaab",
  LK_Name == "Waldshut, Landkreis" ~ "Waldshut ",
  LK_Name == "Weiden i.d.OPf., Kreisfreie Stadt" ~ "Weiden in der Oberpfalz",
  LK_Name == "Wunsiedel i.Fichtelgebirge, Landkreis" ~ "Wunsiedel im Fichtelgebirge",
  LK_Name == "Dillingen a.d.Donau, Landkreis" ~ "Dillingen an der Donau",
  LK_Name == "Saarbrücken, Regionalverband" ~ "Regionalverband Saarbrücken",
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
incomeDf$LK_Name <- str_replace(incomeDf$LK_Name, ", Hansestadt$", "")

# incomeDf <- incomeDf %>% mutate(discreteIncome = case_when(IncomePerson2022 < 25000 ~ "<25,000",
#                                                            IncomePerson2022 < 30000 ~ "25,000-30,000",
#                                                            IncomePerson2022 < 35000 ~ "30,000-35,000",
#                                                            IncomePerson2022 > 35000 ~ ">35,000"))

valuetoplot <- left_join(valuetoplot, incomeDf, by = c("LK_Name"))

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
  Kreisname == "Nienburg (Weser)" ~ "NienburgWeser",
  Kreisname == "Waldshut" ~ "Waldshut ",
  Kreisname == "Rhein-Kreis Neuss" ~ "Rhein-Neuss",
  Kreisname == "Altenkirchen (Westerwald)" ~ "Altenkirchen",
  Kreisname == "Heilbronn" ~ "Landkreis Heilbronn",
  Kreisname == "Karlsruhe" ~ "Landkreis Karlsruhe",
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
valuetoplot <- left_join(valuetoplot, voterturnout)

# Voted right wing, average age, employment rate

#Data from: regionalatlas.statistikportal.de
ZweitstimmeAfd <- read_delim("/Users/sydney/Downloads/ZweitstimmeAfd.csv", skip=2)
colnames(ZweitstimmeAfd)[3] <- "Voted Right Wing (%)"

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

AfdAgeEmployment <- left_join(ZweitstimmeAfd, AverageAge)
AfdAgeEmployment <- left_join(AfdAgeEmployment, BeschaeftigtenQuote)

AfdAgeEmployment <- AfdAgeEmployment %>% mutate(regionaleinheit = case_when(regionaleinheit == "Aschaffenburg, Landkreis" ~ "Landkreis Aschaffenburg",
regionaleinheit == "Bayreuth, Landkreis" ~ "Landkreis Bayreuth",
regionaleinheit == "Würzburg, Landkreis" ~ "Landkreis Würzburg",
regionaleinheit == "Ansbach, Landkreis" ~ "Landkreis Ansbach",
regionaleinheit == "Bamberg, Landkreis" ~ "Landkreis Bamberg",
regionaleinheit == "Coburg, Landkreis" ~ "Landkreis Coburg",
regionaleinheit == "Fürth, Landkreis" ~ "Landkreis Fürth",
regionaleinheit == "Hof, Landkreis" ~ "Landkreis Hof",
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
regionaleinheit == "Nienburg (Weser)" ~ "NienburgWeser",
regionaleinheit =="Waldshut" ~ "Waldshut ",
regionaleinheit == "Rhein-Kreis Neuss" ~ "Rhein-Neuss",
regionaleinheit == "Altenkirchen (Westerwald)" ~ "Altenkirchen",
regionaleinheit == "Region Hannover" ~ "Hannover",
.default = regionaleinheit))
colnames(AfdAgeEmployment)[2] <- "LK_Name"

valuetoplot <- left_join(valuetoplot, AfdAgeEmployment)

#Correlation matrix
valuetoplotRed <- valuetoplot %>% select(c(value, Inhabitantsperkm2, voterTurnout, IncomePerson2022, unemploymentQuota, peopleover65, childrenbelow3inprimarycare, `Voted Right Wing (%)`, `Average Age`, `Employment Rate`))
colnames(valuetoplotRed) <- c("Integral of Exponential", "Inhabitants per km2", "Voter Turnout", "Income per Capita", "Unemployment Rate", "Share 65+ year olds", "Share <3+ year olds in Chidcare", "Share Right Wing Voters", "Average Age", "Employment Rate")
corrmat <- cor(valuetoplotRed)
pdf(height = 9, width = 12, "CorrelationPlot.pdf")
corrplot(corrmat, method = "color", tl.col="black", tl.srt=45, tl.cex = 1.8, cl.pos = "b", cl.cex=1.5)
dev.off()

#Regression Analysis

#Correlation of independent variables

cor(valuetoplot$Inhabitantsperkm2, valuetoplot$IncomePerson2022)
cor(valuetoplot$Inhabitantsperkm2, valuetoplot$voterTurnout)
#Corelations from here on forward 
cor(valuetoplot$Inhabitantsperkm2, valuetoplot$unemploymentQuota)

cor(valuetoplot$IncomePerson2022, valuetoplot$voterTurnout)
cor(valuetoplot$IncomePerson2022, valuetoplot$unemploymentQuota)

cor(valuetoplot$voterTurnout, valuetoplot$unemploymentQuota)

#Forward Selection
#One Variable Models
RegressionPopDens <- lm(value ~ Inhabitantsperkm2, data = valuetoplot)
summary(RegressionPopDens)
AIC(RegressionPopDens)
BIC(RegressionPopDens)
RegressionIncome <- lm(value ~ IncomePerson2022, data = valuetoplot)
summary(RegressionIncome)
AIC(RegressionIncome)
BIC(RegressionIncome)
RegressionVoter <- lm(value ~ voterTurnout, data = valuetoplot)
summary(RegressionVoter)
AIC(RegressionVoter)
BIC(RegressionVoter)
RegressionUnemployment <- lm(value ~ unemploymentQuota, data = valuetoplot)
summary(RegressionUnemployment)
AIC(RegressionUnemployment)
BIC(RegressionUnemployment)
#Population Density leads to the largest adj. R^2 (~ 0.23)
#We continue with the model RegressionPopDens and add the other variables one by one
#Two Variables Models
RegressionDensIncome <- lm(value ~ Inhabitantsperkm2 + IncomePerson2022, data = valuetoplot)
summary(RegressionDensIncome)
AIC(RegressionDensIncome)
BIC(RegressionDensIncome)
RegressionDensVoter <- lm(value ~ Inhabitantsperkm2 + voterTurnout, data = valuetoplot)
summary(RegressionDensVoter)
AIC(RegressionDensVoter)
BIC(RegressionDensVoter)
RegressionDensUnemployment <- lm(value ~ Inhabitantsperkm2 + unemploymentQuota, data = valuetoplot)
summary(RegressionDensUnemployment)
AIC(RegressionDensUnemployment)
BIC(RegressionDensUnemployment)
#RegressionDensIncome leads to the largest adj. R^2 (~ 0.36)
#We continue with this model
#Three Variables Models
RegressionDensVoterIncome <- lm(value ~ Inhabitantsperkm2 + voterTurnout + IncomePerson2022, data = valuetoplot)
summary(RegressionDensVoterIncome)
RegressionDensVoterUnemployment <- lm(value ~ Inhabitantsperkm2 + voterTurnout + unemploymentQuota, data = valuetoplot)
summary(RegressionDensVoterUnemployment)
#Income is significant (p<0.01) and increases adj. R^2 by ~ 1%
#Final model RegressionDensVoterIncome
valuetoplot <- valuetoplot %>% mutate(predicted = predict(RegressionDensVoterIncome))
valuetoplot <- valuetoplot %>% mutate(predictedManual = summary(RegressionDensVoterIncome)$coeff[1] +
                                        summary(RegressionDensVoterIncome)$coeff[2] * Inhabitantsperkm2 +
                                        summary(RegressionDensVoterIncome)$coeff[3] * voterTurnout +
                                        summary(RegressionDensVoterIncome)$coeff[4] * IncomePerson2022)

ggplot(valuetoplot) +
  geom_point(aes(x = value, y = predicted, color = Inhabitantsperkm2))  +
  theme_minimal() + 
  geom_abline(slope=1, intercept = 0) +
  theme(legend.position = "bottom") +
  xlab("Actual Value") +
  ylab("Value Predicted by\nRegression Model") +
  theme(text = element_text(size = 40))

ggplot(valuetoplot) +
  geom_point(aes(x = Inhabitantsperkm2, y = value)) +
  theme_minimal() +
  xlab("Inhabitants per km2") +
  ylab("Integral over exponential") +
  scale_x_log10()+
  theme(text = element_text(size = 40)) +
  geom_line(aes(x=Inhabitantsperkm2, y = predictedManual))

#Backward elimination
fullmodel <- lm(value ~ Inhabitantsperkm2 + voterTurnout + IncomePerson2022 + unemploymentQuota, data = valuetoplot)
summary(fullmodel)  
#Unemployment quota is not statistically significant (p>0.05) and is removed from the the model
fullmodelMinusUnemployment <- lm(value ~ Inhabitantsperkm2 + voterTurnout + IncomePerson2022, data = valuetoplot)
summary(fullmodelMinusUnemployment)
#All three independent variables are statistically significant. Via backwar elimination we reach the same model as via forward selection

#Branch and bound
model <- lm(value ~ ., data=valuetoplotRed)
step(model) #Backward elimination using AIC --> Again, leads to the same model

#Model selection via exhaustive search
#https://www.rdocumentation.org/packages/leaps/versions/3.2/topics/regsubsets
exhaustivesearch <- regsubsets(value ~ ., data=valuetoplotRed)
mod.summary <- summary(exhaustivesearch)
which.min(mod.summary$bic)
which.max(mod.summary$adjr2)

#Transformed Regression
valuetoplot <- valuetoplot %>% 
  mutate(Inhabitantsperkm2Standardized = (Inhabitantsperkm2 - mean(Inhabitantsperkm2))/sd(Inhabitantsperkm2)) %>%
  mutate(voterTurnoutStandardized = (voterTurnout - mean(voterTurnout))/sd(voterTurnout)) %>%
  mutate(IncomePerson2022Standardized = (IncomePerson2022 - mean(IncomePerson2022))/sd(IncomePerson2022))

StandReg <- lm(value ~ Inhabitantsperkm2Standardized + voterTurnoutStandardized + IncomePerson2022Standardized, data = valuetoplot)

StandReg$coefficients
confint(StandReg)

forestplotData <-tibble::tibble(mean = c(StandReg$coefficients[2], StandReg$coefficients[3], StandReg$coefficients[4]),
                                lower = c(confint(StandReg)[2,1], confint(StandReg)[3,1], confint(StandReg)[4,1]),
                                upper = c(confint(StandReg)[2,2], confint(StandReg)[3,2], confint(StandReg)[4,2]),
                                variable = c("Inhabitants per km2", "Voter Turnout", "Income per Capita"))

pdf("Forestplot.pdf", width = 6, height = 2.5)
forestplotData %>%
  forestplot::forestplot(
    labeltext = c(variable),
    xlab = "Standardized Slope \U0394Y/sd(X)",
    txt_gp = fpTxtGp(ticks=gpar(cex=1.2), xlab=gpar(cex=1.2))
  ) %>% 
  fp_set_style(box = "royalblue",
               line = "darkblue",
               summary = "royalblue") %>%
  fp_add_header(variable = c("Explanatory", "Variable")) %>%
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
  geom_sf(aes(fill = log10(Inhabitantsperkm2))) +
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
    title = "log10(Inhabitants per km2)"
  )) +
  coord_sf(expand = FALSE)
dev.off()
pdf("Map_voterTurnour.pdf", width = 6, height = 9)
map_voter <- germany_districts %>%
  ggplot(aes(geometry = geometry)) +
  geom_sf(aes(fill = voterTurnout)) +
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
    title = "Voter Turnout (in percent)"
  )) +
  coord_sf(expand = FALSE)
dev.off()
pdf("Map_Income.pdf", width = 6, height = 9)
map_income <- germany_districts %>%
  ggplot(aes(geometry = geometry)) +
  geom_sf(aes(fill = IncomePerson2022)) +
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
    title = "Income per Capita"
  )) +
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

ggsave("BoxplotWeight.pdf", dpi = 500, w = 4, h = 6) 