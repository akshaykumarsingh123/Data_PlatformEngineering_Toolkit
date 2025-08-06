USE [DBA_Admin]
GO

/****** Object:  StoredProcedure [dbo].[SQL_ErrorLog_Alert]    Script Date: 4/11/2025 10:38:51 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




--select * from sql_errorlog

CREATE PROCEDURE [dbo].[SQL_ErrorLog_Alert] 
@Minutes [int] = NULL  
AS
BEGIN
SET NOCOUNT ON;
DECLARE @ERRORMSG varchar(8000)
DECLARE @SNO INT
DECLARE @Mins INT
DECLARE @SQLVERSION VARCHAR(4)
IF @Minutes IS NULL  -- If the optional parameter is not passed, @Mins value is set to 6
 SET @Mins = 60
ELSE
 SET @Mins = @Minutes
  /* Fetches the numeric part of SQL Version */
 SELECT @SQLVERSION = RTRIM(LTRIM(SUBSTRING(@@VERSION,22,5))) 

IF @SQLVERSION = '2000'  
 /* Checks the version of SQL Server and executes 
 the code depending on it since the output of the 
 sp_readerrorlog varies between SQL 2000 and the next versions */
 BEGIN
  
 /*Temporary table to store the output from execution of sp_readerrorlog */
  
 CREATE Table #ErrorLog2000 
 (ErrorLog varchar(4000),ContinuationRow Int) 
 INSERT INTO  #ErrorLog2000  -- Stores the output of sp_readerrorlog
 EXEC sp_readerrorlog
 /* The code below deletes the rows in the error log which are mostly 
 the SQL startup messages written into the error log */
  
 DELETE FROM #ErrorLog2000 
 WHERE (LEFT(LTRIM(ErrorLog),4) NOT LIKE DATEPART(YYYY,GETDATE()) 
    AND ContinuationRow = 0) 
 

  /* Once the SQL Server startup and other information prior to 
  @Mins is deleted from the temporary table, the below code starts 
  concatenating the remaining rows in the temporary table 
  and stores into single variable */
  
 SELECT @ERRORMSG = COALESCE(@ERRORMSG + CHAR(13) , '')  
   + ErrorLog FROM #ErrorLog2000
  
 DROP TABLE #ErrorLog2000 
 END
ELSE
 BEGIN
 CREATE TABLE #ErrorLog2005 
 (LogDate DATETIME, ProcessInfo VARCHAR(50) ,[Text] VARCHAR(4000))
 INSERT INTO #ErrorLog2005 
 EXEC sp_readerrorlog
 select * INTO #ErrorLog2005_2 from #ErrorLog2005
 WHERE LogDate >= CAST(DATEADD(MI,-@Mins,GETDATE()) AS VARCHAR(23))
 
 --OR ([Text] LIKE '%Logging SQL Server messages in file %')
 AND ( ([Text] LIKE '%Shutdown%')
 OR ([Text] LIKE '%Dead%')
 --OR ([Text] LIKE '%Starting%')
 OR ([Text] LIKE '%critical%')
 OR ([Text] LIKE '%Stopped%'))
-- OR ([Text] LIKE '%Clearing%') -- clearing differential backup message
 --OR ([Text] LIKE '%error%')
 --OR ([Text] LIKE '%Analysis%')
 --OR ([Text] LIKE '%17054%')-- error
 --OR ([Text] LIKE '%8946%'))--error
 --OR ([Text] LIKE '%fail%'))-- system error
 --OR ProcessInfo = '%Backup%' -- Deletes backup information
 SELECT  @ERRORMSG = COALESCE(@ERRORMSG + CHAR(13) , '') 
   + CAST(LogDate AS VARCHAR(23)) + '  ' 
   + [Text] FROM #ErrorLog2005_2
 --select * from #ErrorLog2005_2
 DROP TABLE #ErrorLog2005
 DROP TABLE #ErrorLog2005_2
 
 END
IF @ERRORMSG IS NOT NULL 
  -- There is some data in SQL error log that needs to be stored
 BEGIN
  IF  EXISTS (SELECT * FROM dbo.sysobjects 
    WHERE  id = OBJECT_ID(N'[dbo].[SQL_ErrorLog]') 
    AND OBJECTPROPERTY(id, N'IsUserTable') = 1)
	BEGIN
   SELECT @ERRORMSG
   INSERT INTO [dbo].[SQL_ErrorLog]
   SELECT @ERRORMSG
   END
  ELSE
   
  BEGIN
   
  CREATE TABLE [dbo].[SQL_ErrorLog](
   [TEXT] [varchar](8000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
   ) ON [PRIMARY]
  INSERT INTO [dbo].[SQL_ErrorLog]
  SELECT @ERRORMSG
  
  END
 END
ELSE  -- No error messages have been in the last @Mins minutes
 Print 'No Error Messages'
END


--select * from SQL_ErrorLog
GO


