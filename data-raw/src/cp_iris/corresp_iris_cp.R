##======================================================================
### --- corresp_iris_cp.R ---
##======================================================================
## Auteur: Edouard Chatignoux
## Créé le 2020-09-30
## Dernière mise à jour le 2022-03-22
##======================================================================
##  Description:
##--------------
##' Correspondance entre les IRIS et les codes postaux + 
##' codes IRIS des bases de pop
##' 
##======================================================================

library(haven)
library(readxl)

###'Référentiels
##'==================================== 
####' Référentiel communes 2019 INSEE
##'---------------------------------------- 
ref_com_19<-readRDS("./data-raw/src/com/ref_com.rds") %>%
  filter(annee_geo==2019)

####' Référentiel Iris 2019
##'---------------------------------------- 
ref_iris<-readRDS("./data-raw/src/iris/ref_iris.rds") %>%
  filter(annee_geo==2019)

####' Référentiel codes postaux
##'---------------------------------------- 
ref_cp<-read_csv2("S:/alerte/Coronavirus_2020/3-Surveillance/SIDEP/INDICATEURS SpF/R/Prepare_data/CODE_POSTAL/laposte_hexasmal_20200602.csv",
                  col_types = list(Code_commune_INSEE=col_character(),
                                   Code_postal=col_character()))%>%
  select(cp=Code_postal,com=Code_commune_INSEE)

## Codes postaux hexasmal non dans le shape
corresp_cp_shp<-read_csv2("S:/alerte/Coronavirus_2020/3-Surveillance/SIDEP/INDICATEURS SpF/R/Prepare_data/CODE_POSTAL/corresp_cp2.csv",
                          col_types = list(hexasmal=col_character(),
                                           fond_carte=col_character()))%>%
  select(cp_hexa=hexasmal,cp_shp=fond_carte)

ref_cp<-ref_cp%>%select(cp)%>%unique()%>%
  left_join(corresp_cp_shp%>%rename(cp=cp_hexa))%>%
  mutate(cp_shp=ifelse(is.na(cp_shp),cp,cp_shp))

## Quelques diff
ref_cp%>%filter(cp!=cp_shp)

###'Correspondance IRIS - CP
##'====================================
dt_com_cp <- readRDS("./data-raw/src/cp_com/dt_com_cp.rds")
dt_cp_com <- readRDS("./data-raw/src/cp_com/dt_cp_com.rds")

corresp_cp_com<-
  dt_cp_com%>%
  unnest(com)%>%
  left_join(ref_cp)%>%
  mutate(cp=cp_shp)%>%
  select(-cp_shp)%>%
  group_by(cp,match_cp_com )%>%
  nest()

corresp_com_cp<-
  dt_com_cp%>%
  unnest(cp)%>%
  left_join(ref_cp)%>%
  mutate(cp=cp_shp)%>%
  select(-cp_shp)%>%
  group_by(com,match_com_cp )%>%
  nest()


###'On sauve
##'==================================== 
save(ref_cp,
     ref_iris,
     ref_com,
     corresp_iris_18_20,
     corresp_iris_19_20,
     corresp_com20_cp,
     corresp_cp_com20,
     corresp_com19_cp,
     corresp_cp_com19,
     file="corresp_iris_cp.Rdata")

