##' Internal utility
##'
##'
##' @param data : données
##' @param by : by
##' @return tibble
##' @keywords internal
##' @author Edouard Chatignoux
##' @export
ag_call<-function(data=w_com_cp,
                  by=by_w){
  call<-terms(by)%>%attributes%$%term.labels
  if (length(call)>0){
    for(i in 1:length(call)){
      var<-all.vars(by)[i]
      fun<-function(x) eval(parse(text = gsub(var,"x",call[i])))
      data%<>%
        mutate_at(vars(var),fun)
    }
  }
  data
}


##' Internal function to ventilate postal code to
##' commune/IRIS code
##'
##' Note that population estimates from 2017 (geography 2019) is used to ventilate cases
##'
##'
##' @param data : table with postal codes
##' @param by : formula to compute weights, i.e. use com/IRIS age and/or sex structure to ventilate cases
##' @param geo : out geography ("iris" or "com")
##' @importFrom magrittr %$%
##' @importFrom magrittr %<>%
##' @import dplyr
##' @import rlang
##' @import dtplyr
##' @return A tibble
##' @author Edouard Chatignoux
##' @export
cp_to_geo <-
  function( data, by = ~ 1 , geo = "iris"){
    if(geo == "iris"){
      p_cp<-p_cp_iris
      p_cp%<>%rename(pds=p_i,geo=iris)
      by_imp<-str_replace(all.vars(by),"age","cage")
    }
    else{
      p_cp<-(p_cp_com)
      p_cp%<>%rename(pds=p_c,geo=com)
      by_imp<-all.vars(by)
    }

    data%<>%ungroup()
    if (!any(str_detect(names(data),paste0("^",geo,"$"))))
      data%<>%mutate(geo = NA)
    else
      names(data)[names(data) == geo] <- "geo"

    ## On ne garde que les probas pour le by qui nous intéressent
    p_cp%<>%
      lazy_dt()%>%
      group_by_at(all_of(c("cp","geo",by_imp)))%>%
      summarise(pds=sum(pds))%>%
      as_tibble()

    ## Création d'âge continu dans p_as_iris si besoin
    if (any(str_detect(all.vars(by),"^age$")) & geo=="iris"){

      conv_age<-tibble(age=0:99)%>%
        mutate(cage = cut(age,
                          breaks = c(0,3,6,11,18,25,40,55,64,80,Inf),
                          include.lowest = TRUE,right=F,
                          labels = c("00-02","03-05","06-10","11-17","18-24","25-39","40-54","55-64","65-79","80-P")))%>%
        group_by(cage)%>%
        mutate(n=n())%>%
        ungroup()

      p_cp%<>%
        left_join(conv_age,by="cage")%>%
        mutate_at(vars(pds),~.x/n)%>%
        select_at(vars(-cage))%>%
        select(-n)

    }

    call<-terms(by)%>%attributes%$%term.labels
    if (length(call)>0){
      p_cp<-ag_call(data=p_cp,  by=by)
      p_cp%<>%
        lazy_dt()%>%
        group_by_at(vars(cp,"geo",!!all.vars(by)))%>%
        summarise(pds=sum(pds),.groups = "keep")%>%
        group_by_at(vars(cp,!!all.vars(by)))%>%
        mutate(pds=pds/sum(pds))%>%
        ungroup()%>%
        mutate(pds=ifelse(is.na(pds),0,pds))%>%
        as_tibble()

      data%<>%ag_call(data=., by=by)%>%
        unique()
    }
    
    data%<>%
      mutate(pds_cp=1)

    dt_imp<-data%>%
      ungroup()%>%
      lazy_dt()%>%
      filter(is.na(geo),!is.na(cp))%>%
      select(-geo)%>%
      inner_join(p_cp,by=c("cp",all.vars(by)))%>%
      group_by_at(all_of(c("cp","geo",all.vars(by))))%>%
      summarise_at(vars(pds_cp),~sum(.x*pds))%>%
      arrange(geo)%>%
      as_tibble()

    names(dt_imp)[names(dt_imp) == "geo"] <- geo
    dt_imp
    
  }


##' Fonction de passage d'une géographie à une autre
##'
##' Par défaut, la fonction prend en argument une table d'entrée avec une définition des
##' communes dans un millésime donné et sort une table dans un autre millésime.
##' Les données (variables numériques) des communes fusionnées entre les deux millésime sont aggrégées.
##' Les données (variables numériques) des communes séparées entre les deux millésime sont réparties entre les
##' nouvelles communes au prorata de leur population lors de la première années de la scission.
##' Les strates de population utilisées pour calculer ce prorata est laissé au choix de l'utilisateur.
##' Si aucune table d'entrée n'est spécifiée, une table de conversion entre les géographie est retournée.
##' Si l'option géo est modifiée, la fonction permet le passage d'un code postal vers des communes/iris, et des communes vers les iris (mais ce n'est certainement pas souhaitable).
##'
##' @param geo_in Millésime des codes communes (i.e. ceux de data si
##'   data non NULL)
##' @param geo_out Millésime des codes communes souhaités en sortie
##' @param by : strates de pop utilisées pour le calcul des poids
##'   (peut contenir des formules, de type cut par example); si des
##'   variables de data doivent être conservées telle que, les mettre
##'   dans le by (voir exemples)
##' @param data Table de données dans la géographie millésimée geo_in
##'   à sortir en géographie millésimée geo_out. La table doit avoir
##'   des colonnes compatibles avec le by.  Si laissée à NULL, la
##'   table des poids de passage est retournée.
##' @param data_by : Mettre a TRUE pour regrouper data selon by
##' @param geo : Formule donnant le niveau géographique d'entrée et de
##'   sortie souhaités : \itemize{ \item \code{cp~iris}: pour cp en
##'   entrée et iris en sortie \item \code{com~iris}: pour com en
##'   entrée et iris en sortie \item \code{com~com}: pour com en
##'   entrée et en sortie (idem à \code{~com}) } Toutes les
##'   combinaisons sont possibles, sauf avec le cp en sortie et l'iris
##'   en entrée (\code{com~cp} et \code{iris~com} sont inopérants par
##'   exemple).
##' @return Une table dans le nouveau millésime des communes
##' @author Edouard Chatignoux
##' @export
##' @importFrom magrittr %$%
##' @importFrom magrittr %<>%
##' @import dplyr
##' @import rlang
##' @import tidyr
##' @examples
##' ## Pour avoir les poids de passage
##' ## uniquement
##' pass_geo(geo_in=2015,
##'          geo_out=2017,
##'          by=~1)
##'
##' ## Pour appliquer le passage  directement à une table
##' ## Ex. table des pops géo 2013 à passer en version géo 2017
##' ## Poids calculés par classe d'age * sexe
##' ## On veut garder les infos contenues dans les colonnes dep et annee_pop
##' data(dt_pop_2013)
##' pass_geo(data=dt_pop_2013,
##'          geo_in=2013,
##'          geo_out=2017,
##'          by=~cut(age,breaks=c(-Inf,50,Inf))+sexe+annee_pop+dep,
##'          geo=  ~ com)
pass_geo<-function(geo_in=2016,
                   geo_out=2020,
                   by=NULL,
                   data=NULL,
                   data_by = TRUE,
                   geo=  ~ com
                   ){
  
  dt_pop = NULL
  ## Préliminaires
  type_in <- formula.tools::lhs.vars(geo)
  type_out <- formula.tools::rhs.vars(geo)
  
  if (is.null(type_in))
    type_in <- type_out

  if (is.null(by))
    by<-~1

  ## Vérifications
  if (type_out == "iris" & type_in != "cp" & (min(geo_in,geo_out)<2016))
    stop("IRIS conversion not implemented for years prior to 2016")
  if (type_out == "cp")
    stop("Conversion to postal code not implemented")
  if (type_in == "iris" & type_in != "iris")
    stop("Conversion from iris not implemented")
  if (data_by & !is.null(data)){
    if ((length(all.vars(by))>1) & any(!(all.vars(by) %in% names(data))))
      stop(paste(setdiff(all.vars(by),names(data)),collapse=",")," not in data")
  }

  if (!is.null(data)){
    if ("age" %in% all.vars(by)){
      if (!data_by){
        bya<-as.formula(paste0("~",terms(by)%>%attributes%$%term.labels[all.vars(by)=="age"]))
        lev <- tibble(age=1:2)%>%
          ag_call(data=., by=bya)%$%age%>%levels()
        if (any(lev != levels(data$age)))
          stop("Age levels missmatch")
      }
      if (data_by & !is.numeric(data$age))
        stop("Age must be numeric")
    }
  }
  
  if (type_in == "cp"){
    if (geo_in != 2019)
      message("Geography for postal code only available for 2019")
    geo_in = 2019
  }

  ## Passage entre les versions de communes  
  out <- pass_com.w(geo_in,
                    geo_out,
                    by,
                    dt_pop)
  atr<-attributes(out)

  ## Passage en version IRIS si besoin
  if (type_out == "iris" )
    out <- com_to_iris(out)

  out%<>%
    rename_at(vars(starts_with("pds_")),~paste0(strsplit(.x,"_")[[1]][1],"_w"))%>%
    rename("geo"=all_of(type_out),"geo_out"=paste0(type_out,"_out"))%>%
    select_at(vars(geo,geo_out,statut,all.vars(atr$by_w),pds_w))


  ## Si CP, passage CP vers type_out
  if (type_in == "cp"){

    ref_cp <-
      p_cp_iris%>%
      select(cp)%>%
      unique()%>%
      tidyr::expand(cp,age=0:99)%>%
      tidyr::expand(nesting(cp,age),sexe=1:2)%>%
      select(all_of(c("cp",all.vars(atr$by_w))))%>%
      unique()%>%
      as_tibble()
    ref_cp <- cp_to_geo(ref_cp,by=atr$by_w,geo=type_out)
    ref_cp%<>%rename("geo"=all_of(type_out))

    out_geo<-out
    
    out%<>%
      right_join(ref_cp,by = c("geo",all.vars(atr$by_w)))%>%
      mutate(pds_w = pds_cp * pds_w)%>%
      select(-geo)%>%
      rename(geo=cp)%>%
      group_by_at(vars(geo,geo_out,statut,all.vars(atr$by_w)))%>%
      summarise(pds_w=sum(pds_w))

   out%<>%
     group_by_at(vars("geo",!!all.vars(atr$by_w)))%>%
     mutate(n=n(),pds_w=ifelse(n==1,1,pds_w))%>%
     select(-n)%>%
     ungroup()

  }

    
    if (!is.null(data)) {

        data%<>%rename("geo"=all_of(type_in))
        some_geo <- type_out %in% names(data)
        if (! some_geo)
            data[,type_out] <- NA
        data%<>%rename("geo_out"=all_of(type_out))

        by<-atr$by
        by_w<-atr$by_w

        ## Prise en compte des NA potentiels dans la table
        if (length(all.vars(atr$by_w))>0){
            fill <- "geo"
            if( length(all.vars(atr$by_w))>1)
                fill <- c("geo",all.vars(atr$by_w))
            out%<>%
                bind_rows(
                    lapply(fill,function(v)
                        out%>%
                        lazy_dt()%>%
                        group_by_at(vars(geo,geo_out,v,statut))%>%
                        summarise(pds_w=sum(pds_w)/n())%>%
                        as_tibble())
                )
        }
        
        if (data_by){
            data%<>%ag_call(data=., by=by)
            varn<-data%>%ungroup()%>%select_if(is.numeric)%>%names%>%
                setdiff(c("age","sexe",all.vars(by)))
            data%<>%
                lazy_dt()%>%
                group_by_at(vars("geo","geo_out",!!all.vars(by)))%>%
                summarise_at(vars(varn),~sum(.x),.groups = "keep")%>%
                as_tibble()
        }

        out%<>%
            dtplyr::lazy_dt()%>%
            right_join(
                data%>%filter(is.na(geo_out))%>%select(-geo_out),
                by=c("geo",all.vars(by_w)))%>%
            mutate_at(vars(geo,geo_out,statut),as.character)%>%
            mutate(statut= ifelse(is.na(statut),"Non trouvé",statut),
                   pds_w = ifelse(is.na(pds_w),1,pds_w),
                   geo_out = ifelse(is.na(geo_out),geo,geo_out))%>%
            group_by_at(vars("geo",!!all.vars(by)))%>%
            mutate(to_ag=n()>1)%>%
            group_by_at(vars("geo_out",!!all.vars(by)))%>%
            mutate(to_ag_tmp=n())%>%
            as_tibble()%>%
            mutate(to_ag=ifelse(to_ag_tmp>1,TRUE,to_ag))%>%
            select(-to_ag_tmp)

        
        if (some_geo & type_in == "cp"){
            ## Prise en compte des NA potentiels dans la table
            if (length(all.vars(atr$by_w))>0){
                fill <- "geo"
                if( length(all.vars(atr$by_w))>1)
                    fill <- c("geo",all.vars(atr$by_w))
                out_geo%<>%
                    bind_rows(
                        lapply(fill,function(v)
                            out_geo%>%
                            lazy_dt()%>%
                            group_by_at(vars(geo,geo_out,v,statut))%>%
                            summarise(pds_w=sum(pds_w)/n())%>%
                            as_tibble())
                    )
            }

            out_add<-
                data%>%
                filter(!is.na(geo_out))%>%
                select(-geo,geo=geo_out)%>%
                left_join(out_geo,by=c("geo",all.vars(by_w)))%>%
                mutate(statut= as.character(ifelse(is.na(statut),"Non trouvé",statut)),
                       pds_w = as.numeric(ifelse(is.na(pds_w),1,pds_w)),
                       geo_out = as.character(ifelse(is.na(geo_out),geo,geo_out)))%>%
                group_by_at(vars("geo",!!all.vars(by)))%>%
                mutate(to_ag=n()>1)%>%
                group_by_at(vars("geo_out",!!all.vars(by)))%>%
                mutate(to_ag=ifelse(n()>1,TRUE,to_ag))

            if (nrow(out_add)>0)
                out%<>%
                    bind_rows(
                        out_add
                    )
        }


        varn<-data%>%ungroup()%>%select_if(is.numeric)%>%names%>%
            setdiff(c("age","sexe",all.vars(by)))
        
        ## On joint la table des poids et on pondère les obs
        cols_to_keep <- c("geo",
                          all.vars(by),
                          varn)%>%unique()

        out%<>%
            group_by(to_ag)%>%
            nest()%>%
            mutate(data=purrr::map_if(data, to_ag,
                                      ~ .x %>%
                                          dtplyr::lazy_dt()%>%
                                          group_by_at(vars("geo_out","statut",!!all.vars(by)))%>%
                                          summarise_at(vars(varn),~sum(.x*pds_w))%>%
                                          ungroup()%>%
                                          as_tibble()%>%
                                          rename(geo=geo_out)
                                      )
                   )%>%
            mutate(data=purrr::map_if(data, !to_ag,
                                      ~ .x %>%
                                          select(-geo)%>%
                                          rename(geo=geo_out)%>%
                                          ungroup())
                   )%>%
            tidyr::unnest(cols = c(data))%>%
            ungroup()%>%
            select_at(vars(all_of(cols_to_keep),"statut"))%>%
            rename(geo_out=geo)
        
    }

  if ("geo_out" %in% names(out)){
      if (type_in != "cp" & ("geo" %in% names(out)))
        out%<>%
          rename_at(vars("geo_out"), ~ paste0(type_out,"_out"))
      else 
          out%<>%
          rename_at(vars("geo_out"), ~ paste0(type_out))
      }
    
  if ("geo" %in% names(out))
    out%<>%
      rename_with(~ type_in, all_of("geo"))

  out%>%
    rename_at(vars(starts_with("pds_")),~paste0(strsplit(.x,"_")[[1]][1],"_",type_out))%>%
    mutate(annee_geo = geo_out)%>%
    relocate(statut, .after = last_col())%>%
    relocate(annee_geo, .after = last_col())

}


  ## if (!is.null(data) & data_by){
  ##   data%<>%ungroup()
  ##   if (!any(str_detect(names(data),paste0("^",type_out,"$"))))
  ##     data[,type_out] <- NA
    
##   data%<>%
  ##     dtplyr::lazy_dt()%>%
  ##     group_by_at(vars(!!all.vars(geo),!!all.vars(by)))%>%
  ##     summarise_if(is.numeric,~sum(.x)) %>%
  ##     ungroup()%>%
  ##     as_tibble()
  ##   data%<>%ag_call(., by=atr$by_w)
  ## }
  

