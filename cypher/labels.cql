//--------------------------------------------------
// Villes et régions 
//--------------------------------------------------
// Départements -> régions 
match (n)
where exists (n.reg)
with distinct n.dpt as ndpt, n.reg as nreg
merge (reg :REG {name:nreg})
create (dpt :DPT {name:ndpt})-[:IN_REG]->(reg);

// Villes -> departements 
match (n)
where exists (n.reg)
with distinct n.city as ncity, n.`city-surface` as nsurface, n.`city-population`as npop, n.`city-centre`as ncentre, n.dpt as ndpt
match (dpt :DPT {name:ndpt})
create (city :CITY {name:ncity, citysurface:nsurface, citypop:npop, citycentre:ncentre})-[:IN_DPT]->(dpt);

// Districts -> villes 
match (n)
where exists (n.district)
with distinct n.district as ndistrict, n.city as ncity, n.dpt as ndpt
match (city :CITY {name:ncity})-[:IN_DPT]->(:DPT {name:ndpt})
create (dstr :DISTRICT {name:ndistrict})-[:IN_CITY]->(city);

// Rues et lieux -> villes 
match (n)
where exists(n.street) and not exists (n.district)
with distinct n.street as nstreet, n.city as ncity, n.dpt as ndpt
match (city :CITY {name:ncity})-[:IN_DPT]->(:DPT {name:ndpt})
create (str :STREET {name:nstreet})-[:IN_CITY]->(city);
	
match (n)
where exists(n.`loc-name`) and not exists (n.district)
with distinct n.`loc-name` as nloc, n.city as ncity, n.dpt as ndpt
match (city :CITY {name:ncity})-[:IN_DPT]->(:DPT {name:ndpt})
create (loc :LOCATION {name:nloc})-[:IN_CITY]->(city);

// Rues et lieux -> districts 
match (n)
where exists(n.street) and exists (n.district)
with distinct n.street as nstreet, n.district as ndistrict, n.city as ncity
match (dstr :DISTRICT {name:ndistrict})-[:IN_CITY]->(:CITY {name:ncity})
create (str :STREET {name:nstreet})-[:IN_DSTR]->(dstr);
	
match (n)
where exists(n.`loc-name`) and exists (n.district)
with distinct n.`loc-name` as nloc, n.district as ndistrict, n.city as ncity
match (dstr :DISTRICT {name:ndistrict})-[:IN_CITY]->(:CITY {name:ncity})
create (loc :LOCATION {name:nloc})-[:IN_DSTR]->(dstr);

// Noeuds -> rues ou locations 
match (n)
where exists(n.street) and not exists (n.district)
with n
match (str :STREET {name:n.street})-[:IN_CITY]->(city :CITY {name:n.city})-[:IN_DPT]->(:DPT {name:n.dpt})
create (n)-[:IN_STREET]->(str);

match (n)
where exists(n.`loc-name`) and not exists (n.district)
with n
match (loc :LOC {name:n.`loc-name`})-[:IN_CITY]->(city :CITY {name:n.city})-[:IN_DPT]->(:DPT {name:n.dpt})
create (n)-[:IN_LOC]->(loc);

match (n)
where exists(n.street) and exists (n.district)
with n
match (str :STREET {name:n.street})-[:IN_DSTR]->(dstr {name:n.district})-[:IN_CITY]->(city :CITY {name:n.city})-[:IN_DPT]->(:DPT {name:n.dpt})
create (n)-[:IN_STREET]->(str);

match (n)
where exists(n.`loc-name`) and exists (n.district)
with n
match (loc :LOC {name:n.`loc-name`})-[:IN_DSTR]->(dstr {name:n.district})-[:IN_CITY]->(city :CITY {name:n.city})-[:IN_DPT]->(:DPT {name:n.dpt})
create (n)-[:IN_LOC]->(loc);

//---------------------------------------------------
// Renommer les pistes cyclables 
//---------------------------------------------------

MATCH (n)-[r]->(m)
WHERE exists(r.cycleway) or r.highway='cycleway'
or r.bicycle='use_sidepath' or r.cyclestreet='yes'
or r.bicycle_road='yes' or r.bicycle='designated'
or r.cycleway='lane' or r.`cycleway-right`='lane' or r.`cycleway-left`='lane'
or r.`cycleway-both`='lane' or r.cycleway='opposite_lane' 
or r.`cycleway-right`='opposite_lane' or r.`cycleway-left`='opposite_lane'
or r.`cycleway-both`='opposite_lane'
CREATE (n)-[r2:PISTE_CYCLABLE]->(m)
SET r2 = r
WITH r
DELETE r;

// Longueur des pistes cyclables
MATCH (n)-[r:PISTE_CYCLABLE]->(m)
WITH r,
point({longitude: toFloat(n.lon), latitude: toFloat(n.lat)}) AS src,
point({longitude: toFloat(m.lon), latitude: toFloat(m.lat)}) AS dst
SET r.longueur = distance(src, dst);

// -------------------------------------------------------
// Compression - Dupliquer les noeuds avec + d'une relation entre eux
// -------------------------------------------------------

match (n)-[r :NEXT_NODE]->(m)
with n,m, collect(r) as rels
where size(rels) > 1
with n,m, rels
UNWIND rels as r
MERGE (a :DUPLICATED {osmId:n.osmId, rel_dup:r.osmId})
ON CREATE SET a=n
MERGE (b :DUPLICATED {osmId:m.osmId, rel_dup:r.osmId})
ON CREATE SET b=m
CREATE (a)-[rr :NEXT_DUPLICATED {osmId:r.osmId}]->(b)
SET rr=r
CREATE (n)-[ro:ORIGINAL]->(m)
SET ro = r
WITH r,a,b,n,m,ro
DELETE r;

// relations internes 
MATCH (n :DUPLICATED)
with n
match (m {osmId:n.osmId})-[r :NEXT_NODE {osmId:n.rel_dup}]->(s)
where n<>m
CREATE (n)-[rr :NEXT_NODE]->(s)
SET rr=r;

MATCH (n :DUPLICATED)
with n
match (m {osmId:n.osmId})<-[r :NEXT_NODE {osmId:n.rel_dup}]-(s)
where n<>m
CREATE (n)<-[rr :NEXT_NODE]-(s)
SET rr=r;

// relations externes
MATCH (n)-[o :ORIGINAL]-(n2)
with n, collect(o.osmId) as orel
match (n)-[r]->(s)
where not r.osmId in orel
MATCH (m :DUPLICATED {osmId:n.osmId})
CREATE (m)-[rr :NEXT_NODE]->(s)
SET rr=r;

MATCH (n)-[o :ORIGINAL]-(n2)
with n, collect(o.osmId) as orel
match (n)<-[r]-(s)
where not r.osmId in orel
MATCH (m :DUPLICATED {osmId:n.osmId})
CREATE (m)<-[rr :NEXT_NODE]-(s)
SET rr=r;

// suppresion des noeuds de base
match (n)-[r:ORIGINAL]-(m)
detach delete n,m;

// renommer next_duplicated et enlever rel_dup
MATCH (n)-[r :NEXT_DUPLICATED]->(m)
CREATE (n)-[r2 :NEXT_NODE]->(m)
SET r2 = r
WITH r
DELETE r;

// ----------------------------------------------------------
// Compression - Fusion des noeuds appartenant à la même zone 
// ----------------------------------------------------------
// Calcul de surface
match (n)-[r :NEXT_NODE]->(m)
with r.osmId as osmId, collect(n)[0] as n1, collect(r)[0] as tgs
match p=(n1)-[:NEXT_NODE *1.. {osmId:osmId}]->(n1)
with osmId, nodes(p) as nds, tgs
unwind nds as nd
with osmId, collect (nd.lat) as lat, collect(nd.lon) as lon, tgs, nds
UNWIND range(0, size(lat)-2) as i
with osmId, tgs, lat, lon, nds, abs(sum(radians(toFloat(lon[i+1]) - toFloat(lon[i]))
	* (2+ sin(radians(toFloat(lat[i]))) + sin(radians(toFloat(lat[i+1])))))
	* 6378137 * 6378137 / 2) as surface
CREATE (new :MERGED)
set new=tgs, new.lat=lat, new.lon=lon, new.surface=surface
return new;

// relations ->
match (n)-[r :NEXT_NODE]->(m)
with r.osmId as id, collect(n) as ns, collect(m) as ms, collect(r) as rs
unwind ns + ms as nms
with id, collect(distinct nms) as nds, rs[0] as tgs

with id,tgs, nds
match (n)-[r2]->(s)
where n in nds
and (not exists(r2.osmId) or tgs.osmId<>r2.osmId)
and not s in nds
match (new {osmId:tgs.osmId})
create (new)-[rr:NEXT_MERGED]->(s)
set rr=r2;

// relations <-
match (n)-[r :NEXT_NODE]->(m)
with r.osmId as id, collect(n) as ns, collect(m) as ms, collect(r) as rs
unwind ns + ms as nms
with id, collect(distinct nms) as nds, rs[0] as tgs

with id,tgs,nds
match (n)<-[r2]-(s)
where n in nds
and (not exists(r2.osmId) or tgs.osmId<>r2.osmId)
and not s in nds
match (new {osmId:tgs.osmId})
create (new)<-[rr:NEXT_MERGED]-(s)
set rr=r2;

// suppression
match (n)-[r :NEXT_NODE]->(m)
detach delete n,m;

// remettre les pistes cyclables
MATCH (n)-[r]->(m)
WHERE exists(r.cycleway) or r.highway='cycleway'
or r.bicycle='use_sidepath' or r.cyclestreet='yes'
or r.bicycle_road='yes' or r.bicycle='designated'
or r.cycleway='lane' or r.`cycleway-right`='lane' or r.`cycleway-left`='lane'
or r.`cycleway-both`='lane' or r.cycleway='opposite_lane' 
or r.`cycleway-right`='opposite_lane' or r.`cycleway-left`='opposite_lane'
or r.`cycleway-both`='opposite_lane'
CREATE (n)-[r2:PISTE_CYCLABLE]->(m)
SET r2 = r
WITH r
DELETE r;

// remettre les rues et locs
match (n)-[r :NEXT_MERGED]->(m :STREET)
with n, collect(distinct m) as str, collect(r) as rels
unwind str as m2
create (n)-[:IN_STREET]->(m2)
with rels
unwind rels as r2
delete r2;

match (n)-[r :NEXT_MERGED]->(m :LOCATION)
with n, collect(distinct m) as str, collect(r) as rels
unwind str as m2
create (n)-[:IN_LOC]->(m2)
with rels
unwind rels as r2
delete r2;

//---------------------------------------------------
// Ajout de labels sur les éléments
//---------------------------------------------------

MATCH (n {leisure:'park'})
SET n:PARC:BIODIVERSITE;
MATCH (n {leisure:'garden'})
SET n:JARDIN:BIODIVERSITE;
MATCH (n) WHERE n.landuse='forest' OR n.natural='wood'
SET n:FORET:BIODIVERSITE;
MATCH (n) WHERE n.boundary='national_park' OR n.leisure='nature_reserve' OR n.boundary="protected_area"
SET n:PARC_NATIONAL:BIODIVERSITE;
MATCH (n {man_made:'insect_hotel'})
SET n:HOTEL_INSECTE:BIODIVERSITE;
MATCH (n {man_made:'beehive'})
SET n:RUCHE:BIODIVERSITE;
MATCH (n {man_made:'nesting_site'})
SET n:NIDS:BIODIVERSITE;

MATCH (n {amenity:'marketplace'})
SET n:MARCHE:ECONOMIE;
MATCH (n {shop:'farm'})
SET n:PRODUITS_FERMIERS:ECONOMIE;
MATCH (n {organic:'only'})
SET n:BIO:ECONOMIE;
MATCH (n {shop:'supermarket'})
SET n:SUPERMARCHE:ECONOMIE;
MATCH (n) WHERE n.fair_trade='only' OR n.fair_trade='yes'
SET n:EQUITABLE:ECONOMIE;
MATCH (n) WHERE n.amenity='restaurant' OR n.amenity='fast_food'
SET n:RESTAURANT:ECONOMIE;
MATCH (n) WHERE n.shop='second_hand' OR n.second_hand='only' OR n.shop='charity'
SET n:OCCASION:ECONOMIE;
MATCH (n) WHERE EXISTS(n.repair)
SET n:REPARATION:ECONOMIE;

MATCH (n) WHERE n.amenity='waste_basket' OR n.amenity='waste_disposal' OR n.amenity='recycling'
SET n:DECHETS:ENERGIE;
MATCH (n {landuse:'basin'})
SET n:EAU_PLUIE:ENERGIE;
MATCH (n) where n.`generator-source`='solar' OR n.`plant-source`='solar'
SET n:SOLAIRE:ENERGIE;
MATCH (n) where n.`generator-source`='wind' OR n.`plant-source`='wind'
SET n:EOLIENNE:ENERGIE;
MATCH (n) where n.`generator-source`='biomass' OR n.`plant-source`='biomass'
SET n:BIOMASSE:ENERGIE;
MATCH (n) where n.`plant-source`='hydro'
SET n:HYDRAULIQUE:ENERGIE;
MATCH (n) where n.`generator-source`='geothermal'
SET n:GEOTHERMIE:ENERGIE;

MATCH (n {shop:'bicycle'})
SET n:MAGASIN:MOBILITE;
MATCH (n) where n.amenity='bicycle_rental' or n.`service-bicycle-rental` = 'yes'
SET n:LOCATION_VELO:MOBILITE;
MATCH (n) where n.amenity='bicycle_repair_station' or n.`service-bicycle-repair` = 'yes'
SET n:REPARATION_VELO:MOBILITE;
MATCH (n {amenity:'bicycle_parking'})
SET n:STATIONNEMENT_VELO:MOBILITE;
MATCH (n) where n.club='bicycle' or n.association='bicycle'
SET n:CLUB_VELO:MOBILITE;

MATCH (n) where n.highway='bus_stop' or n.public_transport='stop_position' or n.public_transport='platform'
or n.highway='platform' or n.railway='tram_stop' or n.railway='halt'
SET n:ARRET:MOBILITE;
MATCH (n {amenity:'charging_station'})
SET n:RECHARGE:MOBILITE;
MATCH (n {amenity:'car_pooling'})
SET n:POOLING:MOBILITE;
MATCH (n {amenity:'car_sharing'})
SET n:COVOITURAGE:MOBILITE;
