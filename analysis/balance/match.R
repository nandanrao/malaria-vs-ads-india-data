library(readr)
library(dplyr)
library(Matching)

pairup <- function (a) {
    N <- length(a)
    if (N %% 2 != 0) {
        stop('pairup needs an even-length vector')
    }
    out <- matrix(0, N/2, 2)
    for (i in 1:nrow(out)) {
        out[i,] <- a[1:2]
        a <- a[3:length(a)]
    }
    out
}

get_order <- function (m) {
    pca <- prcomp(scale(m))$x
    order(pca[, "PC1"])
}

pair <- function (di, blacklist) {
    s <- order(di)[2:length(di)]
    for (i in s) {
        if (!(i %in% blacklist)) {
            return(i)
        }
    }
}

pairem <- function (ma, or) {
    dists <- as.matrix(dist(scale(ma), method='euclidean'))
    pairs <- c()
    while(length(or) > 0) {
        i <- or[1]
        d <- dists[i, ]
        p <- pair(d, pairs)
        pairs <- append(pairs, c(i, p))
        or <- or[(or != p) & (or != i)]
    }
    pairs
}

flip <- function () {
    a <- rbinom(1, 1, 0.5)
    b <- ifelse(a == 0, 1, 0)
    c(a,b)
}

choose <- function(pairs) {
    # pairs is a vector where index 1 and index 2 are
    # a pair, same with index 3 and 4, etc...
    N <- length(pairs)
    out <- rep(0, N)
    for (i in seq(1, N, by=2)) {
        f <- flip()
        a <- pairs[i]
        b <- pairs[i+1]
        out[a] <- f[1]
        out[b] <- f[2]
    }
    out
}

get_balance <- function(formula, dat, labels, print.level=0) {
    dat <- mutate(dat, a = labels)
    MatchBalance(formula,
                 data=dat,
                 print.level=print.level)
}


above_threshes <- function (balance, threshes) {
    bm <- balance$BeforeMatching
    for (i in 1:length(bm)) {
        thresh <- threshes[i]
        if (is.na(thresh)) {
            stop("Not enough thresholds given!")
        }
        val <- bm[[i]]$tt$p.value
        if (val < thresh) {
            return(FALSE)
        }
    }
    TRUE
}

rerandomize <- function (formula, df, gen_assignment, threshes, minimum_threshold, iters) {
    for (i in 1:iters) {
        labels <- gen_assignment(df)
        balance <- get_balance(formula, df, labels)
        mi <- balance$BMsmallest.p.value

        if ((mi > minimum_threshold) & above_threshes(balance, threshes)) {
            print(balance)
            return(labels)
        }
    }
}

generate_pairs <- function (ma, match_on) {
    selected_ma <- dplyr::select(ma, all_of(match_on))
    or <- get_order(selected_ma)
    pairem(selected_ma, or)
}

match_and_rerandomize <- function (formula, ma, pairs, threshes, minimum_threshold, iters) {
    gen_assignment <- function(df) choose(pairs)

    assignment <- rerandomize(formula, ma, gen_assignment, threshes, minimum_threshold, iters)

    list(assignment = assignment)
}

check_unique <- function (X) {
    N <- ncol(X)
    for (i in 1:(N-1)) {
        for (j in (i+1):N) {
            if (all(X[,i] == X[,j])) {
                print('phooey')
            }
        }
    }
}

make_pair_ids <- function (pairs) {
    N <- length(pairs)
    out <- rep(0, N)
    j <- 1
    for (i in seq(1, N, by=2)) {
        a <- pairs[i]
        b <- pairs[i+1]
        out[a] <- j
        out[b] <- j
        j <- j + 1
    }
    out
}
