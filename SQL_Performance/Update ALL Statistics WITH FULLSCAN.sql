/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
--  Update ALL Statistics WITH FULLSCAN
--  ONLY GENERATES COMMANDS DOES NOT EXECUTE
--  This will update all the statistics on all the tables in your database
/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
SET NOCOUNT ON
GO

USE

DECLARE updatestats CURSOR
  FOR
    SELECT  table_schema,
            table_name
      FROM INFORMATION_SCHEMA.tables
      WHERE TABLE_TYPE = 'BASE TABLE'
      ORDER BY table_name;

OPEN updatestats

DECLARE @tableSchema NVARCHAR(128)
DECLARE @tableName NVARCHAR(128)
DECLARE @Statement NVARCHAR(300)
FETCH NEXT FROM updatestats INTO @tableSchema, @tableName

WHILE (@@fetch_status = 0)
  BEGIN
    SET @Statement = 'UPDATE STATISTICS ' + '[' + @tableSchema + ']' + '.' + '[' + @tableName + ']' + ' WITH FULLSCAN'
    PRINT @Statement  --  Comment this print statement to prevent it from printing whenever you are ready to execute the command below.
    --  Please do not remove comment in next line unless that you are really sure that you want to run all commands but will cause extra workload to your server
    --  EXEC sp_executesql @Statement
    FETCH NEXT FROM updatestats INTO @tableSchema, @tableName
  END

CLOSE updatestats
DEALLOCATE updatestats
GO

SET NOCOUNT OFF
GO
--  end of script

/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
--  To follow the active progress on the database run the following command:
/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
SELECT  DB_NAME(r.database_id)                                                      AS  [Database Name],
        r.session_id                                                                AS  [Session ID],
        r.command                                                                   AS  [SQL Command],
        r.status                                                                    AS  [Status],
        CONVERT(NUMERIC(6,2),r.percent_complete)                                    AS  [Percent Complete],
        CONVERT(VARCHAR(20),DATEADD(ms,r.estimated_completion_time,GETDATE()),20)   AS  [ETA Completion Time],
        CONVERT(NUMERIC(10,2),r.total_elapsed_time/1000.0/60.0)                     AS  [Elapsed Minutes],
        CONVERT(NUMERIC(10,2),r.estimated_completion_time/1000.0/60.0)              AS  [ETA Minutes],
        CONVERT(NUMERIC(10,2),r.estimated_completion_time/1000.0/60.0/60.0)         AS  [ETA Hours],
        CONVERT(VARCHAR(1000),
          ( SELECT  SUBSTRING(text,r.statement_start_offset/2,
                  CASE WHEN r.statement_end_offset = -1
                    THEN 1000
                    ELSE (r.statement_end_offset-r.statement_start_offset)/2
                  END )
              FROM sys.dm_exec_sql_text(sql_handle)))                               AS [SQL Command]
  FROM sys.dm_exec_requests r
  WHERE command IN ('UPDATE STATISTICS');
GO
