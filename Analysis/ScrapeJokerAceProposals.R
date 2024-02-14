## Load libraries
library(readr)
library(jsonlite)
library(httr)
library(Rmpfr)
library(stringr)
library(lubridate)
library(htm2txt)

## Load Dune Data
data <- read_csv("Data/Dune/DataProposals.csv")
hexTdec <- function(x) str_trim(capture.output(str(mpfr(substr(x,1,66),base=16),give.head=FALSE,digits=100)))
data$urlslug <- sapply(data$data,hexTdec)
data$url <- paste0("https://jokerace.xyz/_next/data/MfaymGS9nmvPwpVNlL4j8/en-US/contest/arbitrumone/",data$contract_address,"/submission/",data$urlslug,".json")
data$block_time <- as_datetime(data$block_time)

## Scrape Porposal Data
parse_prop <- function(x)
{
	data.frame(
				Content = x$pageProps$proposalData$content,
				IsImage = x$pageProps$proposalData$isContentImage,
				Exists = x$pageProps$proposalData$exists
			)
}
prop_data_raw <- list()
prop_data <- list()
for(idx in 1:nrow(data))
{
	prop_data_raw[[idx]] <- fromJSON(data$url[idx])
	prop_data[[idx]] <- parse_prop(prop_data_raw[[idx]])
	message(paste0(idx,"/",nrow(data),":::",length(prop_data_raw[[idx]]$pageProps$proposalData)))
}

## Parse Data
propdf <- do.call(rbind,prop_data)
propfinal <- data.frame(
						BlockTime = data$block_time,
						Contract = data$contract_address,
						Address = data$tx_from,
						Slug = data$urlslug,
						URL = data$url,
						IsImage = propdf$IsImage,
						Content = propdf$Content
				)
propfinal$ContentParsed <- sapply(propfinal$Content,function(x) gsub("\n|•|\"","",htm2txt(x)))
saceRDS(propfinal,"Data/JokerAce/DataProposalsJokerAce.RDS")
write_csv(propfinal,"Data/JokerAce/DataProposalsJokerAce.csv")
