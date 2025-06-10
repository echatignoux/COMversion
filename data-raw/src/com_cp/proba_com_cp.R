##======================================================================
### --- proba_cp_com.R ---
##======================================================================
## Auteur: Edouard Chatignoux
## Créé le 2020-10-02
## Dernière mise à jour le 2022-03-22
##======================================================================
##  Description:
##--------------
##' Calcul de la proba IRIS|CP à partir du poids en pop de l'IRIS dans
##' le CP.
##' On se base soit sur les recoupements IRIS/CP quand ceux ci se font bien
##' (càd CP = Union d'IRIS), ou à partir des intersections géographiques
##' entre le carroyage de l'INSEE, les CP et les IRIS sinon (càd quand un
##' CP coupe un IRIS).
##======================================================================

###'Packages
##'==================================== 
library(data.table)
library(readxl)
library(multidplyr)
library(DBI)
library(RSQLite)
library(sf)
library(readxl)
library(dtplyr)
library(tidyverse)
library(magrittr)

###'Data ====================================
####'Ref communes 2019 et realtions cp/com  ---------------------------------------- 
path_cp_com<-"./data-raw/src/cp_com/"
ref_com <- readRDS("./data-raw/src/com/ref_com.rds")
dt_com_cp<-readRDS(file.path(path_cp_com,"dt_com_cp.rds"))
dt_cp_com<-readRDS(file.path(path_cp_com,"dt_cp_com.rds"))
####'Poids IRIS'---------------------------------------- 
p_cp_iris <- readRDS("./data-raw/src/cp_iris/p_cp_com_iris.rds")
p_cp_com <- readRDS("./data-raw/src/cp_com/p_cp_com.rds")

###'Calcul des poids 
##'==================================== 
####' Communes avec plusieurs CP (345)  -> on utilise les données IRIS -----
p_com_cp <- p_cp_iris %>%
  rename(p_c=p_i) %>% 
  right_join( 
    dt_com_cp %>%
      filter(n_cp>1) %>% 
      unnest(cp) %>%
      select(cp,com),
    by=c("com","cp"))
## 18 (cp,com) sans corresp d'iris
## (probablement intersection vide avec le carroyage)
## On supprime
p_com_cp %<>% filter(!is.na(iris))

## On mets les classes en âges par année
p_com_cp %<>%
  ungroup()%>%
  select(cp,com,cage,sexe,p_c)%>%
  separate(cage,c("a_min","a_max"))%>%
  mutate(a_max=ifelse(a_max=="P",99,a_max))%>%
  mutate_at(vars(a_min,a_max),as.numeric)

p_com_cp %<>%
  left_join(
    p_com_cp%>%select(a_min,a_max)%>%unique()%>%
    mutate(age=map2(a_min,a_max,function(a_min,a_max) tibble(age=a_min:a_max)%>%mutate(n=n())))%>%
    unnest(age))%>%
  mutate(p_c=p_c/n)%>%
  select(com,cp,sexe,age,p_c)

####' Communes avec un seul CP (34,657)  -> poids = 1
p_com_cp %<>%
  bind_rows(
    dt_com_cp %>%
      filter(n_cp==1) %>% 
      unnest(cp) %>%
      select(cp,com) %>%
      mutate(p_c=1)
  )

p_com_cp %>% group_by(cp) %>% summarise(p_c=round(sum(p_c),1)) %>% filter(p_c!=1)
p_com_cp %>% group_by(com) %>% summarise(p_c=round(sum(p_c),1)) %>% filter(p_c!=1)

###'On sauve
##'==================================== 
saveRDS(p_com_cp,"./data-raw/src/com_cp/p_com_cp.rds")

