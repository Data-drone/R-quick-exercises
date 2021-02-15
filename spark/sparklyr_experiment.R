# based on https://www.eddjberry.com/post/2018-12-12-sparklyr-feature-selection/
# but using the feats we generated earlier

library(tidyverse)
library(sparklyr)
library(arrow)
# lets bring in xgb
library(sparkxgb)

# setup local spark for dev
#spark_available_versions()
#spark_install(version='3.0')

spark_address = 'spark://0.0.0.0:7077'
sc <- spark_connect(master = 'local')
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


#### This function gets the feature column names fo running models on
## Excludes the exclude vars
get_feature_cols <- function(tbl, response, exclude = NULL) {
  # column names of the data
  columns <- colnames(tbl)
  # exclude the response/outcome variable and 
  # exclude from the column names
  columns[!(columns %in% c(response, exclude))]
}

#param_grid <- list(linear_regression = list(elastic_net_param = 0))
#param_grid <- list(generalized_linear_regression = list(link = "log", reg_param = 1e-2, max_iter = 10))
param_grid <- list(gbt_regressor = list(max_depth = 10))

# do a full feature selection process 
# ML Fit function Runs cross validation 
ml_fit_cv <-
  function(sc, # Spark connection
           tbl, # tbl_spark
           model_fun, # modelling function
           label_col, # label/response/outcome columns
           feature_cols_exclude = NULL, # vector of features to exclude
           param_grid, # parameter grid
           seed = sample(.Machine$integer.max, 1) # optional seed (following sdf_partition)
  ) {
    
    # columns for the feature
    feature_cols <-
      get_feature_cols(tbl, label_col, feature_cols_exclude)
    
    # vector assembler
    tbl_va <- ft_vector_assembler(tbl,
                                  input_cols = feature_cols,
                                  output_col = "features")
    
    # estimator
    estimator <- model_fun(sc, label_col = label_col)
    
    # an evaluator
    evaluator <-
      ml_regression_evaluator(sc, label_col = label_col)
    
    # do the cv
    ml_cross_validator(
      tbl_va,
      estimator = estimator,
      estimator_param_maps = param_grid,
      evaluator = evaluator,
      seed = seed
    )
  }

# construct the frame that holds 
df_feature_selection <-
  tibble(excluded_feature = get_feature_cols(tbl_train, 'SalePrice'))

#### Add in a full mutate cv fit
df_feature_selection <- df_feature_selection %>%
  mutate(
    cv_fit = map(
      excluded_feature,
      ~ ml_fit_cv(
        sc,
        tbl = tbl_train,
        model_fun = ml_gbt_regressor,
        label_col = 'SalePrice',
        feature_cols_exclude = .x,
        param_grid = param_grid,
        seed = 2018
      )
    ),
    avg_metric = map_dbl(cv_fit, ~ .x$avg_metrics)
  )

