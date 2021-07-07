library(openrouteservice)
library(tidyverse)

# Reading the coordinates of the centroids of all urban Planning Units Zones
# Importa el archivo con las coordenadas de las UPZ urbanas

Zones <- read_csv("GIS/Centroides_UPZ_coordenadas.csv",
                                       col_types = cols(UPlCodigo = col_character(),
                                                        UPlTipo = col_integer(), UPlNombre = col_character(),
                                                        UPlAAdmini = col_character(), UPlArea = col_double(),
                                                        SHAPE_Leng = col_double(), SHAPE_Area = col_double(),
                                                        x = col_double(), y = col_double()))

# Function to organise the coordinates in the right format for the ORS function
# Function para organizar las coordenadas en el formato que se requiere para la funcion del paquete ORS
coord_pair<-function(x){
  y<-c(Zones$x[x],Zones$y[x])
  return(y)
}


coordinates<-lapply(1:length(Zones$UPlCodigo),coord_pair)


# Reads and sets the key for the API
# Lee y fija el KEY del API de ORS
KEY<-readLines("myOSMkey.txt")

ors_api_key(KEY)


# Creates an empty object where the data is going to be stored (this was created because of the limited number of elements by call)
matrix<-list()

for(i in 1:4){
  y<-c((i-1)*114%/%4,(i)*114%/%4-1)
  if(y[2]==111){y[2]<-113}

  matrix[[i]]<-ors_matrix(locations = coordinates,
                     destinations=as.list(c(y[1]:y[2])),
                     metrics = c("duration", "distance"),
                     units = "km",
                     profile = "foot-walking"
  )
}


# Appends the time and distance matrices
Duration_mat<-cbind(matrix[[1]]$durations,matrix[[2]]$durations,matrix[[3]]$durations,matrix[[4]]$durations)
Distance_mat<-cbind(matrix[[1]]$distances,matrix[[2]]$distances,matrix[[3]]$distances,matrix[[4]]$distances)


# Produces long format matrices for further processing
time_long<-as.data.frame(Duration_mat)%>%
  rownames_to_column(var = "O")%>%
  pivot_longer(cols = -O,names_to = "D",names_prefix = "V",values_to = "Walk_time")

dist_long<-as.data.frame(Distance_mat)%>%
  rownames_to_column(var = "O")%>%
  pivot_longer(cols = -O,names_to = "D",names_prefix = "V",values_to = "Walk_dist")


# Saves a CSV file with the matrices and the UPZ list
write_csv(left_join(time_long,dist_long,by=c("O","D")),file = "Walk_matrices.csv",quote_escape = FALSE)
