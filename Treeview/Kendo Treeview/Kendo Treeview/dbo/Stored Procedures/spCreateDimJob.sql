
-- =============================================
-- Author:		Robert Mulroney
-- Create date: 2013-07-01
-- Description:	Popuplate DimJob
-- =============================================
CREATE PROCEDURE [dbo].[spCreateDimJob]
	@rebuildHier as bit = 0
AS
BEGIN



set identity_insert [HierJob] on

-- The Root Node of the Job Hierarchy
	merge [dbo].[HierJob] as target
	using
	(
	select 
		   -10 as [JobHierID]
		   ,'All Jobs' as JobName
		   ,'0-0000' as JobNumber
		   ,null as ParentId



	) as source
	on target.[JobHierID] = source.[JobHierID]
	When matched then
		Update set JobName = source.JobName
				  ,ParentId = source.ParentId
				  ,JobNumber = source.JobNumber
	when not matched then insert
	(	 
		[JobHierID]
		,[JobName]
		,[JobNumber]	     
		,[ParentId]
	)
	values
	(
		source.[JobHierID]
		,source.[JobName]
		,source.[JobNumber]
		,source.[ParentId]

	);

set identity_insert [HierJob] off

set identity_insert DimJob on
-- Add in the Unknown Member
	merge DimJob as target
	using
	(
	select 
		   -1 as JobID
		   ,'No Job' as JobName
		   ,'0-0000' as JobNumber
		   ,-10 as [JobHierID]  
		   		   
	) as source
	on target.JobID = source.JobID
	when matched then Update
		set JobName = source.JobName
		   ,JobNumber = source.JobNumber
		   ,[JobHierID] = source.[JobHierID]
	when not matched then insert
	(	 
		[JobID]
		,[JobName]	     
		,[JobNumber]
		,[JobHierID]
	)
	values
	(
		source.JobID
		,source.JobName
		,source.JobNumber
		,source.JobHierID

	);

set identity_insert DimJob off


-- Leaf Jobs
	merge DimJob as target
	using
	(

		SELECT   		   		  		  
			  a.[JobName]
			  ,a.[JobNumber]   		  
		from myobJob a
			left outer join myobJob p on  a.JobID = p.parentJobid and a.Entityid = p.Entityid 		
		where p.JobName is null
		group by a.[JobName], a.[JobNumber]  

	) as source
	on target.[JobName] = source.[JobName] --and target.[JobNumber] = source.[JobNumber]   
	--when matched then 
	--	Update set [JobName] = source.[JobName]			  
	when not matched then 
		INSERT 
			   ([JobName]
			   ,[JobNumber] )
           
		values(       
			  source.[JobName]
			,source.[JobNumber]
	);

	set identity_insert DimJob off


-- Add Parent Members to Job Hier
	merge HierJob as target
	using
	(

		SELECT 
			   p.[JobName], 
			   p.JobNumber			  		  
		  FROM [dbo].[myobJob] a 			
			inner join [dbo].[myobJob] p on a.ParentJobID = p.JobID  and A.entityID = p.entityid		  
		group by p.JobName, p.JobNumber

	) as source
	on target.[JobName] = source.[JobName]	
	when not matched then 
		INSERT 
			   ([JobName]
			   ,[JobNumber] )
           
		values(       
			 source.[JobName]
			,source.JobNumber	
	);

	
	IF @rebuildHier = 1 BEGIN
	
		-- Where the charts in each MYOB entity are different 
		-- this allocates Jobs according to 

		Declare @entity as int
		DECLARE entity_cursor CURSOR FOR 
		SELECT EntityID
		FROM myobJob
		where not EntityID is null
		GROUP BY EntityID
		ORDER BY EntityID;

		OPEN entity_cursor 

		FETCH NEXT FROM entity_cursor INTO @Entity

		WHILE @@FETCH_STATUS = 0
		BEGIN

			-- Update the Parent's of Parents.

			Update HierJob
			set ParentID = q.Parent, [SetByEntity] = @entity
			from (
				select ma.JobName as AccName, ma.JobNumber as AccNumber, H.[JobHierID] as Parent 
					,ma.ParentJobID
					from  myobJob ma
						inner join  myobJob mp on ma.ParentJobID = mp.JobId and ma.EntityID = mp.EntityID
						inner join HierJob h on mp.JobNumber = h.JobNumber and h.JobName = mp.Jobname --< MYOB uses the same [myobJob].[JobNumber] for different levels of the Job Hier, ie Assets and Balance sheet are both Job 1-0000 
					where ma.EntityID = @entity
					and ma.JobID <> mp.JobID
					and ma.ParentJobID <> 0								
			) as q
			where JobNumber = q.AccNumber			
			and q.Parent <> [JobHierID]
			and coalesce(ParentID, -1) = -1


		FETCH NEXT FROM entity_cursor INTO @Entity
		END

		CLOSE entity_cursor
		DEALLOCATE entity_cursor

		
								
			update DimJob
			set JobHierID = HierID
			from ( 
					select [JobHierID] as HierID,
					[JobName] as name,
					[JobNumber] as number
					from [dbo].[HierJob]				
			) as a
			where JobNumber = a.number
			and coalesce(JobHierID, -1) = -1



			--Add parents to leaf nodes
			update DimJob 
			set JobHierID = parent
			from ( 
	
				 select a.Jobname as accName, a.JobNumber as accNumber, h.JobHierID as parent
				 from MyobJob a 
					inner join MyobJob p on a.ParentJobID = p.JobID and a.entityid = p.entityid
					inner join HierJob h on h.JobName = p.JobName and p.JobNumber = h.JobNumber
				
				) as q
			WHERE q.AccNumber = JobNumber
			and coalesce(JobHierID, -1) = -1
	END

		Update DimJob
		set [JobHierID] = -10
		where [JobHierID] is null

		Update HierJob
		set ParentID = -10
		where Parentid is null and JobHierID <> -10




END


