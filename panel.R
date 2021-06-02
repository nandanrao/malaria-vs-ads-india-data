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

df <- read_csv("data/final/regression-data/panel.csv") %>%
    binarize(binary_confs) %>%
    ordinalize(factor_confs) %>%
    deal_with_numbers() %>%
    mutate(survey_start_time = ymd_hms(survey_start_time)) %>%
    group_by(userid) %>%
    mutate(across(
        c(
            "kutcha", "pucca", "semipucca",
            "university", "unemployed", "female",
            "age", "familymembers", "hasmosquitonet", "admalaria",
            "caste"
        ),
        pick_non_na
    )) %>%
    mutate(waves_answered = n()) %>%
    ungroup()


clean <- df %>%
    filter(waves_answered > 2) %>%
    filter(survey_start_time > ymd("2020-09-21")) %>%
    filter(!is.na(membersbednet) & !is.na(familymembers) & !is.na(age)) %>%
    filter(age < 90 & age > 17 & familymembers < 30)


controls <- c(
    "generalcaste",
    "university",
    "female",
    "student",
    "pregnantwoman",
    "log_age",
    "log_familymembers"
)

specs <- list(
    c("treatment"),
    c("treatment", controls),
    c("treatment*kutcha", "treatment*pucca", controls),
    c("treatment*pucca", controls),
    c("treatment", "admalaria")
)


models <- list(
    lapply(specs, function(s) {
        mm_binom(
            clean, "seekhelpfever",
            s,
            c("fever2weeks", "admalaria", controls)
        )
    }),
    lapply(specs, partial(
        mm_binom, clean, "malaria4months",
        c("admalaria", controls)
    )),
    lapply(specs, partial(
        mm_binom, clean, "fever4months",
        c("admalaria", controls)
    ))
)




model <- mm_binom(
    clean, "seekhelpfever", c("treatment*pucca", controls),
    c(controls)
)
summary(model)

model <- mm_binom(clean, "seekhelpfever", c("fever2weeks"), controls)
summary(model)

model <- mm_binom(clean, "fever2weeks", c(), c("familymembers"))
summary(model)



model <- mm_binom(
    filter(clean, TRUE & hasmosquitonet),
    "sleepundernet"
)
summary(model)

model <- mm_binom(
    filter(clean, TRUE & hasmosquitonet), "sleepundernet",
    c("treatment*pucca"), controls
)
summary(model)

model <- mm_binom(clean, "longsleeves", c(), controls)
summary(model)

model <- mm_binom(clean, "malaria2weeks", c(), controls)
summary(model)




ads <- clean %>%
    filter(!is.na(admalaria)) %>%
    group_by(userid, stratumid, treatment, kutcha, pucca, semipucca) %>%
    summarize()


######################################################################
# Family members under bednet
######################################################################


members <- clean %>%
    mutate(across(c("membersbednet"), ~ case_when(.x == 0 ~ 0.05, .x == 1 ~ 0.95, TRUE ~ .x)))

mem <- members %>%
    group_by(
        userid, stratumid, treatment,
        kutcha, pucca, semipucca,
        familymembers, log_familymembers,
        log_age, university, female
    ) %>%
    summarize(across(c("membersbednet"), mean), waves_answered = n()) %>%
    ungroup() %>%
    mutate(membersbednet = qlogis(membersbednet))


f <- reformulate(
    c("(1 | stratumid / userid)", "treatment*pucca", controls),
    "membersbednet"
)

model <- glmer(f, family = "binomial", weights = familymembers, clean)
summary(model)


model <- lmer(f, members %>% mutate(membersbednet = qlogis(membersbednet)))
summary(model)

# Linear, weighted --

f <- reformulate(c("(1 | stratumid)", "treatment*pucca", controls), "membersbednet")
model <- lmer(f, mem, weights = waves_answered)
summary(model)