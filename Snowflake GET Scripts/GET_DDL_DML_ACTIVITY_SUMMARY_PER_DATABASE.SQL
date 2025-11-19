CREATE OR REPLACE PROCEDURE DBA_ADMIN.DBO.SP_GET_DDL_DML_ACTIVITY_SUMMARY_PER_DATABASE("DBNAME" VARCHAR)
RETURNS TABLE ("QUERY_CATEGORY" VARCHAR, "QUERY_COUNT" NUMBER(38,0), "TOTAL_DURATION_SEC" NUMBER(38,0))
LANGUAGE SQL
EXECUTE AS OWNER
AS '
DECLARE RES RESULTSET;
BEGIN
    RES:=(
        SELECT 
            CASE 
                WHEN query_type IN (''CREATE'', ''DROP'', ''ALTER'', ''TRUNCATE'') THEN ''DDL''
                WHEN query_type IN (''INSERT'', ''UPDATE'', ''DELETE'', ''MERGE'', ''COPY'') THEN ''DML''
                ELSE ''OTHER''
            END AS query_category,
            COUNT(*) AS query_count,
            SUM(total_elapsed_time)/1000 AS total_duration_sec
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE start_time >= DATEADD(day, -30, CURRENT_TIMESTAMP())
          AND database_name = :DBNAME      --Change this
          --AND warehouse_name = ''WAREHOUSE_NAME''     --Change this
        GROUP BY query_category
        ORDER BY query_count DESC
        );
    RETURN TABLE(RES);
END;
';