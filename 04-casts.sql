CREATE TYPE index_to_trees_row AS (
	next_path varchar,
	arr index[]
);

CREATE OR REPLACE FUNCTION cast_index_to_text(data index_data) returns TEXT AS $$
	DECLARE
		_text TEXT;
	BEGIN
		SELECT CONCAT_WS('|', data.owner_id, data.content) INTO _text;
		RETURN _text;
	END;
$$ LANGUAGE plpgsql;

CREATE CAST (index_data AS text) WITH FUNCTION cast_index_to_text(index_data) AS IMPLICIT;


CREATE OR REPLACE FUNCTION cast_index_to_index_data(data index) returns index_data AS $$
	BEGIN
		RETURN (data.owner_id, data.content);
	END;
$$ LANGUAGE plpgsql;

CREATE CAST (index AS index_data) WITH FUNCTION cast_index_to_index_data(index) AS IMPLICIT;
