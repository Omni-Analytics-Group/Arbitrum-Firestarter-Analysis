## Load Libraries
library(readxl)

## Read in data
allsheets <- excel_sheets("Data/ThankARBParticipation/Thank ARB Season 0 (#Gov Month) ThriveCoin Claim Contract Rewards List.xlsx")
# datasheets <- allsheets[c(2:7,9,11,14:28)]
datasheets <- allsheets[c(2:28)]

## Read Sheet
read_sheet <- function(sheetname)
{
	tdata <- read_excel("Data/ThankARBParticipation/Thank ARB Season 0 (#Gov Month) ThriveCoin Claim Contract Rewards List.xlsx", sheet = sheetname,col_names=FALSE)
	adds <- tdata[,2,drop=TRUE]
	adds[grepl("^0x",adds)]
}
read_sheetname <- function(sheetname)
{
	tdata <- read_excel("Data/ThankARBParticipation/Thank ARB Season 0 (#Gov Month) ThriveCoin Claim Contract Rewards List.xlsx", sheet = sheetname,col_names=FALSE)
	tdata[1,1,drop=TRUE]
}
datal <- lapply(datasheets,read_sheet)
# names(datal) <- sapply(datasheets,read_sheetname)
names(datal) <- datasheets
alladds <- unique(tolower(unlist(datal)))

## Make Matrix
datamat <- cbind(Address=alladds,as.data.frame(sapply(datal,function(x,y) y %in% tolower(x),y=alladds)))
saveRDS(datamat,"Data/ThankARBParticipation/ParticipationMatrix.RDS")