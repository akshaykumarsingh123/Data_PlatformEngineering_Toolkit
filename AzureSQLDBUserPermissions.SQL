SELECT DISTINCT pr.principal_id, pr.name AS [UserName], pr.type_desc AS [User_or_Role], pr.authentication_type_desc AS [Auth_Type], 
pe.state_desc,
    pe.permission_name, pe.class_desc, o.[name] AS 'Object' 
    FROM sys.database_principals AS pr 
    JOIN sys.database_permissions AS pe ON pe.grantee_principal_id = pr.principal_id
    LEFT JOIN sys.objects AS o on (o.object_id = pe.major_id)


====================================================================================================================================

	SELECT    roles.principal_id                            AS RolePrincipalID
  ,    roles.name                                    AS RolePrincipalName
  ,    database_role_members.member_principal_id    AS MemberPrincipalID
  ,    members.name                                AS MemberPrincipalName
FROM sys.database_role_members AS database_role_members  
JOIN sys.database_principals AS roles  
  ON database_role_members.role_principal_id = roles.principal_id  
JOIN sys.database_principals AS members  
  ON database_role_members.member_principal_id = members.principal_id;  
GO