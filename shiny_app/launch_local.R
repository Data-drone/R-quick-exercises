# Launch Local App
library("shiny")

shiny::runApp(appDir="shiny_app",host="0.0.0.0", port=7474, launch.browser=F)
