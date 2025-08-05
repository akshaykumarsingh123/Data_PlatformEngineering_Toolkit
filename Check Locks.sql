-- Query to check if specific table is locked.
SELECT *
  from sys.dm_tran_locks
  WHERE resource_associated_entity_id = object_id('schemaname.tablename')
go

-- To find both login name of the user and the query being run
SELECT  DB_NAME(resource_database_id),
        s.original_login_name,
        s.status,
        s.program_name,
        s.host_name,
        (select text from sys.dm_exec_sql_text(exrequests.sql_handle)),
        *
  FROM  sys.dm_tran_locks dbl
  JOIN  sys.dm_exec_sessions s
    ON  dbl.request_session_id = s.session_id
  INNER JOIN  sys.dm_exec_requests exrequests
    ON  dbl.request_session_id = exrequests.session_id
  WHERE DB_NAME(dbl.resource_database_id) = 'dbname'
go

-- Display locks on tables
SELECT OBJECT_NAME(p.OBJECT_ID) AS TableName,
    resource_type, resource_description
  FROM sys.dm_tran_locks l
    JOIN sys.partitions p ON l.resource_associated_entity_id = p.hobt_id;
go

-- Currently active locks on database
SELECT  SessionID = s.Session_id,
        resource_type,
        DatabaseName = DB_NAME(resource_database_id),
        request_mode,
        request_type,
        login_time,
        host_name,
        program_name,
        client_interface_name,
        login_name,
        nt_domain,
        nt_user_name,
        s.status,
        last_request_start_time,
        last_request_end_time,
        s.logical_reads,
        s.reads,
        request_status,
        request_owner_type,
        objectid,
        dbid,
        a.number,
        a.encrypted ,
        a.blocking_session_id,
        a.text
  FROM  sys.dm_tran_locks l
  JOIN  sys.dm_exec_sessions s
    ON  l.request_session_id = s.session_id
  LEFT JOIN
      ( SELECT  *
          FROM  sys.dm_exec_requests r
          CROSS APPLY sys.dm_exec_sql_text(sql_handle) ) a
    ON  s.session_id = a.session_id
  WHERE s.session_id > 50
go
