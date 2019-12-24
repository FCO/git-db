CREATE ROLE gituser;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE git_user TO gituser;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE index    TO gituser;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE head     TO gituser;

GRANT EXECUTE ON FUNCTION uid()                                         TO gituser;
GRANT EXECUTE ON FUNCTION create_blob(JSONB)                            TO gituser;
GRANT EXECUTE ON FUNCTION cat_blob(CHAR(40))                            TO gituser;
GRANT EXECUTE ON FUNCTION create_tree(key_value[], key_value[])         TO gituser;
GRANT EXECUTE ON FUNCTION create_commit(CHAR(40))                       TO gituser;
GRANT EXECUTE ON FUNCTION create_commit(CHAR(40), CHAR(40)[])           TO gituser;
GRANT EXECUTE ON FUNCTION add(index[])                                  TO gituser;
GRANT EXECUTE ON FUNCTION add()                                         TO gituser;
GRANT EXECUTE ON FUNCTION current_branch()                              TO gituser;
GRANT EXECUTE ON FUNCTION commit()                                      TO gituser;
GRANT EXECUTE ON FUNCTION show_commit(CHAR(40))                         TO gituser;
GRANT EXECUTE ON FUNCTION show_commit()                                 TO gituser;
GRANT EXECUTE ON FUNCTION head()                                        TO gituser;
GRANT EXECUTE ON FUNCTION login(VARCHAR)                                TO gituser;
GRANT EXECUTE ON FUNCTION diff(CHAR(40), CHAR(40))                      TO gituser;
GRANT EXECUTE ON FUNCTION diff(CHAR(40))                                TO gituser;
GRANT EXECUTE ON FUNCTION checkout(CHAR(40))                            TO gituser;
GRANT EXECUTE ON FUNCTION checkout()                                    TO gituser;
GRANT EXECUTE ON FUNCTION checkout_branch(VARCHAR)                      TO gituser;
GRANT EXECUTE ON FUNCTION create_branch(VARCHAR)                        TO gituser;
GRANT EXECUTE ON FUNCTION is_descendant(CHAR(40), CHAR(40))             TO gituser;
GRANT EXECUTE ON FUNCTION commit_history(character)                     TO gituser;
GRANT EXECUTE ON FUNCTION commit_base(CHAR(40), CHAR(40))               TO gituser;
GRANT EXECUTE ON FUNCTION merge(CHAR(40), CHAR(40))                     TO gituser;
GRANT EXECUTE ON FUNCTION cast_index_to_jsonb(index)                    TO gituser;

ALTER TABLE git_user ENABLE ROW LEVEL SECURITY;
ALTER TABLE index    ENABLE ROW LEVEL SECURITY;
ALTER TABLE head     ENABLE ROW LEVEL SECURITY;
ALTER TABLE refs     ENABLE ROW LEVEL SECURITY;

CREATE POLICY select_git_user ON "git_user" FOR ALL TO gituser USING (id       = uid());
CREATE POLICY select_files    ON "index"    FOR ALL TO gituser USING (owner_id = uid());
CREATE POLICY select_head     ON "head"     FOR ALL TO gituser USING (owner_id = uid());
CREATE POLICY select_refs     ON "refs"     FOR ALL TO gituser USING (owner_id = uid());

GRANT ALL ON TABLE blob          TO gituser;
GRANT ALL ON TABLE tree          TO gituser;
GRANT ALL ON TABLE tree_blob     TO gituser;
GRANT ALL ON TABLE tree_tree     TO gituser;
GRANT ALL ON TABLE commit        TO gituser;
GRANT ALL ON TABLE commit_parent TO gituser;
GRANT ALL ON TABLE refs          TO gituser;
