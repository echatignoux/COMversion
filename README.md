
# Passage d'une géographie à une autre

La correspondances entre les référentiels géographiques, dans l'espace ou dans le temps, n'est pas toujours un exercice facile.

D'une part, les codes géographiques évoluent dans le temps (e.g. les communes sont regroupées ou scindées), et le référenciel géographique (code officiel géographique - COG) évolue chaque année. Transormer un jeu de données défini pour un référentiel géographique donné (e.g. communes en 2017) en un autre référentiel (e.g. communes en 2020) nécessite donc de donner des règles de passage d'un millésime à un autre (e.g. savoir quelle communes sont scidées entre 2017 et 2020 et comment répartir les données d'une commune A qui devient B et C en 2020 dans B et C).

D'autre part, il n'existe pas toujours d'emboitement strict entre les différents niveaux géographiques (e.g. un code postal peut être à cheval sur les communes A et B, mais ne pas couvrir l'ensemble de ces communes)/

Il convient donc de se munir de règles de passages entre les différents millésimes des géographies et les différents niveaux géographiques.

C'est ce que propose le package `COMversion`.


# Installation

```r

library(remotes)
remotes::install_git("https://gitlab.santepubliquefrance.fr/data/rpackages/comversion")

```

# Documentation

Une vignette de présentation du fonctionnement du paquet et son utilisation est disponible [ici](vignettes/utilisation_COMversion.md)



## Autres ressources

[COGugaison](https://github.com/antuki/COGugaison)
