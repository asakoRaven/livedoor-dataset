
// This script uses the dataset at https://github.com/livedoor/datasets
// should update file path to dataset
export PREF_FILEPATH=file:///livedoor-dataset/datasets-master/prefs.csv
export STATION_FILEPATH=file:///livedoor-dataset/datasets-master/stations.csv
export AREA_FILEPATH=file://.datasets-master/areas.csv
export CATEGORY_FILEPATH=file:///livedoor-dataset/datasets-master/categories.csv
export RESTAURANT_FILEPATH=file:///livedoor-dataset/datasets-master/restaurants.csv
export RATING_FILEPATH=file:///livedoor-dataset/datasets-master/ratings.csv
export RATING_VOTE_FILEPATH=file:///livedoor-dataset/datasets-master/rating_votes.csv



// Prefecture

	// Uniqueness constraints.
CREATE CONSTRAINT ON (prefecture:Prefecture) ASSERT prefecture.id IS UNIQUE;

    // Load.
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS 
FROM
    {PREF_FILEPATH}
    AS line
WITH DISTINCT line
WHERE
    line.id IS NOT NULL
    AND
    line.name IS NOT NULL
CREATE (prefecture:Prefecture {
    id: TOINT(line.id),
    name: line.name
})
;


// Station

	// Uniqueness constraints.
CREATE CONSTRAINT ON (station:Station) ASSERT station.id IS UNIQUE;

	// Load.
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS 
FROM
    {STATION_FILEPATH}
    AS line
WITH DISTINCT line
WHERE line.id IS NOT NULL
      AND
      line.name IS NOT NULL
      AND
      line.pref_id IS NOT NULL
MATCH (p: Prefecture { id: TOINT(line.pref_id) })
CREATE (s:Station {
    id: TOINT(line.id),
	name: line.name,
	name_kana: line.name_kana,
	railroad: line.property
})
MERGE (s) - [:PREFECTURE] -> (p)
;


// Area

    // Uniqueness constraints.
CREATE CONSTRAINT ON (area:Area) ASSERT area.id IS UNIQUE;

	// Load.
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS 
FROM
    {AREA_FILEPATH}
    AS line
WITH DISTINCT line
WHERE line.id IS NOT NULL
    AND
    line.name IS NOT NULL
    AND
    line.pref_id IS NOT NULL
MATCH (p: Prefecture { id: TOINT(line.pref_id) })
CREATE (a:Area {
    id:   TOINT(line.id),
	name: line.name
})
CREATE (a) - [:PREFECTURE] -> (p)
;


// Category

    // Uniqueness constraints.
CREATE CONSTRAINT ON (c:Category) ASSERT c.id IS UNIQUE;

    // Load.
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM
    {CATEGORY_FILEPATH}
    AS line
WITH DISTINCT line
WHERE
    line.id IS NOT NULL
    AND
    line.name IS NOT NULL
CREATE (c:Category)
SET
    c.id        = TOINT(line.id),
    c.name      = line.name,
    c.name_kana = line.name_kana,
    c.similar   = line.similar
;

    // relationship
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM
    {CATEGORY_FILEPATH}
    AS line
WITH DISTINCT line
MATCH (c:Category { id: TOINT(line.id) })
OPTIONAL MATCH (p1:Category { id: TOINT(line.parent1) })
OPTIONAL MATCH (p2:Category { id: TOINT(line.parent2) })
WHERE
    line.id IS NOT NULL
    AND
    line.name IS NOT NULL
// when p1 is null, create relationship will fail
FOREACH (pp1 IN CASE WHEN p1 IS NOT NULL THEN [p1] ELSE [] END |
    CREATE (c) - [:CATEGORY_OF] -> (p1)
)
// when p2 is null, create relationship will fail
FOREACH (pp2 IN CASE WHEN p2 IS NOT NULL THEN [p2] ELSE [] END |
    CREATE (c) - [:CATEGORY_OF] -> (p2)
)
;


// Restaurant

    // Uniqueness constraints.
CREATE CONSTRAINT ON (restaurant:Restaurant) ASSERT restaurant.id IS UNIQUE;

    // Load.
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM
    {RESTAURANT_FILEPATH}
    AS line
WITH DISTINCT line
WHERE
    line.id IS NOT NULL
    AND
    line.name IS NOT NULL
CREATE (r:Restaurant)
SET
    r.id           = TOINT(line.id),
    r.purpose      =  SPLIT(line.purpose, ","),
    r.open_morning = (line.open_morning <> "0"),
    r.open_lunch   = (line.open_lunch <> "0"),
    r.open_late    = (line.open_late <> "0"),
    r.photo_count  = TOINT(line.photo_count),
    r.menu_count   = TOINT(line.menu_count),
    r.fan_count    = TOINT(line.fan_count),
    r.access_count = TOINT(line.access_count),
    r.closed       = (line.closed <> "0"),
    r.name         = line.name,
    r.alphabet     = line.alphabet,
    r.name_kana    = line.name_kana,
    r.branch       = line.property,
    r.zip          = line.zip,
    r.address      = line.address,
    r.north_latitude = line.north_latitude,
    r.east_longitude = line.east_longitude,
    r.description  = line.description
;

    // relationship
    // some column doesn't set. referece node is not included in the data set.
	// so, create relationship after creating node. 
	// additionally, igonre relationship if node cannot be found.
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM
    {RESTAURANT_FILEPATH}
    AS line
WITH DISTINCT line
MATCH (r:Restaurant { id: TOINT(line.id) })
OPTIONAL MATCH (p:Prefecture { id: TOINT(line.pref_id) })
OPTIONAL MATCH (a:Area { id: TOINT(line.area_id) })
OPTIONAL MATCH (s1:Station { id: TOINT(line.station_id1) })
OPTIONAL MATCH (s2:Station { id: TOINT(line.station_id2) })
OPTIONAL MATCH (s3:Station { id: TOINT(line.station_id3) })
OPTIONAL MATCH (c1:Category { id: TOINT(line.category_id1) })
OPTIONAL MATCH (c2:Category { id: TOINT(line.category_id2) })
OPTIONAL MATCH (c3:Category { id: TOINT(line.category_id3) })
OPTIONAL MATCH (c4:Category { id: TOINT(line.category_id4) })
OPTIONAL MATCH (c5:Category { id: TOINT(line.category_id5) })
WHERE
    line.id IS NOT NULL
    AND
    line.name IS NOT NULL
// when p is null, create relationship will fail
FOREACH (pp IN CASE WHEN p IS NOT NULL THEN [p] ELSE [] END |
    CREATE (p) - [:PREFECTURE {area_id: TOINT(line.area_id)}] -> (r)
)
FOREACH (aa IN CASE WHEN a IS NOT NULL THEN [a] ELSE [] END |
    CREATE (a) - [:AREA {prefecrure_id: TOINT(line.pref_id)}] -> (r)
)
FOREACH (ss1 IN CASE WHEN s1 IS NOT NULL THEN [s1] ELSE [] END |
    CREATE (s1) - [:STATION {distance: line.station_distance1, time:line.station_time1}] -> (r)
)
FOREACH (ss2 IN CASE WHEN s2 IS NOT NULL THEN [s2] ELSE [] END |
    CREATE (s2) - [:STATION {distance: line.station_distance2, time:line.station_time2}] -> (r)
)
FOREACH (ss3 IN CASE WHEN s3 IS NOT NULL THEN [s3] ELSE [] END |
    CREATE (s3) - [:STATION {distance: line.station_distance3, time:line.station_time3}] -> (r)
)
FOREACH (cc1 IN CASE WHEN c1 IS NOT NULL THEN [c1] ELSE [] END |
    CREATE (c1) - [:CATEGORY] -> (r)
)
FOREACH (cc2 IN CASE WHEN c2 IS NOT NULL THEN [c2] ELSE [] END |
    CREATE (c2) - [:CATEGORY] -> (r)
)
FOREACH (cc3 IN CASE WHEN c3 IS NOT NULL THEN [c3] ELSE [] END |
    CREATE (c3) - [:CATEGORY] -> (r)
)
FOREACH (cc4 IN CASE WHEN c4 IS NOT NULL THEN [c4] ELSE [] END |
    CREATE (c4) - [:CATEGORY] -> (r)
)
FOREACH (cc5 IN CASE WHEN c5 IS NOT NULL THEN [c5] ELSE [] END |
    CREATE (c5) - [:CATEGORY] -> (r)
)
;



// User & Rating

    // Uniqueness constraints.
CREATE CONSTRAINT ON (u:User)   ASSERT u.id IS UNIQUE;
CREATE CONSTRAINT ON (c:Comment) ASSERT c.id IS UNIQUE;

    // Load.
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM
    {RATING_FILEPATH}
    AS line
WITH DISTINCT line
OPTIONAL MATCH (restaurant:Restaurant { id: TOINT(line.restaurant_id) })
WHERE
    line.id IS NOT NULL
MERGE (user:User {id: line.user_id})
// the reason of issuing MERGE is that rating_id is in duplicate!!
// when create (comment:Comment), load csv stopped loading.
MERGE (comment:Comment { id: TOINT(line.id) })
// merge command says that "Node 278467 already exists with label Rating and property "id"=[191696]"
// so, use SET after MERGE. it means overwrite?
SET
    comment.comment    = line.body,
    comment.purpose    = TOINT(line.purpose),
    comment.created_on = line.created_on
// when line.title is null, merge comment will fail
FOREACH (tt IN CASE WHEN line.title IS NOT NULL THEN [line.title] ELSE [] END |
    SET comment.title = line.title
)
// when restaurant is null, create relationship will fail
// WARNING: Expected to find a node at restaurant but found nothing Some(null)
// (Failure when processing
// URL 'file:/Users/asako/creationline/study/neo4j/livedoor-dataset/datasets-master/ratings.csv'
// on line 205833 (which is the last row in the file).
// Possibly the last row committed during import is line 204999.
// Note that this information might not be accurate.)
// livedoor data set is not clear.
// some row has duplicate id.
// some column set 0 or null. (maybe both means null)
// did some row or column in ratings.csv slipped?
FOREACH (rr IN CASE WHEN restaurant IS NOT NULL THEN [restaurant] ELSE [] END |
    MERGE (comment) -
        [:RATE {
            total      : TOINT(line.total),
            food       : TOINT(line.food),
            service    : TOINT(line.service),
            atmosphere : TOINT(line.atmosphere)
        }] -> (restaurant)
)
MERGE (user) <- [:COMMENTED_BY] - (comment)
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM
    {RATING_VOTE_FILEPATH}
    AS line
WITH DISTINCT line
OPTIONAL MATCH (comment:Comment { id: TOINT(line.rating_id) })
WHERE
    line.rating_id IS NOT NULL
MERGE (user:User { id: line.user })
FOREACH (rr IN CASE WHEN comment IS NOT NULL THEN [comment] ELSE [] END |
    MERGE (user) <- [:VOTED_BY { voted_on: line.created_on }] - (comment)
)
;
