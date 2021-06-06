library(readr)
library(stringr)
library(dplyr)
library(stargazer)
library(lubridate)
library(lmtest)
library(sandwich)
library(lme4)

source("./utils.R")
source("./formatting.R")

#######################################################################
## Formatting data
#######################################################################



#######################################################################
## MODELS
#######################################################################

## controls <- c(
##     "generalcaste",
##     "university",
##     "female",
##     "student",
##     "pregnantwoman",
##     "scaled_log_familymembers",
##     "scaled_distancemedicalcenter"
## )

## specs <- list(
##     c("treatment"),
##     c("treatment", controls),
##     c("treatment*pucca", "kutcha"),
##     c("treatment*pucca", "kutcha", controls)
## )

## hasbednet_panel <- filter(agg_panel, TRUE & hasmosquitonet)


## models <- c(
##     lapply(specs, function(s) {
##         mm_binom(
##             panel,
##             "seekhelpfever",
##             s,
##             controls
##         )
##     }),
##     lapply(specs, function(s) {
##         mm_binom(
##             filter(panel, TRUE & hasmosquitonet),
##             "sleepundernet",
##             s,
##             controls
##         )
##     }),
##     lapply(specs, function(s) {
##         mm_binom(
##             filter(panel, TRUE & hasmosquitonet),
##             "malaria2weeks",
##             s,
##             controls
##         )
##     })
## )

## lapply(models, summary)

## model <- mm_binom(
##     panel, "seekhelpfever", c("treatment*pucca", controls),
##     c(controls)
## )
## summary(model)

## model <- mm_binom(panel, "seekhelpfever", c("fever2weeks"), controls)
## summary(model)

## model <- mm_binom(panel, "fever2weeks", c(), c("familymembers"))
## summary(model)



## model <- mm_binom(
##     ,
##     "sleepundernet"
## )
## summary(model)

## model <- mm_binom(
##     filter(panel, TRUE & hasmosquitonet), "sleepundernet",
##     c("treatment*pucca"), controls
## )
## summary(model)

## model <- mm_binom(panel, "longsleeves", c(), controls)
## summary(model)

## model <- mm_binom(panel, "malaria2weeks", c(), controls)
## summary(model)




## ads <- panel %>%
##     filter(!is.na(admalaria)) %>%
##     group_by(userid, stratumid, treatment, kutcha, pucca, semipucca) %>%
##     summarize()


## ######################################################################
## # Family members under bednet
## ######################################################################

## f <- reformulate(
##     c("(1 | stratumid) + (1 | userid)", "treatment*pucca", controls),
##     "perc_membersbednet"
## )

## model <- glmer(f, family = "binomial", weights = familymembers, panel)
## summary(model)


## model <- lmer(f, members %>% mutate(perc_membersbednet = qlogis(perc_membersbednet)))
## summary(model)


## controls <- c("scaled_log_familymembers", "scaled_log_age", "scaled_distancemedicalcenter", "generalcaste")
## controls <- c()






## # Linear, weighted --
## f <- reformulate(c("(1 | stratumid)", "treatment*pucca + kutcha", controls), "avg_perc_membersbednet")
## model <- lmer(f, agg_panel %>% mutate(across(
##     c("avg_perc_membersbednet"),
##     ~ case_when(.x < 0.05 ~ 0.05, .x > 0.95 ~ 0.95, TRUE ~ .x)
## )) %>% mutate(across(avg_perc_membersbednet, qlogis)), weights = waves_answered)
## summary(model)