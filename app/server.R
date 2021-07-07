# Libraries
rm(list=ls())

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

# Load shape file with UPZ
UPZ <- readOGR("www/UPla.shp",
                   layer = "UPla", GDAL1_integer64_policy = TRUE)


# Load table with times
FULL_matrices <- read_csv("www/FULL_matrices.csv")


# Define server logic required to draw a histogram
shinyServer(function(input, output) {
    output$map<-renderLeaflet({
        leaflet(UPZ) %>%
            addPolygons(layerId = ~ID,color = "#b9c2f5", weight = 1, smoothFactor = 0.5,
                        opacity = 0.4, fillOpacity = 0.3,
                        fillColor = "#b9c2f5",
                        highlightOptions = highlightOptions(color = "white", weight = 2,
                                                            bringToFront = TRUE),label = ~str_to_title(UPlNombre))%>%
            addProviderTiles(providers$CartoDB.Positron, options = providerTileOptions(noWrap = TRUE) ) %>%
            fitBounds(-74.079,4.46,-74.065, 4.80) ## Bogotá
    })

    #Subset data specific origin
    data_for_origin<-function(x,col){
        print(FULL_matrices%>%
                  filter(O==x))

        y<-FULL_matrices%>%
            filter(O==x)%>%
            rename(ID=D)%>%
            select(any_of(c("ID",col)))

        names(y)[names(y)==col]<-"Var"

        return(y)
    }


    ### Function to update the map
    update_UPZ<-function(ID,Mode,variable,value){
        scol<-paste0(Mode,"_",variable,value,collapse = "")
        tmp_data<-data_for_origin(ID,scol)

        tmp_UPZ<-UPZ
        tmp_UPZ@data<-UPZ@data%>%left_join(tmp_data,by="ID")

        pal<-colorNumeric("Blues",domain = c(min(abs(FULL_matrices[,scol]),na.rm = TRUE),max(abs(FULL_matrices[,scol]),na.rm = TRUE)))

        leafletProxy("map",data = tmp_UPZ)%>%
            clearShapes() %>%
            addPolygons(layerId = ~ID,
                        stroke = FALSE,
                        color = ~pal(Var),
                        smoothFactor = 0.5,
                        fillOpacity = 0.6,
                        highlightOptions = highlightOptions(color = "white", weight = 2,
                                                            bringToFront = TRUE),
                        label = ~paste0(str_to_title(UPlNombre),": ",round(Var,digits = 0)," minutos"))
    }



    observe({
        leafletProxy("map")
        event <- input$map_shape_click
        if (is.null(event))
            return()

        isolate({
            print(event$id)
            update_UPZ(event$id,input$mode,input$variable,input$value)
        })
    })



})
