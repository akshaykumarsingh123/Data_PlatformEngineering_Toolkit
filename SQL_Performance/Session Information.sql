/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
--  List sessions connected to the specific database (variable must be given)
--  Analyze what each SPID is doing, reads and writes
/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
USE master
GO
DECLARE @DatabaseName   VARCHAR(255)
SELECT  @DatabaseName = 'sunwingprod'

SELECT  sdes.session_id,
        sdes.login_time,
        sdes.last_request_start_time,
        sdes.last_request_end_time,
        sdes.host_name,
        sdes.program_name,
        sdes.login_name,
        sdes.status,
        sdec.num_reads,
        sdec.num_writes,
        sdec.last_read,
        sdec.last_write,
        sdes.reads,
        sdes.logical_reads,
        sdes.writes,
        sdest.database_name,
        sdest.object,
        sdes.client_interface_name,
        sdes.nt_domain,
        sdes.nt_user_name,
        sdec.client_net_address,
        sdec.local_net_address,
        sdest.query
  FROM  sys.dm_exec_sessions AS sdes
    INNER JOIN sys.dm_exec_connections AS sdec ON sdec.session_id = sdes.session_id
    CROSS APPLY ( SELECT  DB_NAME(dbid)               AS  database_name,
                          OBJECT_NAME(objectid)       AS  object,
                          COALESCE((  SELECT  text    AS  [SQL-Query]
                                        FROM  sys.Dm_exec_sql_text(sdec.most_recent_sql_handle)
                                          FOR xml path(''), type), '') AS Query
                    FROM  sys.Dm_exec_sql_text(sdec.most_recent_sql_handle)) AS sdest
  WHERE sdes.session_id <> @@SPID
    AND sdest.database_name = @DatabaseName
  ORDER BY  sdes.status,
            sdes.last_request_start_time DESC
GO

/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

SELECT  EC.session_id, host_name, program_name,
        nt_domain, login_name, status, cpu_time, memory_usage,
        connect_time, login_time,
        last_request_start_time, last_request_end_time,
        last_read, last_write
  FROM  sys.dm_exec_sessions      ES
  JOIN  sys.dm_exec_connections   EC
    ON  ES.session_id = EC.session_id
  ORDER BY cpu_time DESC, memory_usage DESC;

--  2012 and higher
SELECT DB_NAME(database_id) as [DB]
    , login_name
    , nt_domain
    , nt_user_name
    , status
    , host_name
    , program_name
    , COUNT(*) AS [Connections]
FROM sys.dm_exec_sessions
WHERE database_id > 0 -- OR 4 for user DBs
GROUP BY database_id, login_name, status, host_name, program_name, nt_domain, nt_user_name;

--  2008 and higher
SELECT DB_NAME(dbid) as DBName, COUNT(dbid) as 'Number Of Connections',
    loginame as LoginName
FROM sys.sysprocesses
WHERE dbid > 0
GROUP BY dbid, loginame
ORDER BY dbid, loginame


SELECT  percent_complete,
        estimated_completion_time,
        *
  FROM  sys.dm_exec_requests r
  INNER join sys.dm_os_tasks t on r.session_id = t.session_id


SELECT  WT.session_id,
        OT.task_state,
        WT.wait_type,
        WT.wait_duration_ms,
        WT.blocking_session_id,
        WT.resource_description,
        ES.host_name,
        ES.program_name
  FROM  sys.dm_os_waiting_tasks  WT
    INNER JOIN sys.dm_os_tasks OT
      ON  OT.task_address = WT.waiting_task_address
    INNER JOIN sys.dm_exec_sessions ES
      ON  ES.session_id = WT.session_id
  WHERE ES.is_user_process =  1

SELECT  s.session_id
        , r.granted_query_memory * 8 AS memory_used_kb
        , a.ideal_memory_kb
FROM    sys.dm_exec_sessions AS s
INNER JOIN sys.dm_exec_requests AS r ON r.session_id = s.session_id
LEFT JOIN sys.dm_exec_query_memory_grants a ON a.session_id = s.session_id

SELECT  s.session_id, r.command, r.status,
r.wait_type, r.scheduler_id, w.worker_address,
w.is_preemptive, w.state, t.task_state,
t.session_id, t.exec_context_id, t.request_id
FROM sys.dm_exec_sessions AS s
INNER JOIN sys.dm_exec_requests AS r
ON s.session_id = r.session_id
INNER JOIN sys.dm_os_tasks AS t
ON r.task_address = t.task_address
INNER JOIN sys.dm_os_workers AS w
ON t.worker_address = w.worker_address
WHERE s.is_user_process = 0;



SELECT
  physical_memory_in_use_kb/1024 AS sql_physical_memory_in_use_MB,
    large_page_allocations_kb/1024 AS sql_large_page_allocations_MB,
    locked_page_allocations_kb/1024 AS sql_locked_page_allocations_MB,
    virtual_address_space_reserved_kb/1024 AS sql_VAS_reserved_MB,
    virtual_address_space_committed_kb/1024 AS sql_VAS_committed_MB,
    virtual_address_space_available_kb/1024 AS sql_VAS_available_MB,
    page_fault_count AS sql_page_fault_count,
    memory_utilization_percentage AS sql_memory_utilization_percentage,
    process_physical_memory_low AS sql_process_physical_memory_low,
    process_virtual_memory_low AS sql_process_virtual_memory_low
FROM sys.dm_os_process_memory;




SELECT  wt.session_id,
    ot.task_state,
    wt.wait_type,
    wt.wait_duration_ms,
    wt.blocking_session_id,
    wt.resource_description,
    es.[host_name],
    es.[program_name] ,
    r.percent_complete,r.estimated_completion_time
FROM  sys.dm_os_waiting_tasks  wt
INNER  JOIN sys.dm_os_tasks ot ON ot.task_address = wt.waiting_task_address
INNER JOIN sys.dm_exec_sessions es ON es.session_id = wt.session_id
inner join sys.dm_exec_requests r on r.session_id = wt.session_id
WHERE es.is_user_process =  1


SELECT es.session_id AS session_id,
COALESCE(es.original_login_name, '') AS login_name,
COALESCE(es.host_name,'') AS hostname,
COALESCE(es.last_request_end_time,es.last_request_start_time) AS last_batch,
es.status,
COALESCE(er.blocking_session_id,0) AS blocked_by,
COALESCE(er.wait_type,'MISCELLANEOUS') AS waittype,
COALESCE(er.wait_time,0) AS waittime,
COALESCE(er.last_wait_type,'MISCELLANEOUS') AS lastwaittype,
COALESCE(er.wait_resource,'') AS waitresource,
coalesce(db_name(er.database_id),'No Info') as dbid,
COALESCE(er.command,'AWAITING COMMAND') AS cmd,
sql_text=st.text,
transaction_isolation =
    CASE es.transaction_isolation_level
    WHEN 0 THEN 'Unspecified'
    WHEN 1 THEN 'Read Uncommitted'
    WHEN 2 THEN 'Read Committed'
    WHEN 3 THEN 'Repeatable'
    WHEN 4 THEN 'Serializable'
    WHEN 5 THEN 'Snapshot'
END,
COALESCE(es.cpu_time,0)
    + COALESCE(er.cpu_time,0) AS cpu,
COALESCE(es.reads,0)
    + COALESCE(es.writes,0)
    + COALESCE(er.reads,0)
    + COALESCE(er.writes,0) AS physical_io,
COALESCE(er.open_transaction_count,-1) AS open_tran,
COALESCE(es.program_name,'') AS program_name,
es.login_time
FROM sys.dm_exec_sessions es
    LEFT OUTER JOIN sys.dm_exec_connections ec ON es.session_id = ec.session_id
    LEFT OUTER JOIN sys.dm_exec_requests er ON es.session_id = er.session_id
    LEFT OUTER JOIN sys.server_principals sp ON es.security_id = sp.sid
    LEFT OUTER JOIN sys.dm_os_tasks ota ON es.session_id = ota.session_id
    LEFT OUTER JOIN sys.dm_os_threads oth ON ota.worker_address = oth.worker_address
    CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) AS st
where es.is_user_process = 1
ORDER BY es.session_id


sp_who2 891
SELECT  spid,
        kpid,
        login_time,
        last_batch,
        status,
        cmd,
        hostname,
        program_name,
        nt_username,
        loginame,
        hostprocess,
        waittime,
        waitresource,
        cpu,
        memusage,
        physical_io
  FROM  sys.sysprocesses
  WHERE cmd = 'KILLED/ROLLBACK'
go
SELECT * FROM sys.sysprocesses
WHERE cmd = 'KILLED/ROLLBACK'
KILL 891 WITH STATUSONLY
DBCC INPUTBUFFER (891)
DBCC OPENTRAN

sp_lock
SELECT  *
  FROM  sys.dm_tran_locks

SELECT spid, loginame, program_name, hostname as "From host", login_time, last_batch, DB_NAME(dbid) AS "Against database" ,
(SELECT text FROM sys.dm_exec_sql_text(sql_handle))as "Query executed"
FROM master..sysprocesses WHERE spid = 891 AND open_tran > 0


USE [master]
GO
SELECT   w.session_id
,w.wait_duration_ms
,w.wait_type
,w.blocking_session_id
,w.resource_description
,s.program_name
,t.text
,t.dbid
,s.cpu_time
,s.memory_usage
FROM sys.dm_os_waiting_tasks w
INNER JOIN sys.dm_exec_sessions s
ON w.session_id = s.session_id
INNER JOIN sys.dm_exec_requests r
ON s.session_id = r.session_id
OUTER APPLY sys.dm_exec_sql_text (r.sql_handle) t
WHERE s.is_user_process = 1
GO



USE [master]
GO
SELECT  session_id
,blocking_session_id
,wait_time
,wait_type
,last_wait_type
,wait_resource
,transaction_isolation_level
,lock_timeout
FROM sys.dm_exec_requests
WHERE blocking_session_id <> 0
GO



ALTER DATABASE BREEZESW SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE

ALTER DATABASE BREEZESW SET MULTI_USER WITH ROLLBACK IMMEDIATE


USE master;
ALTER DATABASE BREEZESW SET OFFLINE WITH ROLLBACK IMMEDIATE;
ALTER DATABASE BREEZESW SET ONLINE;
ALTER DATABASE BREEZESW SET READ_WRITE WITH NO_WAIT
go


-- For MS SQL Server 2012 and above
USE [master];
DECLARE @kill varchar(8000) = '';
SELECT @kill = @kill + 'kill ' + CONVERT(varchar(5), session_id) + ';'
FROM sys.dm_exec_sessions
WHERE database_id  = db_id('MyDB')
EXEC(@kill);

-- For MS SQL Server 2000, 2005, 2008
USE master;
DECLARE @kill varchar(8000); SET @kill = '';
SELECT @kill = @kill + 'kill ' + CONVERT(varchar(5), spid) + ';'
FROM master..sysprocesses
WHERE dbid = db_id('MyDB')
EXEC(@kill);


-- Matthew's supremely efficient script updated to use the dm_exec_sessions DMV, replacing the deprecated sysprocesses system table:
USE [master];
GO

DECLARE @Kill VARCHAR(8000) = '';

SELECT
    @Kill = @Kill + 'kill ' + CONVERT(VARCHAR(5), session_id) + ';'
FROM
    sys.dm_exec_sessions
WHERE
    database_id = DB_ID('<YourDB>');

EXEC sys.sp_executesql @Kill;

-- Alternative using WHILE loop (if you want to process any other operations per execution):
USE [master];
GO

DECLARE @DatabaseID SMALLINT = DB_ID(N'<YourDB>');
DECLARE @SQL NVARCHAR(10);

WHILE EXISTS ( SELECT
                1
               FROM
                sys.dm_exec_sessions
               WHERE
                database_id = @DatabaseID )
    BEGIN;
        SET @SQL = (
                    SELECT TOP 1
                        N'kill ' + CAST(session_id AS NVARCHAR(5)) + ';'
                    FROM
                        sys.dm_exec_sessions
                    WHERE
                        database_id = @DatabaseID
                   );
        EXEC sys.sp_executesql @SQL;
    END;

-- You should be careful about exceptions during killing processes. So you may use this script:
USE master;
GO
 DECLARE @kill varchar(max) = '';
 SELECT @kill = @kill + 'BEGIN TRY KILL ' + CONVERT(varchar(5), spid) + ';' + ' END TRY BEGIN CATCH END CATCH ;' FROM master..sysprocesses
EXEC (@kill)


--  The code below is entirely based on @AlexK's answer, the difference is that you can specify the user and a time since
--  the last batch was executed (note that the code uses sys.dm_exec_sessions instead of master..sysprocess):
DECLARE @kill varchar(8000);
set @kill =''
select @kill = @kill + 'kill ' +  CONVERT(varchar(5), session_id) + ';' from sys.dm_exec_sessions
where login_name = 'usrDBTest'
and datediff(hh,login_time,getdate()) > 1
--and session_id in (311,266)
exec(@kill)



SELECT
    spid,
    sp.[status],
    loginame [Login],
    hostname,
    blocked BlkBy,
    sd.name DBName,
    cmd Command,
    cpu CPUTime,
    memusage Memory,
    physical_io DiskIO,
    lastwaittype LastWaitType,
    [program_name] ProgramName,
    last_batch LastBatch,
    login_time LoginTime,
    'kill ' + CAST(spid as varchar(10)) as 'Kill Command'
FROM master.dbo.sysprocesses sp
JOIN master.dbo.sysdatabases sd ON sp.dbid = sd.dbid
WHERE sd.name NOT IN ('master', 'model', 'msdb')
--AND sd.name = 'db_name'
--AND hostname like 'hostname1%'
--AND loginame like 'username1%'
ORDER BY spid
/* If a service connects continuously. You can automatically execute kill process then run your script:
DECLARE @sqlcommand nvarchar (500)
SELECT @sqlcommand = 'kill ' + CAST(spid as varchar(10))
FROM master.dbo.sysprocesses sp
JOIN master.dbo.sysdatabases sd ON sp.dbid = sd.dbid
WHERE sd.name NOT IN ('master', 'model', 'msdb')
--AND sd.name = 'db_name'
--AND hostname like 'hostname1%'
--AND loginame like 'username1%'
--SELECT @sqlcommand
EXEC sp_executesql @sqlcommand
*/