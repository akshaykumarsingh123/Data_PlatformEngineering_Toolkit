# SQL Server Always On - Common Problems and Troubleshooting Guide

## 1. Permission Issues for Service Accounts
**Problem:**  
Missing permissions for the SQL Server service account or the WSFC service account can cause Availability Group (AG) creation, failover, or online failures.

**Symptoms:**
- Error: "Failed to bring availability group online."
- Related errors in SQL Server Error Log or WSFC logs.

**DMVs to Check:**
- `sys.dm_hadr_availability_group_states`
- `sys.dm_hadr_availability_replica_states`
- `sys.dm_server_permissions`

**Columns & Values:**
- `principal_name` (check for NT AUTHORITY\SYSTEM, SQL service accounts)
- `permission_name` (ALTER ANY AVAILABILITY GROUP, CONNECT SQL, VIEW SERVER STATE)

**Resolution:**
```sql
GRANT ALTER ANY AVAILABILITY GROUP TO [NT AUTHORITY\SYSTEM];
GRANT CONNECT SQL TO [NT AUTHORITY\SYSTEM];
GRANT VIEW SERVER STATE TO [NT AUTHORITY\SYSTEM];
```

---

## 2. Network Connectivity Issues Between Replicas
**Problem:**  
Network latency, firewall blocking, or DNS resolution issues prevent data movement between replicas.

**Symptoms:**
- Synchronization state shows DISCONNECTED in `sys.dm_hadr_availability_replica_states`.
- WSFC Cluster logs show heartbeat failures.

**DMVs to Check:**
- `sys.dm_hadr_availability_replica_states` (connected_state_desc should be 'CONNECTED')
- `sys.dm_exec_connections` (check net_transport and client_net_address)

**Resolution:**
- Verify ping/DNS resolution between replicas.
- Check firewall rules for port 5022 (default endpoint port).
- Use `telnet` or `Test-NetConnection` to verify port connectivity.

---

## 3. Database Not Synchronizing (Data Movement Suspended)
**Problem:**  
A replica shows as "Not Synchronizing" or "Data Movement Suspended" due to log send queue buildup.

**Symptoms:**
- `log_send_queue_size` > 0 for prolonged time.
- `synchronization_state_desc` not 'SYNCHRONIZED' (for synchronous replicas).

**DMVs to Check:**
- `sys.dm_hadr_database_replica_states` (log_send_queue_size, redo_queue_size)
- `sys.dm_os_performance_counters` (Log Bytes Sent/sec, Redo Bytes/sec)

**Resolution:**
- Check disk space and I/O latency on replicas.
- Resume data movement:
```sql
ALTER DATABASE [DBName] SET HADR RESUME;
```

---

## 4. Automatic Failover Not Happening
**Problem:**  
Even when the primary goes down, the failover does not occur.

**Symptoms:**
- Failover mode is set to MANUAL for synchronous replicas.
- WSFC quorum or vote misconfiguration.

**DMVs to Check:**
- `sys.availability_replicas` (failover_mode_desc should be 'AUTOMATIC' for HA replicas)
- `sys.dm_hadr_availability_group_states` (primary_replica)

**Resolution:**
- Configure failover mode to AUTOMATIC for both primary and synchronous replica.
- Check WSFC quorum configuration:
```powershell
Get-ClusterQuorum
```

---

## 5. WSFC Cluster Resource Failures
**Problem:**  
WSFC resource dependencies or cluster service issues cause the AG resource to fail.

**Symptoms:**
- Cluster log shows resource failures.
- SQL Error log shows failed attempts to bring AG online.

**DMVs to Check:**
- `sys.dm_hadr_availability_group_states`
- `sys.dm_hadr_cluster`

**Resolution:**
- Review WSFC Cluster logs:
```powershell
Get-ClusterLog -UseLocalTime
```
- Restart Cluster Service if required.
- Ensure correct dependencies (e.g., Listener depends on AG, AG depends on SQL Server service).
