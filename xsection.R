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

xsection <- read_csv("data/final/regression-data/xsection.csv") %>%
    binarize(binary_confs) %>%
    deal_with_numbers() %>%
    filter(!is.na(dwelling)) %>%
    filter(answer_time_90 / answer_time_min >= 1.5) %>%
    filter(invalid_answer_count <= 20) %>%
    filter(age < 90 & age > 17 & familymembers < 30) %>%
    mutate(across(c(
        "cluster_population",
        "cluster_CPM",
        "cluster_CTR",
    ), ~ scale(log(.x))))


hadfever <- filter(xsection, !is.na(seekhelpfever))
sought_help <- filter(xsection, seekhelpfever == TRUE)
sought_help_malaria <- filter(xsection, testmalaria == TRUE)

controls <- c(
    "generalcaste",
    "female",
    "student",
    "pregnantwoman",
)

specs <- list(
    c("treatment", controls),
    c("treatment*kutcha", "treatment*pucca"),
    c("treatment*pucca"),
    c("treatment*pucca", controls)
)

#######################################################################
## Logistic Random Effects Model
#######################################################################
me_models <- c(
    lapply(specs, partial(mixed_effects, hadfever, "seekhelpfever")),
    lapply(specs, partial(mixed_effects, xsection, "malaria4months")),
    lapply(specs, partial(mixed_effects, xsection, "fever4months"))
)


lapply(me_models, summary)


for (outcome in me_models) {
    stargazer(outcome)
}


# TODO: POOL seekhelpfever with panel...


#######################################################################
## Logistic Regression with Clustered Standard Errors
#######################################################################
logreg_models <- list(
    lapply(specs, partial(logistic_regression, hadfever, "seekhelpfever")),
    lapply(specs, partial(logistic_regression, xsection, "malaria4months")),
    lapply(specs, partial(logistic_regression, xsection, "fever4months"))
)

logreg_models

for (outcome in logreg_models) {
    stargazer(outcome)
}