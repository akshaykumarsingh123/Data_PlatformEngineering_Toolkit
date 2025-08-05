SELECT  UPPER(@@SERVERNAME)                             AS  [Cluster Name],
        UPPER(NodeName)                                 AS  [Node Name],
        CASE UPPER(NodeName)
          WHEN UPPER(CAST(SERVERPROPERTY('ComputerNamePhysicalNetBIOS')
            AS VARCHAR)) THEN 'Active'
          ELSE 'Passive'
        END                                             AS  [Node Role],
        CASE SERVERPROPERTY( 'IsClustered' )
          WHEN 1 THEN 'Clustered'
          WHEN 0 THEN 'Not Clustered'
          ELSE 'Unknonwn'
        END                                             AS  [Is Clustered?],
        CASE SERVERPROPERTY( 'IsHadrEnabled' )
          WHEN 1 THEN 'Yes'
          WHEN 0 THEN 'No'
          ELSE 'Unknonwn'
        END                                             AS  [Availability Group?]
  FROM  sys.dm_os_cluster_nodes
  ORDER BY NodeName;