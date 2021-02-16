### Test script for SparkR
## based on https://github.com/AnnaKim77/AnalysisUsingR/blob/1940e16b9901dbf5879586eeae769571e062fe2e/SparkR_card.R

# this config is for R3.x only not R4.x
Sys.getenv()
#Sys.setenv(SPARK_HOME="/home/rstudio/spark/spark-3.0.0-bin-hadoop3.2")
Sys.setenv(SPARK_HOME="/home/rstudio/spark/spark-2.4.0-bin-hadoop2.7")
library(SparkR, lib.loc = c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib")))
library(caret)
sparkR.session(master = "local[*]", sparkConfig = list(spark.driver.memory = "16g"))

### Read in the data
library(tidyverse)
library(arrow)

####### read in the datasets
train_feats = arrow::read_feather('temp_data/train_features.feather')
train_targets = arrow::read_feather('temp_data/train_target.feather')
test_feats = arrow::read_feather('temp_data/test_features.feather')

# we need to merge the target column back for spark I think
feature_columns = colnames(train_feats)
train_feats['SalePrice'] <-  train_targets

train_feats %>% 
  select_if(function(x) any(is.na(x))) %>% 
  summarise_each(funs(sum(is.na(.)))) -> extra_NA

# SparkR seems more sensitive to Nas than Sparklyr
# Also SparkR doesn't seem to be registering the handleInvalid command
train_filter <- train_feats %>%
  drop_na()

# Move the dataframes to spark with SparkR
train_spk <- createDataFrame(train_filter)
test_spk <- createDataFrame(test_feats)

## drop Id column
train_sok <- SparkR::drop(train_spk, "Id")
test_sok <- SparkR::drop(test_spk, "Id")

# train gbt model
price_model<-spark.randomForest(train_sok, 
                          formula=SalePrice~.,
                          type="regression")

summary(price_model)
