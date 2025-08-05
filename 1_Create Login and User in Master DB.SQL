-- Create the login and user within the Master database
--Make sure the connection to the database is through MS-Entra else statements would not execute.

-- CREATE A LOGIN ON THE MASTER DATABASE MAPPED TO A USER-ASSIGNED MANAGED IDENTITY (UMI)
CREATE LOGIN [cd01d-midbelasagt] FROM EXTERNAL PROVIDER;

-- CREATE A USER ON THE MASTER DATABASE MAPPED TO A LOGIN
CREATE USER [cd01d-midbelasagt] FROM EXTERNAL PROVIDER;


