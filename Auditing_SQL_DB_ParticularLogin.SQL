USE [master]

GO

CREATE SERVER AUDIT SPECIFICATION [ServerAuditSpecification-20240320-170631]
FOR SERVER AUDIT [ServerAudit]
ADD (SUCCESSFUL_LOGIN_GROUP)

GO


USE master;
GO
-- Create and Enable server audit
CREATE SERVER AUDIT SignatureTravelGuid
  TO FILE ( FILEPATH = 'T:\SQLAudit',
            MAXSIZE = 200 MB,
            MAX_ROLLOVER_FILES = 1000,
            RESERVE_DISK_SPACE = OFF )
  WITH ( QUEUE_DELAY = 1000, ON_FAILURE = CONTINUE )
  --  Include replication account
  WHERE [server_principal_name] = 'SignatureTravelGuid' OR 
  [server_principal_name] = 'SignatureTravelGuidUser';

ALTER SERVER AUDIT SignatureTravelGuid
  WITH (STATE = ON);
GO




--  All users
USE [website]
GO
-- Create and Enable database specification
CREATE DATABASE AUDIT SPECIFICATION SignatureTravelGuid
  FOR SERVER AUDIT SignatureTravelGuid
--  All users are a member of the public role
  ADD ( SELECT, INSERT, UPDATE, DELETE
        ON SCHEMA::dbo BY public );
ALTER DATABASE AUDIT SPECIFICATION SignatureTravelGuid
  WITH (STATE = ON);
GO