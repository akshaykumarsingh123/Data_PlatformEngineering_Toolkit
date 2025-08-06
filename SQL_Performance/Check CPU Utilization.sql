/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
--  https://blogs.msdn.microsoft.com/docast/2017/07/30/sql-high-cpu-troubleshooting-checklist/
/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
--  Must be run when CPU is high to capture live data
/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
SELECT  s.session_id,
        r.STATUS,
        r.blocking_session_id 'Blk by',
        r.wait_type,
        wait_resource,
        r.wait_time / (1000 * 60) 'Wait M',
        r.cpu_time,
        r.logical_reads,
        r.reads,
        r.writes,
        r.total_elapsed_time / (1000 * 60) 'Elaps M',
        SUBSTRING(st.TEXT, (r.statement_start_offset / 2) + 1,
          ( ( CASE r.statement_end_offset
                WHEN - 1
                THEN DATALENGTH(st.TEXT)
              ELSE r.statement_end_offset
              END - r.statement_start_offset ) / 2 ) + 1) AS statement_text,
        COALESCE(Quotename(DB_NAME(st.dbid)) + N'.'
                  + Quotename(Object_schema_name(st.objectid, st.dbid)) + N'.'
                  + Quotename(OBJECT_NAME(st.objectid, st.dbid)), '') AS command_text,
        r.command,
        s.login_name,
        s.host_name,
        s.program_name,
        s.last_request_end_time,
        s.login_time,
        r.open_transaction_count
  FROM  sys.dm_exec_sessions AS s
  INNER JOIN sys.dm_exec_requests AS r
    ON  r.session_id = s.session_id
  CROSS APPLY sys.Dm_exec_sql_text(r.sql_handle) AS st
  WHERE r.session_id != @@SPID
  ORDER BY r.cpu_time DESC
go
/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
