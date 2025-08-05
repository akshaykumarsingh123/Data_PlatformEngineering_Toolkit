--Replace @@DATABASE

SET NOCOUNT ON
SELECT a.name as LoginName,
    a.default_database_name, 
    a.default_language_name,
    a.sid,
    'EXECUTE sp_addsrvrolemember @loginame = ' + '''' + a.name + '''' + ',@rolename = ' + '''' + pp.name + '''' AS RoleScript
INTO #DatabaseSQLLogins
FROM master.sys.server_principals a inner join [@@DATABASE].dbo.sysusers b on a.sid = b.sid
	LEFT JOIN sys.server_role_members roles on roles.member_principal_id = a.principal_id
     LEFT join sys.server_principals pp on roles.role_principal_id = pp.principal_id

WHERE a.type in ('U','G')
	AND b.islogin = 1
    AND b.issqluser = 0
    AND b.name NOT IN ('dbo', 'guest', 'INFORMATION_SCHEMA','sys')
    AND a.name not in ('sa','NT AUTHORITY\SYSTEM','US\Sqldbaadmin','distributor_admin')
ORDER BY a.name

-----------------------------------------------------------------------------------------------------------------------
DECLARE @LoginName VARCHAR(256)
DECLARE @DefDB VARCHAR(256)
DECLARE @DefLang VARCHAR(256)
DECLARE @RoleScript VARCHAR(1000)
DECLARE @sql VARCHAR(2000)

DECLARE login_cursor CURSOR FOR (SELECT LoginName,default_database_name,default_language_name,RoleScript FROM #DatabaseSQLLogins)
OPEN login_cursor
    FETCH NEXT FROM login_cursor INTO @LoginName,@DefDB,@DefLang,@RoleScript
	WHILE @@FETCH_STATUS = 0
    BEGIN
		SET @sql = 'IF EXISTS (SELECT * FROM sys.server_principals WHERE name = ' + '''' + @LoginName + '''' + ') DROP LOGIN [' + @LoginName + ']'
		PRINT @sql        
		SET @sql = 'CREATE LOGIN [' + @LoginName + '] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[' + @DefLang + ']' 
        PRINT @sql
        IF @RoleScript != ''
			PRINT @RoleScript 
		PRINT '/*------------------------------------------------------------------------------------------------------------------------*/'
        FETCH NEXT FROM login_cursor INTO @LoginName,@DefDB,@DefLang,@RoleScript
    END
CLOSE login_cursor
DEALLOCATE login_cursor
-----------------------------------------------------------------------------------------------------------------------
DROP TABLE #DatabaseSQLLogins


