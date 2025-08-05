-- Add a new job step with custom retry and timeout settings
EXEC jobs.sp_add_jobstep
    @job_name = N'YourJobName',
    @step_name = N'YourStepName',
    @command = N'Your T-SQL Command Here',
    @target_group_name = N'YourTargetGroup',
    @initial_retry_interval_seconds = 10,           -- Initial Retry Interval (seconds)
    @maximum_retry_interval_seconds = 120,          -- Maximum Retry Interval (seconds)
    @retry_attempts = 5,                            -- Number of Retry Attempts
    @retry_interval_backoff_multiplier = 2.0,       -- Retry Interval Backoff Multiplier
    @step_timeout_seconds = 3600;                   -- Timeout (seconds)


-- Update an existing job step with custom retry and timeout settings
EXEC jobs.sp_update_jobstep
    @job_name = N'YourJobName',
    @step_id = 1,                                   -- Replace with your step ID
    @initial_retry_interval_seconds = 10,
    @maximum_retry_interval_seconds = 120,
    @retry_attempts = 5,
    @retry_interval_backoff_multiplier = 2,
    @step_timeout_seconds = 3600;
