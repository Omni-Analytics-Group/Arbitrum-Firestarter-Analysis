## Load libraries
library(readr)
library(Rmpfr)
library(stringr)
library(lubridate)

## Read in Data
propfinal <- readRDS("Data/JokerAce/DataProposalsJokerAce.csv")
data <- read_csv("Data/Dune/DataVotes.csv")

## Parsing Functions
get_propid <- function(x) str_trim(capture.output(str(mpfr(substr(x,1,66),base=16),give.head=FALSE,digits=100)))
get_support <- function(x) str_trim(capture.output(str(mpfr(substr(x,67,130),base=16),give.head=FALSE,digits=100)))
get_votes <- function(x) str_trim(capture.output(str(mpfr(substr(x,131,194),base=16),give.head=FALSE,digits=100)))

## Slug
data$Slug <- sapply(data$data,get_propid)
data$Support <- sapply(data$data,get_support)
data$Votes <- sapply(data$data,get_votes)

## Votes Data
data$block_time <- as_datetime(data$block_time)
votesfinal <- data.frame(
							BlockTime = data$block_time,
							Contract = data$contract_address,
							Address = data$tx_from,
							Slug = data$Slug,
							Support = data$Support,
							Votes = as.numeric(data$Votes)
				)
write_csv(votesfinal,"~/Desktop/TopicAnalysis/DataVotesJokerAce.csv")


## Append into Topic Comment Data
count_votes <- function(x) (sum(x$Votes[x$Support==0]) - sum(x$Votes[x$Support==1]))/10^18
count_voters <- function(x) length(unique(x$Address))
count_psupport <- function(x) length(unique(x$Address[x$Support==0]))
count_nsupport <- function(x) length(unique(x$Address[x$Support==1]))
propout <- read_csv("~/Desktop/TopicAnalysis/PropTopics.csv",col_types = list(col_datetime(),col_character(),col_character(),col_character(),col_character()))
vspl <- split(votesfinal,paste0(votesfinal$Contract,votesfinal$Slug))
vcnts <- data.frame(
						idx = names(vspl),
						Votes = sapply(vspl,count_votes),
						NumVoters = sapply(vspl,count_voters),
						SupportP = sapply(vspl,count_psupport),
						SupportN = sapply(vspl,count_nsupport)
			)
propout2 <- cbind(propout,vcnts[match(paste0(propout$Contract,propout$Slug),vcnts$idx),-1])
row.names(propout2) <- NULL
readr::write_csv(propout2,"~/Desktop/TopicAnalysis/PropTopicsVotes.csv")