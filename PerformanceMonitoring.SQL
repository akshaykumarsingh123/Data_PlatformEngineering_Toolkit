-- Query History filtered with the username
select query_text, database_name, query_type, user_name, role_name, warehouse_name,
warehouse_size,start_time, end_time, total_elapsed_time, compilation_time, execution_time,
queued_provisioning_time,transaction_blocked_time, queued_overload_time, execution_status
  from table(information_schema.QUERY_HISTORY_BY_USER(
    USER_NAME => 'SVC_SUNWINGRES_SNOWFLAKE_PROD',
    END_TIME_RANGE_START=>to_timestamp_ltz('2024-09-23 00:00:00.000'),
    END_TIME_RANGE_END=>to_timestamp_ltz('2024-09-24 00:00:00.000')));
    --where query_type = 'CALL';
	
--Query with the RESULT_LIMIT
select query_text, database_name, query_type, user_name, role_name, warehouse_name,
warehouse_size,start_time, end_time, total_elapsed_time, compilation_time, execution_time,
queued_provisioning_time,transaction_blocked_time, queued_overload_time, execution_status
  from table(information_schema.QUERY_HISTORY_BY_USER(
    USER_NAME => 'SVC_SUNWINGRES_SNOWFLAKE_PROD',
    END_TIME_RANGE_START=>to_timestamp_ltz('2024-09-23 00:00:00.000'),
    END_TIME_RANGE_END=>to_timestamp_ltz('2024-09-24 00:00:00.000'),
    RESULT_LIMIT => 10000));

--Retrieving query history using QUERY_HISTORY table function
select *
from table(information_schema.query_history())
order by start_time;

--Below query retrieves the long running queries which ran more than 5 minutes in last 1 hour
select
    query_id,
    query_text,
    user_name,
    warehouse_name,
    start_time,
    end_time,
    datediff(second, start_time, end_time) as run_time_in_seconds
from table(information_schema.query_history())
where datediff(minute, start_time, end_time) > 5
and start_time > dateadd(hour, -1, current_timestamp())
order by start_time;

--query can also written by passing arguments (END_TIME_RANGE_START, END_TIME_RANGE_END)  to the QUERY_HISTORY table function
select
    query_id,
    query_text,
    user_name,
    warehouse_name,
    start_time,
    end_time,
    datediff(second, start_time, end_time) as run_time_in_seconds
from table(information_schema.query_history(
    END_TIME_RANGE_START => dateadd(hour,-1,current_timestamp()),
    END_TIME_RANGE_END => current_timestamp() ))
where datediff(minute, start_time, end_time) > 5
order by start_time;

--Finding long running queries by Warehouse
select
    query_id,
    query_text,
    user_name,
    warehouse_name,
    start_time,
    datediff(second, start_time, current_timestamp) as run_time_in_seconds
from table(information_schema.query_history_by_warehouse(
    END_TIME_RANGE_START => dateadd(hour,-1,current_timestamp()),
    END_TIME_RANGE_END => current_timestamp(),
    WAREHOUSE_NAME => 'COMPUTE_WH'))
--where execution_status='RUNNING'
order by start_time;

--Finding long running queries by User

select
    query_id,
    query_text,
    user_name,
    warehouse_name,
    start_time,
    datediff(second, start_time, current_timestamp) as run_time_in_seconds
from table(information_schema.query_history_by_user(USER_NAME => 'TONY'))
where execution_status='RUNNING'
order by start_time;

--Killing a long running query in Snowflake using SYSTEM$CANCEL_QUERY

select system$cancel_query('<query_id>');