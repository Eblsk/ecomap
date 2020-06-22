import csv, sys, os, warnings
from xml.etree import ElementTree

def clean(x):
    #neo4j-import doesn't support: multiline (coming soon), quotes next to each other and escape quotes with '\""'
    return x.replace('\n','').replace('\r','').replace('\\','').replace('"','')

def clean_key(x):
    return x.replace(':','-')

print("Opening XML file")
if len (sys.argv) < 2:
    raise ValueError('No file given as argument')
file_name = sys.argv[1]
tree = ElementTree.parse(file_name)
root = tree.getroot()

# Output directory
filename, file_extension = os.path.splitext(file_name)
dir_name=filename + '_csv'
if not os.path.exists(dir_name):
    os.mkdir(dir_name)

print("Retrieving all tags")
node_tags= {':ID','osmId', 'lat', 'lon'}
for node in root.findall('node'):
    for tag in node.findall('tag'):
        node_tags.add(clean_key(tag.get('k')))

way_tags= {'osmId', ':TYPE', ':START_ID', ':END_ID'}
for way in root.findall('way'):
    for tag in way.findall('tag'):
        way_tags.add(clean_key(tag.get('k')))

print("Reading & writing nodes in CSV file")
all_nodes = set()
with open(dir_name +'/nodes.csv', 'w') as f:
    w = csv.DictWriter(f, extrasaction='ignore', fieldnames=node_tags)
    w.writeheader()
    for node in root.findall('node'):
        all_nodes.add(node.get('id'))
        dct = dict.fromkeys(node_tags)
        dct[':ID'] = node.get('id')
        dct['osmId'] = node.get('id')
        dct['lat'] = node.get('lat')
        dct['lon'] = node.get('lon')
        for tag in node.findall('tag'):
            dct[tag.get('k')]=clean(tag.get('v'))
        w.writerow(dct)

complete_ways = True
print("Reading & writing ways in CSV file")
with open(dir_name +'/ways.csv', 'w') as f:
    w = csv.DictWriter(f, extrasaction='ignore', fieldnames=way_tags)
    w.writeheader()
    for way in root.findall('way'):
        dct = dict.fromkeys(way_tags)
        dct['osmId'] = way.get('id')
        dct[':TYPE'] = 'NEXT_NODE'
        nds = way.findall('nd')
        for tag in way.findall('tag'):
            dct[tag.get('k')]=clean(tag.get('v'))
        for i in range(len(nds)-1) :
            nd1 = nds[i].get('ref')
            nd2 = nds[i+1].get('ref')
            if (nd1 in all_nodes and nd2 in all_nodes) :     #check if node is in nodes
                dct[':START_ID'] = nd1
                dct[':END_ID'] = nd2
                w.writerow(dct)
            else :
                complete_ways = False
                # reconstruire les chemins avec des noeuds hors zone ?

if not complete_ways:
    warnings.warn("Some nodes contained in the ways were not provided and were ignored")

print()
print("Move the generated files to the neo4j import directory and execute the following command in neo4j terminal :")
print("bin/neo4j-admin import --nodes=import/nodes.csv --relationships=import/ways.csv ") 
