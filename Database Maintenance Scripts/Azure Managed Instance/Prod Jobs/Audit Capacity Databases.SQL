USE [msdb]
GO

/****** Object:  Job [Audit Capacity - Databases]    Script Date: 4/16/2025 11:18:11 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 4/16/2025 11:18:11 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Audit Capacity - Databases', 
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
/****** Object:  Step [Create Working Tables]    Script Date: 4/16/2025 11:18:11 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Create Working Tables', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--  Step 1: Create Working Tables
CREATE TABLE DBA_Admin.dbo.temp_DatabaseAccess
( Database_Name         SYSNAME,
  Table_Name            SYSNAME       NULL,
  Table_Desccription    NVARCHAR(50)  NULL  );

CREATE TABLE DBA_Admin.dbo.temp_DatabaseTableCount
( Database_Name         SYSNAME,
  Table_Count           SYSNAME       NULL );

CREATE TABLE DBA_Admin.dbo.temp_DatabaseSizes
( Database_Name         SYSNAME,
  Space_Allocated       MONEY         NULL,
  Space_Free            MONEY         NULL,
  Space_Used            MONEY         NULL );', 
		@database_name=N'DBA_Admin', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Populate Audit Table]    Script Date: 4/16/2025 11:18:11 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Populate Audit Table', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--  Step 2: Populate Audit Table
INSERT INTO DBA_Admin.dbo.temp_DatabaseAccess ( Database_Name )
  SELECT  name FROM sys.sysdatabases
    WHERE name NOT IN   --  Ignore DBA/System databases
      ( ''DISTRIBUTION'',''MASTER'',''MODEL'',''MSDB'',''SSISDB'',
        ''TEMPDB'',''ReportServer'',''ReportServerTempDB'' )

EXEC sp_MSforeachdb ''
INSERT INTO DBA_Admin.dbo.temp_DatabaseAccess
  SELECT  DISTINCT DB_NAME(s.database_id), o.name [table_name], o.type_desc
    FROM  [?].sys.dm_db_index_usage_stats s
    JOIN  [?].sys.objects o
      ON  s.object_id = o.object_id
    WHERE s.database_id = DB_ID(''''?'''')
      AND DB_NAME(s.database_id) NOT IN    --  Ignore DBA/System databases
          ( ''''DISTRIBUTION'''',''''MASTER'''',''''MODEL'''',''''MSDB'''',
            ''''TEMPDB'''',''''ReportServer'''',''''ReportServerTempDB'''' )
    ORDER BY  o.name'';

EXEC sp_MSforeachdb ''
USE [?]
INSERT INTO DBA_Admin.dbo.temp_DatabaseTableCount
SELECT  DB_NAME(),
        COUNT(name)
  FROM  sys.objects
  WHERE type = ''''U'''''';

EXEC sp_MSforeachdb ''
USE [?]
INSERT INTO DBA_Admin.dbo.temp_DatabaseSizes
  SELECT  DB_NAME(),
          SUM(size/128.0),
          SUM(size/128.0 - CAST(FILEPROPERTY(name, ''''SpaceUsed'''') AS MONEY)/128.0),
          NULL
  FROM sys.database_files'';

UPDATE DBA_Admin.dbo.temp_DatabaseSizes
  SET Space_Used = Space_Allocated - Space_Free

--  Full User Database List with Last Access Times and Sizes
INSERT INTO [DBA_ADMIN].[dbo].[Audit_Capacity_Databases]
  ( [DatabaseName], [TableCount], [DataSize], [LogSize], [AllocatedMB], [UtilizedMB] )
SELECT  DA.Database_Name                        [Database_Name],
        DTC.Table_Count                         [Table_Count],
        (CAST(MFROWS.RowSize AS MONEY)*8)/1024  [Data_MB],
        (CAST(MFLOG.LogSize AS MONEY)*8)/1024   [Logs_MB],
        ROUND(DS.Space_Allocated, 2)            [Allocated_MB],
        ROUND(DS.Space_Used, 2)                 [Utilized_MB]
  FROM  DBA_Admin.dbo.temp_DatabaseAccess DA,
        DBA_Admin.dbo.temp_DatabaseTableCount DTC,
        DBA_Admin.dbo.temp_DatabaseSizes DS,
        sys.databases DB
  LEFT JOIN ( SELECT  database_id, SUM(size) RowSize
                FROM  sys.master_files
                WHERE type = 0
                GROUP BY database_id, type) MFROWS ON MFROWS.database_id = DB.database_id
  LEFT JOIN ( SELECT  database_id, SUM(size) LogSize
                FROM  sys.master_files
                WHERE type = 1
                GROUP BY database_id, type) MFLOG ON MFLOG.database_id = DB.database_id
  WHERE DB_NAME(DB.database_id) = DA.Database_Name
    AND DA.Database_Name = DTC.Database_Name
    AND DA.Database_Name = DS.Database_Name
  GROUP BY  DA.Database_Name, DTC.Table_Count, MFROWS.RowSize, MFLOG.LogSize,
            DS.Space_Allocated, DS.Space_Used
  ORDER BY  DA.Database_Name;', 
		@database_name=N'DBA_Admin', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Drop Working Tables]    Script Date: 4/16/2025 11:18:11 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Drop Working Tables', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--  Step 3: Drop Working Tables
DROP TABLE DBA_Admin.dbo.temp_DatabaseAccess;
DROP TABLE DBA_Admin.dbo.temp_DatabaseTableCount;
DROP TABLE DBA_Admin.dbo.temp_DatabaseSizes;', 
		@database_name=N'DBA_Admin', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Run Audit Databases Job', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20220301, 
		@active_end_date=99991231, 
		@active_start_time=235500, 
		@active_end_time=235959, 
		@schedule_uid=N'2f97b820-f81c-4c1d-8df9-8b8535714a25'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


