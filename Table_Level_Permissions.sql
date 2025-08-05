Table level Permissions:

SELECT  
Grantor as Grantor,
Grantee as User_Or_Role,
TABLE_CATALOG as database_name,
TABLE_SCHEMA as schema_name,
TABLE_NAME as table_name,
privilege_type as Permission,
IS_GRANTABLE as IS_GRANTABLE,
created as create_date
from information_schema.table_privileges
where User_or_role like '%AR_SUNWINGRES_RWX%' and table_name like '%BR_ADJ_STATEMENT%'
order by TABLE_NAME asc