--The below SQL statements have to be executed on the target database
-- Create the login and user within the Master database
--Make sure the connection to the database is through MS-Entra else statements would not execute.


-- CREATE A LOGIN ON THE MASTER DATABASE MAPPED TO A USER-ASSIGNED MANAGED IDENTITY (UMI)
CREATE LOGIN [<Name of User Managed identity>] FROM EXTERNAL PROVIDER;

-- CREATE A USER ON THE MASTER DATABASE MAPPED TO A LOGIN
CREATE USER [<Name of User Managed identity>] FROM EXTERNAL PROVIDER;


-- CREATE A USER ON A USER DATABASE MAPPED TO A LOGIN.
CREATE USER [<Name of User Managed identity>] FROM LOGIN [<Name of User Managed identity>];

-- GRANT PERMISSIONS AS NECESSARY TO EXECUTE YOUR JOBS. FOR EXAMPLE, ALTER AND CREATE TABLE:
GRANT ALTER ON SCHEMA::DBO TO <Name of User Managed identity>;
GRANT CREATE TABLE TO <Name of User Managed identity>;

CREATE ROLE DB_EXECUTOR;
GRANT EXECUTE TO DB_EXECUTOR;
EXEC SP_ADDROLEMEMBER [DB_Owner], [<Name of User Managed identity>];

GRANT ALTER ON SCHEMA::[DBO] TO [<Name of User Managed identity>];
GRANT SELECT ON SCHEMA::[DBO] TO [<Name of User Managed identity>];
GRANT EXECUTE ON SCHEMA::[DBO] TO [<Name of User Managed identity>];

GRANT ALTER ON SCHEMA::[SalesLT] TO [<Name of User Managed identity>];
GRANT SELECT ON SCHEMA::[SalesLT] TO [<Name of User Managed identity>];
GRANT EXECUTE ON SCHEMA::[SalesLT] TO [<Name of User Managed identity>];

