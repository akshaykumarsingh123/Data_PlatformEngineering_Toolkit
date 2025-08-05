**************Setting Job Schedules*****************************************

--Changing the retry attempts of the job
EXEC jobs.sp_update_jobstep
    @job_name = N'Maintenance – Reorganize & Rebuild Indexes',
    @step_name = N'Rebuild Reorg',
    @retry_attempts = 3;  -- Set the desired number of retry attempts

--Change the retry interval
EXEC jobs.sp_update_jobstep
    @job_name = N'Maintenance – Reorganize & Rebuild Indexes',
    @step_name = N'Rebuild Reorg',
    @initial_retry_interval_seconds = 60;  -- Set retry interval to 60 seconds

--T-SQL to Create, Schedule, and Enable an Azure Elastic Job
EXEC jobs.sp_add_job
    @job_name = N'MyElasticJob',
    @description = N'Example job for scheduled execution',
    @enabled = 1,  -- Enables the job and its schedule
    @schedule_interval_type = N'Days',  -- Options: Once, Minutes, Hours, Days, Weeks, Months
    @schedule_interval_count = 1,       -- Every 1 day
    @schedule_start_time = '2025-06-25T00:00:00';  -- UTC time for first run

--Run Every Day at 10:00 PM (UTC)
EXEC jobs.sp_update_job
    @job_name = N'YourJobName',
    @enabled = 1,
    @schedule_interval_type = N'Days',
    @schedule_interval_count = 1,
    @schedule_start_time = '2025-06-24T22:00:00';  -- 10:00 PM UTC

--Run on a Specific Day of the Week at a Certain Time
EXEC jobs.sp_add_job
    @job_name = N'Maintenance – Reorganize & Rebuild Indexes',
    @description = N'Scheduled Maintenance',
    @enabled = 1,  -- Enables the job and its schedule
    @schedule_interval_type = N'Days',  -- Options: Once, Minutes, Hours, Days, Weeks, Months
    @schedule_interval_count = 1,       -- Every 1 day
    @schedule_start_time = '2025-06-25T00:00:00';  -- UTC time for first run

-- Run job every 30 Minutes
EXEC jobs.sp_update_job
     @job_name = 'JobName',                     -- Replace with your job name
     @enabled = 1,
     @schedule_interval_type = 'Minutes',
     @schedule_interval_count = 30,
     @schedule_start_time = '2025-07-22T20:44:00';