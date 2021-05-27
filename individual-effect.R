library(readr)
library(stringr)
library(dplyr)
library(stargazer)

source('./utils.R')

#######################################################################
## Formatting data
#######################################################################

binary_cols <- list(
    bin_conf("dwelling", "Kutcha (made of mud, tin, straw)", "kutcha"),
    bin_conf("dwelling", "Pucca (have cement/brick wall and floor", "pucca"),
    bin_conf("education", "University degree or higher", "university"),
    bin_conf("occupation", "Unemployed", "unemployed"),
    bin_conf("gender", "Female", "female"),
    bin_conf("sleepundernet", "Yes"),
    bin_conf("hasmosquitonet", "Yes"),
    bin_conf("longsleeves", "Yes"),
    bin_conf("admalaria", "Yes")
)


df <- read_csv('data/final/regression-data/individual.csv') %>%
    binarize(binary_cols) %>%
    replace_cols(parse_numbers, c('age', 'familymembers')) %>%
    group_by(userid) %>%
    filter(all(answer_time_90 / answer_time_min >= 1.5), .preserve=TRUE) %>%
    filter(!any(invalid_answer_count >= 20), .preserve=TRUE) %>%
    summarize_all(pick_non_na) %>%
    filter(!is.na(admalaria))

hasnet <- filter(df, hasmosquitonet == 1)



specs <- list(
    'treatment*ind_treatment',
    'treatment*ind_treatment*kutcha',
    'treatment*ind_treatment*pucca',
    'treatment*ind_treatment + admalaria'
)


#######################################################################
## Logistic Regression
#######################################################################
logreg_models <- c(
    lapply(specs, function(s) glm(reformulate(s, 'sleepundernet'), hasnet, family='binomial')),
    lapply(specs, function(s) glm(reformulate(s, 'longsleeves'), df, family='binomial'))
)

lapply(logreg_models, summary)

stargazer(logreg_models)



#######################################################################
## OLS
#######################################################################

ols_models <- c(
    lapply(specs, function(s) lm(reformulate(s, 'sleepundernet'), hasnet)),
    lapply(specs, function(s) lm(reformulate(s, 'longsleeves'), df))
)

lapply(ols_models, summary)

stargazer(ols_models)
