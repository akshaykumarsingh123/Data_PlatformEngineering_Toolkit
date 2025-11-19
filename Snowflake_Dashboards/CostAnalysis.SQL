--Warehouse Cost Analysis

--Monthly Credit Usage by Warehouse
-- Purpose: Tracks credit consumption by warehouse over time to identify high-cost warehouses.
SELECT 
    TO_CHAR(wmh.start_time, 'YYYY-MM') AS month,
    wmh.warehouse_name,
    SUM(wmh.credits_used) AS total_credits
FROM snowflake.account_usage.warehouse_metering_history wmh
WHERE wmh.start_time >= '2025-04-01'
GROUP BY TO_CHAR(wmh.start_time, 'YYYY-MM'), wmh.warehouse_name
ORDER BY month, total_credits;

--Top 10 Expensive queries by User
WITH query_costs AS (
    SELECT 
        qh.query_id,
        qh.user_name,
        qh.warehouse_name,
        qh.total_elapsed_time / 1000 AS execution_time_seconds,
        CASE 
            WHEN qh.warehouse_size = 'X-Small' THEN 1
            WHEN qh.warehouse_size = 'Small' THEN 2
            WHEN qh.warehouse_size = 'Medium' THEN 4
            WHEN qh.warehouse_size = 'Large' THEN 8
            WHEN qh.warehouse_size = 'X-Large' THEN 16
            WHEN qh.warehouse_size = '2X-Large' THEN 32
            WHEN qh.warehouse_size = '3X-Large' THEN 64
            WHEN qh.warehouse_size = '4X-Large' THEN 128
        END AS credits_per_hour,
        (execution_time_seconds / 3600) * credits_per_hour AS estimated_credits
    FROM snowflake.account_usage.query_history qh
    WHERE qh.start_time >= '2025-09-01'
        AND qh.warehouse_size IS NOT NULL
)
SELECT 
    query_id,
    user_name,
    warehouse_name,
    execution_time_seconds,
    estimated_credits
FROM query_costs
ORDER BY estimated_credits DESC
LIMIT 10;

--Daily Credit Usage Trend

--Daily Credit Usage Trend
SELECT 
    TO_DATE(wmh.start_time) AS usage_date,
    SUM(wmh.credits_used) AS total_credits
FROM snowflake.account_usage.warehouse_metering_history wmh
WHERE wmh.start_time >= '2025-08-01'
GROUP BY TO_DATE(wmh.start_time)
ORDER BY usage_date;