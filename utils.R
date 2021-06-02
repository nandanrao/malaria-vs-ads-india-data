library(rlang)
library(dplyr)
library(lme4)
library(stringr)
library(lmtest)

double_scale <- function(x) {
    scale(x) / 2
}

binarize_col <- function(df, col, targ, new_col = NULL) {
    if (is.null(new_col)) {
        new_col <- col
    }

    s <- as.integer(df[col] == targ)
    mutate(df, "{new_col}" := s)
}


binarize <- function(df, cols) {
    for (c in cols) {
        if (c$col %in% colnames(df)) {
            df <- binarize_col(df, c$col, c$target, c$new_col)
        }
    }
    df
}

ordinalize <- function(df, confs) {
    for (name in names(confs)) {
        if (name %in% colnames(df)) {
            fac <- factor(df[[name]], levels = confs[[name]], order = TRUE)
            scaled <- double_scale(as.numeric(fac))
            df <- mutate(df, "{name}" := fac, "scaled_{name}" := scaled)
        }
    }
    df
}


bin_conf <- function(col, target, new_col = NULL) {
    list(col = col, target = target, new_col = new_col)
}

parse_numbers <- function(col) {
    suppressWarnings(as.numeric(
        str_replace_all(col, "[\\[|\\]|\\.|,|\\s]", "")
    ))
}

mixed_effects <- function(df, response, terms) {
    terms <- c("(1 | stratumid)", terms)
    formula <- reformulate(terms, response = response)
    glmer(formula, df, family = "binomial")
}


mm_binom <- function(df,
                     outcome,
                     spec = c(),
                     additional_covs = c(),
                     additional_nas = c()) {
    groups <- c(
        "userid", "treatment", "stratumid",
        "kutcha", "pucca", "semipucca",
        additional_covs
    )
    nas <- c(outcome, additional_nas)

    df <- df %>%
        filter(across(nas, ~ !is.na(.x))) %>%
        group_by(across({{ groups }})) %>%
        summarize(across(c(outcome), mean), waves_answered = n()) %>%
        ungroup()

    terms <- c("(1 | stratumid)", spec, additional_covs)
    glmer(reformulate(terms, outcome),
        df,
        family = "binomial",
        weights = waves_answered
    )
}


logistic_regression <- function(df, response, terms) {
    formula <- reformulate(terms, response = response)
    model <- glm(formula, df, family = "binomial")
    coeftest(model, vcov = vcovCL, cluster = ~stratumid)
}


pick_non_na <- function(v) {
    if (all(!is.na(v))) {
        return(v[1])
    }
    v[!is.na(v)][1]
}

capped_percentage <- function(num, den) {
    perc <- num / den
    case_when(
        perc > 1.5 ~ NaN,
        perc > 1.0 ~ 1.0,
        TRUE ~ perc
    )
}

extract_random_effect <- function(model, effect) {
    coef(model)[[effect]] %>%
        select("(Intercept)") %>%
        tibble::rownames_to_column() %>%
        rename("{effect}" := rowname,
            random_effect = "(Intercept)"
        )
}

deal_with_numbers <- function(df) {
    df %>%
        mutate(across(
            c("familymembers", "age", "membersbednet"),
            parse_numbers
        )) %>%
        mutate(across(
            c("familymembers"),
            ~ if_else(.x <= 0, 1, .x)
        )) %>%
        mutate(across(
            c("membersbednet"),
            ~ capped_percentage(.x, familymembers)
        )) %>%
        mutate(across(
            c("familymembers", "age"),
            ~ double_scale(log(.x)),
            .names = "log_{.col}"
        ))
}