Create procedure [dbo].[spMissingAccounts]
as

SELECT A.* from myobJournalRecords j
	inner join MYOBAccount a  on a.AccountID = j.AccountID
where transactiondate = convert(datetime, '2013-01-01', 103)
and j.EntityID = 7
and accountname not in (

select Accountname from dimAccount)


