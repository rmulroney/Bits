
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Robert Mulroney
-- Create date: 2012-06-21
-- Description:	Takes Duplicate codes and makes them unquie
-- =============================================
CREATE PROCEDURE spFixDuplicateCustomerCode
	
AS
BEGIN
	/*
UPDATE [stg].[TimeSheetActuals]
SET [Customer_CustomerCode] = newcust
	,[project_projectCode] = replace([project_projectCode], oldcust, newcust)
from (
	select oldCust
		,custDesc
		,left(oldCust, 5) + case when len(convert(varchar(2), rnk)) = 1 then '0' else '' end + convert(varchar(2), rnk) as newCust
	from (
		select Rank() over (PARTITION BY t1.custID  order by t2.[desciption]) +10 as Rnk
			,t1.custID as oldCust, Min(t1.[desciption]) as custDescR
			,t2.[desciption] AS custDesc
		from [stg].TimeSheetCustomer t1
			inner join [stg].TimeSheetCustomer  t2 on t1.custid = t2.custid and t1.[desciption] <> t2.[Desciption]
		group by t1.custID, t2.custid, t2.[desciption]
	) as A 
) as b
where b.custDesc = Customer_Name
*/

select 1

END
GO
