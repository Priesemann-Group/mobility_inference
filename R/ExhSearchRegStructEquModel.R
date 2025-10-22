#Cases by district type
library(forestplot)
library(corrplot)
library(tidyverse)
library(lavaan)
library(furrr)
library(olsrr)

plan(multisession, workers = 8)

#Data Preprocessing -------------------------------------------------------

model <- "fourhundred"

consideredWave <- "firstwave"

outcomeVariable <- "exponential"
run <- "2025-09-14_400_cluster_expdecay_wideealpha"

source("Postprocessing_Clean.R")

disFac_post <- postprocessing_clean(model, consideredWave, run, outcomeVariable)

source("Regressions_DataPrep.R")

LKType <- read_xlsx("/Users/sydney/Downloads/raumgliederungen-referenzen-2023.xlsx", sheet = 4)
LKType <- LKType %>% mutate(KRS_NAME = case_when(KRS_NAME == "Dillingen a.d.Donau" ~ "Dillingen an der Donau",
                                                 KRS_NAME == "Augsburg" ~ "Landkreis Augsburg",
                                                 KRS_NAME == "Leipzig" ~ "Landkreis Leipzig",
                                                 KRS_NAME == "Schweinfurt" ~ "Landkreis Schweinfurt",
                                                 KRS_NAME == "Würzburg" ~ "Landkreis Würzburg",
                                                 KRS_NAME == "Ansbach" ~ "Landkreis Ansbach",
                                                 KRS_NAME == "Aschaffenburg" ~ "Landkreis Aschaffenburg",
                                                 KRS_NAME == "Bamberg" ~ "Landkreis Bamberg",
                                                 KRS_NAME == "Bayreuth" ~ "Landkreis Bayreuth",
                                                 KRS_NAME == "Mühldorf a.Inn" ~ "Mühldorf am Inn",
                                                 KRS_NAME == "Oldenburg (Oldenburg), Stadt" ~ "Oldenburg",
                                                 KRS_NAME == "Coburg" ~ "Landkreis Coburg",
                                                 KRS_NAME == "Fürth" ~ "Landkreis Fürth",
                                                 KRS_NAME == "Heilbronn" ~ "Landkreis Heilbronn",
                                                 KRS_NAME == "Hof" ~ "Landkreis Hof",
                                                 KRS_NAME == "Karlsruhe" ~ "Landkreis Karlsruhe",
                                                 KRS_NAME == "Landshut" ~ "Landkreis Landshut",
                                                 KRS_NAME == "München" ~ "Landkreis München",
                                                 KRS_NAME == "Oldenburg" ~ "Landkreis Oldenburg",
                                                 KRS_NAME == "Osnabrück" ~ "Landkreis Osnabrück",
                                                 KRS_NAME == "Passau" ~ "Landkreis Passau",
                                                 KRS_NAME == "Regensburg" ~ "Landkreis Regensburg",
                                                 KRS_NAME == "Altenkirchen (Westerwald)" ~ "Altenkirchen",
                                                 KRS_NAME == "Frankenthal (Pfalz), kreisfreie Stadt" ~ "Frankenthal (Pfalz)",
                                                 KRS_NAME == "Region Hannover" ~ "Hannover",
                                                 KRS_NAME == "Lübeck, Hansestadt" ~ "Lübeck",
                                                 KRS_NAME == "Koblenz, kreisfreie Stadt" ~ "Koblenz",
                                                 KRS_NAME == "Mainz, kreisfreie Stadt" ~ "Mainz",
                                                 KRS_NAME == "Mühldorf a.Inn" ~ "Mühldorf",
                                                 KRS_NAME == "Neumarkt i.d.OPf." ~ "Neumarkt in der Oberpfalz",
                                                 KRS_NAME == "Neustadt a.d.Aisch-Bad Windsheim" ~ "Neustadt an der Aisch-Bad Windsheim",
                                                 KRS_NAME == "Neustadt a.d.Waldnaab" ~ "Neustadt an der Waldnaab",
                                                 KRS_NAME == "Neustadt an der Weinstraße, kreisfreie Stadt" ~ "Neustadt an der Weinstraße",
                                                 KRS_NAME == "Nienburg (Weser)" ~ "Nienburg/Weser",
                                                 KRS_NAME == "Pirmasens, kreisfreie Stadt" ~ "Pirmasens",
                                                 KRS_NAME == "Rhein-Kreis Neuss" ~ "Rhein-Neuss",
                                                 KRS_NAME == "Speyer, kreisfreie Stadt" ~ "Speyer",
                                                 KRS_NAME == "Trier, kreisfreie Stadt" ~ "Trier",
                                                 KRS_NAME == "Waldshut" ~ "Waldshut",
                                                 KRS_NAME == "Weiden i.d.OPf." ~ "Weiden in der Oberpfalz",
                                                 KRS_NAME == "Worms, kreisfreie Stadt" ~ "Worms",
                                                 KRS_NAME == "Wunsiedel i.Fichtelgebirge" ~ "Wunsiedel im Fichtelgebirge",
                                                 KRS_NAME == "Zweibrücken, kreisfreie Stadt" ~ "Zweibrücken",
                                                 KRS_NAME == "Landau in der Pfalz, kreisfreie Stadt" ~ "Landau in der Pfalz",
                                                 KRS_NAME == "Cottbus, Stadt" ~ "Cottbus - Chóśebuz",
                                                 KRS_NAME == "Darmstadt, Wissenschaftsstadt" ~ "Darmstadt",
                                                 KRS_NAME == "Hagen, Stadt der FernUniversität" ~ "Hagen",
                                                 KRS_NAME == "Kaiserslautern" ~ "Landkreis Kaiserslautern",
                                                 KRS_NAME == "Kaiserslautern, kreisfreie Stadt" ~ "Kaiserslautern",
                                                 KRS_NAME == "Kassel, documenta-Stadt" ~ "Kassel",
                                                 KRS_NAME == "Kassel" ~ "Landkreis Kassel",
                                                 KRS_NAME == "Rosenheim" ~ "Landkreis Rosenheim",
                                                 KRS_NAME == "Lindau (Bodensee)" ~ "Lindau",
                                                 KRS_NAME == "Ludwigshafen am Rhein, kreisfreie Stadt" ~ "Ludwigshafen am Rhein",
                                                 KRS_NAME == "Pfaffenhofen a.d.Ilm" ~ "Pfaffenhofen an der Ilm",
                                                 KRS_NAME == "Solingen, Klingenstadt" ~ "Solingen",
                                                 .default = KRS_NAME))
LKType$KRS_NAME <- str_replace(LKType$KRS_NAME, ", Stadt$", "")
LKType$KRS_NAME <- str_replace(LKType$KRS_NAME, ", Stadtkreis$", "")
LKType$KRS_NAME <- str_replace(LKType$KRS_NAME, ", Landeshauptstadt$", "")
LKType$KRS_NAME <- str_replace(LKType$KRS_NAME, ", Freie und Hansestadt$", "")

LKType <- LKType %>% dplyr::select(KRS_NAME, KTD_NAME)
colnames(LKType) <- c("LK_Name", "group")

cases <- read_csv("/Users/sydney/git/mobility_inference/data/input_data_hierarchical/inputData_fourhundred.csv")

cases <- left_join(cases, LKType)

cases <- cases %>%
  mutate(group_eng = case_when(group == "Große kreisfreie Großstadt" ~ "Large\ncity",
                               group == "Kleine kreisfreie Großstadt" ~ "Small\ncity",
                               group == "Städtischer Kreis" ~ "Suburban/\nindependent\ntown",
                               group == "Ländlicher Kreis mit Verdichtungsansätzen" ~ "Medium\nrural",
                               group == "Dünn besiedelter ländlicher Kreis" ~ "Rural"))

#First wave

cases_firstWave <- cases %>% filter(date < as.Date("2020-06-01")) %>% group_by(LK_Name) %>% summarise(Firstwave90percentile = quantile(Infection_Incidence, 0.9), wave_height = max(Infection_Incidence), corresponding_value = date[which.max(Infection_Incidence)], group_eng = group_eng) 

cases_firstWave$group_eng <- factor(cases_firstWave $group_eng, levels = c("Large\ncity", "Small\ncity", "Suburban/\nindependent\ntown", "Medium\nrural", "Rural"))

cases_firstWave <- cases_firstWave %>% ungroup()
cases_firstWave <- left_join(cases_firstWave, RegVariables, by = "LK_Name")
cases_firstWave <- left_join(cases_firstWave, disFac_post, by = "LK_Name")
cases_firstWave <- cases_firstWave %>% unique()

#Second Wave

cases_secondWave <- cases %>% filter(date > as.Date("2020-09-01")) %>% group_by(LK_Name) %>% summarise(Secondwave90percentile = quantile(Infection_Incidence, 0.9), wave_height = max(Infection_Incidence), corresponding_value = date[which.max(Infection_Incidence)], group_eng =group_eng) 

cases_secondWave <- cases_secondWave %>% unique() 

#Combination

valuetoplotRed <- left_join(cases_firstWave, cases_secondWave, by = "LK_Name")
                             
valuetoplotRed <- valuetoplotRed %>% mutate(Inhabitantsperkm2 = scale(Inhabitantsperkm2)) %>%
                               mutate(voterTurnout = scale(voterTurnout)) %>%
                               mutate(IncomePerson2022 = scale(IncomePerson2022)) %>%
                               mutate(peopleover65 = scale(peopleover65)) %>%
                               mutate(childrenbelow3inprimarycare = scale(childrenbelow3inprimarycare)) %>%
                               mutate(`Voted for Parting Government` = scale(`Voted for Parting Government`)) %>%
                               mutate(`Voted for Incoming Government` = scale(`Voted for Incoming Government`)) %>%
                               mutate(CDU = scale(CDU)) %>%
                               mutate(SPD = scale(SPD)) %>%
                               mutate(FDP = scale(FDP)) %>%
                               mutate(GRUENE = scale(GRUENE)) %>%
                               mutate(AFD = scale(Afd)) %>%
                               mutate(LINKE = scale(Linke)) %>%
                               mutate(CDU2017 = scale(CDU2017)) %>%
                               mutate(SPD2017 = scale(SPD2017)) %>%
                               mutate(FDP2017 = scale(FDP2017)) %>%
                               mutate(GRUENE2017 = scale(GRUENE2017)) %>%
                               mutate(AFD2017 = scale(Afd2017)) %>%
                               mutate(LINKE2017 = scale(Linke2017)) %>%
                               mutate(`Average Age` = scale(`Average Age`)) %>%
                               mutate(`Employment Rate` = scale(`Employment Rate`)) %>%
                               mutate(value = scale(value)) %>%
                               mutate(valueInitWave = scale(valueInitWave)) %>%
                               mutate(valueSecondWave = scale(valueSecondWave)) %>%
                               mutate(Alq2020 = scale(Alq2020)) %>%
                               mutate(ForstFischerei = scale(ForstFischerei)) %>%
                               mutate(ProduzierendesGewerbe = scale(ProduzierendesGewerbe)) %>%
                               mutate(VerarbeitendesGewerbe = scale(VerarbeitendesGewerbe)) %>%
                               mutate(Baugewerbe = scale(Baugewerbe)) %>%
                               mutate(Dienstleistungsgewerbe = scale(Dienstleistungsgewerbe)) %>%
                               mutate(HandelVerkehrGastgewerbe = scale(HandelVerkehrGastgewerbe)) %>%
                               mutate(FinanzVersicherung = scale(FinanzVersicherung)) %>%
                               mutate(OeffentlichSonstigeDienstleistungen = scale(OeffentlichSonstigeDienstleistungen)) %>%
                               mutate(Firstwave90percentile = scale (Firstwave90percentile)) %>%
                               mutate(Secondwave90percentile = scale (Secondwave90percentile))
          


models <- list(
  modelOverall2021 = value ~  Inhabitantsperkm2 + voterTurnout + IncomePerson2022 + childrenbelow3inprimarycare + 
       CDU + SPD + GRUENE + FDP + AFD + LINKE + 
     peopleover65 + `Employment Rate` + `Average Age` + Alq2020 + 
       ForstFischerei + ProduzierendesGewerbe  + Baugewerbe + Dienstleistungsgewerbe + HandelVerkehrGastgewerbe + FinanzVersicherung, 
  modelOverall2017 = value ~  Inhabitantsperkm2 + voterTurnout + IncomePerson2022 + childrenbelow3inprimarycare + 
    CDU2017 + SPD2017 + GRUENE2017 + FDP2017 + AFD2017 + LINKE2017 + 
    peopleover65 + `Employment Rate` + `Average Age` + Alq2020 + 
    ForstFischerei + ProduzierendesGewerbe  + Baugewerbe + Dienstleistungsgewerbe + HandelVerkehrGastgewerbe + FinanzVersicherung, 
  modelFirstWave2021 = valueInitWave ~  Inhabitantsperkm2 + voterTurnout + IncomePerson2022 + childrenbelow3inprimarycare + 
       CDU + SPD + GRUENE + FDP + AFD + LINKE +
       peopleover65 + `Employment Rate` + `Average Age` + Alq2020 + 
       ForstFischerei + ProduzierendesGewerbe  + Baugewerbe + Dienstleistungsgewerbe + HandelVerkehrGastgewerbe + FinanzVersicherung,
  modelFirstWave2017 = valueInitWave ~  Inhabitantsperkm2 + voterTurnout + IncomePerson2022 + childrenbelow3inprimarycare + 
    CDU2017 + SPD2017 + GRUENE2017 + FDP2017 + AFD2017 + LINKE2017 +
    peopleover65 + `Employment Rate` + `Average Age` + Alq2020 + 
    ForstFischerei + ProduzierendesGewerbe  + Baugewerbe + Dienstleistungsgewerbe + HandelVerkehrGastgewerbe + FinanzVersicherung,
  modelSecondWave2021 = valueSecondWave ~  Inhabitantsperkm2 + voterTurnout + IncomePerson2022 + childrenbelow3inprimarycare + 
  CDU + SPD + GRUENE + FDP + AFD + LINKE + 
    peopleover65 + `Employment Rate` + `Average Age` + Alq2020 + 
    ForstFischerei + ProduzierendesGewerbe  + Baugewerbe + Dienstleistungsgewerbe + HandelVerkehrGastgewerbe + FinanzVersicherung, 
  modelSecondWave2017 = valueSecondWave ~  Inhabitantsperkm2 + voterTurnout + IncomePerson2022 + childrenbelow3inprimarycare + 
    CDU2017 + SPD2017 + GRUENE2017 + FDP2017 + AFD2017 + LINKE2017 + 
    peopleover65 + `Employment Rate` + `Average Age` + Alq2020 + 
    ForstFischerei + ProduzierendesGewerbe  + Baugewerbe + Dienstleistungsgewerbe + HandelVerkehrGastgewerbe + FinanzVersicherung, 
  model4 = Firstwave90percentile ~ valueInitWave + Inhabitantsperkm2 + voterTurnout + IncomePerson2022+ childrenbelow3inprimarycare + 
       CDU + SPD + GRUENE + FDP + AFD + LINKE +
     peopleover65 + `Employment Rate` + `Average Age` + Alq2020 + 
       ForstFischerei + ProduzierendesGewerbe  + Baugewerbe + Dienstleistungsgewerbe + HandelVerkehrGastgewerbe + FinanzVersicherung, 
  model5 = Secondwave90percentile ~ valueSecondWave + Inhabitantsperkm2 + voterTurnout + IncomePerson2022 + childrenbelow3inprimarycare + 
       CDU + SPD + GRUENE + FDP + AFD + LINKE +
     peopleover65 + `Employment Rate` + `Average Age` + Alq2020 + 
       ForstFischerei + ProduzierendesGewerbe  + Baugewerbe + Dienstleistungsgewerbe + HandelVerkehrGastgewerbe + FinanzVersicherung 
)

results <- future_map(models, ~{
  fit <- lm(.x, data = valuetoplotRed)
  ols_step_best_subset(fit, metric = "adjr")
})



# Lavaan -> Reaction Strength ----------------------------------------------
colnames(valuetoplotRed)[36] <- "AverageAge"
colnames(valuetoplotRed)[37] <- "EmploymentRate"

results$model1
#Best statistics obsvered for the 9-variable model
#A_names <- c("Inhabitantsperkm2", "voterTurnout", "IncomePerson2022", "GRUENE", "FDP", "peopleover65", "Alq2020", "ForstFischerei", "FinanzVersicherung")
B_name <- "Firstwave90percentile"
C_name <- "value"

a_lab <- paste0("a", 1:9)   # A -> B
c_lab <- paste0("c", 1:9)   # A -> C

B_eq <- paste("value ~", paste(paste0(a_lab, "*", A_names), collapse = " + "), "+1")
C_eq <- paste("Firstwave90percentile ~ b*value +", paste(paste0(c_lab, "*", A_names), collapse = " + "), "+1") 

# define indirect and total effects for each Aj
ind_defs <- paste(paste0("ind_", A_names, " := ", a_lab, "*b"), collapse = "\n")
tot_defs <- paste(paste0("tot_", A_names, " := ", c_lab, " + ind_", A_names), collapse = "\n")

model <- paste(B_eq, C_eq, ind_defs, tot_defs, sep = "\n")

fitReacStrengthMedFirstWave <- sem(model,
           data = valuetoplotRed,
           fixed.x = TRUE,        # treat A's as fixed exogenous
           se = "bootstrap",
           bootstrap = 1000)

summary(fitReacStrengthMedFirstWave, standardized = TRUE, ci = TRUE)
#Surprising: Pos coefficient of voter turnout, income

#Repeating lavaan using Incidence Second Wave instead

B_eq <- paste("value ~", paste(paste0(a_lab, "*", A_names), collapse = " + "), "+1")
C_eq <- paste("Secondwave90percentile ~ b*value +", paste(paste0(c_lab, "*", A_names), collapse = " + "), "+1") 

# define indirect and total effects for each Aj
ind_defs <- paste(paste0("ind_", A_names, " := ", a_lab, "*b"), collapse = "\n")
tot_defs <- paste(paste0("tot_", A_names, " := ", c_lab, " + ind_", A_names), collapse = "\n")

model <- paste(B_eq, C_eq, ind_defs, tot_defs, sep = "\n")

fitReacStrengthMedSecondWave <- sem(model,
                       data = valuetoplotRed,
                       fixed.x = TRUE,        # treat A's as fixed exogenous
                       se = "bootstrap",
                       bootstrap = 1000)

summary(fitReacStrengthMedSecondWave, standardized = TRUE, ci = TRUE)
#Again: Pos coefficient of voter turnout
#FDP and peopleover65 change sign, as well as Alq2020 and FinanzVersicherung

# Lavaan -> Reaction Strength FIRST WAVE -----------------------------------

bestsubset <- results$model2

subset_summary <- cbind(bestsubset$metrics[4], bestsubset$metrics[5], bestsubset$metrics[6], bestsubset$metrics[7], bestsubset$metrics[8], bestsubset$metrics[9], bestsubset$metrics[10], bestsubset$metrics[11],
                        bestsubset$metrics[12], bestsubset$metrics[13],  bestsubset$metrics[14])
subset_summary <- round(subset_summary, 4)

subset_summary <- subset_summary %>% mutate(nrow = row_number()) %>% pivot_longer(cols=c(rsquare, adjr, predrsq, cp, aic, sbic, sbc, msep, fpe, apc, hsp))

subset_summary <- subset_summary %>% group_by(name) %>%
  mutate(is_max = ifelse(value == max(value), 1, 0)) %>% 
  mutate(is_min = ifelse(value == min(value), 1, 0))

subset_summary <- subset_summary %>% mutate(is_opt = case_when(name %in% c("rsquare", "adjr", "predrsq") ~ is_max,
                                                               name %in% c("cp", "aic", "sbic", "sbc", "msep", "fpe", "apc", "hsp") ~ is_min))

subset_summary <- subset_summary %>% mutate(name = case_when(name == "rsquare" ~ "R2",
                                                             name == "adjr" ~ "Adjusted R2",
                                                             name == "predrsq" ~ "Predicted R2",
                                                             name == "cp" ~ "Mallow's Cp",
                                                             name == "aic" ~ "AIC",
                                                             name == "sbic" ~ "SBIC",
                                                             name == "sbc" ~ "BIC",
                                                             name == "msep" ~ "MSEP",
                                                             name == "fpe" ~ "FPE",
                                                             name == "apc" ~ "APC",
                                                             name == "hsp" ~ "HSP"))


subset_summary$name <- factor(subset_summary$name, levels = c("R2", "Adjusted R2", "Predicted R2", "Mallow's Cp", "AIC", "SBIC", "BIC", "MSEP", "FPE", "APC", "HSP"))

left_panel <- ggplot(subset_summary %>% filter(name %in% c("R2", "Adjusted R2", "Predicted R2", "Mallow's Cp", "AIC", "BIC")), aes(x=nrow, y = value)) +
  geom_point(color = "blue4", size = 3, aes(shape = factor(is_opt))) +
  geom_line(color = "blue4") +
  scale_x_continuous(breaks = c(0,3,6,9,12,15,18)) +
  facet_wrap(~name, nrow = 2, scale = "free") + 
  scale_shape_manual(values = c("0" = 21, "1" = 19)) +
  theme_bw() + 
  ylab("Value") +
  xlab("Number of variables") +
  theme_minimal() +
  theme(
    # Remove grid lines
    panel.grid = element_blank(),
    
    # Add a box around the plot
    panel.border = element_rect(color = "black", fill = NA, size = 0.5),
    
    # Remove the default panel background
    panel.background = element_blank(),
    
    # Optional: adjust axis appearance to be more matplotlib-like
    axis.ticks = element_line(color = "black"),
    text = element_text(size = 26),  # Affects most text elements
    axis.text = element_text(size = 26, color = "black"),  # Axis labels
    axis.title = element_text(size = 28, color = "black"), # Axis titles
    strip.text = element_text(size = 26),  #facet title
    plot.title = element_text(size = 30),  # Plot title
    legend.position = "none"
  ) +
 ggtitle("First wave model selection")

#Best statistics obsvered for the 9-variable model
#Difference to exhaustive search for full time: Now AverageAge is included instead of peopleover65 
#cor(valuetoplotRed$AverageAge, valuetoplotRed$peopleover65) #These are strongly(!!!) correlated, so this doesn't come as a surprise
#A_names <- c("Inhabitantsperkm2", "voterTurnout", "IncomePerson2022", "GRUENE", "FDP", "AverageAge", "Alq2020", "ForstFischerei", "FinanzVersicherung")

#Lines above = irrelevant, we now use the following
A_names <- c("Inhabitantsperkm2", "IncomePerson2022", "childrenbelow3inprimarycare", "voterTurnout", "CDU", "SPD", "GRUENE", "FDP", "AFD", "EmploymentRate", "AverageAge", "Alq2020", "ForstFischerei", "FinanzVersicherung")

testA <- lm(valueInitWave ~ Inhabitantsperkm2 + voterTurnout + IncomePerson2022 + GRUENE + FDP + AverageAge + Alq2020 + ForstFischerei + FinanzVersicherung, data = valuetoplotRed)
testB <- lm(valueInitWave ~ Inhabitantsperkm2 + IncomePerson2022 + childrenbelow3inprimarycare + voterTurnout + CDU + SPD + GRUENE + FDP + AFD + EmploymentRate + AverageAge + Alq2020 + ForstFischerei + FinanzVersicherung, data =valuetoplotRed)
B_name <- "Firstwave90percentile"
C_name <- "valueInitWave"

a_lab <- paste0("a", 1:length(A_names))   # A -> B
c_lab <- paste0("c", 1:length(A_names))   # A -> C

B_eq <- paste("valueInitWave ~", paste(paste0(a_lab, "*", A_names), collapse = " + "), "+1")
C_eq <- paste("Firstwave90percentile ~ b*valueInitWave +", paste(paste0(c_lab, "*", A_names), collapse = " + "), "+1") 

# define indirect and total effects for each Aj
ind_defs <- paste(paste0("ind_", A_names, " := ", a_lab, "*b"), collapse = "\n")
tot_defs <- paste(paste0("tot_", A_names, " := ", c_lab, " + ind_", A_names), collapse = "\n")

model <- paste(B_eq, C_eq, ind_defs, tot_defs, sep = "\n")

fitReacStrengthSecondWave <- sem(model,
           data = valuetoplotRed,
           fixed.x = TRUE,        # treat A's as fixed exogenous
           se = "bootstrap",
           bootstrap = 1000)

summary(fitReacStrengthFirstWave, standardized = TRUE, ci = TRUE)
#First fourteen are for Reac Strength Initial Wave
parameterEstimates(fitReacStrengthFirstWave)[1,5] #Coefficient position
parameterEstimates(fitReacStrengthFirstWave)[1,6] #Standard error --> lower = Coeff - 1.96 *standarderror, upper = Coeff + 1.96 *standarderror

i <- 0 #left panel
forestplotData <-tibble::tibble(mean = c(parameterEstimates(fitReacStrengthFirstWave)[1+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[2+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[3+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[4+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[5+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[6+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[7+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[8+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[9+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[10+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[11+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[12+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[13+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[14+i,5]),
                                        # parameterEstimates(fitReacStrengthFirstWave)[15+i,5]),
                                abscoeff = c(abs(parameterEstimates(fitReacStrengthFirstWave)[1+i,5]),
                                          abs(parameterEstimates(fitReacStrengthFirstWave)[2+i,5]),
                                          abs(parameterEstimates(fitReacStrengthFirstWave)[3+i,5]),
                                          abs(parameterEstimates(fitReacStrengthFirstWave)[4+i,5]),
                                          abs(parameterEstimates(fitReacStrengthFirstWave)[5+i,5]),
                                          abs(parameterEstimates(fitReacStrengthFirstWave)[6+i,5]),
                                          abs(parameterEstimates(fitReacStrengthFirstWave)[7+i,5]),
                                          abs(parameterEstimates(fitReacStrengthFirstWave)[8+i,5]),
                                          abs(parameterEstimates(fitReacStrengthFirstWave)[9+i,5]),
                                          abs(parameterEstimates(fitReacStrengthFirstWave)[10+i,5]),
                                          abs(parameterEstimates(fitReacStrengthFirstWave)[11+i,5]),
                                          abs(parameterEstimates(fitReacStrengthFirstWave)[12+i,5]),
                                          abs(parameterEstimates(fitReacStrengthFirstWave)[13+i,5]),
                                          abs(parameterEstimates(fitReacStrengthFirstWave)[14+i,5])),
                                          #abs(parameterEstimates(fitReacStrengthFirstWave)[15+i,5])),
                                lower = c(parameterEstimates(fitReacStrengthFirstWave)[1+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[1+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[2+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[2+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[3+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[3+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[4+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[4+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[5+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[5+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[6+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[6+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[7+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[7+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[8+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[8+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[9+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[9+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[10+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[10+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[11+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[11+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[12+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[12+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[13+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[13+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[14+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[14+i,6]),
                                          #parameterEstimates(fitReacStrengthFirstWave)[15+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[15+i,6]),
                                upper = c(parameterEstimates(fitReacStrengthFirstWave)[1+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[1+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[2+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[2+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[3+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[3+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[4+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[4+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[5+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[5+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[6+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[6+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[7+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[7+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[8+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[8+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[9+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[9+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[10+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[10+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[11+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[11+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[12+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[12+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[13+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[13+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[14+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[14+i,6]),
                                         # parameterEstimates(fitReacStrengthFirstWave)[15+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[15+i,6]),
                                variable = c(#"Reaction strength first wave",
                                             "Population density",
                                             "Income",
                                             "Small children in childcare",
                                             "Voter turnout",
                                             "CDU",
                                             "SPD",
                                             "Green party",
                                             "FDP",
                                             "AfD",
                                             "Employment rate",
                                             "Average age",
                                             "Unemployment rate",
                                             "Agriculture, forestry, fisheries",
                                             "Finance sector"))

#Determening Order
(parameterEstimates(fitReacStrengthFirstWave)[12,5] + parameterEstimates(fitReacStrengthSecondWave)[12,5])/2 #Unemployment rate
(parameterEstimates(fitReacStrengthFirstWave)[1,5] + parameterEstimates(fitReacStrengthSecondWave)[1,5])/2 #Population density
(parameterEstimates(fitReacStrengthFirstWave)[2,5] + parameterEstimates(fitReacStrengthSecondWave)[2,5])/2 #Income
(parameterEstimates(fitReacStrengthFirstWave)[7,5] + parameterEstimates(fitReacStrengthSecondWave)[7,5])/2 #Greens
(parameterEstimates(fitReacStrengthFirstWave)[14,5] + parameterEstimates(fitReacStrengthSecondWave)[14,5])/2 #Finance sector
(parameterEstimates(fitReacStrengthFirstWave)[11,5] + parameterEstimates(fitReacStrengthSecondWave)[11,5])/2 #Average age
(parameterEstimates(fitReacStrengthFirstWave)[4,5] + parameterEstimates(fitReacStrengthSecondWave)[4,5])/2 #Voter turnour
(parameterEstimates(fitReacStrengthFirstWave)[3,5] + parameterEstimates(fitReacStrengthSecondWave)[3,5])/2 #Small children
(parameterEstimates(fitReacStrengthFirstWave)[10,5] + parameterEstimates(fitReacStrengthSecondWave)[10,5])/2 #Employment rate
(parameterEstimates(fitReacStrengthFirstWave)[6,5] + parameterEstimates(fitReacStrengthSecondWave)[6,5])/2 #SPD
(parameterEstimates(fitReacStrengthFirstWave)[5,5] + parameterEstimates(fitReacStrengthSecondWave)[5,5])/2 #CDU
(parameterEstimates(fitReacStrengthFirstWave)[13,5] + parameterEstimates(fitReacStrengthSecondWave)[13,5])/2 #Agriculture, forestry, fisheries
(parameterEstimates(fitReacStrengthFirstWave)[8,5] + parameterEstimates(fitReacStrengthSecondWave)[8,5])/2 #FDP
(parameterEstimates(fitReacStrengthFirstWave)[9,5] + parameterEstimates(fitReacStrengthSecondWave)[9,5])/2 #AfD

forestplotData$variable <- ordered(forestplotData$variable, levels = c("Reaction strength first wave", "Unemployment rate", "Population density", "Income", "Green party", "Finance sector", "Average age", "Voter turnout", "Small children in childcare", "Employment rate", "SPD", "CDU", "Agriculture, forestry, fisheries", "FDP", "AfD"))
forestplotData <- forestplotData %>% arrange(variable)

panel_A <- ggplot(forestplotData, aes(y=fct_rev(variable))) + 
  geom_vline(xintercept = 0, linetype="dashed") +
  geom_linerange(aes(xmin=lower, xmax=upper), color = "darkblue", size = 2)+
  geom_point(aes(x=mean), color = "royalblue", size = 4) +
  scale_x_continuous(limits = c(-0.8,0.6), breaks = c(-0.8,-0.4,0,0.4,0.8)) +
  theme_minimal() +
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
    text = element_text(size = 22),  # Affects most text elements
    axis.text = element_text(color = "black"),  # Axis labels
    axis.title = element_text(color = "black"),
    legend.position = "none",     # Remove axis labels
    #axis.text.x = element_blank(),     # Remove x-axis tick labels
    #axis.ticks.x = element_blank() 
  ) +
  ylab("Explanatory variables") +
  xlab("") +
  ggtitle("... reaction strength")


i <- 166 #left panel total effect size
forestplotData <-tibble::tibble(mean = c(parameterEstimates(fitReacStrengthFirstWave)[1+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[2+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[3+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[4+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[5+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[6+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[7+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[8+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[9+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[10+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[11+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[12+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[13+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[14+i,5]),
                                # parameterEstimates(fitReacStrengthFirstWave)[15+i,5]),
                                abscoeff = c(abs(parameterEstimates(fitReacStrengthFirstWave)[1+i,5]),
                                             abs(parameterEstimates(fitReacStrengthFirstWave)[2+i,5]),
                                             abs(parameterEstimates(fitReacStrengthFirstWave)[3+i,5]),
                                             abs(parameterEstimates(fitReacStrengthFirstWave)[4+i,5]),
                                             abs(parameterEstimates(fitReacStrengthFirstWave)[5+i,5]),
                                             abs(parameterEstimates(fitReacStrengthFirstWave)[6+i,5]),
                                             abs(parameterEstimates(fitReacStrengthFirstWave)[7+i,5]),
                                             abs(parameterEstimates(fitReacStrengthFirstWave)[8+i,5]),
                                             abs(parameterEstimates(fitReacStrengthFirstWave)[9+i,5]),
                                             abs(parameterEstimates(fitReacStrengthFirstWave)[10+i,5]),
                                             abs(parameterEstimates(fitReacStrengthFirstWave)[11+i,5]),
                                             abs(parameterEstimates(fitReacStrengthFirstWave)[12+i,5]),
                                             abs(parameterEstimates(fitReacStrengthFirstWave)[13+i,5]),
                                             abs(parameterEstimates(fitReacStrengthFirstWave)[14+i,5])),
                                #abs(parameterEstimates(fitReacStrengthFirstWave)[15+i,5])),
                                lower = c(parameterEstimates(fitReacStrengthFirstWave)[1+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[1+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[2+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[2+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[3+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[3+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[4+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[4+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[5+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[5+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[6+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[6+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[7+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[7+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[8+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[8+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[9+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[9+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[10+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[10+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[11+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[11+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[12+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[12+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[13+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[13+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[14+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[14+i,6]),
                                #parameterEstimates(fitReacStrengthFirstWave)[15+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[15+i,6]),
                                upper = c(parameterEstimates(fitReacStrengthFirstWave)[1+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[1+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[2+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[2+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[3+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[3+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[4+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[4+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[5+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[5+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[6+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[6+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[7+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[7+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[8+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[8+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[9+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[9+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[10+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[10+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[11+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[11+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[12+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[12+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[13+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[13+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[14+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[14+i,6]),
                                # parameterEstimates(fitReacStrengthFirstWave)[15+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[15+i,6]),
                                variable = c(#"Reaction strength first wave",
                                  "Population density",
                                  "Income",
                                  "Small children in childcare",
                                  "Voter turnout",
                                  "CDU",
                                  "SPD",
                                  "Green party",
                                  "FDP",
                                  "AfD",
                                  "Employment rate",
                                  "Average age",
                                  "Unemployment rate",
                                  "Agriculture, forestry, fisheries",
                                  "Finance sector"))

forestplotData$variable <- ordered(forestplotData$variable, levels = c("Reaction strength first wave", "Unemployment rate", "Population density", "Income", "Green party", "Finance sector", "Average age", "Voter turnout", "Small children in childcare", "Employment rate", "SPD", "CDU", "Agriculture, forestry, fisheries", "FDP", "AfD"))
forestplotData <- forestplotData %>% arrange(variable)

totEffectSize_leftpanel <- ggplot(forestplotData, aes(y=fct_rev(variable))) + 
  geom_vline(xintercept = 0, linetype="dashed") +
  geom_linerange(aes(xmin=lower, xmax=upper), color = "darkblue", size = 2)+
  geom_point(aes(x=mean), color = "royalblue", size = 4) +
  scale_x_reverse(limits = c(1.6,-0.8), breaks = c(1.6,1.2,0.8,0.4,0,-0.4,-0.8)) +
  theme_minimal() +
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
    text = element_text(size = 22),  # Affects most text elements
    axis.text = element_text(color = "black"),  # Axis labels
    axis.title = element_text(color = "black"),
    legend.position = "none",     # Remove axis labels
    #axis.text.x = element_blank(),     # Remove x-axis tick labels
    #axis.ticks.x = element_blank() 
  ) +
  ylab("Explanatory variables") +
  xlab("") +
  ggtitle("Peak incidence first wave")


i <-15
forestplotData <-tibble::tibble(mean = c(parameterEstimates(fitReacStrengthFirstWave)[1+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[2+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[3+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[4+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[5+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[6+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[7+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[8+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[9+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[10+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[11+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[12+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[13+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[14+i,5],
                                         parameterEstimates(fitReacStrengthFirstWave)[15+i,5]),
                                abscoeff = c(abs(parameterEstimates(fitReacStrengthFirstWave)[1+i,5]),
                                             abs(parameterEstimates(fitReacStrengthFirstWave)[2+i,5]),
                                             abs(parameterEstimates(fitReacStrengthFirstWave)[3+i,5]),
                                             abs(parameterEstimates(fitReacStrengthFirstWave)[4+i,5]),
                                             abs(parameterEstimates(fitReacStrengthFirstWave)[5+i,5]),
                                             abs(parameterEstimates(fitReacStrengthFirstWave)[6+i,5]),
                                             abs(parameterEstimates(fitReacStrengthFirstWave)[7+i,5]),
                                             abs(parameterEstimates(fitReacStrengthFirstWave)[8+i,5]),
                                             abs(parameterEstimates(fitReacStrengthFirstWave)[9+i,5]),
                                             abs(parameterEstimates(fitReacStrengthFirstWave)[10+i,5]),
                                             abs(parameterEstimates(fitReacStrengthFirstWave)[11+i,5]),
                                             abs(parameterEstimates(fitReacStrengthFirstWave)[12+i,5]),
                                             abs(parameterEstimates(fitReacStrengthFirstWave)[13+i,5]),
                                             abs(parameterEstimates(fitReacStrengthFirstWave)[14+i,5]),
                                             abs(parameterEstimates(fitReacStrengthFirstWave)[15+i,5])),
                                lower = c(parameterEstimates(fitReacStrengthFirstWave)[1+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[1+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[2+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[2+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[3+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[3+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[4+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[4+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[5+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[5+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[6+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[6+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[7+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[7+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[8+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[8+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[9+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[9+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[10+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[10+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[11+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[11+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[12+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[12+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[13+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[13+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[14+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[14+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[15+i,5] - 1.96*parameterEstimates(fitReacStrengthFirstWave)[15+i,6]),
                                upper = c(parameterEstimates(fitReacStrengthFirstWave)[1+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[1+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[2+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[2+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[3+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[3+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[4+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[4+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[5+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[5+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[6+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[6+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[7+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[7+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[8+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[8+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[9+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[9+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[10+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[10+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[11+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[11+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[12+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[12+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[13+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[13+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[14+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[14+i,6],
                                          parameterEstimates(fitReacStrengthFirstWave)[15+i,5] + 1.96*parameterEstimates(fitReacStrengthFirstWave)[15+i,6]),
                                variable = c("Reaction strength first wave",
                                             "Population density",
                                             "Income",
                                             "Small children in childcare",
                                             "Voter turnout",
                                             "CDU",
                                             "SPD",
                                             "Green party",
                                             "FDP",
                                             "AfD",
                                             "Employment rate",
                                             "Average age",
                                             "Unemployment rate",
                                             "Agriculture, forestry, fisheries",
                                             "Finance sector"))


forestplotData$variable <- ordered(forestplotData$variable, levels = c("Reaction strength first wave", "Unemployment rate", "Population density", "Income", "Green party", "Finance sector", "Average age", "Voter turnout", "Small children in childcare", "Employment rate", "SPD", "CDU", "Agriculture, forestry, fisheries", "FDP", "AfD"))
forestplotData <- forestplotData %>% arrange(variable)

panel_B <- ggplot(forestplotData, aes(y=fct_rev(variable))) + 
  geom_vline(xintercept = 0, linetype="dashed") +
  geom_linerange(aes(xmin=lower, xmax=upper), color = "darkblue", size = 2)+
  geom_point(aes(x=mean), color = "royalblue", size = 4) +
  scale_x_reverse(limits = c(1.6,-0.8), breaks = c(1.6,1.2,0.8,0.4,0,-0.4,-0.8)) +
  theme_minimal() +
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
    text = element_text(size = 22),  # Affects most text elements
    axis.text = element_text(color = "black"),  # Axis labels
    axis.title = element_text(color = "black"),
    legend.position = "none",     # Remove axis labels
    #axis.text.x = element_blank(),     # Remove x-axis tick labels
    #axis.ticks.x = element_blank() 
  ) +
  ylab("Explanatory variables") +
  xlab("") +
  ggtitle("... peak incidence")

#Comparable results as for whole time

#Correlation matrix
corrMatFirstWave <- valuetoplotRed %>% ungroup() %>% dplyr::select(c(valueInitWave, Inhabitantsperkm2, IncomePerson2022, 
                                                                     AverageAge,  peopleover65, childrenbelow3inprimarycare, 
                                                                     voterTurnout, CDU, SPD, GRUENE, FDP, AFD,
                                                                     EmploymentRate,  Alq2020, 
                                                                     ForstFischerei, ProduzierendesGewerbe,  Baugewerbe, Dienstleistungsgewerbe, HandelVerkehrGastgewerbe, FinanzVersicherung))
colnames(corrMatFirstWave) <- c("Reaction strength first wave", "Population density", "Income",
                                "Average age", "65+ year olds", "Small children in childcare",
                                "Voter turnout", "CDU", "SPD", "Green party", "FDP", "AfD",
                                "Employment rate", "Unemployment rate",
                                "Agriculture, forestry, fisheries", "Manufacturing sector", "Construction", "Service sectors", "TTHIC sectors", "Finance sectors")

corrmat <- cor(corrMatFirstWave)
pdf(height = 10, width = 13, "CorrelationPlotFirstWave.pdf") 
corrplot(corrmat, method = "color", tl.col="black", type = "upper", tl.srt = 90, tl.cex = 1.4, cl.pos = "b", diag = FALSE, cl.ratio = 0.25, cl.cex=1.25, mar = c(0,0,1.5,1))
dev.off()


# Lavaan -> Reaction Strength SECOND WAVE ----------------------------------

bestsubset <- results$model3

subset_summary <- cbind(bestsubset$metrics[4], bestsubset$metrics[5], bestsubset$metrics[6], bestsubset$metrics[7], bestsubset$metrics[8], bestsubset$metrics[9], bestsubset$metrics[10], bestsubset$metrics[11],
                        bestsubset$metrics[12], bestsubset$metrics[13],  bestsubset$metrics[14])
subset_summary <- round(subset_summary, 4)

subset_summary <- subset_summary %>% mutate(nrow = row_number()) %>% pivot_longer(cols=c(rsquare, adjr, predrsq, cp, aic, sbic, sbc, msep, fpe, apc, hsp))

subset_summary <- subset_summary %>% group_by(name) %>%
  mutate(is_max = ifelse(value == max(value), 1, 0)) %>% 
  mutate(is_min = ifelse(value == min(value), 1, 0))

subset_summary <- subset_summary %>% mutate(is_opt = case_when(name %in% c("rsquare", "adjr", "predrsq") ~ is_max,
                                                               name %in% c("cp", "aic", "sbic", "sbc", "msep", "fpe", "apc", "hsp") ~ is_min))

subset_summary <- subset_summary %>% mutate(name = case_when(name == "rsquare" ~ "R2",
                                                             name == "adjr" ~ "Adjusted R2",
                                                             name == "predrsq" ~ "Predicted R2",
                                                             name == "cp" ~ "Mallow's Cp",
                                                             name == "aic" ~ "AIC",
                                                             name == "sbic" ~ "SBIC",
                                                             name == "sbc" ~ "BIC",
                                                             name == "msep" ~ "MSEP",
                                                             name == "fpe" ~ "FPE",
                                                             name == "apc" ~ "APC",
                                                             name == "hsp" ~ "HSP"))


subset_summary$name <- factor(subset_summary$name, levels = c("R2", "Adjusted R2", "Predicted R2", "Mallow's Cp", "AIC", "SBIC", "BIC", "MSEP", "FPE", "APC", "HSP"))

right_panel <- ggplot(subset_summary %>% filter(name %in% c("R2", "Adjusted R2", "Predicted R2", "Mallow's Cp", "AIC", "BIC")), aes(x=nrow, y = value)) +
  geom_point(color = "blue4", size = 3, aes(shape = factor(is_opt))) +
  geom_line(color = "blue4") +
  scale_x_continuous(breaks = c(0,3,6,9,12,15,18)) +
  facet_wrap(~name, nrow = 2, scale = "free") + 
  scale_shape_manual(values = c("0" = 21, "1" = 19)) +
  theme_bw() + 
  ylab("Value") +
  xlab("Number of variables") +
  theme_minimal() +
  theme(
    # Remove grid lines
    panel.grid = element_blank(),
    
    # Add a box around the plot
    panel.border = element_rect(color = "black", fill = NA, size = 0.5),
    
    # Remove the default panel background
    panel.background = element_blank(),
    
    # Optional: adjust axis appearance to be more matplotlib-like
    axis.ticks = element_line(color = "black"),
    text = element_text(size = 26),  # Affects most text elements
    axis.text = element_text(size = 26, color = "black"),  # Axis labels
    axis.title = element_text(size = 28, color = "black"), # Axis titles
    strip.text = element_text(size = 26),  #facet title
    plot.title = element_text(size = 30),  # Plot title
    legend.position = "none"
  ) +
  ggtitle("Second wave model selection")

ggarrange(left_panel, right_panel, labels = c("A", "B"), align="v", nrow = 1, ncol = 2, font.label = list(size = 37), legend = "none", heights = c(1,0.08,1))

ggsave("ModelSelectionBothWaves.pdf", dpi = 500, h = 6, w = 24)
ggsave("ModelSelectionBothWaves.png", dpi = 500, h = 6, w = 24)

#Best statistics != as clear as for whole time and first wave
#Adj r^2, pred r^2 -> 12 variable model
#Mallow's C_p -> 11 variable model
#AIC, BIC --> 11 variable model

#Considerin 11 variable model -> Interestingly population density disappears
#A_names <- c("IncomePerson2022", "childrenbelow3inprimarycare", "CDU", "SPD", "FDP", "AFD", "peopleover65", "EmploymentRate", "AverageAge", "Alq2020", "ForstFischerei")

#A_names <- c("Inhabitantsperkm2", "voterTurnout", "IncomePerson2022", "GRUENE", "FDP", "AverageAge", "Alq2020", "ForstFischerei", "FinanzVersicherung")
#A_names <- c("Inhabitantsperkm2", "IncomePerson2022", "childrenbelow3inprimarycare", "voterTurnout", "CDU", "SPD", "FDP", "AFD", "EmploymentRate", "AverageAge", "Alq2020", "ForstFischerei", "FinanzVersicherung")
A_names <- c("Inhabitantsperkm2", "IncomePerson2022", "childrenbelow3inprimarycare", "voterTurnout", "CDU", "SPD", "GRUENE", "FDP", "AFD", "EmploymentRate", "AverageAge", "Alq2020", "ForstFischerei", "FinanzVersicherung")

#testa <- lm(valueSecondWave ~ Inhabitantsperkm2 + voterTurnout + IncomePerson2022 + GRUENE + FDP + AverageAge + Alq2020 + ForstFischerei + FinanzVersicherung, data = valuetoplotRed)
testb <- lm(valueSecondWave ~ Inhabitantsperkm2 + IncomePerson2022 + childrenbelow3inprimarycare + voterTurnout + CDU + SPD + GRUENE + FDP + AFD + EmploymentRate + AverageAge + Alq2020 + ForstFischerei + FinanzVersicherung, data = valuetoplotRed)

B_name <- "Secondwave90percentile"
C_name <- "valueSecondWave"

a_lab <- paste0("a", 1:length(A_names))   # A -> B
c_lab <- paste0("c", 1:length(A_names))   # A -> C

B_eq <- paste("valueSecondWave ~", paste(paste0(a_lab, "*", A_names), collapse = " + "), "+1")
C_eq <- paste("Secondwave90percentile ~ b*valueSecondWave +", paste(paste0(c_lab, "*", A_names), collapse = " + "), "+1") 

# define indirect and total effects for each Aj
ind_defs <- paste(paste0("ind_", A_names, " := ", a_lab, "*b"), collapse = "\n")
tot_defs <- paste(paste0("tot_", A_names, " := ", c_lab, " + ind_", A_names), collapse = "\n")

model <- paste(B_eq, C_eq, ind_defs, tot_defs, sep = "\n")

fitReacStrengthSecondWave <- sem(model,
                                data = valuetoplotRed,
                                fixed.x = TRUE,        # treat A's as fixed exogenous
                                se = "bootstrap",
                                bootstrap = 1000)

summary(fitReacStrengthSecondWave, standardized = TRUE, ci = TRUE)
i <- 0 #left panel
forestplotData <-tibble::tibble(mean = c(parameterEstimates(fitReacStrengthSecondWave)[1+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[2+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[3+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[4+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[5+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[6+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[7+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[8+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[9+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[10+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[11+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[12+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[13+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[14+i,5]),
                                        # parameterEstimates(fitReacStrengthSecondWave)[15+i,5]),
                                abscoeff = c(abs(parameterEstimates(fitReacStrengthSecondWave)[1+i,5]),
                                          abs(parameterEstimates(fitReacStrengthSecondWave)[2+i,5]),
                                          abs(parameterEstimates(fitReacStrengthSecondWave)[3+i,5]),
                                          abs(parameterEstimates(fitReacStrengthSecondWave)[4+i,5]),
                                          abs(parameterEstimates(fitReacStrengthSecondWave)[5+i,5]),
                                          abs(parameterEstimates(fitReacStrengthSecondWave)[6+i,5]),
                                          abs(parameterEstimates(fitReacStrengthSecondWave)[7+i,5]),
                                          abs(parameterEstimates(fitReacStrengthSecondWave)[8+i,5]),
                                          abs(parameterEstimates(fitReacStrengthSecondWave)[9+i,5]),
                                          abs(parameterEstimates(fitReacStrengthSecondWave)[10+i,5]),
                                          abs(parameterEstimates(fitReacStrengthSecondWave)[11+i,5]),
                                          abs(parameterEstimates(fitReacStrengthSecondWave)[12+i,5]),
                                          abs(parameterEstimates(fitReacStrengthSecondWave)[13+i,5]),
                                          abs(parameterEstimates(fitReacStrengthSecondWave)[14+i,5])),
                                          #abs(parameterEstimates(fitReacStrengthSecondWave)[15+i,5])),
                                lower = c(parameterEstimates(fitReacStrengthSecondWave)[1+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[1+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[2+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[2+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[3+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[3+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[4+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[4+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[5+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[5+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[6+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[6+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[7+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[7+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[8+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[8+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[9+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[9+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[10+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[10+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[11+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[11+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[12+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[12+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[13+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[13+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[14+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[14+i,6]),
                                          #parameterEstimates(fitReacStrengthSecondWave)[15+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[15+i,6]),
                                upper = c(parameterEstimates(fitReacStrengthSecondWave)[1+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[1+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[2+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[2+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[3+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[3+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[4+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[4+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[5+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[5+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[6+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[6+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[7+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[7+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[8+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[8+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[9+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[9+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[10+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[10+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[11+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[11+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[12+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[12+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[13+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[13+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[14+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[14+i,6]),
                                         # parameterEstimates(fitReacStrengthSecondWave)[15+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[15+i,6]),
                                variable = c(#"Reaction strength first wave",
                                             "Population density",
                                             "Income",
                                             "Small children in childcare",
                                             "Voter turnout",
                                             "CDU",
                                             "SPD",
                                             "Green party",
                                             "FDP",
                                             "AfD",
                                             "Employment rate",
                                             "Average age",
                                             "Unemployment rate",
                                             "Agriculture, forestry, fisheries",
                                             "Finance sector"))

forestplotData$variable <- ordered(forestplotData$variable, levels = c("Reaction strength second wave", "Unemployment rate", "Population density", "Income", "Green party", "Finance sector", "Average age", "Voter turnout", "Small children in childcare", "Employment rate", "SPD", "CDU", "Agriculture, forestry, fisheries", "FDP", "AfD"))
forestplotData <- forestplotData %>% arrange(variable)

panel_C <- ggplot(forestplotData, aes(y=fct_rev(variable))) + 
  geom_vline(xintercept = 0, linetype="dashed") +
  geom_linerange(aes(xmin=lower, xmax=upper), color = "darkblue", size = 2)+
  geom_point(aes(x=mean), color = "royalblue", size = 4) +
  scale_x_continuous(limits = c(-1,0.6), breaks = c(-0.8,-0.4,0,0.4,0.8)) +
  theme_minimal() +
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
    text = element_text(size = 22),  # Affects most text elements
    axis.text = element_text(color = "black"),  # Axis labels
    axis.title = element_text(color = "black"),
    legend.position = "none",     # Remove axis labels
    #axis.text.x = element_blank(),     # Remove x-axis tick labels
    #axis.ticks.x = element_blank() 
  ) +
  ylab("Explanatory variables") +
  xlab("") +
  ggtitle("... reaction strength")

#forestplotData <- add_row(forestplotData, .before = 1)

i <- 166 #left panel
forestplotData <-tibble::tibble(mean = c(parameterEstimates(fitReacStrengthSecondWave)[1+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[2+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[3+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[4+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[5+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[6+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[7+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[8+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[9+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[10+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[11+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[12+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[13+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[14+i,5]),
                                # parameterEstimates(fitReacStrengthSecondWave)[15+i,5]),
                                abscoeff = c(abs(parameterEstimates(fitReacStrengthSecondWave)[1+i,5]),
                                             abs(parameterEstimates(fitReacStrengthSecondWave)[2+i,5]),
                                             abs(parameterEstimates(fitReacStrengthSecondWave)[3+i,5]),
                                             abs(parameterEstimates(fitReacStrengthSecondWave)[4+i,5]),
                                             abs(parameterEstimates(fitReacStrengthSecondWave)[5+i,5]),
                                             abs(parameterEstimates(fitReacStrengthSecondWave)[6+i,5]),
                                             abs(parameterEstimates(fitReacStrengthSecondWave)[7+i,5]),
                                             abs(parameterEstimates(fitReacStrengthSecondWave)[8+i,5]),
                                             abs(parameterEstimates(fitReacStrengthSecondWave)[9+i,5]),
                                             abs(parameterEstimates(fitReacStrengthSecondWave)[10+i,5]),
                                             abs(parameterEstimates(fitReacStrengthSecondWave)[11+i,5]),
                                             abs(parameterEstimates(fitReacStrengthSecondWave)[12+i,5]),
                                             abs(parameterEstimates(fitReacStrengthSecondWave)[13+i,5]),
                                             abs(parameterEstimates(fitReacStrengthSecondWave)[14+i,5])),
                                #abs(parameterEstimates(fitReacStrengthSecondWave)[15+i,5])),
                                lower = c(parameterEstimates(fitReacStrengthSecondWave)[1+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[1+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[2+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[2+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[3+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[3+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[4+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[4+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[5+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[5+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[6+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[6+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[7+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[7+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[8+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[8+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[9+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[9+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[10+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[10+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[11+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[11+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[12+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[12+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[13+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[13+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[14+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[14+i,6]),
                                #parameterEstimates(fitReacStrengthSecondWave)[15+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[15+i,6]),
                                upper = c(parameterEstimates(fitReacStrengthSecondWave)[1+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[1+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[2+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[2+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[3+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[3+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[4+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[4+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[5+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[5+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[6+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[6+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[7+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[7+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[8+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[8+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[9+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[9+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[10+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[10+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[11+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[11+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[12+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[12+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[13+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[13+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[14+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[14+i,6]),
                                # parameterEstimates(fitReacStrengthSecondWave)[15+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[15+i,6]),
                                variable = c(#"Reaction strength first wave",
                                  "Population density",
                                  "Income",
                                  "Small children in childcare",
                                  "Voter turnout",
                                  "CDU",
                                  "SPD",
                                  "Green party",
                                  "FDP",
                                  "AfD",
                                  "Employment rate",
                                  "Average age",
                                  "Unemployment rate",
                                  "Agriculture, forestry, fisheries",
                                  "Finance sector"))

forestplotData$variable <- ordered(forestplotData$variable, levels = c("Reaction strength second wave", "Unemployment rate", "Population density", "Income", "Green party", "Finance sector", "Average age", "Voter turnout", "Small children in childcare", "Employment rate", "SPD", "CDU", "Agriculture, forestry, fisheries", "FDP", "AfD"))
forestplotData <- forestplotData %>% arrange(variable)


totEffectSize_rightpanel <- ggplot(forestplotData, aes(y=fct_rev(variable))) + 
  geom_vline(xintercept = 0, linetype="dashed") +
  geom_linerange(aes(xmin=lower, xmax=upper), color = "darkblue", size = 2)+
  geom_point(aes(x=mean), color = "royalblue", size = 4) +
  scale_x_reverse(limits = c(1.6,-0.8), breaks = c(1.6,1.2,0.8,0.4,0,-0.4,-0.8)) +
  theme_minimal() +
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
    text = element_text(size = 22),  # Affects most text elements
    axis.text = element_text(color = "black"),  # Axis labels
    axis.title = element_text(color = "black"),
    legend.position = "none",     # Remove axis labels
    #axis.text.x = element_blank(),     # Remove x-axis tick labels
    #axis.ticks.x = element_blank() 
  ) +
  ylab("Explanatory variables") +
  xlab("") +
  ggtitle("Peak incidence second wave")

i <-15
forestplotData <-tibble::tibble(mean = c(parameterEstimates(fitReacStrengthSecondWave)[1+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[2+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[3+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[4+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[5+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[6+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[7+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[8+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[9+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[10+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[11+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[12+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[13+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[14+i,5],
                                         parameterEstimates(fitReacStrengthSecondWave)[15+i,5]),
                                abscoeff = c(abs(parameterEstimates(fitReacStrengthSecondWave)[1+i,5]),
                                             abs(parameterEstimates(fitReacStrengthSecondWave)[2+i,5]),
                                             abs(parameterEstimates(fitReacStrengthSecondWave)[3+i,5]),
                                             abs(parameterEstimates(fitReacStrengthSecondWave)[4+i,5]),
                                             abs(parameterEstimates(fitReacStrengthSecondWave)[5+i,5]),
                                             abs(parameterEstimates(fitReacStrengthSecondWave)[6+i,5]),
                                             abs(parameterEstimates(fitReacStrengthSecondWave)[7+i,5]),
                                             abs(parameterEstimates(fitReacStrengthSecondWave)[8+i,5]),
                                             abs(parameterEstimates(fitReacStrengthSecondWave)[9+i,5]),
                                             abs(parameterEstimates(fitReacStrengthSecondWave)[10+i,5]),
                                             abs(parameterEstimates(fitReacStrengthSecondWave)[11+i,5]),
                                             abs(parameterEstimates(fitReacStrengthSecondWave)[12+i,5]),
                                             abs(parameterEstimates(fitReacStrengthSecondWave)[13+i,5]),
                                             abs(parameterEstimates(fitReacStrengthSecondWave)[14+i,5]),
                                             abs(parameterEstimates(fitReacStrengthSecondWave)[15+i,5])),
                                lower = c(parameterEstimates(fitReacStrengthSecondWave)[1+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[1+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[2+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[2+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[3+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[3+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[4+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[4+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[5+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[5+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[6+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[6+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[7+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[7+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[8+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[8+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[9+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[9+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[10+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[10+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[11+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[11+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[12+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[12+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[13+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[13+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[14+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[14+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[15+i,5] - 1.96*parameterEstimates(fitReacStrengthSecondWave)[15+i,6]),
                                upper = c(parameterEstimates(fitReacStrengthSecondWave)[1+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[1+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[2+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[2+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[3+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[3+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[4+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[4+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[5+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[5+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[6+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[6+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[7+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[7+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[8+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[8+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[9+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[9+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[10+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[10+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[11+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[11+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[12+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[12+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[13+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[13+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[14+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[14+i,6],
                                          parameterEstimates(fitReacStrengthSecondWave)[15+i,5] + 1.96*parameterEstimates(fitReacStrengthSecondWave)[15+i,6]),
                                variable = c("Reaction strength second wave",
                                             "Population density",
                                             "Income",
                                             "Small children in childcare",
                                             "Voter turnout",
                                             "CDU",
                                             "SPD",
                                             "Green party",
                                             "FDP",
                                             "AfD",
                                             "Employment rate",
                                             "Average age",
                                             "Unemployment rate",
                                             "Agriculture, forestry, fisheries",
                                             "Finance sector"))


forestplotData$variable <- ordered(forestplotData$variable, levels = c("Reaction strength second wave", "Unemployment rate", "Population density", "Income", "Green party", "Finance sector", "Average age", "Voter turnout", "Small children in childcare", "Employment rate", "SPD", "CDU", "Agriculture, forestry, fisheries", "FDP", "AfD"))
forestplotData <- forestplotData %>% arrange(variable)

panel_D <- ggplot(forestplotData, aes(y=fct_rev(variable))) + 
  geom_vline(xintercept = 0, linetype="dashed") +
  geom_linerange(aes(xmin=lower, xmax=upper), color = "darkblue", size = 2)+
  geom_point(aes(x=mean), color = "royalblue", size = 4) +
  scale_x_reverse(limits = c(1.6,-0.8), breaks = c(1.6,1.2,0.8,0.4,0,-0.4,-0.8)) +
  theme_minimal() +
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
    text = element_text(size = 22),  # Affects most text elements
    axis.text = element_text(color = "black"),  # Axis labels
    axis.title = element_text(color = "black"),
    legend.position = "none",     # Remove axis labels
    #axis.text.x = element_blank(),     # Remove x-axis tick labels
    #axis.ticks.x = element_blank() 
  ) +
  ylab("Explanatory variables") +
  xlab("") +
  ggtitle("... peak incidence")


ggarrange(NULL, NULL, NULL, NULL, panel_A, panel_B, NULL, panel_C, panel_D, heights = c(0.2,1,1), widths = c(0.2,1,1), labels = c("", "", "", "", "A", "C","", "B", "D"), nrow = 3, ncol = 3, font.label = list(size = 37))

ggsave("ForestplotFigure6.pdf", w=18, h = 12.5)

ggarrange(NULL, NULL, totEffectSize_leftpanel, totEffectSize_rightpanel, heights = c(0.2,1), labels = c("", "", "A", "B"), nrow = 2, ncol = 2, font.label = list(size = 37))

ggsave("ForestplotFigure18.pdf", w=18, h = 6.5)

#Correlation matrix
corrMatSecondWave <- valuetoplotRed %>% ungroup() %>% dplyr::select(c(valueSecondWave, Inhabitantsperkm2, IncomePerson2022, 
                                                                     AverageAge,  peopleover65, childrenbelow3inprimarycare, 
                                                                     voterTurnout, CDU, SPD, GRUENE, FDP, AFD,
                                                                     EmploymentRate,  Alq2020, 
                                                                     ForstFischerei, ProduzierendesGewerbe,  Baugewerbe, Dienstleistungsgewerbe, HandelVerkehrGastgewerbe, FinanzVersicherung))
colnames(corrMatSecondWave) <- c("Reaction strength second wave", "Population density", "Income",
                                "Average age", "65+ year olds", "Small children in childcare",
                                "Voter turnout", "CDU", "SPD", "Green party", "FDP", "AfD",
                                "Employment rate", "Unemployment rate",
                                "Agriculture, forestry, fisheries", "Manufacturing sector", "Construction", "Service sectors", "TTHIC sectors", "Finance sectors")

corrmat <- cor(corrMatSecondWave)
pdf(height = 10, width = 13, "CorrelationPlotSecondWave.pdf") 
corrplot(corrmat, method = "color", tl.col="black", type = "upper", tl.srt = 90, tl.cex = 1.5, cl.pos = "b", diag = FALSE, cl.ratio = 0.25, cl.cex=1.25, mar = c(0,0,1.5,1))
dev.off()


# Exhaustive Search Results Incidence (First Wave) ------------------------

results$model4

#Statistics favor 12 variable model
TwelveVariableModelIncidenceFirstWave <- lm(Firstwave90percentile ~  valueInitWave + Inhabitantsperkm2 + voterTurnout + IncomePerson2022 + childrenbelow3inprimarycare +
                                              SPD + GRUENE + FDP + AFD +
                                              ForstFischerei + Baugewerbe + FinanzVersicherung, data = valuetoplotRed)
summary(TwelveVariableModelIncidenceFirstWave)
#Removing FinanzVersicherung as != significant
ElevenVariableModelIncidenceFirstWave <- lm(Firstwave90percentile ~  valueInitWave + Inhabitantsperkm2 + voterTurnout + IncomePerson2022 + childrenbelow3inprimarycare +
                                              SPD + GRUENE + FDP + AFD +
                                              ForstFischerei + Baugewerbe, data = valuetoplotRed)
summary(ElevenVariableModelIncidenceFirstWave)

# Exhaustive Search Results Incidence (Second Wave) ------------------------

results$model5
#C_p, AIC and BIC favor 10/11 variable model
#Adj r2 favors 12 variable model (only differs in 3rd digit)
#Continue with 11 variable model

ElevenVariablesModelIncidenceSecondWave <- lm(Secondwave90percentile ~  valueSecondWave + Inhabitantsperkm2 + voterTurnout + IncomePerson2022 + childrenbelow3inprimarycare +
                                                CDU + GRUENE + AFD + peopleover65 +
                                                ForstFischerei + FinanzVersicherung, data = valuetoplotRed)
summary(ElevenVariablesModelIncidenceSecondWave)




