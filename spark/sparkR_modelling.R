### Test script for SparkR
## based on https://github.com/AnnaKim77/AnalysisUsingR/blob/1940e16b9901dbf5879586eeae769571e062fe2e/SparkR_card.R

# this config is for R3.x only not R4.x
Sys.getenv()
Sys.setenv(SPARK_HOME="/home/rstudio/spark/spark-3.0.0-bin-hadoop3.2")
library(SparkR, lib.loc = c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib")))
library(caret)
sparkR.session(master = "local[*]", sparkConfig = list(spark.driver.memory = "16g"))

### Read in the data
library(arrow)

####### read in the datasets
train_feats = arrow::read_feather('temp_data/train_features.feather')
train_targets = arrow::read_feather('temp_data/train_target.feather')
test_feats = arrow::read_feather('temp_data/test_features.feather')

# we need to merge the target column back for spark I think
feature_columns = colnames(train_feats)
train_feats['SalePrice'] <-  train_targets



