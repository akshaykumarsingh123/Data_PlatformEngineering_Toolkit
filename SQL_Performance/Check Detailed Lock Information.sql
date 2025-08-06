--  https://docs.microsoft.com/en-us/sql/relational-databases/system-compatibility-views/sys-syslockinfo-transact-sql?view=sql-server-ver15

SELECT  DB_NAME( LOCK.rsc_dbid )            AS  'DATABASE_NAME',
        CASE LOCK.rsc_type
          WHEN 1 THEN 'NULL'
          WHEN 2 THEN 'DATABASE'
          WHEN 3 THEN 'FILE'
          WHEN 4 THEN 'INDEX'
          WHEN 5 THEN 'TABLE'
          WHEN 6 THEN 'PAGE'
          WHEN 7 THEN 'KEY'
          WHEN 8 THEN 'EXTEND'
          WHEN 9 THEN 'RID ( ROW ID)'
          WHEN 10 THEN 'APPLICATION'
        END                                 AS  'REQUEST_TYPE',
        CASE LOCK.req_ownertype
          WHEN 1 THEN 'TRANSACTION'
          WHEN 2 THEN 'CURSOR'
          WHEN 3 THEN 'SESSION'
          WHEN 4 THEN 'ExSESSION'
        END                                 AS  'REQUEST_OWNERTYPE',
        CASE LOCK.req_mode
          WHEN 0 THEN 'NULL'
          WHEN 1 THEN 'Sch-S'
          WHEN 2 THEN 'Sch-M'
          WHEN 3 THEN 'S'
          WHEN 4 THEN 'U'
          WHEN 5 THEN 'X'
          WHEN 6 THEN 'IS'
          WHEN 7 THEN 'IU'
          WHEN 8 THEN 'IX'
          WHEN 9 THEN 'SIU'
          WHEN 10 THEN 'SIX'
          WHEN 11 THEN 'UIX'
          WHEN 12 THEN 'BU'
          WHEN 13 THEN 'RangeS_S'
          WHEN 14 THEN 'RangeS_U'
          WHEN 15 THEN 'RangeI_N'
          WHEN 16 THEN 'RangeI_S'
          WHEN 17 THEN 'RangeI_U'
          WHEN 18 THEN 'RangeI_X'
          WHEN 19 THEN 'RangeX_S'
          WHEN 20 THEN 'RangeX_U'
          WHEN 21 THEN 'RangeX_X'
        END                                 AS  'LOCK_TYPE',
        OBJECT_NAME( LOCK.rsc_objid, LOCK.rsc_dbid )  AS  'OBJECT_NAME',
        PROCESS.HOSTNAME,
        PROCESS.program_name,
        PROCESS.nt_domain,
        PROCESS.nt_username,
        PROCESS.program_name,
        SQLTEXT.text
  FROM  sys.syslockinfo LOCK
    JOIN sys.sysprocesses PROCESS ON LOCK.req_spid = PROCESS.spid
    CROSS APPLY sys.dm_exec_sql_text( PROCESS.sql_handle ) SQLTEXT
GO