EXECUTE dbo.IndexOptimize
        @Databases = 'WestJetTTS',
        @FragmentationLow = NULL,
        @FragmentationMedium = 'INDEX_REORGANIZE',
        @FragmentationHigh = 'INDEX_REBUILD_ONLINE',
        @FragmentationLevel1 = 5,
        @FragmentationLevel2 = 30,
		@UpdateStatistics = 'ALL',
        @FillFactor=90,
        @OnlyModifiedStatistics = 'Y',
        @StatisticsSample=50,
        @Resumable = 'Y',
        @LogToTable = 'Y'
		