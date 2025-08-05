-- DB scripts to find the linked server references from DB objects
-- Two scripts below

-- 1. for 4 parts call references

EXEC sp_MSForEachDB '
USE [?];
SELECT  @@servername                                                          AS  [Host],
        DB_NAME()                                                             AS  [Database Name],
        t.referenced_server_name                                              AS  [Linked Server Name],
        CASE WHEN s.name IS NULL THEN ''Does Not Exist'' ELSE ''Exists'' END  AS  [Linked Server Status],
        ISNULL( s.data_source, '''' )                                         AS  [Remote Server],
        o.name                                                                AS  [Object Name],
        o.type_desc                                                           AS  [Object Type],
        ISNULL( CONVERT( CHAR(10), st.last_execution_time, 23), ''Unknown'' ) AS  [Last Execute Date],
        t.obj                                                                 AS  [Referenced Table]
  FROM  ( SELECT d2.referenced_server_name, d2.referencing_id,
              obj = stuff( (SELECT  '','' + d.referenced_database_name + ''.'' + d.referenced_schema_name + ''.'' + d.referenced_entity_name
                              FROM  sys.sql_expression_dependencies d
                              WHERE d.referencing_id = d2.referencing_id
                                AND d.referenced_server_name = d2.referenced_server_name FOR XML PATH ('''') ), 1, 1,'''' )
            FROM sys.sql_expression_dependencies d2
            WHERE d2.referenced_server_name IS NOT NULL
            GROUP BY d2.referenced_server_name, d2.referencing_id ) t
    INNER JOIN sys.objects o ON t.referencing_id = o.object_id
    LEFT JOIN sys.servers s ON t.referenced_server_name COLLATE DATABASE_DEFAULT = s.name COLLATE DATABASE_DEFAULT
    LEFT JOIN sys.dm_exec_procedure_stats st ON o.object_id = st.object_id
  ORDER BY  DB_NAME(), s.name, o.name';

-- 2. for OPENQUERY references

EXEC sp_MSForEachDB '
USE [?];
SELECT  @@servername          AS  [Host],
        DB_NAME()             AS  [Database Name],
        ''Unknown''           AS  [Linked Server Name],
        ''OPENQUERY''         AS  [Linked Server Status],
        ''Unknown''           AS  [Remote Server],
        o.name                AS  [Object Name],
        o.type_desc           AS  [Object Type],
        ''Unknown''           AS  [Last Execute Date],
        ''OPENQUERY Call''    AS  [Referenced Table]
  FROM  sys.sql_modules m
    JOIN sys.objects o ON m.object_id = o.object_id
  WHERE definition LIKE ''%OPENQUERY%''
  ORDER BY  DB_NAME(), o.name';
