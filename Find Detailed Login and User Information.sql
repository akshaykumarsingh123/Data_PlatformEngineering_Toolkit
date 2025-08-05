SET NOCOUNT ON

DROP TABLE IF EXISTS #LoginUserInfo
CREATE TABLE #LoginUserInfo
  ( ServerName        SYSNAME NULL,
    DatabaseName      SYSNAME NULL,
    LoginName         SYSNAME NULL,
    DBUserName        SYSNAME,
    DatabaseRoleName  SYSNAME,
    DefDBName         SYSNAME NULL,
    DefSchemaName     SYSNAME NULL,
    UserID            INT,
    [SID]             VARBINARY(85) )

DECLARE @command    VARCHAR(MAX)
DECLARE @databases  TABLE
  ( DatabaseName    VARCHAR(128),
    DatabaseSize    INT,
    remarks         VARCHAR(255)  )

INSERT INTO @databases  -- Popluate the table with the list of databases
EXEC sp_databases

SELECT @command = COALESCE( @command, '' ) + '
    USE ' + DatabaseName + '
      INSERT INTO
        #LoginUserInfo
          ( DBUserName,
            DatabaseRoleName,
            LoginName,
            DefDBName,
            DefSchemaName,
            UserID,
            [SID] )
      EXECUTE sp_helpuser
      UPDATE #LoginUserInfo
      SET DatabaseName  = DB_NAME(),
          ServerName    = @@servername
      WHERE DatabaseName IS NULL
    '
  FROM @databases

EXECUTE (@command)

SELECT  DatabaseName,
        LoginName,
        DBUserName,
        DatabaseRoleName,
        DefDBName,
        DefSchemaName
  FROM  #LoginUserInfo
  --  exclude internal SQL Server database users
  WHERE DBUserName NOT IN ( 'dbo', 'sys', 'guest', 'INFORMATION_SCHEMA' );
GO
