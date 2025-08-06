USE [msdb]
GO

/****** Object:  Job [Monitor Long Running Queries]    Script Date: 4/11/2025 10:47:16 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 4/11/2025 10:47:16 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Monitor Long Running Queries', 
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
/****** Object:  Step [Monitor Long Running Queries]    Script Date: 4/11/2025 10:47:16 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Monitor Long Running Queries', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @body NVARCHAR(MAX)
DECLARE @xml NVARCHAR(MAX)
-- specify long running query duration threshold
DECLARE @longrunningthreshold INT
SET @longrunningthreshold = 30
-- step 1: collect long running query details.
;
WITH cte
  AS
    (
      SELECT [Session_id] =          spid,
             [Sessioin_start_time] = (
               SELECT TOP 1 start_time
                 FROM sys.dm_exec_requests
                 WHERE spid = Session_id
                 ORDER BY start_time DESC
             ),
             [Session_status] =      LTRIM( RTRIM( [status] ) ),
             [Session_Duration] =    DATEDIFF( mi, (
               SELECT TOP 1 start_time
                 FROM sys.dm_exec_requests
                 WHERE spid = Session_id
                 ORDER BY start_time DESC
             ), GETDATE() ),
             [Session_query] =       SUBSTRING( st.text, (qs.stmt_start / 2) + 1, ((CASE qs.stmt_end
               WHEN -1 THEN DATALENGTH( st.text )
               ELSE qs.stmt_end
             END - qs.stmt_start) / 2) + 1 )
        FROM sys.sysprocesses qs
          CROSS APPLY sys.dm_exec_sql_text( sql_handle ) st
        WHERE st.text NOT LIKE ''%fn_MSxe_read_event_stream%''
          AND st.text NOT LIKE ''%Backup%''
          AND st.text NOT LIKE ''%UPDATE STATISTICS%''
          AND st.text NOT LIKE ''%ALTER INDEX%''

    )
-- step 2: generate html table

SELECT @xml = CAST( (
    SELECT session_id       AS ''td'',
           '''',
           session_duration AS ''td'',
           '''',
           session_status   AS ''td'',
           '''',
           [session_query]  AS ''td''
      FROM cte
      WHERE session_duration >= @longrunningthreshold
      FOR XML PATH (''tr''), ELEMENTS
  ) AS NVARCHAR(MAX) )

-- step 3: do rest of html formatting
SET @body =
''<html><tbody><h2> (Ariesprd) Long Running Queries ( Limit > 30 Minutes ) </h2>
	<table border = 1 BORDERCOLOR="Black"> 
		<tr>
			<th align="centre"> Session_id </th> 
			<th> Session_Duration(Minute) </th> 
			<th> Session_status </th> 
			<th> Session_query </th>
		</tr>
	''
SET @body = @body + @xml + ''</table></tbody></html>''

-- step 4: send email if a long running query is found.
IF (@xml IS NOT NULL)
  BEGIN
    EXEC msdb.dbo.sp_send_dbmail
      @profile_name = ''DBA_ALERT'',
      @body         = @body,
      @body_format  = ''html'',
      @recipients   = ''dba_alerts@sunwing.ca'',
      @subject      = ''ALERT:  (Ariesprd)- Long Running Queries'';
  END', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every 30 mins', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=30, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20210730, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'155ff600-0a0f-403f-982c-659cfbbe6b6d'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


