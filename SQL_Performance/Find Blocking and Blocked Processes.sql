SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SELECT  SPID = er.session_id,
        Blcledk_By =
          CASE
            WHEN lead_blocker = 1 THEN -1
            ELSE er.blocking_session_id
          END,
        Elapsed_MS = er.total_elapsed_time,
        CPU = er.cpu_time,
        IO_Reads = er.logical_reads + er.reads,
        IO_Writes = er.writes,
        Executions = ec.execution_count,
        Command_Type = er.command,
        Last_Wait_Type = er.last_wait_type,
        Object_Name = OBJECT_SCHEMA_NAME(qt.objectid, dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid),
        SQL_Statement = SUBSTRING(qt.text, er.statement_start_offset / 2,
        ( CASE
            WHEN er.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2
            ELSE er.statement_end_offset
          END - er.statement_start_offset ) / 2),
        STATUS = ses.STATUS,
        [Login] = ses.login_name,
        Host = ses.host_name,
        DB_Name = DB_NAME(er.database_id),
        Start_Time = er.start_time,
        Protocol = con.net_transport,
        Transaction_Isolation =
          CASE ses.transaction_isolation_level
            WHEN 0 THEN 'Unspecified'
            WHEN 1 THEN 'Read Uncommitted'
            WHEN 2 THEN 'Read Committed'
            WHEN 3 THEN 'Repeatable'
            WHEN 4 THEN 'Serializable'
            WHEN 5 THEN 'Snapshot'
          END,
        Connection_Writes = con.num_writes,
        Connection_Reads = con.num_reads,
        Client_Address = con.client_net_address,
        Authentication = con.auth_scheme,
        Datetime_Snapshot = GETDATE()
  FROM  sys.dm_exec_requests er
    LEFT JOIN sys.dm_exec_sessions ses ON ses.session_id = er.session_id
    LEFT JOIN sys.dm_exec_connections con ON con.session_id = ses.session_id
    CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) AS qt
    OUTER APPLY (
      SELECT execution_count = MAX(cp.usecounts)
      FROM sys.dm_exec_cached_plans cp
      WHERE cp.plan_handle = er.plan_handle ) ec
    OUTER APPLY (
      SELECT lead_blocker = 1
      FROM master.dbo.sysprocesses sp
      WHERE sp.SPID IN (
          SELECT blocked
          FROM master.dbo.sysprocesses )
        AND sp.blocked = 0
        AND sp.SPID = er.session_id ) lb
  ORDER BY  er.blocking_session_id DESC,
            er.logical_reads + er.reads DESC,
            er.session_id;
			
			
/*Table locked*/
SELECT
OBJECT_NAME(p.OBJECT_ID) AS TableName,
resource_type, resource_description
FROM
sys.dm_tran_locks l
JOIN sys.partitions p ON l.resource_associated_entity_id = p.hobt_id


USE yourdatabase;
GO

SELECT * FROM sys.dm_tran_locks
  WHERE resource_database_id = DB_ID()
  AND resource_associated_entity_id = OBJECT_ID(N'dbo.yourtablename');