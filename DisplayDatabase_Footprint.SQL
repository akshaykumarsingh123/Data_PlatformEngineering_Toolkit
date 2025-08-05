/* ----------------------------------------------------------------------------------------------------------------- */
--  Find SQL Server start time
/* ----------------------------------------------------------------------------------------------------------------- */
SELECT  sqlserver_start_time
  FROM  sys.dm_os_sys_info;

/* --------------------------------------------------------------------------------------------------------------------------- */
--  The following give the database details, such as last updates, table counts, file sizes, compatibility, collation
/* --------------------------------------------------------------------------------------------------------------------------- */
CREATE TABLE #DatabaseAccess
( Database_Name         SYSNAME,
  Table_Name            SYSNAME       NULL,
  Table_Desccription    NVARCHAR(50)  NULL,
  Last_User_Update      DATETIME      NULL,
  #_Updates             BIGINT        NULL,
  Last_User_Seek        DATETIME      NULL,
  #_Seeks               BIGINT        NULL,
  Last_User_Scan        DATETIME      NULL,
  #_Scans               BIGINT        NULL,
  Last_User_Lookup      DATETIME      NULL,
  #_Lookups             BIGINT        NULL,
  Create_Date           DATETIME      NULL,
  Modify_Date           DATETIME      NULL  );
INSERT INTO #DatabaseAccess ( Database_Name )
  SELECT  name FROM sys.sysdatabases
    WHERE name NOT IN   --  Ignore DBA/System databases
      ( 'distribution','master','model','msdb','SSISDB',
        'tempdb','ReportServer','ReportServerTempDB' )
EXEC sp_MSforeachdb '
INSERT INTO #DatabaseAccess
  SELECT  DISTINCT DB_NAME(s.database_id), o.name [table_name], o.type_desc,
          s.last_user_update, s.user_updates, s.last_user_seek, s.user_seeks,
          s.last_user_scan, s.user_scans, s.last_user_lookup, s.user_lookups,
          o.create_date, o.modify_date
    FROM  [?].sys.dm_db_index_usage_stats s
    JOIN  [?].sys.objects o
      ON  s.object_id = o.object_id
    WHERE s.database_id = DB_ID(''?'')
      AND DB_NAME(s.database_id) NOT IN    --  Ignore DBA/System databases
          ( ''distribution'',''master'',''model'',''msdb'',''SSISDB'',
            ''tempdb'',''ReportServer'',''ReportServerTempDB'' )
    ORDER BY  o.name, s.last_user_update DESC';

CREATE TABLE #DatabaseTableCount
( Database_Name         SYSNAME,
  Table_Count           SYSNAME       NULL );
EXEC sp_MSforeachdb '
USE [?]
INSERT INTO #DatabaseTableCount
SELECT  DB_NAME(),
        COUNT(name)
  FROM  sys.objects
  WHERE type = ''U''';

CREATE TABLE #DatabaseSizes
( Database_Name         SYSNAME,
  Space_Allocated       MONEY         NULL,
  Space_Free            MONEY         NULL,
  Space_Used            MONEY         NULL );
EXEC sp_MSforeachdb '
USE [?]
INSERT INTO #DatabaseSizes
  SELECT  DB_NAME(),
          SUM(size/128.0),
          SUM(size/128.0 - CAST(FILEPROPERTY(name, ''SpaceUsed'') AS MONEY)/128.0),
          NULL
  FROM sys.database_files';

UPDATE #DatabaseSizes
  SET Space_Used = Space_Allocated - Space_Free

--  Full User Database List with Last Access Times and Sizes
SELECT  DAF.Database_Name                       [Database Name],
        MAX(DAF.Last_User_Update)               [Last User Update],
        MAX(DAF.Last_User_Seek)                 [Last User Seek],
        MAX(DAF.Last_User_Scan)                 [Last User Scan],
        MAX(DAF.Last_User_Lookup)               [Last User Lookup],
        DTC.Table_Count                         [Table Count],
        (CAST(MFROWS.RowSize AS MONEY)*8)/1024  [Data MB],
        (CAST(MFLOG.LogSize AS MONEY)*8)/1024   [Logs MB],
        ROUND(DS.Space_Allocated,2)             [Allocated MB],
        ROUND(DS.Space_Used, 2)                 [Utilized MB],
        DB.collation_name                       [Collation],
        CASE DB.compatibility_level
          WHEN 80  THEN 'SQL Server 2000'
          WHEN 90  THEN 'SQL Server 2005'
          WHEN 100 THEN 'SQL Server 2008/R2'
          WHEN 110 THEN 'SQL Server 2012'
          WHEN 120 THEN 'SQL Server 2014'
          WHEN 130 THEN 'SQL Server 2016'
          WHEN 140 THEN 'SQL Server 2017'
          WHEN 150 THEN 'SQL Server 2019'
          WHEN 160 THEN 'SQL Server 2022'
        END                                     [Compatibility]
  FROM  #DatabaseAccess DAF,
        #DatabaseTableCount DTC,
        #DatabaseSizes DS,
        sys.databases DB
  LEFT JOIN ( SELECT  database_id, SUM(size) RowSize
                FROM  sys.master_files
                WHERE type = 0
                GROUP BY database_id, type) MFROWS ON MFROWS.database_id = DB.database_id
  LEFT JOIN ( SELECT  database_id, SUM(size) LogSize
                FROM  sys.master_files
                WHERE type = 1
                GROUP BY database_id, type) MFLOG ON MFLOG.database_id = DB.database_id
  WHERE DB_NAME(DB.database_id) = DAF.Database_Name
    AND DAF.Database_Name = DTC.Database_Name
    AND DAF.Database_Name = DS.Database_Name
  GROUP BY  DAF.Database_Name, DTC.Table_Count, MFROWS.RowSize, MFLOG.LogSize,
            DS.Space_Allocated, DS.Space_Used, DB.collation_name, DB.compatibility_level
  ORDER BY  DAF.Database_Name;

DROP TABLE #DatabaseAccess;
DROP TABLE #DatabaseTableCount;
DROP TABLE #DatabaseSizes;
GO
