--Use case for TRUNCATE statement

--Rollout script
CREATE DATABASE POC_TEST;
CREATE SCHEMA DBO;

CREATE TABLE Employee(ID INT, NAME VARCHAR(20));


INSERT INTO Employee VALUES(1, 'TOM');
INSERT INTO Employee VALUES(2, 'CATHY');
INSERT INTO Employee VALUES(3, 'MERLIN');
INSERT INTO Employee VALUES(4, 'JEREMY');
INSERT INTO Employee VALUES(5, 'ELENA');
INSERT INTO Employee VALUES(6, 'STEVE');

SELECT * FROM Employee;

CREATE or REPLACE TABLE EMPLOYEE_BACKUP CLONE EMPLOYEE; -- Creating a clone of original table before truncating it.
TRUNCATE TABLE EMPLOYEE;  -- Truncating the table

SELECT * FROM Employee;
SELECT * FROM EMPLOYEE_BACKUP;

--Fixing the Original table
--Rollabck 1.
INSERT INTO EMPLOYEE
SELECT * FROM EMPLOYEE_BACKUP;

SELECT * FROM Employee;
SELECT * FROM EMPLOYEE_BACKUP;

--Rollback 2. Should be using time travel

INSERT INTO EMPLOYEE
SELECT * FROM Employee
BEFORE(STATEMENT=>'QUERY_ID FOR THE TRUNCATE STATEMENT')

/*Query Id can be retrived through the following query*/

SELECT query_id, query_text, query_type, user_name, start_time, end_time
FROM table(information_schema.query_history())
--WHERE start_time >= DATEADD(day, -1, CURRENT_TIMESTAMP)  -- Change time window as needed
where query_type = 'TRUNCATE_TABLE'                                
AND user_name = 'AKSINGH'                         
ORDER BY start_time DESC;

select * from table(information_schema.query_history())
order by start_time;

--==================================================================================================================================

--Use case for DML operations (Updates, deletes)

--Rollout Script

--This is just to set the right timezone to avoid confusion
ALTER SESSION SET TIMEZONE = 'America/Toronto';

-- To view all parameters of timezone
show  parameters like '%TIMEZONE%';

SELECT CURRENT_TIMESTAMP;
--2024-10-10 13:36:32.183 -0400

-- We can track the query id of the UPDATE statement
UPDATE EMPLOYEE 
SET NAME='ROGERS'

select * from employee;

--Rollback Script:

--BEFORE THIS TIME before the update occur
SELECT * FROM Employee
BEFORE(TIMESTAMP=>'2024-10-10 13:36:32.183 -0400':: TIMESTAMP_LTZ); 

--(1 min after initial timestamp) AT STATEMENT IS INCLUSIVE OF THE STATE OF DATA.
SELECT * FROM Employee
AT (TIMESTAMP=>'2024-10-10 13:37:32.183 -0400':: TIMESTAMP_LTZ); 

--Find the query id through SQL code
SELECT * FROM Employee
BEFORE( STATEMENT =>'01b799e0-0001-3bac-0002-5d8e0004817e');

SELECT * FROM Employee
AT( STATEMENT =>'01b799e0-0001-3bac-0002-5d8e0004817e');

--*************Query Id can be retrieved using the below SQL queries******************
select query_text, database_name, query_type, user_name, role_name, warehouse_name,
warehouse_size,start_time, end_time, total_elapsed_time, compilation_time, execution_time,
queued_provisioning_time,transaction_blocked_time, queued_overload_time, execution_status
  from table(information_schema.QUERY_HISTORY_BY_USER(
    USER_NAME => 'aksingh',
    END_TIME_RANGE_START=>to_timestamp_ltz('2024-10-10 10:09:06.398 -0700'),
    END_TIME_RANGE_END=>to_timestamp_ltz('2024-10-10 12:09:06.398 -0700')));

select * from table(information_schema.query_history())
order by start_time;


--Repair table using time travel

DELETE FROM EMPLOYEE WHERE NAME='ROGERS';

INSERT INTO Employee
SELECT * FROM Employee
AT( STATEMENT =>'QUERY_ID');

--==================================================================================================================================


--Use Case for DROP TABLE statement

--Rollout 
CREATE TABLE Employee (ID INT, NAME VARCHAR(20));

INSERT INTO Employee VALUES(1, 'TOM');
INSERT INTO Employee VALUES(2, 'CATHY');
INSERT INTO Employee VALUES(3, 'MERLIN');
INSERT INTO Employee VALUES(4, 'JEREMY');
INSERT INTO Employee VALUES(5, 'ELENA');
INSERT INTO Employee VALUES(6, 'STEVE');

DROP TABLE EMPLOYEE;

--Rollback
UNDROP TABLE EMPLOYEE;





