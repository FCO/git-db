CREATE TABLE refs(
    owner_id INTEGER,
	branch   VARCHAR,
    PRIMARY KEY(owner_id, branch)
);

CREATE TABLE git_user(
	id             SERIAL NOT NULL PRIMARY KEY,
	name           VARCHAR,
	email          VARCHAR,
	current_branch VARCHAR DEFAULT 'master'
);

INSERT INTO refs VALUES(0, 'master');
INSERT INTO git_user VALUES(0, 'root');

CREATE TABLE index(
	owner_id INTEGER,
	path     VARCHAR,
	content  TEXT,
	PRIMARY KEY(path, owner_id)
);

CREATE TABLE blob(
	sha1 CHAR(40) PRIMARY KEY,
	data JSONB
);

CREATE TABLE tree(
	sha1 CHAR(40) PRIMARY KEY
);

CREATE TABLE tree_blob(
	tree_sha1 CHAR(40) REFERENCES tree(sha1),
	blob_sha1 CHAR(40) REFERENCES blob(sha1),
	name      VARCHAR NOT NULL,
	PRIMARY KEY(tree_sha1, blob_sha1)
);

CREATE TABLE tree_tree(
	parent_sha1 CHAR(40) REFERENCES tree(sha1),
	child_sha1  CHAR(40) REFERENCES tree(sha1),
	name        VARCHAR NOT NULL,
	PRIMARY KEY(parent_sha1, child_sha1)
);

CREATE TABLE commit(
	sha1     CHAR(40) PRIMARY KEY,
	parent1  CHAR(40) REFERENCES COMMIT(sha1),
	parent2  CHAR(40) REFERENCES COMMIT(sha1),
	owner_id INTEGER  REFERENCES git_user(id),
	created  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE refs ADD COLUMN commit_sha1 CHAR(40) REFERENCES commit(sha1);
ALTER TABLE refs ADD CONSTRAINT refs_owner_id FOREIGN KEY(owner_id) REFERENCES git_user(id);

CREATE TABLE commit_tree(
	commit_sha1 CHAR(40) REFERENCES commit(sha1),
	tree_sha1   CHAR(40) REFERENCES tree(sha1),
	PRIMARY KEY(commit_sha1, tree_sha1)
);

CREATE TABLE head(
	owner_id    INTEGER REFERENCES git_user(id) PRIMARY KEY,
	commit_sha1 CHAR(40)
);

