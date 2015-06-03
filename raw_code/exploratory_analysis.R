# The analytic edge
# Kaggle Competition : predicting popularity of blog articles
# Author : Renaud Dufour
# Date : April 2015

# The following script aims at exploring the dataset

library(ggplot2)

# Load ####

    RawTrain <- read.csv("data/NYTimesBlogTrain.csv", stringsAsFactors=FALSE)
    RawTest  <- read.csv("data/NYTimesBlogTest.csv",  stringsAsFactors=FALSE)
    
    News      <- rbind(RawTrain[,-9], RawTest)

# Format date information ####

    News$PubDate = strptime(News$PubDate, "%Y-%m-%d %H:%M:%S")
    
    News$weekday = factor(weekdays(News$PubDate))
    News$hour    = News$PubDate$hour
    News$weekend = ifelse((News$weekday == "dimanche") | (News$weekday == "samedi"), 1, 0)
    News <- subset(News, select = -PubDate)

# Look at missing values in the first 3 variables :

    # NewsDesk - 12 different values - almost 30% missing values
    unique(News$NewsDesk)         # 2048 undefined = 25%
    unique(NewsTest$NewsDesk)     #  562 undefined = 30%   # no 'national' or 'sport' in the test set 
    unique(NewsTrain$NewsDesk)    # 1846 undefined = 28%
    
    # NewsDesk - 15 different sections - 
    unique(News$SectionName)      # 2899 undefined = 35%
    unique(NewsTest$SectionName)  #  599 undefined = 32%   # no 'style' or 'sport' in the test set 
    unique(NewsTrain$SectionName) # 2300 undefined = 35%
    
    # NewsDesk - 8 different subsections - 
    # Note : 'fashion and style' or 'politics' together count only 4 entries in the training set
    unique(News$SubsectionName)      # 6176 undefined = 73%
    unique(NewsTest$SubsectionName)  # 1350 undefined = 72%   # no 'fashion & style' or 'politics' in the test set 
    unique(NewsTrain$SubsectionName) # 4826 undefined = 74%

    # --> 1626 entries in total have missing values for those 3 variables == 20% of the dataset !
    
    # There are 1093 popular articles in the train set
    # 115 popular articles have 3 NA values 3 NA values
    # --> about 10% of popular articles have only NA values for {NewsdDesk, SectioName, SubsectionName}

# fraction of popular articles ####

    table(NewsTrain$Popular)
    1093/(1093+5439)  # 16.7% of the articles are popular
    5439/(1093+5439)  # baseline accuracy on test set: 83.26%

# NewsDesk variable ####

    nonpop <- aggregate(Popular ~ NewsDesk, data = NewsTrain, function(x) sum(1-x))
    names(nonpop) <- c("NewsDesk","count")
    
    pop <- aggregate(Popular ~ NewsDesk, data = NewsTrain, FUN =  sum)
    names(pop) <- c("NewsDesk","count")
    
    z <- merge(nonpop,pop, by = "NewsDesk")
    names(z) <- c("NewsDesk","non-popular","popular")
    z <- melt(z, id.vars = "NewsDesk", measure.vars = c("non-popular","popular"))
    
    g <- ggplot(z, aes(x = reorder(NewsDesk, -value), y = value, fill = variable)) +
        geom_bar(stat = "identity") +
        ggtitle("Number of article per NewsDesk") + xlab("NewsDesk") + ylab("Number of article")
    g

# SectionName variable ####

    nonpop <- aggregate(Popular ~ SectionName, data = NewsTrain, function(x) sum(1-x))
    names(nonpop) <- c("SectionName","count")
    
    pop <- aggregate(Popular ~ SectionName, data = NewsTrain, FUN =  sum)
    names(pop) <- c("SectionName","count")
    
    z <- merge(nonpop,pop, by = "SectionName")
    names(z) <- c("SectionName","non-popular","popular")
    z <- melt(z, id.vars = "SectionName", measure.vars = c("non-popular","popular"))
    
    g <- ggplot(z, aes(x = reorder(SectionName, -value), y = value, fill = variable)) +
        geom_bar(stat = "identity") +
        ggtitle("Number of article per SectionName") + xlab("SectionName") + ylab("Number of article")
    g

# SubsectionName ####

    nonpop <- aggregate(Popular ~ SubsectionName, data = NewsTrain, function(x) sum(1-x))
    names(nonpop) <- c("SubsectionName","count")
    
    pop <- aggregate(Popular ~ SubsectionName, data = NewsTrain, FUN =  sum)
    names(pop) <- c("SubsectionName","count")
    
    z <- merge(nonpop,pop, by = "SubsectionName")
    names(z) <- c("SubsectionName","non-popular","popular")
    z <- melt(z, id.vars = "SubsectionName", measure.vars = c("non-popular","popular"))
    
    g <- ggplot(z, aes(x = reorder(SubsectionName, -value), y = value, fill = variable)) +
        geom_bar(stat = "identity") +
        ggtitle("Number of article per SubsectionName") + xlab("SubsectionName") + ylab("Number of article")
    g

# relationship between NewsDesk and SectionName and subSectionName
table(NewsTrain$NewsDesk,NewsTrain$SectionName)
table(NewsTrain$SubsectionName,NewsTrain$SectionName)

# WordCount ####

    hist(NewsAll$WordCount, 100)
    
    k = 15
    qs <- quantile(NewsTrain$WordCount, seq(0, 1, length.out = k+1))
    NewsTrain$WordCountBin <- cut(NewsTrain$WordCount, round(qs), include.lowest = TRUE)
    
    z <- aggregate(Popular ~ WordCountBin, data = NewsTrain, FUN = mean)
    names(nonpop) <- c("WordCount","Popular")
    
    g <- ggplot(z, aes(x = WordCountBin, y = Popular)) + geom_point() +
        ggtitle("Popularity v.s. words count") + xlab("Number od words") + ylab("% of popular articles")
    g
