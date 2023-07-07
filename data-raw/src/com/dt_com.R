##======================================================================
### --- dt_com.R ---
##======================================================================
## Auteur: Edouard Chatignoux
## Créé le 2020-10-06
## Dernière mise à jour le 2022-03-22
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
library(furrr)
library(tidyverse)
library(magrittr)
library(data.table)

path<-"./data-raw/src/com"

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
url_zip("https://www.insee.fr/fr/statistiques/fichier/6800675/cog_ensemble_2023_csv.zip")
ref_arm <- read_csv(file.path(path,"./src/v_commune_2023.csv"))%>%rename_all(tolower) %>%
  filter(typecom=="ARM")
ref_com <- read_csv(file.path(path,"./src/v_commune_depuis_1943.csv"))
ref_com%<>%rename_all(tolower)
ref_com%<>%filter(!com %in% c("75056","69123","13055"))

## Déduction des communes présentes une année donnée
ref_com %<>%
  filter(!(date_debut==date_fin & !is.na(date_fin))) %>% 
  mutate(annee_deb = year(date_debut) + (format(date_debut,"%m")>"01"),
         annee_fin = year(date_fin)-(format(date_fin,"%d")=="01" & format(date_fin,"%m")=="01"),
         annee_fin = replace_na(annee_fin,2023)
         ) %>%
  group_by(com) %>%
  arrange(com,date_debut) %>%
  mutate(idem = as.numeric(date_debut == lag(date_fin)),
         idem = replace_na(idem,1),
         idem = as.logical(idem)
         ) %>%
  group_by(com,idem) %>%
  arrange(date_debut) %>% 
  mutate(annee_deb = min(annee_deb)) %>%
  filter(row_number() == max(n()))

ref_com %<>%
  bind_rows(ref_arm %>% mutate(annee_deb = 2005, annee_fin = 2023)) %>% 
  filter(annee_fin > 2005) %>%
  filter(annee_fin > annee_deb | annee_fin==2023) %>% 
  mutate(annee_deb = ifelse(annee_deb<2005,2005,annee_deb)) %>% 
  ungroup() %>% 
  select(com, lib_com = libelle, annee_deb, annee_fin) %>%
  mutate(n = map2(annee_deb,annee_fin,~tibble(annee_geo = seq(.x,.y,by=1)))) %>%
  unnest(n) %>%
  select(-annee_deb,-annee_fin )

## Quelques points particuliers à règler à la main
##' Culey (https://www.insee.fr/fr/metadonnees/cog/commune/COM55138-culey) est sencée être rétablie en 2014,
##' mais n'apparait qu'en 2015
##' Oudon (https://www.insee.fr/fr/metadonnees/cog/commune/COM14472-l-oudon) est sencée être rétablie entre 2014 et 2017,
##' mais ne l'est qu'en 2016 ; en 2015, c'est 14697 (aussi appelée Oudon...).
ref_com %<>%
  filter(!(com=="55138" & annee_geo == 2014)) %>%
  filter(!(com=="14472" & annee_geo != 2016)) %>%
  bind_rows(tibble(com="14697",lib_com="L'Oudon",annee_geo=2015))

###'Populations 
##'==================================== 
##' Attention : contairement à ce qui est indiqué sur le site de l'INSEE
##' (https://www.insee.fr/fr/statistiques/4989761)
##' les référentiels géo des années post 2015 sont en n+3
pop.path<-"S:/REFERENTIELS/population/Recensements/format_csv"

plan(multisession, workers=2)
dt_pop_com<-tibble(annee_pop=2006:2020)%>%
  group_by(annee_pop)%>%
  mutate(pop=future_map(annee_pop,function(a)
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
  mutate(annee_geo=annee_pop+2+(annee_pop>2015))%>%
  select(-annee_pop)
plan(sequential)
gc()

dt_pop_com%<>%mutate_at(vars(com,dep),as.factor)
dt_pop_com%<>%ungroup()%>%select(-annee)%>%
  filter(!com %in% c("75056","13055","69123"))

####'Validation des réferentiels
##'---------------------------------------- 
ref_pc <- dt_pop_com %>% filter(age==0, sexe==1) %>% select(annee_geo,com)
ref_pc %>%
  anti_join(ref_com)

ref_com %>%
  filter(annee_geo %in% 2008:2022) %>%
  filter(!str_sub(com,1,2)=="97") %>% 
  anti_join(ref_pc) %$%
  table(annee_geo)

###'Tables de passage
##'==================================== 
####'Tables de référence
##'---------------------------------------- 
url_zip("https://www.insee.fr/fr/statistiques/fichier/2028028/table_passage_annuelle_2023.zip")
## Table de passage entre les milésimes
dt_pass_coms<-read_xlsx(file.path(path,"./src/table_passage_annuelle_2023.xlsx"),sheet=1,skip=5)%>%
  rename_at(vars(contains("CODGEO")),function(x) gsub("CODGEO","com",x))%>%
  rename_at(vars(contains("LIBGEO")),function(x) gsub("lib","com",x))%>%
  select(NIVGEO,contains("com"))
dt_pass_coms%<>%mutate_all(as.factor)

##' L'Oudon (14472)  n'existe plus en 2015 (transfert en 2014 vers Notre-Dame-de-Fresnay (14697)), mais est présente dans
##' la table de passage.
## Dans la table de passage
dt_pass_coms %>% filter(com_2015 %in% c("14697","14472","14654") |
                          com_2016 %in% c("14697","14472","14654")|
                          com_2014 %in% c("14697","14472","14654")) %>%
  select(com_2014,com_2015,com_2016,com_2017)
## Pas dans la table de pop
ref_pc %>% filter(com %in% c("14697","14472","14654")) %>%
  filter(annee_geo %in% 2014:2017)
##' On corrige ici
dt_pass_coms%<>%filter(!(!is.na(com_2015) & com_2015=="14472"))


##' On enlève les communes de Paris, Luyon et Marseille
dt_pass_coms%<>%filter(!(com_2015 %in% c("13055","69123","75056")))

## Table des scissions de communes
dt_scis_coms<-read_xlsx(file.path(path,"./src/table_passage_annuelle_2023.xlsx"),sheet=3,skip=5)
dt_scis_coms%<>%rename_all(tolower)
dt_scis_coms%<>%mutate_at(vars(-annee_modif),as.factor)

## Table des funsions de communes
dt_fus_coms<-read_xlsx(file.path(path,"./src/table_passage_annuelle_2023.xlsx"),sheet=2,skip=5)
dt_fus_coms%<>%rename_all(tolower)
dt_fus_coms%<>%mutate_at(vars(-annee_modif),as.factor)
## A noter que pour certaines communes (2 en fait), fusion = transfert (i.e. même commune mais pas même numéro)
dt_fus_coms%>%group_by(com_fin)%>%
             filter(n()==1)

##' Tôtes (14697) est présente comme fusion en 2015
##' alors que c'était une fusion en 2014
##' https://www.insee.fr/fr/metadonnees/cog/commune/COM14697-totes
##' Malgré celà, la commune apparait dans les référentiels (et dans les tables de pop) jusqu'en 2015...
##' On corrige donc ici l'année 2015 par 2016 dans la table des fusions
dt_fus_coms[dt_fus_coms$com_ini=="14697","annee_modif"] <- "2016"

####'Travail sur la table de passage
##'---------------------------------------- 
##' 1 - Pour les communes rétablies après une fusion (p.ex 14712->14666->14712)
##' une nouvelle ligne est ajoutée dans dt_pass_coms (on a donc une ligne 14712->14666 et une autre NA->14712). On rétablit donc l'historique linéaire (14712->14666->14712)
dt_pass_full<-dt_pass_coms%>%
  mutate(id=row_number())%>%
  gather(yr,com,-NIVGEO,-id)

## Communes rétalies après fusion
dt_retab<-dt_scis_coms%>%select(com_fin,com_ini)%>%
  inner_join(dt_fus_coms%>%select(com_fin,com_ini))%>%
  select(com_ini)%>%
  left_join(dt_scis_coms)%>%
  filter(com_ini!=as.character(com_fin))%>%
  select(annee_modif,com_ini,com_fin)

## Id concernés par les retab
id_retab<-dt_pass_full%>%
  right_join(dt_retab%>%rename(com=com_ini))%>%
  select(id)%>%unique()
## Id de la ligne ajoutée pour les scissions qui sont en fait des retab
id_drop<-dt_pass_full%>%
  right_join(dt_retab%>%rename(com=com_fin))%>%
  select(id)%>%unique()%>%
  arrange(id)%>%anti_join(id_retab)

## Id de des obs à modifier
id_retab<-dt_pass_full%>%
  select(id,com)%>%unique()%>%
  right_join(id_retab)%>%
  group_by(id)%>%
  mutate(n=row_number())%>%
  spread(n,com)%>%
  rename(com_ini=`1`,com_fin=`2`)%>%
  right_join(dt_retab)

## On modifie les lignes 
dt_pass_full%<>%
  anti_join(id_drop)%>%
  left_join(id_retab%>%select(com_fin,annee_modif))%>%
  mutate(com=ifelse(as.numeric(gsub("com_","",yr))>=annee_modif & !is.na(annee_modif),as.character(com_fin),com))%>%
  arrange(id)%>%
  select(-com_fin,-annee_modif)

## Vérifs
dt_pass_full%>%filter(id==5212)
dt_pass_full%>%filter(id==5213)

dt_pass_full%>%filter(id==30954)
dt_pass_full%>%filter(id==30955)
## Ok

##' 2 - Pour les communes s'étant séparées, dt_pass_coms contient des NA
##' les années avant la scission. Pas pratique pour faire la correspondance : on les remplit donc avec le numéro de la commune avant scission
## Dernière année de la scission
last_com<-
    dt_scis_coms%>%
    right_join(
      dt_pass_full%>%
      filter(!is.na(com))%>%
      right_join(dt_pass_full%>%
                 filter(is.na(com))%>%select(id)%>%
                 unique)%>%
      arrange(id,yr)%>%
      group_by(id)%>%
      slice(1)%>%
      select(id,com_fin=com)
    )%>%
    select(id,com_ini,com_fin)

dt_pass_full%<>%
  left_join(last_com,by=c("id"))%>%
  mutate(com=ifelse(is.na(com),as.character(com_ini),as.character(com)))%>%
  select(-com_ini,-com_fin)%>%
  spread(yr,com)%>%
  select(-id)%>%
  mutate_all(as.factor)


###'On sauve
##'==================================== 
saveRDS(ref_com,file=file.path(path,"ref_com.rds"))
saveRDS(dt_pass_full,file=file.path(path,"dt_pass_com.rds"))
saveRDS(dt_scis_coms,file=file.path(path,"dt_scis_com.rds"))
saveRDS(dt_fus_coms,file=file.path(path,"dt_fus_com.rds"))
saveRDS(dt_pop_com,file=file.path(path,"dt_pop_com.rds"))

