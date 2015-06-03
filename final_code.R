# The analytic edge
# Kaggle Competition : predicting popularity of blog articles
# Final code
# Author : Renaud Dufour
# Date : April 2015

library(ggplot2)
library(tm)
library(reshape2)

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
# Load the data ####
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

RawTrain <- read.csv("data/NYTimesBlogTrain.csv", stringsAsFactors=FALSE)
RawTest  <- read.csv("data/NYTimesBlogTest.csv",  stringsAsFactors=FALSE)

# Merge before preprocessing dropping the Dependent variable
# We also drop the snippet variable which is useless (same info is contained in abstract)
News     <- rbind(RawTrain[,-9], RawTest)

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
# Preprocessing ####
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Format date information ####

    News$PubDate = strptime(News$PubDate, "%Y-%m-%d %H:%M:%S")
    
    News$weekday = factor(weekdays(News$PubDate))
    News$hour    = News$PubDate$hour
    News$weekend = ifelse((News$weekday == "dimanche") | (News$weekday == "samedi"), 1, 0)
    News <- subset(News, select = -PubDate)

# Process NewsDesk, SectionName and SubsectionName variables ####

    # I did some mannual remapping of SentionName
    # May look a bit messy, plz have a look at the raw code for more details

    # Factorize
    News$NewsDesk       <- factor(News$NewsDesk, exclude = "")
    News$SectionName    <- factor(News$SectionName, exclude = "")
    News$SubsectionName <- factor(News$SubsectionName, exclude = "")

    # TSTYLE
    levels(News$SectionName) <- c(levels(News$SectionName), "TStyleMag")               
    News[ News$NewsDesk %in% "TStyle",]$SectionName <- "TStyleMag"
    # Styles
    levels(News$SectionName) <- c(levels(News$SectionName), "Styles - U.S.")
    levels(News$SectionName) <- c(levels(News$SectionName), "Styles - non - U.S.")
    News[ News$NewsDesk %in% "Styles" & !(News$SectionName %in% "U.S."),]$SectionName <- "Styles - non - U.S."
    News[ News$NewsDesk %in% "Styles" & News$SectionName %in% "U.S.",]$SectionName <- "Styles - U.S."
    # Sport
    News[ News$NewsDesk %in% "Sports",]$SectionName <- "Sports"
    # Science
    levels(News$SectionName) <- c(levels(News$SectionName), "Science")
    News[ News$NewsDesk %in% "Science" | News$SectionName %in% "Health",]$SectionName <- "Science"
    # OpEd
    News[ News$NewsDesk %in% "OpEd",]$SectionName <- "Opinion"
    # National
    News[ News$NewsDesk %in% "National",]$SectionName <- "U.S."
    # Foreign
    levels(News$SectionName) <- c(levels(News$SectionName), "Retrospective")
    News[ News$NewsDesk %in% "Foreign" & is.na(News$SectionName),]$SectionName <- "Retrospective"
    # Culture 
    News[ News$NewsDesk %in% "Culture",]$SectionName <- "Arts"
    # Business
    levels(News$SectionName) <- c(levels(News$SectionName), "Business - Other")
    News[ News$NewsDesk %in% "Business" & is.na(News$SectionName),]$SectionName <- "Business - Other"

    # Drop empty levels
    News$SectionName <- droplevels(News$SectionName)

    # Replace NA with "Unknown"
    levels(News$SectionName) <- c(levels(News$SectionName), "unknown")
    News$SectionName[is.na(News$SectionName)] <- "unknown"
    levels(News$SubsectionName) <- c(levels(News$SubsectionName), "unknown")
    News$SubsectionName[is.na(News$SubsectionName)] <- "unknown"
    levels(News$NewsDesk) <- c(levels(News$NewsDesk), "unknown")
    News$NewsDesk[is.na(News$NewsDesk)] <- "unknown"

    # Drop NewsDesk variable - don't need it anymore
    News <- News[,-1]

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
# Topic modelling ####
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Many missing values in the SectionName / SubsectioNname variables
# Too many - cannot use automatic missing values imputation
# So I came with the idea of doing some topic modelling

library(LDAvis)
library(LDAvisData)
library(tm)
library(lda)
stop_words <- stopwords("SMART")

# Use the Headline and Abstract to build the corpus
Abstract <- paste(News$Headline, News$Abstract)

# process the corpus
Abstract <- gsub("'", "", Abstract)             # remove apostrophes
Abstract <- gsub("[[:punct:]]", " ", Abstract)  # replace punctuation with space
Abstract <- gsub("[[:cntrl:]]", " ", Abstract)  # replace control characters with space
Abstract <- gsub("^[[:space:]]+", "", Abstract) # remove whitespace at beginning of documents
Abstract <- gsub("[[:space:]]+$", "", Abstract) # remove whitespace at end of documents
Abstract <- tolower(Abstract)                   # force to lowercase

# tokenize on space and output as a list:
doc.list <- strsplit(Abstract, "[[:space:]]+")

# compute the table of terms:
term.table <- table(unlist(doc.list))
term.table <- sort(term.table, decreasing = TRUE)

# remove terms that are stop words or occur fewer than 5 times:
# (note: I didn't play with sparsity here)
del <- names(term.table) %in% stop_words | term.table < 5
term.table <- term.table[!del]
vocab <- names(term.table)

# now put the documents into the format required by the lda package:
get.terms <- function(x) {
    index <- match(x, vocab)
    index <- index[!is.na(index)]
    rbind(as.integer(index - 1), as.integer(rep(1, length(index))))
}
documents <- lapply(doc.list, get.terms)

# Compute some statistics related to the data set:
D <- length(documents)                                      # number of documents (2,000)
W <- length(vocab)                                          # number of terms in the vocab (14,568)
doc.length <- sapply(documents, function(x) sum(x[2, ]))    # number of tokens per document [312, 288, 170, 436, 291, ...]
N <- sum(doc.length)                                        # total number of tokens in the data (546,827)
term.frequency <- as.integer(term.table)                    # frequencies of terms in the corpus [8939, 5544, 2411, 2410, 2143, ...]

# Fit a topic model - I used 10 Topics ( = number of NewsDesks)
# We should probably tune some stuff here and play with the number of topic,
# (LDAvisData is pretty cool for this).
# But coming up with topic modelling a few days before deadline = no time for that!

# Tuning parameters:
K     <- 10     # Number of topics
G     <- 10000  # Number of iterations
alpha <- 0.02   # Prior document-topic distribution
eta   <- 0.02   # Prior topic-term distribution

# Fit the model (took about 10-15 minutes)
set.seed(1)
fit <- lda.collapsed.gibbs.sampler(documents = documents, K = K, vocab = vocab, 
                                   num.iterations = G, alpha = alpha, 
                                   eta = eta, initial = NULL, burnin = 0,
                                   compute.log.likelihood = TRUE)

# save / load the topic model
#save(fit , file="lda10.RData")
load("Rdata/lda10.RData")

# get document dominant topic
docTopic <- sapply( fit$assignments, FUN = function(x) ifelse(length(x)==0,NA,as.integer(names(which.max(table(x))))))
docTopic[is.na(docTopic)] <- -1  # if doc has no topic

# Add topic variable to dataset
News$topic <- docTopic

# vizualisation using LDAVis ####

theta <- t(apply(fit$document_sums + alpha, 2, function(x) x/sum(x)))
phi <- t(apply(t(fit$topics) + eta, 2, function(x) x/sum(x)))

data <- list(phi = phi,
             theta = theta,
             doc.length = doc.length,
             vocab = vocab,
             term.frequency = term.frequency)

# create the JSON object to feed the visualization:
json <- createJSON(phi = data$phi, 
                   theta = data$theta, 
                   doc.length = data$doc.length, 
                   vocab = data$vocab, 
                   term.frequency = data$term.frequency)


serVis(json, out.dir = 'vis10'), open.browser = interactive()) # pretty cool no ?

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
# Random Forest ####
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

library(caret)
library(rpart)
library(rpart.plot)
library(randomForest)
library(e1071)

# Rebuild the dataset ####

NewsTrain <- head(News, nrow(RawTrain))
NewsTest  <- tail(News, nrow(RawTest))
NewsTrain$Popular  <- RawTrain$Popular
NewsTrain$Popular  <- as.factor(RawTrain$Popular)

# Fit
set.seed(1)
Forest = randomForest(Popular ~ SectionName + SubsectionName + WordCount + hour + weekend + topic,
                      data = NewsTrain, ntree = 2000, mtry = 2)

# look at important variables
vu = varUsed(Forest, count=TRUE)
vusorted = sort(vu, decreasing = FALSE, index.return = TRUE)
dotchart(vusorted$x, names(Forest$forest$xlevels[vusorted$ix]))

# Predict on the test set
PredTest = predict(Forest, newdata = NewsTest)

# Submit
MySubmission = data.frame(UniqueID = NewsTest$UniqueID, Probability1 = PredTest)
MySubmission[ MySubmission$Probability1<0, 2 ] <- 0
write.csv(MySubmission, "SubmissionLastRFTopic12Regression.csv", row.names=FALSE)

# With this I got a final rank 253/3000 on the final leaderboard