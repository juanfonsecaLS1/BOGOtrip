
library(tidyverse)
library(shiny)
library(leaflet)
library(lubridate)
library(shinycssloaders)
library(rgdal)
library(shinythemes)

shinyUI(fluidPage(
  theme = shinytheme("yeti"),
  leafletOutput("map"),
  absolutePanel(
    id = "controls",
    class = "panel panel-default",
    fixed = FALSE,
    draggable = FALSE,
    style = " background-color: white;
              opacity: 0.70;
              padding: 20px 20px 20px 20px;
              margin: auto;
              border-radius: 5pt;
              box-shadow: 0pt 0pt 6pt 0px rgba(61,59,61,0.48);
              padding-bottom: 2mm;
              padding-top: 1mm;",
    top = "auto",
    left = 20,
    right = "auto",
    bottom = 20,
    width = 250,
    height = "auto",
    h1("Tiempos de viaje"),
    p(em("lalalaalala")),
    selectInput(
      inputId = "variable",
      label = "Variable/Variable",
      choices = c("Tiempo/Time" = "t",
                  "Distancia/Distance" = "d"),
      selected = "Tiempo/Time"
    ),
    selectInput(
      inputId = "mode",
      label = "Modo/Mode",
      choices = c(
        "Caminando/Walk" = "Walk",
        "Bicicleta/Bike" = "Bike",
        "Carro/Car" = "Car"
      ),
      selected = "Caminando/Walk"
    ),
    selectInput(
      inputId = "value",
      label = "Valor/Value",
      choices = c(
        "Absoluto/Absolute" = "a",
        "Proporción/Ratio" = "r"
      ),
      "Absoluto/Absolute"
    ),
    checkboxInput("legend", "Show legend", TRUE)
  ),
  tags$head(tags$style("#map{height:100vh !important;}"))
))
