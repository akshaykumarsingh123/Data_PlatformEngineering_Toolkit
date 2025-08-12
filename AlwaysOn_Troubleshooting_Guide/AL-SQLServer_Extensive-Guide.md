Always on Troubleshooting Extensive Guide:

Quest1.
Troubleshooting "Not Synchronizing" or "Data Movement Suspended" with Log Send Queue Buildup in Always On
When a replica in SQL Server Always On Availability Groups shows "Not Synchronizing" or "Data Movement Suspended", and you notice a substantial log send queue buildup, it's typically caused by problems in log data transfer between the primary and secondary replicas. Here’s how to systematically diagnose and resolve the issue:
________________________________________

1. Check Secondary Replica Connectivity
•	Network Issues:
•	Test connectivity using ping, telnet, or PowerShell Test-NetConnection between primary and secondary on database mirroring endpoint port (default: 5022).
•	Look for firewall blocks, routing problems, or DNS resolution failures.
•	Confirm endpoint status in SQL Server:

SELECT * FROM sys.database_mirroring_endpoints;

________________________________________
2. Examine the Log Send Queue and Network Speeds
•	On the primary, use:
SELECT 
  ag.name AS AGName,
  dbs.database_name,
  ars.synchronization_state_desc,
  ars.log_send_queue_size,
  ars.redo_queue_size
FROM sys.dm_hadr_database_replica_states ars
JOIN sys.availability_groups ag ON ars.group_id = ag.group_id
JOIN sys.databases dbs ON ars.database_id = dbs.database_id
WHERE ars.is_local = 1;
•	High log_send_queue_size with low redo_queue_size means logs are not sent, likely because of a network/endpoint problem.


3. Review Synchronization State
•	Use Always On dashboard in SSMS and DMVs to check states:
•	"Not Synchronizing": The secondary cannot keep up or connectivity is lost.
•	"Data Movement Suspended": Log transport has been paused (manual or automatic due to errors).
•	Resume data movement if suspended:

ALTER DATABASE [YourDB] SET HADR RESUME;
________________________________________

4. Check for Resource Bottlenecks
•	CPU, Memory, Disk IO:
•	Confirm primary and secondary have enough resources. High IO latency, especially on secondary storage, delays redo and log replay.
•	Run:

SELECT * FROM sys.dm_os_performance_counters
WHERE object_name LIKE '%Availability Replica%';
________________________________________

5. Verify Endpoint Certificates/Authentication
•	For encrypted endpoints or certificates, ensure validity and that both sides can authenticate.
•	Make sure service accounts have CONNECT permission on endpoints.
________________________________________
6. Inspect SQL Server and Cluster Logs
•	Review SQL Server error logs for related messages (look for errors about endpoint failures, networking, authentication, storage issues).
•	Check the Windows cluster logs for sign of failover, resource failures, or prolonged network partition.
________________________________________
7. Bandwidth and Latency Testing
•	If log send queue grows during peak activity, your network may be insufficient for the volume of transaction logs.
•	Consider scheduling index rebuilds or bulk operations during off-peak periods or increasing bandwidth between replicas.
________________________________________

8. Resolve the Issue
•	If you confirm a network issue, fix routing, firewall, or endpoint configuration.
•	If disk IO is slow, consider upgrading storage, resolving latency, or clearing resource bottlenecks.
•	If the problem was manual suspension, resume data movement.
•	For persistent log send queue buildup, consider temporarily removing and re-adding the replica to force resynchronization (last resort).
--******************************************************************************************************************************************************************
Quest2:
Not able to add new database in an Availability group in SQL Server. It gets added in the AG group UI, however not appearing at the secondary replica.

1. Check Error Logs and Extended Events
•	On the secondary replica, review the SQL Server error log and Windows event log for:
•	Errors related to “automatic seeding,” backup/restore failures, permissions, connectivity, or “database already exists.”

2. Validate Endpoint and AG Connectivity
•	Ensure all AG endpoints are reachable and configured correctly (default port 5022).

Check AG endpoint state:
	SELECT R.REPLICA_SERVER_NAME, R.ENDPOINT_URL,
	RS.CONNECTED_STATE_DESC, RS.LAST_CONNECT_ERROR_DESCRIPTION, 
	RS.LAST_CONNECT_ERROR_NUMBER, RS.LAST_CONNECT_ERROR_TIMESTAMP 
	FROM SYS.DM_HADR_AVAILABILITY_REPLICA_STATES RS JOIN SYS.AVAILABILITY_REPLICAS R
	ON RS.REPLICA_ID=R.REPLICA_ID
	WHERE RS.IS_LOCAL=1
	
•Test basic connectivity checks between the replicas through telent and PortQry.

3. Confirm Permissions
•	The SQL Server Service Accounts on each replica must have access to each other (must be able to log in and perform backup/restore/seed operations).

--******************************************************************************************************************************************************************
Quest3:
Failover occurs successfully in SQL Server Always-On but Databases take minutes to be accessible. 

1. Redo Queue Build-up / Recovery Queueing
When a failover happens, any outstanding changes from the transaction log (the redo queue) must be applied before a database comes online.

If the redo queue is large (from heavy workloads or slow secondaries), recovery takes longer, delaying database access.

Actions:

Query the size of the redo and log send queues:

SELECT
  AG.NAME AS AGNAME,
  DBS.DATABASE_NAME,
  ARS.SYNCHRONIZATION_STATE_DESC,
  ARS.LOG_SEND_QUEUE_SIZE,
  ARS.REDO_QUEUE_SIZE
FROM SYS.DM_HADR_DATABASE_REPLICA_STATES ARS
JOIN SYS.AVAILABILITY_GROUPS AG ON ARS.GROUP_ID = AG.GROUP_ID
JOIN SYS.DATABASES DBS ON ARS.DATABASE_ID = DBS.DATABASE_ID
WHERE ARS.IS_LOCAL = 1;

2. Secondary Replica Performance
If the secondary server has insufficient CPU, memory, or disk I/O, it cannot replay the log records quickly, slowing failover completion.

Actions:
Monitor performance on secondary during replay: CPU, disk IOPS, and latency.
Check if slow In-Memory OLTP objects or slow underlying disks are present.
Ensure both replicas (primary/secondary) have similar hardware/performance.

4. Network Latency and Throughput
Network issues can cause log shipping delays and large queues at failover.

Action: Assess network speed between replicas; ensure endpoints are not bottlenecks.

****On Windows clusters, resource DLLs typically reside in the %SystemRoot%\System32 or the SQL Server BINN folder*****

*********************Different Dlls and their description********************************************************************
hadrres.dll--
The resource DLL for Always On Availability Groups. Runs inside the WSFC Resource Host and is responsible for health monitoring, running diagnostics (like sp_server_diagnostics), and reporting state to the failover cluster.

sqlsrv.dll--
Core SQL Server engine DLL that is required for all fundamental SQL Server operations, including those used by Always On features.
sqldiag.dll	Supports the SQL Server Diagnostics component, storing health diagnostics logs related to availability group resources (SQLDIAG XEL files).

sqlconf.dll--
Required for configuring or validating SQL Server instances, including operations related to availability group settings. If missing, specific AG administration actions through SSMS or command line will fail.

wsfcres.dll-->
Windows Server Failover Cluster Resource DLL, integral for resource management and communication with SQL Server's HADR (High Availability Disaster Recovery) features.

srvauth.dll--
Supports authentication for endpoints and replication channels (used in AG communications).
sqlagtres.dll	SQL Server Agent resource DLL, involved if your AG setup includes jobs or agent monitoring in the cluster.

What Is a Quarantined Node?
A node enters the quarantined state when it leaves the cluster multiple times within a short period—typically due to:

Network instability
Hardware failures
Power issues
Transient errors

Instead of allowing the node to repeatedly rejoin and destabilize the cluster (a behavior known as flapping), the cluster quarantines it for a default period of 2 hours.

*****************************************************************************************************************************************************************

Quest4:
How to fix "Resolving" state in Always On?

When an Availability Group (AG) in SQL Server Always On goes into the resolving state, it means the cluster cannot establish which replica should own the primary role, or a necessary transition was interrupted. Databases in this state are not accessible. This mostly happens when there is communication/connectivity issue between cluster and nodes.

Here is how to troubleshoot and fix the issue:

Common Causes
Network/Node Connectivity Issues: Loss of connectivity between replicas or with the Windows Server Failover Cluster (WSFC).
Quorum or Cluster Problem: WSFC lost quorum or a majority of votes due to one or more nodes being down.
Lease Timeout: SQL Server and WSFC failed to communicate (e.g., due to IO pressure, blocking, or system resource exhaustion causing missed heartbeats).
Automatic or Manual Failover Problem: Failover was attempted but not fully completed.
Patch/Restart Event: Server maintenance, patching, or unexpected restart caused nodes to go offline.


1. Check Node and Cluster Health
Open WSFC Failover Cluster Manager and check node states. All participating nodes must be visible and online.

If nodes are down or quarantined, bring them online. Use PowerShell:


Start-ClusterNode -Name "NodeName"
Or, if in quarantine status:
Start-ClusterNode -Name "NodeName" -ClearQuarantine

2.Examine Error Logs
Check SQL Server ERRORLOG and Windows Event Logs on all participating instances for messages about "RESOLVING," lease timeouts, or cluster communication failures.
Look for messages about role transition failures, endpoint issues, or "diagnostics heartbeat is lost".

3. Restore Cluster Quorum (if lost)
If the cluster is down due to quorum loss, restore quorum (especially after multiple nodes down).

On the surviving node, you may need to force quorum:
Open Failover Cluster Manager on the node that’s up.
Right-click the cluster and select More Actions → Force Cluster Start.
After WSFC is up, ensure all nodes reconnect.

5. Manually Failover to a Healthy Replica (if needed)
If the primary is unhealthy or unreachable:
In SSMS, right-click the AG, select "Failover…" and follow the wizard to move AG primary to a healthy, synchronized secondary.

6. Restart SQL Server Service (as a last resort)
Restart the SQL Server service on the affected replica. This forces state reconciliation with WSFC, but only use if other options fail.

************************************************************************************************************************************************
Quest5:
Frequent Lease Timeouts

The lease timeout is the period the WSFC waits for a SQL Server replica to respond to a "ping" (the lease renewal) before assuming it’s unresponsive. Default: 20 seconds (10 sec lease interval × 2 renewals).

Common Causes
Network latency or packet drops between replicas
Heavy CPU or I/O load on the primary or secondary
WSFC service delays due to resource contention
Time sync issues between cluster nodes

Troubleshooting Steps
a) Check cluster logs for lease expiration events
Get-WinEvent -ProviderName Microsoft-Windows-FailoverClustering | 
    Where-Object {$_.Message -like "*lease expired*"} |
    Select TimeCreated, Message
	
b) Check SQL error log
Lease timeout occurred while processing the primary replica.

c) Review AlwaysOn health session

SELECT * 
FROM sys.dm_xe_sessions 
WHERE name = 'AlwaysOn_health';
Check system_health and AlwaysOn_health XE logs for events around the timeout timestamp.

d) Check OS resource pressure

CPU spikes: sys.dm_os_ring_buffers (type = RING_BUFFER_SCHEDULER_MONITOR)

e) Network diagnostics

Ping with timestamp: ping -t <replicaIP>

Test latency: Test-NetConnection -ComputerName <replica> -Port 5022 (AG endpoint port)
