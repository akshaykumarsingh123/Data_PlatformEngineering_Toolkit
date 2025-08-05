--Monitor Job Execution Status

-- View execution status for all jobs
SELECT * FROM jobs.job_executions
WHERE step_id IS NULL
ORDER BY start_time DESC;

-- View specific columns in the execution status
SELECT job_name, step_id, step_name, target_server_name, target_database_name,
       lifecycle, last_message, start_time, end_time, current_attempts
FROM jobs.job_executions
ORDER BY start_time DESC;

-- View execution statuses for a specific job
SELECT * FROM jobs.job_executions
WHERE job_name = 'JobName'
ORDER BY start_time DESC;

-- View all active job executions
SELECT * FROM jobs.job_executions
WHERE is_active = 1
ORDER BY start_time DESC;

-- View step-level execution details for a specific job execution
SELECT * FROM jobs.job_executions
WHERE job_execution_id = 'JobExecutionId';





