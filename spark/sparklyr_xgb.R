### sparklyr_xgb
## Note that this doesn't work due to sparkxgb not support Spark 3

library(tidyverse)
library(sparklyr)
library(arrow)
# lets bring in xgb
library(sparkxgb)

# setup local spark for dev
#spark_available_versions()
#spark_install(version='3.0')
options(sparklyr.log.console = F)

spark_address = 'spark://0.0.0.0:7077'
sc <- spark_connect(master = 'local', version='2.4.0')
#sc <- spark_connect(master = spark_address)

####### read in the datasets
train_feats = arrow::read_feather('temp_data/train_features.feather')
train_targets = arrow::read_feather('temp_data/train_target.feather')
test_feats = arrow::read_feather('temp_data/test_features.feather')

# we need to merge the target column back for spark I think
feature_columns = colnames(train_feats)
train_feats['SalePrice'] <-  train_targets

## need to test to see why train isn't working
#### Debugging code
train_feats %>% 
  select_if(function(x) any(is.na(x))) %>% 
  summarise_each(funs(sum(is.na(.)))) -> extra_NA

#### shuffle dataframes to spark
tbl_train <- copy_to(sc, train_feats, overwrite=T)
#tbl_train_targets <- copy_to(sc, train_targets, overwrite=T)
tbl_test <- copy_to(sc, test_feats, overwrite=T)
## single train with xgboost

param_grid_xgb <- list(xgboost= list(
      max_depth = c(1, 5),
      num_round = c(10, 50)
    )
  )

model_pipeline <- xgboost_regressor(tbl_train, SalePrice ~ .)

model_pipeline_tk2 <- tbl_train %>%
  ft_r_formula(SalePrice ~ .) %>%
  xgboost_regressor(num_round=100)

model_pipeline_tk2

### this doesn't work xgb isn't the same class as needed for ml_cross_validator
#xgb_fit <- ml_cross_validator(
#  tbl_train,
#  estimator = model_pipeline_tk2,
#  evaluator = ml_regression_evaluator(
#    sc, 
#    label_col = "SalePrice"
#  ),
#  estimator_param_maps = param_grid_xgb
#)

