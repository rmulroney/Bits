
Create view vwDimJob as 

WITH PCStructure
(
	Level, 
	parentId, 
	nodeID, 
	Level1, 
	Level2, 
	Level3, 
	Level4, 
	Level5
)
AS (
SELECT 
	1 Level, 
	JobParentID as parentId, 
	JobId as nodeId,
	null as Level1, 
	null as Level2, 
	null as Level3, 
	null as Level4, 
	null as Level5
FROM [dbo].[vwHierJob] WHERE JobParentID is null 
UNION ALL 
SELECT 
	Level + 1, e.JobParentID, e.JobId, 
	CASE Level WHEN 1 THEN e.JobId ELSE Level1 END AS Level1, 
	CASE Level WHEN 2 THEN e.JobId ELSE Level2 END AS Level2, 
	CASE Level WHEN 3 THEN e.JobId ELSE Level3 END AS Level3, 
	CASE Level WHEN 4 THEN e.JobId ELSE Level4 END AS Level4, 
	CASE Level WHEN 5 THEN e.JobId ELSE Level5 END AS Level5
FROM 
	[dbo].[vwHierJob] e INNER JOIN 
	PCStructure d ON e.JobParentID = d.nodeID)
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
	coalesce(Level5Subselect.nodeDesc, Level4Subselect.nodeDesc, Level3Subselect.nodeDesc, Level2Subselect.nodeDesc, Level1Subselect.nodeDesc, keySubselect.nodeDesc) as level5Desc
from 
	PCStructure a
	left outer join (select JobId as nodeId, JobName as nodeDesc from [dbo].[vwHierJob]) keySubselect on keySubselect.nodeId = a.nodeId
	cross join		(select JobId as nodeId, JobName as nodeDesc from [dbo].[vwHierJob] where JobParentID is null) Level0Subselect
	left outer join (select JobId as nodeId, JobName as nodeDesc from [dbo].[vwHierJob]) Level1Subselect  on Level1Subselect.nodeId = a.Level1
	left outer join (select JobId as nodeId, JobName as nodeDesc from [dbo].[vwHierJob]) Level2Subselect  on Level2Subselect.nodeId = a.Level2
	left outer join (select JobId as nodeId, JobName as nodeDesc from [dbo].[vwHierJob]) Level3Subselect  on Level3Subselect.nodeId = a.Level3
	left outer join (select JobId as nodeId, JobName as nodeDesc from [dbo].[vwHierJob]) Level4Subselect  on Level4Subselect.nodeId = a.Level4
	left outer join (select JobId as nodeId, JobName as nodeDesc from [dbo].[vwHierJob]) Level5Subselect  on Level5Subselect.nodeId = a.Level5
