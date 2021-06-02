source("./utils.R")

binary_confs <- list(

    # Covariates
    bin_conf("dwelling", "Kutcha (made of mud, tin, straw)", "kutcha"),
    bin_conf("dwelling", "Pucca (have cement/brick wall and floor", "pucca"),
    bin_conf("dwelling", "Semi-pucca", "semipucca"),
    bin_conf("education", "University degree or higher", "university"),
    bin_conf("occupation", "Unemployed", "unemployed"),
    bin_conf("occupation", "Student", "student"),
    bin_conf("gender", "Female", "female"),
    bin_conf("pregnantwoman", "Yes"),
    bin_conf("caste", "General", "generalcaste"),
    bin_conf("hasmosquitonet", "Yes"),

    # Outcomes
    bin_conf("fever2weeks", "Yes"),
    bin_conf("malaria2weeks", "Yes"),
    bin_conf("malaria4months", "Yes"),
    bin_conf("seekhelpfever", "Yes"),
    bin_conf("fever4months", "Yes"),
    bin_conf("timeseekhelpfever", "Less than 24 hours", "feverquickhelp"),
    bin_conf("timeseekhelpfever", "More than 2 days", "feverslowhelp"),
    bin_conf("timeseekhelpmalaria", "Less than 24 hours", "malariaquickhelp"),
    bin_conf("timeseekhelpmalaria", "More than 2 days", "malariaslowhelp"),
    bin_conf("sleepundernet", "Yes"),
    bin_conf("longsleeves", "Yes"),
    bin_conf("admalaria", "Yes"),
    bin_conf("worriedmalaria", "Not at all worried", "notworriedmalaria")
)

factor_confs <- list(
    distancemedicalcenter = c(
        "Less than 15 minutes",
        "Between 15 and 30 minutes",
        "Between 30 and 60 minutes",
        "More than 60 minutes"
    )
)