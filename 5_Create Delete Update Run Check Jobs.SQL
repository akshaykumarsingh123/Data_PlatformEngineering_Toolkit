--Job operations 

--1. Create a Job
EXEC jobs.sp_add_job
    '<Job Name>';
	
--2. Add Job Steps
EXEC jobs.sp_add_jobstep
    @job_name= '<Job Name>',
    @step_name = N'<Job Step Name>',
    @command = N'',
    @target_group_name = N'<Target Group>';

--Check if job has been enabled
SELECT job_name, enabled, description
FROM jobs.jobs
WHERE job_name = '<Job Name>';

-- To enable the Job
EXEC jobs.sp_update_job 
    @job_name = 'Job_name', 
    @enabled = 1;
	
--3. Run the Job
EXEC jobs.sp_start_job
    '<Job Name>';

EXEC jobs.sp_stop_job
    @job_execution_id = N'<Job Execution Id>'; --- Provide the job execution id

--4. Monitor Job Execution
-- View job executions
SELECT * FROM jobs.job_executions 
WHERE job_name = N'<Job Name>';

--5. Update the Job Name (in case if needed)
EXEC jobs.sp_update_job
  @job_name = '<Job Name>',
  @new_name = '<Job Name>';

--6 Update the job Step (in case if needed)
EXEC jobs.sp_update_jobstep
    @job_name = N'<Job Name>',
    @step_id = 1,  -- Job step number
    @command = N'';

--7 Delete the job (in case if needed)
EXEC jobs.sp_delete_job '<Job Name>'

