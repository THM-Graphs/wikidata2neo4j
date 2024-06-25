// iterates all nodes having a wikidataId (=Q... Nummer) property and creates nodes/properties with matching data from wikidata
// uses a sparql query to access wikidata
WITH [
// alles was hier steht wird als Property eines Knotens angelegt
"http://www.wikidata.org/entity/P21", // sex or gender
"http://www.wikidata.org/entity/P227", // GND
"http://www.wikidata.org/entity/P31", // is instance of
"http://www.wikidata.org/entity/P509", // cause of death
"http://www.wikidata.org/entity/P21", // sex or gender
"http://www.wikidata.org/entity/P569", // date of birth
"http://www.wikidata.org/entity/P570" // date of death
]
as propertyEntities, [
// alles was hier steht wird als Knoten angelegt und verknüpft
"http://www.wikidata.org/entity/P361", // part of
"http://www.wikidata.org/entity/P39", // position held
"http://www.wikidata.org/entity/P106", // social classification
"http://www.wikidata.org/entity/P53", // family
"http://www.wikidata.org/entity/P3373", // sibling
"http://www.wikidata.org/entity/P1038", // relative
// "http://www.wikidata.org/entity/P21", // sex or gender
// "http://www.wikidata.org/entity/P31", // is instance of
"http://www.wikidata.org/entity/P463", // member of
"http://www.wikidata.org/entity/P26", // spouse of
"http://www.wikidata.org/entity/P40", // child of
"http://www.wikidata.org/entity/P22", // father of
"http://www.wikidata.org/entity/P25", // mother of
"http://www.wikidata.org/entity/P6" // head of governmant
]
as relationshipResults
MATCH (n) WHERE n.wikidataId IS NOT NULL// AND n.wikidataEnrichted IS NULL
WITH 'SELECT ?wd ?wdLabel ?ps ?ps_Label ?ps_ ?wdpq ?wdpqLabel ?pq ?pq_Label {VALUES (?company) {(wd:' + n.wikidataId + ')} ?company ?p ?statement . ?statement ?ps ?ps_ . ?wd wikibase:claim ?p. ?wd wikibase:statementProperty ?ps. OPTIONAL { ?statement ?pq ?pq_ . ?wdpq wikibase:qualifier ?pq . } SERVICE wikibase:label { bd:serviceParam wikibase:language "en" } } ORDER BY ?wd ?statement ?ps'
AS sparql, n, propertyEntities, relationshipResults
CALL apoc.load.jsonParams("https://query.wikidata.org/sparql?query=" + apoc.text.urlencode(sparql),
{ Accept: "application/sparql-results+json"},null)
YIELD value
WITH value.results.bindings AS all, n, propertyEntities, relationshipResults
//SET n.wikidataEnrichted=true
SET n:Wikidata
SET n += apoc.map.fromPairs([x in all WHERE x.wd.value in propertyEntities| [apoc.text.camelCase(x.wdLabel.value), x.ps_Label.value]])
WITH n, all, propertyEntities, relationshipResults
UNWIND all AS rel
WITH rel,n WHERE rel.wd.value in relationshipResults
AND rel.ps_Label.value IS NOT NULL
CALL apoc.merge.node(["Wikidata"], {wikidataId:split(rel.ps_.value, '/')[-1]}, {label:rel.ps_Label.value, pUrl:rel.ps.value, pLabel:rel.wdLabel.value}, {source:'wikidata'}) YIELD node as wikiNode
CALL apoc.merge.relationship(n, toUpper(rel.wdLabel.value), {}, apoc.map.setKey({}, rel.wdpqLabel.value,rel.pq_Label.value), wikiNode) yield rel as rel2
return n, wikiNode, rel2;
