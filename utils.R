binarize_col <- function (df, col, targ, new_col=NULL) {
    if (is.null(new_col)) {
        new_col <- col
    }

    s <- as.integer(df[col] == targ)
    mutate(df, "{new_col}" := s)
}

binarize <- function (df, cols) {
    for (c in cols) {
        df <- binarize_col(df, c$col, c$target, c$new_col)
    }
    df
}

bin_conf <- function (col, target, new_col=NULL) {
    list(col=col, target=target, new_col=new_col)
}


replace_cols <- function(df, fn, cols) {
    for (col in cols) {
        df <- mutate(df, "{col}" := fn(.data[[col]]))
    }
    df
}

parse_numbers <- function(col) {
    as.numeric(str_replace_all(col, "[\\[|\\]|\\.|,|\\s]", ""))
}

mixed_effects <- function(df, response, terms) {
    terms <- c('(1 | stratumid)', terms)
    formula <- reformulate(terms, response=response)
    glmer(formula, df, family='binomial')
}


logistic_regression <- function(df, response, terms) {
    formula <- reformulate(terms, response=response)
    model <- glm(formula, df, family='binomial')
    coeftest(model, vcov = vcovCL, cluster= ~ stratumid)
}

pick_non_na <- function (v) {
    if (all(!is.na(v))) {
        return(v[1])
    }
    v[!is.na(v)][1]
}
