// requêtes analytiques
match (n :BIO)-[*3]->(:DISTRICT m)
return m.name, count(n)

match (n :BIODIVERSITE)-[]-(s :STREET)
return s.name, count(n) as nb, collect(s) as str
order by nb desc

// Magasins bio par arrondissement
match (n :BIO :SUPERMARCHE)-[*2]-(d :DISTRICT)
return d.name as arr, count(distinct n) as nb, avg(n.lat) as lat, avg(n.lon) as lon		// lat lon moyenne

// Piste cyclable la plus longue
match (n)-[r :PISTE_CYCLABLE]-(m)
return r.osmId, sum(r.longueur) as lg
order by lg desc

// Surface des espaces verts par arrondissement
match (n :BIODIVERSITE)-[*2]-(d :DISTRICT)
return d.name as arr, sum(n.surface) as surface
order by surface desc


match (n :BIODIVERSITE)-[*2]-(d :DISTRICT)
return d.name as arr, sum(n.surface) as surface
order by surface desc

// villes reliées par des pistes cyclables
match (n :CITY)-[:IN_CITY|IN_DSTR|IN_STREET *1..2]-()-[:PISTE_CYCLABLE *]->()-[:IN_CITY|IN_DSTR|IN_STREET *1..2]-(m :CITY)
where n<>m
return n.name,m.name

