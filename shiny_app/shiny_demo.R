# note that we do not have a full API key setup for the bus details
install.packages("shinydashboard")

if (!require(devtools))
  install.packages("devtools")
devtools::install_github("rstudio/leaflet")
shiny::runGitHub("rstudio/shiny-examples", subdir="086-bus-dashboard",
                 host="0.0.0.0", port=7474, launch.browser=F)
