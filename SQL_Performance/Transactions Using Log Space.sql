-- This query returns log file space used by all running transactions
SELECT SessionTrans.session_id                               AS [SPID],
       enlist_count                                          AS [Active Requests],
       ActiveTrans.transaction_id                            AS [ID],
       ActiveTrans.Name                                      AS [Name],
       ActiveTrans.transaction_begin_time                    AS [Start Time],
       CASE transaction_type
         WHEN 1 THEN 'Read/Write'
         WHEN 2 THEN 'Read-Only'
         WHEN 3 THEN 'System'
         WHEN 4 THEN 'Distributed'
         ELSE 'Unknown - ' + CONVERT( VARCHAR(20), transaction_type )
       END                                                   AS [Transaction Type],
       CASE transaction_state
         WHEN 0 THEN 'Uninitialized'
         WHEN 1 THEN 'Not Yet Started'
         WHEN 2 THEN 'Active'
         WHEN 3 THEN 'Ended (Read-Only)'
         WHEN 4 THEN 'Committing'
         WHEN 5 THEN 'Prepared'
         WHEN 6 THEN 'Committed'
         WHEN 7 THEN 'Rolling Back'
         WHEN 8 THEN 'Rolled Back'
         ELSE 'Unknown - ' + CONVERT( VARCHAR(20), transaction_state )
       END                                                   AS 'State',
       CASE dtc_state
         WHEN 0 THEN NULL
         WHEN 1 THEN 'Active'
         WHEN 2 THEN 'Prepared'
         WHEN 3 THEN 'Committed'
         WHEN 4 THEN 'Aborted'
         WHEN 5 THEN 'Recovered'
         ELSE 'Unknown - ' + CONVERT( VARCHAR(20), dtc_state )
       END                                                   AS 'Distributed State',
       DB.Name                                               AS 'Database',
       database_transaction_begin_time                       AS [DB Begin Time],
       CASE database_transaction_type
         WHEN 1 THEN 'Read/Write'
         WHEN 2 THEN 'Read-Only'
         WHEN 3 THEN 'System'
         ELSE 'Unknown - ' + CONVERT( VARCHAR(20), database_transaction_type )
       END                                                   AS 'DB Type',
       CASE database_transaction_state
         WHEN 1 THEN 'Uninitialized'
         WHEN 3 THEN 'No Log Records'
         WHEN 4 THEN 'Log Records'
         WHEN 5 THEN 'Prepared'
         WHEN 10 THEN 'Committed'
         WHEN 11 THEN 'Rolled Back'
         WHEN 12 THEN 'Committing'
         ELSE 'Unknown - ' + CONVERT( VARCHAR(20), database_transaction_state )
       END                                                   AS 'DB State',
       database_transaction_log_record_count                 AS [Log Records],
       database_transaction_log_bytes_used / 1024            AS [Log KB Used],
       database_transaction_log_bytes_reserved / 1024        AS [Log KB Reserved],
       database_transaction_log_bytes_used_system / 1024     AS [Log KB Used (System)],
       database_transaction_log_bytes_reserved_system / 1024 AS [Log KB Reserved (System)],
       database_transaction_replicate_record_count           AS [Replication Records],
       command                                               AS [Command Type],
       total_elapsed_time                                    AS [Elapsed Time],
       cpu_time                                              AS [CPU Time],
       wait_type                                             AS [Wait Type],
       wait_time                                             AS [Wait Time],
       wait_resource                                         AS [Wait Resource],
       Reads                                                 AS [Reads],
       logical_reads                                         AS [Logical Reads],
       Writes                                                AS [Writes],
       SessionTrans.open_transaction_count                   AS [Open Transactions(SessionTrans)],
       ExecReqs.open_transaction_count                       AS [Open Transactions(ExecReqs)],
       open_resultset_count                                  AS [Open Result Sets],
       row_count                                             AS [Rows Returned],
       nest_level                                            AS [Nest Level],
       granted_query_memory                                  AS [Query Memory],
       SUBSTRING( SQLText.text, ExecReqs.statement_start_offset / 2, (CASE
         WHEN ExecReqs.statement_end_offset = -1 THEN LEN( CONVERT( NVARCHAR(MAX), SQLText.text ) ) * 2
         ELSE ExecReqs.statement_end_offset
       END - ExecReqs.statement_start_offset) / 2 )          AS query_text
  FROM sys.dm_tran_active_transactions ActiveTrans (NOLOCK)
    INNER JOIN sys.dm_tran_database_transactions DBTrans (NOLOCK) ON DBTrans.transaction_id = ActiveTrans.transaction_id
    INNER JOIN sys.databases DB (NOLOCK) ON DB.database_id = DBTrans.database_id
    LEFT JOIN sys.dm_tran_session_transactions SessionTrans (NOLOCK) ON SessionTrans.transaction_id = ActiveTrans.transaction_id
    LEFT JOIN sys.dm_exec_requests ExecReqs (NOLOCK) ON ExecReqs.session_id = SessionTrans.session_id
      AND ExecReqs.transaction_id = SessionTrans.transaction_id
    OUTER APPLY sys.dm_exec_sql_text( ExecReqs.sql_handle ) AS SQLText
  WHERE SessionTrans.session_id IS NOT NULL -- comment this out to see SQL Server internal processes
GO