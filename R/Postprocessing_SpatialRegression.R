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

#run <- "2025-07-02_400LK_exp_UsedForPostprocessing"

outcomeVariable <- "exponential"
run <- "2025-09-14_400_cluster_expdecay_wideealpha"
#run <- "2025-09-14_400_cluster_expdecay_middleealpha"
source("Postprocessing_Clean.R")

disFac_post <- postprocessing_clean(model, consideredWave, run, outcomeVariable)

source("Regressions_DataPrep.R")

disFac_post <- left_join(disFac_post, RegVariables)

#Correlation matrix
valuetoplotRed <- disFac_post %>% dplyr::select(c(value, Inhabitantsperkm2,  
                                                  Alq2020, `Employment Rate`, ForstFischerei, ProduzierendesGewerbe, VerarbeitendesGewerbe, Baugewerbe, Dienstleistungsgewerbe, HandelVerkehrGastgewerbe, FinanzVersicherung, OeffentlichSonstigeDienstleistungen,
                                                  childrenbelow3inprimarycare, peopleover65 , `Average Age`,
                                                  IncomePerson2022,
                                                  voterTurnout,  `Voted for Incoming Government`, `Voted for Parting Government`))
colnames(valuetoplotRed) <- c("Reaction strength", "Population density", 
                              "Unemployment rate", "Employment rate", "Agriculture, forestry, fisheries", "Manufacturing sector", "Processing sector", "Construction", "Service sectors", "TTHIC sectors", "Finance sector", "Public and health sectors",
                              "Small children in childcare", "65+ year olds", "Average age",
                              "Income",
                              "Voter turnout", "Voted for incoming government", "Voted for parting government")
corrmat <- cor(valuetoplotRed)
pdf(height = 12, width = 13, "CorrelationPlot.pdf")
corrplot(corrmat, method = "color", tl.col="black", type = "upper", tl.srt = 90, tl.cex = 1.6, cl.pos = "b", diag = FALSE, cl.ratio = 0.25, cl.cex=1.25, mar = c(0,0,1.5,1))
dev.off()

# Regression Analysis -----------------------------------------------------

# Scaling of Independent Variables ----------------------------------------

valuetoplotRed <- disFac_post

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
                                      mutate(OeffentlichSonstigeDienstleistungen = scale(OeffentlichSonstigeDienstleistungen)) 

#Variance of inflation factor
library(car)
vif(lm(value ~ . , data = valuetoplotRed)) #All between 1 and 5 --> Some sort of correlation, not large enough to warrant adaptations

# Exhaustive Search -------------------------------------------------------

bestsubset <- olsrr::ols_step_best_subset(lm(value ~ Inhabitantsperkm2 + voterTurnout + IncomePerson2022  + childrenbelow3inprimarycare + `Voted for Incoming Government` + 
                                                `Voted for Parting Government` + peopleover65 + `Employment Rate` + `Average Age` + Alq2020 + 
                                               ForstFischerei + ProduzierendesGewerbe + VerarbeitendesGewerbe + Baugewerbe + Dienstleistungsgewerbe + HandelVerkehrGastgewerbe + FinanzVersicherung + OeffentlichSonstigeDienstleistungen, 
                                             data=valuetoplotRed %>% select(-valueInitWave, -valueSecondWave)), metric = "adjr") 

model8variables <- lm(value ~   Inhabitantsperkm2 + Alq2020 + voterTurnout + IncomePerson2022  + ForstFischerei + ProduzierendesGewerbe + childrenbelow3inprimarycare + Baugewerbe, data =valuetoplotRed)
summary(model8variables)

vif(model8variables)

subset_summary <- cbind(bestsubset$metrics[4], bestsubset$metrics[5], bestsubset$metrics[6], bestsubset$metrics[7], bestsubset$metrics[8], bestsubset$metrics[9], bestsubset$metrics[10], bestsubset$metrics[11],
                        bestsubset$metrics[12], bestsubset$metrics[13],  bestsubset$metrics[14])
subset_summary <- round(subset_summary, 4)
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

ggplot(subset_summary %>% filter(name %in% c("R2", "Adjusted R2", "Predicted R2", "Mallow's Cp", "AIC", "BIC")), aes(x=nrow, y = value)) +
  geom_point(color = "blue4", size = 3, aes(shape = factor(is_opt))) +
  geom_line(color = "blue4") +
  scale_x_continuous(breaks = c(2,4,6,8,10,12,14,16,18)) +
  facet_wrap(~name, nrow = 2, scale = "free") + 
  scale_shape_manual(values = c("0" = 21, "1" = 19)) +
  theme_bw() + 
  ylab("Value") +
  xlab("Number of Variables") +
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
    text = element_text(size = 22),  # Affects most text elements
    axis.text = element_text(size = 20, color = "black"),  # Axis labels
    axis.title = element_text(size = 24, color = "black"),  # Axis titles
    plot.title = element_text(size = 28),  # Plot title
    legend.position = "none"
  )

ggsave("MetricsSpatial.pdf", w = 12, h = 6)


# Regression for First/Second Wave ----------------------------------------------

RegressionWholeTime <- lm(value ~  Alq2020 + Inhabitantsperkm2 + voterTurnout + IncomePerson2022  + ForstFischerei + ProduzierendesGewerbe + childrenbelow3inprimarycare + Baugewerbe, data =valuetoplotRed)
summary(RegressionWholeTime)

RegressionFirstWave <- lm(valueInitWave ~  Inhabitantsperkm2 + Alq2020 + voterTurnout + IncomePerson2022  + ForstFischerei + ProduzierendesGewerbe + childrenbelow3inprimarycare + Baugewerbe, data =valuetoplotRed)
summary(RegressionFirstWave)

RegressionSecondWave <- lm(valueSecondWave ~   Inhabitantsperkm2 + Alq2020 + voterTurnout + IncomePerson2022  + ForstFischerei + ProduzierendesGewerbe + childrenbelow3inprimarycare + Baugewerbe, data =valuetoplotRed)
summary(RegressionSecondWave)

# Viz of Marginal Effects -------------------------------------------------

summary(model8variables)

forestplotData <-tibble::tibble(mean = c(round(model8variables$coefficients[2],2), round(model8variables$coefficients[3],2), round(model8variables$coefficients[4],2), round(model8variables$coefficients[5],2), round(model8variables$coefficients[6],2), round(model8variables$coefficients[7],2), round(model8variables$coefficients[8],2), round(model8variables$coefficients[9],2)),
                                mean_table = c(round(model8variables$coefficients[2],2), round(model8variables$coefficients[3],2), round(model8variables$coefficients[4],2), round(model8variables$coefficients[5],2), round(model8variables$coefficients[6],2), round(model8variables$coefficients[7],2), round(model8variables$coefficients[8],2), round(model8variables$coefficients[9],2)),
                                lower = c(confint(model8variables)[2,1], confint(model8variables)[3,1], confint(model8variables)[4,1], confint(model8variables)[5,1], confint(model8variables)[6,1], confint(model8variables)[7,1], confint(model8variables)[8,1], confint(model8variables)[9,1]),
                                upper = c(confint(model8variables)[2,2], confint(model8variables)[3,2], confint(model8variables)[4,2], confint(model8variables)[5,2], confint(model8variables)[6,2], confint(model8variables)[7,2], confint(model8variables)[8,2], confint(model8variables)[8,2]),
                                confint = c(
                                  paste0("[", as.character(round(confint(model8variables)[2,1], 2)), ",", as.character(round(confint(model8variables)[2,2], 2)), "]"),
                                  paste0("[", as.character(round(confint(model8variables)[3,1], 2)), ",", as.character(round(confint(model8variables)[3,2], 2)), "]"),
                                  paste0("[", as.character(round(confint(model8variables)[4,1], 2)), ",", as.character(round(confint(model8variables)[4,2], 2)), "]"),
                                  paste0("[", as.character(round(confint(model8variables)[5,1], 2)), ",", as.character(round(confint(model8variables)[5,2], 2)), "]"),
                                  paste0("[", as.character(round(confint(model8variables)[6,1], 2)), ",", as.character(round(confint(model8variables)[6,2], 2)), "]"),
                                  paste0("[", as.character(round(confint(model8variables)[7,1], 2)), ",", as.character(round(confint(model8variables)[7,2], 2)), "]"),
                                  paste0("[", as.character(round(confint(model8variables)[8,1], 2)), ",", as.character(round(confint(model8variables)[8,2], 2)), "]"),
                                  paste0("[", as.character(round(confint(model8variables)[9,1], 2)), ",", as.character(round(confint(model8variables)[9,2], 2)), "]")
                                ),
                                pvalue = c(
                                  "<0.001",
                                  "<0.001",
                                  round(summary(model8variables)$coefficients[,4][4],3),
                                  round(summary(model8variables)$coefficients[,4][5],3),
                                  round(summary(model8variables)$coefficients[,4][6],3),
                                  round(summary(model8variables)$coefficients[,4][7],3),
                                  round(summary(model8variables)$coefficients[,4][8],3),
                                  round(summary(model8variables)$coefficients[,4][9],3)
                                ),
                                variable = c("Population density", "Unemployment rate", "Voter turnout", "Income", "Forestry, fishing industry", "Manufacturing industry", "Small children in childcare", "Construction"))


pdf("ForestplotFinalModel.pdf", width = 11, height = 3)
forestplotData %>%
  forestplot::forestplot(
    labeltext = c(variable, mean_table, confint, pvalue),
    xlab = "Standardized Coefficient",
    xticks = c(-0.2, -0.1, 0, 0.1, 0.2),
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

pdf("ForestplotFinalModel.pdf", width = 6, height = 5)
forestplotData %>%
  forestplot::forestplot(
    labeltext = c(variable),
    xlab = "Stand. Coefficient",
    xticks = c(-0.2, 0, 0.2, 0.4, 0.6),
    txt_gp = forestplot::fpTxtGp(ticks=gpar(cex=1.5), xlab=gpar(cex=1.7), label = gpar(cex = 1.7)),
    lwd.ci = 2,           # Thicker CI lines (default is usually 1)
    boxsize =  0.2       # Larger boxes, keeping relative sizes
  ) %>% 
  forestplot::fp_set_style(box = "royalblue",
                           line = "darkblue",
                           summary = "royalblue") %>%
  forestplot::fp_add_header(variable = c("Explanatory Variable")) %>%
  forestplot::fp_set_zebra_style("#EFEFEF")
dev.off()


# Viz First Wave ----------------------------------------------------------

forestplotData <-tibble::tibble(mean = c(round(RegressionFirstWave$coefficients[2],2), round(RegressionFirstWave$coefficients[3],2), round(RegressionFirstWave$coefficients[4],2), round(RegressionFirstWave$coefficients[5],2), round(RegressionFirstWave$coefficients[6],2), round(RegressionFirstWave$coefficients[7],2), round(RegressionFirstWave$coefficients[8],2), round(RegressionFirstWave$coefficients[9],2)),
                                mean_table = c(round(RegressionFirstWave$coefficients[2],2), round(RegressionFirstWave$coefficients[3],2), round(RegressionFirstWave$coefficients[4],2), round(RegressionFirstWave$coefficients[5],2), round(RegressionFirstWave$coefficients[6],2), round(RegressionFirstWave$coefficients[7],2), round(RegressionFirstWave$coefficients[8],2), round(RegressionFirstWave$coefficients[9],2)),
                                lower = c(confint(RegressionFirstWave)[2,1], confint(RegressionFirstWave)[3,1], confint(RegressionFirstWave)[4,1], confint(RegressionFirstWave)[5,1], confint(RegressionFirstWave)[6,1], confint(RegressionFirstWave)[7,1], confint(RegressionFirstWave)[8,1], confint(RegressionFirstWave)[9,1]),
                                upper = c(confint(RegressionFirstWave)[2,2], confint(RegressionFirstWave)[3,2], confint(RegressionFirstWave)[4,2], confint(RegressionFirstWave)[5,2], confint(RegressionFirstWave)[6,2], confint(RegressionFirstWave)[7,2], confint(RegressionFirstWave)[8,2], confint(RegressionFirstWave)[8,2]),
                                confint = c(
                                  paste0("[", as.character(round(confint(RegressionFirstWave)[2,1], 2)), ",", as.character(round(confint(RegressionFirstWave)[2,2], 2)), "]"),
                                  paste0("[", as.character(round(confint(RegressionFirstWave)[3,1], 2)), ",", as.character(round(confint(RegressionFirstWave)[3,2], 2)), "]"),
                                  paste0("[", as.character(round(confint(RegressionFirstWave)[4,1], 2)), ",", as.character(round(confint(RegressionFirstWave)[4,2], 2)), "]"),
                                  paste0("[", as.character(round(confint(RegressionFirstWave)[5,1], 2)), ",", as.character(round(confint(RegressionFirstWave)[5,2], 2)), "]"),
                                  paste0("[", as.character(round(confint(RegressionFirstWave)[6,1], 2)), ",", as.character(round(confint(RegressionFirstWave)[6,2], 2)), "]"),
                                  paste0("[", as.character(round(confint(RegressionFirstWave)[7,1], 2)), ",", as.character(round(confint(RegressionFirstWave)[7,2], 2)), "]"),
                                  paste0("[", as.character(round(confint(RegressionFirstWave)[8,1], 2)), ",", as.character(round(confint(RegressionFirstWave)[8,2], 2)), "]"),
                                  paste0("[", as.character(round(confint(RegressionFirstWave)[9,1], 2)), ",", as.character(round(confint(RegressionFirstWave)[9,2], 2)), "]")
                                ),
                                pvalue = c(
                                  "<0.001",
                                  "<0.001",
                                  round(summary(RegressionFirstWave)$coefficients[,4][4],3),
                                  round(summary(RegressionFirstWave)$coefficients[,4][5],3),
                                  round(summary(RegressionFirstWave)$coefficients[,4][6],3),
                                  round(summary(RegressionFirstWave)$coefficients[,4][7],3),
                                  round(summary(RegressionFirstWave)$coefficients[,4][8],3),
                                  round(summary(RegressionFirstWave)$coefficients[,4][9],3)
                                ),
                                variable = c("Population density", "Unemployment rate", "Voter turnout", "Income", "Forestry, fishing industry", "Manufacturing industry", "Small children in childcare", "Construction"))


pdf("ForestplotFinalModelFirstWave.pdf", width = 6, height = 5)
forestplotData %>%
  forestplot::forestplot(
    labeltext = c(variable),
    xlab = "Stand. Coefficient",
    xticks = c(-0.2, 0, 0.2, 0.4, 0.6),
    txt_gp = forestplot::fpTxtGp(ticks=gpar(cex=1.5), xlab=gpar(cex=1.7), label = gpar(cex = 1.7)),
    lwd.ci = 2,           # Thicker CI lines (default is usually 1)
    boxsize =  0.2       # Larger boxes, keeping relative sizes
  ) %>% 
  forestplot::fp_set_style(box = "royalblue",
                           line = "darkblue",
                           summary = "royalblue") %>%
  forestplot::fp_add_header(variable = c("Explanatory Variable")) %>%
  forestplot::fp_set_zebra_style("#EFEFEF")
dev.off()

# Viz Second Wave ---------------------------------------------------------

forestplotData <-tibble::tibble(mean = c(round(RegressionSecondWave$coefficients[2],2), round(RegressionSecondWave$coefficients[3],2), round(RegressionSecondWave$coefficients[4],2), round(RegressionSecondWave$coefficients[5],2), round(RegressionSecondWave$coefficients[6],2), round(RegressionSecondWave$coefficients[7],2), round(RegressionSecondWave$coefficients[8],2), round(RegressionSecondWave$coefficients[9],2)),
                                mean_table = c(round(RegressionSecondWave$coefficients[2],2), round(RegressionSecondWave$coefficients[3],2), round(RegressionSecondWave$coefficients[4],2), round(RegressionSecondWave$coefficients[5],2), round(RegressionSecondWave$coefficients[6],2), round(RegressionSecondWave$coefficients[7],2), round(RegressionSecondWave$coefficients[8],2), round(RegressionSecondWave$coefficients[9],2)),
                                lower = c(confint(RegressionSecondWave)[2,1], confint(RegressionSecondWave)[3,1], confint(RegressionSecondWave)[4,1], confint(RegressionSecondWave)[5,1], confint(RegressionSecondWave)[6,1], confint(RegressionSecondWave)[7,1], confint(RegressionSecondWave)[8,1], confint(RegressionSecondWave)[9,1]),
                                upper = c(confint(RegressionSecondWave)[2,2], confint(RegressionSecondWave)[3,2], confint(RegressionSecondWave)[4,2], confint(RegressionSecondWave)[5,2], confint(RegressionSecondWave)[6,2], confint(RegressionSecondWave)[7,2], confint(RegressionSecondWave)[8,2], confint(RegressionSecondWave)[8,2]),
                                confint = c(
                                  paste0("[", as.character(round(confint(RegressionSecondWave)[2,1], 2)), ",", as.character(round(confint(RegressionSecondWave)[2,2], 2)), "]"),
                                  paste0("[", as.character(round(confint(RegressionSecondWave)[3,1], 2)), ",", as.character(round(confint(RegressionSecondWave)[3,2], 2)), "]"),
                                  paste0("[", as.character(round(confint(RegressionSecondWave)[4,1], 2)), ",", as.character(round(confint(RegressionSecondWave)[4,2], 2)), "]"),
                                  paste0("[", as.character(round(confint(RegressionSecondWave)[5,1], 2)), ",", as.character(round(confint(RegressionSecondWave)[5,2], 2)), "]"),
                                  paste0("[", as.character(round(confint(RegressionSecondWave)[6,1], 2)), ",", as.character(round(confint(RegressionSecondWave)[6,2], 2)), "]"),
                                  paste0("[", as.character(round(confint(RegressionSecondWave)[7,1], 2)), ",", as.character(round(confint(RegressionSecondWave)[7,2], 2)), "]"),
                                  paste0("[", as.character(round(confint(RegressionSecondWave)[8,1], 2)), ",", as.character(round(confint(RegressionSecondWave)[8,2], 2)), "]"),
                                  paste0("[", as.character(round(confint(RegressionSecondWave)[9,1], 2)), ",", as.character(round(confint(RegressionSecondWave)[9,2], 2)), "]")
                                ),
                                pvalue = c(
                                  round(summary(RegressionSecondWave)$coefficients[,4][2],3),
                                  round(summary(RegressionSecondWave)$coefficients[,4][3],3),
                                  round(summary(RegressionSecondWave)$coefficients[,4][4],3),
                                  round(summary(RegressionSecondWave)$coefficients[,4][5],3),
                                  round(summary(RegressionSecondWave)$coefficients[,4][6],3),
                                  round(summary(RegressionSecondWave)$coefficients[,4][7],3),
                                  round(summary(RegressionSecondWave)$coefficients[,4][8],3),
                                  "<0.001"
                                ),
                                variable = c("Population density", "Unemployment rate", "Voter turnout", "Income", "Forestry, fishing industry", "Manufacturing industry", "Small children in childcare", "Construction"))


pdf("ForestplotFinalModelSecondWave.pdf", width = 6, height = 5)
forestplotData %>%
  forestplot::forestplot(
    labeltext = c(variable),
    xlab = "Stand. Coefficient",
    xticks = c(-0.2, 0, 0.2, 0.4, 0.6),
    txt_gp = forestplot::fpTxtGp(ticks=gpar(cex=1.5), xlab=gpar(cex=1.7), label = gpar(cex = 1.7)),
    lwd.ci = 2,           # Thicker CI lines (default is usually 1)
    boxsize =  0.2       # Larger boxes, keeping relative sizes
  ) %>% 
  forestplot::fp_set_style(box = "royalblue",
                           line = "darkblue",
                           summary = "royalblue") %>%
  forestplot::fp_add_header(variable = c("Explanatory Variable")) %>%
  forestplot::fp_set_zebra_style("#EFEFEF")
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