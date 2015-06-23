-- =============================================
-- Author:		Robert Mulroney
-- Create date: 2013-07-02
-- Description:	Create DimVersionData
-- =============================================
CREATE PROCEDURE [dbo].[spCreateDimVersion]
	
AS
BEGIN
	


	merge [dbo].[DimVersion] as target
	using
	(
		
		select 1 as VersionID, 'GL Actual' as VersionType
			union 
		select 2 as VersionID, 'GL Budget' as VersionType
			union
		select 3 as VersionID, 'GL Forecast' as VersionType

	) as source
	on target.VersionID = source.VersionID
	When matched then
		Update set versionType = source.VersionType
				  
	when not matched then insert
	(	 
		VersionID, 
		VersionType
	)
	values
	(
		source.VersionID,
		source.VersionType		
	);


END

