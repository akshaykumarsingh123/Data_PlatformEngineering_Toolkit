-- Run on SQL managed instance
-- SQL_SERVER_IP_ADDRESS should be an IP address that could be accessed from the SQL Managed Instance host machine.
DECLARE @SQLServerIpAddress NVARCHAR(MAX) = '10.212.35.249'; -- insert your SQL Server IP address in here
DECLARE @tncCommand NVARCHAR(MAX) = 'tnc ' + @SQLServerIpAddress + ' -port 5022 -InformationLevel Quiet';
DECLARE @jobId BINARY(16);

IF EXISTS (
        SELECT *
        FROM msdb.dbo.sysjobs
        WHERE name = 'NetHelper'
        ) THROW 70000,
    'Agent job NetHelper already exists. Please rename the job, or drop the existing job before creating it again.',
    1
    -- To delete NetHelper job run: EXEC msdb.dbo.sp_delete_job @job_name=N'NetHelper'
    EXEC msdb.dbo.sp_add_job @job_name = N'NetHelper',
        @enabled = 1,
        @description = N'Test SQL Managed Instance to SQL Server network connectivity on port 5022.',
        @category_name = N'[Uncategorized (Local)]',
        @owner_login_name = N'sa',
        @job_id = @jobId OUTPUT;

EXEC msdb.dbo.sp_add_jobstep @job_id = @jobId,
    @step_name = N'TNC network probe from SQL MI to SQL Server',
    @step_id = 1,
    @os_run_priority = 0,
    @subsystem = N'PowerShell',
    @command = @tncCommand,
    @database_name = N'master',
    @flags = 40;

EXEC msdb.dbo.sp_update_job @job_id = @jobId,
    @start_step_id = 1;

EXEC msdb.dbo.sp_add_jobserver @job_id = @jobId,
    @server_name = N'(local)';