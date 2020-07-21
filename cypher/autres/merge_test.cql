// Dupliquer les noeuds avant le merge

// import
match (n) detach delete n;

create (a {osmId:1})-[:NEXT {idr:1}]->(b {osmId:2})-[:NEXT {idr:1}]->(c {osmId:3})-[:NEXT {idr:1}]->(d {osmId:4})-[:NEXT {idr:1}]->(e {osmId:5})
with b,c,d create (c)-[:NEXT {idr:2}]->(d)-[:NEXT {idr:2}]->(f {osmId:6})-[:NEXT {idr:2}]->(c)
with b,c,d create (n)-[:NEXT {idr:12}]->(b)-[:NEXT {idr:11}]->(m)
with b,c,d create (d)-[:NEXT {idr:3}]->(h {osmId:8})-[:NEXT {idr:3}]->(g {osmId:7})-[:NEXT {idr:3}]->(b)-[:NEXT {idr:3}]->(c)-[:NEXT {idr:3}]->(d);

// ajouter une relation exterieure hors area (piste cyclable)


// -------------------------------------------------------
// Dupliquer les noeuds avec + d'une relation entre eux			pourchaque parie de noeuds
// -------------------------------------------------------
match (n)-[r]->(m)
with n,m, collect(r) as rels
where size(rels) > 1
with n,m, rels
UNWIND rels as r
MERGE (a :DUPLICATED {osmId:n.osmId, rel_dup:r.idr})
ON CREATE SET a=n, a.rel_dup=r.idr
MERGE (b :DUPLICATED {osmId:m.osmId, rel_dup:r.idr})
ON CREATE SET b=m, b.rel_dup=r.idr
CREATE (a)-[rr :NEXT_DUPLICATE {idr:r.idr}]->(b)
SET rr=r
CREATE (n)-[ro:ORIGINAL]->(m)
SET ro = r
WITH r,a,b,n,m,ro
DELETE r;
// ajouter des tags de num relation sur les NOEUDS qu'on a choisi comme modèle deduplication

// relations internes 
MATCH (n :DUPLICATED)
with n
match (m {osmId:n.osmId})-[r :NEXT {idr:n.rel_dup}]->(s)
where n<>m
CREATE (n)-[rr :NEXT]->(s)
SET rr=r;

MATCH (n :DUPLICATED)
with n
match (m {osmId:n.osmId})<-[r :NEXT {idr:n.rel_dup}]-(s)
where n<>m
CREATE (n)<-[rr :NEXT]-(s)
SET rr=r;

// relations externes
MATCH (n)-[o :ORIGINAL]-(n2)
with n, collect(o.idr) as orel
match (n)-[r :NEXT]->(s)
where not r.idr in orel
MATCH (m :DUPLICATED {osmId:n.osmId})
CREATE (m)-[rr :NEXT]->(s)
SET rr=r;

MATCH (n)-[o :ORIGINAL]-(n2)
with n, collect(o.idr) as orel
match (n)<-[r :NEXT]-(s)
where not r.idr in orel
MATCH (m :DUPLICATED {osmId:n.osmId})
CREATE (m)<-[rr :NEXT]-(s)
SET rr=r;

// suppresion
match (n)-[r:ORIGINAL]-(m)
detach delete n,m;


// Import ------------------------

match (n) detach delete n;

CREATE (a)-[:NEXT {id:'rel1'}]->(b)<-[:EXT {id:'ext'}]-(r)
with a,b CREATE (b)-[:NEXT {id:'rel1'}]->(c)<-[:EXT {id:'ext'}]-(s)
with a,c CREATE (c)-[:NEXT {id:'rel1'}]->(a);

CREATE (a)-[:NEXT {id:'rel2'}]->(b)
with a,b CREATE (b)-[:NEXT {id:'rel2'}]->(c)<-[:EXT {id:'ext'}]-(e)
with a,c CREATE (c)-[:NEXT {id:'rel2'}]->(a)-[:EXT {id:'ext'}]->(d);


//-------------------------------------------------------------------------------------
// création du nouveau noeud
match (n)-[r :NEXT]->(m)
where r.leisure='x' or r.leisure='y'
with r.id as id, collect(n) as ns, collect(m) as ms, collect(r) as rs
unwind ns + ms as nms
with id, collect(distinct nms) as nds, rs[0] as tgs
CREATE (new :MERGED)
set new=tgs

// relations ->
with id,tgs, new, nds
match (n)-[r2]->(s)
where n in nds
and tgs.id<>r2.id
and not s in nds
create (new)-[rr:TEST]->(s)
set rr=r2;

// relations <-
match (n)-[r :NEXT]->(m)
with r.id as id, collect(n) as ns, collect(m) as ms, collect(r) as rs
unwind ns + ms as nms
with id, collect(distinct nms) as nds, rs[0] as tgs

with id,tgs, nds
match (n)<-[r2]-(s)
where n in nds
and tgs.id<>r2.id
and not s in nds
match (new {id:tgs.id})
create (new)<-[rr:TEST]-(s)
set rr=r2;

// suppression
match (n)-[r :NEXT]->(m)
detach delete n,m
return *


// Deuixème version--------------------------------------------------------------------

// création du nouveau noeud
match (n)-[r :NEXT]->(m)
with r.id as id, collect(n) as ns, collect(m) as ms, collect(r) as rs
unwind ns + ms as nms
with id, collect(distinct nms) as nds, rs[0] as tgs
CREATE (new :MERGED)
set new=tgs

// relations ->
with id, tgs, new, nds
match (n)-[r1]->(s1)
where n in nds
and tgs.id<>r1.id
and not s1 in nds

// relations <-
match (n)<-[r2]-(s2)
where n in nds
and tgs.id<>r2.id
and not s2 in nds
create (new)<-[rr1:TEST]-(s1)
set rr1=r1
create (new)-[rr2:TEST]->(s2)
set rr2=r2
// 2 set en même temps

// 2e requete
// suppression des noeuds
with id, nds
unwind nds as n
detach delete n
return *