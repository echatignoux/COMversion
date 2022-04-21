#' Population data in 2013 geography
#'
#' communes' population size by one year age and sex for year 2013 and geography 2015
#' 
#' @name dt_pop_2013
#' @format Tibble/data.frame
#' \itemize{
#' \item \code{annee_pop} Year of population estimates
#' \item \code{annee_geo} Year of the commune version (annee+2 until 2016, annee+3 in 2016 and after)
#' \item \code{sexe} Sex : 1 = men, 2 = women
#' \item \code{com} Commune id
#' \item \code{age} Age in year (from 0 to 99)
#' \item \code{pop} Pop size
#' \item \code{dep} Departement
#' }
#' @source \url{https://www.insee.fr/fr/metadonnees/source/serie/s1321}
#' @seealso \code{\link{get_data}}
#' @docType data
#' @keywords datasets
#' @examples
#' data(dt_pop_2013)
#' dt_pop_2013
NULL

