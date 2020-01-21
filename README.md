# git-db

- create_user(_name VARCHAR, email VARCHAR) RETURNS BOOL
- login(_email VARCHAR) RETURNS BOOLEAN
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
- head() RETURNS CHAR(40)
- diff(commit1 CHAR(40), commit2 CHAR(40)) RETURNS TABLE (path VARCHAR, owner_id INTEGER, content TEXT)
- diff(commit CHAR(40)) RETURNS TABLE (path VARCHAR, owner_id INTEGER, content TEXT)
- checkout(commit_sha1 CHAR(40)) RETURNS VOID
- checkout() RETURNS VOID
- checkout_branch(_branch VARCHAR) RETURNS VOID
- create_branch(_branch VARCHAR) RETURNS VOID
- commit_history(_commit_sha1 character) RETURNS TABLE (commit_sha1 CHAR(40))
- ~commit_base(from CHAR(40), to CHAR(40)) RETURNS CHAR(40)~
- ~merge(from CHAR(40), to CHAR(40)) RETURNS CHAR(40)~





```sql
select login('fernandocorrea@gmail.com');							-- TRUE
SELECT uid();
select * from git_user;
select * from index;
select commit();													-- 8e40203ff76fa96b0b3cdb7b8a3c8e7018a1e613
select * from commit;
select * from blob;
select * from show_commit();
insert into index values(1, 'bli/ple', 'test bli/ple');
select commit();													-- 5579fa8a480365ed9d18b0d5f97278c9ca4a3424
select * from commit;
select * from blob;
select * from show_commit();
select * from diff('8e40203ff76fa96b0b3cdb7b8a3c8e7018a1e613');
delete from index where path = 'ble';
select commit();													-- 923914790343178a02b696a7fb0da36a9502378a
select * from diff('8e40203ff76fa96b0b3cdb7b8a3c8e7018a1e613');
select * from diff('5579fa8a480365ed9d18b0d5f97278c9ca4a3424');
select * from index;
select checkout('5579fa8a480365ed9d18b0d5f97278c9ca4a3424');
select * from index;
select checkout_branch('master');
select * from index;
select create_branch('bla');
delete from index;
insert into index values(1, 'aaa', 'test aaa from branch bla');
select commit();													-- 80c84b61405dad43947b711f531f97cc828f8f47
select * from show_commit();
select checkout_branch('master');
select * from index;
select checkout_branch('bla');
select * from index;
-- select commit_base('80c84b61405dad43947b711f531f97cc828f8f47', '5579fa8a480365ed9d18b0d5f97278c9ca4a3424');
```
