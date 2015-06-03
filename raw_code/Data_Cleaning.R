# The analytic edge
# Kaggle Competition : predicting popularity of blog articles
# Author : Renaud Dufour
# Date : April 2015

# The following script aims at exploring the dataset

library(ggplot2)
library(tm)
library(reshape2)

# Variables in the datasets :

    # NewsDesk = the New York Times desk that produced the story (Business, Culture, Foreign, etc.)
    # SectionName = the section the article appeared in (Opinion, Arts, Technology, etc.)
    # SubsectionName = the subsection the article appeared in (Education, Small Business, Room for Debate, etc.)
    # Headline = the title of the article
    # Snippet = a small portion of the article text
    # Abstract = a summary of the blog article, written by the New York Times
    # WordCount = the number of words in the article
    # PubDate = the publication date, in the format "Year-Month-Day Hour:Minute:Second"
    # UniqueID = a unique identifier for each article

    # Popular : did article have 25 or more comments in its online comment section (equal to 1 if it did, and 0 if it did not)

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

# Process NewsDesk, SectionName and SubsectionName variables ####
# Did some exploration and mannual cleaning (took a while!)

    # Convert to factor - coercing missing values to <NA>
    News$NewsDesk       <- factor(News$NewsDesk, exclude = "")
    News$SectionName    <- factor(News$SectionName, exclude = "")
    News$SubsectionName <- factor(News$SubsectionName, exclude = "")

    # Handle missing values by remapping
    # --> FILL IN THE MISSING VALUES IN 'SECTIONNAME' FROM 'NEWSDESK' MANUALLY
    # --> REPLACE MISSING VALUES IN 'SUBSECTION' WITH 'none'
    # --> DROP THE NEWSDESK VARIABLE

    # TSTYLE --> no associated section or subsection / Might be related to NYT Style Magazine
                 # 9 popular articles in this section BUT Associated with high word count ! (excepted 1 or 2)
                 # So not sure the TStyle variable  is very usefull.
                 levels(News$SectionName) <- c(levels(News$SectionName), "TStyleMag")               
                 News[ News$NewsDesk %in% "TStyle",]$SectionName <- "TStyleMag"
                 # News[ News$NewsDesk %in% "TStyle", 1:3 ]  # check -- we filled 829 entries

    # Travel --> same Information given in SectionName
    #        --> no corresponding NA

    # Styles --> correction massively to SectionName U.S. (238) or Style (2) or Health (1) + 132 NA values
                # News[ News$NewsDesk %in% "Styles", 1:3 ]
                # NewsTrain[ NewsTrain$NewsDesk %in% "Styles" & NewsTrain$SectionName %in% "Style", 7:12 ]
                # NewsTrain[ NewsTrain$NewsDesk %in% "Styles" & NewsTrain$SectionName %in% "Health", 7:12 ]

                # * Styles + Style is not popular (2 entries)
                # * Styles + Health is not popular (1 entry)
                # * Style + U.S. is pretty popular (56% of popular articles there !)
                # * Styles + NA is not popular < 1%

                # Reverse Mapping
                # SectionName Style remaps only to NewsDesk Styles
                # SectionName Health remaps essentially to Science, the latter are very popular (62%)
                
                # --> Split between "Style - US" and "Styles - not US"
                levels(News$SectionName) <- c(levels(News$SectionName), "Styles - U.S.")
                levels(News$SectionName) <- c(levels(News$SectionName), "Styles - non - U.S.")
                
                News[ News$NewsDesk %in% "Styles" & !(News$SectionName %in% "U.S."),]$SectionName <- "Styles - non - U.S."
                News[ News$NewsDesk %in% "Styles" & News$SectionName %in% "U.S.",]$SectionName <- "Styles - U.S."

    # Sports --> Only 2 entries, not popular
    
                News[ News$NewsDesk %in% "Sports",]$SectionName <- "Sports"

    # Science --> mainly maps to Health (247/251)
    
                # Science + Health is rather Popular (62%)
                # Science + not Health is also popular (100%)
                # * Health maps back to Science

                # I create a more general section "Science"
                levels(News$SectionName) <- c(levels(News$SectionName), "Science")
                News[ News$NewsDesk %in% "Science" | News$SectionName %in% "Health",]$SectionName <- "Science"

    # OpEd --> corresponds to Opinion, maybe usefull to input missing values as opinion is an important predictor
    
                News[ News$NewsDesk %in% "OpEd",]$SectionName <- "Opinion"

    # National --> only 4 entries
    
                # 2 maps to U.S. / politics
                # 2 map to NA / NA
                News[ News$NewsDesk %in% "National",]$SectionName <- "U.S."

    # Metro --> corresponds to NY Region
    
                # good mapping with N.Y. Region, nothing to do

    # Magazine --> corresponds to magazine / useless
    
                # good mapping with magazine, nothing to do

    # Foreign --> corresponds to world or nothing / useless since foreign = world (same information)
    
                # Maps to World -- 1.5% popular
                # Or NA == Retrospective articles -- 0 popular

                # Remap but unlikely to be usefull
                levels(News$SectionName) <- c(levels(News$SectionName), "Retrospective")
                News[ News$NewsDesk %in% "Foreign" & is.na(News$SectionName),]$SectionName <- "Retrospective"

    # Culture --> corresponds to Art (838/909)
    
                # Contrast ?
                # * Culture + Art --> 7% (corresponds to the overall popularity of Art)
                # Culture + NA --> 0% (CAREFULL - THERE IS ONLY 1 OBSERVATION THIS IS NOT RELEVANT)

                #levels(News$SectionName) <- c(levels(News$SectionName), "Culture - Arts")
                #levels(News$SectionName) <- c(levels(News$SectionName), "Culture - Others")
                
                #News[ News$NewsDesk %in% "Culture" & !(News$SectionName %in% "Arts"),]$SectionName <- "Culture - Others"
                #News[ News$SectionName %in% "Arts",]$SectionName <- "Culture - Arts"

                # PUT EVERYTHING IN ART

                News[ News$NewsDesk %in% "Culture",]$SectionName <- "Arts"

    # Business --> ONLY NewsDesk containing an additional information
    #          --> corresponds to either 'Business Day', or 'Technology', or 'Crosswords/Games'

                # We keep the subsection
                # 6 entries have NewsDesk Business but no SectionName
                levels(News$SectionName) <- c(levels(News$SectionName), "Business - Other")
                News[ News$NewsDesk %in% "Business" & is.na(News$SectionName),]$SectionName <- "Business - Other"
    
    # SECTIONNAMES :
    
    # [1] "Arts"             "Business Day"     "Crosswords/Games"
    # [4] "Health"           "Magazine"         "Multimedia"      
    # [7] "N.Y. / Region"    "Open"             "Opinion"         
    # [10] "Sports"           "Style"            "Technology"      
    # [13] "Travel"           "U.S."             "World"   

    # SECTIONAME MAPPING :
    
    # opinion           --> NewsDesk OpEd
    # art               --> culture
    # Business day      --> don't know
    # Crosswords/Games  --> business
    # Health            --> science
    # Magazine          --> magazine
    # Multimedia        --> don't know
    # N.Y. / Region     --> Metro
    # Open              --> don't know (only 5 occurences)
    # Opinion           --> OpEd
    # Sports            --> Sports
    # Style             --> Style
    # Technology        --> Business
    # Travel            --> Travel
    # U.S. + Education  --> NA
    # U.S. + NA         --> Styles
    # World + NA        --> Foreign
    # World + Asia Pacific --> NA
    
    # Drop empty levels

    News$SectionName <- droplevels(News$SectionName)


    # Replace NA with "Unknown"
    levels(News$SectionName) <- c(levels(News$SectionName), "unknown")
    News$SectionName[is.na(News$SectionName)] <- "unknown"

    levels(News$SubsectionName) <- c(levels(News$SubsectionName), "unknown")
    News$SubsectionName[is.na(News$SubsectionName)] <- "unknown"

    levels(News$NewsDesk) <- c(levels(News$NewsDesk), "unknown")
    News$NewsDesk[is.na(News$NewsDesk)] <- "unknown"
    

    # Remove NewsDesk variable
    News <- News[,-1]

# Remove Snippet variable

    News <- News[,-4]

# Create new features based on Headline ####

    # Is there a ! or ?
    punct <- rep(0, times = nrow(News))
    punct[grep("?", News$Headline, fixed = TRUE)] <- 1
    punct[grep("!", News$Headline, fixed = TRUE)] <- 1
    
    News$punct <- punct

# Recreate Test and Training sets ####

     NewsTrain <- head(News, nrow(RawTrain))
     NewsTest  <- tail(News, nrow(RawTest))
    NewsTrain$Popular  <- RawTrain$Popular
     NewsTrain$Popular  <- as.factor(RawTrain$Popular)

# Process the Headline variable ####

    CorpusHeadline = Corpus(VectorSource(c(NewsTrain$Headline, NewsTest$Headline)))
    
    CorpusHeadline = tm_map(CorpusHeadline, tolower)
    CorpusHeadline = tm_map(CorpusHeadline, PlainTextDocument)
    CorpusHeadline = tm_map(CorpusHeadline, removePunctuation)
    CorpusHeadline = tm_map(CorpusHeadline, removeWords, stopwords("english"))
    CorpusHeadline = tm_map(CorpusHeadline, stemDocument)
    
    dtm    <- DocumentTermMatrix(CorpusHeadline)
    sparse <- removeSparseTerms(dtm, 0.99)
    HeadlineWords <- as.data.frame(as.matrix(sparse))
    colnames(HeadlineWords) = make.names(colnames(HeadlineWords))
    
    HeadlineWordsTrain <- head(HeadlineWords, nrow(NewsTrain))
    HeadlineWordsTest  <- tail(HeadlineWords, nrow(NewsTest))

# Process the Abstract variable ####

    CorpusAbstract = Corpus(VectorSource(c(NewsTrain$Abstract, NewsTest$Abstract)))
    
    CorpusAbstract = tm_map(CorpusAbstract, tolower)
    CorpusAbstract = tm_map(CorpusAbstract, PlainTextDocument)
    CorpusAbstract = tm_map(CorpusAbstract, removePunctuation)
    CorpusAbstract = tm_map(CorpusAbstract, removeWords, stopwords("english"))
    CorpusAbstract = tm_map(CorpusAbstract, stemDocument)
    
    dtm    <- DocumentTermMatrix(CorpusAbstract)
    sparse <- removeSparseTerms(dtm, 0.99)
    AbstractWords <- as.data.frame(as.matrix(sparse))
    colnames(AbstractWords) = make.names(colnames(AbstractWords))
    
    AbstractWordsTrain <- head(AbstractWords, nrow(NewsTrain))
    AbstractWordsTest  <- tail(AbstractWords, nrow(NewsTest))



    


