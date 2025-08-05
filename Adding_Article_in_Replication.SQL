
1. Rename the current production table 'MrkContactPreference' to 'MrkContactPreference_BKP'

-- To check the current value for 'Allow_Anonymous' and 'Immediate_Sync' parameters
use SoftripNetVE
go
sp_helppublication

**We need to set these parameters 'Allow_Anonymous' and 'Immediate_Sync' to false so that snapshot agent will not generate the snapshot for all the articles, rather
snapshot of the newly created article would be generated.**

2a --Set Allow_Anonymous to false for ATL_YYZ
use SoftripNetVE
go
EXEC sp_changepublication 
@publication = 'ATL_YYZ', 
@property = 'allow_anonymous' , 
@value = 'false' 
GO 

2b --Set Immediate_Sync to false for ATL_YYZ
use SoftripNetVE
go
EXEC sp_changepublication 
@publication = 'ATL_YYZ', 
@property = 'immediate_sync' , 
@value = 'false' 
GO 

3. Add the article 'MrkContactPreference' from the properties of the publisher ATL_YYZ.

4. Run sp_helpsubscription on  publisher database to verify the 'subscription status' of the subscribed article. It will be 1 (Subscribed)
	0 = Inactive
	1 = Subscribed
	2 = Active

5. To make it active, we need to run the snapshot agent.

6. Run sp_helpsubscription again on the SoftripNetVE database, the 'subscription status' will have changed to Active, which means article is now part of the replication.