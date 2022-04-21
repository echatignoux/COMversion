##======================================================================
### --- data_cp.R ---
##======================================================================
## Auteur: Edouard Chatignoux
## Créé le 2020-06-12
## Dernière mise à jour le 2022-03-22
##======================================================================
##  Description:
##--------------
##' Liste de codes CP  
## 
##======================================================================

library( lubridate )
library( pryr )
library( tidyverse )
library( RPostgreSQL )
library( stringr )
library( ISOweek )
library( rlang )
library( magrittr )
library( rmarkdown )
library( haven )
library( sf )

url_zip<-function(url){
  src_dir<-"src"
  if ( !file.exists(src_dir) )
    dir.create(src_dir)
  temp_file<-file.path(src_dir,"tmp.zip")
  download.file(url,temp_file)
  unzip(temp_file,exdir = src_dir)
  file.remove(temp_file)
}

###'Lecture des données
##'==================================== 
####'Ref
##'----------------------------------------
ref_cp<-read_csv2("https://datanova.laposte.fr/explore/dataset/laposte_hexasmal/download/?format=csv&timezone=Europe/Berlin&lang=fr&use_labels_for_header=true&csv_separator=%3B")
ref_cp%<>%
  rename( com=Code_commune_INSEE, code_postal=Code_postal, nom_com=Nom_commune )

## Supprimer les COMs en 98
ref_cp %<>% filter( ! substr( com,1,2) %in% c(98, 99 ))

## Vérification qu'on a bien Saint-Martin, Saint Barthélémy, ST PIERRE ET MIQUELON et Mayotte
ref_cp %>% filter(code_postal %in% c("97150","97133"))
ref_cp %>% filter(substr(code_postal,1,3)==976)
ref_cp %>% filter(substr(com,1,3)==975)

ref_cp%<>%
  select( cp = code_postal)%>%
  unique()

####'Shapes
##'---------------------------------------- 
## Shape de Jerome Pouey pour les DROMS; Emc3 pour métro
## https://www.data.gouv.fr/fr/datasets/fond-de-carte-des-codes-postaux/#resources
chem <- "src/CP_SHP/"
## Shap de Emc3 màj 2019
shap_metro <- st_read( dsn = paste0( chem, "metropole_emc3_2020" ), layer="codes_postaux_region", stringsAsFactors = F )
## Shape de Jerome Pouey
shap_971 <- st_read( paste0( chem, "971/codes_postaux.shp" ), stringsAsFactors=F ) #  +proj=utm +zone=20 +ellps=WGS84 +units=m +no_defs
shap_972 <- st_read( paste0( chem, "972/codes_postaux.shp" ), stringsAsFactors=F ) #   +proj=utm +zone=20 +ellps=WGS84 +units=m +no_defs
shap_973 <- st_read( paste0( chem, "973/codes_postaux.shp" ), stringsAsFactors=F ) #+proj=utm +zone=22 +ellps=GRS80 +units=m +no_defs
shap_974 <- st_read( paste0( chem, "974/codes_postaux.shp" ), stringsAsFactors=F )  #+proj=utm +zone=40 +south +ellps=GRS80 +units=m +no_defs
shap_975 <- st_read( paste0( chem, "975/codes_postaux.shp" ), stringsAsFactors=F ) #Projection WGS84
shap_976 <- st_read( paste0( chem, "976/codes_postaux.shp" ), stringsAsFactors=F ) # +proj=utm +zone=38 +south +ellps=GRS80 +units=m +no_defs
shap_977_978 <- st_read( paste0( chem, "977_978/DEPARTEMENT.shp" ), stringsAsFactors=F ) #Projection WGS84 (long-lat universelle, à utiliser pour le merge)

## Les départements de St Martin et St Barth contiennent chacun un seul code postal  "97150"=St MArtin, "97133 = St Barth
shap_977_978 <- shap_977_978 %>% mutate( 
  ID = ifelse( INSEE_DEP == 978, "97150", "97133" ) 
  ) %>%
  rename( LIB = 'NOM_DEP',
          DEP = "INSEE_DEP"
          ) %>%
dplyr::select( -INSEE_REG )

list_shap <- ls( ) %>% str_subset( "shap_" )

map_cp <- NULL
for( nom_shap in list_shap ){
  print( nom_shap )
  ss <- st_transform( get( nom_shap ), crs='+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0'  ) %>% mutate_if(is.factor, as.character)
  
  if( nom_shap %in% paste0( "shap_", 971:976 ) ){
    ss  <- ss %>% dplyr::select( -POINT_X, -POINT_Y )
  }
  map_cp  <- bind_rows( map_cp , ss )
}

shap_cp <- map_cp %>% select( cp = ID, lib_cp = LIB, dep = DEP)

###'Vérifications
##'==================================== 
## Différence shape et liste cp

setdiff(shap_cp$cp,ref_cp$cp)
## "97610" "74480" en plus dans le shape
##' Le code postal 74480 n'est pas dans les références...
##' On remplace par le 74190
##' https://fr.wikipedia.org/wiki/Passy_(Haute-Savoie)
shap_cp<-shap_cp%>%
  mutate(cp=ifelse(cp=="74480","74190",as.character(cp)))

setdiff(ref_cp$cp,shap_cp$cp)
## Manque Mayotte + qq uns

###'On sauve
##'==================================== 
saveRDS( ref_cp,"./ref_cp.rds")
saveRDS( shap_cp, "./shap_cp.rds" )


###'En plus (département des CP)
##'==================================== 

# Départements des CP
cp<-cp%>%
  mutate(dep=substr(com,1,2))%>%
  mutate(dep=ifelse(dep=="97",substr(com,1,3),dep))

cp_a_cheval <- cp %>%
  left_join(dt_pop%>%group_by(com)%>%summarise(pop=sum(population)))%>%
  mutate( 
    dep_com = dep ) %>%
  group_by( code_postal , dep_com) %>%
  summarise( n=n(), pop=sum(pop) ) %>%
  mutate( n_dep = length( dep_com ) ) %>%
  filter( n_dep > 1 ) %>%
  ungroup() %>%
  arrange( desc( n_dep, n ) )

#' On se créé une base finale de CP, avec comme
#' département celui avec la plus grande pop pour les chevaux

## libellés des CP
lib_cp<-cp%>%
  group_by(code_postal)%>%
  summarise(lib_cp=paste0(unique(nom_com),collapse="/"))

dt_cp<-cp%>%
  mutate(dep=ifelse(is.na(dep),substr(com,1,3),dep))%>%
  left_join(dt_pop%>%group_by(com)%>%summarise(pop=sum(population)))%>%
  group_by( code_postal , dep) %>%
  summarise(pop=sum(pop)) %>%
  group_by( code_postal)%>%
  arrange(code_postal,desc(pop))%>%
  slice(1)%>%
  left_join(lib_cp)%>%
  select(-pop)
