## Load Libraries
library(readxl)
library(readr)

################################################################
## Ethlo
################################################################
## Load Ethlo Data
## Season 1
s1du <- cbind(Season = 1,read_excel("Data/JokerAce/DataProposalsJokerAce.csv/Ethlo/S1/arbitrumdao-s1_decision_users.xlsx"))
s1dc <- cbind(Season = 1,read_excel("Data/JokerAce/DataProposalsJokerAce.csv/Ethlo/S1/comments-s1.xlsx"))
s1dv <- cbind(Season = 1,read_excel("Data/JokerAce/DataProposalsJokerAce.csv/Ethlo/S1/arbitrumdao-s1_survey_and_votes.xlsx"))

## Season 2
s2du <- cbind(Season = 2,read_excel("Data/JokerAce/DataProposalsJokerAce.csv/Ethlo/S2/arbitrumdao-s2_decision_users.xlsx"))
s2dc <- cbind(Season = 2,read_excel("Data/JokerAce/DataProposalsJokerAce.csv/Ethlo/S2/comments-s2.xlsx"))
s2dv <- cbind(Season = 2,read_csv("Data/JokerAce/DataProposalsJokerAce.csv/Ethlo/S2/arbitrumdao-s2-voting-summary.csv"))


## Season 3
s3du <- cbind(Season = 3,read_excel("Data/JokerAce/DataProposalsJokerAce.csv/Ethlo/S3/arbitrumdao-s3_decision_users.xlsx"))
s3dc <- cbind(Season = 3,read_excel("Data/JokerAce/DataProposalsJokerAce.csv/Ethlo/S3/comments-s3.xlsx"))
s3dv <- cbind(Season = 3,read_csv("Data/JokerAce/DataProposalsJokerAce.csv/Ethlo/S3/arbitrumdao-s3-voting-summary.csv"))

## Compile Ethelo Data
natozero <- function(x) ifelse(is.na(x),0,x)
all_users <- unique(na.omit(c(s1du$`Web3 Addresses`,s2du$`Web3 Addresses`,s3du$`Web3 Addresses`)))
ethlo_data <- data.frame(
							Address = all_users,
							E_IfParticipantS1 = all_users %in% s1du$`Web3 Addresses`,
							E_CommentCountS1 = natozero(s1du$`Comment Count`[match(all_users,s1du$`Web3 Addresses`)]),
							E_RolesS1 = s1du$Roles[match(all_users,s1du$`Web3 Addresses`)],
							E_IfParticipantS2 = all_users %in% s2du$`Web3 Addresses`,
							E_CommentCountS2 = natozero(s2du$`Comment Count`[match(all_users,s2du$`Web3 Addresses`)]),
							E_RolesS2 = s2du$Roles[match(all_users,s2du$`Web3 Addresses`)],
							E_IfParticipantS3 = all_users %in% s3du$`Web3 Addresses`,
							E_CommentCountS3 = natozero(s3du$`Comment Count`[match(all_users,s3du$`Web3 Addresses`)]),
							E_RolesS3 = s3du$Roles[match(all_users,s3du$`Web3 Addresses`)]
				)
ethlo_data$E_TotalParticipant = ethlo_data$E_IfParticipantS1 + ethlo_data$E_IfParticipantS2 + ethlo_data$E_IfParticipantS3
ethlo_data$E_TotalCommentCount = ethlo_data$E_CommentCountS1 + ethlo_data$E_CommentCountS2 + ethlo_data$E_CommentCountS3
################################################################
################################################################


################################################################
## Jokerace
################################################################
jokrpd <- read_csv("Data/JokerAce/DataProposalsJokerAce.csv")
jokrvd <- read_csv("~/Desktop/TopicAnalysis/DataVotesJokerAce.csv")
jokrqd <- c(
				"ReduceFriction" = "0xbf47bda4b172daf321148197700cbed04dbe0d58",
				"GrowthInnovation" = "0x5d4e25fa847430bf1974637f5ba8cb09d0b94ec7",
				"Vision" = "0x0d4c05e4bae5ee625aadc35479cc0b140ddf95d4",
				"Mission" = "0x5a207fa8e1136303fd5232e200ca30042c45c3b6"
			)

all_users <- unique(c(jokrpd$Address,jokrvd$Address))
jokerace_data <- data.frame(
								Address = all_users,
								J_CommentReduceFriction = all_users %in% jokrpd$Address[jokrpd$Contract=="0xbf47bda4b172daf321148197700cbed04dbe0d58"],
								J_CommentGrowthInnovation = all_users %in% jokrpd$Address[jokrpd$Contract=="0x5d4e25fa847430bf1974637f5ba8cb09d0b94ec7"],
								J_CommentVision = all_users %in% jokrpd$Address[jokrpd$Contract=="0x0d4c05e4bae5ee625aadc35479cc0b140ddf95d4"],
								J_CommentMission = all_users %in% jokrpd$Address[jokrpd$Contract=="0x5a207fa8e1136303fd5232e200ca30042c45c3b6"],
								J_VoteReduceFriction = all_users %in% jokrvd$Address[jokrvd$Contract=="0xbf47bda4b172daf321148197700cbed04dbe0d58"],
								J_VoteGrowthInnovation = all_users %in% jokrvd$Address[jokrvd$Contract=="0x5d4e25fa847430bf1974637f5ba8cb09d0b94ec7"],
								J_VoteVision = all_users %in% jokrvd$Address[jokrvd$Contract=="0x0d4c05e4bae5ee625aadc35479cc0b140ddf95d4"],
								J_VoteMission = all_users %in% jokrvd$Address[jokrvd$Contract=="0x5a207fa8e1136303fd5232e200ca30042c45c3b6"]
					)
################################################################
################################################################


################################################################
## Snapshot
################################################################
snapd <- readRDS("Data/Snapshot/Votes.RDS")
all_users <- unique(snapd$voter)
snap_data <- data.frame(
							Address = all_users,
							S_Voted_GovMonth_ReduceFriction = all_users %in% snapd$voter[snapd$prop_id=="0x14e71f784e880170972572c2696ef53ef437700c637a151b5176a5827fe5b8bc"],
							S_Voted_GovMonth_GrowthInnovation = all_users %in% snapd$voter[snapd$prop_id=="0x5824d0b51cc435a49f6455ee2715216d6b958637218ed79e3e93c41af6bdef33"],
							S_Voted_DA_Gaming = all_users %in% snapd$voter[snapd$prop_id=="0x399ccb013b49076b1ec98dd48fb088c061d3a1db45b528d8854d59c4dabe2336"],
							S_Voted_DA_Tooling = all_users %in% snapd$voter[snapd$prop_id=="0x6a578c12950f9367d2530b0324f06835bf9df5b957adcfe2bce1a240dcc09ae4"],
							S_Voted_DA_NetProtocolIdeas = all_users %in% snapd$voter[snapd$prop_id=="0xfa78979a7afa0b0df5c885ebf3a0d46c3676152c6c95b482ed9e91c2ed2dcca5"],
							S_Voted_DA_EducationCommunity = all_users %in% snapd$voter[snapd$prop_id=="0x84e841ad47a5ac7eae2c8ee87c05abc381f8e724598d939ae67060487268304f"]
				)
snap_data$S_Voted_Total <- 		snap_data$S_Voted_GovMonth_ReduceFriction+snap_data$S_Voted_GovMonth_GrowthInnovation+snap_data$S_Voted_DA_Gaming+
									snap_data$S_Voted_DA_Tooling+snap_data$S_Voted_DA_NetProtocolIdeas+snap_data$S_Voted_DA_EducationCommunity
							
################################################################
################################################################


################################################################
## Combined
################################################################
ethlo_data$Address <- tolower(ethlo_data$Address)
jokerace_data$Address <- tolower(jokerace_data$Address)
snap_data$Address <- tolower(snap_data$Address)

all_data <- merge(snap_data,merge(ethlo_data,jokerace_data,all=TRUE),all=TRUE)
write_csv(all_data,"Data/Participation/ParticipationData1.csv")
################################################################
################################################################

