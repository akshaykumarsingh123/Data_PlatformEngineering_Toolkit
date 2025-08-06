USE [msdb]
GO

/****** Object:  Job [Monitor DB Size]    Script Date: 4/11/2025 10:47:53 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 4/11/2025 10:47:53 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Monitor DB Size', 
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
/****** Object:  Step [Monitor DB Size]    Script Date: 4/11/2025 10:47:54 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Monitor DB Size', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @threshold INT = 750000

-- step 1: Create temp table and record sqlperf data

CREATE TABLE #DBList
  (
    database_Name SYSNAME,
    log_size_mb   DECIMAL(18, 5),
    row_size_mb   DECIMAL(18, 5),
    total_size_mb DECIMAL(18, 5)
  )

INSERT INTO
  #DBList
  SELECT database_name = DB_NAME( database_id ),
         log_size_mb =   CAST( SUM( CASE
           WHEN type_desc = ''LOG'' THEN size
         END ) * 8. / 1024 AS DECIMAL(8, 2) ),
         row_size_mb =   CAST( SUM( CASE
           WHEN type_desc = ''ROWS'' THEN size
         END ) * 8. / 1024 AS DECIMAL(12, 2) ),
         total_size_mb = CAST( SUM( size ) * 8. / 1024 AS DECIMAL(12, 2) )
    FROM sys.master_files WITH (NOWAIT)
    WHERE database_id = DB_ID() -- for current db 
    GROUP BY database_id

-- step 2: get DB exceeding threshold size in html table format

DECLARE @xml NVARCHAR(MAX)

SELECT @xml = CAST( (
    SELECT database_Name AS ''td'',
           '''',
           log_size_mb   AS ''td'',
           '''',
           row_size_mb   AS ''td'',
           '''',
           total_size_mb AS ''td''


      FROM #DBList
      WHERE total_size_mb >= (@threshold)
      FOR XML PATH (''tr''), ELEMENTS
  ) AS NVARCHAR(MAX) )

-- step 3: Specify table header and complete html formatting

DECLARE @body NVARCHAR(MAX)

SET @body =
''<html><body><H2>High T-Log Size </H2><table border = 1 BORDERCOLOR="Black"> <tr><th> Database </th>  <th> log_size_mb </th><th> row_size_mb </th> <th> total_size_mb </th> </tr>''

SET @body = @body + @xml + ''</table></body></html>''

-- step 4: send email if a DB Size exceeds threshold

IF (@xml IS NOT NULL)

  BEGIN

    EXEC msdb.dbo.sp_send_dbmail
      @profile_name = ''DBA_Alert'',
      @body         = @body,
      @body_format  = ''html'',
      @recipients   = ''dba_alerts@sunwing.ca'',
      @subject      = ''ALERT: DB has exceeded threshold Size'';

  END

DROP TABLE #DBList

SET NOCOUNT OFF', 
		@database_name=N'sunwingprod', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Twice a Day', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=12, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20210730, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'1a248343-d6b4-4428-844a-8a43e22fe9b3'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


