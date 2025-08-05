--Replace @@DATABASE

USE master
GO
IF OBJECT_ID ('sp_hexadecimal') IS NOT NULL
  DROP PROCEDURE sp_hexadecimal
GO
CREATE PROCEDURE sp_hexadecimal
    @binvalue varbinary(256),
    @hexvalue varchar (514) OUTPUT
AS
DECLARE @charvalue varchar (514)
DECLARE @i int
DECLARE @length int
DECLARE @hexstring char(16)
SELECT @charvalue = '0x'
SELECT @i = 1
SELECT @length = DATALENGTH (@binvalue)
SELECT @hexstring = '0123456789ABCDEF'
WHILE (@i <= @length)
BEGIN
  DECLARE @tempint int
  DECLARE @firstint int
  DECLARE @secondint int
  SELECT @tempint = CONVERT(int, SUBSTRING(@binvalue,@i,1))
  SELECT @firstint = FLOOR(@tempint/16)
  SELECT @secondint = @tempint - (@firstint*16)
  SELECT @charvalue = @charvalue +
    SUBSTRING(@hexstring, @firstint+1, 1) +
    SUBSTRING(@hexstring, @secondint+1, 1)
  SELECT @i = @i + 1
END

SELECT @hexvalue = @charvalue
GO
 
-----------------------------------------------------------------------------------------------------------------------
----------------------------------------PUT YOUR DATABASE HERE---------------------------------------------------------
USE [@@DATABASE]
SET NOCOUNT ON
SELECT a.name as LoginName, 
	CONVERT(varbinary(256), LOGINPROPERTY(a.name, 'PasswordHash')) PassHash,
	SPACE(514) PassText,
	b.sid [SID],
    a.default_database_name, 
    a.default_language_name,
    'EXECUTE sp_addsrvrolemember @loginame = ' + '''' + a.name + '''' + ',@rolename = ' + '''' + pp.name + '''' AS RoleScript
INTO #DatabaseSQLLogins
FROM master.sys.server_principals a inner join dbo.sysusers b on a.sid = b.sid
	LEFT JOIN sys.server_role_members roles on roles.member_principal_id = a.principal_id
     LEFT join sys.server_principals pp on roles.role_principal_id = pp.principal_id
WHERE
    a.type = 'S' AND 
    a.name NOT IN ('sa', 'guest')
    AND a.name not in ('sa','NT AUTHORITY\SYSTEM','US\Sqldbaadmin','distributor_admin')
ORDER BY a.name
SET NOCOUNT OFF
-----------------------------------------------------------------------------------------------------------------------
DECLARE @SID VARBINARY(256)
DECLARE @LoginName VARCHAR(256)
DECLARE @DefDB VARCHAR(256)
DECLARE @DefLang VARCHAR(256)
DECLARE @PassHash VARBINARY(256)
DECLARE @Password VARCHAR(514)
DECLARE @RoleScript VARCHAR(1000)
DECLARE @sql VARCHAR(2000)

DECLARE login_cursor CURSOR FOR (SELECT LoginName, [SID], PassHash,default_database_name,default_language_name,RoleScript FROM #DatabaseSQLLogins)
OPEN login_cursor
    FETCH NEXT FROM login_cursor INTO @LoginName, @SID, @PassHash,@DefDB,@DefLang,@RoleScript
	WHILE @@FETCH_STATUS = 0
    BEGIN
		EXEC master.dbo.sp_hexadecimal @PassHash, @Password OUTPUT
		SET @sql = 'USE MASTER IF EXISTS (SELECT * FROM sys.server_principals WHERE name = ' + '''' + @LoginName + '''' + ') DROP LOGIN [' + @LoginName + ']'
		--PRINT @sql        
		SET @sql = 'USE MASTER CREATE LOGIN ' + @LoginName + ' WITH PASSWORD = '
        SET @sql = @sql + CONVERT(nvarchar(512), COALESCE(@Password, 'NULL')) 
        SET @sql = @sql + ' HASHED, CHECK_POLICY = ON, DEFAULT_DATABASE=[' + @DefDB + '], DEFAULT_LANGUAGE=[' + @DefLang + ']' 
		SET @Password = null
        PRINT @sql
		
		SET @sql = 'USE [@@DATABASE] EXEC sp_change_users_login ' + '''' + 'Update_One' + '''' + 
			', ' + '''' + @LoginName + '''' + ', ' + '''' + @LoginName + ''''
        PRINT @sql
        IF @RoleScript != ''
        PRINT @RoleScript
        PRINT '/*------------------------------------------------------------------------------------------------------------------------*/'
        
        FETCH NEXT FROM login_cursor INTO @LoginName, @SID, @PassHash,@DefDB,@DefLang,@RoleScript
    END
CLOSE login_cursor
DEALLOCATE login_cursor
-----------------------------------------------------------------------------------------------------------------------
DROP TABLE #DatabaseSQLLogins
GO
USE master
GO
IF OBJECT_ID ('sp_hexadecimal') IS NOT NULL
  DROP PROCEDURE sp_hexadecimal