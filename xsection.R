library(lme4)
library(purrr)
library(stringr)
library(readr)
library(dplyr)
library(stargazer)
library(sandwich)
library(lmtest)


source('./utils.R')

#######################################################################
## Formatting data
#######################################################################

binary_cols <- list(
    bin_conf("malaria4months", "Yes"),
    bin_conf("seekhelpfever", "Yes"),
    bin_conf("fever4months", "Yes"),
    bin_conf("dwelling", "Kutcha (made of mud, tin, straw)", "kutcha"),
    bin_conf("dwelling", "Pucca (have cement/brick wall and floor", "pucca"),
    bin_conf("education", "University degree or higher", "university"),
    bin_conf("occupation", "Unemployed", "unemployed"),
    bin_conf("gender", "Female", "female"),
    bin_conf("timeseekhelpfever", "Less than 24 hours", "feverquickhelp"),
    bin_conf("timeseekhelpfever", "More than 2 days", "feverslowhelp"),
    bin_conf("timeseekhelpmalaria", "Less than 24 hours", "malariaquickhelp"),
    bin_conf("timeseekhelpmalaria", "More than 2 days", "malariaslowhelp")
)

df <- read_csv('data/final/regression-data/xsection.csv') %>%
    binarize(binary_cols) %>%
    filter(!is.na(dwelling)) %>% # didn't finish the survey
    filter(answer_time_90 / answer_time_min >= 1.5) %>% # consistently answer fast
    filter(invalid_answer_count <= 20) %>% # spamming
    replace_cols(parse_numbers, c('age', 'familymembers')) %>%
    filter(age < 90 & familymembers < 30) %>% # remove users with bad ages/familymember amounts
    replace_cols(scale, c('cluster_population', 'cluster_CPM', 'cluster_CTR', 'age', 'familymembers')) # scale number columns for algo


hadfever <- filter(df, !is.na(seekhelpfever))
sought_help <- filter(df, seekhelpfever == TRUE)
sought_help_malaria <- filter(df, testmalaria == TRUE)

controls <- c('university', 'unemployed', 'cluster_population', 'cluster_CPM', 'cluster_malaria5year', 'cluster_CTR', 'female')

specs <- list(
    c('treatment'),
    c('treatment*kutcha'),
    c('treatment*pucca'),
    c('treatment*pucca', controls)
)

#######################################################################
## Logistic Random Effects Model
#######################################################################
me_models <- list(
    lapply(specs, partial(mixed_effects, hadfever, 'seekhelpfever')),
    lapply(specs, partial(mixed_effects, df, 'malaria4months')),
    lapply(specs, partial(mixed_effects, df, 'fever4months'))
)

me_models

for (outcome in me_models) {
    stargazer(outcome)
}


#######################################################################
## Logistic Regression with Clustered Standard Errors
#######################################################################
logreg_models <- list(
    lapply(specs, partial(logistic_regression, hadfever, 'seekhelpfever')),
    lapply(specs, partial(logistic_regression, df, 'malaria4months')),
    lapply(specs, partial(logistic_regression, df, 'fever4months'))
)

logreg_models

for (outcome in logreg_models) {
    stargazer(outcome)
}
