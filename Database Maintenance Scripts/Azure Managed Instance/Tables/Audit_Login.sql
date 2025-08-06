USE [DBA_Admin]
GO

/****** Object:  Table [dbo].[Audit_Login]    Script Date: 4/11/2025 10:37:35 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[Audit_Login](
	[Target] [varchar](100) NOT NULL,
	[Source] [varchar](100) NOT NULL,
	[LoginInfo] [varchar](100) NOT NULL,
	[DBname] [varchar](100) NOT NULL,
	[Program] [varchar](300) NOT NULL,
	[LoginTime] [datetime] NOT NULL,
	[AuditTime] [datetime] NOT NULL,
	[HostProcess] [int] NOT NULL
) ON [PRIMARY]
GO

SET ANSI_PADDING OFF
GO


