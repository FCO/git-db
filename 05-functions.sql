CREATE OR REPLACE FUNCTION create_blob(data index_data) RETURNS char(40) as $$
	DECLARE
		_sha1 char(40);
	BEGIN
		_sha1 := encode(digest(CAST(data AS TEXT), 'sha1'), 'hex');
		INSERT INTO blob values(_sha1, data) ON CONFLICT DO NOTHING;
		RETURN _sha1;
	END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION cat_blob(_sha1 CHAR(40)) RETURNS index_data AS $$
	DECLARE
		_data index_data;
	BEGIN
		SELECT INTO _data data FROM blob WHERE sha1 = _sha1;
		RETURN _data;
	END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION create_tree(blob_pair key_value[], tree_pair key_value[]) RETURNS CHAR(40) AS $$
	DECLARE
		_sha1 char(40);
		pair key_value;
	BEGIN
		SELECT ENCODE(DIGEST(CONCAT_WS('|||', CAST(blob_pair AS TEXT), CAST(tree_pair AS TEXT)), 'sha1'), 'hex') INTO _sha1;
		INSERT INTO tree VALUES(_sha1) ON CONFLICT DO NOTHING;
		FOREACH pair IN ARRAY blob_pair LOOP
			INSERT INTO tree_blob VALUES(_sha1, pair.sha1, pair.name) ON CONFLICT DO NOTHING;
		END LOOP;
		FOREACH pair IN ARRAY tree_pair LOOP
			INSERT INTO tree_tree VALUES(_sha1, pair.sha1, pair.name) ON CONFLICT DO NOTHING;
		END LOOP;
		RETURN _sha1;
	END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION create_commit(tree_sha1 CHAR(40)[]) RETURNS CHAR(40) AS $$
	DECLARE
		_sha1 char(40);
		sha1 CHAR(40);
	BEGIN
		SELECT ENCODE(DIGEST(CONCAT_WS('|||', NULL, NULL, CAST(tree_sha1 AS TEXT)), 'sha1'), 'hex') INTO _sha1;
		INSERT INTO COMMIT VALUES(_sha1) ON CONFLICT DO NOTHING;
		FOREACH sha1 IN ARRAY tree_sha1 LOOP
			INSERT INTO commit_tree VALUES(_sha1, sha1) ON CONFLICT DO NOTHING;
		END LOOP;
		RETURN _sha1;
	END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION create_commit(tree_sha1 CHAR(40)[], parent_sha1 CHAR(40)) RETURNS CHAR(40) AS $$
	DECLARE
		_sha1 char(40);
		sha1 CHAR(40);
	BEGIN
		SELECT ENCODE(DIGEST(CONCAT_WS('|||', parent_sha1, NULL, CAST(tree_sha1 AS TEXT)), 'sha1'), 'hex') INTO _sha1;
		INSERT INTO commit VALUES(_sha1, parent_sha1) ON CONFLICT DO NOTHING;
		FOREACH sha1 IN ARRAY tree_sha1 LOOP
			INSERT INTO commit_tree VALUES(_sha1, sha1) ON CONFLICT DO NOTHING;
		END LOOP;
		RETURN _sha1;
	END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION create_commit(tree_sha1 CHAR(40)[], parent1_sha1 CHAR(40), parent2_sha1 CHAR(40)) RETURNS CHAR(40) AS $$
	DECLARE
		_sha1 char(40);
		sha1 CHAR(40);
	BEGIN
		SELECT ENCODE(DIGEST(CONCAT_WS('|||', parent1_sha1, parent2_sha1, CAST(tree_sha1 AS TEXT)), 'sha1'), 'hex') INTO _sha1;
		INSERT INTO commit VALUES(_sha1, parent_sha1) ON CONFLICT DO NOTHING;
		FOREACH sha1 IN ARRAY tree_sha1 LOOP
			INSERT INTO commit_tree VALUES(_sha1, sha1) ON CONFLICT DO NOTHING;
		END LOOP;
		RETURN _sha1;
	END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION add(files index[]) RETURNS CHAR(40) AS $$
	DECLARE
		tree_tree_pair key_value[] := ARRAY[]::key_value[];
		tree_blob_pair key_value[] := ARRAY[]::key_value[];
		file index_to_trees_row;
		f index;
		_sha1 CHAR(40);
	BEGIN
--		raise notice 'files: %', files;
		FOR file IN
			SELECT
				CASE
					WHEN array_length(regexp_split_to_array(path, '/'), 1) = 1 THEN ''
					ELSE (regexp_split_to_array(path, '/'))[1]
				END AS next_path,
				ARRAY_AGG(i) AS arr
			FROM
				UNNEST(files) as i
			GROUP BY
				array_length(regexp_split_to_array(path, '/'), 1),
				CASE
					WHEN array_length(regexp_split_to_array(path, '/'), 1) = 1 THEN ''
					ELSE (regexp_split_to_array(path, '/'))[1]
				END
		LOOP
--			raise notice 'file: %', file;
			IF file.next_path IS NULL OR file.next_path = '' THEN
				FOREACH f IN ARRAY file.arr LOOP
					DECLARE
						tmp key_value;
					BEGIN
--						raise notice 'f: %', f;
						tmp.sha1 := create_blob(f);
						tmp.name := f.path;
						tree_blob_pair := ARRAY_APPEND(tree_blob_pair, tmp);
					END;
					END LOOP;
			ELSE
				DECLARE
					tmp key_value;
					tmp_array index[];
				BEGIN
					FOREACH f IN ARRAY file.arr LOOP
						f.path := regexp_replace(f.path, '^.+?/', '');
						tmp_array := ARRAY_APPEND(tmp_array, f);
					END LOOP;
					tmp.sha1 := add(tmp_array);
					tmp.name := file.next_path;
					tree_tree_pair := ARRAY_APPEND(tree_tree_pair, tmp);
				END;
			END IF;
		END LOOP;
--		raise notice 'tree_blob_pair: %', tree_blob_pair;
--		raise notice 'tree_tree_pair: %;', tree_tree_pair;
		_sha1 := create_tree(tree_blob_pair, tree_tree_pair);
		RETURN _sha1;
	END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION add() RETURNS CHAR(40) AS $$
	DECLARE
		arr index[];
	BEGIN
		SELECT
			ARRAY_AGG(index)
		INTO
			arr
		FROM
			"index"
		;

--		raise notice 'arr: %', arr;
		RETURN add(arr);
	END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION commit() RETURNS CHAR(40) AS $$
	DECLARE
		tree CHAR(40);
		_sha1 CHAR(40);
		head_sha1 CHAR(40);
	BEGIN
		tree := add();
		SELECT commit_sha1 into head_sha1 FROM head;
		IF head_sha1 IS NOT NULL THEN
		    _sha1 := create_commit(ARRAY[tree], head_sha1);
		    UPDATE head SET commit_sha1 = _sha1 WHERE user_id = current_setting('git.logged_user_id')::integer;
		ELSE
		    _sha1 := create_commit(ARRAY[tree]);
		    INSERT INTO head VALUES(current_setting('git.logged_user_id')::integer, _sha1);
		END IF;
		RETURN _sha1;
	END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION show_commit(commit CHAR(40)) RETURNS TABLE (path VARCHAR, owner_id INTEGER, content TEXT) AS $$
	BEGIN
		RETURN QUERY
		WITH RECURSIVE blobs(levels, root, path, blob_sha1) AS (
			SELECT
				0,
				tree_sha1,
				name,
				blob_sha1
			FROM
				tree_blob
			UNION
			SELECT
				levels + 1,
				parent_sha1,
				name || '/' || b.path,
				blob_sha1
			FROM
				blobs b
				JOIN tree_tree t ON b.root = t.child_sha1
		),
		max_levels as (
			SELECT
				MAX(b.levels) AS levels, b.path
			FROM
				blobs b
			GROUP BY
				b.path
		),
		files_by_root as (
			SELECT
				b.root,
				b.path,
				b.blob_sha1
			FROM
				blobs b
				join max_levels m ON b.path = m.path AND b.levels = m.levels
		)
		SELECT
			f.path as path,
			(b.data).owner_id as owner_id,
			(b.data).content as content
		FROM
			commit_tree c
			JOIN files_by_root f ON c.tree_sha1 = f.root
			JOIN "blob" b ON f.blob_sha1 = b.sha1
		WHERE
			c.commit_sha1 = "commit"
		;
	END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION show_commit() RETURNS TABLE (path VARCHAR, owner_id INTEGER, content TEXT) AS $$
	DECLARE
		_sha1 CHAR(40);
	BEGIN
	    _sha1 := head();
		RETURN QUERY SELECT * from show_commit(_sha1);
	END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION head() RETURNS CHAR(40) AS $$
	DECLARE
		_sha1 CHAR(40);
    BEGIN
        SELECT commit_sha1 INTO _sha1 FROM head WHERE user_id = current_setting('git.logged_user_id')::integer;
        RETURN _sha1;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION login(_email VARCHAR) RETURNS BOOL AS $$
    DECLARE
        uid VARCHAR;
    BEGIN
        SELECT id::VARCHAR INTO uid FROM git_user WHERE git_user.email = _email;
        PERFORM set_config('git.logged_user_id', uid, FALSE);
        RETURN TRUE;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION diff(commit1 CHAR(40), commit2 CHAR(40)) RETURNS TABLE (op TEXT, path VARCHAR, owner_id INTEGER, content TEXT) AS $$
    BEGIN
        RETURN QUERY
            SELECT
                '+' op,
                added.*
            FROM
                (
                    SELECT * FROM show_commit(commit1)
                    EXCEPT
                    SELECT * FROM show_commit(commit2)
                ) AS added
            UNION
            SELECT
                '-' op,
                removed.*
            FROM
                (
                    SELECT * FROM show_commit(commit2)
                    EXCEPT
                    SELECT * FROM show_commit(commit1)
                ) AS removed
        ;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION diff(commit CHAR(40)) RETURNS TABLE (op TEXT, path VARCHAR, owner_id INTEGER, content TEXT) AS $$
    DECLARE
        commit1 CHAR(40);
    BEGIN
        commit1 := head();
        RETURN QUERY SELECT * FROM diff(commit1, commit);
    END;
$$ LANGUAGE plpgsql;