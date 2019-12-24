--insert into refs values('master');
SELECT CREATE_USER('fernando', 'fernandocorrea@gmail.com');
INSERT INTO INDEX VALUES(1, 'bla', 'test bla');
INSERT INTO INDEX VALUES(1, 'ble', 'test ble');
INSERT INTO INDEX VALUES(1, 'bli/blo', 'test bli/blo');
INSERT INTO INDEX VALUES(1, 'bli/blu/pla', 'test bli/blu/pla');

SELECT CREATE_USER('fernando2', 'fco@cpan.org');
INSERT INTO INDEX VALUES(2, 'bla', 'test bla');
INSERT INTO INDEX VALUES(2, 'ble', 'test ble');
INSERT INTO INDEX VALUES(2, 'cla/cle', 'test bli/blo');