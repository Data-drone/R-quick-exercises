# tidyverse packages
install.packages("tidyverse")

# xgboost
install.packages("drat", repos="https://cran.rstudio.com")
drat:::addRepo("dmlc")
#install.packages("xgboost", repos="http://dmlc.ml/drat/", type = "source")

install.packages("xgboost")

# getting access to kaggle data
install.packages("devtools")

# moments for skew and kurtosis
install.packages("moments")

# reshape for correlation diagram
install.packages("reshape2")

# GGally for better pair plots (Hadley approved)
install.packages("GGally")

# standard modelling package
install.packages("caret")
install.packages("e1071")
install.packages("fastDummies")

# for shiny apps
install.packages("shiny")

# for spark
install.packages("sparklyr")

# install arrow format for saving data
install.packages("arrow")

# xgboost this is only for spark 2.4 at this stage
install.packages("sparkxgb")
#devtools::install_github("Data-drone/sparkxgb", ref="feature/xgboost-1.3.1")
