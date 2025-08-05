EXECUTE dbo.IndexOptimize
@Databases = 'OlaMaintenance',
@FragmentationLow = NULL,
@FragmentationMedium = 'INDEX_REORGANIZE',
@FragmentationHigh = 'INDEX_REBUILD_ONLINE',
@FragmentationLevel1 = 5,
@FragmentationLevel2 = 30,
@UpdateStatistics = 'ALL',
@OnlyModifiedStatistics = 'Y',
@MaxDOP = 0, -- using all available CPU cores
@Resumable = 'Y',
--@SortInTempdb = 'Y', --either resumable or sort_in_tempdb can be used at a time
@LogToTable = 'Y',
@Indexes = 'ALL_INDEXES, -OlaMaintenance.HumanResources.Department'

select * from [dbo].[CommandLog]


--Large Tables
EXECUTE dbo.IndexOptimize
@Databases = 'OlaMaintenance',
@objects = 'OlaMaintenance.Person.Address,OlaMaintenance.HumanResources.Department,OlaMaintenance.Person.Person',
@FragmentationMedium = 'INDEX_REORGANIZE',
@FragmentationHigh = 'INDEX_REBUILD_ONLINE',
@UpdateStatistics = 'ALL',
@OnlyModifiedStatistics = 'Y',
@MaxDOP = 0






