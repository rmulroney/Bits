-- =============================================
-- Author:		Robert Mulroney
-- Create date: 2013-07-03
-- Description:	Add Opening Account Balances to the GL Fact Table
-- =============================================
CREATE PROCEDURE  [dbo].[spBuildOpeningBalances]
	
	
-- This date should be equivilent to the balance data for the Account balances in the 
--		[myobAccount].[ThisYearOpeningBalance] column

	@openingBalanceDate datetime = null
AS
BEGIN

Declare @d as int


if @openingBalanceDate is null 
	select  @openingBalanceDate  = convert(Datetime, '2004-06-30', 102) 
	
select @d = [dateId]
from [dbo].[DimDate] 
where [date] = @openingBalanceDate


delete from [dbo].[FactOpeningBal]

INSERT INTO [dbo].[FactOpeningBal]
           ([TransactionDate]
           ,[AccountID]
           ,[JournalAmount]
		   ,[JobID]
           ,[EntityID]
           ,[VersionID]
           ,[JournalDesc]
           ,[TransactionNumber])
Select @d
	   ,a.AccountID
	   --,f.ThisYearOpeningBalance * case when f.isCreditBalance = 'Y' then -1 else  1 end
	   ,f.[OpeningAccountBalance] * case when f.isCreditBalance = 'Y' then -1 else  1 end
	   ,-1 as Job
	   ,f.EntityID
	   ,v.VersionID
	   ,'Opening Balance'
	   ,'OB'
from myobAccount f
	left outer join myobAccount p on  f.AccountID = p.parentAccountid and f.Entityid = p.Entityid -- we only want non-Parent Accounts	
	left outer Join [dbo].[DimAccount] as a on f.AccountNumber + ' - ' + f.AccountName = a.AccountName
	left outer Join DimVersion v on v.VersionType = 'GL Actual'
where p.accountName is null


END

/****** Object:  UserDefinedFunction [dbo].[fnSplitParameters2]    Script Date: 9/07/2013 3:37:03 PM ******/
SET ANSI_NULLS ON
