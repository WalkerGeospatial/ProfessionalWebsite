library(tidyverse)
library(readxl)
library(e1071)
library(ggplot2)
library(kableExtra)
library(webshot)
library(scales)


df <- read.csv("H:/SIUEGradSchool/Fall2023/GEOG-522_Quant/Data/SelectedCharacteristics_2019_IL_tracts.csv")
head(df)

inputv = df$MedianInc

GetStats <- function(alldata, table, graph, inputv, outpath, caption, xlabel, ylabel, title){

  StatMean <- round(mean(inputv),2)
  StatMedian <- round(median(inputv),2)
  StatMin <- round(min(inputv),2)
  StatMax <- round(max(inputv),2)
  StatIQR <- round(IQR(inputv),2)
  StatSD <- round(sd(inputv),2)
  StatVariance <- round(var(inputv),2)
  StatSkewness <- round(skewness(inputv),2)
  StatKurtosis <- round(kurtosis(inputv),2)
  
  Statistic <- c("Mean", "Median", "Minimum", "Maximum", "Interquartile Range","Standard Deviation", "Variance", "Skewness", "Kurtosis")
  Value <- c(StatMean, StatMedian, StatMin, StatMax, StatIQR, StatSD, StatVariance, StatSkewness, StatKurtosis)
  statdf <- data.frame(Statistic, Value)
  
  html <- kable(statdf, caption = caption) %>%
    kable_classic(full_width=F, html_font = "Sans") %>%
    save_kable(file = file.path(outpath,table), zoom = 2)
  
  p<-ggplot(alldata, aes(x=inputv)) + 
    geom_histogram(color="darkseagreen4", fill="darkseagreen3")+
    ggtitle(title)+
    xlab(xlabel)+
    ylab(ylabel)+
    theme_minimal()+
    theme(text=element_text(size=10,  family="Cambria"))
  ggsave(p, file= file.path(outpath,graph))
  
}

# Median Income
GetStats(df,"MedianIncTable.png","MedianIncGraph.jpg", df$MedianInc,"H:/SIUEGradSchool/Fall2023/GEOG-522_Quant/Assignment2/outputs","Summary Statistics of Median Household Incomes for Illinois Census Tracts","Median Household Income","Count", "Distribution of Median Household Incomes for Illinois Census Tracts")

# White
GetStats(df,"WhiteTable.png","WhiteGraph.jpg", df$White,"H:/SIUEGradSchool/Fall2023/GEOG-522_Quant/Assignment2/outputs","Summary Statistics of Percentage White Population for Illinois Census Tracts","Percentage White Population","Count", "Distribution of Percentage White Population for Illinois Census Tracts")
  
# Black
GetStats(df,"BlackTable.png","BlackGraph.jpg", df$Black,"H:/SIUEGradSchool/Fall2023/GEOG-522_Quant/Assignment2/outputs","Summary Statistics of Percentage Black Population for Illinois Census Tracts","Percentage Black Population","Count", "Distribution of Percentage Black Population for Illinois Census Tracts")

# American Indian
GetStats(df,"AMINDTable.png","AMINDGraph.jpg", df$AMIND,"H:/SIUEGradSchool/Fall2023/GEOG-522_Quant/Assignment2/outputs","Summary Statistics of Percentage American Indian Population for Illinois Census Tracts","Percentage American Indian Population","Count", "Distribution of Percentage American Indian Population for Illinois Census Tracts")

# Asian
GetStats(df,"AsianTable.png","AsianGraph.jpg", df$Asian,"H:/SIUEGradSchool/Fall2023/GEOG-522_Quant/Assignment2/outputs","Summary Statistics of Percentage Asian Population for Illinois Census Tracts","Percentage Asian Population","Count", "Distribution of Percentage Asian Population for Illinois Census Tracts")

# Hawaii
GetStats(df,"HawaiiTable.png","HawaiiGraph.jpg", df$Hawaii,"H:/SIUEGradSchool/Fall2023/GEOG-522_Quant/Assignment2/outputs","Summary Statistics of Percentage Hawaiian Population for Illinois Census Tracts","Percentage Hawaiian Population","Count", "Distribution of Percentage Hawaiian Population for Illinois Census Tracts")

# Hispanic
GetStats(df,"HispanicTable.png","HispanicGraph.jpg", df$Hispanic,"H:/SIUEGradSchool/Fall2023/GEOG-522_Quant/Assignment2/outputs","Summary Statistics of Percentage Hispanic Population for Illinois Census Tracts","Percentage Hispanic Population","Count", "Distribution of Percentage Hispanic Population for Illinois Census Tracts")

# LessHS
GetStats(df,"LessHSTable.png","LessHSGraph.jpg", df$LessHS,"H:/SIUEGradSchool/Fall2023/GEOG-522_Quant/Assignment2/outputs","Summary Statistics of Percentage Without High School Degree for Illinois Census Tracts","Percentage Without High School Degree","Count", "Distribution of Percentage Without High School Degree for Illinois Census Tracts")

# HighSchoolGrad
GetStats(df,"HighSchoolGradTable.png","HighSchoolGradGraph.jpg", df$HighSchoolGrad,"H:/SIUEGradSchool/Fall2023/GEOG-522_Quant/Assignment2/outputs","Summary Statistics of Percentage With Only High School Degree for Illinois Census Tracts","Percentage With Only High School Degree","Count", "Distribution of Percentage With Only High School Degree for Illinois Census Tracts")

# SomeCollege
GetStats(df,"SomeCollegeTable.png","SomeCollegeGraph.jpg", df$SomeCollege,"H:/SIUEGradSchool/Fall2023/GEOG-522_Quant/Assignment2/outputs","Summary Statistics of Percentage With Some College Completed for Illinois Census Tracts","Percentage With Some College Completed","Count", "Distribution of Percentage With Some College Completed for Illinois Census Tracts")

# BachelorDeg
GetStats(df,"BachelorDegTable.png","BachelorDegGraph.jpg", df$BachelorDeg,"H:/SIUEGradSchool/Fall2023/GEOG-522_Quant/Assignment2/outputs","Summary Statistics of Percentage With A Bachelor's Degree for Illinois Census Tracts","Percentage With A Bachelor's Degree","Count", "Distribution of Percentage With A Bachelor's Degree for Illinois Census Tracts")

Statistic <- c("Mean", "Median", "Minimum", "Maximum", "Interquartile Range","Standard Deviation", "Variance", "Skewness", "Kurtosis")
statdf <- data.frame(Statistic)

AddStats <- function(columnname){
  StatMean <- round(mean(columnname),2)
  StatMedian <- round(median(columnname),2)
  StatMin <- round(min(columnname),2)
  StatMax <- round(max(columnname),2)
  StatIQR <- round(IQR(columnname),2)
  StatSD <- round(sd(columnname),2)
  StatVariance <- round(var(columnname),2)
  StatSkewness <- round(skewness(columnname),2)
  StatKurtosis <- round(kurtosis(columnname),2)
  statties <- c(StatMean, StatMedian, StatMin, StatMax, StatIQR, StatSD, StatVariance, StatSkewness, StatKurtosis)
  return(statties)
}

white <- AddStats(df$White)
statdf$White <- white

black <- AddStats(df$Black)
statdf$Black <- black

AMIND <- AddStats(df$AMIND)
statdf$American_Indian <- AMIND

AMIND <- AddStats(df$AMIND)
statdf$American_Indian <- AMIND

Asian <- AddStats(df$Asian)
statdf$Asian <- Asian

Hawaiian <- AddStats(df$Hawaii)
statdf$Hawaiian <- Hawaiian

Hispanic <- AddStats(df$Hispanic)
statdf$Hispanic <- Hispanic

html <- kable(statdf, col.names = c("Statistic","White","Black","American Indian","Asian", "Hawaiian", "Hispanic"), caption = "Summary Statistics of the Percent Racial and Ethnic Makeup of Illinois Census Tracts") %>%
  kable_classic(full_width=F, html_font = "Sans") %>%
  save_kable(file = "H:/SIUEGradSchool/Fall2023/GEOG-522_Quant/Assignment2/outputs/RaceTable.png", zoom = 2)

Edudf <- data.frame(Statistic)

LessHS <- AddStats(df$LessHS)
Edudf$LessHS <- LessHS

HighSchoolGrad <- AddStats(df$HighSchoolGrad)
Edudf$HighSchoolGrad <- HighSchoolGrad

SomeCollege <- AddStats(df$SomeCollege)
Edudf$SomeCollege <- SomeCollege

BachelorDeg <- AddStats(df$BachelorDeg)
Edudf$BachelorDeg <- BachelorDeg

html <- kable(Edudf, col.names = c("Statistic","Without HS Degree","Only HS Degree","Some College Completed","Bachelor's Degree"), caption = "Summary Statistics of the Percent Educational Attainment of Illinois Census Tracts") %>%
  kable_classic(full_width=F, html_font = "Sans") %>%
  save_kable(file = "H:/SIUEGradSchool/Fall2023/GEOG-522_Quant/Assignment2/outputs/EducationTable.png", zoom = 2)

df$zLessHS <- (df$LessHS-mean(df$LessHS))/sd(df$LessHS)
df$zHighSchoolGrad <- (df$HighSchoolGrad-mean(df$HighSchoolGrad))/sd(df$HighSchoolGrad)
df$zSomeCollege <- (df$SomeCollege-mean(df$SomeCollege))/sd(df$SomeCollege)
df$zBachelorDeg <- ((df$BachelorDeg-mean(df$BachelorDeg))/sd(df$BachelorDeg)*2)
df$averageZ <- (((df$zLessHS*-1)+df$zHighSchoolGrad+df$zSomeCollege+df$zBachelorDeg)/4)
df$rescaleZ <- (df$averageZ + abs(min(df$averageZ))) / (max(df$averageZ) + abs(min(df$averageZ))) * 100

# education index
GetStats(df,"PercentTable.png","PercentGraph.jpg", df$rescaleZ,"H:/SIUEGradSchool/Fall2023/GEOG-522_Quant/Assignment2/outputs","Summary Statistics of the Calculated Educational Index","Educational Index","Count", "Distribution of Calculated Educational Index for Illinois Census Tracts")

# Calculate the threshold for the top 25% of data
threshold <- quantile(df$rescaleZ, 0.75)

# Create a ggplot histogram
p <- ggplot(df, aes(x = df$rescaleZ)) +
  geom_histogram(aes(fill = ifelse(df$rescaleZ >= threshold, "Highly Educated", "Other")),
                 binwidth = 5, color = "black",size=0.1) +
  scale_fill_manual(values = c("Highly Educated" = "darkorange", "Other" = "deepskyblue")) +
  labs(x = "Educational Index", y = "Count", title = "Census Tracts Considered Highly Educated",color="Legend", fill="Legend") +
  theme_minimal()+
  theme(text=element_text(size=12,  family="Cambria"))

ggsave(p, file= "H:/SIUEGradSchool/Fall2023/GEOG-522_Quant/Assignment2/outputs/SelectedTracts.jpg")


df$whitediff <- (abs(16.67-df$White))
df$blackdiff <- (abs(16.67-df$Black))
df$AMINDdiff <- (abs(16.67-df$AMIND))
df$Asiandiff <- (abs(16.67-df$Asian))
df$Hawaiidiff <- (abs(16.67-df$Hawaii))
df$Hispanicdiff <- (abs(16.67-df$Hispanic))
df$totaldiff <- df$whitediff + df$blackdiff + df$AMINDdiff + df$Asiandiff + df$Hawaiidiff + df$Hispanicdiff
df$rescalediff <- abs((rescale(df$totaldiff,to = c(0,100)))-100)

# diversity index
GetStats(df,"DiversityTable.png","DiversityGraph.jpg", df$rescalediff,"H:/SIUEGradSchool/Fall2023/GEOG-522_Quant/Assignment2/outputs","Summary Statistics of the Calculated Diversity Index","Diversity Index","Count", "Distribution of Calculated Diversity Index for Illinois Census Tracts")

# Calculate the thresholds for the top 25% and bottom 25% of data
threshold_top <- quantile(df$rescalediff, 0.75)
threshold_bottom <- quantile(df$rescalediff, 0.25)
print(threshold_top)
print(threshold_bottom)
# Create a ggplot histogram
p <- ggplot(df, aes(x = df$rescalediff)) +
  geom_histogram(aes(fill = ifelse(df$rescalediff >= threshold_top, "Diverse",
                                   ifelse(df$rescalediff <= threshold_bottom, "Segregated", "Other"))),
                 binwidth = 5, color = "black",size=0.1) +
  scale_fill_manual(values = c("Diverse" = "darkorange", "Other" = "deepskyblue", "Segregated"="aquamarine3")) +
  labs(x = "Diversity Index", y = "Count", title = "Census Tracts Considered Relatively Diverse/Segregated",color="Legend", fill="Legend") +
  theme_minimal()+
  theme(text=element_text(size=12,  family="Cambria"))

ggsave(p, file= "H:/SIUEGradSchool/Fall2023/GEOG-522_Quant/Assignment2/outputs/SelectedDiverseTracts.jpg")

p <- ggplot(df, aes(x = df$rescalediff)) +
  geom_density(aes(fill = ifelse(df$rescalediff >= threshold_top, "Diverse",
                                   ifelse(df$rescalediff <= threshold_bottom, "Segregated", "Other"))),
                 binwidth = 5, color = "black",size=0.1) +
  scale_fill_manual(values = c("Diverse" = "darkorange", "Other" = "deepskyblue", "Segregated"="aquamarine3")) +
  labs(x = "Diversity Index", y = "Count", title = "Census Tracts Considered Relatively Diverse/Segregated",color="Legend", fill="Legend") +
  theme_minimal()+
  theme(text=element_text(size=12,  family="Cambria"))

ggsave(p, file= "H:/SIUEGradSchool/Fall2023/GEOG-522_Quant/Assignment2/outputs/SelectedDiverseTractsDensity.jpg")
