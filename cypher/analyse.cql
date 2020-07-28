// requêtes analytiques
match (n :BIO)-[*3]->(:DISTRICT m)
return m.name, count(n)

match (n :BIODIVERSITE)-[]-(s :STREET)
return s.name, count(n) as nb, collect(s) as str
order by nb desc

// Magasins bio
match (n :BIO :SUPERMARCHE)-[*2]-(d :DISTRICT)
return d.name as arr, count(n) as nb, avg(n.lat) as lat, avg(n.lon) as lon		// lat lon du 1er magasin