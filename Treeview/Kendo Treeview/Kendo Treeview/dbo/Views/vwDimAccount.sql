
CREATE view [dbo].[vwDimAccount] as 
WITH PCStructure
(
	Level, 
	parentId, 
	nodeID, 
	Level1, 
	Level2, 
	Level3, 
	Level4, 
	Level5, 
	Level6, 
	Level7, 
	Level8, 
	Level9, 
	Level10
)
AS (
SELECT 
	1 Level, 
	AccountParentID as parentId, 
	accountId as nodeId,
	null as Level1, 
	null as Level2, 
	null as Level3, 
	null as Level4, 
	null as Level5, 
	null as Level6, 
	null as Level7, 
	null as Level8, 
	null as Level9, 
	null as Level10	
FROM [dbo].[vwHierAccount] WHERE AccountParentID is null 
UNION ALL 
SELECT 
	Level + 1, e.AccountParentID, e.accountId, 
	CASE Level WHEN 1 THEN e.accountId ELSE Level1 END AS Level1, 
	CASE Level WHEN 2 THEN e.accountId ELSE Level2 END AS Level2, 
	CASE Level WHEN 3 THEN e.accountId ELSE Level3 END AS Level3, 
	CASE Level WHEN 4 THEN e.accountId ELSE Level4 END AS Level4, 
	CASE Level WHEN 5 THEN e.accountId ELSE Level5 END AS Level5, 
	CASE Level WHEN 6 THEN e.accountId ELSE Level6 END AS Level6, 
	CASE Level WHEN 7 THEN e.accountId ELSE Level7 END AS Level7, 
	CASE Level WHEN 8 THEN e.accountId ELSE Level8 END AS Level8, 
	CASE Level WHEN 9 THEN e.accountId ELSE Level9 END AS Level9, 
	CASE Level WHEN 10 THEN e.accountId ELSE Level10 END AS Level10	
FROM 
	[dbo].[vwHierAccount] e INNER JOIN 
	PCStructure d ON e.AccountParentID = d.nodeID)
select 
	keySubselect.*,
	Level0Subselect.nodeId	as Level0,
	Level0Subselect.nodeDesc as Level0Desc,
	coalesce(Level1Subselect.nodeId, keySubselect.nodeId) as level1, 
	coalesce(Level1Subselect.nodeDesc, keySubselect.nodeDesc) as level1Desc, 
	coalesce(Level2Subselect.nodeId, Level1Subselect.nodeId, keySubselect.nodeId) as level2, 
	coalesce(Level2Subselect.nodeDesc, Level1Subselect.nodeDesc, keySubselect.nodeDesc) as level2Desc, 
	coalesce(Level3Subselect.nodeId, Level2Subselect.nodeId, Level1Subselect.nodeId, keySubselect.nodeId) as level3, 
	coalesce(Level3Subselect.nodeDesc, Level2Subselect.nodeDesc, Level1Subselect.nodeDesc, keySubselect.nodeDesc) as level3Desc, 
	coalesce(Level4Subselect.nodeId, Level3Subselect.nodeId, Level2Subselect.nodeId, Level1Subselect.nodeId, keySubselect.nodeId) as level4, 
	coalesce(Level4Subselect.nodeDesc, Level3Subselect.nodeDesc, Level2Subselect.nodeDesc, Level1Subselect.nodeDesc, keySubselect.nodeDesc) as level4Desc, 
	coalesce(Level5Subselect.nodeId, Level4Subselect.nodeId, Level3Subselect.nodeId, Level2Subselect.nodeId, Level1Subselect.nodeId, keySubselect.nodeId) as level5, 
	coalesce(Level5Subselect.nodeDesc, Level4Subselect.nodeDesc, Level3Subselect.nodeDesc, Level2Subselect.nodeDesc, Level1Subselect.nodeDesc, keySubselect.nodeDesc) as level5Desc, 
	coalesce(Level6Subselect.nodeId, Level5Subselect.nodeId, Level4Subselect.nodeId, Level3Subselect.nodeId, Level2Subselect.nodeId, Level1Subselect.nodeId, keySubselect.nodeId) as level6, 
	coalesce(Level6Subselect.nodeDesc, Level5Subselect.nodeDesc, Level4Subselect.nodeDesc, Level3Subselect.nodeDesc, Level2Subselect.nodeDesc, Level1Subselect.nodeDesc, keySubselect.nodeDesc) as level6Desc, 
	coalesce(Level7Subselect.nodeId, Level6Subselect.nodeId, Level5Subselect.nodeId, Level4Subselect.nodeId, Level3Subselect.nodeId, Level2Subselect.nodeId, Level1Subselect.nodeId, keySubselect.nodeId) as level7, 
	coalesce(Level7Subselect.nodeDesc, Level6Subselect.nodeDesc, Level5Subselect.nodeDesc, Level4Subselect.nodeDesc, Level3Subselect.nodeDesc, Level2Subselect.nodeDesc, Level1Subselect.nodeDesc, keySubselect.nodeDesc) as level7Desc, 
	coalesce(Level8Subselect.nodeId, Level7Subselect.nodeId, Level6Subselect.nodeId, Level5Subselect.nodeId, Level4Subselect.nodeId, Level3Subselect.nodeId, Level2Subselect.nodeId, Level1Subselect.nodeId, keySubselect.nodeId) as level8, 
	coalesce(Level8Subselect.nodeDesc, Level7Subselect.nodeDesc, Level6Subselect.nodeDesc, Level5Subselect.nodeDesc, Level4Subselect.nodeDesc, Level3Subselect.nodeDesc, Level2Subselect.nodeDesc, Level1Subselect.nodeDesc, keySubselect.nodeDesc) as level8Desc, 
	coalesce(Level9Subselect.nodeId, Level8Subselect.nodeId, Level7Subselect.nodeId, Level6Subselect.nodeId, Level5Subselect.nodeId, Level4Subselect.nodeId, Level3Subselect.nodeId, Level2Subselect.nodeId, Level1Subselect.nodeId, keySubselect.nodeId) as level9, 
	coalesce(Level9Subselect.nodeDesc, Level8Subselect.nodeDesc, Level7Subselect.nodeDesc, Level6Subselect.nodeDesc, Level5Subselect.nodeDesc, Level4Subselect.nodeDesc, Level3Subselect.nodeDesc, Level2Subselect.nodeDesc, Level1Subselect.nodeDesc, keySubselect.nodeDesc) as level9Desc, 
	coalesce(Level10Subselect.nodeId, Level9Subselect.nodeId, Level8Subselect.nodeId, Level7Subselect.nodeId, Level6Subselect.nodeId, Level5Subselect.nodeId, Level4Subselect.nodeId, Level3Subselect.nodeId, Level2Subselect.nodeId, Level1Subselect.nodeId, keySubselect.nodeId) as level10, 
	coalesce(Level10Subselect.nodeDesc, Level9Subselect.nodeDesc, Level8Subselect.nodeDesc, Level7Subselect.nodeDesc, Level6Subselect.nodeDesc, Level5Subselect.nodeDesc, Level4Subselect.nodeDesc, Level3Subselect.nodeDesc, Level2Subselect.nodeDesc, Level1Subselect.nodeDesc, keySubselect.nodeDesc) as level10Desc
	
from 
	PCStructure a
	left outer join (select accountId as nodeId, AccountName as nodeDesc from [dbo].[vwHierAccount]) keySubselect on keySubselect.nodeId = a.nodeId
	cross join		(select accountId as nodeId, AccountName as nodeDesc from [dbo].[vwHierAccount] where AccountParentID is null) Level0Subselect
	left outer join (select accountId as nodeId, AccountName as nodeDesc from [dbo].[vwHierAccount]) Level1Subselect  on Level1Subselect.nodeId = a.Level1
	left outer join (select accountId as nodeId, AccountName as nodeDesc from [dbo].[vwHierAccount]) Level2Subselect  on Level2Subselect.nodeId = a.Level2
	left outer join (select accountId as nodeId, AccountName as nodeDesc from [dbo].[vwHierAccount]) Level3Subselect  on Level3Subselect.nodeId = a.Level3
	left outer join (select accountId as nodeId, AccountName as nodeDesc from [dbo].[vwHierAccount]) Level4Subselect  on Level4Subselect.nodeId = a.Level4
	left outer join (select accountId as nodeId, AccountName as nodeDesc from [dbo].[vwHierAccount]) Level5Subselect  on Level5Subselect.nodeId = a.Level5
	left outer join (select accountId as nodeId, AccountName as nodeDesc from [dbo].[vwHierAccount]) Level6Subselect  on Level6Subselect.nodeId = a.Level6
	left outer join (select accountId as nodeId, AccountName as nodeDesc from [dbo].[vwHierAccount]) Level7Subselect  on Level7Subselect.nodeId = a.Level7
	left outer join (select accountId as nodeId, AccountName as nodeDesc from [dbo].[vwHierAccount]) Level8Subselect  on Level8Subselect.nodeId = a.Level8
	left outer join (select accountId as nodeId, AccountName as nodeDesc from [dbo].[vwHierAccount]) Level9Subselect  on Level9Subselect.nodeId = a.Level9
	left outer join (select accountId as nodeId, AccountName as nodeDesc from [dbo].[vwHierAccount]) Level10Subselect  on Level10Subselect.nodeId = a.Level10



