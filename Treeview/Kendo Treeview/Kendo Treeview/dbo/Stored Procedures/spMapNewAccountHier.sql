
-- =============================================
-- Author:		Robert Mulroney
-- Create date: 2013-07-05
-- Description:	Restructure Account hier
-- =============================================

CREATE PROCEDURE [dbo].[spMapNewAccountHier]
	@AccountName as varchar(max),
	@Parent as varchar(max)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

IF rtrim(@AccountName) = '' BEGIN
	Raiserror('(blank) is not a valid account name.', 16, 1)
	return -1

END



   declare @ParentID as int,
			@flag as int

	-- Extract Parent Account Number.
	select @ParentID =  
		substring(
			@Parent, 
			Patindex('%&[[]%]', @Parent ) + 2,
			len(@Parent) - Patindex('%&[[]%]', @Parent) - 2			
		) 



-- Prevent Leaf Nodes from becoming Parents

IF @ParentID > 0 BEGIN
	Raiserror('Natural accounts cannot be made parents Account hierarchy.', 16, 1)
	return -1
END

-- Test to see if our new account exists
IF @AccountName in (select Accountname From [dbo].[vwHierAccount]) BEGIN
	Raiserror('An Account with this name already exists.', 16, 1)
	return -1
END



INSERT INTO [dbo].[HierAccount]
           ([AccountName]
           ,[AccountNumber]
           ,[ParentID])
     VALUES
           (@AccountName
           ,''
           ,@ParentID)

exec [dbo].[spProcessAccountDim]

END

