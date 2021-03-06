# ======================
# Initialisation
# ======================
#install.packages("insuranceData")
#install.packages("lme4")

library(MASS)
library(insuranceData)
data("ClaimsLong")
claims_df <- ClaimsLong

# ==========================
# Problem statement
# ==========================
# Insurance underwriting - dyanmic prediction
# In insurance domain, the insurance pricing or claim predictions can't be static
# These need to update based on prior information available.

# Build a model that predicts number of claims of an policy given some history.

# ==========================
# Data Analysis and Cleaning
# ==========================
# Summary
str(claims_df)

# ANALYSIS - policyID
unique(claims_df$policyID)
sum(is.na(claims_df$policyID)) # No NAs

# ANALYSIS - agecat
# as per data definition the value ranges from 1-6
unique(claims_df$agecat)
# we see that there a category code - 10 which is beyond range 1-6
# let's look at  the count of these
nrow(claims_df[which(claims_df$agecat==10),])
# 27345 rows found which is 22.78% of the data
# we will discard this 22.78% of the data because we have no mention of 
# age category code in data definition
claims_df <- claims_df[-which(claims_df$agecat==10), ]

# ANALYSIS - valuecat
unique(claims_df$valuecat)
# as per data definition the value ranges from 1-6
# but documentation says, 1 has been recorded as 9, so we will replace 9 with 1 to maintain consistency
claims_df[which(claims_df$valuecat==9), ]$valuecat <- 1

# ANALYSIS - period
unique(claims_df$period)

# ANALYSIS - numclaims
unique(claims_df$numclaims)

# ANALYSIS - claim
unique(claims_df$claim)

# ======================
# Understanding data 
# ======================
# > claims_df[which(claims_df$policyID==4),]
# policyID agecat valuecat period numclaims claim
#     4     35    37500      1         0     0
#     4     35    37500      2         2     1
#     4     35    37500      3         0     0
# > claims_df[which(claims_df$policyID==7),]
# policyID agecat valuecat period numclaims claim
#      7     55    25000      1         1     1
#      7     55    25000      2         0     0
#      7     55    25000      3         0     0
# > claims_df[which(claims_df$policyID==19),]
# policyID agecat valuecat period numclaims claim
#     19     35    25000      1         1     1
#     19     35    25000      2         0     0
#     19     35    25000      3         1     1

# We have multuiple observations per policy for a period of 3 (units unknown from data).
# Each policy is different, the difference in policy comes from difference in behaviour
# of policy holders. No two policy holders are the same.
# Some policy holders make claims often while some dont make any claims at all.
# This individual effect can be of two kinds:
# - Fixed effect
# - Random effect
# Fixed effects are produced by factors and levels choosen for study, which are of interest to us.
# Random effects are produced by factors whose levels are randomly selected from number of available options.
# In our data set we have 3 variables that contribute to the fixed effect
# - agecat (age levels selected are of interest for study and not random)
# - valuecat (value levels selected are of interest for study and not random)
# - period (period levels selected are of interest for study and not random)
# And we have one random effect
# - policyID

# Let us try to understand why we should consider these effects.
# If you were to model this problem as logistic regression, your linear predictor would look something like
# y = beta0 + beta1*agecat + beta2*valuecat + beta3*period
# Now since each policy is different, having the same intercept (or) beta0 creates a bias
# When we consider individual effect, we would get a different intercept (or) beta0 for every group,
# but co-efficients of explanantory variables would reamin the same.

# What does this mean? This means that even though the effect of explanatory variables remain the same
# The individual effect is captured in the intercept.


# ======================
# Modeling approach
# ======================
# Usually the data is distributed normally. Example house prices.
# But insurance data doesn't necessarily follow normal distribution because 
# there are individual effect which causes the distribution of the insurance data 
# to deviate from the normal distribution.
# This individual effect can be fixed or random effect as described above.
# Hence insurance data can't be modelled as a regular regression problem.

# Generalised Linear Model (GLM) are very popular solution as they allow  
# response variable to be modelled as non-normal distribution.
# GLM makes an assumption that the the response variable is distributed with
# exponential distribution such as 
# - Binomial
# - Multinomial
# - Poisson etc
 
# Components of GLM
# 1) Random component: distribution of the response variable, in our case - numclaims
# 2) Systematic component: linear predictor
# 3) Link function: connects systematic component with parameter of the reponse distribution.
# The link function transforms the random component distribution to systematic component.
# Parameter of binomial distribution is p (probability of an desired event occuring)
# Parameter of poisson distribution is lambda (mean of the distribution)

# GLM models fixed effects. For modeling fixed effects dummy variables for fixed effects are added.
# To model fixed and random effects we need mixed models. 
# MASS package contains a method called glmmPQL, which can be used to model explanatory variables
# along with fixed and random effects.
# NOTE: we don't need to add dummy variables for random effects because they are not correlated
# to the explanatory variables hence they will not create bias in explanatory variables.
# But we need to account for them in order to correct serial correlation.

# ======================
# Data Preparation
# ======================
# As we need to model the effect of individuality 
# Creating dummy variables for the fixed effects 
# - agecat
# - valuecat
# - period 

claims_df$agecat <- factor(claims_df$agecat)
claims_df$valuecat <- factor(claims_df$valuecat)
claims_df$period <- factor(claims_df$period)

agecat_dummy <- data.frame(model.matrix(~agecat, data=claims_df))[,-1]
valuecat_dummy <- data.frame(model.matrix(~valuecat, data=claims_df))[,-1]
period_dummy <- data.frame(model.matrix(~period, data=claims_df))[,-1]

claims_df_dummy <- cbind(claims_df, agecat_dummy)
claims_df_dummy <- cbind(claims_df_dummy, valuecat_dummy )
claims_df_dummy <- cbind(claims_df_dummy, period_dummy )

claims_df_processed <- claims_df_dummy[,-c(2,3,4,5)]

# Divide the data in training and test set
# Keeping out 30% of the data to test model on unseen data 

set.seed(100)
indices <- sample(1:nrow(claims_df_processed), 0.90*nrow(claims_df_processed))
training_data <- claims_df_processed[indices,]
test_data <- claims_df_processed[-indices,]

# ======================
# Modeling
# ======================
m0 <- glmmPQL(claim~agecat2+agecat4+agecat5+agecat6+valuecat2+valuecat3+valuecat4+valuecat5+valuecat6+period2+period3, random = ~1|policyID, family=binomial, data=training_data)
summary(m0)

# Comparing accuracy for training data
training.results <- predict(m0,newdata=subset(training_data,select=c(1,3 , 4 , 5 , 6  ,7 , 8 , 9, 10 ,11, 12 ,13)),type='response')
training.results <- ifelse(training.results > 0.5,1,0)
training.error <- mean(training.results != training_data$claim)
print(paste('Accuracy',1-training.error))
# Accuracy on training data : 92% 

# Comparing accuracy for test data 
test.results <- data.frame(res = predict(m0,newdata=subset(test_data,select=c(1,3 , 4 , 5 , 6  ,7 , 8 , 9, 10 ,11, 12 ,13)),type='response'))
test.results$res <- ifelse(test.results$res > 0.5,1,0)
test.error <- mean(test.results[!is.na(test.results$res),] != test_data[!is.na(test.results$res),])
print(paste('Accuracy',1-test.error))
# Accuracy on test data: 73%


# ======================
# Model Analysis
# ======================
#       (Intercept)    agecat2    agecat4   agecat5    agecat6 valuecat2 valuecat3  valuecat4  valuecat5 valuecat6
# 39991  -3.3252734 -0.2232318 -0.2771932 -0.464657 -0.4248755 0.2510378 0.1345615 -0.5246707 -0.6351367 -1.220205
# 39993  -3.6194876 -0.2232318 -0.2771932 -0.464657 -0.4248755 0.2510378 0.1345615 -0.5246707 -0.6351367 -1.220205
# 39995  -0.6365598 -0.2232318 -0.2771932 -0.464657 -0.4248755 0.2510378 0.1345615 -0.5246707 -0.6351367 -1.220205
# 39996  -3.6194876 -0.2232318 -0.2771932 -0.464657 -0.4248755 0.2510378 0.1345615 -0.5246707 -0.6351367 -1.220205
# 39998  -3.6194876 -0.2232318 -0.2771932 -0.464657 -0.4248755 0.2510378 0.1345615 -0.5246707 -0.6351367 -1.220205
# 39999  -0.7691254 -0.2232318 -0.2771932 -0.464657 -0.4248755 0.2510378 0.1345615 -0.5246707 -0.6351367 -1.220205
#         period2   period3
# 39991 0.1260747 0.3165939
# 39993 0.1260747 0.3165939
# 39995 0.1260747 0.3165939
# 39996 0.1260747 0.3165939
# 39998 0.1260747 0.3165939
# 39999 0.1260747 0.3165939

# As it can be seen from the model coeffs, we have different intercept per random effect
# i.e policyID. The different intercept is the uniqueness of the policy being modelled.
# When we have a new policy we don't have it's understanding and hence we can make prediction
# using intercept=0 for the first time. But as we collect data we develop an understanding about the
# policy which is reflected in the intercept.

# Summary
summary(m0)

# Linear mixed-effects model fit by maximum likelihood
# Data: training_data 
# AIC BIC logLik
# NA  NA     NA
# 
# Random effects:
#   Formula: ~1 | policyID
# (Intercept)  Residual
# StdDev:    2.181642 0.5770924
# 
# Variance function:
#   Structure: fixed weights
# Formula: ~invwt 
# Fixed effects: claim ~ agecat2 + agecat4 + agecat5 + agecat6 + valuecat2 + valuecat3 +      valuecat4 + valuecat5 + valuecat6 + period2 + period3 
# Value Std.Error    DF   t-value p-value
# (Intercept) -2.6256421 0.0490533 52532 -53.52632  0.0000
# agecat2     -0.2232318 0.0570602 30845  -3.91222  0.0001
# agecat4     -0.2771932 0.0554405 30845  -4.99983  0.0000
# agecat5     -0.4646570 0.0598156 30845  -7.76815  0.0000
# agecat6     -0.4248755 0.0664157 30845  -6.39721  0.0000
# valuecat2    0.2510378 0.0437324 30845   5.74032  0.0000
# valuecat3    0.1345615 0.1232216 30845   1.09203  0.2748
# valuecat4   -0.5246707 0.4594298 30845  -1.14200  0.2535
# valuecat5   -0.6351367 0.7370696 30845  -0.86171  0.3889
# valuecat6   -1.2202052 0.8368457 30845  -1.45810  0.1448
# period2      0.1260747 0.0189176 52532   6.66442  0.0000
# period3      0.3165939 0.0186322 52532  16.99179  0.0000
# Correlation: 
#   (Intr) agect2 agect4 agect5 agect6 valct2 valct3 valct4 valct5 valct6 perid2
# agecat2   -0.787                                                                      
# agecat4   -0.815  0.701                                                               
# agecat5   -0.753  0.650  0.668                                                        
# agecat6   -0.688  0.584  0.602  0.557                                                 
# valuecat2 -0.150 -0.032  0.002 -0.009  0.045                                          
# valuecat3 -0.062  0.005  0.011 -0.005  0.025  0.063                                   
# valuecat4 -0.018  0.008 -0.002  0.000  0.010  0.016  0.006                            
# valuecat5 -0.008 -0.003  0.001 -0.006  0.005  0.011  0.004  0.001                     
# valuecat6 -0.012  0.008  0.004  0.000  0.003  0.009  0.003  0.001  0.001              
# period2   -0.199  0.001  0.000  0.000  0.000  0.001  0.000  0.000  0.000  0.000       
# period3   -0.204 -0.001 -0.001 -0.001 -0.001  0.001 -0.001  0.000  0.000  0.000  0.520
# 
# Standardized Within-Group Residuals:
#   Min         Q1        Med         Q3        Max 
# -2.3342565 -0.2950359 -0.2694744 -0.2499035  3.0045980 
# 
# Number of Observations: 83389
# Number of Groups: 30855 
# Linear mixed-effects model fit by maximum likelihood
# Data: training_data 
# AIC BIC logLik
# NA  NA     NA
# 
# Random effects:
#   Formula: ~1 | policyID
# (Intercept)  Residual
# StdDev:    2.181642 0.5770924
# 
# Variance function:
#   Structure: fixed weights
# Formula: ~invwt 
# Fixed effects: claim ~ agecat2 + agecat4 + agecat5 + agecat6 + valuecat2 + valuecat3 +      valuecat4 + valuecat5 + valuecat6 + period2 + period3 
# Value Std.Error    DF   t-value p-value
# (Intercept) -2.6256421 0.0490533 52532 -53.52632  0.0000
# agecat2     -0.2232318 0.0570602 30845  -3.91222  0.0001
# agecat4     -0.2771932 0.0554405 30845  -4.99983  0.0000
# agecat5     -0.4646570 0.0598156 30845  -7.76815  0.0000
# agecat6     -0.4248755 0.0664157 30845  -6.39721  0.0000
# valuecat2    0.2510378 0.0437324 30845   5.74032  0.0000
# valuecat3    0.1345615 0.1232216 30845   1.09203  0.2748
# valuecat4   -0.5246707 0.4594298 30845  -1.14200  0.2535
# valuecat5   -0.6351367 0.7370696 30845  -0.86171  0.3889
# valuecat6   -1.2202052 0.8368457 30845  -1.45810  0.1448
# period2      0.1260747 0.0189176 52532   6.66442  0.0000
# period3      0.3165939 0.0186322 52532  16.99179  0.0000
# Correlation: 
#   (Intr) agect2 agect4 agect5 agect6 valct2 valct3 valct4 valct5 valct6 perid2
# agecat2   -0.787                                                                      
# agecat4   -0.815  0.701                                                               
# agecat5   -0.753  0.650  0.668                                                        
# agecat6   -0.688  0.584  0.602  0.557                                                 
# valuecat2 -0.150 -0.032  0.002 -0.009  0.045                                          
# valuecat3 -0.062  0.005  0.011 -0.005  0.025  0.063                                   
# valuecat4 -0.018  0.008 -0.002  0.000  0.010  0.016  0.006                            
# valuecat5 -0.008 -0.003  0.001 -0.006  0.005  0.011  0.004  0.001                     
# valuecat6 -0.012  0.008  0.004  0.000  0.003  0.009  0.003  0.001  0.001              
# period2   -0.199  0.001  0.000  0.000  0.000  0.001  0.000  0.000  0.000  0.000       
# period3   -0.204 -0.001 -0.001 -0.001 -0.001  0.001 -0.001  0.000  0.000  0.000  0.520
# 
# Standardized Within-Group Residuals:
#   Min         Q1        Med         Q3        Max 
# -2.3342565 -0.2950359 -0.2694744 -0.2499035  3.0045980 
# 
# Number of Observations: 83389
# Number of Groups: 30855 

# As we can see valuecat3, valuecat4, valuecat5 and valuecat6 have high p-value hence less 
# significant to the model.
