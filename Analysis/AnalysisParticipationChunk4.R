alldat <- read_csv("Data/Participation/ParticipationData2.csv")

alldat$SupportiveParticipant = as.numeric(alldat$`W4 Gitcoin` & apply(alldat[,c(34,35,37,36,10:14,16:18,22:23)],1,sum))
alldat$ActiveSnapshotVoter = as.numeric(apply(alldat[,25:30],1,sum)==6)
alldat$SurveyArtist = as.numeric(alldat$`W3 Ethelo Mission Vision` & alldat$`W4 Ethelo Priorities`)
alldat$CrossPlatformInformer = as.numeric(apply(alldat[,c(34,35,37,36,10:14)],1,sum) & apply(alldat[,c(18,22)],1,sum))
alldat$SignalBooster = as.numeric(alldat$`W1 Push` & alldat$`W1 Twitter`)
saveRDS(alldat,"Data/Participation/ParticipationDataLabelled.RDS")