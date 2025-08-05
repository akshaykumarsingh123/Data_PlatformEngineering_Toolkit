/* ----------------------------------------------------------------------------------------------------------------- */
--  Auditing tracked in DBA_Admin database
/* ----------------------------------------------------------------------------------------------------------------- */
--  Last Server Login
SELECT  RTRIM( UPPER([Target]) )  AS  [Target Endpoint],
        RTRIM( [Source] )         AS  [Source Endpoint],
        RTRIM( [LoginInfo] )      AS  [SQL Login],
        MAX( [LoginTime] )        AS  [Last Login Time]
  FROM  [DBA_Admin].[dbo].[Audit_Login]
  WHERE ( [LoginInfo] = 'sa'
          OR [LoginInfo] = 'boreports'
          OR [LoginInfo] = 'pcvoyages'
          OR [LoginInfo] LIKE '%svc_%' )
    AND [Source] NOT IN ( 'STG70485-LT', 'STG70612-LT', 'STG100875-LT', 'STG100440-DT', 'STG101343-LT' )
    AND ( RTRIM( [LoginInfo] ) IS NOT NULL
          AND RTRIM( [LoginInfo] ) != '' )
  GROUP BY  [Target], [Source], [LoginInfo]
  ORDER BY  [Target], [Source], [LoginInfo]
GO

--  Last Database Login
SELECT  RTRIM( UPPER([Target]) )  AS  [Target Endpoint],
        RTRIM( [DBname] )         AS  [Database Name],
        RTRIM( [Source] )         AS  [Source Endpoint],
        RTRIM( [LoginInfo] )      AS  [SQL Login],
        MAX( [LoginTime] )        AS  [Last Login Time]
  FROM  [DBA_Admin].[dbo].[Audit_Login]
  WHERE ( [LoginInfo] = 'sa'
          OR [LoginInfo] = 'boreports'
          OR [LoginInfo] = 'pcvoyages'
          OR [LoginInfo] LIKE '%svc_%' )
    AND [DBname] = 'BREEZESW'     -- Target Database
    AND [Source] NOT IN ( 'STG70485-LT', 'STG70612-LT', 'STG100875-LT', 'STG100440-DT', 'STG101343-LT' )
  GROUP BY  [Target], [DBname], [Source], [LoginInfo]
  ORDER BY  [Target], [DBname], [Source], [LoginInfo]
GO

--  Check Developer / QA access endpoints for the last 90 days
SELECT  RTRIM( UPPER([Target]) )  AS  [Target Endpoint],
        RTRIM( [DBname] )         AS  [Database Name],
        RTRIM( [Source] )         AS  [Source Endpoint],
        RTRIM( [LoginInfo] )      AS  [SQL Login],
        RTRIM( [Program] )        AS  [Program],
        MAX( [LoginTime] )        AS  [Last Login Time]
  FROM  [DBA_Admin].[dbo].[Audit_Login]
  WHERE ( [LoginInfo] = 'sa'
          OR [LoginInfo] = 'boreports'
          OR [LoginInfo] = 'pcvoyages'
          OR [LoginInfo] LIKE 'svc_%' )
    AND [Program] LIKE '%Microsoft SQL Server Management Studio%'
    AND [Source] NOT IN ( 'STG70485-LT', 'STG70612-LT', 'STG100875-LT', 'STG100440-DT', 'STG101343-LT' )
    AND [LoginTime] >= DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate())-90)
  GROUP BY  [Target], [DBname], [Source], [LoginInfo], [Program]
  ORDER BY  [Target], [DBname], [Source], [LoginInfo], [Program]
GO

--  Find server endpoint connections
SELECT  RTRIM( UPPER([Target]) )  AS  [Target Endpoint],
        RTRIM( [Source] )         AS  [Source Endpoint],
        MAX( [LoginTime] )        AS  [Last Login Time]
  FROM  [DBA_Admin].[dbo].[Audit_Login]
  --  Exclude End User connections
  WHERE [Source] NOT LIKE 'STG%'
    AND [Source] NOT LIKE 'DB%'
    AND [Source] NOT LIKE 'NBC%'
    AND [Source] NOT LIKE 'DESKTOP%'
    AND [Source] NOT LIKE 'LAPTOP%'
    AND [Source] NOT LIKE 'SOFIFY%'
    AND [Source] NOT LIKE '%NEW'  --  Exclude name during server migration
    AND [Target] NOT LIKE '%NEW'  --  Exclude name during server migration
    AND [Source] != SERVERPROPERTY('ServerName')  --  Exclude local host
    AND [LoginTime] >= DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate())-120)
  GROUP BY  [Target], [Source]
  ORDER BY  [Last Login Time] DESC, [Target], [Source]
GO

--  Find detailed server endpoint connections
SELECT  RTRIM( UPPER([Target]) )  AS  [Target Endpoint],
        RTRIM( [DBname] )         AS  [Database Name],
        RTRIM( [Source] )         AS  [Source Endpoint],
        RTRIM( [LoginInfo] )      AS  [SQL Login],
        RTRIM( [Program] )        AS  [Program],
        MAX( [LoginTime] )        AS  [Last Login Time]
  FROM  [DBA_Admin].[dbo].[Audit_Login]
  WHERE [Program] NOT LIKE '%Microsoft SQL Server Management Studio%' -- End User Software
    AND [Source] !=  @@SERVERNAME           --  Local Machine
    AND [Source] NOT LIKE 'STG%'            --  End User
    AND [Source] NOT LIKE 'DB%'             --  End User
    AND [Source] NOT LIKE 'NBC%'            --  End User
    AND [Source] NOT LIKE 'DESKTOP%'        --  End User
    AND [Source] NOT LIKE 'LAPTOP%'         --  End User
    AND [Source] NOT LIKE 'SOFIFY%'         --  End User
    AND [Source] NOT LIKE 'SOFTIFY%'        --  End User
    AND [LoginInfo] != 'DPA'                --  Exclude Database Performance Analyzer
    AND [LoginInfo] != 'svc_SoftvoyageRep'  --  Exclude Softvoyage Replication
    AND [LoginInfo] != '' AND [LoginInfo] IS NOT NULL --  Remove empty login names
    AND [LoginTime] >= '2023-01-01'         --  Only connections for 2023
  GROUP BY  [Target], [DBname], [Source], [LoginInfo], [Program]
  ORDER BY  [Last Login Time] DESC, [Target], [DBname], [Source], [LoginInfo], [Program]
GO

--  Look for all 'sa' connections for the last 90 days
SELECT  RTRIM( UPPER([Target]) )  AS  [Target Endpoint],
        RTRIM( [DBname] )         AS  [Database Name],
        RTRIM( [Source] )         AS  [Source Endpoint],
        RTRIM( [LoginInfo] )      AS  [SQL Login],
        RTRIM( [Program] )        AS  [Program],
        [LoginTime]               AS  [Login Time]
  FROM  [DBA_Admin].[dbo].[Audit_Login]
  WHERE [Program] NOT LIKE '%Microsoft SQL Server Management Studio%' -- End User Software
    AND [LoginInfo] = 'sa'                  --  Include 'sa' connections only
    AND [LoginTime] >= GETDATE() - 90       --  Check for the last 90 days
  ORDER BY  [Target], [DBname], [Source], [Login Time] DESC, [LoginInfo], [Program]
GO

/* ----------------------------------------------------------------------------------------------------------------- */
--  Works for SQL Server 2000 AND Higher
/* ----------------------------------------------------------------------------------------------------------------- */
SELECT DISTINCT @@SERVERNAME            AS  'Target_Hostname',
                p.hostname              AS  'Source_Hostname',
                p.loginame              AS  'Login',
                d.name                  AS  'Database',
                p.program_name          AS  'Program',
                MIN(p.login_time )      AS  'Login_DateTime',
                GETDATE()               AS  'Audit_DateTime',
                p.hostprocess           AS  'Host_Process'
  FROM  master.dbo.sysdatabases d
    INNER JOIN master.dbo.sysprocesses p
      ON  p.dbid = d.dbid
  WHERE p.spid > 50
    AND p.hostname <> ''
  GROUP BY p.hostname, p.loginame, d.name, p.program_name, p.hostprocess
  ORDER BY d.name, p.loginame, p.hostname
GO


/* ----------------------------------------------------------------------------------------------------------------- */
--  Detailed Session/Process Information - Only works for SQL Server 2008 AND Higher
/* ----------------------------------------------------------------------------------------------------------------- */
SELECT  SessionId                 = s.session_id,
        [LoginInfo]                 = s.login_name,
        DatabaseName              = ISNULL(DB_NAME(r.database_id), N''),
        TaskState                 = ISNULL(t.task_state, N''),
        Command                   = ISNULL(r.command, N''),
        App                       = ISNULL(s.program_name, N''),
        OpenTrans                 = ISNULL(r.open_transaction_count,0),
        [LoginTime]                 = s.login_time,
        LastReqStartTime          = s.last_request_start_time,
        HostName                  = ISNULL(s.host_name, N''),
        NetworkAddress            = ISNULL(c.client_net_address, N''),
        ExecContext               = ISNULL(t.exec_context_id, 0),
        RequestId                 = ISNULL(r.request_id, 0),
        LastCommandBatch          = ( SELECT text FROM sys.dm_exec_sql_text(c.most_recent_sql_handle))
  FROM  sys.dm_exec_sessions s
    LEFT OUTER JOIN sys.dm_exec_connections c
      ON ( s.session_id = c.session_id )
    LEFT OUTER JOIN sys.dm_exec_requests r
      ON ( s.session_id = r.session_id )
    LEFT OUTER JOIN sys.dm_os_tasks t
      ON ( r.session_id = t.session_id
          AND r.request_id = t.request_id )
    -- Using row_number to SELECT longest wait for each thread AND should be representative of other wait relationships if thread has multiple involvements
    LEFT OUTER JOIN ( SELECT  *, ROW_NUMBER() OVER
                                ( PARTITION BY waiting_task_address ORDER BY wait_duration_ms DESC ) AS row_num
                        FROM  sys.dm_os_waiting_tasks ) w
      ON ( t.task_address = w.waiting_task_address )
      AND w.row_num = 1
    LEFT OUTER JOIN sys.dm_exec_requests r2
      ON ( r.session_id = r2.blocking_session_id )
      OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) AS st
  WHERE s.session_Id > 50               --  Ignore anything pertaining to the system spids.
    AND s.session_id NOT IN (@@SPID)    --  Ignore your own session
    AND s.host_name LIKE 'STG%'
  ORDER BY s.session_id
GO
