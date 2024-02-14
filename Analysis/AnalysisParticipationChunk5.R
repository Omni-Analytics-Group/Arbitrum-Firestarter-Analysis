library(ggplot2)
library(reshape2)
library(hrbrthemes)
library(omnitheme)

## Read in Data
alldat <- read_csv("Data/Participation/ParticipationData2.csv")

## Week wise activity
w1 <- alldat$Address[Reduce("|",as.list(alldat[,c(2,3,34,35,37,36)]))]
w2 <- alldat$Address[Reduce("|",as.list(alldat[,8:14]))]
w3 <- alldat$Address[Reduce("|",as.list(alldat[,15:18]))]
w4 <- alldat$Address[Reduce("|",as.list(alldat[,19:24]))]

allusers <- data.frame(Address=unique(c(w1,w2,w3,w4)),Week="")
allusers$Week[allusers$Address %in% w4] <- "Week 4"
allusers$Week[allusers$Address %in% w3] <- "Week 3"
allusers$Week[allusers$Address %in% w2] <- "Week 2"
allusers$Week[allusers$Address %in% w1] <- "Week 1"
allusers$Week <- as.factor(allusers$Week)
actmat <- sapply(list(w1,w2,w3,w4),function(x) table(allusers$Week[match(x,allusers$Address)]))	
colnames(actmat) <- c("Week 1","Week 2","Week 3","Week 4")
plotdat <- melt(actmat)
names(plotdat) <- c("Joined","Week","Participants")

plot <- ggplot(plotdat[plotdat$Participants>0,],aes(fill=Joined, y=Participants, x=Week,label = Participants)) + 
		geom_bar(position="stack", stat="identity") + 
		scale_fill_brewer(palette="Set2") + 
		geom_text( size = 2, position = position_stack(vjust = 0.5),colour = "white") +
		ggtitle("Partcipation over Time",subtitle = "Participants Color coded according to the week they first participated.") + 
		scale_y_continuous(breaks = seq(0, 15000, by = 2500),limits=c(0,15000)) + 
		theme_ipsum() + 
		watermark_img(filename = "Images/arb.png", location = "tr", width = 40, alpha = 0.5)

ggsave(plot, filename = "Images/plotout.jpeg", dpi = 300, width = 10, height = 6)



plotdat <- alldat[,c("CorrectColScoreSum","DelegateARB_g10k")]
plotdat <- plotdat[complete.cases(plotdat),]
plotdat$DelegateARB_g10k <- as.logical(plotdat$DelegateARB_g10k)
	ggplot(plotdat,aes(x=DelegateARB_g10k,y=CorrectColScoreSum,fill=DelegateARB_g10k)) +
	geom_violin() + 
	scale_y_log10()
			