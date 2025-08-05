-- Connect to the new job database specified when creating the elastic job agent

-- Create a database master key if one does not already exist, using your own password.  
CREATE MASTER KEY ENCRYPTION BY PASSWORD='<password>';  

-- Create two database-scoped credentials.  
-- The credential to connect to the Azure SQL logical server, to execute jobs
CREATE DATABASE SCOPED CREDENTIAL job_credential WITH IDENTITY = 'job_credential',
  SECRET = '<password>';
GO
-- The credential to connect to the Azure SQL logical server, to refresh the database metadata in server
CREATE DATABASE SCOPED CREDENTIAL refresh_credential WITH IDENTITY = 'refresh_credential',
  SECRET = '<password>';
GO

Step 1: Create a SQL Credential on the Job Database

-- Connect to the job agent database (jobdb)
-- Replace 'your_sql_user' and 'password' accordingly

CREATE DATABASE SCOPED CREDENTIAL SqlAuthCredential
WITH IDENTITY = 'your_sql_user',
SECRET = 'your_password';

Step 2: Register the Target Server and Database

-- Register the target logical server
EXEC jobs.sp_add_target_group_member
    @target_group_name = 'ElasticJobTargetGroup',
    @server_name = 'your-sqlserver-name.database.windows.net',
    @database_name = 'dblabtest',
    @refresh_credential_name = 'SqlAuthCredential';
	
--Step 3: Create the Job and Its Steps

-- Create the job (option1)
EXEC jobs.sp_add_job @job_name = 'RebuildIndexesJob';
---- Connect to the job database specified when creating the job agent

			-- Add job for create table (option2)
			EXEC jobs.sp_add_job @job_name = 'CreateTableTest', @description = 'Create Table Test';

			-- Add job step for create table
			EXEC jobs.sp_add_jobstep @job_name = 'CreateTableTest',
			@command = N'IF NOT EXISTS (SELECT * FROM sys.tables WHERE object_id = object_id(''Test''))
				CREATE TABLE [dbo].[Test]([TestId] [int] NOT NULL);',
			@target_group_name = 'PoolGroup';

-- Add a step to rebuild all indexes (simple maintenance example)
EXEC jobs.sp_add_jobstep
    @job_name = 'RebuildIndexesJob',
    @step_name = 'RebuildIndexes',
    @command = N'
         DECLARE @sql NVARCHAR(MAX)
        SELECT @sql = N'ALTER INDEX [' + i.name + '] ON [' + t.name + '] REBUILD;'
        FROM sys.indexes i
        JOIN sys.tables t ON i.object_id = t.object_id
        WHERE i.type_desc = 'NONCLUSTERED' AND i.is_disabled = 0;

        EXEC sp_executesql @sql;
    ',
    @credential_name = 'SqlAuthCredential',
    @target_group_name = 'ElasticJobTargetGroup';

Step 4: Start the Job
-- Start the job manually
EXEC jobs.sp_start_job @job_name = 'RebuildIndexesJob';

Step 5:Schedule the Job

-- Create a schedule to run the job every day at 2 AM
EXEC jobs.sp_add_schedule
    @schedule_name = 'Daily2AM',
    @start_time = '02:00:00',
    @enabled = 1;

-- Attach the schedule to the job
EXEC jobs.sp_add_job_schedule
    @job_name = 'RebuildIndexesJob',
    @schedule_name = 'Daily2AM';
	
Step 6: Monitor Job Execution

-- Get execution history
SELECT * FROM jobs.job_executions
ORDER BY start_time DESC;




