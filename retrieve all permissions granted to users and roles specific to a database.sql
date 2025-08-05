-- Query to retrieve all permissions granted to users and roles specific to a database
SELECT  
Grantor as Grantor,
Grantee as User_Or_Role,
OBJECT_CATALOG as database_name,
OBJECT_SCHEMA as object_name,
object_type as type_of_object,
privilege_type as permission,
is_grantable as is_grantable,
created as create_date
FROM  INFORMATION_SCHEMA.OBJECT_PRIVILEGES;