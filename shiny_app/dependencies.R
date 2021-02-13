# Based on https://github.com/rstudio/shiny-examples/blob/master/086-bus-dashboard/dependencies.R
# This is needed because the shinyapps dependency detection doesn't realize
# that jsonlite::fromJSON needs httr when using URLs.
library(httr)