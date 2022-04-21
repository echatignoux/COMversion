##======================================================================
### --- build_pack.R ---
##======================================================================
## Auteur: Edouard Chatignoux
## Créé le mer.  1 oct. 2014
## Dernière mise à jour le 2022-04-04
##======================================================================
##  Description:
##--------------
##' Suite des étapes pour construire un pacquage avec devtools.
##======================================================================

##'Création des répertoires
devtools::create()

##'Vignette
usethis::use_vignette("my-vignette")

##'Liste des packages dont on a besoin
##' (use_package ajoute le paquet à DOCUMENT)
usethis::use_package("data.table")
usethis::use_package("dplyr")
usethis::use_package("dtplyr")
usethis::use_package("purrr")
usethis::use_package("magrittr")
usethis::use_package("rlang")
usethis::use_package("kableExtra")
usethis::use_package("DBI")
usethis::use_package("RSQLite")

## Fichier/dossiers à ignorer
usethis::use_build_ignore("devtools_history.R")
usethis::use_build_ignore("data-raw")
usethis::use_build_ignore("inst")
usethis::use_build_ignore("build_pack.R")
usethis::use_build_ignore("./R/read_sql.R")

##'On charge tout (et on regarde si ça marche)
devtools::load_all()

##' Création des .Rd à partir des commentaires roxygen
devtools::document()

##' On regarde si tous va bien
##' dans les exemples...
devtools::run_examples()
##' et dans la structure
devtools::check()

## Manuel en pdf
devtools::build_manual()

## Vignette
devtools::build_vignettes()

## Construction du package (.zip)
devtools::build(binary = TRUE)

## Installation dans mon R
devtools::install()

data(dt_pop_2013)
a<-pass_geo(geo_in = 2015,
            geo_out = 2017)

b<-pass_geo(data=dt_pop_2013,
            geo_in = 2015,
            geo_out = 2017)

a%>%select(com_out,statut)%>%unique()%$%table(statut)
a%>%select(com,statut)%>%unique()%$%table(statut)

a%>%filter(statut=="Inchangée",as.character(com)!=as.character(com_out))
b%>%select(com_out,statut)%>%unique()%$%table(statut)

pass_geo(data=dt_pop_2013,
         geo_in=2019,
         geo_out=2019,
         by=~cut(age,breaks=c(-Inf,50,Inf))+sexe+dep+annee_pop,
         geo=  ~ com)%>%tail


dt_iris_p1bis<-readRDS("s:/pop_vulnerable/iss/1_SIDEP/2_Data/prdr/test_imputation/dt_iris_p1bis.rds")


install.packages("../COMversion_1.1.zip")



a<-readRDS("s:/pop_vulnerable/iss/1_SIDEP/2_Data/prdr/test_imputation/dt_iris.rds")

aa<-
  a%>%filter(iris %in% c("010040102","010040201","114400000"))%>%
  mutate(iris=ifelse(iris=="010040201",NA,iris))%>%
  filter(!is.na(cage),!is.na(sexe))%>%
  filter(cp %in% c("01500","11220"))

aa%<>%
  rowwise()%>%
  mutate(age=as.numeric(strsplit(cage,"-")[[1]][1])+1)%>%
  mutate(age=cut(age,breaks=c(-Inf,2,5,10,17,24,39,54,64,79,Inf)))%>%
  ungroup()%>%
  select(date,iris,age,sexe,cp,N)

aa<-a%>%
  filter(date == as.Date("2020-10-20"))%>%
  filter(cp %in% c("01500","11220"))
aa%>%select(cp,iris)%>%unique()
aa$cp[1]<-"toto"
aa$iris[1]<-NA

cp_iris_sp <-
  pass_geo(data=aa,
           geo_in = 2019,
           geo_out = 2019,
           by=~sexe+date,
           geo=cp~iris, 
           data_by = TRUE)

cp_iris_sp%$%table(statut)

aa%$%sum(N)
cp_iris_sp%$%sum(N)

aa%>%filter(iris=="114400000")
cp_iris_sp%>%filter(iris=="114400000")

aa%>%filter(iris=="010040102")%$%sum(N)
cp_iris_sp%>%filter(iris=="010040102")%$%sum(N)



aa%>%select(cp,iris)%>%unique()
cp_iris_sp%>%select(cp,iris)%>%unique()

library(lubridate)
aa%>%filter(iris=="114400000",date==as.Date("2020-10-20"))
cp_iris_sp%>%filter(iris=="114400000",date==as.Date("2020-10-20"))

aa%>%filter(iris=="114400000")%>%
  anti_join(cp_iris_sp%>%select(date,age,iris))

  %$%sum(T)
cp_iris_sp%>%filter(iris=="114400000")%$%sum(T)
aa%$%sum(T)
cp_iris_sp%$%sum(T)

cp_iris_sp%>%
  filter(iris=="010040102")%$%sum(T)
aa%>%
  filter(iris=="010040102")%$%sum(T)

cp_iris_sp%>%
  filter(iris!="114400000")%>%
  group_by(iris)%>%
  summarise(T=sum(T))%>%
  filter(iris!="010040102")%$%sum(T)

cp_iris_sp%>%
  filter(iris!="114400000")%>%
  group_by(iris)%>%
  summarise(T=sum(T))%>%
  filter(iris=="010040102")%$%sum(T)


aa%>%
  group_by(cp,iris)%>%
  summarise(sum(T))

cps<-pass_geo(data=NULL,
              geo_in = 2019,
              geo_out = 2019,
              by=~1,
              geo=cp~iris)


b<-aa%>%select(cp,iris)%>%unique()%>%mutate(n=1)
bb<-pass_geo(data=b,
             geo_in = 2019,
             geo_out = 2019,
             by=~1,
             geo=cp~iris)
cps%>%filter(cp=="01500")
cps%>%filter(cp=="11220")
bb
b

aa%>%

aa%>%select(cp,iris)%>%unique()
cps%>%filter(cp %in% unique(aa$cp))
cps%>%inner_join(aa%>%select(iris)%>%unique())

cps%>%filter(cp=="11220")
cps%>%filter(cp=="01500")
 
cp_iris_sp%>%select(iris)%>%unique()

aa$cp%>%unique()
cp_iris_sp$cp%>%unique()

aa$iris%>%unique()
cp_iris_sp$iris%>%unique()



aa%>%select(cp,iris)%$%table(cp,iris,useNA="always")
aa%>%filter(cp %in% c("01500","11220"))



pass_geo(data = a,
         geo_out=2019,
         by=~sexe,
         geo=cp~iris)





dt_imp<-
  data%>%
  ungroup()%>%
  filter(is.na(geo),!is.na(cp))%>%
  select(-geo)%>%
  inner_join(p_cp,by=c(all.vars(by_w)))%>%
  group_by_at(all_of(c("geo",all.vars(by))))%>%
  summarise_at(vars(varn),~sum(.x*pds))%>%
  arrange(geo)%>%
  as_tibble()

