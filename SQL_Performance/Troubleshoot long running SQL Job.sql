*/---Active SQL Jobs----/*
	select a.session_id, b.job_id, b.name
from sys.dm_exec_sessions a
	inner join msdb.dbo.sysjobs b on b.job_id = cast(convert( binary(16), substring(a.program_name , 30, 34), 1) as uniqueidentifier)
where program_name like 'SQLAgent - TSQL JobStep (Job % : Step %)'

*/---Job Id's---/*
SELECT        TOP (100) PERCENT sj.name, sja.run_requested_date, CONVERT(VARCHAR(12), sja.stop_execution_date - sja.start_execution_date, 114) AS Duration, sj.job_id, sj.enabled
FROM            msdb.dbo.sysjobactivity AS sja INNER JOIN
                         msdb.dbo.sysjobs AS sj ON sja.job_id = sj.job_id
WHERE        (sja.run_requested_date IS NOT NULL) AND (CONVERT(VARCHAR(12), sja.stop_execution_date - sja.start_execution_date, 114) > CONVERT(VARCHAR(12), '00:00:02:000', 114))
ORDER BY sja.run_requested_date DESC

*/sessions/*
SELECT *
FROM sys. dm_exec_sessions


*/---Activity Monitor---*/
SELECT [Session ID] = s.session_id, 
       [User Process] = CONVERT(CHAR(1), s.is_user_process), 
       [Login] = s.login_name, 
       [Blocked By] = ISNULL(CONVERT (varchar, w.blocking_session_id), ''), 
         [Head Blocker]  =
    CASE
        -- session has an active request, is blocked, but is blocking others or session is idle but has an open tran and is blocking others
        WHEN r2.session_id IS NOT NULL AND (r.blocking_session_id = 0 OR r.session_id IS NULL) THEN '1'
        -- session is either not blocking someone, or is blocking someone but is blocked by another party
        ELSE ''
    END,
                        [DatabaseName] = ISNULL(db_name(r.database_id), N''), 
                        [Task State] = ISNULL(t.task_state, N''), 
                        [Command] = ISNULL(r.command, N''), 
                        [statement_text] = Substring(st.TEXT, (r.statement_start_offset / 2) + 1, 
                                            ( ( CASE r.statement_end_offset WHEN - 1 THEN Datalength(st.TEXT)
                                            ELSE r.statement_end_offset 
                                            END - r.statement_start_offset ) / 2 ) + 1), ----It will display the statement which is being executed presently.

 [command_text] =Coalesce(Quotename(Db_name(st.dbid)) + N'.' + Quotename(Object_schema_name(st.objectid, st.dbid)) + N'.' + Quotename(Object_name(st.objectid, st.dbid)), ''), -- It will display the Stored Procedure's Name.

 [Total CPU (ms)] = r.cpu_time,
 r.total_elapsed_time / (1000.0) 'Elapsed Time (in Sec)',
                                 [Wait Time (ms)] = ISNULL(w.wait_duration_ms, 0),
                                 [Wait Type] = ISNULL(w.wait_type, N''),
                                 [Wait Resource] = ISNULL(w.resource_description, N''),
                                 [Total Physical I/O (MB)] = (s.reads + s.writes) * 8 / 1024,
                                 [Memory Use (KB)] = s.memory_usage * 8192 / 1024, 
 --[Open Transactions Count] = ISNULL(r.open_transaction_count,0),
 --[Login Time]    = s.login_time,
 --[Last Request Start Time] = s.last_request_start_time,

 [Host Name] = ISNULL(s.host_name, N''),
 [Net Address] = ISNULL(c.client_net_address, N''), 

 -- [Execution Context ID] = ISNULL(t.exec_context_id, 0),
 -- [Request ID] = ISNULL(r.request_id, 0),
 [Workload Group] = N'',
                     [Application] = ISNULL(s.program_name, N'')
FROM sys.dm_exec_sessions s
LEFT OUTER JOIN sys.dm_exec_connections c ON (s.session_id = c.session_id)
LEFT OUTER JOIN sys.dm_exec_requests r ON (s.session_id = r.session_id)
LEFT OUTER JOIN sys.dm_os_tasks t ON (r.session_id = t.session_id
                                      AND r.request_id = t.request_id)
LEFT OUTER JOIN
  ( -- In some cases (e.g. parallel queries, also waiting for a worker), one thread can be flagged as
 -- waiting for several different threads.  This will cause that thread to show up in multiple rows
 -- in our grid, which we don't want.  Use ROW_NUMBER to select the longest wait for each thread,
 -- and use it as representative of the other wait relationships this thread is involved in.
 SELECT *, 
        ROW_NUMBER() OVER (PARTITION BY waiting_task_address
                           ORDER BY wait_duration_ms DESC) AS row_num 
   FROM sys.dm_os_waiting_tasks ) w ON (t.session_id = w.session_id)
AND w.row_num = 1 
LEFT OUTER JOIN sys.dm_exec_requests r2 ON (r.session_id = r2.blocking_session_id) OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) AS st 

WHERE s.session_Id > 50 -- Ignore system spids.

ORDER BY s.session_id --,[Total CPU (ms)] desc ;

