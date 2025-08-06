SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#Info', 'U') IS NOT NULL DROP TABLE #Info
CREATE TABLE #Info
(
    [Database]     sysname,
    [UserName]     sysname,
    [TypeDesc]     nvarchar(60),
    [Permission]   nvarchar(100),
    [GrantedThrough] sysname
)

DECLARE @databaseName sysname
DECLARE @sql nvarchar(max)

DECLARE db_cursor CURSOR FOR
SELECT name FROM sys.databases 
WHERE state_desc = 'ONLINE'
  AND database_id > 4 -- Exclude system databases

OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @databaseName

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = '
USE ' + QUOTENAME(@databaseName) + ';
WITH ExplicitPerms AS (
    SELECT 
        dp.name, 
        dp.type_desc, 
        perms.permission_name, 
        perms.state_desc, 
        perms.class_desc, 
        perms.major_id, 
        CAST('''' AS sysname) AS grant_through
    FROM sys.database_principals dp
    LEFT JOIN sys.database_permissions perms ON dp.principal_id = perms.grantee_principal_id
    WHERE dp.type_desc <> ''DATABASE_ROLE''
),
RolePerms AS (
    SELECT 
        dp.name, 
        dp.type_desc, 
        perms.permission_name, 
        perms.state_desc, 
        perms.class_desc, 
        perms.major_id, 
        rp.name as grant_through
    FROM sys.database_role_members drm
    INNER JOIN sys.database_principals dp ON drm.member_principal_id = dp.principal_id
    INNER JOIN sys.database_principals rp ON drm.role_principal_id = rp.principal_id
    LEFT JOIN sys.database_permissions perms ON perms.grantee_principal_id = drm.role_principal_id
    WHERE dp.type_desc <> ''DATABASE_ROLE''
)
INSERT INTO tempdb..#Info([Database],[UserName],[TypeDesc],[Permission],[GrantedThrough])
SELECT 
    DB_NAME(), 
    name, 
    type_desc,
    ISNULL(permission_name, ''(none)''), 
    grant_through 
FROM ExplicitPerms
UNION ALL
SELECT 
    DB_NAME(), 
    name, 
    type_desc,
    ISNULL(permission_name, ''(none)''), 
    grant_through 
FROM RolePerms
'
    EXEC(@sql)
    FETCH NEXT FROM db_cursor INTO @databaseName
END

CLOSE db_cursor
DEALLOCATE db_cursor

SELECT * 
FROM #Info
WHERE [UserName] NOT IN ('dbo', 'guest') -- Exclude system users if desired
ORDER BY [Database], [UserName], [TypeDesc], [Permission]
