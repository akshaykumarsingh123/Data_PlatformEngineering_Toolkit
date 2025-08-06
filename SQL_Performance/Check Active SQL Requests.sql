--  Check Active SQL Requests
--  This query will show what is running and estimate how long it will take
SELECT  DB_NAME(r.database_id)  AS  [Database],
        r.session_id,
        r.start_time,
        r.status,
        r.command,
        r.cpu_time,
        r.total_elapsed_time,
        r.percent_complete,
        t.text
  FROM  sys.dm_exec_requests r
    CROSS apply sys.dm_exec_sql_text(r.sql_handle) t
  WHERE session_id != @@SPID  --  don't show this query
    AND session_id > 50       --  don't show system queries
  ORDER BY command
GO