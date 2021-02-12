# tidyverse packages
install.packages("tidyverse")

# xgboost
install.packages("drat", repos="https://cran.rstudio.com")
drat:::addRepo("dmlc")
install.packages("xgboost", repos="http://dmlc.ml/drat/", type = "source")

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
