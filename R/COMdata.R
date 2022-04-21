#' Data for conversion.
#'
##' Datas used for conversion.
##'
##' @name COMdata
##' @format Internal data bases:
##' \enumerate{
##' \item \code{fus_com}: data listing commune's fusions
##' \itemize{
##' \item \code{annee_modif} Year of fusion
##' \item \code{com_ini} Id of the commune before the fusion
##' \item \code{com_fin} Id of the commune after the fusion
##' }
##' \item \code{scis_com}: data listing commune's scissions:
##' \itemize{
##' \item \code{annee_modif} Year of scission
##' \item \code{com_ini} Id of the commune before the scissions
##' \item \code{com_fin} Id of the commune after the scissions
##' \item \code{lib_com_ini} Name of the commune before the scissions
##' \item \code{lib_com_fin}  Name of the commune after the scissions
##' }
##' \item \code{pass_iris}: list of changes in IRIS from 2016 to 2020
##' \itemize{
##' \item \code{annee_geo} Year of modification
##' \item \code{com_ini} Id of the commune before the modification
##' \item \code{iris_ini} Id of the iris before the modification
##' \item \code{com_fin} Id of the commune after the modification
##' \item \code{iris_fin} Id of the iris after the modification
##' }
##' \item \code{p_cp_iris}: probability for an observation from postal code to belong to an iris (P(iris|cp))
##' \itemize{
##' \item \code{cp} Postal code
##' \item \code{iris} Id of the iris
##' \item \code{cage} Age class
##' \item \code{sexe} Sexe
##' \item \code{p_i} Probability that an iris is within the cp (sum(p_ic)=1 by cp)
##' }
##' \item \code{p_cp_com}: probability for an observation from postal code to belong to an commune (P(com|cp))
##' \itemize{
##' \item \code{cp} Postal code
##' \item \code{com} Id of the commune
##' \item \code{age} Age in year
##' \item \code{sexe} Sexe
##' \item \code{p_i} Probability that a commune is within the cp (sum(p_ic)=1 by cp)
##' }
##' \item \code{pass_com}: full correpondance of communes Id for years 2003 to 2021:
##' \itemize{
##' \item \code{NIVGEO} Type of commune (ARM - arrondissement - or COM - commune)
##' \item \code{com_YEAR} Id of the commune for each YEAR from 2003 to 2021
##' }
##' \item \code{pop_com}: communes' population size by one year age and sex for years 2006 to 2018, for communes who changed (i.e. communes in scis_com and fus_com):
##' \itemize{
##' \item \code{annee_pop} Year of the population size estimates
##' \item \code{annee_geo} Year of the commune version (annee_pop+2 until 2016, annee_pop+3 since 2016)
##' \item \code{sexe} Sex : 1 = men, 2 = women
##' \item \code{com} Commune id
##' \item \code{age} Age in year (from 0 to 99)
##' \item \code{pop} Pop size
##' }
##' \item \code{ref_geo}: reference table for iris and comunes for years 2008 to 2020
##' \itemize{
##' \item \code{annee_geo} Year of the geo version
##' \item \code{com} Commune id
##' \item \code{iris} IRIS id
##' \item \code{lib_com} Commune name
##' \item \code{lib_iris} IRIS name
##' }
##' }
##' @source Recensement de la population \url{https://www.insee.fr/fr/metadonnees/source/serie/s1321}
##' @source Données de référence communes \url{https://www.insee.fr/fr/information/2028028}
##' @source Données de référence IRIS \url{https://www.insee.fr/fr/information/2017499}
##' @source Correspondance codes postaux communes pour la géographie 2019 \url{https://www.insee.fr/fr/information/2017499}
##' @docType data
##' @keywords datasets
##' @examples
##' COMversion:::fus_com
NULL

