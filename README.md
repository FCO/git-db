# git-db

- create_blob(data index_data) RETURNS char(40)
- cat_blob(_sha1 CHAR(40)) RETURNS index_data
- create_tree(blob_pair key_value[], tree_pair key_value[]) RETURNS CHAR(40)
- create_commit(tree_sha1 CHAR(40)[]) RETURNS CHAR(40)
- add(files index[]) RETURNS CHAR(40)
- add() RETURNS CHAR(40)
- current_branch()
- commit() RETURNS CHAR(40)
- create_commit(tree_sha1 CHAR(40)[], parent_sha1 CHAR(40)) RETURNS CHAR(40)
- create_commit(tree_sha1 CHAR(40)[], parent1_sha1 CHAR(40), parent2_sha1 CHAR(40)) RETURNS CHAR(40)
- show_commit(commit CHAR(40)) RETURNS TABLE (path VARCHAR, owner_id INTEGER, content TEXT)
- show_commit() RETURNS TABLE (path VARCHAR, owner_id INTEGER, content TEXT)
- login(_email VARCHAR) RETURNS BOOLEAN
- head() RETURNS CHAR(40)
- diff(commit1 CHAR(40), commit2 CHAR(40)) RETURNS TABLE (path VARCHAR, owner_id INTEGER, content TEXT)
- diff(commit CHAR(40)) RETURNS TABLE (path VARCHAR, owner_id INTEGER, content TEXT)
- checkout(commit_sha1 CHAR(40)) RETURNS VOID
- checkout() RETURNS VOID
- checkout_branch(_branch VARCHAR) RETURNS VOID
- create_branch(_branch VARCHAR) RETURNS VOID
- commit_history(_commit_sha1 character) RETURNS TABLE (commit_sha1 CHAR(40))
- commit_base(from CHAR(40), to CHAR(40)) RETURNS CHAR(40)
- merge(from CHAR(40), to CHAR(40)) RETURNS CHAR(40)





```sql
select login('fernandocorrea@gmail.com');
select * from index;
select commit();
select * from commit;
select * from blob;
select * from show_commit();
insert into index values('bli/ple', 1, 'test bli/ple');
select commit();
select * from commit;
select * from blob;
select * from show_commit();
select * from diff('d4c3e114e65ed9b1935462d86613f22059ee2757');
delete from index where path = 'ble';
select commit();
select * from diff('f131b51a02973f5dfe4fdd0c53e0c8c3045c4dbf');
select * from diff('d4c3e114e65ed9b1935462d86613f22059ee2757');
select * from index;
select checkout('d4c3e114e65ed9b1935462d86613f22059ee2757');
select * from index;
select checkout_branch('master');
select * from index;
select create_branch('bla');
delete from index;
insert into index values('aaa', 1, 'test aaa from branch bla');
select commit();
select * from show_commit();
select checkout_branch('master');
select * from index;
select checkout_branch('bla');
select * from index;
select commit_base('d4c3e114e65ed9b1935462d86613f22059ee2757', '4b7873e919dc7d26b5d2dc31a986e00731ddef17');
select merge('d4c3e114e65ed9b1935462d86613f22059ee2757', '4b7873e919dc7d26b5d2dc31a986e00731ddef17'); -- NYFI
```