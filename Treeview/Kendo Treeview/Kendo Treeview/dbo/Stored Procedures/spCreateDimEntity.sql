
-- =============================================
-- Author:		Robert Mulroney
-- Create date: 2013-07-02
-- Description:	Create DimEntity Data
-- =============================================
CREATE PROCEDURE [dbo].[spCreateDimEntity]
	
AS
BEGIN
	
	
set identity_insert [HierEntity] on

-- The Root Node of the Entity Hierarchy
	merge [dbo].[HierEntity] as target
	using
	(
	select 
		   -10 as [EntityHierID]
		   ,'Consolidated' as EntityName		
		   ,null as ParentId

	

	) as source
	on target.[EntityHierID] = source.[EntityHierID]
	When matched then
		Update set EntityName = source.EntityName
				  ,ParentId = source.ParentId
				  
	when not matched then insert
	(	 
		[EntityHierID]
		,[EntityName]
		
		,[ParentId]
	)
	values
	(
		source.[EntityHierID]
		,source.[EntityName]
		,source.[ParentId]

	);

set identity_insert [HierEntity] off



	merge [dbo].[DimEntity]as target
	using
	(
		
		select [CompanyName], EntityID from [dbo].[myobDataFileInformation]
		group by [CompanyName], EntityID 

		union 
		select 'Unknown Company' as [CompanyName], -1 as EntityID 

	) as source
	on target.EntityID = source.EntityID
	When matched then
		Update set [EntityName] = source.[CompanyName]
				  
	when not matched then insert
	(	 
		EntityID, 
		[EntityName],
		[ParentEntityID]
	)
	values
	(
		source.EntityID,
		source.[CompanyName],
		-10
	);


END


