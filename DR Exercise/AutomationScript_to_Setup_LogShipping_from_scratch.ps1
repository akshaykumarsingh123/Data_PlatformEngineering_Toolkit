$params = @{
SourceSqlInstance = 'YYZSQLDEV01'
 DestinationSqlInstance = 'YYZSQLDEV02'
 Database = 'TestLS','PS_Test','LS_Test123'
 SharedPath= '\\YYZSQLDEV01\LS_LogBackup'
 LocalPath= 'H:\LS_LogBackup'
 BackupScheduleFrequencyType = 'daily'
 BackupScheduleFrequencyInterval = 5
 BackupThreshold=45
 CompressBackup = $true
 CopyScheduleFrequencyType = 'daily'
 CopyScheduleFrequencyInterval = 5
 GenerateFullBackup = $true
 RestoreScheduleFrequencyType = 'daily'
 RestoreScheduleFrequencyInterval = 5
 RestoreThreshold=45
 RestoreAlertThreshold=45
 CopyDestinationFolder = '\\YYZSQLDEV02\LS_Copy'
 DisconnectUsers=$true
 Standby=$true
 StandbyDirectory='\\YYZSQLDEV02\LS_StandBy'
 Force = $true
 }
 Set-DbatoolsInsecureConnection -SessionOnly
 Invoke-DbaDbLogShipping @params