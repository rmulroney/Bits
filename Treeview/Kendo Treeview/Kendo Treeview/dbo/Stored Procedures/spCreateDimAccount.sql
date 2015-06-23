

-- =============================================
-- Author:		Robert Mulroney
-- Create date: 2013-07-01
-- Description:	Populate DimAccount
-- =============================================
CREATE PROCEDURE [dbo].[spCreateDimAccount]
	@rebuildHier as bit = 0
AS
BEGIN


set identity_insert [HierAccount] on

-- The Root Node of the Account Hierarchy
	merge [dbo].[HierAccount] as target
	using
	(
	select 
		   -10 as [AccountHierID]
		   ,'Trial Balance' as AccountName
		   ,'0-0000' as AccountNumber
		   ,null as ParentId

		   union  all 

	select  -1 as [AccountHierID]
		   ,'Unmapped Account' as AccountName
		   ,'0-0000' as AccountNumber
		   ,-10  as ParentId


	) as source
	on target.[AccountHierID] = source.[AccountHierID]
	When matched then
		Update set AccountName = source.AccountName
				  ,ParentId = source.ParentId
				  ,AccountNumber = source.AccountNumber
	when not matched then insert
	(	 
		[AccountHierID]
		,[AccountName]
		,[AccountNumber]	     
		,[ParentId]
	)
	values
	(
		source.[AccountHierID]
		,source.[AccountName]
		,source.[AccountNumber]
		,source.[ParentId]

	);

set identity_insert [HierAccount] off

set identity_insert DimAccount on
-- Add in the Unknown Member
	merge DimAccount as target
	using
	(
	select 
		   -2 as AccountID
		   ,'Unknown Account' as AccountName
		   ,'0-0000' as AccountNumber
		   ,-1 as [AccountHierID]  
	) as source
	on target.AccountID = source.AccountID
	when matched then Update
		set AccountName = source.accountName
		   ,AccountNumber = source.AccountNumber
		   ,[AccountHierID] = source.[AccountHierID]
	when not matched then insert
	(	 
		[AccountID]
		,[AccountName]	     
		,[AccountNumber]
		,[AccountHierID]
	)
	values
	(
		source.AccountID
		,source.AccountName
		,source.AccountNumber
		,source.AccountHierID

	);

set identity_insert DimAccount off


-- Leaf Accounts
	merge DimAccount as target
	using
	(

		SELECT   		   		  		  
			  a.[AccountName]
			  ,a.[AccountNumber]   		  
		from myobAccount a
			left outer join myobAccount p on  a.AccountID = p.parentAccountid and a.Entityid = p.Entityid 		
		where p.accountName is null
		group by a.[AccountName], a.[AccountNumber]  

	) as source
	on target.[AccountName] = source.[AccountName] --and target.[AccountNumber] = source.[AccountNumber]   
	--when matched then 
	--	Update set [AccountName] = source.[AccountName]			  
	when not matched then 
		INSERT 
			   ([AccountName]
			   ,[AccountNumber] )
           
		values(       
			  source.[AccountNumber] + ' - ' +source.[AccountName]
			,source.[AccountNumber]
	);

	set identity_insert DimAccount off


-- Add Parent Members to Account Hier
	merge HierAccount as target
	using
	(

		SELECT 
			   p.[AccountName], 
			   p.accountNumber			  		  
		  FROM [dbo].[myobAccount] a 			
			inner join [dbo].[myobAccount] p on a.ParentAccountID = p.AccountID  and A.entityID = p.entityid		  
		group by p.AccountName, p.accountNumber


	) as source
	on target.[AccountName] = source.[AccountName]	
	when not matched then 
		INSERT 
			   ([AccountName]
			   ,[AccountNumber] )
           
		values(       
			 source.[AccountName]
			,source.accountNumber	
	);

	
	IF @rebuildHier = 1 BEGIN
	
		-- Where the charts in each MYOB entity are different 
		-- this allocates accounts according to 

		Declare @entity as int
		DECLARE entity_cursor CURSOR FOR 
		SELECT EntityID
		FROM myobAccount
		where not EntityID is null
		GROUP BY EntityID
		ORDER BY EntityID;

		OPEN entity_cursor 

		FETCH NEXT FROM entity_cursor INTO @Entity

		WHILE @@FETCH_STATUS = 0
		BEGIN

			-- Update the Parent's of Parents.

			Update HierAccount
			set ParentID = q.Parent, [SetByEntity] = @entity
			from (
				select ma.AccountName as AccName, ma.AccountNumber as AccNumber, H.[AccountHierID] as Parent 
					,ma.ParentAccountID
					from  myobAccount ma
						inner join  myobAccount mp on ma.ParentAccountID = mp.AccountId and ma.EntityID = mp.EntityID
						inner join HierAccount h on mp.AccountNumber = h.AccountNumber and h.AccountName = mp.accountname --< MYOB uses the same [myobaccount].[accountNumber] for different levels of the account Hier, ie Assets and Balance sheet are both account 1-0000 
					where ma.EntityID = @entity
					and ma.AccountID <> mp.AccountID
					and ma.ParentAccountID <> 0								
			) as q
			where AccountNumber = q.AccNumber			
			and q.Parent <> [AccountHierID]
			and coalesce(ParentID, -1) = -1


		FETCH NEXT FROM entity_cursor INTO @Entity
		END

		CLOSE entity_cursor
		DEALLOCATE entity_cursor

		
								
			update DimAccount
			set AccountHierID = HierID
			from ( 
					select [AccountHierID] as HierID,
					[AccountName] as name,
					[AccountNumber] as number
					from [dbo].[HierAccount]				
			) as a
			where AccountNumber = a.number
			and coalesce(AccountHierID, -1) = -1



			--Add parents to leaf nodes
			update DimAccount 
			set AccountHierID = parent
			from ( 
	
				 select a.Accountname as accName, a.AccountNumber as accNumber, h.AccountHierID as parent
				 from MyobAccount a 
					inner join MyobAccount p on a.ParentAccountID = p.AccountID and a.entityid = p.entityid
					inner join HierAccount h on h.AccountName = p.AccountName and p.accountNumber = h.accountNumber
				
				) as q
			WHERE q.AccNumber = AccountNumber
			and coalesce(AccountHierID, -1) = -1
	END

		Update DimAccount
		set [AccountHierID] = -1
		where [AccountHierID] is null

		Update HierAccount
		set ParentID = -10
		where Parentid is null and AccountHierID <> -10


END


