
DECLARE @job_name VARCHAR(40)
DECLARE @SQL VARCHAR(600)

DECLARE job_cursor CURSOR FOR 
SELECT 	name
FROM msdb.dbo.sysjobs
WHERE name LIKE '%LSRestore%'

OPEN job_cursor
FETCH NEXT FROM job_cursor INTO @job_name

WHILE @@fetch_status = 0
BEGIN
SET @SQL = 'EXEC MSDB.dbo.sp_stop_job ''' + @job_name + ''''
PRINT @SQL
FETCH NEXT FROM job_cursor INTO @job_name
END

CLOSE job_cursor
DEALLOCATE job_cursor

