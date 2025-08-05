sp_change_users_login 'report'

EXEC msdb.dbo.sp_send_dbmail
     @profile_name = 'DBA_Admin',
     @recipients = 'aksingh@sunwing.ca',
     @body = 'Test',
     @subject = 'Test';
GO

EXECUTE msdb.dbo.sysmail_add_principalprofile_sp  
    @profile_name = 'DBA_Admin',  
    @principal_name = 'public',  
    @is_default = 1 ;
GO
select * from msdb.dbo.sysmail_sentitems

select * from msdb.dbo.sysmail_unsentitems

select * from msdb.dbo.sysmail_faileditems
SELECT * FROM msdb.dbo.sysmail_event_log;

--The mail could not be sent to the recipients because of the mail server failure. 
--(Sending Mail using Account 1 (2024-04-08T17:14:06). 
--Exception Message: Cannot send mails to mail server. (The operation has timed out.)

SELECT is_broker_enabled FROM sys.databases WHERE name = 'msdb';
GO
SELECT * FROM  sys.configurations WHERE name = 'Database Mail XPs'
GO

SELECT [sysmail_server].[account_id],
       [sysmail_account].[name] AS [Account Name],
       [servertype],
       [servername] AS [SMTP Server Address],
       [Port]
FROM [msdb].[dbo].[sysmail_server]
     INNER JOIN [msdb].[dbo].[sysmail_account] ON [sysmail_server].[account_id] = [sysmail_account].[account_id];
