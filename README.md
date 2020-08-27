# Ecomap

## Télécharger les données OSM
1. Ouvrir le fichier overpass_query.txt
2. Choisir la zone à étudier et la remplacer dans le début de la requête 
3. Copier la requête dans le formulaire de l'API Overpass : https://lz4.overpass-api.de/query_form.html

## Convertir les données OSM en fichiers CSV
Executer le script python osm_convert/xml_to_csv_gouv.py, avec le fichier OSM en paramètre.
Un nouveau dossier avec le même nom que le fichier passé en paramètre est créé. Ce dossier contient deux fichiers CSV : un fichier contenant les noeuds et un fichier contenant les relations.

## Importer les fichiers CSV dans Neo4j 
1. Créer une nouvelle base de données Neo4j.
2. Déplacer les fichiers CSV dans le dossier import de la base de données.
3. Ouvrir le terminal correspondant à la base de données créée.
4. Ecrire la commande suivante dans le terminal :
bin/neo4j-admin import --nodes=import/nodes.csv --relationships=import/ways.csv
</ol>

## Ajouter les labels sur la base de données Neo4j
1. Lancer la base de données créée.
2. Copier le contenu du fichier cypher/labels.cql dans le formulaire de requête Neo4j.
