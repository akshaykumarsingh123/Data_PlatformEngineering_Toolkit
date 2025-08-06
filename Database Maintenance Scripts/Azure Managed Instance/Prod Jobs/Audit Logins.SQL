USE [msdb]
GO

/****** Object:  Job [Audit - Logins]    Script Date: 4/16/2025 11:17:55 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 4/16/2025 11:17:55 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Audit - Logins', 
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
/****** Object:  Step [Feed the DBA_ Admin DB]    Script Date: 4/16/2025 11:17:56 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Feed the DBA_ Admin DB', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'INSERT INTO
  [DBA_Admin].[dbo].[Audit_Login]
    ( [Target],
      [Source],
      [LoginInfo],
      [DBname],
      [Program],
      [LoginTime],
      [AuditTime],
      [HostProcess] )
  SELECT DISTINCT RTRIM( CAST( @@servername AS VARCHAR(100) ) )   [Target],
                  RTRIM( CAST( p.hostname AS VARCHAR(100) ) )     [Source],
                  RTRIM( CAST( p.loginame AS VARCHAR(100) ) )     [LoginInfo],
                  RTRIM( CAST( d.name AS VARCHAR(100) ) )         [DBname],
                  RTRIM( CAST( p.program_name AS VARCHAR(300) ) ) [Program],
                  MIN( p.login_time )                             [LoginTime],
                  GETDATE()                                       [AuditTime],
                  p.HostProcess                                   [HostProcess]
    FROM sysdatabases d
      INNER JOIN sysprocesses p ON p.dbid = d.dbid
    WHERE p.spid > 50
      AND p.net_address <> ''''   --  Remote connections only
      AND p.program_name NOT LIKE (''%SQLAgent%'')
      AND p.program_name NOT LIKE (''%DatabaseMail%'')
    GROUP BY p.hostname, p.loginame, d.name, p.program_name, p.HostProcess
    ORDER BY [DBname], [LoginInfo], [Source]
GO', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Feed DBA_Admin', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=15, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20200124, 
		@active_end_date=99991231, 
		@active_start_time=1313, 
		@active_end_time=235959, 
		@schedule_uid=N'8a2785ab-7043-4615-b1ab-59452bc97a04'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


