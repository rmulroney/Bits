








CREATE view [dbo].[vwHierJob] as

select a.JobID, 
		a.JobHierID as JobParentID, 
		a.JobName, 
		a.JobNumber
from [dbo].[DimJob] a 
	


union all 

select h.JobHierID as JobID,
		h.ParentID,
		h.[JobName],
		h.JobNumber
	from [dbo].[HierJob] h
		



