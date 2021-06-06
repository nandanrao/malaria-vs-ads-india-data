source('./match.R')


########################################
# INDIVIDUAL EFFECT STUDY

ind_effect <- read_csv('data/raw/ind-effect-for-balance.csv')

thresholds  <- rep(0.2, 18)
formula <- a ~ treatment + gender + dwelling + education + malaria4months + fever4months + hasmosquitonet + caste

gen <- function (df) rbinom(nrow(df), 1, 0.5)
b <- rerandomize(formula, ind_effect, gen, thresholds, 0.2, 100)

balance <- MatchBalance(formula, data=ind_effect %>% mutate(a = b))
