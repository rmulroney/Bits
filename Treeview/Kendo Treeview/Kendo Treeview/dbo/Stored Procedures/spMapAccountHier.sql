-- =============================================
-- Author:		Robert Mulroney
-- Create date: 2013-07-05
-- Description:	Restructure Account hier
-- =============================================

CREATE PROCEDURE [dbo].[spMapAccountHier]
	@AccountID as varchar(max),
	@NewParent as varchar(max)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;



   declare @ChildID as int,
			@ParentID as int,
			@flag as int

	-- Extract our Account Numbers.
	select @ChildID =  
		substring(
			@AccountID, 
			Patindex('%&[[]%]', @AccountID ) + 2,
			len(@AccountID) - Patindex('%&[[]%]', @AccountID) - 2			
		) 

	select @ParentID =  
		substring(
			@NewParent, 
			Patindex('%&[[]%]', @NewParent ) + 2,
			len(@NewParent) - Patindex('%&[[]%]', @NewParent) - 2			
		) 

-- Prevent Leaf Nodes from becoming Parents

IF @ParentID > 0 BEGIN

	Raiserror('Natural accounts cannot be made parents Account hierarchy. Create a new account.', 16, 1)
	return -1
END

IF @ParentID = @ChildID BEGIN
	Raiserror('Accounts cannot be made thier own Parents.', 16, 1)
	return -1
END

-- Test to see if our new parent will cause a recurrsive loop.

declare @AncestorAccounts as table (AccountId int)
declare @LastAncestor as int	

select @flag =0, @LastAncestor = @ParentID

insert into @AncestorAccounts
		select @ChildID


WHILE @flag = 0 BEGIN



	select @LastAncestor = [AccountParentID]
	from [dbo].[vwHierAccount]
	where AccountID = @LastAncestor
	

	if @LastAncestor in (select Accountid from @AncestorAccounts) begin
		select @Flag = -1 --Fail
	END ELSE IF @LastAncestor  is null BEGIN
		select @Flag = 1 -- Success
	END ELSE BEGIN
		insert into @AncestorAccounts
		select @LastAncestor
	END


END

IF @Flag < 0 BEGIN
	Raiserror('Accounts cannot be made thier own ancestor.', 16, 1)
	return -1

END ELSE IF @ChildID = -1 or @ChildID = -10  BEGIN 
	Raiserror('This account is protected and cannot be moved in the Account hierarchy.', 16, 1)
	return -1

END ELSE IF @ChildID < 0 BEGIN 
	Update HierAccount
	set [ParentID] = @ParentID
	where [AccountHierID] = @ChildID
	
	exec spProcessAccountDim

END ELSE IF @ChildID > 0 BEGIN 
	Update DimAccount
	set [AccountHierID] = @ParentID
	where AccountID = @ChildID

	exec spProcessAccountDim
END else BEGIN

declare @e as varchar(100)
select @e = 'Child Account not found.'
	Raiserror(@e, 16, 1)
	return -1

END


END

