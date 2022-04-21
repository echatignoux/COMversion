##======================================================================
### --- data_pack.R ---
##======================================================================
## Auteur: Edouard Chatignoux
## Créé le 2021-10-14
## Dernière mise à jour le 2022-03-28
##======================================================================
##  Description:
##--------------
##' Données internes pour le paquet 
## 
##======================================================================

###'Packages
##'==================================== 
library(data.table)
library(readxl)
library(multidplyr)
library(tidyverse)
library(magrittr)
library(DBI)
library(RSQLite)
library(COMversion)

setwd("./data-raw")

###'Lecture des données
##'==================================== 
####'Commune
##'---------------------------------------- 
dt_pass_com <- readRDS(file="./src/com/dt_pass_com.rds")
dt_scis_com <- readRDS(file="./src/com/dt_scis_com.rds")
dt_fus_com <- readRDS(file="./src/com/dt_fus_com.rds")
dt_pop_com  <- readRDS(file="./src/com/dt_pop_com.rds")

####'Iris
##'---------------------------------------- 
dt_pass_iris<-readRDS(file="./src/iris/dt_pass_iris.rds")
dt_ref_geo<-readRDS(file="./src/iris/ref_iris_com.rds")
w_pass_iris<-readRDS(file="./src/iris/w_pass_iris.rds")

####'Passage iris/cp
##'---------------------------------------- 
p_cp_iris <- readRDS("./src/cp_iris/p_cp_iris.rds")
## On supprime les cases vides
p_cp_iris%<>%
  filter(! substr(iris,1,3) == "976")%>%
  group_by(iris)%>%
  mutate(sump=sum(p_i))%>%
  filter(sump!=0)%>%
  select(-sump)%>%
  ungroup()
## on renormalise par CP (pbs numériques sinon)
p_cp_iris%<>%
  group_by(cp)%>%
  mutate(p_i=p_i/sum(p_i))%>%
  ungroup()

####'Poids de passage com/cp
##'---------------------------------------- 
p_cp_com <- readRDS("./src/cp_com/p_cp_com.rds")
## On supprime les cases vides
p_cp_com%<>%
  filter(!is.na(sexe),!is.na(age))%>%
  filter(! substr(com,1,3) == "976")%>%
  group_by(com)%>%
  mutate(sump=sum(p_c))%>%
  filter(!sump==0)%>%
  select(-sump)%>%
  ungroup()
## on renormalise par CP (pbs numériques sinon)
p_cp_com%<>%
  group_by(cp)%>%
  mutate(p_c=p_c/sum(p_c))%>%
  ungroup()

###'Sauvegarde 
##'=============
## Sélection des pops nécessaires (comunes qui on connu des fusiosn ou scissions)
dt_pop_com%<>%select(annee_pop,annee_geo,com,age,sexe,pop)
com_fs <- c(dt_fus_com%>%select(com_ini,com_fin)%>%unlist()%>%as.character,
  dt_scis_com%>%select(com_ini,com_fin)%>%unlist()%>%as.character)%>%unique

## Plus léger
format(object.size(dt_pop_com),"Gb")
format(object.size(dt_pop_com%>%filter(com %in% com_fs)),"Gb")
format(object.size(p_cp_iris),"Gb")
format(object.size(p_cp_com),"Gb")

format(object.size(dt_fus_com),"Gb")
format(object.size(dt_scis_com),"Gb")
format(object.size(dt_pass_com),"Gb")
format(object.size(dt_pass_iris),"Gb")
format(object.size(dt_ref_geo),"Gb")

dt_pass_iris%<>%mutate_if(is.character,as.factor)
dt_ref_geo%<>%mutate_if(is.character,as.factor)

pass_com <- dt_pass_com
fus_com <- dt_fus_com
scis_com <- dt_scis_com
pop_com<-dt_pop_com%>%filter(com %in% com_fs)%>%select(annee_pop,annee_geo,com,sexe,age,pop)
pass_iris<-dt_pass_iris
ref_geo<-dt_ref_geo

## save(pass_com,fus_com,scis_com,pop_com,pass_iris,p_cp_com,p_cp_iris,
##      file = "./inst/sysdata.rda")
usethis::use_data(pass_com,fus_com,scis_com,pop_com,
                  pass_iris,w_pass_iris,
                  ref_geo,
                  p_cp_com,p_cp_iris,
                  internal = TRUE,overwrite = TRUE)

####'rda
##'---------------------------------------- 
dt_pop_2013 <- dt_pop_com%>%filter(annee_pop==2013)%>%
  mutate(dep=substr(com,1,2))%>%
  select(annee_pop,annee_geo,dep,com,age,sexe,pop)%>%
  arrange(com)
save(dt_pop_2013,file="../data/dt_pop_2013.rda")

setwd("../")

