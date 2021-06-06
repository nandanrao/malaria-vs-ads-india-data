source("./data.R")



#######################################################################
## Cluster level
#######################################################################

controls <- c(
    "generalcaste",
    "university",
    "female",
    "student",
    "pregnantwoman",
    "scaled_log_familymembers",
    "scaled_distancemedicalcenter"
)

spec <- function(..., fn = identity) {
    list(terms = c(...), fn = fn)
}

puccaize <- function(df) df %>% filter(pucca == 1)

specs <- list(
    spec("treatment"),
    spec("treatment*pucca + semipucca", controls),
    spec("treatment", fn = puccaize)
)

panel_oct <- agg_panel(full_panel, "2020-08-01", agg_to = "2020-08-23")
panel_with_fever <- agg_panel(full_panel, "2020-09-21", "seekhelpfever")
hasbednet_panel <- filter(panel_oct, TRUE & hasmosquitonet)




outcomes <- list(
    `Treatment Seeking` = list(
        `Round 1 Panel` =
            map(specs, ~ mixed_effects(
                .x$fn(panel_with_fever),
                "avg_seekhelpfever",
                .x$terms,
                weights = "waves_answered"
            )),
        `Round 2 Cross Section` =
            map(specs, ~ mixed_effects(
                .x$fn(xsection) %>% filter(!is.na(seekhelpfever)),
                "seekhelpfever",
                .x$terms
            ))
    ),
    `Sleeping Under Bednet - Panel` = list(
        `Self` = c(
            map(specs, ~ mixed_effects(
                .x$fn(hasbednet_panel),
                "avg_sleepundernet",
                .x$terms,
                weights = "waves_answered"
            ))
        ),
        `Household` = c(
            map(specs, ~ mixed_effects(
                .x$fn(hasbednet_panel),
                "avg_perc_membersbednet",
                .x$terms,
                weights = "waves_answered"
            ))
        )
    ),
    `Sleeping Under Bednet - OLS` = list(
        `Probability of Sleeping (Self)` =
            map(specs, ~ ols(
                .x$fn(hasbednet_panel),
                "avg_sleepundernet",
                .x$terms
            )),
        `Average Percentage of Household` =
            map(specs, ~ ols(
                .x$fn(hasbednet_panel),
                "avg_perc_membersbednet",
                .x$terms
            ))
    ),
    `Malaria Incidence` = list(
        `Round 1 Panel` =
            map(specs, ~ mixed_effects(
                .x$fn(panel_oct),
                "any_malaria2weeks",
                .x$terms
            )),
        `Round 2 Cross Section` =
            map(specs, ~ mixed_effects(
                .x$fn(xsection),
                "malaria4months",
                .x$terms
            ))
    ),
    `Malaria Incidence - OLS` = list(
        `Round 1 Panel` =
            map(specs, ~ ols(
                .x$fn(panel_oct),
                "any_malaria2weeks",
                .x$terms
            )),
        `Round 2 Cross Section` =
            map(specs, ~ ols(
                .x$fn(xsection),
                "malaria4months",
                .x$terms
            ))
    ),
    `Fever Incidence` = list(
        `Round 1 Panel` =
            map(specs, ~ mixed_effects(
                .x$fn(panel_oct),
                "any_fever2weeks",
                .x$terms
            )),
        `Round 2 Cross Section` =
            map(specs, ~ mixed_effects(
                .x$fn(xsection),
                "fever4months",
                .x$terms
            ))
    )
)


for (name in names(outcomes)) {
    x <- outcomes[[name]]

    lines <- list(
        c("Controls", rep(c("No", "Yes", "No"), 2)),
        c("Subgroup", rep(c("All", "All", "Pucca"), 2))
        ## c("Reference", map_dbl(flatten(x), ~ get_or(.x, c("treatment"), c())$base)),
        ## c("Treated", map_dbl(flatten(x), ~ get_or(.x, c("treatment"), c())$treated))
    )

    write_table(
        flatten(x),
        name,
        add.lines = lines,
        omit = c("Constant", controls),
        title = name,
        dep.var.caption = "",
        column.labels = names(x),
        column.separate = c(3, 3),
        dep.var.labels.include = FALSE
    )
}


#######################################################################
## Individual Level
#######################################################################

ind_controls <- c(
    "generalcaste",
    "university",
    "female",
    "student",
    "pregnantwoman",
    "scaled_log_age",
    "scaled_log_familymembers",
    "scaled_distancemedicalcenter"
)


ind_specs <- list(
    c("treatment*pucca + semipucca + ind_treatment", ind_controls),
    c("ind_treatment"),
    c("ind_treatment + treatment + pucca + semipucca", ind_controls),
    c("ind_treatment*treatment", ind_controls),
    c("ind_treatment*pucca + treatment + semipucca", ind_controls),
    c("ind_treatment + treatment", "admalaria", ind_controls)
)

lines <- list(c("Controls", map_chr(ind_specs, ~ ifelse("generalcaste" %in% .x, "Yes", "No"))))

ind_outcomes <- list(
    `Sleeping Under Bednet (Individual Level) - Logistic Regression` = list(
        `Slept Under Net` =
            map(ind_specs, ~ glm(reformulate(.x, "sleepundernet"),
                filter(individual_effect, TRUE & hasmosquitonet),
                family = "binomial"
            ))
    ),
    `Sleeping Under Bednet (Individual Level) - OLS` = list(
        `Slept Under Net` =
            map(ind_specs, ~ lm(
                reformulate(.x, "sleepundernet"),
                filter(individual_effect, TRUE & hasmosquitonet)
            ))
    )
)

for (name in names(ind_outcomes)) {
    write_table(
        flatten(ind_outcomes[[name]]),
        name,
        add.lines = lines,
        omit = c("Constant", ind_controls),
        dep.var.caption = name,
        dep.var.labels = names(ind_outcomes[[name]])
    )
}