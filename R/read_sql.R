##' Extract data from the SQLite database dts_com
##'
##' @param dt data in the SQLite database \code{\link{dts_com.sqlite}}
##' @section Eight data sets available:
##' \describe{
##' \itemize{
##' \item \code{pop_com}: communes' population size by one year age and sex for years 2006 to 2018
##' \item \code{pass_com}: full correpondance of communes Id for years 2003 to 2021
##' \item \code{pass_iris}: full correpondance of iris Id for years 2016 to 2021
##' \item \code{fus_com}: data listing commune's fusions
##' \item \code{scis_com}: data listing commune's scissions
##' \item \code{p_cp_iris}: probability for an observation from postal code to belong to an iris (P(iris|cp))
##' \item \code{p_cp_com}: probability for an observation from postal code to belong to an commune (P(com|cp))
##' \item \code{ref_geo}: reference table for iris and comunes for years 2008 to 2020
##' }
##' }
##' @return A tibble
##' @author Edouard Chatignoux
##' @export
##' @importFrom magrittr %$% 
##' @import dplyr
##' @seealso \code{\link{dts_com.sqlite}}
##' @examples
##' get_data(pass_com)
get_data <- function(dt){
  dt <- deparse(substitute(dt))
  con_com <- system.file("extdata", "dts_com.sqlite", package = "COMversion")
  con_com <- DBI::dbConnect(RSQLite::SQLite(), con_com)
  dt <- dplyr::tbl(con_com, dt)%>%dplyr::collect()
  DBI::dbDisconnect(con_com)
  dt
  }


