## Load libraries
library(jsonlite)
library(httr)
library(lubridate)
library(ghql)
library(dplyr)

## Initialize Client Connection
con <- GraphqlClient$new("https://hub.snapshot.org/graphql")

## Prepare New Query
qry <- Query$new()

## Add Spaces Qury
qry$query('space_data',
	'query space_data($skip:Int!)
	{
		spaces(orderBy: "id", orderDirection: asc,first:1000,skip:$skip)
		{
			id
			name
			private
			about
			avatar
			website
			twitter
			github
			coingecko
			email
			network
			symbol
			domain
			proposalsCount
			activeProposals
			followersCount
			votesCount
			verified
			flagged
			rank
		}
	}'
)

## Add Proposals Query
qry$query('prop_data',
	'query prop_data($slugid: String!, $timestamp: Int!)
	{
		proposals(orderBy: "created", orderDirection: asc,first:1000,where:{space:$slugid,created_gt:$timestamp}) 
		{
			id
			space{id}
			ipfs
			author
			created
			network
			type
			title
			body
			start
			end
			state
			votes
			choices
			scores_state
			scores
		}
	}'
)

## Add Votes Query
qry$query('vote_data',
	'query vote_data($propid: String!, $timestamp: Int!)
	{
		votes(orderBy: "created", orderDirection: asc,first:1000,where:{proposal:$propid,created_gt:$timestamp}) 
		{
			id
			proposal{id}
			ipfs
			voter
			created
			choice
			vp
		}
	}'
)

########################################################
## Proposals
########################################################
get_spaces <- function()
{
    ## Loop historical
    skip <- 0
    space_data <- data.frame()
    while(TRUE)
    {
        sd_t <- fromJSON(con$exec(qry$queries$space_data,list(skip = skip)))$data$spaces
        if(length(sd_t)==0) break()
        space_data <- bind_rows(space_data,sd_t)
        skip <- skip+1000
        message(paste0("Fetched ",nrow(space_data)," Entries"))
    }
    return(space_data)
}


########################################################
## Proposals
########################################################
get_proposals <- function(slug)
{
    ## Loop historical
    c_timestamp <- 0
    prop_data <- data.frame()
    while(TRUE)
    {
        pd_t <- fromJSON(con$exec(qry$queries$prop_data,list(slugid = slug,timestamp=c_timestamp)))$data$proposals
        if(length(pd_t)==0) break()
        prop_data <- bind_rows(prop_data,pd_t)
        id_last <- tail(pd_t$id,1)
        c_timestamp <- as.numeric(tail(pd_t$created,1))
        message(paste0("Fetched ",nrow(prop_data)," Entries"))
        # Sys.sleep(1)
    }
    prop_data$space_id <- prop_data$space$id
    prop_data$space <- NULL
    return(prop_data)
}
prop_df <- get_proposals("arbitrumfoundation.eth")
prop_df <- prop_df[prop_df$id %in% c("0x14e71f784e880170972572c2696ef53ef437700c637a151b5176a5827fe5b8bc","0x5824d0b51cc435a49f6455ee2715216d6b958637218ed79e3e93c41af6bdef33"),]
prop_df$scores <- sapply(prop_df$scores,function(x) paste(x,collapse="<||>"))
prop_df$choices <- sapply(prop_df$choices,function(x) paste(x,collapse="<||>"))
########################################################
########################################################


########################################################
## Votes
########################################################
get_votes <- function(prop)
{
    ## Loop historical
    c_timestamp <- 0
    vote_data <- data.frame()
    while(TRUE)
    {
        # Sys.sleep(1)
        vd_t <- fromJSON(con$exec(qry$queries$vote_data,list(propid = prop,timestamp=c_timestamp)))$data$votes
        if(length(vd_t)==0) break()
        vote_data <- bind_rows(vote_data,vd_t)
        id_last <- tail(vd_t$id,1)
        c_timestamp <- as.numeric(tail(vd_t$created,1))
        message(paste0("Fetched ",nrow(vote_data)," Entries"))
    }
    vote_data$prop_id <- vote_data$proposal$id
    vote_data$proposal <- NULL
    return(vote_data)
}
vote_l <- list()
idx <- 1
while(TRUE)
{
	qry_res <- tryCatch(
	{
		get_votes(prop_df$id[idx])
	},
	error = function(err) err
	)
	if(inherits(qry_res, "error"))
	{
		message("Votes Error")
		Sys.sleep(2)
		next
	}
	vote_l[[idx]] <- qry_res
	message(paste0("Proposal:",idx,"/",nrow(prop_df)))
	idx <- idx + 1
	if(idx > nrow(prop_df)) break()
}
vote_df <- do.call(rbind,vote_l)
# vote_df$choice <- sapply(vote_df$choice,function(x) paste(x,collapse="<||>"))
saveRDS(vote_df,"Data/Snapshot/Votes.RDS")
saveRDS(prop_df,"Data/Snapshot/Proposals.RDS")


## Split and analysis
vote_df14 <- vote_df[vote_df$prop_id == "0x14e71f784e880170972572c2696ef53ef437700c637a151b5176a5827fe5b8bc",]
vote_df58 <- vote_df[vote_df$prop_id == "0x5824d0b51cc435a49f6455ee2715216d6b958637218ed79e3e93c41af6bdef33",]

## RankingRaw
rankraw14 <- data.frame(
						Choice = 1:10,
						SumRank = apply(do.call(rbind,lapply(vote_df14$choice,function(x) match(1:10,x))),2,sum),
						SumRankAvg = apply(do.call(rbind,lapply(vote_df14$choice,function(x) match(1:10,x))),2,sum)/nrow(vote_df14),
						PctFirst = sapply(1:10,function(x,y) sum(sapply(y,function(z) z[1]==x)),y=vote_df14$choice)/nrow(vote_df14),
						PctLast = sapply(1:10,function(x,y) sum(sapply(y,function(z) z[10]==x)),y=vote_df14$choice)/nrow(vote_df14),
						PctFirstFive = sapply(1:10,function(x,y) sum(sapply(y,function(z) x %in% z[1:5])),y=vote_df14$choice)/nrow(vote_df14),
						VPRankAvg = apply(do.call(rbind,mapply(function(x,y) match(1:10,x)/55*y,vote_df14$choice,vote_df14$vp/sum(vote_df14$vp),SIMPLIFY=FALSE)),2,sum)
					)


rankraw58 <- data.frame(
						Choice = 1:10,
						SumRank = apply(do.call(rbind,lapply(vote_df58$choice,function(x) match(1:10,x))),2,sum),
						SumRankAvg = apply(do.call(rbind,lapply(vote_df58$choice,function(x) match(1:10,x))),2,sum)/nrow(vote_df58),
						PctFirst = sapply(1:10,function(x,y) sum(sapply(y,function(z) z[1]==x)),y=vote_df58$choice)/nrow(vote_df58),
						PctLast = sapply(1:10,function(x,y) sum(sapply(y,function(z) z[10]==x)),y=vote_df58$choice)/nrow(vote_df58),
						PctFirstFive = sapply(1:10,function(x,y) sum(sapply(y,function(z) x %in% z[1:5])),y=vote_df58$choice)/nrow(vote_df58),
						VPRankAvg = apply(do.call(rbind,mapply(function(x,y) match(1:10,x)/55*y,vote_df58$choice,vote_df58$vp/sum(vote_df58$vp),SIMPLIFY=FALSE)),2,sum)
					)

readr::write_csv(rbind(
						cbind(Proposal = "0x14e71f784e880170972572c2696ef53ef437700c637a151b5176a5827fe5b8bc",rankraw14),
						cbind(Proposal = "0x5824d0b51cc435a49f6455ee2715216d6b958637218ed79e3e93c41af6bdef33",rankraw58)
				),"Data/Snapshot/Results.csv")