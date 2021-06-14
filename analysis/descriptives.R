############################
# Descriptives
############################
library(ggplot2)
library(corrr)
library(tibble)

source("./data.R")


baseline %>%
    select(
        malaria5year,
        malaria2weeks,
        scaled_distancemedicalcenter,
        familymembers,
        scaled_dwelling,
        scaled_education,
        backwardcaste,
        hasairconditioning,
        scaled_education
    ) %>%
    correlate() %>%
    rearrange() %>%
    focus(malaria2weeks, malaria5year) %>%
    fashion(3) %>%
    data.frame() %>%
    mutate(term = c(
        "Distance to Medical Center",
        "Backward Caste",
        "Family Size",
        "Air Conditioning",
        "Education",
        "Dwelling"
    )) %>%
    column_to_rownames("term") %>%
    rename(
        `Malaria - 2 weeks` = malaria2weeks,
        `Malaria - 5 years` = malaria5year
    ) %>%
    stargazer(
        summary = FALSE,
        label = "tbl:baseline-corr",
        title = "Marginal Correlations at Baseline",
        out = "../tables/baseline-corr.tex"
    )


get_marginal_ords <- function(df, x, outcome) {
    get_or(glm(reformulate(x, outcome), df, family = "binomial"), c(x), c())
}

baseline %>%
    mutate(
        `Recruitment` =
            if_else(survey_start_time < ymd("2020-07-25"),
                "Naive",
                "Optimized"
            )
    ) %>%
    group_by(stratumid, `Recruitment`) %>%
    summarize(kutcha = mean(pucca)) %>%
    ungroup() %>%
    ggplot(aes(kutcha,
        color = factor(`Recruitment`),
        fill = factor(`Recruitment`),
        xmin = -0.1,
        xmax = 0.5
    )) +
    geom_histogram(
        position = "identity",
        alpha = 0.4,
        bins = 16,
        size = 0.3,
        color = "white"
    ) +
    geom_density(alpha = 0.1, fill = NA, bw = 0.03) +
    scale_fill_brewer(palette = "Set2") +
    scale_color_brewer(palette = "Set2") +
    labs(
        x = "Percentage kutcha",
        y = "Number of districts",
        color = "Recruitment",
        fill = "Recruitment"
    ) +
    ggsave("../figures/recruitment.png", width = 8, height = 4)



full_panel %>%
    group_by(week) %>%
    summarize(n = n()) %>%
    ggplot(aes(week, n)) +
    geom_col()



jitter_plot <- function(df) {
    df %>%
        filter(!is.na(sleepundernet)) %>%
        group_by(stratumid, treatment) %>%
        summarize(across(c("sleepundernet"), mean), num_participants = n()) %>%
        ggplot(aes(
            x = factor(treatment),
            color = factor(treatment),
            y = sleepundernet, size = num_participants
        )) +
        geom_jitter(width = 0.2)
}

# TODO: put into

jitter_plot(baseline)
jitter_plot(clean)

re <- extract_random_effect(model, "stratumid")

d <- clean %>%
    filter(!is.na(sleepundernet)) %>%
    group_by(stratumid, treatment) %>%
    summarize(across(c("sleepundernet"), mean), num_participants = n()) %>%
    rename(marginal = sleepundernet) %>%
    inner_join(re) %>%
    pivot_longer(cols = c(marginal, random_effect)) %>%
    mutate(foo = paste0(name, treatment))

d %>% ggplot(aes(
    x = factor(foo),
    color = factor(stratumid),
    y = value,
    shape = factor(name),
    size = num_participants
)) +
    geom_jitter(width = 0.3)


d <- rbind(
    mutate(baseline, name = "baseline"),
    clean %>%
        mutate(name = "post") %>%
        select(-log_familymembers)
)


## RANDOM CLUSTER LEVEL COMPARISON
avgd_baseline <- baseline %>%
    filter(!is.na(malaria2weeks) & pucca == 1) %>%
    group_by(stratumid) %>%
    summarize(pre = mean(malaria2weeks), pre_n = n())

xsection %>%
    filter(!is.na(malaria4months) & pucca == 1) %>%
    group_by(stratumid, treatment) %>%
    summarize(post = mean(malaria4months), post_n = n()) %>%
    inner_join(avgd_baseline, by = "stratumid") %>%
    ungroup() %>%
    mutate(across(c("post", "pre"), scale)) %>%
    mutate(dif = post - pre) %>%
    ggplot(aes(y = dif, x = factor(treatment), fill = factor(treatment), color = factor(treatment))) +
    geom_jitter(width = 0.3) +
    geom_boxplot(alpha = 0.3)










risk <- baseline %>%
    group_by(stratumid) %>%
    summarize(m = mean(malaria2weeks)) %>%
    mutate(district_risk = case_when(
        m > 0.02 ~ "high",
        TRUE ~ "low"
    )) %>%
    select(stratumid, district_risk)

baseline %>%
    inner_join(risk, on = "stratumid") %>%
    group_by(dwelling, district_risk) %>%
    summarize(across(c("malaria5year", "malaria2weeks"), ~ mean(.x, na.rm = TRUE)))