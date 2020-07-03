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