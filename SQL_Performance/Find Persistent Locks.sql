--  https://www.cafe-encounter.net/p694/sp_wholock-a-t-sql-stored-proc-combining-sp_who-and-sp_lock-to-show-whos-locking-what-and-how-much#gsc.tab=0
SET NOCOUNT ON

IF OBJECT_ID( 'tempdb..#lock' ) IS NOT NULL
  DROP TABLE #lock

CREATE TABLE #lock
  ( spid     INT,
    dbid     INT,
    objId    INT,
    indId    INT,
    Type     CHAR(4),
    resource NCHAR(32),
    Mode     CHAR(8),
    status   CHAR(6)  )

INSERT INTO #lock
  EXEC sp_lock

IF OBJECT_ID( 'tempdb..#who' ) IS NOT NULL
  DROP TABLE #who

CREATE TABLE #who
  ( spid       INT,
    ecid       INT,
    status     CHAR(30),
    loginame   CHAR(128),
    hostname   CHAR(128),
    blk        CHAR(5),
    dbname     CHAR(128),
    cmd        CHAR(16),
    request_id INT        ) --  Needed for SQL 2008 onwards

INSERT INTO #who
  EXEC sp_who

--  Lock Summary
IF OBJECT_ID( 'tempdb..#locksummary' ) IS NOT NULL
  DROP TABLE #LockSummary

SELECT LEFT( loginame, 28 )             AS loginame,
       LEFT( DB_NAME( dbid ), 128 )     AS DB,
       LEFT( OBJECT_NAME( objId ), 30 ) AS object,
       MAX( Mode )                      AS [ToLevel],
       COUNT( * )                       AS [How Many],
       MAX( CASE
         WHEN Mode = 'X' THEN cmd
         ELSE NULL
       END )                            AS [Xclusive lock for command],
       l.spid,
       hostname
  INTO #LockSummary
  FROM #lock l
    JOIN #who w ON l.spid = w.spid
  WHERE dbid != DB_ID( 'tempdb' )
    AND l.status = 'GRANT'
  GROUP BY dbid, objId, l.spid, hostname, loginame;

SELECT *
  FROM #LockSummary
  ORDER BY [ToLevel] DESC, [How Many] DESC, loginame, DB, object;

--  Who is blocking:
SELECT p.spid,
       CONVERT( CHAR(12), d.name )   db_name,
       program_name,
       p.loginame,
       CONVERT( CHAR(12), hostname ) hostname,
       cmd,
       p.status,
       p.blocked,
       login_time,
       last_batch,
       p.spid
  FROM master..sysprocesses p
    JOIN master..sysdatabases d ON p.dbid = d.dbid
  WHERE EXISTS (
      SELECT 1
        FROM master..sysprocesses p2
        WHERE p2.blocked = p.spid
    );

--  Details:
SELECT LEFT( loginame, 30 )             AS loginame,
       l.spid,
       LEFT( DB_NAME( dbid ), 15 )      AS DB,
       LEFT( OBJECT_NAME( objId ), 40 ) AS object,
       Mode,
       blk,
       l.status
  FROM #lock l
    JOIN #who w ON l.spid = w.spid
  WHERE dbid != DB_ID( 'tempdb' )
    AND blk <> 0
  ORDER BY Mode DESC, blk, loginame, dbid, objId, l.status;