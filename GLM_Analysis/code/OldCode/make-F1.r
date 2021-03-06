
#Read in the data file and convert the first col to rownames
Bach.dat <- read.table("../dat/OverviewSelCoeffwSHAPE.csv", header = TRUE, sep = ",", stringsAsFactors = FALSE)
Lehman.dat <- read.table("../dat/OverviewSelCoeffLehman.csv", header = TRUE, sep = ",", stringsAsFactors = FALSE)
Zanini.dat <- read.table("../dat/OverviewSelCoeffZanini.csv", header = TRUE, sep = ",", stringsAsFactors = FALSE)

library(plotrix)

plotter <- function(datset){
    par(mar = c(4.5, 4.5, 0.5, 0.5))
    if(datset == "Lehman"){
        main.dat <- Lehman.dat
        wheresthebreak <- 6
        remap = 1
    }
    if(datset == "Zanini"){
        main.dat <- Zanini.dat
        wheresthebreak <- 5
        remap = 0
    }
    if(datset == "Bachelor"){
        main.dat <- Bach.dat
        wheresthebreak <- 5
        remap = 1
    }
    cols <- brewer.pal(6, "Set2")[c(1, 2, 3, 6)]
    dataset <- main.dat[main.dat$TypeOfSite != "res",]
    if(datset == "Zanini"){ toPlot <- dataset$TSmutrate/dataset$EstSelCoeff }
    if(datset == "Bachelor"){ toPlot <- dataset$colMeansTs0 }
    if(datset == "Lehman"){ toPlot <- dataset$colMeansTsLehman }
    toPlot <- toPlot[!is.na(toPlot)]
    colVect <- rep(0, nrow(dataset))
    colVect[dataset$TypeOfSite == "nonsyn"] <- cols[2]
    colVect[dataset$TypeOfSite == "syn"] <- cols[1]
    colVect[dataset$TypeOfSite == "stop"] <- "black"
    plot(5, type = "n", log = "y", axes = FALSE, xlim = c(0, length(toPlot[!is.na(toPlot)])), ylim = c(10^-(wheresthebreak), max(toPlot, na.rm = TRUE)),  ylab = "Mean mutation frequency", xlab = "Mutations ordered by mean mutation frequency", cex.lab = 1.5)
    for(i in 1:wheresthebreak){
        abline(h = 1:10 * 10^(-i), col = "gray90")
    }
    abline(h = 10^-(wheresthebreak), col = "gray90")
    if(remap == 1){
        eaxis(side = 2, at = 10^((-1):(-(wheresthebreak-1))))
        axis(side = 2, at = c(1, 10^-(wheresthebreak)), label = c(1, 0), las = 2)
        box()
        axis.break(2,2*10^-(wheresthebreak),style="slash")
    }else{
        eaxis(side = 2, at = 10^((0):(-(wheresthebreak))))
        axis(side = 2, at = 1, label = 1, las =2)
        box()
    }
    toPlot[toPlot == 0] <- 10^-(wheresthebreak)
    points(1:length(toPlot), sort(toPlot), col = colVect[order(toPlot)], pch = "|", cex = .5)
    axis(1)
    legend("bottomright", c("Synonymous", "Nonsynonymous", "Stop"), col = c(cols[1], cols[2], "black"), pch = "|", bg = "white")
}

for(dat.file in c("Lehman", "Zanini", "Bachelor")){
    pdf(paste("../graphs/F1-ordered-", dat.file, ".pdf", sep = ""), height = 5, width = 8)
    plotter(dat.file)
    dev.off()
}


#plotter("Bachelor")
#plotter("Lehman")
#plotter("Zanini")







