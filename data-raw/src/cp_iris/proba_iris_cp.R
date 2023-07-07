##======================================================================
### --- proba_iris_cp.R ---
##======================================================================
## Auteur: Edouard Chatignoux
## Créé le 2020-10-02
## Dernière mise à jour le 2022-03-27
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

###'Init
##'==================================== 
library(sf)
library(readxl)
library(dtplyr)
library(tidyverse)
library(gridExtra)

url_zip<-function(url){
  src_dir<-"./data-raw/src/cp_iris/src"
  if ( !file.exists(src_dir) )
    dir.create(src_dir)
  temp_file<-file.path(src_dir,"tmp.zip")
  download.file(url,temp_file)
  unzip(temp_file,exdir = src_dir)
  file.remove(temp_file)
}

###'Référentiels + pop
##'==================================== 
####'Ref
##'---------------------------------------- 
ref_com<-readRDS("./data-raw/src/com/ref_com.rds") %>% filter(annee_geo==2019)
ref_iris<-readRDS("./data-raw/src/iris/ref_iris.rds") %>% filter(annee_geo==2019)
ref_cp<-readRDS("././data-raw/src/cp/ref_cp.rds")%>%arrange(cp)

####'Pop
##'---------------------------------------- 
pop_iris<-readRDS("./data-raw/src/iris/pop_iris_2019.rds")
pop_iris<-readRDS("./data-raw/src/iris/dt_pop_iris.rds")

###'Correspondance cp-com
##'==================================== 
dt_com_cp<-readRDS("./data-raw/src/cp_com/dt_com_cp.rds")
dt_cp_com<-readRDS("./data-raw/src/cp_com/dt_cp_com.rds")

###'Shape files
##'==================================== 
####'Shap carreaux
##'---------------------------------------- 
## https://www.insee.fr/fr/statistiques/4176290?sommaire=4176305
if (FALSE){## Très long
  shap_car<-st_read("./Filosofi2015_carreaux_200m_shp/Filosofi2015_carreaux_200m_metropole.shp")
  save(shap_car,file="shap_car.Rdata")
  }
load("./data-raw/src/cp_iris/src/shap_car.Rdata")

####'Shap codes postaux
##'---------------------------------------- 
shap_cp<-readRDS("./data-raw/src/cp/shap_cp.rds")
shap_cp%<>%st_transform(st_crs(shap_car))

####'Shap IRIS
##'---------------------------------------- 
shap_iris<-readRDS("./data-raw/src/iris/shap_iris.rds")
shap_iris%<>%st_transform( st_crs(shap_car))

###' Table de poids des IRIS dans les CPs
##'==================================== 
####' Intersection des iris, des carreaux et des cp
##'---------------------------------------- 
##' Assez long...
if (FALSE){
  mailles<-st_intersection(shap_iris,shap_car)
  mailles<-st_intersection(shap_cp,mailles)

  mailles<-
    mailles%>%
    select(iris,com,carreau=IdINSPIRE,cp,pop=Ind,geometry)
  
  mailles<-mailles%>%mutate(area=st_area(geometry))

  w_mailles<-
    mailles%>%
    as_tibble()%>%
    select(iris,com,carreau,cp,pop,area)%>%  
    group_by(carreau)%>%
    mutate(w=as.numeric(area)/sum(as.numeric(area)))%>%
    ungroup()

  save(w_mailles,mailles,file="inter_mailles_cp_iris.Rdata")

} else {
  load("./data-raw/src/cp_iris/inter_mailles_cp_iris.Rdata")
}

####'Vérifs
##'---------------------------------------- 
##' Pas d'intersection avec des coms?
empty_int<-setdiff(
  setdiff(ref_iris%>%mutate(com=substr(iris,1,5))%>%filter(substr(com,1,2)<97)%$%com,w_mailles$com),
  c("13055","69123","75056"))

no_match<-function(cc){
  bounds<-shap_iris%>%filter(com==cc)%$%geometry%>%st_bbox
  ggplot()+
    geom_sf(data=shap_iris%>%filter(com==cc))+
    geom_sf(data=shap_car%>%filter(substr(Depcom,1,2)==substr(cc,1,2)),fill=NA)+
    xlim(bounds[c(1,3)]*c(0.99,1.01))+ylim(bounds[c(1,3)+1]*c(0.999,1.001))+
    ggtitle(pop_iris%>%filter(com==cc)%$%sum(pop))
   }
lapply(empty_int,no_match)%>%marrangeGrob(nrow=3,ncol=3)
##' Marginal -> des communes sans personne ou des iles  ou le 2B015...
##' Pour le 2B015, le CP est l'union des communes. On est donc ok (on le récupère).
dt_com_cp%>%filter(com=="2B015")%>%unnest(cp)
dt_cp_com%>%filter(cp=="20272")%>%unnest(com)

##' Des cas en plus si on s'intéresse aux iris : das pop à 0 et l'Île de Friouls (132070301) 
pop_iris%>%
  ungroup()%>%
  anti_join(w_mailles%>%ungroup()%>%select(iris)%>%unique)%>%
  filter(!com %in% empty_int)%>%
  group_by(iris)%>%
  summarise(pop=sum(pop))%>%
  filter(pop!=0)

##' Pour ces reliquats, on rajoute des lignes à pop=0 et w=1
##' -> intersection vide avec carreaux 2015
##'    -> Iles, Dom
##' -> populations vides
w_add_miss<-
  pop_iris%>%ungroup()%>%
  anti_join(w_mailles%>%ungroup()%>%select(iris))%>%
  group_by(iris)%>%
  summarise(pop=sum(pop))%>%
  mutate(w=1,carreau=paste0("carreau_aouté_",iris))%>%
  mutate(com=substr(iris,1,5))

##' Vérification des match CP/com pour les doms
##' Union des CP de la commune est la commune?
dt_com_cp%>%
  filter(substr(com,1,2)=="97")%>%
  mutate(dep=substr(com,1,3))%$%table(dep,match_com_cp)

##' Union des comunes du CP est le CP?
dt_cp_com%>%
  unnest(com)%>%
  filter(substr(com,1,2)=="97")%>%
  mutate(dep=substr(com,1,3))%$%table(dep,match_cp_com)

##'Si pas :
dt_com_cp%>%
  filter(substr(com,1,2)=="97")%>%filter(!match_com_cp)%>%
  select(com)%>%
  left_join(dt_cp_com%>%unnest(com))%>%
  filter(match_cp_com==FALSE)

##' 3 communes pose pb...
##' On verra plus tard
##' On ajoute en attendant les communes pour lesquelles l'union des CP est la commune
w_mailles<-
  w_mailles%>%
  bind_rows(
    w_add_miss%>%
      inner_join(dt_com_cp%>%
                   ungroup()%>%
                   filter(match_com_cp)%>%
                   unnest(cp)%>%
                   select(cp,com)%>%
                   unique())
      )

###' Calcul des probas
##'==================================== 
####' 1 - CP = union stricte de communes (et donc d'IRIS)
##'---------------------------------------- 
w_cp_u_com<-
  dt_cp_com%>%
  ungroup()%>%
  filter(match_cp_com)%>%
  unnest(com)%>%
  select(cp,com)%>%
  left_join(pop_iris%>%
              filter(age=="-",sexe==3)%>%
              select(com,iris,w=pop))%>%
  group_by(cp)%>%
  mutate(w=w/sum(w))%>%
  ungroup()

## Pas de pop pour Mayotte ; On supprime.
w_cp_u_com%<>%
  filter(!is.na(iris))

####' 2 - Communes = union stricte de CP
##'---------------------------------------- 
w_com_u_cp<-
  dt_com_cp%>%
  ungroup()%>%
  filter(match_com_cp)%>%
  unnest(cp)%>%
  anti_join(w_cp_u_com%>%select(cp,com))%>%
  select(cp,com)%>%
  left_join(w_mailles)%>%
  group_by(cp,com,iris)%>%
  summarise(w=sum(w*pop))%>%
  group_by(cp)%>%
  mutate(w=w/sum(w))%>%
  ungroup()

####'3 - Autres cas
##'---------------------------------------- 
w_cp_com_ot_cas<-
  dt_cp_com%>%
  ungroup()%>%
  unnest(com)%>%
  anti_join(w_com_u_cp%>%select(com))%>%
  anti_join(w_cp_u_com%>%select(cp))%>%
  select(cp,com)%>%
  unique()

w_cp_com_ot_cas<-
  w_mailles%>%
  right_join(w_cp_com_ot_cas)%>%
  filter(!is.na(w))
 
w_cp_com_ot_cas<-
  w_cp_com_ot_cas%>%
  group_by(com,iris,cp)%>%
  summarise(w=sum(pop*w))%>%
  group_by(cp)%>%
  mutate(w=w/sum(w))%>%
  ungroup()

####'On regroupe le tout
##'---------------------------------------- 
w_iris_cp<-w_com_u_cp%>%
  bind_rows(w_cp_u_com)%>%
  bind_rows(w_cp_com_ot_cas)%>%
  unique()%>%
  filter(!is.na(w))

## Vérif qu'on a bien tout
##' Tous les IRIS de w_iris dans pop
w_iris_cp%>%ungroup()%>%select(iris)%>%
  anti_join(pop_iris%>%ungroup()%>%select(iris))

##' Tous les IRIS de pop dans w_iris ?
pop_iris%>%ungroup()%>%
  anti_join(w_iris_cp%>%ungroup()%>%select(iris))%>%
  group_by(iris)%>%
  summarise(pop=sum(pop))%>%arrange(desc(pop))%>%
  filter(!substr(iris,1,2)=="97")

##' On a pas les iris de population nulle
##' On les rajoute pour être complet
iris_0<-pop_iris%>%ungroup()%>%
  anti_join(w_iris_cp%>%ungroup()%>%select(iris))%>%
  group_by(iris)%>%
  filter(substr(iris,1,2)!="97")%>%
  summarise(pop=sum(pop))%$%iris

w_iris_cp%<>%
  bind_rows(
    dt_com_cp%>%
      ungroup()%>%
      filter(com %in% substr(iris_0,1,5))%>%
      unnest(cp)%>%
      select(com,cp)%>%
      mutate(iris=iris_0,w=0)
  )%>%
  arrange(cp,com,iris)

####'Vérifications
##'---------------------------------------- 
w_iris_cp%>%ungroup()%>%select(cp)%>%
  anti_join(dt_cp_com%>%select(cp))
dt_cp_com%>%select(cp)%>%
  anti_join(w_iris_cp%>%ungroup()%>%select(cp))## Manque Mayotte
## 3 cp métro non dans le shape, mais ils correspondent à des communes ok pour les cp...
dt_cp_com%>%filter(cp=="83530")%>%unnest(com)
dt_com_cp%>%filter(com=="83118")

w_iris_cp%>%ungroup()%>%select(com)%>%
  anti_join(dt_com_cp%>%ungroup()%>%select(com))
dt_com_cp%>%ungroup()%>%select(com)%>%
  anti_join(w_iris_cp%>%ungroup()%>%select(com)) ## Manque Mayotte

w_iris_cp%>%ungroup()%>%select(iris)%>%
  anti_join(ref_iris%>%ungroup()%>%select(iris))
ref_iris%>%ungroup()%>%select(iris)%>%
  anti_join(w_iris_cp%>%ungroup()%>%select(iris))%$%table(substr(iris,1,3))## Manque Mayotte

###'On ajoute les coms
##'==================================== 
list_iris_com <- read_xls("S:/REFERENTIELS/population/Recensements/iris/base-ic-evol-struct-pop-2016-com.xls",skip=5)%>%select(iris=IRIS)%>%unique

cp_com<-tibble(dep=c("975","977","978"),
               cp=c("97500","97133","97150"))
w_iris_cp_com<-
  list_iris_com%>%left_join(pop_iris%>%filter(age=="-",sexe==3)%>%select(iris,pop))%>%
  mutate(dep=substr(iris,1,3))%>%
  right_join(cp_com)%>%
  mutate(com=substr(iris,1,5))%>%
  select(iris,com,cp,w=pop)%>%
  unique()%>%
  group_by(cp)%>%
  mutate(w=w/sum(w))

w_iris_cp<-w_iris_cp%>%
  bind_rows(w_iris_cp_com)


###'On ajoute les probas age,sexe|iris
##'==================================== 
####'Calcul de la proba par age et sexe dans un iris
##'---------------------------------------- 
p_iris<-pop_iris%>%
  select(iris)%>%unique()%>%
  mutate(p_as=1)

p_age_iris<-pop_iris%>%
  filter(age!="-")%>%
  group_by(iris)%>%
  mutate(p_age=pop/sum(pop))%>%
  select(iris,age,p_age)

p_sexe_iris<-pop_iris%>%
  filter(age=="-",sexe!=3)%>%
  group_by(iris)%>%
  mutate(p_sexe=pop/sum(pop))%>%
  select(iris,sexe,p_sexe)

p_as_iris<-p_age_iris%>%
  left_join(p_sexe_iris)%>%
  mutate(p_as=p_sexe*p_age)%>%
  select(-p_sexe,-p_age)

p_as_iris<-
  p_iris%>%
  bind_rows(p_as_iris)%>%
  bind_rows(p_age_iris%>%rename(p_as=p_age))%>%
  bind_rows(p_sexe_iris%>%rename(p_as=p_sexe))%>%
  mutate(p_as=replace_na(p_as,0))%>%
  select(iris,cage=age,sexe,p_as)%>%
  ungroup()

p_as_iris%<>%filter(!is.na(cage),!is.na(sexe))


####'Table finale avec le poids p_i
##'---------------------------------------- 
p_cp_iris<-p_as_iris%>%filter(!is.na(cage),!is.na(sexe))%>%
  left_join(w_iris_cp)%>%
  mutate(p_i=w*p_as)%>%
  select(cp,iris,cage,sexe,p_i)

p_cp_iris%<>%lazy_dt%>%arrange(cp,iris,cage,sexe)%>%as_tibble()
p_cp_iris%<>%mutate_if(is.character,as.factor)

###'On sauve
##'==================================== 
saveRDS(p_cp_iris,"./data-raw/src/cp_iris/p_cp_iris.rds")


###'Vérifications
##'==================================== 
w_mailles%>%filter(substr(iris,1,5)=="91479")
w_mailles%>%filter(cp=="94390")
w_iris_cp%>%filter(cp=="94390")

w_cp_com_ot_cas%>%filter(cp=="94390")
w_com_u_cp%>%filter(cp=="94390")
w_cp_u_com%>%filter(cp=="94390")
w_mailles%>%filter(cp=="94390",com=="91479")

ggplot()+
  geom_sf(data=shap_iris%>%filter(com=="91479"),fill=NA,aes(colour=iris))+
  geom_sf(data=shap_cp%>%filter(cp %in% c("91550","94390")),aes(fill=cp),alpha=0.2)+
  geom_sf(data=mailles%>%filter(cp %in% c("91550","94390")),aes(fill=cp))

