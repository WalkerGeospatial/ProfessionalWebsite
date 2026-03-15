library(sf)
library(tidyverse)
library(tidycensus)
library(corrr)
library(tmap)
library(spdep)
library(tigris)
library(rmapshaper)
library(flextable)
library(car)
library(spatialreg)
library(stargazer)
library(lmtest)
library(MASS)
library(GWmodel)
library(lctools)


# Read Data
tractsSF <- read_sf("C:/Users/Nathan Walker/Downloads/IL_Lag_error (1)/IL_Lag_error.shp")

# Create Model
Q1OLS <- lm(Pct_Pov100 ~ Pct_white + Pct_Black + Pct_Hisp + Pct_asian + Pct_colleg + Pct_Unem_1 + Pct_Manage,data = tractsSF)

# Create Table
summary(Q1OLS)
stargazer(Q1OLS, type = "html",dep.var.labels = "% 100% Below Poverty", covariate.labels = c("% White","% Black", "% Hisp", "% Asian", "% College", "% Unemployed", "% Managerial"), out = "Q1OLS.html")

# Create a neighbors matrix
tractsSFNB <- poly2nb(tractsSF, queen=T)

# Create a weights matrix
tractsW <- nb2listw(tractsSFNB, style="W", zero.policy = TRUE)

lm.morantest(Q1OLS, tractsW)

# Test for both a spatial lag model and a spatial error model
results <- lm.LMtests(Q1OLS, tractsW, test=c("LMerr", "LMlag"))

# Print the results
summary(results)

Q1Lag <- lagsarlm(Pct_Pov100 ~ Pct_white + Pct_Black + Pct_Hisp + Pct_asian + Pct_colleg + Pct_Unem_1 + Pct_Manage, data = tractsSF, tractsW)
summary(Q1Lag)

stargazer(Q1Lag, type = "html",add.lines=list(c("Rho","0.573***"),c("","(0.018)")), dep.var.labels = "% 100% Below Poverty", covariate.labels = c("% White","% Black", "% Hisp", "% Asian", "% College", "% Unemployed", "% Managerial"), out = "Q1LAG.html")

Q1Error <- errorsarlm(Pct_Pov100 ~ Pct_white + Pct_Black + Pct_Hisp + Pct_asian + Pct_colleg + Pct_Unem_1 + Pct_Manage, data = tractsSF, tractsW)
summary(Q1Error)

stargazer(Q1Error, type = "html",add.lines=list(c("Lambda","0.681***"),c("","(0.017)")), dep.var.labels = "% 100% Below Poverty", covariate.labels = c("% White","% Black", "% Hisp", "% Asian", "% College", "% Unemployed", "% Managerial"), out = "Q1ERROR.html")

stargazer(Q1OLS, Q1Lag, Q1Error, type = "html",add.lines=list(c("Rho/Lambda","","0.573***","0.681***"),c("Std. Error","","(0.018)","(0.017)")), model.names = FALSE, column.labels = c("OLS","Spatial Lag", "Spatial Error"), dep.var.labels = "% 100% Below Poverty", covariate.labels = c("% White","% Black", "% Hisp", "% Asian", "% College", "% Unemployed", "% Managerial"),title="Table 1: Q1 Regression Results", out = "Q1COMBINED.html")

#----------------------------------------------------
# Create Model
Q2OLS <- lm(Pct_colleg ~ Pct_white + Pct_Black + Pct_Hisp + Pct_asian + Pct_Unem_1, data = tractsSF)

# Create Table
summary(Q2OLS)
stargazer(Q2OLS, type = "html",dep.var.labels = "% With a Bachelor's Degree", covariate.labels = c("% White","% Black", "% Hisp", "% Asian", "% Unemployed"), out = "Q2OLS.html")

# Create a neighbors matrix
tractsSFNB <- poly2nb(tractsSF, queen=T)

# Create a weights matrix
tractsW <- nb2listw(tractsSFNB, style="W", zero.policy = TRUE)

lm.morantest(Q2OLS, tractsW)

# Test for both a spatial lag model and a spatial error model
results <- lm.LMtests(Q2OLS, tractsW, test=c("LMerr", "LMlag"))

# Print the results
summary(results)

Q2Lag <- lagsarlm(Pct_colleg ~ Pct_white + Pct_Black + Pct_Hisp + Pct_asian + Pct_Unem_1, data = tractsSF, tractsW)
summary(Q2Lag)

stargazer(Q2Lag, type = "html",add.lines=list(c("Rho","0.573***"),c("","(0.018)")), dep.var.labels = "% With a Bachelor's Degree", covariate.labels = c("% White","% Black", "% Hisp", "% Asian", "% Unemployed"), out = "Q2LAG.html")

Q2Error <- errorsarlm(Pct_colleg ~ Pct_white + Pct_Black + Pct_Hisp + Pct_asian + Pct_Unem_1, data = tractsSF, tractsW)
summary(Q2Error)

stargazer(Q2Error, type = "html",add.lines=list(c("Lambda","0.681***"),c("","(0.017)")), dep.var.labels = "% With a Bachelor's Degree", covariate.labels = c("% White","% Black", "% Hisp", "% Asian", "% Unemployed"), out = "Q2ERROR.html")

stargazer(Q2OLS, Q2Lag, Q2Error, type = "html",add.lines=list(c("Rho/Lambda","","0.797***","0.852***"),c("Std. Error","","(0.012)","(0.011)")), model.names = FALSE, column.labels = c("OLS","Spatial Lag", "Spatial Error"), dep.var.labels = "% With a Bachelor's Degree", covariate.labels = c("% White","% Black", "% Hisp", "% Asian", "% Unemployed"),title="Table 2: Q2 Regression Results", out = "Q2COMBINED.html")

