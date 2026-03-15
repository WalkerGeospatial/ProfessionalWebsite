library(tidyverse)
library(readxl)
library(e1071)
library(ggplot2)
library(kableExtra)
library(webshot)
library(scales)
library(ggpubr)
library(haven)
library(corrplot)

# Define a function to perform correlation tests all at once
correlation_tests <- function(target_field, data, fields) {
  results <- data.frame(Variable = character(0),
                         Correlation = numeric(0),
                         "R-squared" = numeric(0),
                         "P-value" = numeric(0),
                         stringsAsFactors = FALSE)
  
  for (field in fields) {
    if (field != target_field) {
      correlation <- cor.test(data[[target_field]], data[[field]])
      
      results <- rbind(results, data.frame(
        Variable = field,
        Correlation = correlation$estimate,
        "R-squared" = correlation$estimate^2,
        "P-value" = correlation$p.value
      ))
    }
  }
  rownames(results) <- NULL
  return(results)
}


calculate_r_squared <- function(x, y) {
  # Run a correlation test using cor.test
  correlation_result <- cor.test(x, y, use = "complete.obs")
  
  # Extract the correlation coefficient (Pearson's r) from the test result
  correlation_coefficient <- correlation_result$estimate
  
  # Calculate R-squared
  r_squared <- correlation_coefficient^2
  
  return(r_squared)
}


# Examples
df <- read.csv("H:/SIUEGradSchool/Fall2023/GEOG-522_Quant/Data/SelectedCharacteristics_2019_IL_tracts.csv")

# cor(x, y, method = c("pearson", "kendall", "spearman"))
# cor.test(x, y, method=c("pearson", "kendall", "spearman"))

cor(df$Black, df$MedianInc, method = "pearson")
cor.test(df$Black, df$MedianInc, method = "pearson")

# ggscatter(my_data, x = "mpg", y = "wt", 
# add = "reg.line", conf.int = TRUE, 
# cor.coef = TRUE, cor.method = "pearson",
# xlab = "Miles/(US) gallon", ylab = "Weight (1000 lbs)")

ggscatter(
  df, x = 'Black', y = 'MedianInc', add = "reg.line", conf.int = TRUE, cor.coef = TRUE, cor.method = "pearson", xlab = "Percent Black Population", ylab = "Median Income")
)

# # Question 1
# 
# savdata <- read_sav("H:/SIUEGradSchool/Fall2023/GEOG-522_Quant/Data/GSS_2018.sav")
# 
# subset <- savdata[,c("AGE","ATTEND","CHILDS","WWWHR","TVHOURS")]
# r2row <- c(calculate_r_squared(subset$AGE,subset$ATTEND),calculate_r_squared(subset$Age,subset$CHILDS),calculate_r_squared(subset$Age,subset$WWWHR), calculate_r_squared(subset$Age,subset$TVHOURS))
# collnames <- c("Age","Church\nAttendance","# of Children","Internet Hours","TV Hours")
# colnames(subset) <- collnames
# correlationsQ1 <- cor(subset, use = "complete.obs")
# correlationsP <- cor.mtest(subset, conf.level = 0.95)
# round(correlationsQ1,2)
# 
# corrplot.mixed(correlationsQ1, p.mat =correlationsP$p, sig.level = c(0.001, 0.01, 0.05), upper = 'ellipse', lower = 'number', lower.col = 'black', insig = 'label_sig')
# 
# r2matrix <-correlationsQ1*correlationsQ1
# 
# outputtable <- round(as.data.frame(r2matrix),2)
# 
# rownames(outputtable) <- NULL
# 
# outputrow <-outputtable[1,]
# 
# outputrow[1,1] <- "Age"
# 
# html <- kable(outputrow, col.names = c("","Church\nAttendance","# of Children","Internet Hours","TV Hours"), caption = "Table 1: Question 1 Calculated R Squared Values") %>%
#   kable_classic(full_width=F, html_font = "Sans") %>%
#   save_kable(file = "H:/SIUEGradSchool/Fall2023/GEOG-522_Quant/Assignment4/Q1.png", zoom = 2)

# Actual Question 1

savdata <- read_sav("H:/SIUEGradSchool/Fall2023/GEOG-522_Quant/Data/GSS_2018.sav")

subset <- savdata[,c("AGE","ATTEND","CHILDS","WWWHR","TVHOURS")]

outputQ1 <- correlation_tests("AGE", subset, c("ATTEND","CHILDS","WWWHR","TVHOURS"))

print(outputQ1)

outputQ1$Variable = c("Church Attendance", "No. of Children", "Internet Hours", 'TV Hours')
outputQ1$P.value = c("<0.01", "<0.01", "<0.01", "<0.01")

html <- kable(outputQ1, caption = "Table 1: Question 1 Correlation Tests With Age", col.names = c("Variable", "Coefficient","R-Squared", "P-Value")) %>%
  kable_classic(full_width=F, html_font = "Times New Roman") %>%
  save_kable(file = "H:/SIUEGradSchool/Fall2023/GEOG-522_Quant/Assignment4/Q1.png", zoom = 2)

# Question 2

savdata <- read_sav("C:/Users/Nathan Walker/Downloads/States.sav")

subset <- savdata[,c("South","BA","TrafDths17","Internet","ChildPoor")]

outputQ2South <- correlation_tests("South", subset, c("TrafDths17","Internet","ChildPoor"))

print(outputQ2South)

outputQ2South$Variable = c("2017 Traffic Fatalities", "% HH with Internet", "% Children in Poverty")

outputQ2South$P.value = c("<0.01", "<0.01", "<0.01")

outputQ2BA <- correlation_tests("BA", subset, c("TrafDths17","Internet","ChildPoor"))

print(outputQ2BA)

outputQ2BA$Variable = c("2017 Traffic Fatalities", "% HH with Internet", "% Children in Poverty")

outputQ2BA$P.value = c("<0.01", "<0.01", "<0.01")

combined <- rbind(outputQ2South, outputQ2BA)
html <- kable(combined, caption = "Table 2: Question 2 Correlation Tests With Southern State and Bachelor's Education", col.names = c("Variable", "Coefficient","R-Squared", "P-Value")) %>%
  kable_classic(full_width=F, html_font = "Times New Roman") %>%
  pack_rows("Southern State", 1,3) %>%
  pack_rows("% Bachelor's Education", 4,6) %>%
  save_kable(file = "H:/SIUEGradSchool/Fall2023/GEOG-522_Quant/Assignment4/Q2.png", zoom = 2)

# Question 3

savdata <- read_sav("C:/Users/Nathan Walker/Downloads/States.sav")

subset <- savdata[,c("Homicide","CarTheft","PopGrow","CopSpend","Unempl")]

outputQ3PopGrow <- correlation_tests("PopGrow", subset, c("Homicide","CarTheft"))

print(outputQ3PopGrow)

outputQ3PopGrow$Variable = c("Homicide Rate", "Rate of Auto Theft")

outputQ3CopSpend <- correlation_tests("CopSpend", subset, c("Homicide","CarTheft"))

print(outputQ3CopSpend)

outputQ3CopSpend$Variable = c("Homicide Rate", "Rate of Auto Theft")

outputQ3Unempl <- correlation_tests("Unempl", subset, c("Homicide","CarTheft"))

print(outputQ3Unempl)

outputQ3Unempl$Variable = c("Homicide Rate", "Rate of Auto Theft")

combined <- rbind(outputQ3PopGrow, outputQ3CopSpend, outputQ3Unempl)
html <- kable(combined, caption = "Table 3: Question 3 Correlation Tests for Population Growth, Police Expenditures, and Unemployment Rate on Homicide Rates and Car Theft", col.names = c("Variable", "Coefficient","R-Squared", "P-Value")) %>%
  kable_classic(full_width=F, html_font = "Times New Roman") %>%
  pack_rows("Population Growth", 1,2) %>%
  pack_rows("Police Expenditures", 3,4) %>%
  pack_rows("Unemployment Rate", 5,6) %>%
  save_kable(file = "H:/SIUEGradSchool/Fall2023/GEOG-522_Quant/Assignment4/Q3.png", zoom = 2)

# Question 4

savdata <- read_sav("C:/Users/Nathan Walker/Downloads/States.sav")

subset <- savdata[,c("MdHHinc","Theft","Robbery","Rape","Burglary")]
colnames(subset) <- c("HH Income","Theft","Robbery","Rape","Burglary")
correlationsQ4 <- cor(subset, use = "complete.obs")
correlationsP <- cor.mtest(subset, conf.level = 0.95)
corrplot(correlationsQ4, method = "color", type = "lower",p.mat =correlationsP$p, sig.level = c(0.001, 0.01, 0.05),insig = 'label_sig', tl.col="black",pch.cex = 2, tl.cex=1,addCoef.col = "black",mar=c(1,1,2,1))
title(sub = "Figure 1: Correlation Matrix of Tested Crime Variables and Household Income")
