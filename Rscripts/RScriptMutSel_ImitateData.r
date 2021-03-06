#This script will run simulations (using a separate C++ script) to create a fake DFE, population frequencies in a few hundred patients, based on the DFE,  
# and fake Bacheler, Zanini and Lehman like datasets using what we know about how the samples were taken. 
#I then calculate R^2 values between all datasets. 

####################
#Preparations
#setwd("~/Dropbox/MarionKristofBachelerProject/GitMarionKristof/bachelerProject/SimulationsEstimatingSelCoeffSims/Scripts")
setwd("~/Documents/Git/bachelerProject/SimulationsEstimatingSelCoeffSims/Scripts")
system("./Code_and_shellscript/make_HIV1site")    #compile the code 
library(ggplot2)
#####function to go from mu/meanfreq to estimated s (including case where meanfreq = 0)
source("../../Rscripts/baseRscript.R")
#EstimatedS <- function(mu, meanfreq){ #Now in basescript
#    if (meanfreq == 0) return (1)
#    else return (min(c(mu/meanfreq,1)))
#}
######
#First, let's get the sample sizes for Bacheler data and store them in Numseqs
#Read the correct fastafiles.
listfastafiles<-list.files("../../Data/BachelerFiles//FASTAfiles")
lengthallsequenceslist<-c()
NumseqsBach<-c()
for (i in 1:length(listfastafiles)){ #for each fastafile
    filename=paste("../../Data/BachelerFiles/FASTAfiles/",substr(listfastafiles[i],1,6),".fasta",sep="")
    patfasta<-read.dna(filename, format = "fasta",as.character=TRUE) #read the file
    NumseqsBach<-c(NumseqsBach,nrow(patfasta))
}
NumseqsBach<-NumseqsBach[NumseqsBach>1] #remove patients with just one sequence

Data<-data.frame(RealVsBach=0,RealVsZan=0,RealVsLehm=0,BachVsLehm=0,BachVsZan=0,ZanVsLeh=0)

for (j in 1:10){
##########################
#Create Fake DFE based on estimated gamma parameters
BachParamLethal=0.065; BachParamShape = 0.209; BachParamScale = 0.317;
numsites = 100 #should be 900 later 
numlethal =  round(BachParamLethal*numsites)
ListCosts = c(round(rgamma(numsites-numlethal, shape = 0.209, scale = 0.317),6),rep(1,numlethal))
ListCosts[ListCosts>1]<-1 #to make sure it doesn't go above 1    

##########################
#Create Fake Pop Frequencies based on ListCosts and chosen parameters (theta!)
#This part uses the C++ script
#The output on screen looks weird, it comes from this line in the cpp code: cerr << numgen_inN<< " "<<numgen << "\n";
system("rm ../Data/*") #remove old data
Ne = 10000 #currently Ne cannot be changed in the sims 
TotalNumPats = 400 #(max num of patients, should be around 400, enough for Bach, Zanini and Lehman)
NUMRUNS=1; numoutputs=TotalNumPats
theta = 1 #Working with just one theta value for now. 
mu = theta / Ne
seed =1
for (site in 1:numsites){
    print(paste("site",site))
    cost = ListCosts[site]
    #make script 
    x<-"#!/bin/bash"
    x<-c(x,paste("mu=",mu,sep=""))
    outputfrequency=min(c(2*Ne,ceiling(5/cost)))
    x<-c(x,paste("output_every_Xgen=",outputfrequency,sep=""))
    x<-c(x,paste("numgen_inN=",(numoutputs+2)*outputfrequency/Ne,sep=""))
    x<-c(x,paste("start_output=",2*outputfrequency/Ne,sep=""))
    x<-c(x,paste("cost=",cost,sep=""))
    x<-c(x,paste("for seed in",seed))
    x<-c(x,"do",
         "echo \"", "$seed", "$mu", "$cost",
         "$output_every_Xgen", "$numgen_inN", "$start_output",
         paste("\" | ./Code_and_shellscript/HIVevolution_HIV1site >../Data/Data_s_", site, "_T_", theta, "_cost_", cost,".txt",sep=""), 
         "done")
    write(x,file="./Code_and_shellscript/tempscript.sh")
    system("chmod 775 ./Code_and_shellscript/tempscript.sh")
    #Run tempscript.sh
    system("./Code_and_shellscript/tempscript.sh")
}

##### make sure that ListCosts and ListFiles is in the same order
ListFiles<-list.files("../Data/")
ListCosts<-rep(0,length(ListFiles))
for (i in 1:length(ListFiles)){
    ListCosts[i]<-as.numeric(substr(ListFiles[i], regexpr("cost",ListFiles[i])[1]+5, regexpr(".txt",ListFiles[i])[1]+-1))
}

#####################
#Create Bacheler dataset. 
#For the fake set of selection coefficients, I will create a fake Bacheler dataset that has theta = 1, sample sizes for 171 patients as in the actual Bacheler dataset and no sequencing errors. 
ListMeanFreqsBach<-rep(0,length(ListFiles))
ListMeanPopFreqsBach<-rep(0,length(ListFiles))
NumpatsBach = length(NumseqsBach)
Pats<-1:NumpatsBach #take the first NumpatsBach patients
for (i in 1:length(ListFiles)){ # for each site
    PopFreqs<-read.csv(paste("../Data/",ListFiles[i],sep=""),sep = "\t")$freq[Pats]
    SampleFreqs<-rep(0,NumpatsBach)
    for (pat in 1:length(Pats)){ #for each pat determine SampleFreq depending on PopFreq and Samplesize (NumseqsBach) 
        SampleFreqs[pat]<-rbinom(1,NumseqsBach[pat],PopFreqs[pat])/NumseqsBach[pat]}
    ListMeanFreqsBach[i]<-mean(SampleFreqs)
    ListMeanPopFreqsBach[i]<-mean(PopFreqs)    
}
#Now go from frequencies to estimated selection coefficients
ListEstimatedCostsBach<-sapply(ListMeanFreqsBach,function(x) EstimatedS(mu,x))

#####################
#Make a Zanini dataset
#I’ll also create a fake Zanini dataset with around 70 samples, with 100 RNA templates per sample and a 1/500 error rate. 
ListMeanFreqsZanini<-rep(0,length(ListFiles))
NumpatsZanini = 70 ; NumseqsZanini = rep(100,NumpatsZanini)
ZaniniErrorRate=1/500
Pats<-(1+NumpatsBach):(NumpatsBach+NumpatsZanini) #take the second batch of patients
for (i in 1:length(ListFiles)){ # for each site
    PopFreqs<-read.csv(paste("../Data/",ListFiles[i],sep=""),sep = "\t")$freq[Pats] #Pats makes sure I get the "right" patients, not the same as in the Bach dataset
    SampleFreqs<-rep(0,NumpatsZanini)
    for (pat in 1:length(Pats)){ #for each pat determine SampleFreq depending on PopFreq and Samplesize (Numseqs) 
        NumMut<-rbinom(1,NumseqsZanini[pat],PopFreqs[pat])
        #Now I need to add a sequencing error here. 
        #The number of mutants that are erroneously called as WT
        AddWT<-rbinom(1,NumMut,ZaniniErrorRate)
        AddMut<-rbinom(1,NumseqsZanini[pat]-NumMut,ZaniniErrorRate)
        SampleFreqs[pat]<-(NumMut+AddMut-AddWT)/NumseqsZanini[pat]
    }
    ListMeanFreqsZanini[i]<-mean(SampleFreqs)
}
#Now go from frequencies to estimated selection coefficients
ListEstimatedCostsZanini<-sapply(ListMeanFreqsZanini,function(x) EstimatedS(mu,x))


#####################
#Make a Lehman dataset
#I’ll also create a fake Lehman dataset with around 100 samples, with 1600 RNA templates per sample and a 1/200 error rate. 
ListMeanFreqsLehman<-rep(0,length(ListFiles))
NumpatsLehman = 100 ; NumseqsLehman = rep(1600,NumpatsLehman) #1600 RNA templates
LehmanErrorRate=1/200
Pats<-(1+NumpatsBach+NumpatsZanini):(NumpatsBach+NumpatsZanini+NumpatsLehman) #take the first Numpats patients
for (i in 1:length(ListFiles)){ # for each site
    PopFreqs<-read.csv(paste("../Data/",ListFiles[i],sep=""),sep = "\t")$freq[Pats] #Pats makes sure I get the "right" patients, not the same as in the Bach dataset
    SampleFreqs<-rep(0,NumpatsLehman)
    for (pat in 1:length(Pats)){ #for each pat determine SampleFreq depending on PopFreq and Samplesize (Numseqs) 
        NumMut<-rbinom(1,NumseqsLehman[pat],PopFreqs[pat])
        #Now I need to add a sequencing error here. 
        #The number of mutants that are erroneously called as WT
        AddWT<-rbinom(1,NumMut,LehmanErrorRate)
        AddMut<-rbinom(1,NumseqsLehman[pat]-NumMut,LehmanErrorRate)
        SampleFreqs[pat]<-(NumMut+AddMut-AddWT)/NumseqsLehman[pat]
    }
    ListMeanFreqsLehman[i]<-mean(SampleFreqs)
}
#Now go from frequencies to estimated selection coefficients
ListEstimatedCostsLehman<-sapply(ListMeanFreqsLehman,function(x) EstimatedS(mu,x))

RsquaredValues<-c(
cor.test(ListCosts,ListEstimatedCostsBach)$estimate,
cor.test(ListCosts,ListEstimatedCostsZanini)$estimate,
cor.test(ListCosts,ListEstimatedCostsLehman)$estimate,
cor.test(ListEstimatedCostsBach,ListEstimatedCostsLehman)$estimate,
cor.test(ListEstimatedCostsBach,ListEstimatedCostsZanini)$estimate,
cor.test(ListEstimatedCostsZanini,ListEstimatedCostsLehman)$estimate)     
     
Data[j,]<-RsquaredValues
}

write.csv(Data,"SimResultsR2Values.csv")

#Make Plot
Means<-apply(Data,2,mean)
SD <-apply(Data,2,sd)
#Serr <- with(Data, tapply(HR, Status, function(x)sd(x)/sqrt(length(x))))
plot(Means,pch=16,cex=2,ylim=c(0,1),xaxt="n",main="R^2 values between simulated and real datasets")
axis(1, at=1:(length(SD)),labels=names(SD), las=1)
for (x in 1:length(SD)){
    lines(rep(x,2), c(Means[x]+SD[x], Means[x]-SD[x]),lwd=2)
    }

#Add datapoints
read.csv("../../Output/OverviewSelCoeff_Bacheler.csv")$EstSelCoeff->ListEstimatedCostsBachReal
read.csv("../../Output/OverviewSelCoeffZanini.csv")$EstSelCoeff->ListEstimatedCostsZaniniReal
read.csv("../../Output/OverviewSelCoeffLehman.csv")$EstSelCoeff->ListEstimatedCostsLehmanReal
points(6,cor.test(ListEstimatedCostsBachReal,ListEstimatedCostsLehmanReal)$estimate,col=2,pch=16,cex=2)
points(5,cor.test(ListEstimatedCostsZaniniReal,ListEstimatedCostsBachReal)$estimate,col=2,pch=16,cex=2)
points(4,cor.test(ListEstimatedCostsZaniniReal,ListEstimatedCostsLehmanReal)$estimate,col=2,pch=16,cex=2)


read.csv("../../Output/OverviewSelCoeff_Bacheler.csv")$colMeansTs0->ListFreqsBachReal
read.csv("../../Output/OverviewSelCoeffZanini.csv")$colMeansTsZanini->ListFreqsCostsZaniniReal
read.csv("../../Output/OverviewSelCoeffLehman.csv")$colMeansTsLehman->ListFreqsLehmanReal
cor.test(ListFreqsBachReal,ListFreqsLehmanReal)
cor.test(ListFreqsCostsZaniniReal,ListFreqsBachReal)
cor.test(ListFreqsCostsZaniniReal,ListFreqsLehmanReal)

plot(ListCosts,ListEstimatedCostsBach,xlim=c(0,1),ylim=c(0,1))
plot(ListCosts,ListEstimatedCostsZanini,xlim=c(0,1),ylim=c(0,1))
plot(ListCosts,ListEstimatedCostsLehman,xlim=c(0,1),ylim=c(0,1))
plot(ListEstimatedCostsBach,ListEstimatedCostsLehman,xlim=c(0,1),ylim=c(0,1))
plot(ListEstimatedCostsBach,ListEstimatedCostsZanini,xlim=c(0,1),ylim=c(0,1))
plot(ListEstimatedCostsZanini,ListEstimatedCostsLehman,xlim=c(0,1),ylim=c(0,1))

plot(ListEstimatedCostsBachReal+0.001,ListEstimatedCostsLehmanReal+0.001,log="xy")
plot(ListEstimatedCostsZaniniReal,ListEstimatedCostsBachReal)
plot(ListEstimatedCostsZaniniReal,ListEstimatedCostsLehmanReal)
