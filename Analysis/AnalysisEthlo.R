# set options
options(stringsAsFactors = F)         # no automatic data transformation
options("scipen" = 100, "digits" = 4) # suppress math annotation
## Load Libraries
library(readxl)
library(lubridate)
library(knitr) 
library(kableExtra) 
library(DT)
library(tm)
library(topicmodels)
library(reshape2)
library(ggplot2)
library(wordcloud)
library(pals)
library(SnowballC)
library(lda)
library(ldatuning)
library(flextable)
library(stringi)


## Load Data
s1d <- cbind(Season = 1,read_excel("Data/JokerAce/DataProposalsJokerAce.csv/Ethlo/S1/comments-s1.xlsx"))
s2d <- cbind(Season = 2,read_excel("Data/JokerAce/DataProposalsJokerAce.csv/Ethlo/S2/comments-s2.xlsx"))
s3d <- cbind(Season = 3,read_excel("Data/JokerAce/DataProposalsJokerAce.csv/Ethlo/S3/comments-s3.xlsx"))
clean_data <- function(x)
{
  x <- x[nchar(x$Content)>40,]
  x <- x[!(x$Content %in% which(table(x$Content)>1)),]
  data.frame(
              Season = x$Season,
              Id = x$`Comment ID`,
              Topic = x$Topic,
              Target = x$Target,
              User = x$`Posted By Id`,
              Comment = x$Content,
              Time = as_datetime(x$`Posted On`,format="%b %d, %Y %I:%M%p"),
              Reply = x$`Reply Count`,
              Flag = x$`Flag Count`,
              Like = x$`Like Count`
        )
}
alld <- do.call(rbind,lapply(list(s1d,s2d,s3d),clean_data))
readr::write_csv(alld,"Data/JokerAce/DataProposalsJokerAce.csv/Ethlo/CleanData.csv")


########################################################################
## Process Text & Topic Modelling
########################################################################
textdata <- data.frame(Season = alld$Season,text = alld$Comment, doc_id = alld$Id)
corpus <- Corpus(DataframeSource(textdata))

# Preprocessing chain
english_stopwords <- readLines("https://slcladal.github.io/resources/stopwords_en.txt", encoding = "UTF-8")
english_stopwords <- c(english_stopwords,c("arbitrumdao","arbitrum","project","arb","dao"))
processedCorpus <- tm_map(corpus, content_transformer(tolower))
processedCorpus <- tm_map(processedCorpus, removeWords, english_stopwords)
processedCorpus <- tm_map(processedCorpus, removePunctuation, preserve_intra_word_dashes = TRUE)
processedCorpus <- tm_map(processedCorpus, removeNumbers)
processedCorpus <- tm_map(processedCorpus, stemDocument, language = "en")
processedCorpus <- tm_map(processedCorpus, stripWhitespace)

# compute document term matrix with terms >= minimumFrequency
minimumFrequency <- 5
DTM <- DocumentTermMatrix(processedCorpus, control = list(bounds = list(global = c(minimumFrequency, Inf))))
# have a look at the number of documents and terms in the matrix
dim(DTM)

# due to vocabulary pruning, we have empty rows in our DTM
# LDA does not like this. So we remove those docs from the
# DTM and the metadata
sel_idx <- slam::row_sums(DTM) > 0
DTM <- DTM[sel_idx, ]
textdata <- textdata[sel_idx,]

# create models with different number of topics
result <- ldatuning::FindTopicsNumber(
                    DTM,
                    topics = seq(from = 2, to = 20, by = 1),
                    metrics = c("CaoJuan2009",  "Deveaud2014"),
                    method = "Gibbs",
                    control = list(seed = 77),
                    verbose = TRUE
  )
FindTopicsNumber_plot(result)

# number of topics
K <- 3
# set random number generator seed
set.seed(9161)
# compute the LDA model, inference via 1000 iterations of Gibbs sampling
topicModel <- LDA(DTM, K, method="Gibbs", control=list(iter = 5000, verbose = 25))

# have a look a some of the results (posterior distributions)
tmResult <- posterior(topicModel)
theta <- tmResult$topics
textdata$Topic <- apply(theta,1,which.max)
  
terms(topicModel, 50)
########################################################################
########################################################################
