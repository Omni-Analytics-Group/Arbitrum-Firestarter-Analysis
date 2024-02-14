## Load Libraries
library(readr)

## Load Data
catd <- read_csv("Data/GrantSurvey/grant-category.csv")
idd <- read_csv("Data/GrantSurvey/grant-id-project.csv")
revd <- read_csv("Data/GrantSurvey/gap-survey-question-answers.csv")
revd$Title <- idd$Title[match(revd$GrantId,idd$GrantId)]

# number of grants reviewed = just sum up the total number of unique grants with at least 1 review
length(table(revd$GrantId))

# top 10 grants reviewed = sorted list of grants by the number of reviews (I'm guessing this will match the reviews per project .csv
td1 <- sort(tapply(revd$PublicAddress,revd$GrantId,function(x) length(unique(x))),decreasing=TRUE)
res1 <- data.frame(
					GrantId = names(td1),
					Title = idd$Title[match(names(td1),idd$GrantId)],
					CountReviewers = as.numeric(td1)
		)
write_csv(res1,"Data/GrantSurvey/Result1.csv")

# how many profiles were updated......not sure what this is.....so we can't do it.


# number of reviewers = number of unique public addresses
length(table(revd$PublicAddress))



# average number of reviews by qualifying wallets = sorted list of number of reviews per wallet with summary statistics
td2 <- sort(tapply(revd$GrantId,revd$PublicAddress,function(x) length(unique(x))),decreasing=TRUE)
res2 <- data.frame(
					Reviewer = names(td2),
					CountGrantsReviewed = as.numeric(td2)
		)
write_csv(res2,"Data/GrantSurvey/Result2.csv")
summary(res2$CountGrantsReviewed)


# how many reviews by category = summary stats by category with sorted list of number of reviews by category
revd1 <- revd
revd1$FirstCategory <- sapply(revd1$GrantId,function(x,catd) catd$CategoryName[min(which(catd$AttestationID==x))],catd=catd)
revd1$LastCategory <- sapply(revd1$GrantId,function(x,catd) catd$CategoryName[max(which(catd$AttestationID==x))],catd=catd)
revd1$AllCategory <- sapply(revd1$GrantId,function(x,catd) paste0(catd$CategoryName[which(catd$AttestationID==x)],collapse=","),catd=catd)
td3 <- sort(tapply(revd1$GrantId,revd1$FirstCategory,function(x) length(unique(x))),decreasing=TRUE)
td4 <- sort(tapply(revd1$GrantId,revd1$LastCategory,function(x) length(unique(x))),decreasing=TRUE)
td5 <- sort(tapply(revd1$GrantId,revd1$AllCategory,function(x) length(unique(x))),decreasing=TRUE)
res3 <- data.frame(FirstCategory = names(td3),CountGrantsReviewed = as.numeric(td3))
res4 <- data.frame(FirstCategory = names(td4),CountGrantsReviewed = as.numeric(td4))
res5 <- data.frame(FirstCategory = names(td5),CountGrantsReviewed = as.numeric(td5))
write_csv(res3,"Data/GrantSurvey/ByFirstCategory.csv")
write_csv(res4,"Data/GrantSurvey/ByLastCategory.csv")
write_csv(res5,"Data/GrantSurvey/ByAllCategory.csv")