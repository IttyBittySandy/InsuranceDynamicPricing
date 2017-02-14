##Approach Document

####TOPIC - INSURANCE DYNAMIC PRICING UNDERWRITING

###Data 

    URL : https://cran.r-project.org/web/packages/insuranceData/insuranceData.pdf
    Dataset : ClaimsLong
    Description : Car insurance data set containing 1,20,000 records.
                  columns - 
                  policyID: unique identifier of policy
                  agecat: categorical value of age
                  valuecat: categorical value of value of the car
                  period: duration of the policy 
                  numclaims: number of claim
                  claim: categorical value whether claim was made or not

###Problem Details
    Problem statement : Predict the number of claim for policy

    Problem Detail: Unlike regular regression problems with the values of dependant variables are normally distributed. 
                    In insurance domain the dependant variable is not distributed normally.
                    This leads us to go beyond linear regression modeling to Generalised Linear Models or GLMs.

                GLMs have 3 components - 

                1) Random component - the distribution of dependent variable. In our case claim number.
                The claim number follows poisson distribution. Poisson distribution expresses the probability of 
                a given number of events occuring in fixed interval of time.

                2) Systematic component - Linear predictor of dependent variables

                3) Link function - connects the random and systematic component.
                Takes the output of systematic component which is linear
                Transforms this using link function to paramter that describes random component,
                in case of poisson distribution it represents lambda (poisson mean)

                The link function descripes how the mean of the distribution is related to 
                linear or the systematic component.
                For instance if the systematic comment is α + βx 

                μ or λ(in case of poisson) = e^(α + βx ) 
                Mean is estimated using Maximum likelihood estimator.

                Maximum likelihood estimator is used where the value has some noise and the value can be 
                predicted as highly likely and not as precise value.
                Maximum likelihood works by first finding the likelihood function.
                Taking log of the likelihood function and then differentiating to find values of parameters
                at which the maximum value is likely to occur.
###Procedure

    1) Exploratory Data Analysis
                    - Outlier Analysis 
                    - Missing value Analysis 
    2) Data Tranformation 
                    - Convert categorical data to numerical values 
                      Variables agecat and valuecat are converted to numerical by replacing categorical code by values.
    3) Modeling 
                    - Based on the link function then choose explanatory variables that can be modelled
                    - With choosen explanatory variables model is developed
    4) Visualisation

                 



