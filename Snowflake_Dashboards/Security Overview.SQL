--Security Overview

--Failed Login Attempts
/*select
  event_timestamp,
  user_name,
  client_ip,
  reported_client_type,
  error_message,
  Count(*) as failed_attempts
from SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
where event_timestamp >= dateadd('day', -30, current_timestamp())
  and (is_success = 'NO' and is_success = false or error_message is not null)
  group by user_name
order by event_timestamp desc;*/

select
  date_trunc('day', event_timestamp) as login_date,
  user_name,
  count(*) as failed_attempts
from SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
where event_timestamp >= dateadd('day', -30, current_timestamp())
  and (is_success = 'NO' and is_success = false or error_message is not null)
group by login_date, user_name
order by login_date desc;

--Query Failure Error Messages

with top_errors as (
  select error_message
  from SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
  where start_time >= dateadd('day', -30, current_timestamp())
    and error_code is not null
  group by error_message
  order by count(*) desc
  limit 10
)
select
  date_trunc('hour', start_time) as hour,
  qh.error_message,
  count(*) as error_count
from SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY qh
join top_errors te on qh.error_message = te.error_message
where start_time >= dateadd('day', -30, current_timestamp())
  and error_code is not null
group by 1, 2
order by hour desc;

--AAD Security Groups (No Roles Assigned)

Select distinct
    name as Role_Name
from
    SNOWFLAKE.ACCOUNT_USAGE.ROLES
where
    Role_Name not in (
        Select
            distinct(grantee_name)
        from
            SNOWFLAKE.ACCOUNT_USAGE.GRANTS_TO_ROLES
        where deleted_on is null
    )
    and Role_name in (
        Select
            Distinct(Name)
        from
            snowflake.account_usage.roles
        where
            deleted_on is null
    ) and  role_name like '%SNOWFLAKE_%';
	
	--FR to DDL Assignment Matrix
	
	SELECT 
    grantee_name AS functional_role,
    name AS access_role
FROM SNOWFLAKE.ACCOUNT_USAGE.GRANTS_TO_ROLES
WHERE GRANTED_TO = 'ROLE'
    AND GRANTED_ON = 'ROLE'
    AND grantee_name LIKE 'FR%'
    AND name LIKE 'AR_%_DDL'
    AND DELETED_ON IS NULL
ORDER BY functional_role, access_role;


--TOTAL SIGN-IN ERROR BY ERROR TYPE
set daterange = '2025-02-10';

select
    user_name,
    event_timestamp,
    error_message
from SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
where is_success = 'NO'
  and TO_VARCHAR(EVENT_TIMESTAMP,'yyyy-mm-dd') = $daterange;
  
  --Inactive Role by Query Execution
  
  select
    count(query_id) Number_of_Queries,
    role_name
from
    "SNOWFLAKE"."ACCOUNT_USAGE"."QUERY_HISTORY"
where
    ROLE_NAME in (
        Select
            Distinct(Name)
        from
            snowflake.account_usage.roles
        where
            deleted_on is null
    )
    and start_time = :daterange
group by
    role_name; 






