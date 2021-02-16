# Modelling Script
# based on https://www.kaggle.com/serigne/stacked-regressions-top-4-on-leaderboard
library(MASS)
library(tidyverse)
library(moments)
library(caret)
library(e1071)
library(fastDummies)

# we need newer dplyr for starting
# this script needs dplyr > 1.0
#devtools::install_github("tidyverse/dplyr", ref="v1.0.3")

train <- read_csv('house_prices_data/train.csv')
test <- read_csv('house_prices_data/test.csv')

train_wo_id <- train %>% dplyr::select(-Id)
test_wo_id <- test %>% dplyr::select(-Id)

# outlier removal
train_filtered <- train_wo_id  %>%
  dplyr::filter(!(GrLivArea>4000 & SalePrice<300000))

# Log transform the target
train_feat_eng <- train_filtered %>%
  dplyr::mutate(LogSales=log1p(SalePrice)) %>%
  dplyr::select(-SalePrice)

## Full Feature Engineering Section

train_cut = train %>% 
  dplyr::filter(!(GrLivArea>4000 & SalePrice<300000)) 
train_y_values <- train_cut %>% dplyr::select(SalePrice)
train_cut <- train_cut %>%
  dplyr::select(-SalePrice)
ntrain = nrow(train_cut)
ntest = nrow(test)
full_dataset <- rbind(train_cut, test)

## Missing Data Imputation

full_dataset <- full_dataset %>%
  tidyr::replace_na(list(PoolQC='None', MiscFeature='None', Alley='None', Fence='None', FireplaceQu='None', 
                  GarageType='None', GarageFinish='None', GarageQual='None', 
                  GarageCond='None', GarageYrBlt=0, GarageArea=0, GarageCars=0,
                  BsmtFinSF1=0, BsmtFinSF2=0, BsmtUnfSF=0,TotalBsmtSF=0, 
                  BsmtFullBath=0, BsmtHalfBath=0, BsmtQual='None', BsmtCond='None', 
                  BsmtExposure='None', BsmtFinType1='None', BsmtFinType2='None',
                  MasVnrType='None', MasVnrArea=0, MSZoning='RL', Functional='Typ',
                  Electrical='SBrkr', KitchenQual='TA', Exterior1st='VinylSd',
                  Exterior2nd='VinylSd', SaleType='WD', MSSubClass='None')) %>%
  dplyr::select(-Utilities)

# convert some numerical to categorical
full_dataset <- full_dataset %>%
  dplyr::mutate(MSSubClass=as.factor(MSSubClass), OverallCond=as.factor(OverallCond), 
         YrSold=as.factor(YrSold), MoSold=as.factor(MoSold))

# LabelEncode
cols = c('FireplaceQu', 'BsmtQual', 'BsmtCond', 'GarageQual', 'GarageCond', 
         'ExterQual', 'ExterCond','HeatingQC', 'PoolQC', 'KitchenQual', 'BsmtFinType1', 
         'BsmtFinType2', 'Functional', 'Fence', 'BsmtExposure', 'GarageFinish', 'LandSlope',
         'LotShape', 'PavedDrive', 'Street', 'Alley', 'CentralAir', 'MSSubClass', 'OverallCond', 
         'YrSold', 'MoSold')

full_dataset <- full_dataset %>%
  dplyr::mutate(across(all_of(cols), as.factor)) %>%
  dplyr::mutate(across(all_of(cols), as.numeric))

# testy - for finding nas
#full_dataset %>% group_by(SaleType) %>% summarise(count=n()) %>% arrange(desc(count))

# Add a total floor area
full_dataset <- full_dataset %>%
  dplyr::mutate(TotalSF = TotalBsmtSF + `1stFlrSF` + `2ndFlrSF`)

# median frontage by Neighborhood
full_dataset <- full_dataset %>%
  dplyr::group_by(Neighborhood) %>%
  dplyr::mutate(LotFrontage=ifelse(is.na(LotFrontage), median(LotFrontage,na.rm=TRUE), LotFrontage))

# fix numbers in names
full_dataset <- full_dataset %>%
  dplyr::mutate(ThreeSsnPorch = `3SsnPorch`, FirstFlrSF = `1stFlrSF`, SecondFlrSF = `2ndFlrSF`) %>%
  dplyr::select(-`3SsnPorch`, -`1stFlrSF`, -`2ndFlrSF`)

# Select the top Skewed Columns
top_skewed <- full_dataset %>%
  dplyr::ungroup() %>%
  dplyr::summarise(across(where(is.numeric), ~ skewness(.x))) %>%
  tidyr::pivot_longer(everything(), names_to = "cols", values_to = "skewness") %>%
  dplyr::arrange(desc(skewness)) %>%
  dplyr::filter(abs(skewness) > 0.75) %>%
  dplyr::select(cols)

# quick test
check_min <- full_dataset %>% 
  ungroup() %>% 
  dplyr::select(top_skewed$cols) %>%
  summarise_all(list(min)) %>%
  tidyr::pivot_longer(everything(), names_to = "cols", values_to = "min")

# and use Box Cox on them
# this doesnt seem to be doing anything
box_coxed <- full_dataset %>%
  dplyr::ungroup() %>%
  dplyr::mutate(across(all_of(top_skewed$cols), ~ .x+1)) %>%
  dplyr::mutate(across(all_of(top_skewed$cols), ~ BoxCoxTrans(.x) %>% predict(.x) ))

# skewness(box_coxed$MiscVal)
feat_enged_table <- fastDummies::dummy_cols(box_coxed, remove_selected_columns=T)

# quick xgb model
train_sub = feat_enged_table[0:ntrain,]
test_sub = feat_enged_table %>%
  dplyr::slice(ntrain+1:n())

########## Save out copies here for use elsewhere if need be
library(arrow)

arrow::write_feather(train_sub, 'temp_data/train_features.feather')
arrow::write_feather(train_y_values, 'temp_data/train_target.feather')
arrow::write_feather(test_sub, 'temp_data/test_features.feather')


########## Modelling

library(xgboost)
xgb <- xgboost(data = as.matrix(train_sub),
               label= train_y_values$SalePrice,
               colsample_bytree = 0.4603,
               gamma=0.0468,
               learning_rate=0.05,
               max_depth = 3, 
               min_child_weight=1.7817, n_estimators=2200,
               reg_alpha=0.4640, reg_lambda=0.8571,
               subsample=0.5213, silent=1,
               random_state =7, nthread = -1,
               nrounds=500)