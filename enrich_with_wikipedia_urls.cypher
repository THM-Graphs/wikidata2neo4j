// enriches nodes with a wikidataId property with appropriate links to wikipedia pages
// uses the wikiddata API to getch sitelinks for languages de, en and commons
// resulting urls are constructed and stored into properties ‘wikipedia_url_de, wikipedia_url_en, wikipedia_url_commons
with  ['en', 'de', 'commons'] as languages
match (w) where w.wikipedia_url_de is null
and w.wikidataId is not null
call apoc.load.json("https://www.wikidata.org/w/api.php?action=wbgetentities&ids=" + w.wikidataId + "&props=sitelinks&format=json") yield value 
with  apoc.map.fromLists([lang in languages| apoc.text.format("wikipedia_url_%s",[lang])], [lang in languages | case value.entities[w.wikidataId].sitelinks[lang +"wiki"].title when is null then null else apoc.text.format( "https://%s.wikipedia.org/wiki/%s", [lang,  replace(value.entities[w.wikidataId].sitelinks[lang +"wiki"].title, " ","_")]) end ]) as map,w
set w += map;
