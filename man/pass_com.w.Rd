% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/pass_com.R
\name{pass_com.w}
\alias{pass_com.w}
\title{Fonction interne pour calculer les poids de passages entre deux années}
\usage{
pass_com.w(
  geo_in = 2016,
  geo_out = 2020,
  by = ~cut(age, breaks = c(-Inf, 50, Inf)) + sexe,
  dt_pop = NULL
)
}
\arguments{
\item{by}{: strates de pop utilisées pour le calcul des poids (peut contenir des formules de type cut)}

\item{dt_pop}{: population (or weigth) table to use (default table if NULL)}

\item{geo_in:}{année de la géo d'entrée}

\item{geo_out:}{année de la géo de sortie}
}
\value{
A tibble
}
\description{
Utilise récursivement pass_com.w.one pour aller de l'année a à l'année b
}
\examples{
pass_com.w(geo_in=2016,geo_out=2020,by=~sexe+toto)
}
\seealso{
\code{\link{pass_com}}, \code{\link{dts_com.sqlite}}
}
\author{
Edouard Chatignoux
}
\keyword{internal}
