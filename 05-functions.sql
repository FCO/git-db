CREATE OR REPLACE FUNCTION create_blob(data JSONB) RETURNS CHAR(40) AS $$
	DECLARE
		_sha1 char(40);
	BEGIN
		_sha1 := encode(digest(CAST(data AS TEXT), 'sha1'), 'hex');
		INSERT INTO blob values(_sha1, data) ON CONFLICT DO NOTHING;
		RETURN _sha1;
	END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION cat_blob(_sha1 CHAR(40)) RETURNS JSONB AS $$
	DECLARE
		_data JSONB;
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


CREATE OR REPLACE FUNCTION create_commit(tree_sha1 CHAR(40)) RETURNS CHAR(40) AS $$
	BEGIN
        RETURN create_commit(tree_sha1, ARRAY[]::CHAR(40)[]);
	END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION create_commit(tree_sha1 CHAR(40), parents_sha1 CHAR(40)[]) RETURNS CHAR(40) AS $$
	DECLARE
		_sha1 char(40);
		sha1 CHAR(40);
	BEGIN
		SELECT
            ENCODE(
                DIGEST(
                    JSON_BUILD_OBJECT(
                        'parents', parents_sha1,
                        'owner',   uid(),
                        'tree',    CAST(tree_sha1 AS TEXT)
                    )::TEXT,
                    'sha1'
                ),
                'hex'
            )
        INTO
            _sha1
        ;
		INSERT INTO commit(sha1, owner_id, tree) VALUES(_sha1, uid(), tree_sha1) ON CONFLICT DO NOTHING;
		FOREACH sha1 IN ARRAY parents_sha1 LOOP
			INSERT INTO commit_parent VALUES(sha1, _sha1) ON CONFLICT DO NOTHING;
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

CREATE OR REPLACE FUNCTION current_branch() RETURNS CHAR(40) AS $$
	DECLARE
		_current_branch VARCHAR;
	BEGIN
		SELECT current_branch INTO _current_branch FROM git_user WHERE id = uid();
        RETURN _current_branch;
	END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION commit() RETURNS CHAR(40) AS $$
	DECLARE
		tree CHAR(40);
		_sha1 CHAR(40);
		head_sha1 CHAR(40);
		_current_branch VARCHAR;
	BEGIN
		tree := add();
		SELECT commit_sha1 into head_sha1 FROM head;
		IF head_sha1 IS NOT NULL THEN
		    _sha1 := create_commit(tree, ARRAY[head_sha1]);
		    UPDATE head SET commit_sha1 = _sha1 WHERE owner_id = uid();
		ELSE
		    _sha1 := create_commit(tree);
		    INSERT INTO head VALUES(uid(), _sha1);
		END IF;
		SELECT current_branch INTO _current_branch FROM git_user WHERE id = uid();
		IF _current_branch IS NOT NULL THEN
		    UPDATE refs SET commit_sha1 = _sha1 WHERE branch = _current_branch;
		END IF;
		RETURN _sha1;
	END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION show_commit(commit CHAR(40)) RETURNS TABLE (path VARCHAR, content JSONB) AS $$
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
			b.data
		FROM
			commit c
			JOIN files_by_root f ON c.tree = f.root
			JOIN "blob" b ON f.blob_sha1 = b.sha1
		WHERE
			c.sha1 = "commit"
		;
	END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION show_commit() RETURNS TABLE (path VARCHAR, content JSONB) AS $$
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
        SELECT commit_sha1 INTO _sha1 FROM head WHERE owner_id = uid();
        RETURN _sha1;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION create_user(_name VARCHAR, _email VARCHAR) RETURNS BOOL AS $$
    DECLARE
        uid VARCHAR;
        _sha1 CHAR(40);
    BEGIN
        INSERT INTO git_user(name, email) VALUES(_name, _email) RETURNING id INTO uid;
        SELECT commit_sha1 INTO _sha1 FROM refs WHERE branch = 'master' and owner_id = 0;
        INSERT INTO refs VALUES(uid::INTEGER, 'master', _sha1);
        RETURN TRUE;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION login(_email VARCHAR) RETURNS BOOL AS $$
    DECLARE
        uid VARCHAR;
        _sha1 CHAR(40);
    BEGIN
        SET ROLE gitdb;
        SELECT id::VARCHAR INTO uid FROM git_user WHERE git_user.email = _email;
        PERFORM set_config('git.logged_user_id', uid, FALSE);
        SET ROLE gituser;
        RETURN TRUE;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION diff(commit1 CHAR(40), commit2 CHAR(40)) RETURNS TABLE (op TEXT, path VARCHAR, content JSONB) AS $$
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

CREATE OR REPLACE FUNCTION diff(commit CHAR(40)) RETURNS TABLE (op TEXT, path VARCHAR, content JSONB) AS $$
    DECLARE
        commit1 CHAR(40);
    BEGIN
        commit1 := head();
        RETURN QUERY SELECT * FROM diff(commit1, commit);
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION checkout(_commit_sha1 CHAR(40)) RETURNS VOID AS $$
    BEGIN
        DELETE FROM index WHERE owner_id = uid();
        INSERT INTO index select uid() as uid, path, content -> 'content' FROM show_commit(_commit_sha1);
        UPDATE head SET commit_sha1 = _commit_sha1 WHERE owner_id = uid();
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION checkout() RETURNS VOID AS $$
    BEGIN
        SELECT checkout(head());
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION checkout_branch(_branch VARCHAR) RETURNS VOID AS $$
    DECLARE
        _sha1 CHAR(40);
    BEGIN
        SELECT commit_sha1 INTO _sha1 FROM refs WHERE branch = _branch;
        PERFORM checkout(_sha1);
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION create_branch(_branch VARCHAR) RETURNS VOID AS $$
    DECLARE
        _sha1 CHAR(40);
    BEGIN
        SELECT commit_sha1 INTO _sha1 FROM refs WHERE branch = _branch;
        IF _sha1 IS NOT NULL THEN
            RAISE 'Branch % already exists', _branch;
        END IF;
        _sha1 := head();
        INSERT INTO refs VALUES(uid(), _branch, _sha1);
        UPDATE git_user SET current_branch = _branch WHERE id = uid();
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION is_descendant(_commit1 CHAR(40), _commit2 CHAR(40)) RETURNS VOID AS $$
    DECLARE
    BEGIN
    END;
$$ LANGUAGE plpgsql;

-- TODO: Fix
CREATE OR REPLACE FUNCTION commit_history(_commit_sha1 character) RETURNS TABLE (commit_sha1 CHAR(40)) AS $$
	BEGIN
		RETURN QUERY
      		WITH RECURSIVE commit_hist(parent_sha1, child_sha1) AS (
			SELECT
				parent_sha1,
				child_sha1
			FROM
				commit_parent c
			WHERE
				child_sha1 = _commit_sha1
			UNION
			SELECT
				p.parent_sha1,
				p.child_sha1
			FROM
				commit_hist c
				LEFT JOIN commit_parent p ON c.parent_sha1 = p.child_sha1
		)
		SELECT _commit_sha1 AS sha1
		UNION ALL
		SELECT
			parent_sha1 as sha1
		FROM
			commit_hist
		WHERE
			child_sha1 IS NOT NULL
		;
	END;
$$ LANGUAGE plpgsql;

-- TODO: Fix
CREATE OR REPLACE FUNCTION commit_base(_from CHAR(40), _to CHAR(40)) RETURNS CHAR(40) AS $$
	DECLARE
		base CHAR(40);
	BEGIN
		SELECT
			a.commit_sha1 as commit
		INTO
			base
		FROM
			commit_history(_from) a,
			commit_history(_to) b
		WHERE
			a.commit_sha1 = b.commit_sha1
		LIMIT
			1
		;

		RETURN base;
	END;
$$ LANGUAGE plpgsql;

-- TODO: Fix
CREATE OR REPLACE FUNCTION merge(_from CHAR(40), _to CHAR(40)) RETURNS CHAR(40) AS $$
	DECLARE
		base CHAR(40);
		_current_branch CHAR(40);
	BEGIN
		_current_branch := current_branch();
		base := commit_base(_from, _to);
		IF base = _to THEN
			RETURN _from;
		ELSIF base = _from THEN
			UPDATE refs SET commit_sha1 = _to WHERE branch = _current_branch;
			RETURN _to;
		ELSE
            -- TODO: Implement the real merge
			raise 'Not Yet Implemented';
		END IF;
	END;
$$ LANGUAGE plpgsql;