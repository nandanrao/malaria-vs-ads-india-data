
# TODO: create data loading/cleaning functions for each data frame used

baseline <- df %>%
    filter(survey_start_time < ymd("2020-08-20") & wave == 0) %>%
    filter(!is.na(dwelling))

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