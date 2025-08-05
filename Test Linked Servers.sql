DECLARE @LinkedServerTable  TABLE
  ( Status      INT,
    ServerName  VARCHAR(100),
    ErrorMsg    VARCHAR(4000) )

DECLARE @lvLinkedServer     NVARCHAR(100)

--  Open cursor for only linked servers
DECLARE GetLinkedID CURSOR FOR
SELECT  name
  FROM  sys.servers
  WHERE is_linked = 1

OPEN GetLinkedID

FETCH NEXT FROM GetLinkedID INTO @lvLinkedServer
WHILE @@FETCH_STATUS = 0

BEGIN

  --  Use TRY/CATCH since sys.sp_testlinkedserver raises an exception on failure
  BEGIN TRY
    EXEC sys.sp_testlinkedserver @lvLinkedServer
  END TRY

  BEGIN CATCH
    INSERT INTO @LinkedServerTable
      VALUES  (1, @lvLinkedServer, ERROR_MESSAGE() )
  END CATCH

  FETCH NEXT FROM GetLinkedID INTO @lvLinkedServer

END

CLOSE GetLinkedID
DEALLOCATE GetLinkedID

SELECT ServerName, ErrorMsg FROM @LinkedServerTable


--  List server details, local and remote (linked)
SELECT  SS.server_id,
        SS.name,
        CASE SS.Server_id
          WHEN  0
            THEN  'Local Server'
          ELSE  'Remote Server'
          END   [Server],
        CASE LL.uses_self_credential
          WHEN  1
            THEN  'Uses Self Credentials'
          ELSE  SP.name
          END [Local Login],
        LL.remote_name [Remote Login],
        SS.product,
        SS.provider,
        SS.catalog,
        CASE SS.is_rpc_out_enabled
          WHEN  1
            THEN  'True'
          ELSE  'False'
          END [RPC Out Enabled],
        CASE SS.is_data_acceSS_enabled
          WHEN  1
            THEN  'True'
          ELSE  'False'
          END [Data AcceSS Enabled]
  FROM  sys.servers SS
  LEFT JOIN sys.linked_logins LL
    ON  SS.server_id = LL.server_id
  LEFT JOIN sys.server_principals SP
    ON  SP.principal_id = LL.local_principal_id
go
