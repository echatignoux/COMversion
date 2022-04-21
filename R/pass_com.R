##' Fonction interne pour calculer les poids de passages d'une année sur l'autre
##'
##' @param geo : année de départ
##' @param forward : TRUE si on augmente de millésime, FALSE sinon
##' @param by : strates de pop utilisées pour le calcul des poids (peut contenir des formules de type cut)
##' @param dt_pop : population (or weigth) table to use (default table if NULL)
##' @return Une table de poids
##' @author Edouard Chatignoux
##' @keywords internal
##' @importFrom magrittr %$% 
##' @importFrom magrittr %<>%
##' @import dplyr
##' @import rlang
##' @seealso \code{\link{pass_com}}, \code{\link{dts_com.sqlite}}
##' @export
##' @examples
##' pass_com.w.one(geo = 2016,by=~sexe)
pass_com.w.one<-function(geo = 2016,
                         forward = TRUE,
                         by=~cut(age,breaks=c(-Inf,50,Inf))+sexe,
                         dt_pop = NULL){

  geo_in=geo
  geo_out=geo+forward-!forward

  dt_fus_coms <- fus_com
  dt_scis_coms <- scis_com
  dt_pass_com <- pass_com
  if (is.null(dt_pop))
    dt_pop <- pop_com%>%
      filter(annee_geo==ifelse(geo_out==2018,2017,geo_out))
  
  if (is.null(by))
    by_w<-~1
  else {
    dv <- setdiff(all.vars(by),names(dt_pop))
    if (length(dv)>0)
      by_w<-update(by,
                   paste0("~.-",paste(setdiff(all.vars(by),names(dt_pop)),collapse="-")))
    else
      by_w<-by
  }
  com_in<-paste0("com_",geo_in)
  com_out<-paste0("com_",geo_out)

  if (geo_in<geo_out)
  {
    dt_split <- dt_scis_coms%>%
      filter(.data$annee_modif==geo_out)%>%
      select(com=.data$com_ini,com_out=.data$com_fin)
    dt_fus <- dt_fus_coms%>%
      filter(.data$annee_modif==geo_out)%>%
      select(com=com_ini,com_out=com_fin)
  }
  if (geo_in>geo_out){
    ## Dans le cas du reverse, l'année de la modif correspond à l'année - 1
    ## fusion en 2016 = scission en 2015
    ## A noter qu'il n'y a pas de géographie en 2018, si bien qu'on se rattache
    ## à la géographie de 2017 pour l'année 2019
    dt_split <- dt_fus_coms%>%
      rename(com=com_fin,com_out=com_ini)%>%
      filter(annee_modif==geo)%>%
      mutate(annee_modif=as.numeric(annee_modif)-1-(annee_modif==2019))%>%
      select(com,com_out)
    dt_fus <- dt_scis_coms%>%
      rename(com=com_fin,com_out=com_ini)%>%
      filter(annee_modif==geo)%>%
      mutate(annee_modif=as.numeric(annee_modif)-1-(annee_modif==2019))%>%
      select(com,com_out)
  }

  ## Bilan des scissions et des fusions
  dt_pass<-
    dt_pass_com%>%
    rename(com=!!(com_in),com_out=!!(com_out))%>%
    select(com,com_out)%>%
    unique()%>%
    filter(!(is.na(com) & is.na(com_out)))

  ## Pndération pour les scissions
  if (nrow(dt_split)>0)
    dt_pop%<>%
      filter(com %in% as.character(dt_split$com_out))
  else
    dt_pop%<>%
      filter(com %in% as.character(dt_pop$com[[1]]))

  dt_pop<-ag_call(data=dt_pop, by=by_w)
  ## On somme selon le by_w -> poids pour répartir les splits
  dt_pop%<>%
    group_by_at(vars(com,!!all.vars(by_w)))%>%
    summarise(pds_com=sum(pop),.groups = "keep")%>%
    ungroup()%>%
    rename(com_out=com)

  dt_split%<>%
    left_join(dt_pop, by = "com_out")%>%
    group_by_at(vars(com,!!all.vars(by_w)))%>%
    mutate(pds_com=pds_com/sum(pds_com))%>%
    ungroup()

  if (length(all.vars(by_w))>0)
    dt_pass%<>%
      tidyr::expand(tidyr::nesting(com,com_out),dt_pop%>%select_at(all.vars(by_w))%>%unique)

  dt_pass%<>%
    left_join(dt_split,by=c("com","com_out",all.vars(by_w)))%>%
    mutate(pds_com=tidyr::replace_na(pds_com,1))
  attributes(dt_pass)$by_w <- by_w
  dt_pass

}

##' Fonction interne pour calculer les poids de passages entre deux années
##'
##' Utilise récursivement pass_com.w.one pour aller de l'année a à l'année b
##'
##' @param geo_in: année de la géo d'entrée
##' @param geo_out: année de la géo de sortie
##' @param by : strates de pop utilisées pour le calcul des poids (peut contenir des formules de type cut)
##' @param dt_pop : population (or weigth) table to use (default table if NULL)
##' @return
##' @author Edouard Chatignoux
##' @keywords internal
##' @importFrom magrittr %$%
##' @importFrom magrittr %<>%
##' @import dplyr
##' @import rlang
##' @seealso \code{\link{pass_com}}, \code{\link{dts_com.sqlite}}
##' @export
##' @examples
##' pass_com.w(geo_in=2016,geo_out=2020,by=~sexe+toto)
pass_com.w<-function(geo_in=2016,
                     geo_out=2020,
                     by=~cut(age,breaks=c(-Inf,50,Inf))+sexe,
                     dt_pop = NULL){

    if (geo_in!=geo_out){
        dt_fus_coms <- fus_com
        dt_scis_coms <- scis_com
        dt_pass_com <- pass_com
        yrs<-geo_in:(ifelse(geo_out==2018,2017,geo_out))
        if (is.null(dt_pop))
            dt_pop <- pop_com%>%
                filter(annee_geo %in% yrs)%>%
                select(-annee_pop)

        if (is.null(by))
            by<-~1
        com_in<-paste0("com_",geo_in)
        com_out<-paste0("com_",geo_out)

        if (geo_in<geo_out)
        {
            dt_split <- dt_scis_coms%>%
                filter(annee_modif>geo_in & annee_modif<=geo_out)%>%
                select(com=com_ini,com_out=com_fin)
            dt_fus <- dt_fus_coms%>%
                filter(annee_modif>geo_in & annee_modif<=geo_out)%>%
                select(com=com_ini,com_out=com_fin)
        }
        if (geo_in>geo_out){
            ## Dans le cas du reverse, l'année de la modif correspond à l'année - 1
            ## fusion en 2016 = scission en 2015
            ## A noter qu'il n'y a pas de géographie en 2018, si bien qu'on se rattache
            ## à la géographie de 2017 pour l'année 2019
            dt_split <- dt_fus_coms%>%
                rename(com=com_fin,com_out=com_ini)%>%
                filter(annee_modif>geo_out & annee_modif<=geo_in)%>%
                mutate(annee_modif=as.numeric(annee_modif)-1-(annee_modif==2019))%>%
                select(com,com_out)
            dt_fus <- dt_scis_coms%>%
                rename(com=com_fin,com_out=com_ini)%>%
                filter(annee_modif>geo_out & annee_modif<=geo_in)%>%
                mutate(annee_modif=as.numeric(annee_modif)-1-(annee_modif==2019))%>%
                select(com,com_out)
        }

        ## Bilan des scissions et des fusions
        dt_pass<-
            dt_pass_com%>%
            rename(com=!!(com_in),com_out=!!(com_out))%>%
            select(com,com_out)%>%
            unique()%>%
            filter(!(is.na(com) & is.na(com_out)))%>%
            left_join(dt_fus%>%select(com)%>%mutate(fus=T),by="com")%>%
            left_join(dt_split%>%select(com)%>%mutate(sci=T),by="com")%>%
            unique()%>%
            mutate_at(vars(fus,sci),~tidyr::replace_na(.x,FALSE))%>%
            group_by(com_out)%>%
            mutate(fus=fus&(n()>1))%>%
            group_by(com)%>%
            mutate(sci=sci&(n()>1))%>%
            ungroup()%>%
            mutate(statut=
                       case_when(fus~ "Fusion",
                                 sci~ "Scission",
                                 TRUE~"Inchangée")%>%factor)%>%
            select(-fus,-sci)%>%
            unique

        cat("---------------------------------------\n")
        cat("Fusions et scissions entre les périodes\n")
        cat("---------------------------------------")
        kableExtra::kable(dt_pass%>%select(com,statut)%>%unique()%$%table(statut),"pipe")%>%
            knitr:::print.knitr_kable()
        cat("--------------------------------------------------------------------------------\n")
        cat("Les poids des communes séparées sont calculés au prorata de leurs populations\n")
        cat("au moment de la scission\n")
        cat("--------------------------------------------------------------------------------\n")

        forward <- geo_out>geo_in
        dt_pass_w<-pass_com.w.one(geo=geo_in,forward=forward,by=by,dt_pop = dt_pop)
        by_w<-attributes(dt_pass_w)$by_w
        if (length(geo_in:geo_out)>2)
            for (geo in (geo_in+forward-!forward):(geo_out-forward+!forward)){
                dt_pass_w<-
                    dt_pass_w%>%
                    rename(pds_ini=pds_com,com_in=com,com=com_out)%>%
                    full_join(
                        pass_com.w.one(geo=geo,forward=forward,by=by,dt_pop = dt_pop), by= c( "com", all.vars(by_w)))%>%
                    mutate_at(vars(pds_com,pds_ini),~tidyr::replace_na(.x,1))%>%
                    mutate(pds_com=pds_com*pds_ini)%>%
                    select_at(vars(com=com_in,com_out,pds_com,all.vars(by_w)))
            }
        dt_pass<-dt_pass_w%>%left_join(dt_pass%>%select(com_out,statut)%>%unique,by="com_out")
        ## Pour les communes rétablies, on remet le poids à 1
        dt_pass%<>%
            ## filter(!(statut=="Inchangée" & as.character(com)!=as.character(com_out)))%>%
            mutate(pds_com=ifelse(statut=="Inchangée",1,pds_com))

    } else {
        if (is.null(dt_pop))
            dt_pop <- pop_com%>%
                filter(annee_geo == geo_in)%>%
                collect()
        dt_pass_w<-pass_com.w.one(geo=geo_in,forward=FALSE,by=by,dt_pop = dt_pop)
        by_w<-attributes(dt_pass_w)$by_w
        dt_pass<-dt_pass_w%>%mutate(com_out=com)%>%unique()%>%
            mutate(statut="Inchangée")
    }
    
    attributes(dt_pass)$by <- by
    attributes(dt_pass)$by_w <- by_w
    attributes(dt_pass)$geo_in <- geo_in
    attributes(dt_pass)$geo_out <- geo_out
    dt_pass

}
