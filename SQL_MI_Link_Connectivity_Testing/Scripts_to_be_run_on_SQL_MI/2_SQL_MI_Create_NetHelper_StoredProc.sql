-- Run on managed instance
IF EXISTS(SELECT * FROM sys.objects WHERE name = 'ExecuteNetHelper')
    THROW 70001, 'Stored procedure ExecuteNetHelper already exists. Rename or drop the existing procedure before creating it again.', 1
GO
CREATE PROCEDURE ExecuteNetHelper AS
-- To delete the procedure run: DROP PROCEDURE ExecuteNetHelper
BEGIN
    -- Start the job.
    DECLARE @NetHelperstartTimeUtc DATETIME = GETUTCDATE();
    DECLARE @stop_exec_date DATETIME = NULL;

    EXEC msdb.dbo.sp_start_job @job_name = N'NetHelper';

    -- Wait for job to complete and then see the outcome.
    WHILE (@stop_exec_date IS NULL)
    BEGIN
        -- Wait and see if the job has completed.
        WAITFOR DELAY '00:00:01'

        SELECT @stop_exec_date = sja.stop_execution_date
        FROM msdb.dbo.sysjobs sj
        INNER JOIN msdb.dbo.sysjobactivity sja
            ON sj.job_id = sja.job_id
        WHERE sj.name = 'NetHelper'

        -- If job has completed, get the outcome of the network test.
        IF (@stop_exec_date IS NOT NULL)
        BEGIN
            SELECT sj.name JobName,
                sjsl.date_modified AS 'Date executed',
                sjs.step_name AS 'Step executed',
                sjsl.log AS 'Connectivity status'
            FROM msdb.dbo.sysjobs sj
            LEFT JOIN msdb.dbo.sysjobsteps sjs
                ON sj.job_id = sjs.job_id
            LEFT JOIN msdb.dbo.sysjobstepslogs sjsl
                ON sjs.step_uid = sjsl.step_uid
            WHERE sj.name = 'NetHelper'
        END

        -- In case of operation timeout (90 seconds), print timeout message.
        IF (datediff(second, @NetHelperstartTimeUtc, getutcdate()) > 90)
        BEGIN
            SELECT 'NetHelper timed out during the network check. Please investigate SQL Agent logs for more information.'

            BREAK;
        END
    END
END;