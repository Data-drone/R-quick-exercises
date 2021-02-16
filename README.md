# R-quick-exercises
Some quick R code for common scenarios

## Exercises

Data Analytics Example with data munging / visualisation and modelling
`data_analysis` subfolder
- `setup.R`
    Setup common environment and often used packages

- `data_exploration.Rmd`
    Exploration of the kaggle housing data dataset based on Python Kernel
    https://www.kaggle.com/pmarcelino/comprehensive-data-exploration-with-python


- `feat_eng_model.R`
    Feature engineering and modelling script based on:
    https://www.kaggle.com/serigne/stacked-regressions-top-4-on-leaderboard
    
Shiny Application
- Basic one based on: Based on: https://github.com/rstudio/shiny-examples/tree/master/086-bus-dashboard
   - TODO - Still needs refactoring to show updated routes properly but will suffice for now

Spark Integration
`spark` subfolder
- `sparklyr_experiment,R`
    Sparklyr and mllib driven model development based on:
        https://www.eddjberry.com/post/2018-12-12-sparklyr-feature-selection/
- `sparklyr_xgb.R`
    XGBoost4j with Rstudio sparkxgb (Spark 2.4 only currently)
        
- Possible Content to add:
    https://spark.rstudio.com/mlib/#example-workflow
    https://datascience-enthusiast.com/Hadoop/SparkR_on_HDP_AWS_EC2_part2.html
- TODO


