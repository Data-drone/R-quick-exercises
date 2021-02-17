# Launch Local App
library("shiny")
library("shinydashboard")
library("leaflet")

# CML settings
address = '127.0.0.1'

# Shiny needs to have port as number
cml_port = Sys.getenv(x='CDSW_APP_PORT')
cml_port = as.numeric(cml_port)

# Use for local tests
# generic open id = "0.0.0.0"
# generic_port = 7474
shiny::runApp(appDir="shiny_app",host=address, port=cml_port, launch.browser=F)
