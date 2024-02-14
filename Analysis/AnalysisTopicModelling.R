# set options
options(stringsAsFactors = F)         # no automatic data transformation
options("scipen" = 100, "digits" = 4) # suppress math annotation
# load packages
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
propfinal <- readRDS("Data/JokerAce/DataProposalsJokerAce.RDS")
english_stopwords <- readLines("https://slcladal.github.io/resources/stopwords_en.txt", encoding = "UTF-8")
english_stopwords <- c(english_stopwords,c("arbitrumdao","arbitrum","project","arb","dao"))
contestdf <- do.call(rbind,list(
                                  data.frame(Address = "0xbf47bda4b172daf321148197700cbed04dbe0d58",Name = "Reduce Friction",Slug = "RF4",Topics = 4),
                                  data.frame(Address = "0x5d4e25fa847430bf1974637f5ba8cb09d0b94ec7",Name = "Growth and Innovation",Slug = "GI5",Topics = 5),
                                  data.frame(Address = "0x0d4c05e4bae5ee625aadc35479cc0b140ddf95d4",Name = "Vision",Slug = "V7",Topics = 7),
                                  data.frame(Address = "0x0d4c05e4bae5ee625aadc35479cc0b140ddf95d4",Name = "Vision",Slug = "V10",Topics = 10),
                                  data.frame(Address = "0x5a207fa8e1136303fd5232e200ca30042c45c3b6",Name = "Mission",Slug = "M11",Topics = 11),
                                  data.frame(Address = "0x5a207fa8e1136303fd5232e200ca30042c45c3b6",Name = "Mission",Slug = "M15",Topics = 15)
                            )
              )
sapply(paste0("~/Desktop/jokerace/temp_data/txts/",contestdf$Slug),dir.create)
########################################################################
## Process Text & Topic Modelling
########################################################################
results <- as.data.frame(matrix(1:50))
propout <- propfinal
names(results) <- "TermIdx"
for(idx in 1:nrow(contestdf))
{
  textdata <- propfinal$ContentParsed[propfinal$Contract==contestdf$Address[idx]]
  textdata <- textdata[Encoding(textdata)!="bytes"]
  textdata <- textdata[nchar(textdata)>40]
  textdata <- textdata[!(textdata %in% names(which(table(textdata)>1)))]
  textdata <- data.frame(Contest = contestdf$Name[idx],doc_id = 1:length(textdata),text = textdata)
  corpus <- Corpus(DataframeSource(textdata))

  # Preprocessing chain
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
  # result <- ldatuning::FindTopicsNumber(
  #   DTM,
  #   topics = seq(from = 2, to = 20, by = 1),
  #   metrics = c("CaoJuan2009",  "Deveaud2014"),
  #   method = "Gibbs",
  #   control = list(seed = 77),
  #   verbose = TRUE
  # )
  # FindTopicsNumber_plot(result)

  # number of topics
  K <- contestdf$Topics[idx]
  # set random number generator seed
  set.seed(9161)
  # compute the LDA model, inference via 1000 iterations of Gibbs sampling
  topicModel <- LDA(DTM, K, method="Gibbs", control=list(iter = 5000, verbose = 25))

  # have a look a some of the results (posterior distributions)
  tmResult <- posterior(topicModel)
  theta <- tmResult$topics
  textdata$Topic <- apply(theta,1,which.max)
  
  propout <- cbind(propout,NA)
  names(propout)[ncol(propout)] <- contestdf$Slug[idx]
  propout[,contestdf$Slug[idx]][match(textdata$text,propout$ContentParsed)] <- textdata$Topic
  for(tidx in unique(textdata$Topic))
  {
    tempd <- textdata[textdata$Topic == tidx,]
    writeLines(paste0(paste0("Submission : ",1:nrow(tempd),"\n",tempd$text),collapse="\n\n\n"),paste0("~/Desktop/jokerace/temp_data/txts/",contestdf$Slug[idx],"/Topic-",tidx,".txt"))  
  }
  result_t <- as.data.frame(terms(topicModel, 50))
  names(result_t) <- paste0(contestdf$Slug[idx],"_Topic_",1:contestdf$Topics[idx])
  results <- cbind(results,result_t)
  message(idx)
}  
########################################################################
########################################################################

readr::write_csv(results,"~/Desktop/TopicAnalysis/TopicTerms.csv")
readr::write_csv(propout,"~/Desktop/TopicAnalysis/PropTopics.csv")
