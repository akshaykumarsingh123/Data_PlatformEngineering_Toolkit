USE [msdb]
GO

/****** Object:  Job [Audit Capacity - Tables]    Script Date: 4/16/2025 11:18:19 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 4/16/2025 11:18:19 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Audit Capacity - Tables', 
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
/****** Object:  Step [Populate Audit Table]    Script Date: 4/16/2025 11:18:19 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Populate Audit Table', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--  Step 1: Populate Audit Table
EXEC sp_MSForEachDB ''
USE [?];
  INSERT INTO [DBA_Admin].[dbo].[Audit_Capacity_Tables]
    ( [DatabaseName], [TableName], [RowCount], [TotalMB], [UsedMB], [UnusedMB] )
  SELECT  DB_NAME()                                                   [Database],
          t.name                                                      [Table Name],
          p.rows                                                      [Row Count],
          CAST(SUM(a.total_pages)/128 AS MONEY)                       [Total (MB)],
          CAST(SUM(a.used_pages)/128 AS MONEY)                        [Used (MB)],
          CAST((SUM(a.total_pages) - SUM(a.used_pages))/128 AS MONEY) [Unused (MB)]
    FROM  sys.tables t
      INNER JOIN  sys.indexes i
        ON t.OBJECT_ID = i.object_id
      INNER JOIN  sys.partitions p
        ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
      INNER JOIN  sys.allocation_units a
        ON p.partition_id = a.container_id
      LEFT OUTER JOIN sys.schemas s
        ON t.schema_id = s.schema_id
    WHERE t.is_ms_shipped = 0
      AND i.OBJECT_ID > 255
      AND DB_NAME() NOT IN
      ( ''''DBA_Admin'''',''''DISTRIBUTION'''',''''MASTER'''',''''MODEL'''',''''MSDB'''',''''SSISDB'''',''''TEMPDB'''' ) --  Ignore DBA/System databases
    GROUP BY  t.name, p.rows
    ORDER BY  [Database], [Table Name]''
GO
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Run Audit Tables Job', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20220301, 
		@active_end_date=99991231, 
		@active_start_time=235500, 
		@active_end_time=235959, 
		@schedule_uid=N'52a71af2-90aa-43f3-8b83-db132b30a422'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


