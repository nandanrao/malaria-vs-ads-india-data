library(purrr)
library(glue)
source("./utils.R")

binary_covariate_confs <- list(
    bin_conf("dwelling", "Kutcha (made of mud, tin, straw)", "kutcha"),
    bin_conf("dwelling", "Pucca (have cement/brick wall and floor", "pucca"),
    bin_conf("dwelling", "Semi-pucca", "semipucca"),
    bin_conf("education", "University degree or higher", "university"),
    bin_conf("occupation", "Unemployed", "unemployed"),
    bin_conf("occupation", "Student", "student"),
    bin_conf("gender", "Female", "female"),
    bin_conf("pregnantwoman", "Yes"),
    bin_conf("caste", "General", "generalcaste"),
    bin_conf("caste", c("General", "Other"), "forwardcaste"),
    bin_conf("caste", c("OBC", "SC/Dalit", "ST"), "backwardcaste"),
    bin_conf("hasmosquitonet", "Yes"),
    bin_conf("hasairconditioning", "Yes"),
    bin_conf("admalaria", "Yes")
)

binary_outcome_confs <- list(
    bin_conf("fever2weeks", "Yes"),
    bin_conf("malaria5year", "Yes"),
    bin_conf("malaria2weeks", "Yes"),
    bin_conf("malaria4months", "Yes"),
    bin_conf("seekhelpfever", "Yes"),
    bin_conf("fever4months", "Yes"),
    bin_conf("timeseekhelpfever", "Less than 24 hours", "feverquickhelp"),
    bin_conf("timeseekhelpfever", "More than 2 days", "feverslowhelp"),
    bin_conf("timeseekhelpmalaria", "Less than 24 hours", "malariaquickhelp"),
    bin_conf("timeseekhelpmalaria", "More than 2 days", "malariaslowhelp"),
    bin_conf("sleepundernet", "Yes"),
    bin_conf("longsleeves", "Yes"),
    bin_conf("worriedmalaria", "Not at all worried", "notworriedmalaria"),
    bin_conf("treatmentseeking", "I would seek treatment right away", "hypotheticalfeverquickhelp")
)

binary_confs <- c(binary_covariate_confs, binary_outcome_confs)

factor_confs <- list(
    distancemedicalcenter = c(
        "Less than 15 minutes",
        "Between 15 and 30 minutes",
        "Between 30 and 60 minutes",
        "More than 60 minutes"
    ),
    education = c(
        "Never attended school",
        "Primary",
        "Secondary",
        "University degree or higher"
    ),
    dwelling = c(
        "Kutcha (made of mud, tin, straw)",
        "Semi-pucca",
        "Pucca (have cement/brick wall and floor"
    )
)

deal_with_numbers <- function(df) {
    df %>%
        mutate(across(
            c("familymembers", "age", "membersbednet"),
            parse_numbers
        )) %>%
        mutate(across(c("familymembers"), ~ remove_bad_numbers(.x, 1, 40))) %>%
        mutate(across(c("age"), ~ remove_bad_numbers(.x, 12, 100))) %>%
        mutate(across(c("membersbednet"), ~ remove_bad_numbers(.x, 0, 40))) %>%
        mutate(across(
            c("familymembers"),
            ~ if_else(.x <= 0, 1, .x)
        )) %>%
        mutate(across(
            c("familymembers", "age"),
            ~ log(.x),
            .names = "log_{.col}"
        )) %>%
        mutate(across(
            c("log_familymembers", "log_age"),
            ~ double_scale(.x),
            .names = "scaled_{.col}"
        ))
}

make_covariate_names <- function() {
    binary_vars <- map_chr(
        binary_covariate_confs,
        ~ ifelse(!is.null(.x$new_col), .x$new_col, .x$col)
    )
    raw_factors <- names(factor_confs)
    continuous <- c("familymembers", "age")

    c(
        binary_vars,
        raw_factors,
        map_chr(raw_factors, ~ glue("scaled_{.x}")),
        continuous,
        map_chr(continuous, ~ glue("log_{.x}")),
        map_chr(continuous, ~ glue("scaled_log_{.x}"))
    )
}


agg_panel <- function(full_panel, agg_from, na_check = "dwelling", agg_to = "2021-01-31") {
    full_panel %>%
        filter(waves_answered > 2) %>%
        filter(survey_start_time > ymd(agg_from)) %>%
        filter(survey_start_time < ymd(agg_to)) %>%
        filter(age < 90 & age > 17 & familymembers < 30) %>%
        filter(across(na_check, ~ !is.na(.x))) %>%
        agg_waves(c(
            "sleepundernet",
            "longsleeves",
            "malaria2weeks",
            "fever2weeks",
            "seekhelpfever",
            "perc_membersbednet"
        ), all_possible_covariates)
}


all_possible_covariates <- make_covariate_names()
