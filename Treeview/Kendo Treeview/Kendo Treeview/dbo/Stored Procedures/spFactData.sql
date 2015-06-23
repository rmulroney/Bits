



-- =============================================
-- Author:		Robert Mulroney
-- Create date: 2012-07-02
-- Description:	Populate FactData
-- =============================================
CREATE PROCEDURE [dbo].[spFactData]
	@openingBalanceDate datetime = null
	
AS
BEGIN
	
	declare @d as int

--MYOB Clears it's Balance date as the year rolls so make sure we're getting the ones after the opening balance.
	if @openingBalanceDate is null 
		select  @openingBalanceDate  = convert(Datetime, '2004-06-30', 102) 

	select @d = [dateId]
	from [dbo].[DimDate] 
	where [date] = @openingBalanceDate

-- Clear out the Fact Data in the current extract range.
	declare @startDate as int,
			@endDate as int
	
	select @startDate  = MIN(d.dateid),
			@endDate  = max(d.dateid) 
	from [dbo].[myobJournalRecords] j
		inner join [dbo].[DimDate] d on j.[TransactionDate] = d.[date]		

	delete from [dbo].[FactJournal]
	where [TransactionDate] between @StartDate and  @endDate


	delete from myobJournalRecords
	where year(transactionDate) > 2020
	
-- Insert Fact Data
	INSERT INTO [dbo].[factJournal](           
            [TransactionDate]
           ,[AccountID]
           ,[JournalAmount]
		   ,[JobID]           
           ,[EntityID]
		   ,[VersionID]
		   ,[JournalDesc]
		   ,[TransactionNumber])	
		SELECT 	            
		    coalesce(d.[dateId], -1)
		   ,coalesce(Case when acc.AccountID < -1 then -1 else acc.AccountID end, -2) as [AccountID]
		   ,mf.[TaxExclusiveAmount]
		   ,coalesce(j.[jobID], -1) as [JobID]
		   ,coalesce(mf.[EntityID], -2) as [EntityID]
		   ,1 as VersionID
		   ,[Memo]
		   ,[TransactionNumber]
		 from [dbo].[myobJournalRecords] mf
			left outer join [dbo].[myobJournalSets] ms on ms.SetID = mf.SetID and ms.EntityID = mf.EntityID
			left outer Join myobAccount ma on mf.accountID = ma.AccountID and mf.entityID = ma.entityID
			left outer Join [dbo].[DimAccount] as acc on ma.AccountNumber + ' - ' + ma.AccountName = acc.AccountName
			left outer Join myobJob mj on mf.JobID = mj.JobID and mf.EntityID = mj.EntityID
			left outer join DimJob j on mj.JobName = j.JobName and mj.JobNumber = j.JobNumber
			left outer join [dbo].[DimDate] d on d.[date] = mf.[TransactionDate]
		where d.[dateId] > @d





/*
		select * from dimAccount
		where accountID  in (
			select [nodeId] from [dbo].[vwDimAccount] )


		select * from dimAccount
		where accountname = 'Dividend Paid'

		select * from hierAccount
		where accountname = 'Dividend Paid'

		select * from [dbo].[vwDimAccount]
		where nodedesc like 'Dividend Paid'
		
		select * from [dbo].[vwHierAccount]
		where AccountID = 3734

		select * from [dbo].[vwHierAccount]
		where AccountID = -6144

		select * from [dbo].[vwHierAccount]
		where AccountID = -6131

		select * from [dbo].[vwHierAccount]
		where AccountID = -6115

		
		select * from [dbo].[vwHierAccount]
		where AccountID = -6234

		select * from [dbo].[vwHierAccount]
		where AccountID = -6265


		select * from [dbo].[vwHierAccount]
		where accountParentID = -10
		


	select a.AccountName, p.Accountname from myobAccount a
		inner join myobAccount p on a.parentAccountID = p.AccountID and p.EntityID = a.EntityID
	where a.Accountname = 'Operating Expenses'

	select a.AccountName, p.Accountname from myobAccount a
		inner join myobAccount p on a.parentAccountID = p.AccountID and p.EntityID = a.EntityID
	where a.Accountname = 'Other Expenses'



	select * from [dbo].[vwHierAccount]
		where accountname like 'Net%'

		select * from hierAccount
		where accountname like 'Net Profit / (Loss)'
		

		update hierAccount
		set ParentID = -6265
		where [AccountHierID] = -6234

		update dimAccount set [AccountHierID] = -6144
		where accountID = 3734
		*/
END





