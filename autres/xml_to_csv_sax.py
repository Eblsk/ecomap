import csv, sys, os, warnings, xml.sax
from xml.etree import ElementTree

def clean(x):
    #neo4j-import doesn't support: multiline (coming soon), quotes next to each other and escape quotes with '\""'
    return x.replace('\n','').replace('\r','').replace('\\','').replace('"','')

def clean_key(x):
    return x.replace(':','-')

# Retrieving tags
class TagsHandler(xml.sax.ContentHandler):
    def startDocument(self):
        self.parentFlag = ""
        self.nodeTags = set()
        self.wayTags = set()
        self.relationTags = set()

    def startElement(self, name, attrs):
        if name == "node" or name=="way" or name=="relation":
            self.parentFlag = name
        elif name=='tag':
            if self.parentFlag == "node":
                self.nodeTags.add(clean_key(attrs.getValue('k')))
            elif self.parentFlag == "way":
                self.wayTags.add(clean_key(attrs.getValue('k')))
            elif self.parentFlag == "relation":
                self.relationTags.add(clean_key(attrs.getValue('k')))

    def endElement(self,name):
        if name == "node" or name=="way" or name=="relation":
            self.parentFlag = ""

    def tags(self):
        return self.nodeTags, self.wayTags, self.relationTags

# Writing in csv
class CsvHandler(xml.sax.ContentHandler):
    def startDocument(self):
        self.ndf = open(dir_name +'/nodes.csv', 'w')
        self.wayf = open(dir_name +'/ways.csv', 'w')
        self.relf = open(dir_name +'/relations.csv', 'w')
        self.ndw = csv.DictWriter(self.ndf, extrasaction='ignore', fieldnames=nodeTags)
        self.wayw = csv.DictWriter(self.wayf, extrasaction='ignore', fieldnames=wayTags) # |relTags)
        self.relw = csv.DictWriter(self.relf, extrasaction='ignore', fieldnames=wayTags|relTags)

        self.ndw.writeheader()
        self.wayw.writeheader()
        self.relw.writeheader()

        self.parentFlag = ""
        self.allNodes = set()      # used to check if nodes in relations exist
        

    def startElement(self, name, attrs):
        # Lecture des sous tags
        # Gérer les liens
        # Ajouter la longueur du chemin
        if self.parentFlag!="":
            if name=='tag':
                self.dct[clean_key(attrs.getValue('k'))]=clean(attrs.getValue('v'))

            elif self.parentFlag == "way":  # nd
                if self.ndPred!="":
                    nd=attrs.getValue('ref')
                    if(self.ndPred in self.allNodes and nd in self.allNodes):
                        print(self.ndPred + " " + nd)
                        self.dct[':START_ID']=self.ndPred
                        self.dct[':END_ID']=nd
                        self.wayw.writerow(self.dct)        # réinitialiser au bon endroit
                    else:
                        completeWays=False
                self.ndPred=attrs.getValue('ref')
        else:
            # Initialisation des dictionnaires
            # Ajouter la recherche de ville par périmètre
            if name == "node":
                self.parentFlag = name
                osmId=attrs.getValue('id')
                self.allNodes.add(osmId)

                self.dct = dict.fromkeys(nodeTags)
                self.dct[':ID'] = osmId
                self.dct['osmId'] = osmId
                self.dct['lat'] = attrs.getValue('lat')
                self.dct['lon'] = attrs.getValue('lon')

            elif name=="way":
                self.parentFlag = name
                self.dct = dict.fromkeys(wayTags)#|relTags)
                self.dct['osmId'] = attrs.getValue('id')
                self.dct[':TYPE'] = 'NEXT_NODE'
                self.ndPred=""
            
            # Voir cmt les relations sont représentées dans Spatial
            # elif self.parentFlag == "relation":        


    # Ecriture des dictionnaires
    def endElement(self,name):
        if name == "node":
            self.parentFlag = ""
            self.ndw.writerow(self.dct)

        # Gérer les liens
        elif name == "way":
            self.parentFlag = ""

        elif name == "relation":
            self.parentFlag = ""
            self.relw.writerow(self.dct)

    def endDocument(self):
        self.ndf.close()
        self.wayf.close()
        self.relf.close()

# MAIN  -----------------------------------------------------------------
print("Opening XML file")
if len (sys.argv) < 2:
    raise ValueError('No file given as argument')
file_name = sys.argv[1]

# Output directory
filename, file_extension = os.path.splitext(file_name)
dir_name=filename + '_csv'
if not os.path.exists(dir_name):
    os.mkdir(dir_name)

print("Retrieving all tags")

tagsHandler = TagsHandler()
xml.sax.parse(file_name, tagsHandler)
nodeTags, wayTags, relTags = tagsHandler.tags()

nodeTags = nodeTags | {':ID','osmId', 'lat', 'lon'}
wayTags = wayTags | {'osmId', ':TYPE', ':START_ID', ':END_ID'}
relTags = relTags | {'osmId', ':TYPE', ':START_ID', ':END_ID'}


allTags = nodeTags.union(wayTags).union(relTags)
print(sorted(allTags))

# CSV
print("Reading & writing in CSV file")
completeWays = True
xml.sax.parse(file_name, CsvHandler())

if not completeWays:
    warnings.warn("Some nodes contained in the ways were not provided and were ignored")

print()
print("Move the generated files to the neo4j import directory and execute the following command in neo4j terminal :")
print("bin/neo4j-admin import --nodes=import/nodes.csv --relationships=import/ways.csv ") 
