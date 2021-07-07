#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#


if(!require(tidyverse)) install.packages('tidyverse')
if(!require(shiny)) install.packages('shiny')
if(!require(leaflet)) {
  devtools::install_github('rstudio/leaflet')
  devtools::install_github("rstudio/leaflet.providers")
  devtools::install_github('bhaskarvk/leaflet.extras')
}
if(!require(lubridate)) install.packages('lubridate')
if(!require(shinycssloaders)) install.packages('shinycssloaders')
if(!require(rgdal)) install.packages('rgdal')

# Define UI for application that draws a histogram
shinyUI(fluidPage(div(class="outer",


                      leafletOutput("map"),
                      absolutePanel(id = "controls", class = "panel panel-default", fixed = TRUE,
                                    draggable = TRUE, top = 60, left = "auto", right = 20, bottom = "auto",
                                    width = 330, height = "auto",
                                    h1("Tiempos de viaje"),
                                    p(em("lalalaalala")),
                                    br(),
                                    selectInput(inputId = "variable",label = "Variable",
                                                choices = c("Time" = "t",
                                                            "Distance" = "d"),
                                                "Time"),
                                    br(),
                                    selectInput(inputId = "mode",label = "Mode",
                                                choices = c("Walk" = "Walk",
                                                            "Bike" = "Bike",
                                                            "Car" = "Car"),
                                                "Walk"),
                                    br(),
                                    selectInput(inputId = "value",label = "Value",
                                                choices = c("Absolute" = "a",
                                                            "Ratio" = "r"),
                                                "Absolute"),
                                    br()
                                    ),
                      tags$head(tags$style("#map{height:100vh !important;}"))

)))
