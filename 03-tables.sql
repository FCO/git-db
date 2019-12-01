CREATE TABLE git_user(
	id   serial not null primary key,
	name varchar,
	email varchar
);

CREATE TABLE index(
	path varchar primary key,
	owner_id integer,
	content TEXT
);

CREATE TABLE blob(
	sha1 char(40) primary key,
	data index_data
);

CREATE TABLE tree(
	sha1 char(40) primary key
);

CREATE TABLE tree_blob(
	tree_sha1 char(40) references tree(sha1),
	blob_sha1 char(40) references blob(sha1),
	name varchar NOT NULL,
	primary key(tree_sha1, blob_sha1)
);

CREATE TABLE tree_tree(
	parent_sha1 char(40) references tree(sha1),
	child_sha1  char(40) references tree(sha1),
	name varchar NOT NULL,
	primary key(parent_sha1, child_sha1)
);

CREATE TABLE commit(
	sha1 char(40) primary key,
	parent1 char(40) references commit(sha1),
	parent2 char(40) references commit(sha1),
	user_id integer references git_user(id),
	created TIMESTAMP not null default CURRENT_TIMESTAMP
);

CREATE TABLE commit_tree(
	commit_sha1 char(40) references commit(sha1),
	tree_sha1 char(40) references tree(sha1),
	primary key(commit_sha1, tree_sha1)
);


CREATE TABLE refs(
	branch varchar primary key,
	commit_sha1 char(40) references commit(sha1)
);


CREATE TABLE head(
	user_id integer REFERENCES git_user(id) PRIMARY KEY,
	commit_sha1 CHAR(40)
);

