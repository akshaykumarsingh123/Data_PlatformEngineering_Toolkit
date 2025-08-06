USE [DBA_Admin]
GO

/****** Object:  Table [dbo].[Audit_Capacity_Tables]    Script Date: 4/11/2025 10:36:57 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Audit_Capacity_Tables](
	[DatabaseName] [sysname] NOT NULL,
	[TableName] [sysname] NOT NULL,
	[RowCount] [bigint] NOT NULL,
	[TotalMB] [decimal](15, 2) NOT NULL,
	[UsedMB] [decimal](15, 2) NOT NULL,
	[UnusedMB] [decimal](15, 2) NOT NULL,
	[AuditTime] [datetime] NOT NULL
) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [PK_Audit_Capacity_Tables]    Script Date: 4/11/2025 10:36:58 AM ******/
CREATE CLUSTERED INDEX [PK_Audit_Capacity_Tables] ON [dbo].[Audit_Capacity_Tables]
(
	[DatabaseName] ASC,
	[TableName] ASC,
	[AuditTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Audit_Capacity_Tables] ADD  DEFAULT (getdate()) FOR [AuditTime]
GO


