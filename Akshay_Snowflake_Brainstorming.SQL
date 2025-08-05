--Filter Queries by Specific Client Tool

SELECT 
    query_id,
    user_name,
    warehouse_name,
    database_name,
    client_application_name,
    query_type,
    start_time,
    total_elapsed_time/1000 AS duration_sec,
    query_text
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
  AND warehouse_name = 'MY_WH'
  AND database_name = 'MY_DB'
  AND LOWER(client_application_name) LIKE '%python%'
ORDER BY start_time DESC;

--Top N Longest Running Queries

SELECT 
    query_text,
    user_name,
    start_time,
    end_time,
    total_elapsed_time/1000 AS duration_sec,
    warehouse_name
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
ORDER BY duration_sec DESC
LIMIT 20;

--Warehouse Usage by Query Type
SELECT 
    warehouse_name,
    query_type,
    COUNT(*) AS num_queries,
    SUM(execution_time)/1000 AS total_exec_time_sec
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
GROUP BY warehouse_name, query_type
ORDER BY total_exec_time_sec DESC;

--Failed Queries Audit
SELECT 
    USER_NAME,
    QUERY_TEXT,
    ERROR_CODE,
    ERROR_MESSAGE,
    START_TIME
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE ERROR_CODE IS NOT NULL
AND START_TIME >= DATEADD(DAY, -14, CURRENT_TIMESTAMP())
ORDER BY START_TIME DESC;

--DDL vs DML Activity Summary
SELECT 
    CASE 
        WHEN query_type IN ('CREATE', 'DROP', 'ALTER') THEN 'DDL'
        ELSE 'DML'
    END AS query_category,
    COUNT(*) AS num_queries
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE start_time >= DATEADD(day, -30, CURRENT_TIMESTAMP())
GROUP BY query_category;

--DDL vs DML Activity Summary (by Database & Warehouse)
SELECT 
    CASE 
        WHEN query_type IN ('CREATE', 'DROP', 'ALTER', 'TRUNCATE') THEN 'DDL'
        WHEN query_type IN ('INSERT', 'UPDATE', 'DELETE', 'MERGE', 'COPY') THEN 'DML'
        ELSE 'OTHER'
    END AS query_category,
    COUNT(*) AS query_count,
    SUM(total_elapsed_time)/1000 AS total_duration_sec
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE start_time >= DATEADD(day, -30, CURRENT_TIMESTAMP())
  AND database_name = 'DATABASE_NAME'       --Change this
  AND warehouse_name = 'WAREHOUSE_NAME'     --Change this
GROUP BY query_category
ORDER BY query_count DESC;

--Users Without MFA Enabled

SELECT 
    name AS user_name,
    disabled,
    has_rsa_public_key,
    has_mfa
FROM SNOWFLAKE.ACCOUNT_USAGE.USERS
WHERE has_mfa = FALSE
  AND disabled = FALSE;


--Unused Roles in Last 90 Days
SELECT 
    r.name AS role_name,
    r.created_on,
    MAX(q.start_time) AS last_used_on
FROM SNOWFLAKE.ACCOUNT_USAGE.ROLES r
LEFT JOIN SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY q 
    ON r.name = q.role_name
    AND q.start_time >= DATEADD(day, -90, CURRENT_TIMESTAMP())
GROUP BY r.name, r.created_on
HAVING MAX(q.start_time) IS NULL;

--Users Created But Never Logged In

SELECT 
    u.name AS user_name,
    u.created_on,
    MAX(l.event_timestamp) AS last_login
FROM SNOWFLAKE.ACCOUNT_USAGE.USERS u
LEFT JOIN SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY l 
    ON u.name = l.user_name
GROUP BY u.name, u.created_on
HAVING MAX(l.event_timestamp) IS NULL;

