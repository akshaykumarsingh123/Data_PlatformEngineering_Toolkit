--  Pythian - Selective Index Maintenance - Analysis

sp_msforeachdb 'USE [?]
DECLARE @objectid INT,
        @indexid  INT;
DECLARE @schemaname NVARCHAR(130),
        @objectname NVARCHAR(130),
        @indexname  NVARCHAR(130);
DECLARE @frag       FLOAT,
        @page_count FLOAT;
DECLARE @command NVARCHAR(4000);
DECLARE @dbid INT;

SET @dbid = DB_ID();

SELECT  [object_id],
        index_id,
        avg_fragmentation_in_percent AS frag,
        page_count
  INTO  #work_to_do
  FROM  sys.dm_db_index_physical_stats (@dbid, NULL, NULL , NULL, N''LIMITED'')
  WHERE avg_fragmentation_in_percent > 5.0
  AND index_id > 0 AND page_count > 1000

DECLARE partitions
  CURSOR FOR
    SELECT  object_id,
            index_id,
            frag,
            page_count
      FROM  #work_to_do;

OPEN partitions;

WHILE (1=1)
  BEGIN
  FETCH NEXT
  FROM partitions
  INTO @objectid, @indexid, @frag, @page_count;
  IF @@FETCH_STATUS < 0 BREAK;

  SELECT  @objectname = QUOTENAME( o.name ),
          @schemaname = QUOTENAME( s.name )
    FROM  sys.objects AS o
    JOIN  sys.schemas AS s
      ON  s.schema_id = o.schema_id
    WHERE o.object_id = @objectid;

  SELECT  @indexname = QUOTENAME(name)
    FROM  sys.indexes
    WHERE object_id = @objectid AND index_id = @indexid;

  IF @frag < 15
    SET @command = N''ALTER INDEX '' + @indexname + N'' ON ['' + DB_NAME() + ''].'' + @schemaname + N''.'' + @objectname + N'' REORGANIZE WITH ( LOB_COMPACTION = ON )'';
  ELSE
    SET @command = N''ALTER INDEX '' + @indexname + N'' ON ['' + DB_NAME() + ''].'' + @schemaname + N''.'' + @objectname + N'' REBUILD'';

  INSERT INTO AVAIL.dbo.WORK_TO_DO
      ( DB,
        SIZE,
        FRAG,
        CMD,
        CREATE_DATE )
    VALUES
        ( DB_NAME(),
          CAST( (@page_count * 8) / 1024 AS NVARCHAR ),
          @frag,
          @command,
          GETDATE() )

END

CLOSE partitions;
DEALLOCATE partitions;
DROP TABLE #work_to_do'


--- Pythian - Selective Index Maintenance - Execution
SET QUOTED_IDENTIFIER ON

DECLARE @CMD VARCHAR(5000)
DECLARE @ID SMALLINT
DECLARE @db VARCHAR(100)
DECLARE @log_used FLOAT
DECLARE @data_ini DATETIME

SELECT TOP 1 @ID = id,
             @db = db,
             @CMD = cmd
  FROM  avail..work_to_do
  WHERE total_time IS NULL
    AND error IS NULL
  ORDER BY priority, id

IF LEFT( @CMD, 11 ) <> 'ALTER INDEX'
BEGIN
  DELETE avail..work_to_do
    WHERE id = @ID
  RETURN
END

CREATE TABLE #perf
  ( dbname   VARCHAR(100),
    log_size FLOAT,
    log_used FLOAT,
    status   INT )

INSERT INTO #perf EXEC ('dbcc sqlperf(logspace)')
SELECT  @log_used = log_used
  FROM  #perf
  WHERE dbname = @db

IF @log_used > 80
BEGIN
  DROP TABLE #perf
  UPDATE  avail..work_to_do
    SET   priority = priority + 1
    WHERE id = @ID
  PRINT 'Database ' + @db + ' is using ' + CONVERT( VARCHAR, @log_used ) + ' of log space, process delayed'
  RETURN
END

SET @data_ini = getdate()

BEGIN TRY

  EXEC (@CMD)
  UPDATE  avail..work_to_do
    SET   process_date = @data_ini,
          total_time = DATEDIFF( n, @data_ini, getdate() )
    WHERE id = @ID

END TRY

BEGIN CATCH

  DECLARE @ErrMsg      NVARCHAR(4000),
          @ErrSeverity INT
  SELECT  @ErrMsg = ERROR_MESSAGE(),
          @ErrSeverity = ERROR_SEVERITY()
  UPDATE  avail..work_to_do
    SET   process_date = @data_ini,
          total_time = DATEDIFF( n, @data_ini, getdate() ),
          error = @ErrMsg
    WHERE id = @ID

END CATCH

DROP TABLE #perf