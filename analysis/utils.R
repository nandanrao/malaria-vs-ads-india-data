library(rlang)
library(dplyr)
library(lme4)
library(stringr)
library(lmtest)
library(stargazer)
library(sandwich)

clustered_se <- function(m) coeftest(m, vcov = vcovCL, cluster = ~stratumid)[, 2]
get_se <- function(m) summary(m)$coefficient[, 2]

double_scale <- function(x) {
    scale(x) / 2
}

binarize_col <- function(df, col, targ, new_col = NULL) {
    if (is.null(new_col)) {
        new_col <- col
    }
    c <- df[[col]]

    s <- as.integer(case_when(
        is.na(c) ~ NA,
        c %in% targ ~ TRUE,
        TRUE ~ FALSE
    ))

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
    col <- suppressWarnings(as.numeric(
        str_replace_all(col, "[\\[|\\]|\\.|,|\\s]", "")
    ))

    case_when(
        is.infinite(col) ~ NA_real_,
        TRUE ~ col
    )
}

mixed_effects <- function(df, response, terms, weights = NULL, family = "binomial") {
    if (!is.null(weights)) {
        weights <- df[[weights]]
    }

    terms <- c("(1 | stratumid)", terms)
    formula <- reformulate(terms, response = response)
    model <- glmer(formula, df, weights = weights, family = family)
    model
}

logistic_regression <- function(df, response, terms, weights = NULL) {
    if (!is.null(weights)) {
        weights <- df[[weights]]
    }
    formula <- reformulate(terms, response = response)
    model <- glm(formula, df, family = "binomial", weights = weights)
    cluster_se("stratumid", model)
}

ols <- function(df, response, terms, weights = NULL) {
    if (!is.null(weights)) {
        weights <- df[[weights]]
    }
    model <- lm(reformulate(terms, response = response), df, weights = weights)
    cluster_se("stratumid", model)
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

remove_bad_numbers <- function(col, min, max) {
    case_when(
        col < min | col > max ~ NA_real_,
        TRUE ~ col
    )
}


cluster_se <- function(var_, model) {
    class(model) <- c("cluster_se", class(model))
    attr(model, "cluster_se_var") <- var_
    model
}

get_se <- function(model) {
    UseMethod("get_se")
}

get_se.glmerMod <- function(model) {
    summary(model)$coefficient[, 2]
}

get_se.lm <- function(model) {
    summary(model)$coefficient[, 2]
}

get_se.cluster_se <- function(model) {
    coeftest(model,
        vcov = vcovCL,
        cluster = reformulate(attr(model, "cluster_se_var"))
    )[, 2]
}


write_table <- function(models, filename, ...) {
    stargazer(
        models,
        out = glue("../tables/{filename}.tex"),
        keep.stat = c("n"),
        se = map(models, ~ get_se(.x)),
        digits = 2,
        label = glue("tbl:{filename}"),
        ...
    )
}

extract_vars <- function(term_list) {
    attr(terms(reformulate(term_list)), "variables")
}

agg_waves <- function(df, outcomes, covariates) {
    groups <- c(
        "userid", "treatment", "stratumid", covariates
    )

    df %>%
        group_by(across({{ groups }})) %>%
        summarize(
            across(all_of(outcomes), mean, .names = "avg_{.col}"),
            across(all_of(outcomes), sum, .names = "count_{.col}"),
            across(all_of(outcomes), ~ sum(.x) >= 1, .names = "any_{.col}"),
            waves_answered = n()
        ) %>%
        ungroup()
}


get_or <- function(model, treated, baseline = c(), rnd = 4) {
    coefs <- summary(model)$coefficients[, 1]

    # TODO: add CI from SE's from summary...

    i <- coefs[["(Intercept)"]]
    c <- sum(coefs[baseline])
    t <- sum(coefs[treated])

    tp <- plogis(i + c + t)
    basep <- plogis(i + c)

    list(or = tp / basep, base = round(basep, rnd), treated = round(tp, rnd))
}

get_marginal_ords <- function(df, x, outcome) {
    get_or(glm(reformulate(x, outcome), df, family = "binomial"), c(x), c())
}