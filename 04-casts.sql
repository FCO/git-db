CREATE TYPE index_to_trees_row AS (
	next_path varchar,
	arr index[]
);

CREATE OR REPLACE FUNCTION cast_index_to_jsonb(data index) RETURNS JSONB AS $$
	SELECT jsonb_build_object('content', data.content);
$$ LANGUAGE sql;

CREATE CAST (index AS JSONB) WITH FUNCTION cast_index_to_jsonb(index) AS IMPLICIT;
