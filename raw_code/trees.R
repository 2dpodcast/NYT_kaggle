# The analytic edge
# Kaggle Competition : predicting popularity of blog articles
# Author : Renaud Dufour
# Date : April 2015

# Use of classification trees

library(caret)
library(rpart)
library(rpart.plot)
library(randomForest)
library(e1071)



# A simple CART Model ####

    CARTb = rpart(Popular ~ WordCount + weekend + hour + SectionName + SubsectionName, data = NewsTrain, method = "class", cp = 0.0001)
    prp(CARTb)
    summary(CARTb)
    
    # Predict on training Set
    truth <- factor(NewsTrain$Popular==1, levels = c(FALSE,TRUE))
    pred  = factor(predict(CARTb, type = "prob")[,2]>.5, labels = c(FALSE,TRUE)) # problem : do not give prediction for NA values
    confusionMatrix(pred,truth)
    
    # Predict on the test set
    PredTest = predict(CARTb, newdata = NewsTest, type = "prob")[,2]
    MySubmission = data.frame(UniqueID = NewsTest$UniqueID, Probability1 = PredTest)
    write.csv(MySubmission, "SubmissionCARTcp00001.csv", row.names=FALSE)
    # result is 0.82341 with default values (cp = 0.01)
    # result is 0.88200 with cp = 0.0
    # resulr is 0.87838 with cp = 0.001
    # resulr is 0.88200 with cp = 0.0001


# RF model ####

    set.seed(1)
    Forest = randomForest(Popular ~ WordCount + weekend + hour + SectionName + SubsectionName, data = NewsTrain)
    
    # predict on training set
    truth <- factor(NewsTrain$Popular==1, levels = c(FALSE,TRUE))
    pred  = factor(predict(Forest)>.5, labels = c(FALSE,TRUE)) # problem : do not give prediction for NA values
    confusionMatrix(pred,truth)
    
    # look at important variables
    vu = varUsed(Forest, count=TRUE)
    vusorted = sort(vu, decreasing = FALSE, index.return = TRUE)
    dotchart(vusorted$x, names(Forest$forest$xlevels[vusorted$ix]))
    
    # Predict on the test set
    PredTest = predict(Forest, newdata = NewsTest)
    MySubmission = data.frame(UniqueID = NewsTest$UniqueID, Probability1 = PredTest)
    write.csv(MySubmission, "SubmissionBasicRF.csv", row.names=FALSE)
    # result is 0.92624

# RF model with different mtry

    set.seed(1)
    Forest = randomForest(Popular ~ WordCount + weekend + hour + SectionName + SubsectionName, data = NewsTrain, mtry = 2)
    
    # predict on training set
    truth <- factor(NewsTrain$Popular==1, levels = c(FALSE,TRUE))
    pred  = factor(predict(Forest)>.5, labels = c(FALSE,TRUE)) # problem : do not give prediction for NA values
    confusionMatrix(pred,truth)
    
    # look at important variables
    vu = varUsed(Forest, count=TRUE)
    vusorted = sort(vu, decreasing = FALSE, index.return = TRUE)
    dotchart(vusorted$x, names(Forest$forest$xlevels[vusorted$ix]))
    
    # Predict on the test set
    PredTest = predict(Forest, newdata = NewsTest)
    MySubmission = data.frame(UniqueID = NewsTest$UniqueID, Probability1 = PredTest)
    write.csv(MySubmission, "SubmissionBasicRFmtry2.csv", row.names=FALSE)
    # result is 0.93274 --> top 40 on the leaderboard when submitted

# RF model with topic labels

    set.seed(1)
    t1 <- Sys.time()
    Forest = randomForest(Popular ~ SectionName + SubsectionName + WordCount + hour + weekend + topic, data = NewsTrain, ntree = 2000, mtry = 2)
    t2 <- Sys.time()
    t2 - t1  # about 

    # look at important variables
    vu = varUsed(Forest, count=TRUE)
    vusorted = sort(vu, decreasing = FALSE, index.return = TRUE)
    dotchart(vusorted$x, names(Forest$forest$xlevels[vusorted$ix]))
    
    # Predict on the test set
    PredTest = predict(Forest, newdata = NewsTest)
    MySubmission = data.frame(UniqueID = NewsTest$UniqueID, Probability1 = PredTest)
    MySubmission[ MySubmission$Probability1<0, 2 ] <- 0
    write.csv(MySubmission, "SubmissionLastRFTopic12Regression.csv", row.names=FALSE)
    # result is 0.93631 --> top 53 on the leaderboard when submitted


# RF playground

set.seed(1)
t1 <- Sys.time()
Forest = randomForest(Popular ~ SectionName + SubsectionName + WordCount + hour + weekend + topic, data = NewsTrain, ntree = 2000, mtry = 2)
t2 <- Sys.time()
t2 - t1

# look at important variables
vu = varUsed(Forest, count=TRUE)
vusorted = sort(vu, decreasing = FALSE, index.return = TRUE)
dotchart(vusorted$x, names(Forest$forest$xlevels[vusorted$ix]))

# Predict on the test set
PredTest = predict(Forest, newdata = NewsTest, type = "prob")
MySubmission = data.frame(UniqueID = NewsTest$UniqueID, Probability1 = PredTest[,2])
MySubmission[ MySubmission$Probability1<0, 2 ] <- 0
MySubmission[ MySubmission$Probability1>1, 2 ] <- 1
write.csv(MySubmission, "SubmissionLastRFTopic10Classification.csv", row.names=FALSE)    
