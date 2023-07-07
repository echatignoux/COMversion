##======================================================================
### --- dt_iris.R ---
##======================================================================
## Auteur: Edouard Chatignoux
## Créé le 2020-10-06
## Dernière mise à jour le 2022-03-28
##======================================================================
##  Description:
##--------------
##
##
##======================================================================

###'Init
##'====================================
library(readxl)
library(sf)
library(tidyverse)
library(magrittr)
library(readxl)
library(sf)
library(furrr)
library(tidyverse)
library(magrittr)
library(data.table)

path<-"./data-raw/src/iris"

url_zip<-function(url){
  src_dir<-"src"
  if ( !file.exists(src_dir) )
    dir.create(file.path(path,src_dir))
  temp_file<-file.path(path,src_dir,"tmp.zip")
  download.file(url,temp_file)
  unzip(temp_file,exdir = file.path(path,src_dir))
  file.remove(temp_file)
}

###'Référentiel
##'====================================
url_zip("https://www.insee.fr/fr/statistiques/fichier/2017499/reference_IRIS_geo2019.zip")
ref_iris <- read_xls(file.path(path,"./src/reference_IRIS_geo2019.xls"),skip=5)
ref_iris%<>%rename(iris=CODE_IRIS)%>%
  rename_all(tolower)

###'Fichier pop
##'====================================
####' Telechargement des données
##'----------------------------------------
url_zip("https://www.insee.fr/fr/statistiques/fichier/3137409/base-ic-evol-struct-pop-2014.zip")
url_zip("https://www.insee.fr/fr/statistiques/fichier/3627376/base-ic-evol-struct-pop-2015.zip")
url_zip("https://www.insee.fr/fr/statistiques/fichier/4228434/base-ic-evol-struct-pop-2016.zip")
url_zip("https://www.insee.fr/fr/statistiques/fichier/4799309/base-ic-evol-struct-pop-2017.zip")
url_zip("https://www.insee.fr/fr/statistiques/fichier/5650720/base-ic-evol-struct-pop-2018.zip")
url_zip("https://www.insee.fr/fr/statistiques/fichier/6543200/base-ic-evol-struct-pop-2019.zip")
url_zip("https://www.insee.fr/fr/statistiques/fichier/3137409/base-ic-evol-struct-pop-2014-com.zip")
url_zip("https://www.insee.fr/fr/statistiques/fichier/3627376/base-ic-evol-struct-pop-2015-com.zip")
url_zip("https://www.insee.fr/fr/statistiques/fichier/4228434/base-ic-evol-struct-pop-2016-com.zip")
url_zip("https://www.insee.fr/fr/statistiques/fichier/4799309/base-ic-evol-struct-pop-2017-com.zip")
url_zip("https://www.insee.fr/fr/statistiques/fichier/5650720/base-ic-evol-struct-pop-2018-com.zip")
url_zip("https://www.insee.fr/fr/statistiques/fichier/6543200/base-ic-evol-struct-pop-2019-com.zip")


####' Lecture et mise en forme
##'----------------------------------------
get_pop <- function(annee){
  if( annee < 2017){
    dt_pop_iris <- read_xls(file.path(path,paste0("./src/base-ic-evol-struct-pop-",annee,".xls")),skip=5)
    dt_pop_iris_com <- read_xls(file.path(path,paste0("./src/base-ic-evol-struct-pop-",annee,"-com.xls")),skip=5)
    }
  else {
    dt_pop_iris <- read_xlsx(file.path(path,paste0("./src/base-ic-evol-struct-pop-",annee,".xlsx")),skip=5)
    dt_pop_iris_com <- read_xlsx(file.path(path,paste0("./src/base-ic-evol-struct-pop-",annee,"-com.xlsx")),skip=5)
    }

  dt_pop_iris%<>%
    mutate_at(vars(-IRIS,-COM,-LAB_IRIS,-TYP_IRIS),as.numeric)%>%
    bind_rows(
      dt_pop_iris_com%>%
      mutate_at(vars(IRIS,COM,LAB_IRIS),as.character)%>%
      mutate_at(vars(-IRIS,-COM,-LAB_IRIS),as.numeric)
    )%>%
    gather(var,val,-IRIS:-LAB_IRIS)%>%
    filter(str_detect(var,"P[0-9]+\\_"))%>%
    select(iris=IRIS,com=COM,var,val)%>%
    separate(var,c("var","age","var2"),sep="_")

  dt_pop_iris %<>%
    filter(is.na(var2))%>%
    select(-var2)%>%
    mutate(sexe=substr(age,1,1),
           sexe=as.numeric(factor(sexe,levels=c("H","F","P"))),
           age=substr(age,2,nchar(age))
           )

  dt_pop_iris %<>%
    filter(!age %in% c("MEN","HORMEN"))%>%
    mutate(age=gsub("OP","",age))%>%
    mutate(sexe=ifelse(age=="H",1,sexe),
           sexe=ifelse(age=="F",2,sexe),
           age=ifelse(age=="H","",age),
           age=ifelse(age=="F","",age)
           )%>%
    select(-var)%>%
    mutate(age=paste0(substr(age,1,2),"-",substr(age,3,4)))%>%
    rename(pop=val)

  dt_pop_iris %>%
    filter(!age %in% c("00-14","15-29","30-44","45-59","60-74","75-P","00-19","20-64","65-P"))%>%
    mutate(annee_geo = annee + 2)

}

dt_pop <- lapply(2014:2019,get_pop)%>%
  bind_rows()

####' Vérifs
##'----------------------------------------
## Manque Saint-Pierre-et-Miquelon, Saint-Barthélemy et Saint-Martin aux refs iris
setdiff(dt_pop%>%filter(annee_geo==2019)%$%iris%>%unique,ref_iris$iris)
## Manque Mayotte à la pop
setdiff(ref_iris$iris,dt_pop$iris%>%unique)

###'Shape file
##'====================================
####'Shap IRIS
##'----------------------------------------
## https://geoservices.ign.fr/documentation/diffusion/telechargement-donnees-libres.html#contoursiris
## voir la doc : https://geoservices.ign.fr/ressources_documentaires/Espace_documentaire/BASES_VECTORIELLES/CONTOURS_IRIS/SE_Contours-IRIS.pdf
## pour metropole : 2019
## pour St Pierre et Miquelon : 2017
## pour ST Barth et St Martin : 2014
shap_iris_metro <-
    read_sf("./src/shap_iris2021/CONTOURS-IRIS.shp")
shap_iris_guad <-
    read_sf("./src/CONTOURS-IRIS_2-1_SHP_UTM20W84GUAD_GLP-2018/CONTOURS-IRIS.shp")
shap_iris_mart <-
  read_sf("./src/CONTOURS-IRIS_2-1_SHP_UTM20W84MART_MTQ-2018/CONTOURS-IRIS.shp")
shap_iris_may <-
  read_sf("./src/CONTOURS-IRIS_2-1_SHP_RGM04UTM38S_MYT-2018/CONTOURS-IRIS.shp")
shap_iris_reu <-
  read_sf("./src/CONTOURS-IRIS_2-1_SHP_RGR92UTM40S_REU-2018/CONTOURS-IRIS.shp")
shap_iris_guy <-
  read_sf("./src/CONTOURS-IRIS_2-1_SHP_UTM22RGFG95_GUF-2018/CONTOURS-IRIS.shp")
## St Pierre et Miquelon - 2017
shap_iris_975 <-
    read_sf( "./src/CONTOURS-IRIS_2-1_SHP_RGSPM06U21_SPM-2018/CONTOURS-IRIS.shp"  )
## SAINT-BARTHELEMY 977 - 2014
shap_iris_977 <-
  read_sf( dsn = "S:/alerte/Coronavirus_2020/3-Surveillance/SIDEP/INDICATEURS SpF/R/Prepare_data/IRIS/CONTOURS-IRIS_2-0__SHP_LAMB93_FXX2014_2014-01-01/CONTOURS-IRIS/1_DONNEES_LIVRAISON_2014/CONTOURS-IRIS_2-0_SHP_UTM20W84GUAD_D977-2014", layer="CONTOURS-IRIS_D977"  )
## SAINT-MARTIN 978 - 2014
shap_iris_978 <- read_sf( dsn = "S:/alerte/Coronavirus_2020/3-Surveillance/SIDEP/INDICATEURS SpF/R/Prepare_data/IRIS/CONTOURS-IRIS_2-0__SHP_LAMB93_FXX2014_2014-01-01/CONTOURS-IRIS/1_DONNEES_LIVRAISON_2014/CONTOURS-IRIS_2-0_SHP_UTM20W84GUAD_D978-2014",
                         layer="CONTOURS-IRIS_D978"  )

## Shape global
shap_iris <-
  list(
      shap_iris_metro,
      shap_iris_guad,
      shap_iris_mart,
      shap_iris_may,
      shap_iris_reu,
      shap_iris_guy,
      shap_iris_975,
      shap_iris_977%>%rename(INSEE_COM=DEPCOM)%>%mutate(CODE_IRIS=paste0(INSEE_COM,IRIS)),
      shap_iris_978%>%rename(INSEE_COM=DEPCOM)%>%mutate(CODE_IRIS=paste0(INSEE_COM,IRIS))
      )%>%bind_rows()%>%
  select(iris=CODE_IRIS,lib_iris=NOM_IRIS,com=INSEE_COM,geometry)

setdiff(shap_iris$iris%>%unique,dt_pop$iris%>%unique)
setdiff(ref_iris$iris,dt_pop$iris%>%unique)


###'Passage entre les millésimes
##'====================================
####'Lecture des tables
##'----------------------------------------
read_iris<-function(annee){
  if (annee>=2016)
    url<-paste0("https://www.insee.fr/fr/statistiques/fichier/2017499/reference_IRIS_geo",annee,".zip")
  else
    url<-paste0("https://www.insee.fr/fr/statistiques/fichier/2017499/IRIS_table_geo",annee,".zip")
  url_zip(url)
  file<-grep(paste0("reference_IRIS_geo",annee),dir(file.path(path,"./src")),value=T)
  if (str_detect(file,".xlsx$")){
    dt_ref<-read_xlsx(file.path(path,"./src",file),skip=5,sheet=1)
    if(annee>=2016)
      dt_modif<-read_xlsx(file.path(path,"./src",file),skip=5,sheet="Modifications_IRIS")%>%
        rename_all(tolower)%>%
        select(annee_modif,
               modif_iris,
               iris_ini,
               iris_fin,
               com_ini,
               com_fin
               )
  }
  else{
    dt_ref<-read_xls(file.path(path,"./src",file),skip=5-(annee==2013),sheet=1)
    if(annee>=2016)
      dt_modif<-read_xls(file.path(path,"./src",file),skip=5,sheet="Modifications_IRIS")%>%
        rename_all(tolower)%>%
        select(annee_modif,
               modif_iris,
               iris_ini,
               iris_fin,
               com_ini,
               com_fin
               )
  }
  if(annee<2016) dt_modif<-NULL

  tibble(annee_geo=annee)%>%
    mutate(dt_modif=list(
               dt_modif),
           dt_ref = list(dt_ref%>%
                         rename_all(tolower)%>%
                         select(iris=code_iris,lib_iris,com=depcom,everything())))
}
tab_iris<-lapply(2008:2022,read_iris)%>%
  bind_rows()

####'Table de référence géo (com + iris)
##'----------------------------------------
## https://www.insee.fr/fr/information/2434332
dt_ref_geo <- tab_iris%>%
  select(annee_geo,dt_ref)%>%
  unnest()%>%
  unique%>%
  select(annee_geo,iris,lib_iris,com,lib_com=libcom)

dt_pass_iris<-tab_iris%>%
  select(-dt_ref)%>%
  unnest(dt_modif)%>%
  filter(annee_geo==annee_modif)%>%
  select(-annee_modif)

shap_iris2016<-read_sf(file.path(path,"./src/shap_iris2016/CONTOURS-IRIS.shp"))%>%
  select(com=INSEE_COM,iris=CODE_IRIS)
shap_iris2017<-read_sf(file.path(path,"./src/shap_iris2017/CONTOURS-IRIS.shp"))%>%
  select(com=INSEE_COM,iris=CODE_IRIS)
shap_iris2018<-read_sf(file.path(path,"./src/shap_iris2018/CONTOURS-IRIS.shp"))%>%
  select(com=INSEE_COM,iris=CODE_IRIS)
shap_iris2019<-read_sf(file.path(path,"./src/shap_iris2019/CONTOURS-IRIS.shp"))%>%
  select(com=INSEE_COM,iris=CODE_IRIS)
shap_iris2020<-read_sf(file.path(path,"./src/shap_iris2020/CONTOURS-IRIS.shp"))%>%
  select(com=INSEE_COM,iris=CODE_IRIS)
shap_iris2021<-read_sf(file.path(path,"./src/shap_iris2021/CONTOURS-IRIS.shp"))%>%
  select(com=INSEE_COM,iris=CODE_IRIS)
shap_iris2022<-read_sf(file.path(path,"./src/shap_iris2022/CONTOURS-IRIS.shp"))%>%
  select(com=INSEE_COM,iris=CODE_IRIS)


####'Travail sur la table de passage
##'----------------------------------------
##' La table de passage est affreuse et doit
##' être retravillée...
##' Ce qui est fait ici
##' Par exemple, dans l'onglet  modif_iris de la table de référnce de 2017, il est dit que les communes 77166, 77170 et 77299 fusionnent avec la commune 77316,
##' ce qui n'est pas le cas en 2017, mais en 2016.
##' 
##' 2017	773160000	77316	Moret-Loing-et-Orvanne	773160101	77316	Moret-Loing-et-Orvanne	2	Déplacement de limites
##' 2017	771660000	77166	Écuelles	        773160102	77316	Moret-Loing-et-Orvanne	3	Rétablissement/Fusion de communes irisées
##' 2017	771700000	77170	Épisy	                773160102	77316	Moret-Loing-et-Orvanne	3	Rétablissement/Fusion de communes irisées
##' 2017	772990000	77299	Montarlot	        773160102	77316	Moret-Loing-et-Orvanne	3	Rétablissement/Fusion de communes irisées
##'
##' D'autres soucis au cas par cas (voir plus bas dans le code)

source(file.path(path,"../../../R/pass_com.R"))
source(file.path(path,"../../../R/pass_geo.R"))
fus_com<-readRDS(file.path(path,"../com/dt_fus_com.rds"))
scis_com<-readRDS(file.path(path,"../com/dt_scis_com.rds"))
pop_com<-readRDS(file.path(path,"../com/dt_pop_com.rds"))
pass_com<-readRDS(file.path(path,"../com/dt_pass_com.rds"))

dt_pass<-dt_pass_iris%>%filter(! (modif_iris==4 & iris_ini == iris_fin) )

pass_iris<-function(geo){

  geo_in<-geo
  geo_out<-geo+1

  ## Liste des iris en in et en out
  ref_fwd<-
    dt_ref_geo%>%
    filter(annee_geo==geo_in)%>%
    select(com,iris)%>%
    mutate(inn=TRUE)%>%
    full_join(
      dt_ref_geo%>%filter(annee_geo==geo_in+1)%>%
        select(com,iris)%>%mutate(out=TRUE)
    )
  
    out <- pass_com.w(geo_in,
                      geo_out,
                      by=~1)

 
  # Pas de modification d'IRIS dans la commune ###
  match1 <-
    ref_fwd %>% 
    group_by(com) %>%
    filter(out,inn)%>%
    mutate(com_fin=com,iris_fin=iris,match=1)%>%
    select(com,iris,com_out=com_fin,iris_out=iris_fin,match)

  # Modification de numéro d'IRIS dans les communes non irisées ###
  match2 <-
    ref_fwd %>% 
    group_by(com) %>%
    filter(sum(inn, na.rm = T ) == 1, sum(out, na.rm = T ) ==1, n()>1)

  match2 %<>%
    filter(inn) %>%
    select(com, iris) %>%
    left_join( match2 %>%
                 filter(out) %>%
                 select(com, iris_out = iris)
              ) %>%
    mutate(com_out=com) %>% 
    mutate(match=2)

  ## Fusion de communes non irisées ###
  match3<-
    ref_fwd%>%
    filter(is.na(out))%>%
    inner_join(
      out%>%
        filter(statut=="Fusion")%>%
        left_join(dt_ref_geo%>%filter(annee_geo==geo+1)%>%select(com_out=com,iris_out=iris))%>%
        filter(com != com_out)%>%
        group_by(com)%>%
        filter(n()==1)
    ) %>%
    mutate(match=3)%>%
    select(com,iris,com_out,iris_out,match) %>%
    arrange(iris_out)

  ## Scissions de communes
  match4<-
    ref_fwd%>%
    filter(is.na(inn) & !is.na(out))%>%
    rename(com_out=com,iris_out=iris)%>%
    inner_join(out%>%filter(statut=="Scission"))%>%
    left_join(dt_ref_geo%>%filter(annee_geo==geo))%>%
    mutate(match=4)%>%
    select(com,iris,com_out,iris_out,match)

  ## Création d'IRIS dans des communes non irisées jusque là
  match5<-
    ref_fwd %>% 
    group_by(com) %>%
    filter(sum(inn,na.rm=T) ==1,
           sum(out,na.rm=T) >1) %>%
    arrange(com) 

  match5 %<>%
    filter(inn) %>%
    select(com, iris) %>%
    left_join( match5 %>%
                 filter(out) %>%
                 select(com, iris_out = iris)
              ) %>%
    mutate(com_out=com) %>% 
    mutate(match=5)

  ## Bilan temporaire
  ref_tmp<-
    match1%>%
    bind_rows(match2)%>%
    bind_rows(match3)%>%
    bind_rows(match4)%>%
    bind_rows(match5) %>% 
    unique()

  ## Modification d'iris documentée dans la table des modifs ###
  match6 <-
    ref_fwd%>%
    anti_join(ref_tmp %>%
                select(com,iris)) %>% 
    filter(is.na(out)) %>% 
    anti_join(ref_tmp %>%
                select(com=com_out,iris=iris_out)) 

  match6 %<>%
    left_join(
      dt_pass%>%
        filter(annee_geo==geo+1)%>%
        rename(iris=iris_ini,com=com_ini)
    )%>%
    filter(!is.na(annee_geo))%>%
    select(com,iris,com_out=com_fin,iris_out=iris_fin)%>%
    inner_join(out)%>%
    select(com,iris,com_out,iris_out)%>%
    mutate(match=6)

  ## Modification d'iris non documentée dans la table des modifs ###
  ref_tmp<-
    match1%>%
    bind_rows(match2)%>%
    bind_rows(match3)%>%
    bind_rows(match4)%>%
    bind_rows(match5)%>%
    bind_rows(match6)%>%
    unique()

  match7<-
    ref_fwd%>%
    anti_join(ref_tmp %>%
                select(com,iris))

  match7%<>%
    filter(is.na(out))%>%
    left_join(dt_pass%>%filter(annee_geo==geo+1)%>%rename(iris=iris_ini,com=com_ini))%>%
    filter(is.na(annee_geo))%>%
    left_join(out)
  match7%$%table(statut)

  match7 %<>%
    select(com,iris,com_out)%>%
    left_join(dt_ref_geo%>%
                filter(annee_geo==geo+1)%>%
                select(com_out=com,iris_out=iris)
              ) %>%
    mutate(match=7)

  ## Attention, certains num d'iris correspondent à d'anciens IRIS. On les cherche ici.
  if (nrow(match7)>0)
    match7%<>%
      group_by(com,iris,com_out)%>%
      mutate(seek_old=n()>1)%>%
      group_by(seek_old)%>%
      nest()%>%
      mutate(data=map2(data,seek_old,
                       function(data,seek_old){
                         if (seek_old)
                           data%<>%left_join(
                             dt_pass%>%select(iris=iris_fin,com=com_fin,iris_ini)%>%
                               left_join(dt_pass%>%select(iris_ini,iris_fin))%>%
                               select(-iris_ini)%>%unique()
                           )%>%filter(iris_out==iris_fin)
                         data
                       }))%>%
      unnest(data)%>%
      ungroup()%>%
      select(com,iris,com_out,iris_out,match)

  ## Utilisation de shapefiles
  ref_tmp<-
    match1%>%
    bind_rows(match2)%>%
    bind_rows(match3)%>%
    bind_rows(match4)%>%
    bind_rows(match5)%>%
    bind_rows(match6)%>%
    bind_rows(match7)%>%
    unique()

  match8<-
    ref_fwd%>%
    filter(is.na(inn) & !is.na(out))%>%
    anti_join(ref_tmp %>%
                select(com=com_out,iris=iris_out)) %>%
    select(-inn, -out)

  if (nrow(match8)>0){

    shap_in<-get(paste0("shap_iris",geo))%>%
      inner_join(match8%>%select(com)%>%unique())%>%
      mutate(area_in = st_area(geometry))
    shap_out<-get(paste0("shap_iris",geo+1))%>%
      inner_join(match8%>%select(com)%>%unique())%>%
      mutate(area_out = st_area(geometry))%>%
      rename(iris_out=iris)

    match8 <- st_intersection(shap_in, shap_out) %>%
      mutate(int_area = st_area(.)) %>%   # create new column with shape area
      select(com, iris, iris_out, area_in, area_out, int_area) %>%   # only select columns needed to merge
      st_drop_geometry()  %>%
      mutate(pct_in = as.numeric(int_area/area_in),
             pct_out = as.numeric(int_area/area_out)
             )%>%
      filter(pct_out>.9)%>%
      select(com,iris,iris_out)%>%
      filter(iris!=iris_out)%>%
      anti_join(ref_tmp)%>%
      mutate(match=8)%>%
      mutate(com_out=com)

  }

  pass<-
    match1%>%
    bind_rows(match2)%>%
    bind_rows(match3)%>%
    bind_rows(match4)%>%
    bind_rows(match5)%>%
    bind_rows(match6)%>%
    bind_rows(match7)%>%
    bind_rows(match8)%>%
    unique() 

  ref_fwd %>% filter(inn) %>% anti_join(pass)
  ref_fwd %>% filter(out) %>% select(iris_out = iris) %>% anti_join(pass)

  pass
}

dt_pass_iris <- tibble(annee_geo=2016:2021) %>%
  mutate(pass=map(annee_geo,pass_iris)) %>%
  unnest(pass)

dt_pass_iris %$% table(match)

## Doublons?
dt_pass_iris%>%
  group_by(annee_geo,com,iris,com_out,iris_out)%>%
  filter(n()>1)
## ok

dt_pass_iris%<>%
  group_by(com,iris,annee_geo,com_out)%>%
  mutate(match=max(match))%>%
  ungroup()

## dt_pass_iris%<>%select(-match)


####'Vérifications
##'----------------------------------------
## pass_in dans ref
dt_pass_iris%>%
  select(com,iris,annee_geo)%>%
  anti_join(dt_ref_geo)

dt_pass_iris%>%
  select(com=com_out,iris=iris_out,annee_geo)%>%
  mutate(annee_geo = annee_geo +1 )%>%
  anti_join(dt_ref_geo)

dt_ref_geo%>%
  filter(annee_geo %in% 2016:2021)%>%
  anti_join(
    dt_pass_iris%>%
    select(com,iris,annee_geo)
  )%$%table(annee_geo)

dt_ref_geo%>%
  filter(annee_geo %in% 2017:2022)%>%
  anti_join(
    dt_pass_iris%>%
    select(com=com_out,iris=iris_out,annee_geo)%>%
    mutate(annee_geo = annee_geo +1 )
  )
## Ok

## Scissions de communes
dt_pass_iris%>%
  select(com,com_out,annee_geo)%>%
  unique()%>%
  group_by(com,annee_geo)%>%
  mutate(n=n())%>%
#  filter(com=="55298")
  filter(n>1)%>%
  arrange(com)
readRDS(file.path(path,"../com/dt_scis_com.rds"))%>%filter(annee_modif>2016)
## Ok

## Fusions de communes
fus_iris<-
  dt_pass_iris%>%
  select(com,com_out,annee_geo)%>%
  unique()%>%
  group_by(com_out,annee_geo)%>%
  mutate(n=n())%>%
  filter(n>1)%>%
  arrange(com_out)%>%
  mutate(annee_geo=as.character(annee_geo+1))

fus_iris%>%
  anti_join(
    readRDS(file.path(path,"../com/dt_fus_com.rds"))%>%
    mutate(annee_geo=annee_modif)%>%
    rename(com=com_ini,com_out=com_fin))

readRDS(file.path(path,"../com/dt_fus_com.rds"))%>%
  filter(annee_modif %in% 2017:2022)%>%
  mutate(annee_geo=annee_modif)%>%
  rename(com=com_ini,com_out=com_fin)%>%
  anti_join(
    fus_iris
  )

fus_iris%>%filter(com=="27058")
dt_pass_iris%>%filter(com=="27058")

readRDS(file.path(path,"../com/dt_fus_com.rds"))%>%filter(com_fin=="01095")

####'Poids de passage pour les iris modifiés hors communes
##'----------------------------------------
## Forward
pass_fwd <- dt_pass_iris%>%
  group_by(iris,com_out,com,annee_geo)%>%
  mutate(n=n())%>%filter(n>1)%>%arrange(iris)
w_fwd<-dt_pop%>%
  rename(com_out=com,iris_out=iris)%>%
  mutate(annee_geo=annee_geo-1)%>%
  right_join(pass_fwd%>%ungroup()%>%select(iris_out,annee_geo)%>%unique)%>%
  filter(!(sexe=="3" & age == "-"))
w_fwd%<>%
  filter(age=="-")%>%
  mutate(p_s=pop)%>%
  select(-age,-pop)%>%
  left_join(
    w_fwd%>%
    filter(sexe==3)%>%
    mutate(p_a=pop)%>%
    select(-sexe,-pop)
  )
w_fwd%<>%
  right_join(pass_fwd)%>%
  group_by(iris_out,annee_geo,age)%>%
  mutate(p_s=p_s/sum(p_s))%>%
  group_by(iris,annee_geo,sexe)%>%
  mutate(p_a=p_a/sum(p_a))%>%
  ungroup()%>%
  mutate(p_pass=p_s*p_a)%>%
  select(iris,iris_out,com,com_out,sexe,cage=age,p_pass,annee_geo)

## Backward
pass_bwd <- dt_pass_iris%>%
  rename(iris_tmp=iris,com_tmp=com)%>%
  rename(iris = iris_out, com = com_out,
         iris_out = iris_tmp, com_out = com_tmp)%>%
  group_by(iris,com_out,com,annee_geo)%>%
  mutate(n=n())%>%filter(n>1)%>%arrange(iris)

w_bwd<-dt_pop%>%
  rename(com_out=com,iris_out=iris)%>%
  mutate(annee_geo=annee_geo)%>%
  right_join(pass_bwd%>%ungroup()%>%select(iris_out,annee_geo)%>%unique)%>%
  filter(!(sexe=="3" & age == "-"))

w_bwd%<>%
  filter(age=="-")%>%
  mutate(p_s=pop)%>%
  select(-age,-pop)%>%
  left_join(
    w_bwd%>%
    filter(sexe==3)%>%
    mutate(p_a=pop)%>%
    select(-sexe,-pop)
  )

w_bwd%<>%
  right_join(pass_bwd)%>%
  group_by(iris_out,annee_geo,age)%>%
  mutate(p_s=p_s/sum(p_s))%>%
  group_by(iris,annee_geo,sexe)%>%
  mutate(p_a=p_a/sum(p_a))%>%
  ungroup()%>%
  mutate(p_pass=p_s*p_a)%>%
  mutate(annee_geo=annee_geo+1)%>%
  select(iris,iris_out,com,com_out,sexe,cage=age,p_pass,annee_geo)

## Des poids à NA pour les IRIS sans pop ; on met des 0.
w_pass_iris<-
  tibble(forward = list(w_fwd%>%mutate(p_pass=ifelse(is.na(p_pass),0,p_pass))),
         backward = list(w_bwd%>%mutate(p_pass=ifelse(is.na(p_pass),0,p_pass))))


###'Ref iris
##'==================================== 
ref_iris <- tab_iris %>%
  select(annee_geo,dt_ref) %>%
  unnest(dt_ref) %>%
  select(annee_geo, com, iris, lib_iris) %>%
  mutate(com = str_sub(iris, 1, 5))

## Chek avec la ref com
ref_com <- readRDS(file.path(path,"../com/ref_com.rds"))
ref_iris %>% anti_join(ref_com)
ref_com %>% filter(annee_geo>=2008,annee_geo<2023,str_sub(com,1,2)!="97") %>% anti_join(ref_iris)


###'On sauve
##'====================================
saveRDS(dt_pop %>% filter(annee_geo == 2019),file=file.path(path,"pop_iris_2019.rds"))
saveRDS(ref_iris,file=file.path(path,"ref_iris.rds"))
saveRDS(dt_pass_iris,file=file.path(path,"dt_pass_iris.rds"))
saveRDS(w_pass_iris,file=file.path(path,"w_pass_iris.rds"))
saveRDS(tab_iris,file=file.path(path,"tab_iris.rds"))
saveRDS(dt_ref_geo,file=file.path(path,"ref_iris_com.rds"))



