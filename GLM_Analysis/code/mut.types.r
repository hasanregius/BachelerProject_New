
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
    pdf(paste("../graphs/ordered.", dat.file, ".pdf", sep = ""), height = 5, width = 8)
    plotter(dat.file)
    dev.off()
}


plotter("Bachelor")

plotter("Lehman")

plotter("Zanini")








gap.plot(0, type= "n", xlim = c(0,1), ylim = c(0, max(forYlim$counts)), gap = gaplen, gap.axis = "x", xtics = seq(0, 1, by = .2), ytics = seq(0, max(forYlim$counts), by = 10), ylab = ylabs[[nuc]], xlab = xlabs[[nuc]], main = "", cex.lab = 1.5)
    
    
    siteType <- which(main.dat$TypeOfSite == typematch)
    yrange <- intersect(which(main.dat$WTnt == nuc), siteType)
    sToPlot <- main.dat[yrange, ]$EstSelCoeff
    meanS <- mean(sToPlot)


    
    splitPlot = 0
    if(datset == "Lehman"){
        main.dat <- Lehman.dat
        if(typematch == "nonsyn"){
            xlim.set = c(0, 1)
        }else{
            xlim.set = c(0, 1)
        }
    }
    if(datset == "Zanini"){
        main.dat <- Zanini.dat
        if(typematch == "nonsyn"){
            xlim.set = c(0, 0.65)
        }else{
            xlim.set = c(0, 0.16)
        }
    }
    if(datset == "Bachelor"){
        main.dat <- Bach.dat
        if(typematch == "nonsyn"){
            xlim.set = c(0, 1)
            splitPlot = 1 
        }else{
            xlim.set = c(0, .05)
        }
    }

    print(paste(datset, "xlims = ", paste(xlim.set, collapse = " - "), splitPlot, collapse = " "))
#    layout(matrix(1:4, nrow = 2))
    par(mfcol=c(2,2),oma = c(0, 0, 3, 0))
    par(bty="n")
    gaplen <- c(.65, .95)


    ylabs <- list(a = "Count", t = "Count", c = "", g = "")
    xlabs <- list(a = "", t = "s", c = "", g = "s")
    mars <- list(a = c(2, 4.5, 2, 1), t = c(4, 4.5, 0, 1), c = c(2, 2, 2, 3.5), g = c(4, 2, 0, 3.5))

    for (nuc in c("a", "t", "c", "g")){

        siteType <- which(main.dat$TypeOfSite == typematch)
        yrange <- intersect(which(main.dat$WTnt == nuc), siteType)
        sToPlot <- main.dat[yrange, ]$EstSelCoeff
        meanS <- mean(sToPlot)
        plotBreaks <- seq(0, xlim.set[2], by = xlim.set[2]/30)
        forYlim <- hist(sToPlot, breaks = plotBreaks, plot = FALSE)
        par(mar = mars[[nuc]])

        if(splitPlot == 1){
            gap.plot(0, type= "n", xlim = c(0,1), ylim = c(0, max(forYlim$counts)), gap = gaplen, gap.axis = "x", xtics = seq(0, 1, by = .2), ytics = seq(0, max(forYlim$counts), by = 10), ylab = ylabs[[nuc]], xlab = xlabs[[nuc]], main = "", cex.lab = 1.5)
            abline(v = c(.65), col = "white", lwd = 2)
            abline(v = c(.665), col = "white", lwd = 2)
            axis.break(1,.65,style="slash")
            text(.35, max(forYlim$counts), paste(toupper(nuc)), pos = 1, cex = 1.5)
            sToPlot[sToPlot == 1] <- .7
            hist(sToPlot, breaks = plotBreaks, add = TRUE, col = cols[which(nuc == c("a", "t", "c", "g"))])
        }else{
            hist(sToPlot, breaks = plotBreaks, add = FALSE, col = cols[which(nuc == c("a", "t", "c", "g"))], main = "", xlim = xlim.set, ylim = c(0, max(forYlim$counts)), ylab = ylabs[[nuc]], xlab = xlabs[[nuc]], cex.lab = 1.5)
            text(mean(xlim.set), max(forYlim$counts), paste(toupper(nuc)), pos = 1, cex = 1.5)
        }
        abline(v = meanS, lwd = 2, col = "grey", lty = "solid")
    }
    if(typematch == "syn"){
        typematch.out = "synonymous"
    }else if(typematch == "nonsyn"){
        typematch.out = "nonsynonymous"
    }
    mtext(paste(datset, " Data, ",typematch.out , " sites", sep = ""), outer = TRUE, cex = 1.5)
}



for(dat.file in c("Lehman", "Zanini", "Bachelor")){
    for(sitetype in c("nonsyn", "syn")){
        pdf(paste("../graphs/", dat.file, ".", sitetype, ".pdf", sep = ""), height = 8, width = 8)
        plotter(dat.file, sitetype)
        dev.off()
    }
}
