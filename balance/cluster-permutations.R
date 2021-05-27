source("./match.R")

# Read raw data for making cluster assignment
ma <- read_csv('data/raw/ma.csv')

# Use these variables for matching
match_on <- c('kutchas', 'university', 'malaria', 'malaria_now', 'population', 'cost_per_completion', 'saturated')

thresholds <-  c(c(.6, .3, .3, .6, .75, .75, .3), rep(.1, 13))

pairs <- generate_pairs(ma, match_on)
pair_ids <- make_pair_ids(pairs)

ma %>%
    dplyr::select(disthash) %>%
    mutate(pair_id = pair_ids) %>%
    write_csv('data/final/pairs.csv')



###############################################
# Make 1000 random assignments that satisfy balance requirements
# based one p-values. NOTE: in retrospect, one should not use
# p-values for this.

library(doRNG)
cl <- parallel::makeForkCluster(7)
doParallel::registerDoParallel(cl)

# Read raw data for making cluster assignment
ma <- read_csv('data/raw/ma.csv')

formula <- a ~ kutchas + university + unemployed + malaria + malaria_now + population + cost_per_completion + cost_per_message + CTR + CPM + I(malaria**2) + I(malaria_now**2) + I(kutchas*population) + I(malaria*kutchas)

set.seed(123)
bb <- foreach(i = 1:1000, .combine = 'cbind') %dorng% {
    match_and_rerandomize(formula, ma, thresholds, 0.35, 2000)$assignment
}

write_csv(data.frame(bb), 'data/final/cluster-assignments.csv')
