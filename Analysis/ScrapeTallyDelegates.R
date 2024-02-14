library("ghql")
library("jsonlite")

con <- GraphqlClient$new(
                          url = "https://api.tally.xyz/query",
                          headers = list("Api-Key" = "Tally Key Here")
                        )

#################################################################################
#################################################################################
## Make Query
qry <- Query$new()
qry$query('mydata',
  'query Delegates($input: DelegatesInput!)
  {
    delegates(input: $input)
    {
      nodes
      {
        ... on Delegate
        {
          id
          account
          {
            address
            name
          }
          votesCount
          delegatorsCount
        }
      }
      pageInfo
      {
        firstCursor
        lastCursor
      }
    }
  }'
)
qry$query('mydata2',
  'query AddressHeader($address: Address!)
  {
    address(address: $address)
    {
      participations {
        governance {
          id
        }
        stats {
          delegations {
            total
          }
        }
      }
    }
  }'
)
#################################################################################
#################################################################################


#################################################################################
## Loop Scrape
#################################################################################
variables <- list(
                    "input" = list(
                                    "filters"=list("governanceId" = "eip155:42161:0xf07DeD9dC292157749B6Fd268E37DF6EA38395B9"),
                                    "sort"=list("isDescending" = TRUE,"sortBy" = "VOTES"),
                                    "page"=list("limit" = 20)
                              )
              )

resp <- con$exec(qry$queries$mydata,variables=variables)

delegatesdf <- data.frame(
                            Address = fromJSON(resp)$data$delegates$nodes$account$address,
                            Name = fromJSON(resp)$data$delegates$nodes$account$name,
                            votesCount = fromJSON(resp)$data$delegates$nodes$votesCount,
                            delegatorsCount = fromJSON(resp)$data$delegates$nodes$delegatorsCount
                          )

while(TRUE)
{
  variables <- list(
                    "input" = list(
                                    "filters"=list("governanceId" = "eip155:42161:0xf07DeD9dC292157749B6Fd268E37DF6EA38395B9"),
                                    "sort"=list("isDescending" = TRUE,"sortBy" = "VOTES"),
                                    "page"=list("limit" = 20,"afterCursor" = fromJSON(resp)$data$delegates$pageInfo$lastCursor)
                              )
              )
  resp <- con$exec(qry$queries$mydata,variables=variables)
  delegatesdft <- data.frame(
                            Address = fromJSON(resp)$data$delegates$nodes$account$address,
                            Name = fromJSON(resp)$data$delegates$nodes$account$name,
                            votesCount = fromJSON(resp)$data$delegates$nodes$votesCount,
                            delegatorsCount = fromJSON(resp)$data$delegates$nodes$delegatorsCount
                          )
  delegatesdf <- rbind(delegatesdf,delegatesdft)
  message(paste0(length(unique(delegatesdf$Address)),"  :  ",round(as.numeric(tail(fromJSON(resp)$data$delegates$nodes$votesCount,1))/(10^18)),"  :  ",tail(fromJSON(resp)$data$delegates$nodes$delegatorsCount,1)))
}
delegatesdft <- delegatesdf[(as.numeric(delegatesdf$votesCount)/10^18)>1000,]
saveRDS(delegatesdft,"Data/TallyDelegate/DelegatesTemp.RDS")
#################################################################################
#################################################################################


#################################################################################
## Loop Number of Delegators Scrape
#################################################################################
delegatesdft <- readRDS("Data/TallyDelegate/DelegatesTemp.RDS")
delegatesdft$trustedBy <- delegatesdft$delegatorsCount
for(idx in 1:nrow(delegatesdft))
{
    variables2 <- list("address" = delegatesdft$Address[idx])
    resp2 <- fromJSON(con$exec(qry$queries$mydata2,variables=variables2))$data$address$participations
    delegatesdft$delegatorsCount[idx] <- resp2$stats$delegations$total[resp2$governance$id=="eip155:42161:0xf07DeD9dC292157749B6Fd268E37DF6EA38395B9"]
    message(paste0(idx," : ",delegatesdft$trustedBy[idx]," : ",delegatesdft$delegatorsCount[idx]))
}
saveRDS(delegatesdft,"Data/TallyDelegate/Delegates.RDS")
#################################################################################
#################################################################################



