# The analytic edge
# Kaggle Competition : predicting popularity of blog articles
# Author : Renaud Dufour
# Date : April 2015

# Use Topic Modelling

# Requires package LDAvisData (install using devtools::install_github("cpsievert/LDAvisData"))
# See tutorial at : http://cpsievert.github.io/LDAvis/reviews/reviews.html

library(LDAvis)
library(LDAvisData)
library(tm)
library(lda)
stop_words <- stopwords("SMART")

# Read the data ####
# RawTrain <- read.csv("data/NYTimesBlogTrain.csv", stringsAsFactors=FALSE)
# RawTest  <- read.csv("data/NYTimesBlogTest.csv",  stringsAsFactors=FALSE)
# News     <- rbind(RawTrain[,-9], RawTest)

    # Note : 8273 entries have same Snippet and Abstract
    # For the remaining, the Abstract is an extension of the Snippet.
    # --> Snippet variable is useless
    
    # May be usefull to concatenate Abstract with the Headline

Abstract <- paste(News$Headline, News$Abstract)

# pre-processing:
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

# FIT A TOPIC MODEL ####
# We first consider 12 Topics - equal to the number of NewsDesks

# MCMC and model tuning parameters:
K <- 10         # Number of topics
G <- 10000      # Number of iterations
alpha <- 0.02   # Prior document-topic distribution
eta <- 0.02     # Prior topic-term distribution

# Fit the model:
set.seed(1)
t1 <- Sys.time()
fit <- lda.collapsed.gibbs.sampler(documents = documents, K = K, vocab = vocab, 
                                   num.iterations = G, alpha = alpha, 
                                   eta = eta, initial = NULL, burnin = 0,
                                   compute.log.likelihood = TRUE)
t2 <- Sys.time()
t2 - t1  # about 5-10 minutes

# save the model
save(fit , file="lda12.RData")

# get document dominant topic
docTopic <- sapply( fit$assignments, FUN = function(x) ifelse(length(x)==0,NA,as.integer(names(which.max(table(x))))))
docTopic[is.na(docTopic)] <- -1

# Add to dataset
News$topic <- docTopic


# VISUALIZATION USING LDAVIS ####

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


serVis(json, out.dir = 'vis10', open.browser = interactive())
