library(readr)
library(lubridate)

source("./utils.R")
source("./formatting.R")


#######################################################################
## Dataframes
#######################################################################

xsection <- read_csv("data/final/regression-data/xsection.csv") %>%
    binarize(binary_confs) %>%
    ordinalize(factor_confs) %>%
    deal_with_numbers() %>%
    filter(!is.na(dwelling)) %>%
    filter(answer_time_90 / answer_time_min >= 1.5) %>%
    filter(invalid_answer_count <= 20) %>%
    filter(age < 90 & age > 17 & familymembers < 30) %>%
    mutate(across(c(
        "cluster_population",
        "cluster_CPM",
        "cluster_CTR",
    ), ~ scale(log(.x)))) %>%
    filter(stratumid != "ff099f99") # Balrampur was accidentally in two states


individual_effect <- read_csv("data/final/regression-data/individual.csv") %>%
    binarize(binary_confs) %>%
    deal_with_numbers() %>%
    group_by(userid) %>%
    filter(all(answer_time_90 / answer_time_min >= 1.5), .preserve = TRUE) %>%
    filter(!any(invalid_answer_count >= 20), .preserve = TRUE) %>%
    summarize_all(pick_non_na) %>%
    filter(age < 90 & age > 17 & familymembers < 30) %>%
    filter(!is.na(admalaria)) %>%
    ordinalize(factor_confs)


full_panel <- read_csv("data/final/regression-data/panel.csv") %>%
    binarize(binary_confs) %>%
    ordinalize(factor_confs) %>%
    deal_with_numbers() %>%
    mutate(survey_start_time = ymd_hms(survey_start_time)) %>%
    group_by(userid) %>%
    mutate(
        across(all_of(all_possible_covariates), pick_non_na),
        waves_answered = n()
    ) %>%
    ungroup() %>%
    mutate(across(
        c("membersbednet"),
        ~ capped_percentage(.x, familymembers),
        .names = "perc_{.col}"
    ))  %>%
    filter(stratumid != "ff099f99") # Balrampur was accidentally in two states


baseline <- full_panel %>%
    filter(wave == 0) %>%
    filter(!is.na(dwelling) & !is.na(education)) %>%
    filter(age < 90 & age > 17 & familymembers < 30) %>%
    filter(survey_start_time < ymd("2020-08-22")) %>%
    filter(answer_time_90 / answer_time_min >= 1.5) %>%
    filter(invalid_answer_count <= 20)
