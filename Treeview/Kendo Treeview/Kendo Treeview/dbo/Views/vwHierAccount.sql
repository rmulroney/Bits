







CREATE view [dbo].[vwHierAccount] as

select a.AccountID, 
		a.AccountHierID as AccountParentID, 
		a.AccountName, 
		a.AccountNumber
from [dbo].[DimAccount] a 
	


union all 

select h.AccountHierID as AccountID,
		h.ParentID,
		h.[AccountName],
		h.AccountNumber
	from [dbo].[HierAccount] h
		


