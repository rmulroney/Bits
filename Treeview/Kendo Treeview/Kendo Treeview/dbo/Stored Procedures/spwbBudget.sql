

-- =============================================
-- Author:		Robert Mulroney - Calumo Australia
-- Create date: 2012-07-03
-- Description:	Budget Write Back for Summit Care
-- =============================================
CREATE PROCEDURE [dbo].[spwbBudget]
	-- Add the parameters for the stored procedure here
	@DateMonth  Varchar(Max),
	@Version Varchar(Max),
	@Entity Varchar(Max),
	@Account Varchar(Max),
	@RelativePeriod varchar(max),
	@WBValue float
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	/*

	Declare @DateMonth  Varchar(Max),
	@Version Varchar(Max),
	@Entity Varchar(Max),
	@Account Varchar(Max),
	@RelativePeriod varchar(max),
	@WBValue float

	select   @DateMonth=N'0||201306',@Version=N'2',@Entity=N'1',@Account=N'0||-7836',@RelativePeriod=N'0',@WBValue=N'63'
	*/

Create table #DateMonth	 ([dateid] varchar(max)) 
Create table #Version (versionID varchar(max))
Create table #Entity (entityID varchar(max))
Create table #Account (AccountID varchar(max))
Create table #RelativePeriod (RelativePeriodID varchar(max))



Declare @CountMonth int, 
		@CountVersion  int, 
		@CountEntity  int, 
		@CountAccount  int,
		@BadRelativePeriod  as varchar(max),
		@BadVersion as varchar(max),

		@TargetLine bigint, 
		@TargetCostCenter as varchar(50),
		@TargetYr as int


-- Get the Dimension Attributes we're writing too.

if @DateMonth ='0' BEGIN
	insert into #DateMonth
	select [dateId]
	from [dbo].[vwDimDate]
END ELSE BEGIN
	insert into #DateMonth
	select * 
	from  dbo.[fnSplitParameters2](@DateMonth,'||')
	where [Value] <>'0'
END

if @Version ='0' BEGIN
	insert into #version
	select [VersionID]
	from [dbo].[vwDimVersion]
	
END ELSE BEGIN
	insert into #Version
	select * 
	from  dbo.[fnSplitParameters2](@Version,'||')
	where [Value] <>'0'
END 

IF @Entity ='0' BEGIN
	insert into #Entity
	select [nodeID]
	from [dbo].[vwDimEntity]
END ELSE BEGIN
	insert into #Entity
	select * 
	from  dbo.[fnSplitParameters2](@Entity,'||')
	where [Value] <>'0'
END 

if @Account ='0' BEGIN
	insert into #Account
	select [nodeId]
	from [dbo].[vwDimAccount]
END ELSE BEGIN
	insert into #Account
	select * 
	from  dbo.[fnSplitParameters2](@Account,'||')
	where [Value] <>'0'
END 

-- Clear off the Summary Account Levels
Delete from #Account
where Accountid not in (
	select AccountID from DimAccount )



if @RelativePeriod ='0' BEGIN
	insert into #RelativePeriod
	select RelativePeriodID 
	from [dbo].[vwRelativePeriod]
	where [RelativePeriodType] = 'Current Period'

END ELSE BEGIN
	insert into #RelativePeriod
	select * 
	from  dbo.[fnSplitParameters2](@RelativePeriod,'||')
	where [Value] <>'0'
END 


-- Test Writeback Dimensions

Select  @CountMonth = count(*) from #datemonth	 
Select  @CountVersion = count(*) from #Version
Select  @CountEntity = count(*) from #Entity
Select  @CountAccount = count(*) from #Account

IF @CountMonth > 1 BEGIN
	RAISERROR('Writeback may only be preformed against a single Month.', 16, 1)
	return 
END ELSE IF @CountVersion > 1 BEGIN
	RAISERROR('Writeback may only be preformed against a single Version.', 16, 1)
	return 
END ELSE IF @CountEntity > 1 BEGIN
	RAISERROR('Writeback may only be preformed against a single Entity.', 16, 1)
	return 
END ELSE IF @CountAccount < 1 BEGIN
	RAISERROR('Writeback cannot be preformed against a Summary Account with no Children.', 16, 1)
	return 
END 

-- Check Appropriate Dimensions

select @BadRelativePeriod = '', @BadVersion   = ''

select  'Writeback can only be performed against the "Current" Relative Period, "' + convert(Varchar(50), dr.[RelativePeriodType]) + '" has been selected.' 
from  #RelativePeriod tr
	inner join [dbo].[vwRelativePeriod] dr on tr.[RelativePeriodID] = dr.[RelativePeriodID]
where tr.[RelativePeriodID] <> 1


IF @BadRelativePeriod <> '' BEGIN
	RAISERROR(@BadRelativePeriod, 16, 1)
END

select @BadVersion  = 'Writeback cannot be preformed against version "' + convert(Varchar(50), dv.[VersionType]) + '".' 
from  #version tv
	inner join [dbo].[DimVersion] dv on tv.versionID = dv.VersionID
where coalesce(AllowsWriteback, -1) <> 1

IF @BadVersion <> '' BEGIN
	RAISERROR(@BadVersion, 16, 1)
END



-- Merge in the new Writeback

merge [dbo].[wbFactBudget] as target using
(
	select 
		convert(int, convert(varchar(6), [dateid]) + '01') as DateID -- first day of the month
		,convert(int, versionID) as VersionID
		,convert(int, entityID) as EntityID
		,convert(int, AccountID) as AccountID
		,convert(float, @WBValue) / @CountAccount as WB		
	from #DateMonth	
		cross join #Version 
		cross Join #Entity 
		cross join #Account 
) as source 
on source.dateId = target.[TransactionDate]
	and source.versionID = target.versionID 
	and source.entityID = target.entityID 
	and source.AccountID = target.AccountID

when matched then 
	Update set target.[JournalAmount] = source.wb

when not Matched then

	INSERT  ([TransactionDate]
        ,[AccountID]
        ,[EntityID]
        ,[VersionID]
		,[JournalAmount])
    VALUES
        (source.[dateid]
		,source.AccountID		 
		,source.entityID 
		,source.versionID
		,source.WB		);
	

drop table #DateMonth
drop table #Version
drop table #Entity 
drop table #Account 
drop table #RelativePeriod 



END
