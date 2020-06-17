// Lecture du fichier xml
CALL apoc.load.xml("file:///natureo.osm")
YIELD value

UNWIND [elt in value._children where elt._type='node'] as nodes
UNWIND [elt in value._children where elt._type='way'] as ways
//UNWIND [elt in value._children where elt._type='relation'] as relations

// Nodes
WITH ways,
nodes.id as id,
nodes.lat as lat,
nodes.lon as lon,
[t in nodes._children] as tags
MERGE (n {id: id})
SET n.lat = lat, n.lon=lon

WITH ways, n, tags
UNWIND tags AS tag
call apoc.create.setProperty(n, tag.k, tag.v)
YIELD node

// Ways
with ways.id as rid,
[t in ways._children where t._type='nd'] as rnodes,
[t in ways._children where t._type='tag'] as rtags

with rnodes, rtags, rid
UNWIND RANGE(1,size(rnodes)-1) AS i
WITH rnodes[i-1] AS a, rnodes[i] AS b, rtags, rid
MATCH (aa {id:a.ref}),(bb {id:b.ref})
MERGE (aa)-[r:NEXT {id:rid}]->(bb)
with r, rtags
unwind rtags as rtag
call apoc.create.setRelProperty(r, rtag.k, rtag.v) yield rel
return *