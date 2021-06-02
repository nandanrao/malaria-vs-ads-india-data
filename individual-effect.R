library(readr)
library(stringr)
library(dplyr)
library(stargazer)

source("./utils.R")
source("./formatting.R")

#######################################################################
## Formatting data
#######################################################################

ied <- read_csv("data/final/regression-data/individual.csv") %>%
    binarize(binary_confs) %>%
    deal_with_numbers() %>%
    group_by(userid) %>%
    filter(all(answer_time_90 / answer_time_min >= 1.5), .preserve = TRUE) %>%
    filter(!any(invalid_answer_count >= 20), .preserve = TRUE) %>%
    summarize_all(pick_non_na) %>%
    filter(age < 90 & age > 17) %>%
    filter(!is.na(admalaria)) %>%
    ordinalize(factor_confs)


controls <- c(
    "generalcaste",
    "university",
    "female",
    "student",
    "pregnantwoman",
    "treatment",
    "log_age",
    "log_familymembers",
    "scaled_distancemedicalcenter"
)


specs <- list(
    c("ind_treatment"),
    c("ind_treatment", controls),
    c("ind_treatment*kutcha", "ind_treatment*pucca", controls),
    c("ind_treatment*pucca", controls),
    c("ind_treatment", "admalaria")
)


#######################################################################
## Logistic Regression
#######################################################################
logreg_models <- c(
    lapply(specs, function(s) {
        glm(reformulate(s, "sleepundernet"),
            filter(ied, hasmosquitonet == 1),
            family = "binomial"
        )
    }),
    lapply(specs, function(s) {
        glm(reformulate(s, "longsleeves"),
            ied,
            family = "binomial"
        )
    }),
    lapply(specs, function(s) {
        glm(reformulate(s, "notworriedmalaria"),
            ied,
            family = "binomial"
        )
    })
)

lapply(logreg_models, summary)
stargazer(logreg_models)



#######################################################################
## OLS
#######################################################################


ols_models <- c(
    lapply(specs, function(s) {
        lm(
            reformulate(s, "sleepundernet"),
            filter(ied, hasmosquitonet == 1)
        )
    }),
    lapply(specs, function(s) lm(reformulate(s, "longsleeves"), ied)),
    lapply(specs, function(s) lm(reformulate(s, "notworriedmalaria"), ied))
)

lapply(ols_models, summary)

stargazer(ols_models)


# Two weird things:
# 1. semipucca are for some reason way less worried about malaria
# after treatment. This makes no sense. Must be a confounder that is
# by chance unbalanced.
# 2. treated pucca are less likely to wear longsleeves?? Also random.
#
# TODO: Write a function to look over a set of variables
# for balance with regards to a set of other variables (i.e.
# ind_treatment*semipucca vs. rest)