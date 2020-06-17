CREATE (TourEiffel:Monument {name:'Tour Eiffel', latitude:48.8584, longitude:2.2945})
CREATE (Louvre:Monument {name:'Musée du Louvre', latitude:48.8606, longitude:2.3376})
CREATE (ArcTriomphe:Monument {name:'Arc de Triomphe', latitude:48.8738, longitude:2.2950})
CREATE (SacreCoeur:Monument {name:'Basilique du Sacré-Cœur de Montmartre', latitude:48.8867, longitude:2.3431})
CREATE (NotreDame:Monument {name:'Notre-Dame de Paris', latitude:48.8530, longitude:2.3499})

CREATE (Emma:Personne {name:"Emma", born:1997})
CREATE (Lucie:Personne {name:"Lucie", born:1998})
CREATE (Sarah:Personne {name:"Sarah", born:1992})
CREATE (Thomas:Personne {name:"Thomas", born:1995})
CREATE (Lucas:Personne {name:"Lucas", born:2002})
CREATE (Camille:Personne {name:"Camille", born:2001})
CREATE (Kevin:Personne {name:"Kevin", born:1993})
CREATE (Antoine:Personne {name:"Antoine", born:1990})
CREATE (Marine:Personne {name:"Marine", born:2000})

CREATE
(Emma)-[:AMI]->(Lucie),
(Emma)-[:AMI]->(Sarah),
(Emma)-[:AMI]->(Lucas),
(Emma)-[:AMI]->(Camille),
(Lucie)-[:AMI]->(Marine),
(Lucie)-[:AMI]->(Thomas),
(Lucie)-[:AMI]->(Kevin),
(Sarah)-[:AMI]->(Antoine),
(Sarah)-[:AMI]->(Marine),
(Kevin)-[:AMI]->(Thomas),
(Kevin)-[:AMI]->(Antoine),
(Antoine)-[:AMI]->(Camille),
(Lucas)-[:AMI]->(Camille)

CREATE
(Emma)-[:VISITE]->(TourEiffel),
(Thomas)-[:VISITE]->(TourEiffel),
(Lucas)-[:VISITE]->(TourEiffel),
(Camille)-[:VISITE]->(TourEiffel),
(Kevin)-[:VISITE]->(ArcTriomphe),
(Antoine)-[:VISITE]->(ArcTriomphe),
(Sarah)-[:VISITE]->(ArcTriomphe),
(Marine)-[:VISITE]->(SacreCoeur),
(Antoine)-[:VISITE]->(SacreCoeur),
(Lucie)-[:VISITE]->(SacreCoeur),
(Camille)-[:VISITE]->(NotreDame),
(Marine)-[:VISITE]->(NotreDame),
(Lucie)-[:VISITE]->(Louvre),
(Sarah)-[:VISITE]->(Louvre),
(Lucas)-[:VISITE]->(Louvre)


// Amis des amis de Thomas
MATCH p=(:Personne {name:"Thomas"})-[:AMI*2]-(p2:Personne)
RETURN p2, nodes(p)

// Monuments visités par les amis de Thomas
MATCH (p:Personne {name:"Thomas"})-[:AMI]-(ami:Personne)-[:VISITE]->(m:Monument)
RETURN ami,m

// Monument le plus visité
MATCH (p:Personne)-[:VISITE]->(m:Monument)
RETURN m, count(p) as nb
ORDER BY nb DESC LIMIT 1