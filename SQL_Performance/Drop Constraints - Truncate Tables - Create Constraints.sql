-- Drop All Constrains, Truncate All Tables, Re-Create All Constrains ---
-- https://gist.github.com/danguilherme/04fbe3906b46844f9351

USE [<database>]
GO
SET NOCOUNT ON
GO
--Get the list of all the tables to be truncated
DECLARE @TablesToBeTruncated AS TABLE (
      Id INT IDENTITY(1,1),
      TableObjectId INT,
      TableName SYSNAME,
    SchemaId INT
)
INSERT INTO @TablesToBeTruncated (TableObjectId, TableName, SchemaId)
SELECT
      ST.object_id,
      ST.name,
      ST.schema_id
FROM
      sys.Tables ST
      INNER JOIN sys.Schemas SS
            ON ST.schema_id = SS.schema_id
WHERE ST.type = 'U' AND ST.NAME NOT LIKE '#%' AND ST.name <> 'sysdiagrams'
      --AND SS.name IN ('') -- Specify here the comma separated schema names which tables need to be truncated
      --AND ST.NAME NOT IN ('') -- Specify here the comma separated table names which needs to be truncated
      --AND ST.NAME IN ('') -- Specify here the comma separated table names for which truncation is not required

PRINT 'BEGIN TRANSACTION TruncateTables'
PRINT 'BEGIN TRY'

DECLARE @DbName VARCHAR(MAX)
SELECT @DbName = db_name();
PRINT '    USE [' + @DbName + ']'

--Generate the foreignkeys drop and create back script
DECLARE
      @CreateScript AS NVARCHAR(MAX),
      @DropScript AS NVARCHAR(MAX)

SELECT
    ------------DROP SCRIPT--------------------
    @DropScript = ISNULL(@DropScript,'') +
            '    ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(FKey.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(FKey.parent_object_id)) +
            ' DROP CONSTRAINT ' + QUOTENAME(FKey.name) + CHAR(10),

     -----------CREATE BACK SCRIPT-------------
    @CreateScript = ISNULL(@CreateScript,'') +
            '    ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(FKey.schema_id)) + '.' + QUOTENAME(OBJECT_NAME(FKey.parent_object_id)) +
            ' ADD CONSTRAINT ' + QUOTENAME(FKey.name) +
            ' FOREIGN KEY ' +
                  '(' + STUFF(( -- Get the list of columns
                 SELECT ',' + QUOTENAME(COL_NAME(FKeyCol.parent_object_id, FKeyCol.parent_column_id))
                 FROM SYS.FOREIGN_KEY_COLUMNS FKeyCol
                 WHERE FKey.OBJECT_ID = FKeyCol.constraint_object_id
                 ORDER BY FKeyCol.constraint_column_id
                 FOR XML PATH('')),1,1,'') +
                  ')' +
            ' REFERENCES ' + QUOTENAME(SCHEMA_NAME(Tlist.SchemaId)) + '.' + QUOTENAME(OBJECT_NAME(FKey.referenced_object_id)) +
                  ' (' + STUFF(( -- Get the list of columns
                SELECT ',' + QUOTENAME(COL_NAME(FKeyCol.referenced_object_id, FKeyCol.referenced_column_id))
                FROM SYS.FOREIGN_KEY_COLUMNS FKeyCol
                WHERE FKey.OBJECT_ID = FKeyCol.constraint_object_id
                ORDER BY FKeyCol.constraint_column_id
                FOR XML PATH('')),1,1,'') +
                  ') ' +
            -- ON UPDATE ?
            CASE
                  WHEN update_referential_action_desc = 'CASCADE' THEN ' ON UPDATE CASCADE'
            WHEN update_referential_action_desc = 'SET_DEFAULT' THEN ' ON UPDATE SET DEFAULT'
            WHEN update_referential_action_desc = 'SET_NULL' THEN ' ON UPDATE SET NULL'
            ELSE ''
            END +
            -- ON DELETE ?
            CASE
                  WHEN delete_referential_action_desc = 'CASCADE' THEN ' ON DELETE CASCADE'
            WHEN delete_referential_action_desc = 'SET_DEFAULT' THEN ' ON DELETE SET DEFAULT'
            WHEN delete_referential_action_desc = 'SET_NULL' THEN ' ON DELETE SET NULL'
            ELSE ''
       END + CHAR(10)
FROM
      @TablesToBeTruncated Tlist
    INNER JOIN SYS.FOREIGN_KEYS FKey
        ON Tlist.TableObjectId = FKey.referenced_object_id

--PRINT THE TRUNCATION SCRIPT
IF LEN(ISNULL(@DropScript,'')) > 0
BEGIN
      PRINT CHAR(10) + CHAR(10) + '    --------DROP FOREIGN KEY CONSTRAINTS SCRIPT--------'
      PRINT CAST((@DropScript + CHAR(10) + CHAR(10)) AS NTEXT)
END

PRINT '    --------TRUNCATE TABLES SCRIPT--------'
--TRUNCATE TABLES

DECLARE
      @id INT,
      @truncatescript NVARCHAR(MAX)

SELECT
      @id = MIN(Id)
FROM
      @TablesToBeTruncated

WHILE @id IS NOT NULL
BEGIN
    SELECT
            @truncatescript = '    TRUNCATE TABLE ' + QUOTENAME(SCHEMA_NAME(SchemaId)) + '.' + QUOTENAME(TableName)
    FROM
            @TablesToBeTruncated
      WHERE
            Id = @id

      PRINT CAST(@truncatescript AS NTEXT)

    SELECT
            @id = MIN(Id)
      FROM
            @TablesToBeTruncated
      WHERE Id > @id
END

IF LEN(ISNULL(@CreateScript,'')) > 0
BEGIN
      PRINT CHAR(10)
    PRINT '    --------CREATE BACK THE FOREIGN KEY CONSTRAINTS SCRIPT--------'
      PRINT CAST((@CreateScript + CHAR(10) + CHAR(10)) AS NTEXT)
END

PRINT '    COMMIT TRANSACTION TruncateTables'
PRINT 'END TRY'

PRINT 'BEGIN CATCH'
PRINT '    ROLLBACK TRANSACTION TruncateTables'
PRINT 'END CATCH'

GO