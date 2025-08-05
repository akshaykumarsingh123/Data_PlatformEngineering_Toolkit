/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
--  The following will search program code for a work or phrase, and allow for exclusions
--  The regular expression is case-insensitive and may contain spaces, the number of spaces must be specific
--  This cannot cannot search over CF or LF ( a single phrase over multiple lines)
/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
DECLARE @SearchString             VARCHAR(255)
DECLARE @DoesNotContain           VARCHAR(255)

SELECT  @SearchString = 'regex'   --  Replace with text you are searching for
SELECT  @DoesNotContain = ''      --  Leave '' or add text to exclude between quotes

SELECT  DISTINCT sysobjects.name  AS  [Object Name] ,
        CASE
          WHEN sysobjects.xtype = 'P'   THEN  'Stored Procedure'
          WHEN sysobjects.xtype = 'TF'  THEN  'Function'
          WHEN sysobjects.xtype = 'TR'  THEN  'Trigger'
          WHEN sysobjects.xtype = 'V'   THEN  'View'
        END                       AS  [Object Type]
  FROM  sysobjects,syscomments
  WHERE sysobjects.id = syscomments.id
    AND sysobjects.type IN ('P','TF','TR','V')
    AND sysobjects.category = 0
    AND CHARINDEX( @SearchString, syscomments.text) > 0
    AND CHARINDEX( @DoesNotContain, syscomments.text) = 0;
GO

/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
--  Find any text within in any program code within a database
--  The regular expression is case-insensitive and may contain spaces, the number of spaces must be specific
/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
DECLARE @Search1  VARCHAR(255)
DECLARE @Search2  VARCHAR(255)
DECLARE @Search3  VARCHAR(255)
DECLARE @Search4  VARCHAR(255)
SET @Search1 = 'FTP'
SET @Search2 = 'SQLCMD'
SET @Search3 = 'OPENROWSET'
SET @Search4 = 'OPENDATASOURCE'

SELECT  DISTINCT
          LEFT(so.name, 100)      AS  [Object Name],
          ( CASE so.type
              WHEN 'AF' THEN 'Aggregate Function (CLR)'
              WHEN 'C'  THEN 'Check Constraint'
              WHEN 'D'  THEN 'Default Constraint'
              WHEN 'F'  THEN 'Foreign Key Constraint'
              WHEN 'L'  THEN 'Log'
              WHEN 'FN' THEN 'Scalar Function'
              WHEN 'FS' THEN 'Assembly (CLR) Scalar Function'
              WHEN 'FT' THEN 'Assembly (CLR) Table Valued Function'
              WHEN 'IF' THEN 'In-lined Table Function'
              WHEN 'IT' THEN 'Internal Table'
              WHEN 'P'  THEN 'Stored Procedure'
              WHEN 'PC' THEN 'Assembly (CLR) Stored Procedure'
              WHEN 'PK' THEN 'Primary Key Constraint'
              WHEN 'RF' THEN 'Replication Filter Stored Procedure'
              WHEN 'S'  THEN 'System Table'
              WHEN 'SN' THEN 'Synonym'
              WHEN 'SQ' THEN 'Service Queue'
              WHEN 'TA' THEN 'Assembly (CLR) Trigger'
              WHEN 'TF' THEN 'Table Function'
              WHEN 'TR' THEN 'Trigger'
              WHEN 'TT' THEN 'Table Type'
              WHEN 'U'  THEN 'User Table'
              WHEN 'UQ' THEN 'Unique Constraint (type is K)'
              WHEN 'V'  THEN 'View'
              WHEN 'X'  THEN 'Extended Stored Procedure'
              ELSE '<<UNKNOWN ' + so.type + '>>'
            END )                 AS  [Object Type]
  FROM  syscomments sc
  INNER JOIN sysobjects so
    ON  so.id = sc.id
  WHERE text Like '%'+@Search1+'%'
    OR  text Like '%'+@Search2+'%'
    OR  text Like '%'+@Search3+'%'
--    OR  text Like '%'+@Search4+'%'
  ORDER BY 2, 1;
GO

/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
--  Find any text within in any program code within ALL databases
--  The regular expression is case-insensitive and may contain spaces, the number of spaces must be specific
/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
EXEC sp_MSforeachdb '
USE [?];

SELECT  DISTINCT
          @@SERVERNAME    [Server Name],
          DB_NAME()       [Database Name],
          LEFT(so.name, 100)      AS  [Object Name],
          ( CASE so.type
              WHEN ''AF'' THEN ''Aggregate Function (CLR)''
              WHEN ''C''  THEN ''Check Constraint''
              WHEN ''D''  THEN ''Default Constraint''
              WHEN ''F''  THEN ''Foreign Key Constraint''
              WHEN ''L''  THEN ''Log''
              WHEN ''FN'' THEN ''Scalar Function''
              WHEN ''FS'' THEN ''Assembly (CLR) Scalar Function''
              WHEN ''FT'' THEN ''Assembly (CLR) Table Valued Function''
              WHEN ''IF'' THEN ''In-lined Table Function''
              WHEN ''IT'' THEN ''Internal Table''
              WHEN ''P''  THEN ''Stored Procedure''
              WHEN ''PC'' THEN ''Assembly (CLR) Stored Procedure''
              WHEN ''PK'' THEN ''Primary Key Constraint''
              WHEN ''RF'' THEN ''Replication Filter Stored Procedure''
              WHEN ''S''  THEN ''System Table''
              WHEN ''SN'' THEN ''Synonym''
              WHEN ''SQ'' THEN ''Service Queue''
              WHEN ''TA'' THEN ''Assembly (CLR) Trigger''
              WHEN ''TF'' THEN ''Table Function''
              WHEN ''TR'' THEN ''Trigger''
              WHEN ''TT'' THEN ''Table Type''
              WHEN ''U''  THEN ''User Table''
              WHEN ''UQ'' THEN ''Unique Constraint (type is K)''
              WHEN ''V''  THEN ''View''
              WHEN ''X''  THEN ''Extended Stored Procedure''
              ELSE ''<<UNKNOWN '' + so.type + ''>>''
            END )                 AS  [Object Type]
  FROM  syscomments sc
  INNER JOIN sysobjects so
    ON  so.id = sc.id
  WHERE text Like ''%OPENROWSET%''
    OR  text Like ''%OPENDATASOURCE%''
    OR  text Like ''%sqlcmd%''
    OR  text Like ''%xp_cmdshell%''
    OR  text Like ''%bcp%''
    OR  text Like ''%ftp%''
    OR  text Like ''%queryout%''
  ORDER BY 2, 1;
'

/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
--  Look through all databases for an index of a specific name
/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
EXEC sp_MSforeachdb '
USE [?];
SELECT  DISTINCT
          @@SERVERNAME            [Server Name],
          DB_NAME()               [Database Name],
          OBJECT_NAME(object_id)  [Table_Name],
          name                    [Index Name],
          type_desc               [Index_Type]
  FROM  sys.indexes
  WHERE	is_hypothetical = 0
    AND index_id != 0
    AND name = ''prdsunwingca''
'
