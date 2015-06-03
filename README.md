# predicting which New York Times blog articles will be the most popular

* Kaggle competition 15.071x - The Analytics Edge (13 Apr - 4 May 2015)
* Ranked 252/2923

What makes online news articles popular?
Newspapers and online news aggregators like Google News need to understand which news articles will be the most popular, so that they can prioritize the order in which stories appear. In this competition, you will predict the popularity of a set of New York Times blog articles from the time period September-December 2014.

Many blog articles are published each day, and the New York Times has to decide which articles should be featured. In this competition, the challenge was to develop an analytics model that will help the New York Times understand the features of a blog post that make it popular.

## Content

* `README.md`: this file
* `data.zip`: datasets
* `raw_code/`: R codes for data cleaning, topic modelling and model fitting.
* `final_code.R`: Final code including all steps
* `vis10`: an example of topic modelling output (download and open index.html)

## Data description

The data provided for this competition comes from the New York Times website and is split into two files:

* `NYTimesBlogTrain.csv` is the training data set. It consists of 6532 articles.
* `NYTimesBlogTest.csv` is the testing data set. It consists of 1870 articles.
 
## Variable Description

The **dependent variable** in this problem is the variable *Popular*, which labels if an article had 25 or more comments in its online comment section (equal to 1 if it did, and 0 if it did not). The **independent variables** consist of **8 pieces of article data** available at the time of publication, and a unique identifier:

* *NewsDesk*: the New York Times desk that produced the story (Business, Culture, Foreign, etc.)
* *SectionName*: the section the article appeared in (Opinion, Arts, Technology, etc.)
* *SubsectionName*: the subsection the article appeared in (Education, Small Business, Room for Debate, etc.)
* *Headline: the title of the article
* *Snippet*: a small portion of the article text
* *Abstract*: a summary of the blog article, written by the New York Times
* *WordCount*: the number of words in the article
* *PubDate*: the publication date, in the format "Year-Month-Day Hour:Minute:Second"
* *UniqueID*: a unique identifier for each article

## Model

This is how I built my model (see final_code.R for the R code) :

* First I explore the data (see raw_code/exploratory_analysis.R). From this it appeared clearly that word count was an important predictor, along with *NewsDesk*/*SectionName*/*SubsectionName* variables (for example editorials or opinion articles are much more popular).
* Then I did some manual processing of the variables *NewsDesk*, *SectionName* and *SubsectionName*. These variables contain lot of missing values. After some exploration I decided to use *NewsDesk* and *SubsectionName* to input values in *SectionName*. I then dropped *NewsDesk* because it was redundant information.
* Following the previous step, *SectionName* and *SubsectionName* still contained a lot of missing values. So for many articles it was not possible to link them to a particular topic. For this reason I implemented a topic modelling approach, using the *Headline* and *Abstract* to distribute the articles into 10 topics. (I used tm and lda packages, along with LDAvis and LDAvisData for topic visualization).You can have a look at the generated topics by opening the html in the vis/ folder.
* Finally I fitted a random forest using predictors *SectionName* + *SubsectionName* + *WordCount* + *hour* + *weekend* + *topic*.

With this I achieved a ROI of 0.903 and ranked 252/3000 on the final leaderboard. I was ranking 60 before final score calculation but seems that I somehow over-fitted the data!

