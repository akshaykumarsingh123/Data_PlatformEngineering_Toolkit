--  Source material
--    https://www.brentozar.com/archive/2013/09/index-maintenance-sql-server-rebuild-reorganize/
--    https://www.sqlskills.com/blogs/paul/sqlskills-sql101-rebuild-vs-reorganize/
--    https://solutioncenter.apexsql.com/why-when-and-how-to-rebuild-and-reorganize-sql-server-indexes/
--    https://docs.microsoft.com/en-us/sql/relational-databases/indexes/guidelines-for-online-index-operations?view=sql-server-2017
--    https://docs.microsoft.com/en-us/sql/relational-databases/indexes/reorganize-and-rebuild-indexes?view=sql-server-2017
/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
--  Find indexes where the fragmentation is greater than 10% for a single database
/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
SELECT  D.name                            AS  "Database",
        T.name                            AS  "Table Name",
        I.name                            AS  "Index Name",
        IP.object_id                      AS  "Object ID",
        IP.index_id                       AS  "Index ID",
        IP.avg_fragmentation_in_percent   AS "% Fragmentation"
  FROM  master..sysdatabases D,
        sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS IP
    INNER JOIN sys.indexes AS I ON IP.object_id = I.object_id
      AND IP.index_id = I.index_id
    INNER JOIN sys.tables AS T ON T.object_id = IP.object_id
  WHERE IP.database_id = DB_ID()
    AND D.dbid = IP.database_id
    AND IP.index_id != 0
    AND IP.avg_fragmentation_in_percent > 10
    AND index_type_desc != 'HEAP'
    AND page_count > 1000
  ORDER BY T.name, IP.avg_fragmentation_in_percent DESC;
GO

/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
--  If avg_fragmentation_in_percent is > 15 AND < 30 then a Reorganize Index is required (ALTER INDEX REORGANIZE ...)
--  If avg_fragmentation_in_percent is > 30 then a Rebuild Index is required (ALTER INDEX REBUILD ...)
/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
--  Find indexes where the fragmentation is greater than 10% for all databases
/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
EXEC sp_MSforeachdb '
USE [?];
SELECT  D.name                            AS  "Database",
        T.name                            AS  "Table Name",
        I.name                            AS  "Index Name",
        IP.object_id                      AS  "Object ID",
        IP.index_id                       AS  "Index ID",
        IP.avg_fragmentation_in_percent   AS "% Fragmentation"
  FROM  master..sysdatabases D,
        sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS IP
    INNER JOIN sys.indexes AS I ON IP.object_id = I.object_id
      AND IP.index_id = I.index_id
    INNER JOIN sys.tables AS T ON T.object_id = IP.object_id
  WHERE IP.database_id = DB_ID()
    --  Ignore DBA/System databases
    AND D.name NOT IN
      ( ''DBA_Admin'',''DISTRIBUTION'',''MASTER'',''MODEL'', ''MSDB'',''SSISDB'',''TEMPDB'' )
    AND D.dbid = IP.database_id
    AND IP.index_id != 0
    AND IP.avg_fragmentation_in_percent > 10
    AND index_type_desc != ''HEAP''
    AND page_count > 1000
  ORDER BY T.name, IP.avg_fragmentation_in_percent DESC';
GO