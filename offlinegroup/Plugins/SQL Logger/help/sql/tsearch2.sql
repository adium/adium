-- Jeffrey Melloy <jmelloy@visualdistortion.org>

-- $URL: http://svn.visualdistortion.org/repos/projects/sqllogger/sql/tsearch2.sql $
-- $Rev: 809 $ $Date$

-- This script adds full-text index searching (fast).
-- It needs to be run after the "tsearch2" module is installed.
-- If the tsearch2 module is not installed correctly, it will fail with
-- "type tsvector does not exist"

-- Although it can be run either before or after data is in table,
-- running it before a large data entry (parser.pl) will cause data to
-- be entered much more slowly.

-- For large tables, this script may take a few minutes, especially the 
-- "create index" stage.

alter table im.messages add idxfti tsvector;
update im.messages set idxfti=to_tsvector('default', message);
create index fti_idx on im.messages using gist(idxfti);
create trigger tsvectorupdate before update or insert on im.messages
for each row execute procedure tsearch2(idxfti, message);
