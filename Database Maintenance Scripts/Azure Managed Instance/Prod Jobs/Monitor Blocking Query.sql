USE [msdb]
GO

/****** Object:  Job [Monitor Blocking Query]    Script Date: 4/11/2025 10:46:03 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 4/11/2025 10:46:03 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Monitor Blocking Query', 
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
/****** Object:  Step [Monitor Blocked Processes]    Script Date: 4/11/2025 10:46:04 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Monitor Blocked Processes', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @body NVARCHAR(max)
declare @xml nvarchar(max)
-- specify long running query duration threshold
--DECLARE @longrunningthreshold int
--SET @longrunningthreshold=2;

WITH cteBL (session_id, blocking_these) AS 
(SELECT s.session_id, blocking_these = x.blocking_these FROM sys.dm_exec_sessions s 
CROSS APPLY    (SELECT isnull(convert(varchar(6), er.session_id),'''') --+ '', ''  
                FROM sys.dm_exec_requests as er
                WHERE er.blocking_session_id = isnull(s.session_id ,0)
                AND 
				er.blocking_session_id <> 0
                FOR XML PATH('''') ) AS x (blocking_these)
)
SELECT s.session_id, blocked_by = r.blocking_session_id, bl.blocking_these
,  input_buffer = ib.event_info, s.login_time,s.host_name,s.program_name,s.original_login_name  into #temp
FROM sys.dm_exec_sessions s 
LEFT OUTER JOIN sys.dm_exec_requests r on r.session_id = s.session_id
INNER JOIN cteBL as bl on s.session_id = bl.session_id
OUTER APPLY sys.dm_exec_sql_text (r.sql_handle) t
OUTER APPLY sys.dm_exec_input_buffer(s.session_id, NULL) AS ib
--WHERE (blocking_these is not null or r.blocking_session_id > 0) and r.wait_time>300000
WHERE blocking_these is not null or r.blocking_session_id > 0
ORDER BY len(bl.blocking_these) desc, r.blocking_session_id desc, r.session_id;
select * from #temp
 -- step 2: generate html table
 SELECT @xml = Cast((SELECT session_id AS ''td'',
'''',
isnull(blocked_by,'''') AS ''td'',
'''',
isnull(blocking_these,''NULL'') AS ''td'',
'''',
isnull(input_buffer,'''') as ''td'',
'''',
login_time as ''td'',
'''',
host_name as ''td'',
'''',
program_name as ''td'',
'''',
original_login_name as ''td'',
''''
from #temp
--WHERE floor(total_elapsed_time / (1000 * 60)) % 60 >= @longrunningthreshold and blocking_session_id<>0
FOR xml path(''tr''), elements) AS NVARCHAR(max))
select * from #temp
-- step 3: do rest of html formatting
SET @body =
''<html><tbody><h2> Blocked Queries are found </h2>
	<table border = 1 BORDERCOLOR="Black"> 
		<tr>
			<th align="centre"> Session_id </th> 
			<th> Blocked_By </th> 
			<th> Blocking_These </th> 
			<th> Input_Buffer </th>
			<th> Login_time </th>
			<th> Host_Name </th>
			<th> Program_Name </th>
			<th> Login_Name </th>
		</tr>	''
SET @body = @body + @xml + ''</table></tbody></html>''
 
-- step 4: send email if a BLOCKING query is found.
IF( @xml is not null)
BEGIN
EXEC msdb.dbo.Sp_send_dbmail
@profile_name = ''DBA_ALERT'',
@body = @body,
@body_format =''html'',
@recipients = ''dba_alerts@sunwing.ca'',
@subject = ''ALERT:  Blocked Queries'';
END
drop table #temp

', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every 5 mins', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20210730, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'a00611c9-4c18-43ca-a324-fe5102173486'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


