USE [msdb]
GO

/****** Object:  Job [DB Maintenance - Update Statistics (Partial Scan)]    Script Date: 4/11/2025 11:08:16 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 4/11/2025 11:08:16 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DB Maintenance - Update Statistics (Partial Scan)', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DB Maintenance - Update Statistics (Partial Scan)]    Script Date: 4/11/2025 11:08:16 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DB Maintenance - Update Statistics (Partial Scan)', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'/*  DB Maintenance - Update Statistics (Partial Scan)  */
USE [sunwingprod]
GO

SET NOCOUNT ON
GO

DECLARE updatestats CURSOR
  FOR
    SELECT  table_schema,
            table_name
      FROM INFORMATION_SCHEMA.tables
      WHERE TABLE_TYPE = ''BASE TABLE''
      ORDER BY table_name;

OPEN updatestats

DECLARE @tableSchema NVARCHAR(128)
DECLARE @tableName NVARCHAR(128)
DECLARE @Statement NVARCHAR(300)
FETCH NEXT FROM updatestats INTO @tableSchema, @tableName

WHILE (@@fetch_status = 0)
  BEGIN
    SET @Statement = ''UPDATE STATISTICS '' + ''['' + @tableSchema + '']'' + ''.'' + ''['' + @tableName + '']'' + '' WITH SAMPLE 50 PERCENT''
    --  PRINT @Statement  --  Comment this print statement to prevent it from printing whenever you are ready to execute the command below.
    --  Please do not remove comment in next line unless that you are really sure that you want to run all commands but will cause extra workload to your server
    EXEC sp_executesql @Statement
    FETCH NEXT FROM updatestats INTO @tableSchema, @tableName
  END

CLOSE updatestats
DEALLOCATE updatestats
GO

SET NOCOUNT OFF
GO
', 
		@database_name=N'sunwingprod', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'DB Maintenance - Update Statistics (Partial Scan)', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=63, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20230315, 
		@active_end_date=99991231, 
		@active_start_time=200500, 
		@active_end_time=235959, 
		@schedule_uid=N'd1d1f0b9-d8db-49ae-9b74-c94a82c5fb16'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


