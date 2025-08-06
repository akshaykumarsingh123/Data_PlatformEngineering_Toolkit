DECLARE @dbname VARCHAR(40)
DECLARE @SQL VARCHAR(600)
DECLARE table_cursor CURSOR FOR 
SELECT name
FROM sys.databases 
WHERE is_read_only=1 AND database_id > 4

OPEN table_cursor
FETCH NEXT FROM table_cursor INTO @dbname

WHILE @@fetch_status = 0
BEGIN
SET @SQL = 'RESTORE DATABASE [' + @dbname + '] WITH RECOVERY ;'
PRINT @SQL
FETCH NEXT FROM table_cursor INTO @dbname
END

CLOSE table_cursor
DEALLOCATE table_cursor



