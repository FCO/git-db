# git-db

- create_blob(data index_data) RETURNS char(40)
- cat_blob(_sha1 CHAR(40)) RETURNS index_data
- create_tree(blob_pair key_value[], tree_pair key_value[]) RETURNS CHAR(40)
- create_commit(tree_sha1 CHAR(40)[]) RETURNS CHAR(40)
- add(files index[]) RETURNS CHAR(40)
- add() RETURNS CHAR(40)
- commit() RETURNS CHAR(40)
- create_commit(tree_sha1 CHAR(40)[], parent_sha1 CHAR(40)) RETURNS CHAR(40)
- create_commit(tree_sha1 CHAR(40)[], parent1_sha1 CHAR(40), parent2_sha1 CHAR(40)) RETURNS CHAR(40)
- show_commit(commit CHAR(40)) RETURNS TABLE (path VARCHAR, owner_id INTEGER, content TEXT)
- show_commit() RETURNS TABLE (path VARCHAR, owner_id INTEGER, content TEXT)
- login(_email VARCHAR) RETURNS BOOLEAN
- head() RETURNS CHAR(40)
- diff(commit1 CHAR(40), commit2 CHAR(40)) RETURNS TABLE (path VARCHAR, owner_id INTEGER, content TEXT)
- diff(commit CHAR(40)) RETURNS TABLE (path VARCHAR, owner_id INTEGER, content TEXT)





```sql
select login('fernandocorrea@gmail.com');
select * from index;
select commit();
select * from commit;
select * from blob;
insert into index values('bli/ple', 1, 'test bli/ple');
select commit();
select * from commit;
select * from blob;
select * from diff('d4c3e114e65ed9b1935462d86613f22059ee2757');
```