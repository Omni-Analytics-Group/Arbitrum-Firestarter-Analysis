library(readr)

## Read in data
datamat <- readRDS("Data/Participation/ParticipationData1.csv")
jokdat <- read_csv("Data/ParticipationData.csv")
deldat <- readRDS("Data/TallyDelegate/Delegates.RDS")
deldat$VParb <- as.numeric(deldat$votesCount)/10^18

## Join Data
alldat <- merge(x=datamat,y=jokdat,by="Address",all=TRUE)
alldat <- alldat[,c(1:30,32,35,38,43:50)]
for(idx in 2:ncol(alldat)) alldat[,idx] <- as.numeric(ifelse(is.na(alldat[,idx]),FALSE,alldat[,idx]))

## Number of wallets in one sheet
# as.data.frame(apply(alldat[,-1],2,sum))

## Add Scores
iv_columns <- names(alldat)[c(2,3,34,35,37,36,8:24)]
alldat$AllColSum <- apply(alldat[,-1],1,sum)
alldat$CorrectColSum <- apply(alldat[,iv_columns],1,sum)
alldat$CorrectColScoreSum <- apply(as.matrix(alldat[,iv_columns]) %*% diag(c(1,2,5,5,5,5,1,2,4,4,4,4,6,2,5,3,7,1,2,7,7,3,6)),1,sum)
alldat$OnlySnapshotParticipation <- as.numeric(!apply(alldat[,iv_columns],1,sum)>0)
alldat$DelegateARB <- deldat$VParb[match(tolower(alldat$Address),tolower(deldat$Address))]
alldat$DelegateARB_g10k <- as.numeric(alldat$DelegateARB >= 10000)
alldat$DelegateCount <- deldat$delegatorsCount[match(tolower(alldat$Address),tolower(deldat$Address))]
alldat$DelegateCount_g10 <- as.numeric(alldat$DelegateCount >= 10)
alldat$ifFitDelegateCriterion_g10k_g10 <- as.numeric(alldat$DelegateARB_g10k & alldat$DelegateCount_g10)
alldat$ifFitDelegateCriterion_g10k_g10 <- ifelse(is.na(alldat$ifFitDelegateCriterion_g10k_g10),0,alldat$ifFitDelegateCriterion_g10k_g10)
write_csv(alldat,"Data/Participation/ParticipationData2.csv")

alldat[!(alldat$OnlySnapshotParticipation)&alldat$ifFitDelegateCriterion_g10k_g10,c(1,44)]



## Task Proportion
all_usr_count <- nrow(alldat)
correct_usr_count <- sum(alldat$OnlySnapshotParticipation==0)
prop_results <- data.frame(
							Activity = iv_columns,
							ActivityPropAllUsers = apply(alldat[,iv_columns],2,sum)/all_usr_count,
							ActivityPropCorrectUsers = apply(alldat[,iv_columns],2,sum)/correct_usr_count
				)
write_csv(prop_results,"Data/Participation/ParticipationProportion.csv")



# ## W1 Participants
# sum(Reduce("|",as.list(alldat[,c(2,3,34,35,37,36)])))

# ## W2 Participants
# sum(Reduce("|",as.list(alldat[,c(8:14)])))

# ## W3 Participants
# sum(Reduce("|",as.list(alldat[,c(15:18)])))

# ## W4 Participants
# sum(Reduce("|",as.list(alldat[,c(19:24)])))




## Distance Matrix
# library(parallelDist)
# distmatjac <- as.matrix(parDist(as.matrix(datamat[,-1]),method="binary"))
# saveRDS(distmatjac,"~/Desktop/ThankARBParticipation/distmatjac.RDS")
# distmatjac <- readRDS("~/Desktop/arbitrum/ThankARBParticipation/distmatjac.RDS")

# ## Number of Profiles
# datamat$Profile <- apply(datamat[,-1],1,function(x) paste0(as.numeric(x),collapse=""))

# profdata <- data.frame(Profile = names(table(datamat$Profile)),Count = as.numeric(table(datamat$Profile)))
# profdataout <- profdata[order(profdata$Count,decreasing=TRUE),][1:25,]
# profdataout <- cbind(profdataout,do.call(rbind,lapply(profdataout$Profile,function(x,datamat) datamat[match(x,datamat$Profile),-c(1,ncol(datamat))],datamat=datamat)))
