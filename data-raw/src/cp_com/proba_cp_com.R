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

###'Lecture données
##'==================================== 
####' Ref 2019
##'---------------------------------------- 
ref_com <- readRDS("./data-raw/src/com/ref_com.rds") %>%
  filter(annee_geo==2019)
ref_cp <- readRDS("./data-raw/src/cp/ref_cp.rds") 

####' Populations communales géo 2019
##'---------------------------------------- 
## Attention : populations données pour géo n+2 jusqu'en 2015, géo n+3 après
pop.path<-"S:/REFERENTIELS/population/Recensements/format_csv"

dt_pop_com<-tibble(annee_pop=2016)%>%
  group_by(annee_pop)%>%
  mutate(pop=map(annee_pop,function(a)
    fread(file.path(pop.path,paste0("recensement_",a,".csv")),
          colClasses = c(com="character",dep="character"))%>%
    as_tibble()%>%
    mutate(population=as.numeric(population)%>%replace_na(0))%>%
    bind_rows(
      haven::read_sas(file.path(pop.path,"../format_sas/detail_arrondisement",
                                paste0("recensement_",a,"arrd.sas7bdat")))%>%
      as_tibble()%>%
      mutate(population=as.numeric(population)%>%replace_na(0)))%>%
    select(annee,sexe,com,dep,age,pop=population)%>%
    mutate(com=paste0(substr(dep,1,2),com)
           )
    ))%>%
  unnest(pop)%>%
  mutate(annee_geo=ifelse(annee_pop>2015,annee_pop+3,annee_pop+2))%>%
  select(-annee_pop)

dt_pop_com%<>%mutate_at(vars(com,dep),as.factor)
dt_pop_com%<>%
  ungroup()%>%
  select(-annee_pop,-dep,-annee)%>%
  filter(!com %in% c("75056","69123","13055"))

## Vérif que c'est bien la géo 2019
dt_pop_com%>%select(com)%>%unique()%>%
  anti_join(ref_com)
ref_com %>%
  anti_join(
    dt_pop_com%>%select(com)%>%unique())
##Ok; manque juste la pop de Mayotte

####'Corresps CP-com
##'---------------------------------------- 
dt_com_cp <- readRDS("./data-raw/src/cp_com/dt_com_cp.rds")
dt_cp_com <- readRDS("./data-raw/src/cp_com/dt_cp_com.rds")

####'Poids IRIS
##'---------------------------------------- 
p_cp_iris <- readRDS("./data-raw/src/cp_iris/p_cp_iris.rds")

###'Calcul des poids 
##'==================================== 
####'CP qui regroupent plusieurs commmunes
##'---------------------------------------- 
dt_cp_com%>%
  filter(match_cp_com,n_com>1)%>%
  unnest(com)%>%
  select(cp,com)%>%
  left_join(dt_pop_com)%>%
  group_by(com)%>%
  mutate(p_cp_c=pop/sum(pop))

dt_com_cp%>%
  filter(match_com_cp)%>%unnest(cp)%>%
  mutate(p_cp_c=1)%>%
  select(cp,com,p_cp_c)

####'CP à cheval -> on utilise les données IRIS
##'---------------------------------------- 
match_coms<-c(dt_com_cp%>%
              filter(match_com_cp)%$%com,
              dt_cp_com%>%
              filter(match_cp_com)%>%
              unnest(com)%$%com)%>%unique

p_cp_iris%>%
  group_by(cp)%>%
  summarise(p_i=sum(p_i))%>%
  filter(p_i<0.9)

##' On calcule les poids de la commune dans le cp
##' tel que la sommme des poids dans le cp vaut 1
p_cp_com<-p_cp_iris%>%
  mutate(com=substr(iris,1,5))%>%
  filter(!com %in% match_coms)

## On mets les classes en âges par année
p_cp_com%<>%
  ungroup()%>%
  select(cp,com,cage,sexe,p_c=p_i)%>%
  separate(cage,c("a_min","a_max"))%>%
  mutate(a_max=ifelse(a_max=="P",99,a_max))%>%
  mutate_at(vars(a_min,a_max),as.numeric)

p_cp_com%<>%
  left_join(
    p_cp_com%>%select(a_min,a_max)%>%unique()%>%
    mutate(age=map2(a_min,a_max,function(a_min,a_max) tibble(age=a_min:a_max)%>%mutate(n=n())))%>%
    unnest(age))%>%
  group_by(cp)%>%
  mutate(p_c=p_c/n)%>%
  group_by(cp)%>%
  mutate(p_c=p_c/sum(p_c))%>% ## On renormalise pour les pbs avec des communes à 0 pop
  ungroup()
  
## On ajoute les cp qui matchent les communes 
p_cp_com%<>%
  bind_rows(
    dt_cp_com%>%
    filter(match_cp_com,n_com>1)%>%
    unnest(com)%>%
    filter(!cp %in% c("21110","21800","45210"))%>%
    select(cp,com)%>%
    left_join(dt_pop_com)%>%
    group_by(cp)%>%
    mutate(p_c=pop/sum(pop)))%>%
  bind_rows(
    dt_com_cp%>%
    filter(match_com_cp)%>%unnest(cp)%>%
    mutate(p_c=1)%>%
    select(cp,com,p_c)
  )%>%
  select(cp,com,age,sexe,p_c)

p_cp_com%>%na.omit()%>%group_by(cp)%>%summarise(p=sum(p_c))%$%range(p)

p_cp_com%<>%lazy_dt%>%arrange(cp,com,age,sexe)%>%as_tibble()
p_cp_com%<>%mutate_if(is.character,as.factor)

p_cp_com %>% group_by(cp) %>% summarise(p_c=sum(p_c))%$%table(p_c)
p_cp_com %>% anti_join(ref_com) %>% filter(!str_sub(com,1,2)=="97")
p_cp_com %>% anti_join(ref_cp) %>% filter(!str_sub(com,1,2)=="97")

###'On sauve
##'==================================== 
saveRDS(p_cp_com,"./data-raw/src/cp_com/p_cp_com.rds")
