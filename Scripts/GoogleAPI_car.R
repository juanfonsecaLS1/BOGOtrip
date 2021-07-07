library(mapsapi)
library(lubridate)
library(tidyverse)

# Reading the coordinates of the centroids of all urban Planning Units Zones
# Importa el archivo con las coordenadas de las UPZ urbanas

Zones <- read_csv("GIS/Centroides_UPZ_coordenadas.csv",
                  col_types = cols(UPlCodigo = col_character(),
                                   UPlTipo = col_integer(), UPlNombre = col_character(),
                                   UPlAAdmini = col_character(), UPlArea = col_double(),
                                   SHAPE_Leng = col_double(), SHAPE_Area = col_double(),
                                   x = col_double(), y = col_double()))


# INPUTS ------------------------------------------------------------------
source('02_Scripts/new_mapsapi.R')

# Get Zones
Zones <- read_excel("\\\\europe.jacobs.com\\Leeds\\Projects\\B2327FEK - M6 Jct33\\Technical\\Model\\Modal Shift\\Zones\\Zones_summary.xlsx",
                    sheet = "Tidy_table",
                    col_types = c("numeric",
                                  "text", "text", "text", "numeric",
                                  "numeric", "text", "text"))

KEY <- readLines(con = "./01_Inputs/API_key.txt",n = 1,warn = FALSE)



## Defining the ODs
base_od_pairs<-read_excel("P:/B2327FEK - M6 Jct33/Technical/Model/Modal Shift/Zones/Zones_summary.xlsx",
                          sheet = "For API_form", col_types = c("numeric",
                                                                "numeric", "skip", "skip", "skip",
                                                                "skip"))%>%
  rownames_to_column("ID")

m.mode="driving"

# Defining the Max number of iterations, and intervals for time
max_attempts = 5 # For the errors in reponse
interval = 20 #mins

# Defining the function to extract data -----------------------------------
## Today's date
today<-format(Sys.Date(), format = "%Y%m%d")
## Defining the date
base_datetime<-dmy_hms("16/6/21 8:30:00", tz = "Europe/London")

## Existing files
path<-"C:/Users/fonsecj/OneDrive - Jacobs/GitHub_Network/Google_API_Matrix/03_Outputs/20210608_driving"
files.xml<-list.files(path = path,pattern = "driving.*\\.xml$")
.files.available<-data.frame(file=files.xml)%>%mutate(O=as.numeric(str_extract(file,pattern = "^\\d{1,3}")),
                                                      D=as.numeric(str_extract(file,pattern = "(?<=^\\d{1,3}_)\\d{1,3}")),
                                                      ts=ymd_hm(str_extract(file,pattern = "\\d{8}_\\d{4}"),tz = "Europe/London"))

# Creates a directory for the data
dir.create(paste0("03_Outputs/",
                  today),
           recursive = TRUE,
           showWarnings = FALSE)

# Defines function to get the XML response
.extract_XML<-function(x,
                       O=od_pairs$O[od_pairs$ID==x],
                       D=od_pairs$D[od_pairs$ID==x]){

  print(paste(Sys.time(), "Processing OD:",O,"to",D))

  #Extracting coordinates
  O.coords<-c(Zones$X[Zones$Zone==O],Zones$Y[Zones$Zone==O])
  D.coords<-c(Zones$X[Zones$Zone==D],Zones$Y[Zones$Zone==D])

  ## Running the API request
  y <- tryCatch({mp_directions(
    origin = O.coords,
    destination = D.coords,
    mode = m.mode,
    departure_time =  datetime,
    key = KEY,
    quiet = TRUE)},
    error = function (e) NA)

  Sys.sleep(0.02)

  if (!is.na(y)) {
    # Saves the xml file just in case
    write_xml(y,
              file = paste0(
                "03_Outputs/",
                today,
                "/",
                O,
                "_",
                D,
                "_",
                m.mode,
                "_",
                format(datetime, format = "%Y%m%d_%H%M"),
                ".xml"
              ))

    if (y %>%
        xml_child("status") %>%
        xml_text == "OK") {
      z<-data.frame(
        O = O,
        D = D,
        comments = "OK")
    } else{
      z <- data.frame(
        O = O,
        D = D,
        comments = paste0(y %>%xml_child("status") %>%xml_text,
                          y %>%xml_child("error_message") %>%xml_text))
    }
  } else {
    z <- data.frame(
      O = O,
      D = D,
      comments = "Error in response. Check inputs"
    )
  }
  return(z)
}


# Defines the loop

lapply(0:2,function(x){
  message(paste("Processing the files for:",base_datetime+x*interval*60))
  datetime=base_datetime+x*interval*60

  files.OK<-.files.available%>%select(O,D)%>%unique()

  od_pairs<-base_od_pairs%>%anti_join(files.OK,by=c("O","D"))
  message(paste("Total files to get: ",length(od_pairs$ID)))

  ## Running the process for the car times (initial iteration)
  DB.cartimes <- do.call(rbind, lapply(od_pairs$ID, .extract_XML))

  # Check for bad responses due to Non-identified API errors
  check.responses <-
    length(DB.cartimes$O[DB.cartimes$comments == "Error in response. Check inputs"]) >
    0

  Final.Cartimes <- list(NULL)
  # Runs the process in case there are issues with the connections
  if (!check.responses) {
    Final.Cartimes[[1]] <- DB.cartimes
  } else{
    Final.Cartimes[[1]] <- DB.cartimes
    cont = 2

    failed_od_pairs <- od_pairs %>%
      semi_join(
        Final.Cartimes[[1]] %>%
          filter(comments == "Error in response. Check inputs"),
        by = c("O", "D")
      )
    Final.Cartimes[[1]] <- DB.cartimes %>%
      filter(comments != "Error in response. Check inputs")

    while (cont < max_attempts & check.responses) {
      print("Starting a new iteration")
      DB.cartimes.try <-
        do.call(rbind, lapply(failed_od_pairs$ID, .extract_XML))

      check.responses <-
        length(DB.cartimes.try$O[DB.cartimes.try$comments == "Error in response. Check inputs"]) >
        0

      if (cont < max_attempts & check.responses) {
        failed_od_pairs <- od_pairs %>%
          semi_join(
            DB.cartimes.try %>%
              filter(comments == "Error in response. Check inputs"),
            by = c("O", "D")
          )

        Final.Cartimes[[cont]] <- DB.cartimes.try %>%
          filter(comments != "Error in response. Check inputs")
      } else{
        Final.Cartimes[[cont]] <- DB.cartimes.try
      }
      cont = cont + 1
      Sys.sleep(3)

    }


  }

  return(bind_rows(Final.Cartimes))


})
