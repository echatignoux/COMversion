---
title: Logique de correspondance entre les millésimes d'IRIS
output: 
  rmarkdown::html_vignette:
    keep_md: true
vignette: >
  %\VignetteIndexEntry{Logique de correspondance entre les millésimes d'IRIS}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---


```r
 knitr::opts_chunk$set(eval = TRUE, echo=T, cache=T,message = FALSE , warning = FALSE, include=TRUE )
```





Position du problème
====================

Millésimes d'IRIS
-----------------

Les IRIS évoluent dans le temps, et on ne dispose pas dans les bases
de l'INSEE d'une table stricte de correspondance entre les millésimes
des IRIS.

Les modifications d'IRIS peuvent provenir de :

1. Création/fusion d'IRIS existants

2. Fusion/scission de communes

3. Échange de parcelles


Documentation disponible
------------------------

L'INSEE met à disposition des tables de référentiels d'IRIS (liste des
IRIS officiels pour une année données), ainsi qu'une table listant les
modification survenue dans les IRIS les 5 années précédentes.

Si les référentiels d'IRIS pour une année donnée sont complets et fiables, la
documentation sur les modification est assez fragmentaire, voir
parfois trompeuse, et ne permet pas à elle seule de construire une
table de passage entre les différents millésimes.

Ces difficultés d'utilisation de la documentation sont de deux ordres.

### Modifications sur les 5 dernières années ###

D'une part, les modifications rapportées dans les onglets couvrent une
période de 5 ans, sans que l'année de modification réelle de l'IRIS
soit rapportée dans la table.

Par exemple, dans la table des modifications d'IRIS de 2017, l'IRIS
"490180103" est rapporté comme étant la fusion de plusieurs IRIS de
2016, du fait de fusion de communes: 


```r
library(kableExtra)
modif_2017 %>%
  filter(IRIS_FIN=="490180103")%>%
  kbl%>%
  kable_styling()
```

<table class="table" style="margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:right;"> annee_modif </th>
   <th style="text-align:left;"> IRIS_INI </th>
   <th style="text-align:left;"> COM_INI </th>
   <th style="text-align:left;"> LIB_COM_INI </th>
   <th style="text-align:left;"> IRIS_FIN </th>
   <th style="text-align:left;"> COM_FIN </th>
   <th style="text-align:left;"> LIB_COM_FIN </th>
   <th style="text-align:left;"> MODIF_IRIS </th>
   <th style="text-align:left;"> NATURE_MODIF </th>
   <th style="text-align:left;"> an </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:right;"> 2017 </td>
   <td style="text-align:left;"> 491570000 </td>
   <td style="text-align:left;"> 49157 </td>
   <td style="text-align:left;"> Le Guédeniau </td>
   <td style="text-align:left;"> 490180103 </td>
   <td style="text-align:left;"> 49018 </td>
   <td style="text-align:left;"> Baugé-en-Anjou </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> Rétablissement/Fusion de communes irisées </td>
   <td style="text-align:left;"> 2017 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 2017 </td>
   <td style="text-align:left;"> 491160000 </td>
   <td style="text-align:left;"> 49116 </td>
   <td style="text-align:left;"> Cuon </td>
   <td style="text-align:left;"> 490180103 </td>
   <td style="text-align:left;"> 49018 </td>
   <td style="text-align:left;"> Baugé-en-Anjou </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> Rétablissement/Fusion de communes irisées </td>
   <td style="text-align:left;"> 2017 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 2017 </td>
   <td style="text-align:left;"> 490310000 </td>
   <td style="text-align:left;"> 49031 </td>
   <td style="text-align:left;"> Bocé </td>
   <td style="text-align:left;"> 490180103 </td>
   <td style="text-align:left;"> 49018 </td>
   <td style="text-align:left;"> Baugé-en-Anjou </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> Rétablissement/Fusion de communes irisées </td>
   <td style="text-align:left;"> 2017 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 2017 </td>
   <td style="text-align:left;"> 490790000 </td>
   <td style="text-align:left;"> 49079 </td>
   <td style="text-align:left;"> Chartrené </td>
   <td style="text-align:left;"> 490180103 </td>
   <td style="text-align:left;"> 49018 </td>
   <td style="text-align:left;"> Baugé-en-Anjou </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> Rétablissement/Fusion de communes irisées </td>
   <td style="text-align:left;"> 2017 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 2017 </td>
   <td style="text-align:left;"> 492450000 </td>
   <td style="text-align:left;"> 49245 </td>
   <td style="text-align:left;"> Pontigné </td>
   <td style="text-align:left;"> 490180103 </td>
   <td style="text-align:left;"> 49018 </td>
   <td style="text-align:left;"> Baugé-en-Anjou </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> Rétablissement/Fusion de communes irisées </td>
   <td style="text-align:left;"> 2017 </td>
  </tr>
</tbody>
</table>

Le problème, c'est que ces mofications de communes ont eu lieu en
2016, et non en 2017, comme le montre la table de passage des communes.


```r
ref_com %>%
  filter(com_2017 == "49018") %>%
  select(com_2015:com_2017) %>%
  unique() %>%
  kbl%>%
  kable_styling()
```

<table class="table" style="margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> com_2015 </th>
   <th style="text-align:left;"> com_2016 </th>
   <th style="text-align:left;"> com_2017 </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 49018 </td>
   <td style="text-align:left;"> 49018 </td>
   <td style="text-align:left;"> 49018 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 49031 </td>
   <td style="text-align:left;"> 49018 </td>
   <td style="text-align:left;"> 49018 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 49079 </td>
   <td style="text-align:left;"> 49018 </td>
   <td style="text-align:left;"> 49018 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 49097 </td>
   <td style="text-align:left;"> 49018 </td>
   <td style="text-align:left;"> 49018 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 49101 </td>
   <td style="text-align:left;"> 49018 </td>
   <td style="text-align:left;"> 49018 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 49116 </td>
   <td style="text-align:left;"> 49018 </td>
   <td style="text-align:left;"> 49018 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 49128 </td>
   <td style="text-align:left;"> 49018 </td>
   <td style="text-align:left;"> 49018 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 49143 </td>
   <td style="text-align:left;"> 49018 </td>
   <td style="text-align:left;"> 49018 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 49157 </td>
   <td style="text-align:left;"> 49018 </td>
   <td style="text-align:left;"> 49018 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 49315 </td>
   <td style="text-align:left;"> 49018 </td>
   <td style="text-align:left;"> 49018 </td>
  </tr>
</tbody>
</table>

Cette liste des modifications rapportées pour cet IRIS est donc obsolète
pour 2017. 

Celà pourrait être sans conséquence si l'IRIS "490180103" n'avait pas
changé entre 2016 et 2017. Or, il se trouve que l'IRIS "490180103"
n'existait pas en 2016 et est apparu en 2017...

On se trouve ici dans un cas de figure tordu, où, pour un IRIS qui
apparait en 2017, on dispose d'information dans la table des
modifications, mais que ces informations concernent des modifications
antérieures apportées à un IRIS parent de l'IRIS "490180103" en 2016. 

Il s'agit dans ce cas de l'IRIS "490180000", qui résultait de la
fusion des communes en 2016, et qui a été redivisé en 2017 en 5
nouveaux IRIS, pour lesquels on ne dispose pas de documentation
adaptée dans les tables INSEE.

Si on va chercher dans la table des référentiels, la situation
s'éclaircit : la commune "49018", non irisée en 2016, est découpée en
IRIS en 2017.


```r
ref_iris %>%
  filter(annee_geo %in% 2016:2017) %>%
  select(annee_geo,dt_ref)%>%
  unnest() %>%
  filter( com == "49018") %>%
  kbl%>%
  kable_styling()
```

<table class="table" style="margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:right;"> annee_geo </th>
   <th style="text-align:left;"> iris </th>
   <th style="text-align:left;"> lib_iris </th>
   <th style="text-align:left;"> com </th>
   <th style="text-align:left;"> typ_iris </th>
   <th style="text-align:left;"> modif_iris </th>
   <th style="text-align:left;"> triris </th>
   <th style="text-align:left;"> grd_quart </th>
   <th style="text-align:left;"> libcom </th>
   <th style="text-align:left;"> uu2010 </th>
   <th style="text-align:left;"> reg </th>
   <th style="text-align:left;"> dep </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:right;"> 2016 </td>
   <td style="text-align:left;"> 490180000 </td>
   <td style="text-align:left;"> Baugé-en-Anjou (commune non irisée) </td>
   <td style="text-align:left;"> 49018 </td>
   <td style="text-align:left;"> Z </td>
   <td style="text-align:left;"> 0 </td>
   <td style="text-align:left;"> ZZZZZZ </td>
   <td style="text-align:left;"> 4901800 </td>
   <td style="text-align:left;"> Baugé-en-Anjou </td>
   <td style="text-align:left;"> 49306 </td>
   <td style="text-align:left;"> 52 </td>
   <td style="text-align:left;"> 49 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 2017 </td>
   <td style="text-align:left;"> 490180101 </td>
   <td style="text-align:left;"> Baugé </td>
   <td style="text-align:left;"> 49018 </td>
   <td style="text-align:left;"> H </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> ZZZZZZ </td>
   <td style="text-align:left;"> 4901801 </td>
   <td style="text-align:left;"> Baugé-en-Anjou </td>
   <td style="text-align:left;"> 49306 </td>
   <td style="text-align:left;"> 52 </td>
   <td style="text-align:left;"> 49 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 2017 </td>
   <td style="text-align:left;"> 490180102 </td>
   <td style="text-align:left;"> Vieil Baugé </td>
   <td style="text-align:left;"> 49018 </td>
   <td style="text-align:left;"> H </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> ZZZZZZ </td>
   <td style="text-align:left;"> 4901801 </td>
   <td style="text-align:left;"> Baugé-en-Anjou </td>
   <td style="text-align:left;"> 49306 </td>
   <td style="text-align:left;"> 52 </td>
   <td style="text-align:left;"> 49 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 2017 </td>
   <td style="text-align:left;"> 490180103 </td>
   <td style="text-align:left;"> Bocé </td>
   <td style="text-align:left;"> 49018 </td>
   <td style="text-align:left;"> H </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> ZZZZZZ </td>
   <td style="text-align:left;"> 4901801 </td>
   <td style="text-align:left;"> Baugé-en-Anjou </td>
   <td style="text-align:left;"> 49306 </td>
   <td style="text-align:left;"> 52 </td>
   <td style="text-align:left;"> 49 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 2017 </td>
   <td style="text-align:left;"> 490180201 </td>
   <td style="text-align:left;"> Clefs </td>
   <td style="text-align:left;"> 49018 </td>
   <td style="text-align:left;"> H </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> ZZZZZZ </td>
   <td style="text-align:left;"> 4901802 </td>
   <td style="text-align:left;"> Baugé-en-Anjou </td>
   <td style="text-align:left;"> 49306 </td>
   <td style="text-align:left;"> 52 </td>
   <td style="text-align:left;"> 49 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 2017 </td>
   <td style="text-align:left;"> 490180202 </td>
   <td style="text-align:left;"> Cheviré-le-Rouge </td>
   <td style="text-align:left;"> 49018 </td>
   <td style="text-align:left;"> H </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> ZZZZZZ </td>
   <td style="text-align:left;"> 4901802 </td>
   <td style="text-align:left;"> Baugé-en-Anjou </td>
   <td style="text-align:left;"> 49306 </td>
   <td style="text-align:left;"> 52 </td>
   <td style="text-align:left;"> 49 </td>
  </tr>
</tbody>
</table>



<div class="figure">
<img src="passage_iris_files/figure-html/fig1-1.svg" alt="Illustration du problème de documentation des passages." width="100%" />
<p class="caption">Illustration du problème de documentation des passages.</p>
</div>

A noter que dans ce cas de figure, les IRIS listés en 2016 comme
parents de "490180103" ne sont pas dans le référentiel des IRIS de
2016 (mais dans celui de 2015, soit avant la fusion des communes en 2016).

### Modifications non documentées ###

A l'invserse, certaines modifications ne sont pas documentées.
Ex. : entre 2016 et 2017, 240530201 fusionne avec l'IRIS 244470000 pour
devenir 240530103,  sans que celà soit listé dans les onglets modif_iris.


<table class="table" style="margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:right;"> annee_modif </th>
   <th style="text-align:left;"> IRIS_INI </th>
   <th style="text-align:left;"> COM_INI </th>
   <th style="text-align:left;"> LIB_COM_INI </th>
   <th style="text-align:left;"> IRIS_FIN </th>
   <th style="text-align:left;"> COM_FIN </th>
   <th style="text-align:left;"> LIB_COM_FIN </th>
   <th style="text-align:left;"> MODIF_IRIS </th>
   <th style="text-align:left;"> NATURE_MODIF </th>
   <th style="text-align:left;"> an </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:right;"> 2017 </td>
   <td style="text-align:left;"> 240130000 </td>
   <td style="text-align:left;"> 24013 </td>
   <td style="text-align:left;"> Atur </td>
   <td style="text-align:left;"> 240530103 </td>
   <td style="text-align:left;"> 24053 </td>
   <td style="text-align:left;"> Boulazac Isle Manoire </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> Rétablissement/Fusion de communes irisées </td>
   <td style="text-align:left;"> 2017 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 2017 </td>
   <td style="text-align:left;"> 244470000 </td>
   <td style="text-align:left;"> 24447 </td>
   <td style="text-align:left;"> Sainte-Marie-de-Chignac </td>
   <td style="text-align:left;"> 240530103 </td>
   <td style="text-align:left;"> 24053 </td>
   <td style="text-align:left;"> Boulazac Isle Manoire </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> Rétablissement/Fusion de communes irisées </td>
   <td style="text-align:left;"> 2017 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 2017 </td>
   <td style="text-align:left;"> 244390000 </td>
   <td style="text-align:left;"> 24439 </td>
   <td style="text-align:left;"> Saint-Laurent-sur-Manoire </td>
   <td style="text-align:left;"> 240530103 </td>
   <td style="text-align:left;"> 24053 </td>
   <td style="text-align:left;"> Boulazac Isle Manoire </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> Rétablissement/Fusion de communes irisées </td>
   <td style="text-align:left;"> 2017 </td>
  </tr>
</tbody>
</table>

<div class="figure">
<img src="passage_iris_files/figure-html/fig2-1.svg" alt="Illustration du problème de documentation non documentées." width="100%" />
<p class="caption">Illustration du problème de documentation non documentées.</p>
</div>


Logique de construction d'une table de passage
=============================================
Pour illustrer la logique de construction de la table de passage et
les choix méthodologiques, on se focalise sur le passage entre les
millésimes 2016 et 2017.

Travail à partir des modifications de communes
----------------------------------------------

### Pas de modification d'IRIS dans la commune ###

On sélectionne les IRIS dont les numéros sont inchangés entre deux
millésimes : même numéro d'iris en 2016 et 2017.


```r
match1 <-
  ref_fwd %>% 
  group_by(com) %>%
  filter(out,inn)%>%
  mutate(com_fin=com,iris_fin=iris,match=1)%>%
  select(com,iris,com_out=com_fin,iris_out=iris_fin,match)
match1
```

```
## # A tibble: 49,713 × 5
## # Groups:   com [35,449]
##    com   iris      com_out iris_out  match
##    <chr> <chr>     <chr>   <chr>     <dbl>
##  1 01001 010010000 01001   010010000     1
##  2 01002 010020000 01002   010020000     1
##  3 01004 010040101 01004   010040101     1
##  4 01004 010040102 01004   010040102     1
##  5 01004 010040201 01004   010040201     1
##  6 01004 010040202 01004   010040202     1
##  7 01005 010050000 01005   010050000     1
##  8 01006 010060000 01006   010060000     1
##  9 01007 010070000 01007   010070000     1
## 10 01008 010080000 01008   010080000     1
## # … with 49,703 more rows
```

### Modification de numéro d'IRIS dans les communes non irisées ###

Des changements de numéros d'IRIS peuvent intervenir lors d'échange de
parcelles, sans que la commune (non irisées) n'ait été modifiée. On
traite ce cas ici.


```r
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
match2
```

```
## # A tibble: 0 × 5
## # Groups:   com [0]
## # … with 5 variables: com <chr>, iris <chr>, iris_out <chr>, com_out <chr>, match <dbl>
```


### Fusion de communes non irisées ###

Il s'agit ici des IRIS présents en 2016, mais non retrouvé en 2017 du
fait de fusions entre des communes _non irisées_.


```r
match3<-
  ref_fwd%>%
  filter(is.na(out))%>%
  right_join(
    out%>%filter(statut=="Fusion")%>%
      left_join(dt_ref_geo%>%filter(annee_geo==2016+1)%>%select(com_out=com,iris_out=iris))%>%
      filter(com != com_out)%>%
      group_by(com)%>%
      filter(n()==1)
  ) %>%
  mutate(match=3)%>%
  select(com,iris,com_out,iris_out,match) %>%
  arrange(iris_out)
match3
```

```
## # A tibble: 403 × 5
##    com   iris      com_out iris_out  match
##    <chr> <chr>     <chr>   <chr>     <dbl>
##  1 01172 011720000 01095   010950000     3
##  2 01316 013160000 01098   010980000     3
##  3 03318 033180000 03168   031680000     3
##  4 04198 041980000 04033   040330000     3
##  5 05175 051750000 05101   051010000     3
##  6 08371 083710000 08053   080530000     3
##  7 08475 084750000 08053   080530000     3
##  8 08072 080720000 08491   084910000     3
##  9 09317 093170000 09062   090620000     3
## 10 12020 120200000 12090   120900000     3
## # … with 393 more rows
```

### Scissions de communes ###

Il s'agit ici des IRIS présents en 2017, mais non retrouvé en 2016 du
fait de scission de communes.


```r
match4<-
  ref_fwd%>%
  filter(is.na(inn) & !is.na(out))%>%
  rename(com_out=com,iris_out=iris)%>%
  inner_join(out%>%filter(statut=="Scission"))%>%
  left_join(dt_ref_geo%>%filter(annee_geo==2016))%>%
  mutate(match=4)%>%
  select(com,iris,com_out,iris_out,match)
match4
```

```
## # A tibble: 1 × 5
##   com   iris      com_out iris_out  match
##   <chr> <chr>     <chr>   <chr>     <dbl>
## 1 76676 766760000 76601   766010000     4
```

### Création d'IRIS dans des communes non irisées jusque là ###

Un seul IRIS en 2016, plusieurs en 2017, car des IRIS ont été créés
dans une commune non irisée.


```r
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

match5
```

```
## # A tibble: 43 × 5
## # Groups:   com [8]
##    com   iris      iris_out  com_out match
##    <chr> <chr>     <chr>     <chr>   <dbl>
##  1 49018 490180000 490180101 49018       5
##  2 49018 490180000 490180102 49018       5
##  3 49018 490180000 490180103 49018       5
##  4 49018 490180000 490180201 49018       5
##  5 49018 490180000 490180202 49018       5
##  6 49050 490500000 490500101 49050       5
##  7 49050 490500000 490500102 49050       5
##  8 49050 490500000 490500103 49050       5
##  9 49050 490500000 490500104 49050       5
## 10 49050 490500000 490500105 49050       5
## # … with 33 more rows
```

### Bilan des modifications de communes ###

A ce stade, il reste une centaine de modifications d'IRIS non traitées.


```r
ref_tmp<-
  match1%>%
  bind_rows(match2)%>%
  bind_rows(match3)%>%
  bind_rows(match4)%>%
  bind_rows(match5) %>% 
  unique()

ref_fwd %>%
  filter(is.na(out)) %>% 
  anti_join(ref_tmp %>% select(iris)) 
```

```
## # A tibble: 94 × 4
##    com   iris      inn   out  
##    <chr> <chr>     <lgl> <lgl>
##  1 08443 084430000 TRUE  NA   
##  2 08493 084930000 TRUE  NA   
##  3 24053 240530201 TRUE  NA   
##  4 24447 244470000 TRUE  NA   
##  5 27265 272650000 TRUE  NA   
##  6 35209 352090000 TRUE  NA   
##  7 35254 352540000 TRUE  NA   
##  8 49001 490010000 TRUE  NA   
##  9 49014 490140000 TRUE  NA   
## 10 49037 490370000 TRUE  NA   
## # … with 84 more rows
```

```r
ref_fwd %>%
  filter(is.na(inn)) %>%  
  anti_join(ref_tmp %>% select(iris = iris_out))  
```

```
## # A tibble: 61 × 4
##    com   iris      inn   out  
##    <chr> <chr>     <lgl> <lgl>
##  1 08490 084900201 NA    TRUE 
##  2 24053 240530103 NA    TRUE 
##  3 27679 276790201 NA    TRUE 
##  4 35069 350690201 NA    TRUE 
##  5 49023 490230202 NA    TRUE 
##  6 49023 490230203 NA    TRUE 
##  7 49023 490230204 NA    TRUE 
##  8 49023 490230205 NA    TRUE 
##  9 49023 490230206 NA    TRUE 
## 10 49092 490920202 NA    TRUE 
## # … with 51 more rows
```

Utilisation de la table des modifcations
----------------------------------------

### Modification d'iris documentée dans la table des modifs ###

Il s'agit ici des IRIS présents en 2016, non retrouvé en 2017,
dont les modifs sont documentées dans la table des modifs 2017.
On espère que les infos dans la table des modifs sont les bonnes...


```r
match6 <-
  ref_fwd%>%
  filter(is.na(out)) %>% 
  anti_join(ref_tmp %>%
              select(com=com_out,iris=iris_out)) 

match6 %<>%
  left_join(
    dt_pass%>%
      filter(annee_geo==2016+1)%>%
      rename(iris=iris_ini,com=com_ini)
  )%>%
  filter(!is.na(annee_geo))%>%
  select(com,iris,com_out=com_fin,iris_out=iris_fin)%>%
  inner_join(out)%>%
  select(com,iris,com_out,iris_out)%>%
  mutate(match=6)

match6 %>%
  group_by(iris) %>%
  mutate(n = n()) %$%
  table(n)
```

```
## n
##   1 
## 101
```

```r
match6
```

```
## # A tibble: 101 × 5
##    com   iris      com_out iris_out  match
##    <chr> <chr>     <chr>   <chr>     <dbl>
##  1 08443 084430000 08490   084900201     6
##  2 08493 084930000 08490   084900201     6
##  3 24447 244470000 24053   240530103     6
##  4 27265 272650000 27679   276790201     6
##  5 35209 352090000 35069   350690201     6
##  6 35254 352540000 35069   350690201     6
##  7 49001 490010000 49050   490500102     6
##  8 49014 490140000 49331   493310204     6
##  9 49018 490180000 49018   490180101     6
## 10 49037 490370000 49331   493310202     6
## # … with 91 more rows
```


### Modification d'iris non documentée dans la table des modifs ###
En entrée mais pas en sortie, pas dans dt_pass : noms modifiés lors des fusions
Ex. : entre 2016 et 2017, 240530201 devient 240530103,
sans que celà soit listé dans les onglets modif_iris


```r
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
  left_join(dt_pass%>%filter(annee_geo==2016+1)%>%rename(iris=iris_ini,com=com_ini))%>%
  filter(is.na(annee_geo))%>%
  left_join(out)
match7%$%table(statut)
```

```
## statut
##    Fusion Inchangée  Scission 
##         1         0         0
```

```r
match7 %<>%
  select(com,iris,com_out)%>%
  left_join(dt_ref_geo%>%
              filter(annee_geo==2016+1)%>%
              select(com_out=com,iris_out=iris)
            ) %>%
  mutate(match=7)

## Attention, certains num d'iris correspondent à d'anciens IRIS. On les cherche ici.
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

match7
```

```
## # A tibble: 1 × 5
##   com   iris      com_out iris_out  match
##   <chr> <chr>     <chr>   <chr>     <dbl>
## 1 24053 240530201 24053   240530103     7
```

### Bilan à ce stade ###

Il reste encore 15 IRIS apparus en 2017 qui n'ont pas
de correspondance en 2016.


```r
ref_tmp<-
  match1%>%
  bind_rows(match2)%>%
  bind_rows(match3)%>%
  bind_rows(match4)%>%
  bind_rows(match5)%>%
  bind_rows(match6)%>%
  bind_rows(match7)%>%
  unique()

ref_fwd %>%
  filter(is.na(out)) %>% 
  anti_join(ref_tmp %>% select(iris,com))
```

```
## # A tibble: 0 × 4
## # … with 4 variables: com <chr>, iris <chr>, inn <lgl>, out <lgl>
```

```r
ref_fwd %>%
  filter(is.na(inn)) %>%  
  anti_join(ref_tmp %>% select(iris = iris_out,com=com_out)) 
```

```
## # A tibble: 15 × 4
##    com   iris      inn   out  
##    <chr> <chr>     <lgl> <lgl>
##  1 49023 490230202 NA    TRUE 
##  2 49023 490230203 NA    TRUE 
##  3 49023 490230204 NA    TRUE 
##  4 49023 490230205 NA    TRUE 
##  5 49023 490230206 NA    TRUE 
##  6 49092 490920302 NA    TRUE 
##  7 49092 490920303 NA    TRUE 
##  8 49092 490920304 NA    TRUE 
##  9 49092 490920305 NA    TRUE 
## 10 49301 493010202 NA    TRUE 
## 11 49301 493010203 NA    TRUE 
## 12 49301 493010204 NA    TRUE 
## 13 49301 493010205 NA    TRUE 
## 14 49301 493010206 NA    TRUE 
## 15 49301 493010207 NA    TRUE
```


Utilisation de shapefiles
-------------------------

C'est le dernier cas de figure, où des IRIS sont apparus en 2017, sans
que l'on ne retrouve la trace de ces apparitions dans la table des
modifications de 2017, ni que ces apparitions soient dues à des modificaitions
de communes.
On utilise des shapes files pour voir où sont intervenues les modifications.


```r
match8<-
  ref_fwd%>%
  filter(is.na(inn) & !is.na(out))%>%
  anti_join(ref_tmp %>%
              select(com=com_out,iris=iris_out))

geo <- 2016
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

match8
```

```
## # A tibble: 15 × 5
##    com   iris      iris_out  match com_out
##    <chr> <chr>     <chr>     <dbl> <chr>  
##  1 49023 490230201 490230204     8 49023  
##  2 49301 493010201 493010206     8 49301  
##  3 49092 490920301 490920302     8 49092  
##  4 49023 490230201 490230206     8 49023  
##  5 49023 490230201 490230202     8 49023  
##  6 49092 490920301 490920305     8 49092  
##  7 49301 493010201 493010203     8 49301  
##  8 49301 493010201 493010205     8 49301  
##  9 49301 493010201 493010204     8 49301  
## 10 49092 490920301 490920304     8 49092  
## 11 49023 490230201 490230205     8 49023  
## 12 49092 490920301 490920303     8 49092  
## 13 49301 493010201 493010207     8 49301  
## 14 49023 490230201 490230203     8 49023  
## 15 49301 493010201 493010202     8 49301
```

```r
ref_tmp<-
  match1%>%
  bind_rows(match2)%>%
  bind_rows(match3)%>%
  bind_rows(match4)%>%
  bind_rows(match5)%>%
  bind_rows(match6)%>%
  bind_rows(match7)%>%
  bind_rows(match8)%>%
  unique()
```

On a bien traité tous les cas à ce stade.


```r
ref_fwd %>%
  filter(inn) %>% 
  anti_join(ref_tmp %>% select(iris, com)) 
```

```
## # A tibble: 0 × 4
## # … with 4 variables: com <chr>, iris <chr>, inn <lgl>, out <lgl>
```

```r
ref_fwd %>%
  filter(out) %>% 
  anti_join(ref_tmp %>% select(iris = iris_out, com=com_out))
```

```
## # A tibble: 0 × 4
## # … with 4 variables: com <chr>, iris <chr>, inn <lgl>, out <lgl>
```

Illustration:

L'IRIS "490230202" est présent en 2017, et est listé comme étant lié à
l'IRIS "493750000" en 2016. 


```r
modif_2017 %>% filter(IRIS_FIN=="490230202")
```

```
## # A tibble: 1 × 10
##   annee_modif IRIS_INI  COM_INI LIB_COM_INI          IRIS_FIN  COM_FIN LIB_COM_FIN         MODIF_IRIS NATURE_…¹ an   
##         <dbl> <chr>     <chr>   <chr>                <chr>     <chr>   <chr>               <chr>      <chr>     <chr>
## 1        2017 493750000 49375   Villedieu-la-Blouère 490230202 49023   Beaupréau-en-Mauges 3          Rétablis… 2017 
## # … with abbreviated variable name ¹​NATURE_MODIF
```

L'IRIS "493750000" n'est cependant pas présent en 2016, mais en 2015.
Il s'agit ici d'une reprise des IRIS qui existaient au préalable à une
fusion de commune intervenue en 2016.

Les IRIS qui correspondaient aux communes de 2015, qui avaient été
fusionné en l'IRIS "490230201" 2016 en même temps que les communes,
ont été rétablis en 2017, mais avec de nouveaux numéros. 

Difficile de faire le lien dans ce contexte sans passer par des
cartes.

On aurait cependant pû repasser également par les historiques de modifications d'IRIS des
annnées antérieures (2016 en l'occurence).


```r
modif_2016 %>% filter(IRIS_FIN=="490230201")
```

```
## # A tibble: 9 × 10
##   ANNEE_MODIF IRIS_INI  COM_INI LIB_COM_INI              IRIS_FIN  COM_FIN LIB_COM_FIN         MODIF_…¹ NATUR…² an   
##         <dbl> <chr>     <chr>   <chr>                    <chr>     <chr>   <chr>               <chr>    <chr>   <chr>
## 1        2016 493120000 49312   Saint-Philbert-en-Mauges 490230201 49023   Beaupréau-en-Mauges 3        Rétabl… 2016 
## 2        2016 493750000 49375   Villedieu-la-Blouère     490230201 49023   Beaupréau-en-Mauges 3        Rétabl… 2016 
## 3        2016 490720000 49072   La Chapelle-du-Genêt     490230201 49023   Beaupréau-en-Mauges 3        Rétabl… 2016 
## 4        2016 491510000 49151   Gesté                    490230201 49023   Beaupréau-en-Mauges 3        Rétabl… 2016 
## 5        2016 491620000 49162   Jallais                  490230201 49023   Beaupréau-en-Mauges 3        Rétabl… 2016 
## 6        2016 491650000 49165   La Jubaudière            490230201 49023   Beaupréau-en-Mauges 3        Rétabl… 2016 
## 7        2016 492390000 49239   Le Pin-en-Mauges         490230201 49023   Beaupréau-en-Mauges 3        Rétabl… 2016 
## 8        2016 492430000 49243   La Poitevinière          490230201 49023   Beaupréau-en-Mauges 3        Rétabl… 2016 
## 9        2016 490060000 49006   Andrezé                  490230201 49023   Beaupréau-en-Mauges 3        Rétabl… 2016 
## # … with abbreviated variable names ¹​MODIF_IRIS, ²​NATURE_MODIF
```

<div class="figure">
<img src="passage_iris_files/figure-html/fig3-1.svg" alt="Illustration du besoin d'utilisation des shapefiles." width="100%" />
<p class="caption">Illustration du besoin d'utilisation des shapefiles.</p>
</div>
