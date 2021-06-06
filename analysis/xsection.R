library(lme4)
library(purrr)
library(stringr)
library(readr)
library(dplyr)
library(stargazer)
library(sandwich)
library(lmtest)


source("./utils.R")
source("./formatting.R")

#######################################################################
## Formatting data
#######################################################################




## hadfever <- filter(xsection, !is.na(seekhelpfever))
## sought_help <- filter(xsection, seekhelpfever == TRUE)
## sought_help_malaria <- filter(xsection, testmalaria == TRUE)