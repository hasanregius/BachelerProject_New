#add a comment here to show ryan
setwd("~/Documents/Git/bachelerProject/Rscripts/")

if (FALSE) source("prepareDataForGLM.R")
source("helperFunctionsForF2.R")

#Substantially more complicated model with structural elements
#fullmodel.int <- glm(minor ~ t + c + g + bigAAChange + inRT + t*nonsyn + c*nonsyn + g*nonsyn + shape + CpG + CpG*t  + CpG*nonsyn + CpG*nonsyn*t + helix*nonsyn + beta*nonsyn + coil*nonsyn,  family = "binomial", data = datFitModel[datFitModel$res == 0 & datFitModel$stop == 0,])

#Run model  
if (FALSE) fullmodel.int <- glm(minor ~ inRT + shape + t + c + g + CpG + CpG*t  + t*nonsyn + c*nonsyn + g*nonsyn + nonsyn*CpG + t:nonsyn:CpG + bigAAChange,  family = "binomial", data = datFitModel[datFitModel$res == 0 & datFitModel$stop == 0,])
if (FALSE) sumOfModel <- summary(fullmodel.int)

#Create a table for latex 
require(xtable)
#This doesn't work yet: #write(xtable(sumOfModel, digits = 3), "ModelTable.txt")
xtable(sumOfModel, digits = 3)
print(xtable(sumOfModel, digits = 3),type="html",file="../Output/SumOfGLMModel1.html")

#fullmodel.small <- glm(minor ~ t + c + g + bigAAChange + t*nonsyn + c*nonsyn + g*nonsyn + CpG + CpG*t  + CpG*nonsyn + CpG*nonsyn*t,  family = "binomial", data = datFitModel[datFitModel$res == 0 & datFitModel$stop == 0,])
#sumOfModel <- summary(fullmodel.small)

modcoef <- sumOfModel$coef

coef.vals <- modcoef[,1]
coef.pSE.vals <- coef.vals + modcoef[,2]
coef.mSE.vals <- coef.vals - modcoef[,2]

inPRrows <- intersect(which(OverviewDF$TypeOfSite != "overlap"), 1:297)
inRTrows <- intersect(which(OverviewDF$TypeOfSite != "overlap"), 298:984)

#Pleuni: not sure what this does
tmpDat.0 <- DataFrameOfData()
tmpDat.0[,8] <- 0 #shape
tmpDat.1 <- DataFrameOfData()
tmpDat.1[,8] <- 1 #shape

mean(exp(tmpDat.0 %*% coef.vals))
mean(exp(tmpDat.1 %*% coef.vals))

#syn vs nonsyn
nonsynrows <- which(OverviewDF$TypeOfSite == "nonsyn")
synrows <- which(OverviewDF$TypeOfSite == "syn")
mean(exp(DataFrameOfData()[nonsynrows,] %*% coef.vals))
mean(exp(DataFrameOfData()[synrows,] %*% coef.vals))
mean(OverviewDF$MeanFreq[nonsynrows])
mean(OverviewDF$MeanFreq[synrows])


#Let's do some fresh analysis on this for Marion.
#What's the average shape coefficient?
avShape <- mean(PolShapeData$SHAPE)
avShape
inRTval <- 1
#PSP Sept 2017: make sure we read those mutation rates 
read.csv("../Data/HIVMutRates/HIVMutRates.csv")->mutrates
included<-c(which(mutrates$Nucleotide.substitution=="AG"),
  which(mutrates$Nucleotide.substitution=="UC"),
  which(mutrates$Nucleotide.substitution=="CU"),
  which(mutrates$Nucleotide.substitution=="GA"))

for (MutRates in c("Abram","Zan")){
    if (MutRates == "Abram") mus<-mutrates$Probability[included] #This reads the Abram mut rates
    if (MutRates == "Zan") mus<-mutrates$ZaniniProb[included] #This reads the Abram mut rates
    #mus <- c(1.11e-05, 1.11e-05, 2.41e-05, 5.48e-05)

# Point 1:
#synonymous CpG forming mutations
CpGSyn<-mus/exp(makeDataFrameToModify.withSHAPEandinRT(0,1,0, avShape, inRTval)[,rownames(modcoef)] %*% coef.vals)

#synonymous non-CpG forming mutations
NonCpGSyn<-mus/exp(makeDataFrameToModify.withSHAPEandinRT(0,0,0, avShape, inRTval)[,rownames(modcoef)] %*% coef.vals)

#Magnitude changes
magchanges<-(mus/exp(makeDataFrameToModify.withSHAPEandinRT(0,1,0, avShape, inRTval)[,rownames(modcoef)] %*% coef.vals))/(mus/exp(makeDataFrameToModify.withSHAPEandinRT(0,0,0, avShape, inRTval)[,rownames(modcoef)] %*% coef.vals))

if (MutRates == "Abram") cat("MUTRATES FROM ABRAM 2010" ,file = "../Output/GLMResultsText.txt", append=FALSE,sep="\n")
if (MutRates == "Zan") cat("MUTRATES FROM ZANINI 2017" ,file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")

cat("\n\nPOINT 1\n" ,file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")

cat("Using model-predicted frequencies and known mutation rates, we find that CpG-creating synonymous mutations are ",file = "../Output/GLMResultsText.txt", append=TRUE)
cat(round(mean(magchanges[1:2])),file = "../Output/GLMResultsText.txt", append=TRUE)
cat(" times more costly (selection coefficient appr. ",file = "../Output/GLMResultsText.txt", append=TRUE)
cat(round(mean(CpGSyn[1:2]),3),file = "../Output/GLMResultsText.txt", append=TRUE)
cat( ") than non-CpG-creating synonymous mutations (selection coefficient ~",file = "../Output/GLMResultsText.txt", append=TRUE)
cat(round(mean(NonCpGSyn[1:2]),5),file = "../Output/GLMResultsText.txt", append=TRUE)
cat(" )).\n",file = "../Output/GLMResultsText.txt", append=TRUE)


cat("\nMore detail \nA-G mutations\n",file = "../Output/GLMResultsText.txt", append=TRUE)
cat(round(mean(magchanges[1]),2),file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(round(mean(CpGSyn[1]),4),file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(round(mean(NonCpGSyn[1]),6),file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")

cat("\nC-T mutations\n",file = "../Output/GLMResultsText.txt", append=TRUE)
cat(round(mean(magchanges[2]),2),file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(round(mean(CpGSyn[2]),4),file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(round(mean(NonCpGSyn[2]),6),file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")

# Point 2: Pleuni: not sure which point this is. 
AGGA<-mus/exp(makeDataFrameToModify.withSHAPEandinRT(0,0,0, avShape, inRTval)[,rownames(modcoef)] %*% coef.vals)

cat(        "\n\nPOINT 2\n" ,file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")

cat("\n\nIndeed, the estimated selection coefficients based on model predictions suggested that synonymous G to A mutations are" ,file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(round(AGGA[4]/AGGA[1],2),file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat("times as costly as non-CpG-forming A to G mutations (",file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(round(AGGA[4],4),file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat("vs",file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(round(AGGA[1],4),file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(").",file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")

cat("\n Note that p-values come from analyseAndFigures-Bacheler.Rmd",file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")

#  Point 3:
#Non-synonymous (changes AA group versus doesn’t change AA group) - among non-CpG forming mutations. 

#Does not change AA group:
NotDrastic<-mus/exp(makeDataFrameToModify.withSHAPEandinRT(1,0,0, avShape, inRTval)[,rownames(modcoef)] %*% coef.vals)

#Does change AA group:
Drastic<-mus/exp(makeDataFrameToModify.withSHAPEandinRT(1,0,1, avShape, inRTval)[,rownames(modcoef)] %*% coef.vals)

#Magnitude change:
MagChange<-(mus/exp(makeDataFrameToModify.withSHAPEandinRT(1,0,1, avShape, inRTval)[,rownames(modcoef)] %*% coef.vals))/(mus/exp(makeDataFrameToModify.withSHAPEandinRT(1,0,0, avShape, inRTval)[,rownames(modcoef)] %*% coef.vals))
cat(        "\n\nPOINT 3\n" ,file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")

cat("\n\nIn general, mutations that led to a drastic amino acid change were found at lower frequency than mutations that did not ($p < 0.001$).",
    file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")

cat("\nFor example, A to G mutations that result in a drastic amino acid change are roughly" ,file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(round(MagChange[1],2),file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat("times more costly than A to G mutations that do not (",file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(round(Drastic[1],4),file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(        "vs" ,file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(round(NotDrastic[1],4),file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(       ").",file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n") 
cat("We observed similar fold changes for the other possible transitions.",file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")


#  Point 4:
#Nonsynonymous, does not change AA group, does not create new CpG:
noNewCpG <- mus/exp(makeDataFrameToModify.withSHAPEandinRT(1,0,0, avShape, inRTval)[,rownames(modcoef)] %*% coef.vals)

#Nonsynonymous, does not change AA group, does create new CpG:
NewCpG <- mus/exp(makeDataFrameToModify.withSHAPEandinRT(1,1,0, avShape, inRTval)[,rownames(modcoef)] %*% coef.vals)

#Magnitude change
NewCpG/noNewCpG


cat("\n\nPOINT 4\n" ,file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")

cat("\nThere was also an effect of whether or not a non-synonymous mutation created a 
    CpG site ($p < 0.001$ for both A-G and T-C mutations). 
    The difference in frequencies suggests that, 
    among mutations that do not lead to a drastic amino acid change, 
    A-G mutations that create a CpG site are approximately" ,file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(round(NewCpG[1]/noNewCpG[1],2),file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(        "times more costly than those that do not " ,file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(round(NewCpG[1],4),file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(        "vs" ,file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(round(noNewCpG[1],4),file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")

cat(        "\n\nSimilarly, 
            among mutations that do not lead to a drastic amino acid change, 
            T-C mutations that create a CpG site are approximately " ,file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(round(NewCpG[2]/noNewCpG[2],2),file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat( "times more costly than those that do not" ,file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(round(NewCpG[2],4),file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(        "vs" ,file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")

cat(round(noNewCpG[2],4),file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")


#  Point 5
#Non synonymous, non-CpG forming, does not change AA group:
noNewCpG

cat(        "\n\nPOINT 5\n" ,file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")

cat(        "\nWe estimated that, among non-synonymous mutations that do not involve a drastic amino acid change 
            or create a CpG site, 
            C-T mutations are \n" ,file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")

cat(round(noNewCpG[3]/noNewCpG[1],2),file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(        "times more costly than A-G mutations " ,file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(round(noNewCpG[3],4),file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(        "vs" ,file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(round(noNewCpG[1],4),file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(        ", and G-A mutations are " ,file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
#PSP I think this should be noNewCpG[1] instead of noNewCpG[2]
cat(round(noNewCpG[4]/noNewCpG[1],2),file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(        "times more costly than A-G mutations" ,file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(round(noNewCpG[4],4),file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(        "vs" ,file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")
cat(round(noNewCpG[1],4),file = "../Output/GLMResultsText.txt", append=TRUE,sep="\n")

#PSP: continue here. 

#Make plots
library(plotrix)
require(RColorBrewer)
png("../Output/modeled_freqs_Sep2017_2.png",width=12,height=7.5,units="in",res=100)
#if (MutRates == "Zan") png("../Output/EstSelCoeffZanPRO_aug2017.png",width=12,height=7.5,units="in",res=100)
#pdf("../Output/modeled_freqs_May2017_2.pdf", width = 12, height = 7)
#cols <- brewer.pal(4, "Set2")
layout(matrix(1:2, nrow = 1))
par(mar = c(4, 4.5, 1.5, 1))
makePlot.axisbreak(main = "Synonymous Sites")
plotVals(0, 1, 0, cols[1], .1)
plotVals(0, 0, 0, cols[2], -.1)
plotDat(0, 1, 0, cols[1], .1)
plotDat(0, 0, 0, cols[2], -.1)
abline(v = 1:3 + .5, col = "black")
#legend("topleft", c("CpG-forming", "non-CpG-forming"), col = cols[1:2], pch = 16, bg = "white")
legend("bottomright", c("No drastic AA change (non-CpG-forming)", "No drastic AA change (CpG-forming)", "Drastic AA change (non-CpG-forming)",  "Drastic AA change (CpG-forming)"), col = cols[c(2,1,3,4)], pch = 16, bg = "white" )
makePlot.axisbreak(main = "Non-synonymous Sites")
plotDat(1, 0, 1, cols[3], .1)
plotDat(1, 0, 0, cols[2], -.3)
plotDat(1, 1, 0, cols[1], -.1)
plotDat(1, 1, 1, cols[4], .3)
plotVals(1, 0, 1, cols[3], .1)
plotVals(1, 0, 0, cols[2], -.3)
plotVals(1, 1, 0, cols[1], -.1 )
plotVals(1, 1, 1, cols[4], .3 )
abline(v = 1:3 + .5, col = "black")
dev.off()

#pdf("../Output/modeled_sels_May2017.pdf", width = 12, height = 7)
if (MutRates == "Abram") png("../Output/modeled_sels_AbramSEP2017.png",width=12,height=7.5,units="in",res=100)
if (MutRates == "Zan") png("../Output/modeled_sels_ZanSEP2017.png",width=12,height=7.5,units="in",res=100)
#cols <- brewer.pal(4, "Set2")
layout(matrix(1:2, nrow = 1))
par(mar = c(4, 4.5, 1.5, 1))
makePlot.svals(main = "Synonymous Sites")
plotVals.svals(0, 1, 0, cols[1], .1,mus)
plotVals.svals(0, 0, 0, cols[2], -.1,mus)
plotDat.svals(0, 1, 0, cols[1], .1,mus)
plotDat.svals(0, 0, 0, cols[2], -.1,mus)
abline(v = 1:3 + .5, col = "black")
#legend("topleft", c("CpG-forming", "non-CpG-forming"), col = cols[1:2], pch = 16, bg = "white")
legend("topleft", c("No drastic AA change (non-CpG-forming)", "No drastic AA change (CpG-forming)", "Drastic AA change (non-CpG-forming)",  "Drastic AA change (CpG-forming)"), col = cols[c(2,1,3,4)], pch = 16, bg = "white" )
#legend("topleft", c("Same AA group (non-CpG-forming)", "Same AA group (CpG-forming)", "Changes AA group (non-CpG-forming)",  "Changes AA group (CpG-forming)"), col = cols[c(2,1,3,4)], pch = 16, bg = "white" )
makePlot.svals(main = "Non-synonymous Sites")
plotDat.svals(1, 0, 1, cols[3], .1,mus)
plotDat.svals(1, 0, 0, cols[2], -.3,mus)
plotDat.svals(1, 1, 0, cols[1], -.1,mus)
plotDat.svals(1, 1, 1, cols[4], .3,mus)
plotVals.svals(1, 0, 1, cols[3], .1,mus)
plotVals.svals(1, 0, 0, cols[2], -.3,mus)
plotVals.svals(1, 1, 0, cols[1], -.1 ,mus)
plotVals.svals(1, 1, 1, cols[4], .3 ,mus)
abline(v = 1:3 + .5, col = "black")
dev.off()

}
#Look at modelPredTest.r It has code to look at how good the model predicts frequencies. Not very good. 

