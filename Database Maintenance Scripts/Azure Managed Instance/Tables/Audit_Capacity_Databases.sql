USE [DBA_Admin]
GO

/****** Object:  Table [dbo].[Audit_Capacity_Databases]    Script Date: 4/11/2025 10:35:11 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Audit_Capacity_Databases](
	[DatabaseName] [sysname] NOT NULL,
	[TableCount] [bigint] NOT NULL,
	[DataSize] [decimal](15, 2) NOT NULL,
	[LogSize] [decimal](15, 2) NOT NULL,
	[AllocatedMB] [decimal](15, 2) NOT NULL,
	[UtilizedMB] [decimal](15, 2) NOT NULL,
	[AuditTime] [datetime] NOT NULL
) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [PK_Audit_Capacity_Databases]    Script Date: 4/11/2025 10:35:11 AM ******/
CREATE CLUSTERED INDEX [PK_Audit_Capacity_Databases] ON [dbo].[Audit_Capacity_Databases]
(
	[DatabaseName] ASC,
	[AuditTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Audit_Capacity_Databases] ADD  DEFAULT (getdate()) FOR [AuditTime]
GO


