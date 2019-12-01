-- index_data
CREATE TYPE index_data AS (
	owner_id INTEGER,
	content TEXT
);

CREATE TYPE key_value AS (
	name varchar,
	sha1 char(40)
);