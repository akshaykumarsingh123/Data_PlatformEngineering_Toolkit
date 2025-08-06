Index rebuild reorg and update stats only for the below tables
DBOOKRMK DBOOKLOG DBILLING DPRA DPRADET DBOOKOVPRI DBOOKAP DBOOKCOMP DCOMPNAME DHOCATLOG 

EXECUTE dbo.IndexOptimize
        @Databases = 'sunwingprod',
        @FragmentationLow = NULL,
        @FragmentationMedium = 'INDEX_REORGANIZE',
        @FragmentationHigh = 'INDEX_REBUILD_ONLINE',
        @FragmentationLevel1 = 5,
        @FragmentationLevel2 = 30,
		@Indexes ='sunwingprod.dbo.DBOOKRMK,sunwingprod.dbo.DBOOKLOG,sunwingprod.dbo.DBILLING,sunwingprod.dbo.DPRA,sunwingprod.dbo.DPRADET,
		           sunwingprod.dbo.DBOOKOVPRI,sunwingprod.dbo.DBOOKAP,sunwingprod.dbo.DBOOKCOMP,sunwingprod.dbo.DCOMPNAME,sunwingprod.dbo.DHOCATLOG'
        @UpdateStatistics = 'ALL',
        @FillFactor=90,
        @OnlyModifiedStatistics = 'Y',
        @StatisticsSample=50,
        @Resumable = 'Y',
        @LogToTable = 'Y'
		