// import file
CALL spatial.importOSM('/home/eva/Bureau/ecomap/evry_nodes.osm')

// Retourne les villes
// On utilise `` à cause du caractère ':'
MATCH (n)
WHERE EXISTS(n.`addr:city`)
RETURN DISTINCT n.`addr:city`

// Retourne les magasins avec leur coordonnées
MATCH (tag)-[:TAGS]-(center)-[:GEOM]-(geo)
WHERE EXISTS(tag.shop)
RETURN tag, center, geo

// Ajoute une étiquette aux supermarchés
MATCH (n)-[:TAGS]->(tgs)
WHERE tgs.shop='supermarket'
SET n:Supermarché
RETURN n, tgs

// Ajoute une étiquette aux magasins bio
MATCH (n)-[:TAGS]->(tgs)
WHERE tgs.shop='supermarket'
AND tgs.organic='only'
SET n:MagasinBio
RETURN n, tgs

// Afficher magasins bio sur NeoMap
// (erreur avec un seul magasin)
MATCH (n:MagasinBio)-[:TAGS]->(tgs)
WHERE exists(n.lat)
AND exists(n.lon)
RETURN n.lat as latitude,
n.lon as longitude,
tgs.name as tooltip
LIMIT 10000