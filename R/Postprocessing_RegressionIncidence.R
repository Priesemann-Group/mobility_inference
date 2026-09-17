#Cases by district type
library(forestplot)
library(corrplot)
library(tidyverse)

#Data Preprocessing -------------------------------------------------------

model <- "fourhundred"

consideredWave <- "firstwave"

#run <- "2025-07-02_400LK_exp_UsedForPostprocessing"

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

cases_firstWave <- cases %>% filter(date < as.Date("2020-06-01")) %>% group_by(LK_Name) %>% summarise(wave90percentile = quantile(Infection_Incidence, 0.9), wave_height = max(Infection_Incidence), corresponding_value = date[which.max(Infection_Incidence)], group_eng = group_eng) 

cases_firstWave$group_eng <- factor(cases_firstWave $group_eng, levels = c("Large\ncity", "Small\ncity", "Suburban/\nindependent\ntown", "Medium\nrural", "Rural"))

cases_firstWave <- cases_firstWave %>% ungroup %>% unique()

cases_firstWave %>% anova_test(wave90percentile ~ group_eng)

my_comparisons <- list(c("Grosse Grossstadt", "Kleine Grossstadt"),
                       c("Kleine Grossstadt", "Städtische Kreise"),
                       c("Städtische Kreise", "Ländlicher Kreis mit Verdichtungsansätzen"),
                       c("Ländlicher Kreis mit Verdichtungsansätzen", "Dünn besiedelt ländlicher Kreis"))
my_comparisons <- list(c("Large\ncity", "Small\ncity"),
                       c("Small\ncity", "Suburban/\nindependent\ntown"),
                       c("Suburban/\nindependent\ntown", "Medium\nrural"),
                       c("Medium\nrural", "Rural"))
symnum.args <- list(cutpoints = c(0, 0.0001, 0.001, 0.01, 0.05, Inf), symbols = c("****", "***", "**", "*", "ns"))

manual_scale <- c("#D4B2CC", "#D385AC",  "#A56693", "#66507A", "#2D204C")
boxplot_firstWave <- ggplot(cases_firstWave %>% filter(wave90percentile < 300) %>% unique(), aes(x= group_eng, y=wave90percentile)) +
  geom_boxplot(lwd=1.5, color = "#393b79")+
  stat_compare_means(comparisons = my_comparisons, symnum.args = symnum.args, method = "t.test", size = 8) +
  theme_minimal() +
  #ylim(0,400) +
  guides(color=guide_legend(nrow=2,byrow=TRUE)) +
  ylab("Peak incidence") +
  scale_color_manual(values= manual_scale) +
  xlab("") +
  theme(
    # Remove grid lines
    panel.grid = element_blank(),
    
    # Add a box around the plot
    #panel.border = element_rect(color = "black", fill = NA, size = 0.5),
    axis.line.x.bottom = element_line(color = "black"),
    axis.line.y.left = element_line(color = "black"),
    
    # Remove the default panel background
    panel.background = element_blank(),
    
    # Optional: adjust axis appearance to be more matplotlib-like
    axis.ticks = element_line(color = "black"),
    axis.ticks.length = unit(10, "pt"),
    axis.text = element_text(color = "black"),  # Axis labels
    axis.title = element_text(color = "black"),
    axis.text.y=element_text(size = 21, color = "#000000"),
    axis.text.x=element_text(size = 21, color = "#000000"),
    axis.title.y=element_text(size = 23),
    legend.text = element_text(size = 21),
    plot.title = element_text(size = 25)
  ) +
  ggtitle("First wave") +
  theme(legend.position = "none", legend.title = element_blank())

# Second Wave

cases_secondWave <- cases %>% filter(date > as.Date("2020-09-01")) %>% group_by(LK_Name) %>% summarise(wave90percentile = quantile(Infection_Incidence, 0.9), wave_height = max(Infection_Incidence), corresponding_value = date[which.max(Infection_Incidence)], group_eng
                                                                                                       =group_eng) 

cases_secondWave$group_eng <- factor(cases_secondWave $group_eng, levels = c("Large\ncity", "Small\ncity", "Suburban/\nindependent\ntown", "Medium\nrural", "Rural"))

cases_secondWave <- cases_secondWave %>% ungroup %>% unique()

cases_secondWave %>% anova_test(wave90percentile ~ group_eng)

my_comparisons <- list(c("Grosse Grossstadt", "Kleine Grossstadt"),
                       c("Kleine Grossstadt", "Städtische Kreise"),
                       c("Städtische Kreise", "Ländlicher Kreis mit Verdichtungsansätzen"),
                       c("Ländlicher Kreis mit Verdichtungsansätzen", "Dünn besiedelt ländlicher Kreis"))
my_comparisons <- list(c("Large\ncity", "Small\ncity"),
                       c("Small\ncity", "Suburban/\nindependent\ntown"),
                       c("Suburban/\nindependent\ntown", "Medium\nrural"),
                       c("Medium\nrural", "Rural"))
symnum.args <- list(cutpoints = c(0, 0.0001, 0.001, 0.01, 0.05, Inf), symbols = c("****", "***", "**", "*", "ns"))

manual_scale <- c("#D4B2CC", "#D385AC",  "#A56693", "#66507A", "#2D204C")

cases_secondWave %>% anova_test(value ~ group_eng)

boxplot_secondWave <- ggplot(cases_secondWave %>% unique(), aes(x= group_eng, y=wave90percentile)) +
  geom_boxplot(lwd=1.5, color = "#393b79")+
  stat_compare_means(comparisons = my_comparisons, symnum.args = symnum.args, method = "t.test", size = 8) +
  theme_minimal() +
  #ylim(0,400) +
  guides(color=guide_legend(nrow=2,byrow=TRUE)) +
  ylab("Peak incidence") +
  scale_color_manual(values= manual_scale) +
  xlab("") +
  theme(
    # Remove grid lines
    panel.grid = element_blank(),
    
    # Add a box around the plot
    #panel.border = element_rect(color = "black", fill = NA, size = 0.5),
    axis.line.x.bottom = element_line(color = "black"),
    axis.line.y.left = element_line(color = "black"),
    
    # Remove the default panel background
    panel.background = element_blank(),
    
    # Optional: adjust axis appearance to be more matplotlib-like
    axis.ticks = element_line(color = "black"),
    axis.ticks.length = unit(10, "pt"),
    #text = element_text(size = 22),  # Affects most text elements
    axis.text = element_text(color = "black"),  # Axis labels
    axis.title = element_text(color = "black"),
    axis.text.y=element_text(size = 21, color = "#000000"),
    axis.text.x=element_text(size = 21, color = "#000000"),
    axis.title.y=element_text(size = 23),
    legend.text = element_text(size = 21),
    plot.title = element_text(size = 25)
  ) +
  ggtitle("Second wave") +
  theme(legend.position = "none", legend.title = element_blank())


ggarrange(boxplot_firstWave, boxplot_secondWave, labels = c("A", "B"), nrow = 1, ncol = 2,font.label = list(size = 25), heights = c(1,1))

ggsave(paste0("DistrictType-90thPercentileIncidence.pdf"), dpi = 500, h = 6, w = 18)
ggsave(paste0("DistrictType-90thPercentileIncidence.png"), dpi = 500, h = 6, w = 18)


# Regression First Wave ---------------------------------------------------

cases_firstWave <- cases_firstWave %>% ungroup()
cases_firstWave <- left_join(cases_firstWave, RegVariables)
cases_firstWave <- left_join(cases_firstWave, disFac_post)
cases_firstWave <- cases_firstWave %>% unique()

#Correlation matrix
# valuetoplotRed <- cases_firstWave %>% ungroup() %>% dplyr::select(c(LK_Name, wave90percentile, Inhabitantsperkm2, IncomePerson2022, unemploymentQuota, `Employment Rate`, `Average Age`, peopleover65, childrenbelow3inprimarycare, voterTurnout, `Voted for Parting Government`, `Voted for Incoming Government`))
# #colnames(valuetoplotRed) <- c("Reaction Strength", "Inhabitants per km2", "Income", "Unemployment Rate", "Employment Rate", "Average Age", "65+ year olds", "Small Children (< 3) in Childcare",  "Voter Turnout", "Voted for Parting Government", "Voted for Incoming Government")
# 
# #valuetoplotRed <- valuetoplotRed %>% select(c("Reaction Strength", "Inhabitants per km2", "Voted for Incoming Government", "Small Children (< 3) in Childcare", "Voter Turnout", "Unemployment Rate", "Income"))
# corrmat <- cor(valuetoplotRed)
# #pdf(height = 10, width = 13, "CorrelationPlotFirstWave.pdf")
# #pdf(height = 8, width = 13, "CorrelationPlotReduced.pdf")
# corrplot(corrmat, method = "color", tl.col="black", type = "upper", tl.srt = 90, tl.cex = 1, cl.pos = "b", diag = FALSE, cl.ratio = 0.25, cl.cex=1.25, mar = c(0,0,1.5,1))
# dev.off()
# 
# disFac_post <- disFac_post %>% dplyr::select(LK_Name, value, valueInitWave, valueSecondWave)
# 
# valuetoplotRed <- left_join(valuetoplotRed, disFac_post)

# Scaling of Independent Variables ----------------------------------------

valuetoplotRed <- cases_firstWave

valuetoplotRed <- valuetoplotRed %>% mutate(Inhabitantsperkm2 = scale(Inhabitantsperkm2)) %>%
                    mutate(voterTurnout = scale(voterTurnout)) %>%
                    mutate(IncomePerson2022 = scale(IncomePerson2022)) %>%
                    #mutate(unemploymentQuota = scale(unemploymentQuota)) %>%
                    mutate(peopleover65 = scale(peopleover65)) %>%
                    mutate(childrenbelow3inprimarycare = scale(childrenbelow3inprimarycare)) %>%
                    mutate(`Voted for Parting Government` = scale(`Voted for Parting Government`)) %>%
                    mutate(`Voted for Incoming Government` = scale(`Voted for Incoming Government`)) %>%
                    mutate(`Average Age` = scale(`Average Age`)) %>%
                    mutate(`Employment Rate` = scale(`Employment Rate`)) %>%
                    mutate(value = scale(value)) %>%
                    mutate(valueInitWave = scale(valueInitWave)) %>%
                    mutate(valueSecondWave = scale(valueSecondWave)) %>%
                    #mutate(Alq2019 = scale(Alq2019)) %>%
                    mutate(Alq2020 = scale(Alq2020)) %>%
                    #mutate(Alq2021 = scale(Alq2021)) %>%
                    #mutate(Alq20192020Abs = scale(Alq20192020Abs)) %>%
                    #mutate(Alq20192021Abs = scale(Alq20192021Abs)) %>%
                    #mutate(Kurz042020Rel = scale(Kurz042020Rel)) %>%
                    #mutate(Kurz052020Rel = scale(Kurz052020Rel)) %>%    
                    #mutate(SPD = scale(SPD)) %>%
                    mutate(ForstFischerei = scale(ForstFischerei)) %>%
                    mutate(ProduzierendesGewerbe = scale(ProduzierendesGewerbe)) %>%
                    mutate(VerarbeitendesGewerbe = scale(VerarbeitendesGewerbe)) %>%
                    mutate(Baugewerbe = scale(Baugewerbe)) %>%
                    mutate(Dienstleistungsgewerbe = scale(Dienstleistungsgewerbe)) %>%
                    mutate(HandelVerkehrGastgewerbe = scale(HandelVerkehrGastgewerbe)) %>%
                    mutate(FinanzVersicherung = scale(FinanzVersicherung)) %>%
                    mutate(OeffentlichSonstigeDienstleistungen = scale(OeffentlichSonstigeDienstleistungen)) %>%
                    #mutate(ReacStrengthInitWave = scale(ReacStrengthInitWave)) %>%
                    mutate(wave90percentile = scale (wave90percentile))

#Variance of inflation factor
library(car)
vif(lm(value ~ . , data = valuetoplotRed)) #All between 1 and 5 --> Some sort of correlation, not large enough to warrant adaptations

# Exhaustive Search -----------------------------

bestsubsetFirstWave <- olsrr::ols_step_best_subset(lm(wave90percentile  ~ valueInitWave + Inhabitantsperkm2 + voterTurnout + IncomePerson2022  + childrenbelow3inprimarycare + `Voted for Incoming Government` + 
                                               `Voted for Parting Government` + peopleover65 + `Employment Rate` + `Average Age` + Alq2020 + 
                                               ForstFischerei + ProduzierendesGewerbe + VerarbeitendesGewerbe + Baugewerbe + Dienstleistungsgewerbe + HandelVerkehrGastgewerbe + FinanzVersicherung + OeffentlichSonstigeDienstleistungen, 
                                             data=valuetoplotRed), metric = "adjr") 

lmSixVariablesFirstWave <- lm(wave90percentile ~ valueInitWave + Inhabitantsperkm2 + voterTurnout ,valuetoplotRed)

ggplot(valuetoplotRed) +
  geom_point(aes(x=wave90percentile, y=valueInitWave))


# forestplotData <-tibble::tibble(mean = c(round(sameSixVariablesIntWave$coefficients[2],4), round(sameSixVariablesIntWave$coefficients[3],4), round(sameSixVariablesIntWave$coefficients[4],2), round(sameSixVariablesIntWave$coefficients[5],2), round(sameSixVariablesIntWave$coefficients[6],2), round(sameSixVariablesIntWave$coefficients[7],2), round(sameSixVariablesIntWave$coefficients[8],2)),
#                                 mean_table = c(round(sameSixVariablesIntWave$coefficients[2],2), round(sameSixVariablesIntWave$coefficients[3],2), round(sameSixVariablesIntWave$coefficients[4],2), round(sameSixVariablesIntWave$coefficients[5],2), round(sameSixVariablesIntWave$coefficients[6],2), round(sameSixVariablesIntWave$coefficients[7],2), round(sameSixVariablesIntWave$coefficients[8],2)),
#                                 lower = c(confint(sameSixVariablesIntWave)[2,1], confint(sameSixVariablesIntWave)[3,1], confint(sameSixVariablesIntWave)[4,1], confint(sameSixVariablesIntWave)[5,1], confint(sameSixVariablesIntWave)[6,1], confint(sameSixVariablesIntWave)[7,1], confint(sameSixVariablesIntWave)[8,1]),
#                                 upper = c(confint(sameSixVariablesIntWave)[2,2], confint(sameSixVariablesIntWave)[3,2], confint(sameSixVariablesIntWave)[4,2], confint(sameSixVariablesIntWave)[5,2], confint(sameSixVariablesIntWave)[6,2], confint(sameSixVariablesIntWave)[7,2], confint(sameSixVariablesIntWave)[8,2]),
#                                 confint = c(
#                                   paste0("[", as.character(round(confint(sameSixVariablesIntWave)[2,1], 4)), ",", as.character(round(confint(sameSixVariablesIntWave)[2,2], 4)), "]"),
#                                   paste0("[", as.character(round(confint(sameSixVariablesIntWave)[3,1], 4)), ",", as.character(round(confint(sameSixVariablesIntWave)[3,2], 4)), "]"),
#                                   paste0("[", as.character(round(confint(sameSixVariablesIntWave)[4,1], 4)), ",", as.character(round(confint(sameSixVariablesIntWave)[4,2], 4)), "]"),
#                                   paste0("[", as.character(round(confint(sameSixVariablesIntWave)[5,1], 4)), ",", as.character(round(confint(sameSixVariablesIntWave)[5,2], 4)), "]"),
#                                   paste0("[", as.character(round(confint(sameSixVariablesIntWave)[6,1], 4)), ",", as.character(round(confint(sameSixVariablesIntWave)[6,2], 4)), "]"),
#                                   paste0("[", as.character(round(confint(sameSixVariablesIntWave)[7,1], 4)), ",", as.character(round(confint(sameSixVariablesIntWave)[7,2], 4)), "]"),
#                                   paste0("[", as.character(round(confint(sameSixVariablesIntWave)[8,1], 4)), ",", as.character(round(confint(sameSixVariablesIntWave)[8,2], 4)), "]")
#                                 ),
#                                 pvalue = c(
#                                   "<0.001",
#                                   "<0.001",
#                                   round(summary(sameSixVariablesIntWave)$coefficients[,4][4],3),
#                                   round(summary(sameSixVariablesIntWave)$coefficients[,4][5],3),
#                                   round(summary(sameSixVariablesIntWave)$coefficients[,4][6],3),
#                                   "<0.001",
#                                   "<0.001"
#                                 ),
#                                 variable = c("Reaction strength first wave", "Population density", "Unemployment quota", "Voter turnout", "Income" , "Small children in childcare", "Voted for incoming government"))
# 
# forestplotData <- forestplotData %>% mutate(mean = (-1)*mean, mean_table = (-1)*mean_table, lowersave = lower, lower = (-1)*upper, upper = (-1)*lowersave)
# 
# pdf("ForestplotFinalModelFirstWave.pdf", width = 11, height = 3)
# forestplotData %>%
#   forestplot::forestplot(
#     labeltext = c(variable, mean_table, confint, pvalue),
#     xlab = "Standardized Coefficient",
#     xticks = c(-0.4, -0.2, 0, 0.2, 0.4),
#     txt_gp = forestplot::fpTxtGp(ticks=gpar(cex=1.1), xlab=gpar(cex=1.1)),
#     lwd.ci = 2,           # Thicker CI lines (default is usually 1)
#     boxsize =  0.2       # Larger boxes, keeping relative sizes
#   ) %>% 
#   forestplot::fp_set_style(box = "royalblue",
#                            line = "darkblue",
#                            summary = "royalblue") %>%
#   forestplot::fp_add_header(variable = c("Explanatory Variable"), mean_table = c("Stand. Coefficient"), confint = c("95% CI"), pvalue = c("p-value")) %>%
#   forestplot::fp_set_zebra_style("#EFEFEF")
# dev.off()
# 
# pdf("ForestplotFinalModelFirstWave.pdf", width = 6, height = 3)
# forestplotData %>%
#   forestplot::forestplot(
#     labeltext = c(variable),
#     xlab = "Standardized Coefficient",
#     xticks = c(-0.8, -0.6, -0.4, -0.2, 0, 0.2, 0.4, 0.6, 0.8),
#     txt_gp = forestplot::fpTxtGp(ticks=gpar(cex=1.1), xlab=gpar(cex=1.1)),
#     lwd.ci = 2,           # Thicker CI lines (default is usually 1)
#     boxsize =  0.2       # Larger boxes, keeping relative sizes
#   ) %>% 
#   forestplot::fp_set_style(box = "royalblue",
#                            line = "darkblue",
#                            summary = "royalblue") %>%
#   forestplot::fp_add_header(variable = c("Explanatory Variable")) %>%
#   forestplot::fp_set_zebra_style("#EFEFEF")
# dev.off()

# Regression Second Wave --------------------------------------------------

cases_secondWave <- cases_secondWave %>% ungroup()
cases_secondWave <- left_join(cases_secondWave, RegVariables)
cases_secondWave <- left_join(cases_secondWave, disFac_post)
cases_secondWave <- cases_secondWave %>% unique()

#Correlation matrix
valuetoplotRed <- cases_secondWave %>% ungroup() 

#valuetoplotRed <- valuetoplotRed %>% select(c("Reaction Strength", "Inhabitants per km2", "Voted for Incoming Government", "Small Children (< 3) in Childcare", "Voter Turnout", "Unemployment Rate", "Income"))
corrmat <- cor(valuetoplotRed)
pdf(height = 10, width = 13, "CorrelationPlotSecondWave.pdf")
#pdf(height = 8, width = 13, "CorrelationPlotReduced.pdf")
corrplot(corrmat, method = "color", tl.col="black", type = "upper", tl.srt = 90, tl.cex = 1, cl.pos = "b", diag = FALSE, cl.ratio = 0.25, cl.cex=1.25, mar = c(0,0,1.5,1))
dev.off()

valuetoplotRed <- left_join(valuetoplotRed, disFac_post)

valuetoplotRed <- valuetoplotRed %>% mutate(Inhabitantsperkm2 = scale(Inhabitantsperkm2)) %>%
  mutate(voterTurnout = scale(voterTurnout)) %>%
  mutate(IncomePerson2022 = scale(IncomePerson2022)) %>%
  #mutate(unemploymentQuota = scale(unemploymentQuota)) %>%
  mutate(peopleover65 = scale(peopleover65)) %>%
  mutate(childrenbelow3inprimarycare = scale(childrenbelow3inprimarycare)) %>%
  mutate(`Voted for Parting Government` = scale(`Voted for Parting Government`)) %>%
  mutate(`Voted for Incoming Government` = scale(`Voted for Incoming Government`)) %>%
  mutate(`Average Age` = scale(`Average Age`)) %>%
  mutate(`Employment Rate` = scale(`Employment Rate`)) %>%
  mutate(value = scale(value)) %>%
  mutate(valueInitWave = scale(valueInitWave)) %>%
  mutate(valueSecondWave = scale(valueSecondWave)) %>%
  #mutate(Alq2019 = scale(Alq2019)) %>%
  mutate(Alq2020 = scale(Alq2020)) %>%
  #mutate(Alq2021 = scale(Alq2021)) %>%
  #mutate(Alq20192020Abs = scale(Alq20192020Abs)) %>%
  #mutate(Alq20192021Abs = scale(Alq20192021Abs)) %>%
  #mutate(Kurz042020Rel = scale(Kurz042020Rel)) %>%
  #mutate(Kurz052020Rel = scale(Kurz052020Rel)) %>%    
  #mutate(SPD = scale(SPD)) %>%
  mutate(ForstFischerei = scale(ForstFischerei)) %>%
  mutate(ProduzierendesGewerbe = scale(ProduzierendesGewerbe)) %>%
  mutate(VerarbeitendesGewerbe = scale(VerarbeitendesGewerbe)) %>%
  mutate(Baugewerbe = scale(Baugewerbe)) %>%
  mutate(Dienstleistungsgewerbe = scale(Dienstleistungsgewerbe)) %>%
  mutate(HandelVerkehrGastgewerbe = scale(HandelVerkehrGastgewerbe)) %>%
  mutate(FinanzVersicherung = scale(FinanzVersicherung)) %>%
  mutate(OeffentlichSonstigeDienstleistungen = scale(OeffentlichSonstigeDienstleistungen)) %>%
  #mutate(ReacStrengthSecondWave = scale(ReacStrengthSecondWave)) %>%
  mutate(wave90percentile = scale (wave90percentile))

#Variance of inflation factor
library(car)
vif(lm(wave90percentile ~ . , data = valuetoplotRed)) #All between 1 and 5 --> Some sort of correlation, not large enough to warrant adaptations

# Same Six Variables as for Reaction Strength -----------------------------

bestsubsetSecondWave <- olsrr::ols_step_best_subset(lm(wave90percentile  ~  valueSecondWave + Inhabitantsperkm2 + voterTurnout + IncomePerson2022  + childrenbelow3inprimarycare + `Voted for Incoming Government` + 
                                               `Voted for Parting Government` + peopleover65 + `Employment Rate` + `Average Age` + Alq2020 + 
                                               ForstFischerei + ProduzierendesGewerbe + VerarbeitendesGewerbe + Baugewerbe + Dienstleistungsgewerbe + HandelVerkehrGastgewerbe + FinanzVersicherung + OeffentlichSonstigeDienstleistungen, 
                                             data=valuetoplotRed), metric = "adjr") 

lmTenVariablesSecondWave <- lm(wave90percentile ~ valueSecondWave + IncomePerson2022 + childrenbelow3inprimarycare +
                                 `Voted for Incoming Government` + `Voted for Parting Government`+ peopleover65 + Alq2020 + ProduzierendesGewerbe + VerarbeitendesGewerbe + FinanzVersicherung,
                               data =valuetoplotRed)
summary(lmTenVariablesSecondWave)

forestplotData <-tibble::tibble(mean = c(round(sameSixVariablesSecondWave$coefficients[2],4), round(sameSixVariablesSecondWave$coefficients[3],4), round(sameSixVariablesSecondWave$coefficients[4],2), round(sameSixVariablesSecondWave$coefficients[5],2), round(sameSixVariablesSecondWave$coefficients[6],2), round(sameSixVariablesSecondWave$coefficients[7],2), round(sameSixVariablesSecondWave$coefficients[8],2)),
                                mean_table = c(round(sameSixVariablesSecondWave$coefficients[2],2), round(sameSixVariablesSecondWave$coefficients[3],2), round(sameSixVariablesSecondWave$coefficients[4],2), round(sameSixVariablesSecondWave$coefficients[5],2), round(sameSixVariablesSecondWave$coefficients[6],2), round(sameSixVariablesSecondWave$coefficients[7],2), round(sameSixVariablesSecondWave$coefficients[8],2)),
                                lower = c(confint(sameSixVariablesSecondWave)[2,1], confint(sameSixVariablesSecondWave)[3,1], confint(sameSixVariablesSecondWave)[4,1], confint(sameSixVariablesSecondWave)[5,1], confint(sameSixVariablesSecondWave)[6,1], confint(sameSixVariablesSecondWave)[7,1], confint(sameSixVariablesSecondWave)[8,1]),
                                upper = c(confint(sameSixVariablesSecondWave)[2,2], confint(sameSixVariablesSecondWave)[3,2], confint(sameSixVariablesSecondWave)[4,2], confint(sameSixVariablesSecondWave)[5,2], confint(sameSixVariablesSecondWave)[6,2], confint(sameSixVariablesSecondWave)[7,2], confint(sameSixVariablesSecondWave)[8,2]),
                                confint = c(
                                  paste0("[", as.character(round(confint(sameSixVariablesSecondWave)[2,1], 4)), ",", as.character(round(confint(sameSixVariablesSecondWave)[2,2], 4)), "]"),
                                  paste0("[", as.character(round(confint(sameSixVariablesSecondWave)[3,1], 4)), ",", as.character(round(confint(sameSixVariablesSecondWave)[3,2], 4)), "]"),
                                  paste0("[", as.character(round(confint(sameSixVariablesSecondWave)[4,1], 4)), ",", as.character(round(confint(sameSixVariablesSecondWave)[4,2], 4)), "]"),
                                  paste0("[", as.character(round(confint(sameSixVariablesSecondWave)[5,1], 4)), ",", as.character(round(confint(sameSixVariablesSecondWave)[5,2], 4)), "]"),
                                  paste0("[", as.character(round(confint(sameSixVariablesSecondWave)[6,1], 4)), ",", as.character(round(confint(sameSixVariablesSecondWave)[6,2], 4)), "]"),
                                  paste0("[", as.character(round(confint(sameSixVariablesSecondWave)[7,1], 4)), ",", as.character(round(confint(sameSixVariablesSecondWave)[7,2], 4)), "]"),
                                  paste0("[", as.character(round(confint(sameSixVariablesSecondWave)[8,1], 4)), ",", as.character(round(confint(sameSixVariablesSecondWave)[8,2], 4)), "]")
                                ),
                                pvalue = c(
                                  round(summary(sameSixVariablesSecondWave)$coefficients[,4][2],3),
                                  "p<0.001",
                                  round(summary(sameSixVariablesSecondWave)$coefficients[,4][4],3),
                                  round(summary(sameSixVariablesSecondWave)$coefficients[,4][5],3),
                                  round(summary(sameSixVariablesSecondWave)$coefficients[,4][6],3),
                                  round(summary(sameSixVariablesSecondWave)$coefficients[,4][7],3),
                                  "p<0.001"
                                ),
                                variable = c("Reaction strength second wave", "Population density", "Unemployment quota", "Voter turnout", "Income" , "Small children in childcare", "Voted for incoming government"))

forestplotData <- forestplotData %>% mutate(mean = (-1)*mean, mean_table = (-1)*mean_table, lowersave = lower, lower = (-1)*upper, upper = (-1)*lowersave)

pdf("ForestplotFinalModelSecondWave.pdf", width = 11, height = 3)
forestplotData %>%
  forestplot::forestplot(
    labeltext = c(variable, mean_table, confint, pvalue),
    xlab = "Standardized Coefficient",
    #xticks = c(-16, -12, -8, -4, 0, 4, 8, 12, 16),
    txt_gp = forestplot::fpTxtGp(ticks=gpar(cex=1.1), xlab=gpar(cex=1.1)),
    lwd.ci = 2,           # Thicker CI lines (default is usually 1)
    boxsize =  0.2       # Larger boxes, keeping relative sizes
  ) %>% 
  forestplot::fp_set_style(box = "royalblue",
                           line = "darkblue",
                           summary = "royalblue") %>%
  forestplot::fp_add_header(variable = c("Explanatory Variable"), mean_table = c("Stand. Coefficient"), confint = c("95% CI"), pvalue = c("p-value")) %>%
  forestplot::fp_set_zebra_style("#EFEFEF")
dev.off()

pdf("ForestplotFinalModelSecondWave.pdf", width = 6, height = 3)
forestplotData %>%
  forestplot::forestplot(
    labeltext = c(variable),
    xlab = "Standardized Coefficient",
    xticks = c(-0.8, -0.6, -0.4, -0.2, 0, 0.2, 0.4, 0.6, 0.8),
    txt_gp = forestplot::fpTxtGp(ticks=gpar(cex=1.1), xlab=gpar(cex=1.1)),
    lwd.ci = 2,           # Thicker CI lines (default is usually 1)
    boxsize =  0.2       # Larger boxes, keeping relative sizes
  ) %>% 
  forestplot::fp_set_style(box = "royalblue",
                           line = "darkblue",
                           summary = "royalblue") %>%
  forestplot::fp_add_header(variable = c("Explanatory Variable")) %>%
  forestplot::fp_set_zebra_style("#EFEFEF")
dev.off()

