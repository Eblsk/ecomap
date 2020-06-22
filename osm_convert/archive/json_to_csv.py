import json
import pandas as pd
import os

print("Creating directory")
dir_name='csv_files'
if not os.path.exists(dir_name):
    os.mkdir(dir_name)

'''
import ijson
for prefix, theType, value in ijson.parse(open(jsonFileName)):
    print prefix, theType, value
'''
print("Reading file")
with open('evry.json') as f:
    d = json.load(f)
# load en plusieurs fois puis concaténer
df = pd.json_normalize(d['elements'])

print("Creating nodes")
# dupliquer id pour avoir id du noeud OSM et :ID pour les relations neo4j
nodes_df = df[df['type'] == 'node'].dropna(how='all', axis='columns').drop(['type'], axis=1).replace("\n", ' ', regex=True).replace(",", ' ', regex=True).replace('"', ' ', regex=True).replace("'", ' ', regex=True).rename(columns = lambda x: x.replace(':', '-')).rename(columns={'id': ':ID'}).rename(columns = lambda x: x.replace('tags.', ''))

print("Creating ways")
ways_df = df[df['type'] == 'way'].dropna(how='all', axis='columns').drop(['type'], axis=1).replace(",", ' ', regex=True).replace('"', ' ', regex=True).replace("'", ' ', regex=True).rename(columns = lambda x: x.replace(':', '-')).rename(columns = lambda x: x.replace('tags.', ''))
#rels_df = df[df['type'] == 'relation'].dropna(how='all', axis='columns')

# https://stackoverflow.com/questions/45377085/pandas-create-link-pairs-from-multiple-rows
df=ways_df[['id','nodes']].explode('nodes')
ways_df = ways_df.drop(['nodes'], axis=1)


df['sequence'] = df.groupby('id').cumcount()
df2 = df

result = df.merge(df2, on='id', how='left')
result = result[result['sequence_x']+1==result['sequence_y']]

result = pd.DataFrame(result.groupby(['id','nodes_x','nodes_y']).size().rename('val'))
result = result.reset_index().drop(['val'], axis=1)

ways_df= ways_df.merge(result).rename(columns={"nodes_x" :":START_ID","nodes_y":":END_ID"})
ways_df[":TYPE"]="NEXT_NODE"

print("Exporting data")
nodes_df.to_csv(dir_name +'/nodes.csv',index=False)
ways_df.to_csv(dir_name+'/relations.csv',index=False)

# bin/neo4j-admin import --nodes=import/nodes.csv --relationships=import/relations.csv 
