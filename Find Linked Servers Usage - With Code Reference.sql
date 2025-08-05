SELECT  @@SERVERNAME                                    AS  "Server (Host)",
        DB_NAME()                                       AS  "Database",
        s.name                                          AS  "Linked Server",
        s.data_source                                   AS  "Remote Server",
        o.name                                          AS  "Object",
        o.type_desc                                     AS  "Object Type",
        CONVERT( CHAR(10), st.last_execution_time, 23 ) AS  "Last Execute Date",
        t.obj                                           AS  "Remote Referencing Table"
  FROM  ( SELECT d2.referenced_server_name,
                 d2.referencing_id,
                 obj = STUFF( (
                   SELECT ',' + d.referenced_database_name + '.' + d.referenced_schema_name + '.' + d.referenced_entity_name
                     FROM sys.sql_expression_dependencies d
                     WHERE d.referencing_id = d2.referencing_id
                       AND d.referenced_server_name = d2.referenced_server_name
                     FOR XML PATH ('')
                 ), 1, 1, '' )
            FROM sys.sql_expression_dependencies d2
            WHERE d2.referenced_server_name IS NOT NULL
            GROUP BY d2.referenced_server_name, d2.referencing_id ) t
    INNER JOIN sys.objects o ON t.referencing_id = o.object_id
    INNER JOIN sys.servers s ON t.referenced_server_name COLLATE database_default = s.name COLLATE database_default
    LEFT JOIN sys.dm_exec_procedure_stats st ON o.object_id = st.object_id
  ORDER BY s.name, o.name;
GO
