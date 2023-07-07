
# Passage d'une géographie à une autre

Etablir la correspondances entre les référentiels géographiques, dans
l'espace ou dans le temps, n'est pas toujours un exercice facile. 

D'une part, les codes géographiques évoluent dans le temps (e.g. les
communes sont regroupées ou scindées), et le référenciel géographique
(code officiel géographique - COG) change en conséquence chaque
année. Transormer un jeu de données défini pour un référentiel
géographique donné (e.g. communes en 2017) en un autre référentiel
(e.g. communes en 2020) nécessite donc de donner des règles de passage
d'un millésime à un autre (e.g. savoir quelle communes sont scidées
entre 2017 et 2020 et comment répartir les données d'une commune A qui
devient B et C en 2020 dans B et C). 

D'autre part, il n'existe pas toujours d'emboitement strict entre les
différents niveaux géographiques (e.g. un code postal peut être à
cheval sur les communes A et B, mais ne pas couvrir l'ensemble de ces
communes). 

Il convient donc de se munir de règles de passages entre les
différents millésimes des géographies et les différents niveaux
géographiques. 

C'est ce que propose le package `COMversion`.


# Installation

```r

library(remotes)
remotes::install_git("https://gitlab.santepubliquefrance.fr/data/rpackages/comversion")

```

# Documentation

Une vignette de présentation de la logique de construction des règles
de passage d'une géographie à une autre, du fonctionnement du paquet
et de son utilisation est disponible
[ici](vignettes/utilisation_COMversion.md). 

Une autre [vignette](vignettes/passage_iris.md) présente la logique de
construction d'une table de passage entre les millésimes d'IRIS. 

# Avertissement

Les règles de passage utilisées dans ce paquet sont basées sur des
hypothèses et des données qui comportent des limites. Elles ne
ne constituent donc en aucun cas des règles _officielles_ de passage
entre les géographies.

Merci de nous signaler toute erreur/contradiction auxquelles vous
seriez confronté lors de l'utilisation du paquet.

## Liste des codes postaux
La liste de codes postaux (et leur géographie) date de 2015. Nous
n'avons pas trouvé de référentiel actualisé, mais peut être que c'est
qu'il n'a pas évolué depuis.

## Passage entre des millésimes de communes
La correspondance entre les communes est établie par l'INSEE et est de
ce fait officielle. En cas de scission de communes cependant, la règle
établie dans le paquet est de calculer un poids basé sur les tailles
de population : une commune A séparée en deux communes B et C
l'année N, sera séparée entre B et C au prorata du poids des
populations B et C l'année N. 
Cette règle parrait raisonnable pour des données de santé par exemple,
mais probablement moins pour des données environenentales par exemple.

## Passage entre des millésimes d'IRIS
Il n'existe pas de table de correspondance officielle de passage entre
IRIS. Des règle spécifiques ont donc été choisies pour cet aspect
particulier (voir la [vignette](vignettes/passage_iris.md) à ce
sujet).

Ces règles ne couvrent probablement pas toutes les spécificités
délicates du passage entre les millésimes d'IRIS. L'utilisateur devra
donc se montrer particulièrement vigilant sur les sorties du paquet.

## Passage entre CP et communes/IRIS
La correspondance entre codes postaux et communes/IRIS est établie à
partir de deux sources :

1. Les données Atlas Santé qui liste les correspondances strictes
   (inclusion stricte d'une ou plusieurs communes dans un CP,
   inclusion  stricte de plusieurs CP dans une commune)  ou partielles
   (recouvrement d'une partie d'une commune par un CP)
2. Les données de population de l'INSEE de 2015 par mailles de 200m. 

Pour les correspondances partielles, les CP sont réparties dans les
communes/IRIS au prorata du poids de la population dans les mailles
en 2015. La situation peut bien entendu avoir évolué depuis cette
année, et les poids de 2015 peuvent être assez peu représentatifs de
la situation de 2020 par exemple. 

## Autres ressources

[COGugaison](https://github.com/antuki/COGugaison)
