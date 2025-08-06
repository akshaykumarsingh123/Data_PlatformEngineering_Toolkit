/*===================================================================================================================*/
--    https://www.mssqltips.com/sqlservertip/2393/determine-sql-server-memory-use-by-database-and-object/
/*===================================================================================================================*/
--  Querying sys.dm_os_buffer_descriptors requires the VIEW_SERVER_STATE permission
DECLARE @total_buffer INT;
SELECT  @total_buffer = cntr_value
  FROM  sys.dm_os_performance_counters
  WHERE RTRIM([object_name]) LIKE '%Buffer Manager'
    AND counter_name = 'Database Pages';
WITH src AS
  ( SELECT  database_id, db_buffer_pages = COUNT_BIG(*)
      FROM  sys.dm_os_buffer_descriptors
      GROUP BY database_id )
  SELECT  CASE [database_id]
            WHEN 32767 THEN 'Resource DB'
            ELSE DB_NAME([database_id])
          END                                         [DB Name],
          db_buffer_pages                             [Buffer Pages],
          db_buffer_pages / 128                       [Buffer (MB)],
          CONVERT(DECIMAL(6,3),
            db_buffer_pages * 100.0 / @total_buffer)  [Buffer %]
    FROM  src
    ORDER BY db_buffer_pages DESC;
GO

/*===================================================================================================================*/
--  https://www.mssqltips.com/sqlservertip/2979/querying-sql-server-index-statistics/
USE DBPCVDAT;
GO
EXEC sp_updatestats;

/*===================================================================================================================*/
--  Querying sys.dm_os_buffer_descriptors requires the VIEW_SERVER_STATE permission
--  Utilize a set of catalog views to determine the number of pages (amount of memory) dedicated to each object
--  This must be execute in the database you are reviewing
--  Drill down into memory used by objects in database of your choice
WITH src AS
  ( SELECT  [Object] = o.name,
            [Type] = o.type_desc,
            [Index] = COALESCE(i.name, ''),
            [Index Type] = i.type_desc,
            p.[object_id],
            p.index_id,
            au.allocation_unit_id
      FROM  sys.partitions AS p
      INNER JOIN sys.allocation_units AS au
        ON  p.hobt_id = au.container_id
      INNER JOIN sys.objects AS o
        ON  p.[object_id] = o.[object_id]
      INNER JOIN sys.indexes AS i
        ON  o.[object_id] = i.[object_id]
        AND p.index_id = i.index_id
      WHERE au.[type] IN (1,2,3)
        AND o.is_ms_shipped = 0 )
  SELECT  src.[Object],
          src.[Type],
          src.[Index],
          src.[Index_Type],
          COUNT_BIG(b.page_id)        AS  [Buffer Pages],
          COUNT_BIG(b.page_id) / 128  AS  [Buffer (MB)]
    FROM  src
    INNER JOIN sys.dm_os_buffer_descriptors AS b
      ON  src.allocation_unit_id = b.allocation_unit_id
    WHERE b.database_id = DB_ID()
    GROUP BY  src.[Object], src.[Type], src.[Index], src.[Index_Type]
    ORDER BY  buffer_pages DESC;
GO

/*===================================================================================================================*/
--  https://www.sqlservergeeks.com/category/one-dmv-a-day/
--  https://www.sqlservergeeks.com/category/one-dmv-a-day/page/8/
--  Returns the set of all memory clerks that are currently active in the instance of SQL Server
--  https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-os-memory-clerks-transact-sql?view=sql-server-ver15
SELECT  *
  FROM  sys.dm_os_memory_clerks
  ORDER BY (single_pages_kb + multi_pages_kb + awe_allocated_kb) DESC
GO

/*===================================================================================================================*/
--  Top Cached Stored Procedures by Total Logical Reads - Logical reads relate to memory pressure
--  This helps you find the most expensive cached stored procedures from a memory perspective
--  You should look at this if you see signs of memory pressure
SELECT  TOP(25) p.name AS [SP Name],
        qs.total_logical_reads AS [Total Logical Reads],
        qs.total_logical_reads/qs.execution_count AS [Avg Logical Reads],
        qs.execution_count AS [Execution Count],
        ISNULL(qs.execution_count/DATEDIFF(Second, qs.cached_time, GETDATE()), 0) AS [Calls/Second],
        qs.total_elapsed_time AS [Total Elapsed Time],
        qs.total_elapsed_time/qs.execution_count AS [Avg Elapsed Time],
        qs.cached_time AS [Cached Time]
  FROM  sys.procedures AS p
  INNER JOIN sys.dm_exec_procedure_stats AS qs
    ON  p.[object_id] = qs.[object_id]
  WHERE qs.database_id = DB_ID()
  ORDER BY qs.total_logical_reads DESC;
GO

/*===================================================================================================================*/
DECLARE @FileName VARCHAR(MAX)

SELECT @FileName = SUBSTRING(path, 0,
   LEN(path)-CHARINDEX('\', REVERSE(path))+1) + '\Log.trc'
FROM sys.traces
WHERE is_default = 1;

SELECT  o.name,
        o.OBJECT_ID,
        o.create_date,
        gt.NTUserName,
        gt.HostName,
        gt.SPID,
        gt.DatabaseName,
        gt.TEXTData
FROM sys.fn_trace_gettable( @FileName, DEFAULT ) AS gt
JOIN tempdb.sys.objects AS o
     ON gt.ObjectID = o.OBJECT_ID
WHERE gt.DatabaseID = 2
  AND gt.EventClass = 46 -- (Object:Created Event from sys.trace_events)
  AND o.create_date >= DATEADD(ms, -100, gt.StartTime)
  AND o.create_date <= DATEADD(ms, 100, gt.StartTime)
