ALTER TABLE index ENABLE ROW LEVEL SECURITY;
ALTER TABLE head ENABLE ROW LEVEL SECURITY;

CREATE POLICY select_files ON index FOR SELECT USING (
    owner_id = current_setting('git.logged_user_id')::INTEGER
);

CREATE POLICY select_head ON head FOR SELECT USING (
    user_id = current_setting('git.logged_user_id')::INTEGER
);
