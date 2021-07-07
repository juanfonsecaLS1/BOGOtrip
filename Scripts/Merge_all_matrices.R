library(tidyverse)

Linea_recta_distancias <- read_csv("GIS/Linea_recta_distancias.csv")%>%
  pivot_longer(cols = -"ID",names_to = "D",values_to = "str.dist")%>%
  rename(O=ID)%>%mutate(D=as.numeric(D),
                        str.dist=str.dist/1e3)

modes<-lapply(c("Bike","Walk","Car"), function(x){y<-read_csv(paste0(x,"_matrices.csv"))})%>%
  reduce(full_join,by=c("O","D"))

Full<-Linea_recta_distancias%>%
  full_join(modes,by=c("O","D"))%>%
  arrange(O,D)%>%
  mutate_at(.vars = vars(ends_with("_dist")),
            .funs = list(ratio=~(./(str.dist))),
            .names="{fn}_{col}")


write_csv(Full,
          file = "app/www/Full_matrices.csv",
          quote_escape = FALSE)
