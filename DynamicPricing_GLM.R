# Load data 
library(insuranceData)
data("ClaimsLong")
claims_df <- ClaimsLong

# Pre Data Cleaning categorical data analysis
# 1) agecat, as per data definition the value ranges from 1-6
unique(claims_df$age)
# we see that there a category code - 10 which is beyond range 1-6
# let's look at  the count of these
nrow(claims_df[which(claims_df$agecat==10),])
# 27345 rows found which is 22.78% of the data
# we will discard this 22.78% of the data because we have no mention of 
# age category code in data definition
claims_df <- claims_df[-which(claims_df$agecat==10), ]

# 2) valuecat, as per data definition the value ranges from 1-6
# but 1 has been recorded as 9, so we will replace 9 with 1 to maintain consistency
claims_df[which(claims_df$valuecat==9), ]$valuecat <- 1

# Data Cleaning
# 1) convert agecat from categorical to numerical values
#    since the data set doesn't give any information about the age ranges
#    we are going to assume below values 
#    1 belongs to range -> (20-29) ; so we will consider value 25
#    2 belongs to range -> (30-39) ; so we will consider value 35
#    3 belongs to range -> (40-49) ; so we will consider value 45
#    4 belongs to range -> (50-59) ; so we will consider value 55
#    5 belongs to range -> (60-69) ; so we will consider value 65
#    6 belongs to range -> (70-79) ; so we will consider value 75

claims_df[which(claims_df$agecat==1),]$agecat <- 25
claims_df[which(claims_df$agecat==2),]$agecat <- 35
claims_df[which(claims_df$agecat==3),]$agecat <- 45
claims_df[which(claims_df$agecat==4),]$agecat <- 55
claims_df[which(claims_df$agecat==5),]$agecat <- 65
claims_df[which(claims_df$agecat==6),]$agecat <- 75

# 2) convert valuecat from categorical to numerical values
#    since the data set doesn't give any information about the age ranges
#    we are going to assume below values
#    1 belongs to range -> (<25,000) ; so we will consider value 25,000
#    2 belongs to range -> (25,000-50,000) ; so we will consider value 37,500
#    3 belongs to range -> (50,000-75,000) ; so we will consider value 50,000
#    4 belongs to range -> (75,000-100,000) ; so we will consider value 62,500
#    5 belongs to range -> (100,000-125,000) ; so we will consider value 75,000
#    6 belongs to range -> (>125,000) ; so we will consider value 1,00,000

claims_df[which(claims_df$valuecat==1),]$valuecat <- 25000
claims_df[which(claims_df$valuecat==2),]$valuecat <- 37500
claims_df[which(claims_df$valuecat==3),]$valuecat <- 50000
claims_df[which(claims_df$valuecat==4),]$valuecat <- 62500
claims_df[which(claims_df$valuecat==5),]$valuecat <- 75000
claims_df[which(claims_df$valuecat==6),]$valuecat <- 100000
