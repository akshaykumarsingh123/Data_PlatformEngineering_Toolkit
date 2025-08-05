--  Query details about statistics for all objects within a single database
--  Details on sys.stats system view:
--    https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-stats-transact-sql?view=sql-server-ver15
--  Details on sys.dm_db_stats_properties system procedure:
--    https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-stats-properties-transact-sql?view=sql-server-ver15

SELECT DISTINCT OBJECT_NAME( s.[object_id] )            [TableName],
                s.[object_id]                           [ObjectID],
                c.name                                  [ColumnName],
                sc.column_id                            [ColumnID],
                s.name                                  [StatName],
                sp.unfiltered_rows                      [RowCount],
                sp.rows_sampled                         [SampledRows],
                sp.modification_counter                 [ModificationCounter],
                STATS_DATE( s.[object_id], s.stats_id ) [LastUpdated],
                CASE s.auto_created
                  WHEN 1 THEN 'Yes'
                  ELSE 'No'
                END                                     [AutoCreated],
                CASE s.user_created
                  WHEN 1 THEN 'Yes'
                  ELSE 'No'
                END                                     [UserCreated],
                CASE s.no_recompute
                  WHEN 1 THEN 'Yes'
                  ELSE 'No'
                END                                     [NoRecompute]
  FROM sys.stats s
    CROSS APPLY sys.dm_db_stats_properties( s.object_id, s.stats_id ) AS sp
    JOIN sys.stats_columns sc ON sc.[object_id] = s.[object_id]
      AND sc.stats_id = s.stats_id
    JOIN sys.columns c ON c.[object_id] = sc.[object_id]
      AND c.column_id = sc.column_id
    JOIN sys.partitions par ON par.[object_id] = s.[object_id]
    JOIN sys.objects obj ON par.[object_id] = obj.[object_id]
  WHERE OBJECTPROPERTY( s.object_id, 'IsUserTable' ) = 1
    AND (s.auto_created = 1 OR s.user_created = 1)
  ORDER BY [TableName], [ColumnID];



--  https://www.sqlshack.com/sql-server-statistics-and-how-to-perform-update-statistics-in-sql/

--  Update all statistics in a single database
EXEC sp_updatestats

--  Update all statistics of a single object
UPDATE STATISTICS dbo.DBOOKCOMP

--  Update statistics of a single index
UPDATE STATISTICS [dbo].[DBOOKCOMP] [IX_DBOOKCOMP_BOOKING]
