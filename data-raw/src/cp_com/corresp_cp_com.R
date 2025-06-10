##======================================================================
### --- corresp_cp_com.R ---
##======================================================================
## Auteur: Edouard Chatignoux
## Créé le 2022-03-17
## Dernière mise à jour le 2022-03-22
##======================================================================
##  Description:
##--------------
## 
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
library( furrr )
plan(multisession, workers = 4)
library(progressr)

###'Ref communes 2019
##'====================================
path<-"./data-raw/src/cp_com/"
ref_com <- readRDS("./data-raw/src/com/ref_com.rds") %>%
  filter(annee_geo==2019)

###'Table de correspondance communes/cp
##'==================================== 
####'Lecture et mef de la table
##'---------------------------------------- 
dt_cp_com<-read.csv("S:/REFERENTIELS/nomenclature/geographie/code_postal/old/t-corresp-cp.csv", sep=",", encoding = "latin1",colClasses = "character")%>%
  as_tibble()
dt_cp_com<-dt_cp_com%>%
  select(-source,-date_maj)%>%
  mutate(com=map(as.character(liste_com19_code),~ strsplit(.," ; ")[[1]]))%>%
  mutate(com_lib=map(as.character(liste_com19_lib),~ strsplit(.," ; ")[[1]]))%>%
  select(-liste_com19_code)%>%
  rename(cp_lib=liste_com19_lib)%>%
  mutate(com=map2(com,com_lib,function(com,com_lib) tibble(com=com,com_lib=com_lib)))%>%
  select(-com_lib)%>%
  rename(cp=cp_code)%>%
  select(-cp_lib)  

## 3 communes, fusionnées début 2019 manquent à l'appel...
dt_cp_com%>%unnest(com)%>%
  anti_join(ref_com%>%select(com))
ref_com%>%select(com)%>%
  anti_join(dt_cp_com%>%unnest(com))
## On les rajoute à la main
add_coms<-
  ref_com%>%
  select(com)%>%
  anti_join(dt_cp_com%>%unnest(com))%>%
  mutate(cp=case_when(com=="21507"~"21110",
                      com=="21213"~"21800",
                      com=="45287"~"45210"
                      ))

dt_cp_com%<>%
  select(-nb_com19)%>%
  unnest(com)%>%
  bind_rows(add_coms)%>%
  group_by(cp)%>%
  mutate(nb_com19=n())%>%
  group_by(cp,nb_com19)%>%
  nest()%>%
  rename(com=data)%>%
  ungroup()

####'Match commmune -> CP
##'----------------------------------------
##' Indicatrice à TRUE si l'union des communes du CP est le CP
##' i.e. que toutes les communes du CP n'appartiennent qu'au CP
##' ATTENTION : un peu long (+ 6 000 cp...); truc qui cloche avec furrr...
dt_cp_com%<>%
  mutate(match_cp_com=
           furrr::future_map2(cp,com,function(cpp,comu)
             sum(comu$com %in%
                   (dt_cp_com%>%
                      filter(cp != cpp)%>%
                      unnest(com)%$%com))==0
             ))%>%
  mutate(match_cp_com=map_lgl(match_cp_com,~.[[1]]))

dt_cp_com%>%filter(match_cp_com)
dt_cp_com[1,]%>%unnest(com)%$%com->cc
dt_cp_com%>%unnest(com)%>%filter(com %in% cc)%$%cp%>%unique

dt_cp_com%>%filter(!match_cp_com)%>%.[1,]%>%unnest(com)%$%com->cc
dt_cp_com%>%unnest(com)%>%filter(com %in% cc)%$%cp%>%unique
dt_cp_com%>%filter(cp=="01460")%>%unnest(com)%$%com

dt_cp_com%>%filter(!match_cp_com)
## 685 codes postaux (sur 6,187), pour lesquels les communes inclues dans le
## CP n'appartiennent pas qu'au CP
## Ce qui revient à dire que ces CP coupent des communes en 2

####'Match CP -> commmune
##'----------------------------------------
##' Indicatrice à TRUE si l'union des CP de la commune est la commune
##' i.e. que toutes les CP de la commune n'appartiennent qu'à la commune
dt_com_cp<-
  dt_cp_com%>%
  unnest(com)%>%
  select(cp,com)%>%
  group_by(com)%>%
  nest()%>%
  rename(cp=data)%>%
  mutate(cp=map(cp,unlist))%>%
  ungroup()

dt_com_cp%<>%
  mutate(n_cp=map_dbl(cp,~length(.x)))

with_progress({
  p <- progressor(steps = nrow(dt_com_cp))
  dt_com_cp%<>%
    ungroup%>%
    mutate(i=row_number())%>%
    mutate(match_com_cp=
             furrr::future_pmap(list(com,cp,i),function(comu,cp,i){
               p()
               sum(cp %in%
                   (dt_com_cp%>%
                    filter(com != comu)%$%cp%>%unlist))==0
             }
             ))%>%
    mutate(match_com_cp=map_lgl(match_com_cp,~.[[1]]))%>%
    select(-i)
})

dt_cp_com%<>%
  mutate(n_com = as.numeric(nb_com19))%>%
  select(cp,com,n_com,match_cp_com)

###'On sauve
##'====================================
saveRDS(dt_com_cp,file.path(path,"dt_com_cp.rds"))
saveRDS(dt_cp_com,file.path(path,"dt_cp_com.rds"))
