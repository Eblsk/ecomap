// requêtes analytiques
match (n :BIO)-[*3]->(:DISTRICT m)
return m.name, count(n)

match (n :BIODIVERSITE)-[]-(s :STREET)
return s.name, count(n) as nb
order by nb desc