SELECT name, type_desc FROM sys.database_principals
WHERE type_desc='SQL_USER' AND
name NOT LIKE 'INFORMATION_SCHEMA' AND
name NOT LIKE 'dbo' AND
name NOT LIKE 'sys' AND
name NOT LIKE 'guest' 
