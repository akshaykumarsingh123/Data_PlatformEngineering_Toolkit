
--Top 50 Long Running Queries

select
  q.query_id,
  q.user_name,
  q.role_name,
  q.warehouse_name,
  q.database_name,
  q.schema_name,
  q.query_text,
  q.execution_status,
  q.start_time,
  q.end_time,
  datediff('second', q.start_time, q.end_time) as elapsed_seconds,
  q.bytes_scanned,
  q.rows_produced
from SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY q
where q.start_time >= dateadd('day', -30, current_timestamp())
  and q.execution_status = 'SUCCESS'
  and datediff('second', q.start_time, q.end_time) >= 60   -- >60s
order by elapsed_seconds desc limit 70;

--Warehouse Metering

with V_CREDIT_PRICING as (
    select 4.0 as usd_per_credit  -- change to your blended rate
),
m as (
    select 
        warehouse_name,
        date_trunc('day', start_time) as day,
        sum(credits_used) as credits
    from SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
    where start_time >= dateadd('day', -30, current_timestamp())
    group by 1,2
)
select 
    m.warehouse_name, 
    m.day, 
    m.credits,
    round(m.credits * p.usd_per_credit, 2) as est_usd
from m
cross join V_CREDIT_PRICING p
order by day desc, warehouse_name;

--Warehouse Avg Running


select
  warehouse_name,
  date_trunc('hour', start_time) as hour,
  avg(avg_running) as avg_running,
  --avg(avg_blocked) as avg_blocked
from SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
where start_time >= dateadd('day', -15, current_timestamp())
group by 1,2
order by hour, warehouse_name;

--Warehouse Avg Running


select
  warehouse_name,
  date_trunc('hour', start_time) as hour,
  avg(avg_running) as avg_running,
  --avg(avg_blocked) as avg_blocked
from SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
where start_time >= dateadd('day', -15, current_timestamp())
group by 1,2
order by hour, warehouse_name;

--Warehouse Avg Queue Load Time

select
  warehouse_name,
  date_trunc('hour', start_time) as hour,
  --avg(avg_running) as avg_running,
  avg(avg_queued_load) as avg_queued_load,              -- queued due to load
  --avg(avg_queued_provisioning) as avg_queued_provision, -- waiting for clusters
  --avg(avg_blocked) as avg_blocked
from SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
where start_time >= dateadd('day', -15, current_timestamp())
group by 1,2
order by hour, warehouse_name;

--Warehouse Avg Provisioning Time


select
  warehouse_name,
  date_trunc('hour', start_time) as hour,
  avg(avg_queued_provisioning) as avg_queued_provision, -- waiting for clusters
  --avg(avg_blocked) as avg_blocked
from SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
where start_time >= dateadd('day', -15, current_timestamp())
group by 1,2
order by hour, warehouse_name;

