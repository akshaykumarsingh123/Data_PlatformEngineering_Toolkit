--Use case for dropping a column

--Rollout Script
create database poc;
CREATE SCHEMA DBO;

CREATE TABLE POC_TEST(ID INT, NAME VARCHAR(20));


INSERT INTO POC_TEST VALUES(1, 'TOM');
INSERT INTO POC_TEST VALUES(2, 'CATHY');
INSERT INTO POC_TEST VALUES(3, 'MERLIN');
INSERT INTO POC_TEST VALUES(4, 'JEREMY');
INSERT INTO POC_TEST VALUES(5, 'ELENA');
INSERT INTO POC_TEST VALUES(6, 'STEVE');

create table poc_test_backup clone poc_test;-- taking backup before dropping the column. 


alter table poc_test drop column name; -- dropping the column

select * from poc_test;

--Rollback Script
alter table poc_test add column name varchar(20); -- adding column back to the original table


select * from poc_test;

MERGE INTO poc_test AS target
USING poc_test_backup AS source
ON target.id = source.id -- Use the appropriate primary key to match rows
WHEN MATCHED THEN
  UPDATE SET target.name = source.name
WHEN NOT MATCHED THEN
  INSERT (id, name)
  VALUES (source.id, source.name);
  
-- altering a column
    -- what happens to data if a column size is reduced below the length of the data
--In Snowflake, we cannot directly reduce the size of a column (for eg: VARCHAR column from VARCHAR(20) to VARCHAR(5)) due to the potential risk of data loss. --However, we can achieve this in a few steps by creating a new column, migrating the data (with truncation if needed), and then dropping the original column.


-- add column
    -- can we add a column in the middle of a table
--Snowflake, columns are always added at the end of the table definition, but the logical order of columns doesn't affect query results. We can specify any column --order when querying.

-- drop column
--This was demonstrated through the above code.









