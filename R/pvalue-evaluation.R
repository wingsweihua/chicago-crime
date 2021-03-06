library(MASS)
library(maptools)
library(sp)
library(spdep)
library(doParallel)

cl <- makeCluster(4)
registerDoParallel(cl)


source("NBUtils.R")

args <- commandArgs(trailingOnly = TRUE)
z = file(paste("glmmadmb-", args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10],".out", sep="-"), open="wa")





# generate the contiguous spatial weight
ca = readShapeSpatial("../data/ChiCA_gps/ChiCaGPS")
w1 <- spatialWeight(ca)

demos <- read.table('pvalue-demo.csv', header=TRUE, sep=",")
focusColumn <- names(demos) %in% c("total.population", "population.density",
                                   "disadvantage.index", "residential.stability",
                                   "ethnic.diversity")
demos.part <- demos[,focusColumn]
stopifnot( ncol(demos.part) == 5 )
cat("Selected Demographics features:\n", names(demos.part), "\n")


# spatial matrix
# w1 <- as.matrix(read.csv('pvalue-spatiallag.csv', header=FALSE))


# social matrix
# The entry (i,j) means the flow from j entering i.
# row i means, the flow from other CAs entering CA_i
w2 <- as.matrix(read.csv('pvalue-sociallag.csv', header=FALSE))
rownames(w2) <- as.character(1:77)


# crime
Y <- read.csv('pvalue-crime.csv', header=FALSE)
Y <- Y$V1

# use crime rate instead of crime count
# Y <- Y / demos$total.population * 10000


if (args[5] == "logpop") {
    demos.part[,'total.population'] = log(demos$total.population / 1000) 
}


if (args[8] == "logpopdensty" ){
    demos.part[, "population.density"] = log(demos.part$population.density)
}

if (args[9] == "templag") {
    yt <- read.csv('pvalue-templag.csv', header=FALSE)
    yt <- log(yt$V1)
    demos.part[,"templag"] <- yt
}


if (args[10] == "selfflow") {
    sf <- read.csv('pvalue-selfflow.csv', header=FALSE)
    sf <-  sf$V1 / demos$total.population * 1000 
    demos.part[,"selfflow"] <- sf
}

stopifnot(all(is.finite(as.matrix(demos.part))))


lags <- args[6]



normalize <- TRUE
sn <- args[3]

cat(args, "\n")
sink(z, append=TRUE, type="output", split=FALSE)
errors <- leaveOneOut(demos.part, ca, w2, Y, coeff=TRUE, normalize=normalize, socialnorm=sn, exposure=args[4], lagstr=lags)
mae.org <- mean(errors)
cat(mae.org, "\n")
itersN <- strtoi(args[7])


pvalues <- c()


                                        # permute demographics
for (i in 1:ncol(demos.part)) {
    
    featureName <- colnames(demos.part)[i]
    cat(featureName, ' ')
    cnt <- 0
    
    for (j in 1:itersN) {
        demos.copy <- demos.part
                                        # permute features
        demos.copy[,i] <- sample( demos.part[,i] )
        mae <- leaveOneOut(demos.copy, ca, w2, Y, normalize=normalize, socialnorm=sn, exposure=args[4], lagstr=lags)
        if (j %% (itersN %/% 5)  == 0) {
            cat("-->", mae, "\n")
        }
        if (mae.org > mae) {
            cnt = cnt + 1
        }
    }
    pvalues[[featureName]] <- cnt/itersN
}



if (lags != "0000") {
    lags.flag <- unlist(strsplit(lags, split=""))
                                        # permute lag
    cnt.social <- 0
    cnt.spatial <- 0
    cnt.social.disadv <- 0
    cnt.spatial.disadv <- 0
    for (j in 1:itersN) {
        mae = leaveOneOut.PermuteLag(demos.part, ca, w2, Y, normalize, socialnorm=sn, exposure=args[4], lagstr=lags)

        if (j %% (itersN %/% 5) == 0) {
            cat("-->", mae, "\n")
        }
        
        if (lags.flag[1] == "1" && mae.org > mae['social']) { # first one is social lag
            cnt.social = cnt.social + 1
        }

        if (lags.flag[2] == "1" && mae.org > mae['spatial']) {
            cnt.spatial = cnt.spatial + 1
        }
        
        if (lags.flag[3] == "1" && mae.org > mae['social.disadv']) { # first one is social lag
            cnt.social.disadv = cnt.social.disadv + 1
        }

        if (lags.flag[4] == "1" && mae.org > mae['spatial.disadv']) {
            cnt.spatial.disadv = cnt.spatial.disadv + 1
        }
    }

    if (lags.flag[1] == "1") {
        pvalues <- c(pvalues, social.lag=cnt.social / itersN)
        cat("social.lag", cnt.social / itersN, "\n")
    }
    

    if (lags.flag[2] == "1") {
        pvalues <- c(pvalues, spatial.lag=cnt.spatial / itersN)
        cat("spatial.lag", cnt.spatial / itersN, "\n")
    }

    if (lags.flag[3] == "1") {
        pvalues <- c(pvalues, social.lag.disadv=cnt.social.disadv / itersN)
        cat("social.lag.disadv", cnt.social.disadv / itersN, "\n")
    }
    

    if (lags.flag[4] == "1") {
        pvalues <- c(pvalues, spatial.lag.disadv=cnt.spatial.disadv / itersN)
        cat("spatial.lag.disadv", cnt.spatial.disadv / itersN, "\n")
    }
}

cat(names(unlist(pvalues)), "\n")
cat(unlist(pvalues), "\n")


sink()

stopCluster(cl)
