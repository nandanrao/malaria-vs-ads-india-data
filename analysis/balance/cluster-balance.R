ma <- read_csv('data/raw/ma-with-treatment.csv')

formula <- a ~ kutchas + university + unemployed + malaria + malaria_now + population + cost_per_completion + cost_per_message + CTR + CPM + I(malaria**2) + I(malaria_now**2) + I(kutchas*population) + I(malaria*kutchas)

b <- get_balance(formula, ma, ma$treatment, 1)


# TODO: GENERATE BALANCE TABLES FOR CLUSTERS
