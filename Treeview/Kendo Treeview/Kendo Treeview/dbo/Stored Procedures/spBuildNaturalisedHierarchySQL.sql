CREATE proc [dbo].[spBuildNaturalisedHierarchySQL] (
@objectName varchar(255) = '[dbo].[vwHierJob]'					--The table or view containing the parent child information
,@levels int = 5											--The number of levels you want to build out to
,@childColumnName varchar(255) = 'JobId'				--The column name containing the child or node Id
,@childDescriptionColumnName varchar(255) = 'JobName'	--The column name containing the child or node description
,@parentColumnName varchar(255) = 'JobParentID'			--The column name containing the parentNodeId. NOTE! The root parentId is considered to be null.  0 or multiple roots will cause the SQL to fail.
) as

declare @currentRecursiveLevel int = 1
declare @sql varchar(max)
declare @currentLevel int = 1
set @sql = '
WITH PCStructure
(
	Level, 
	parentId, 
	nodeID, '

while @currentLevel  <= @levels
	begin
		set @sql = @sql + '
	Level'+ cast(@currentLevel as varchar) + ', '
		set @currentLevel = @currentLevel + 1
	end
--Trim comma
set @sql = substring(@sql,1,len(@sql)-1)

set @sql = @sql + '
)
AS (
SELECT 
	1 Level, 
	' + @parentColumnName + ' as parentId, 
	' + @childColumnName + ' as nodeId,'
set @currentLevel = 1
while @currentLevel  <= @levels
	begin
		set @sql = @sql + '
	null as Level'+ cast(@currentLevel as varchar) + ', '
		set @currentLevel = @currentLevel + 1
	end
--Trim comma
set @sql = substring(@sql,1,len(@sql)-1)

set @sql = @sql + '
FROM ' + @objectName + ' WHERE ' + @parentColumnName + ' is null 
UNION ALL 
SELECT 
	Level + 1, e.' + @parentColumnName + ', e.' + @childColumnName + ', '

set @currentLevel = 1
while @currentLevel  <= @levels
	begin
		set @sql = @sql + '
	CASE Level WHEN '+ cast(@currentLevel as varchar) + ' THEN e.' + @childColumnName + ' ELSE Level'+ cast(@currentLevel as varchar) + ' END AS Level'+ cast(@currentLevel as varchar) + ', '
		set @currentLevel = @currentLevel + 1
	end
--Trim comma
set @sql = substring(@sql,1,len(@sql)-1)

set @sql = @sql + '
FROM 
	' + @objectName +' e INNER JOIN 
	PCStructure d ON e.' + @parentColumnName + ' = d.nodeID)
select 
	keySubselect.*,
	Level0Subselect.nodeId	as Level0,
	Level0Subselect.nodeDesc as Level0Desc,'

set @currentLevel = 1
while @currentLevel  <= @levels
	begin
--Coalesced Ids
		set @sql = @sql + '
	coalesce('
		set @currentRecursiveLevel = 1
		while @currentRecursiveLevel <= @currentLevel
			begin
				set @sql = @sql + 'Level'+ cast(@currentLevel+1-@currentRecursiveLevel as varchar) +'Subselect.nodeId, '
				set @currentRecursiveLevel = @currentRecursiveLevel + 1
			end
			set @sql = @sql + 'keySubselect.nodeId) as level'+ cast(@currentLevel as varchar) + ', '
--Descriptions
		set @sql = @sql + '
	coalesce('
			set @currentRecursiveLevel = 1
			while @currentRecursiveLevel <= @currentLevel
				begin
					set @sql = @sql + 'Level'+ cast(@currentLevel+1-@currentRecursiveLevel as varchar) +'Subselect.nodeDesc, '
					set @currentRecursiveLevel = @currentRecursiveLevel + 1
				end
				set @sql = @sql + 'keySubselect.nodeDesc) as level'+ cast(@currentLevel as varchar) + 'Desc, '
			set @currentLevel = @currentLevel + 1
	end

--Trim comma
set @sql = substring(@sql,1,len(@sql)-1)

set @sql = @sql + '
from 
	PCStructure a
	left outer join (select ' + @childColumnName + ' as nodeId, ' + @childDescriptionColumnName + ' as nodeDesc from ' + @objectName + ') keySubselect on keySubselect.nodeId = a.nodeId
	cross join		(select ' + @childColumnName + ' as nodeId, ' + @childDescriptionColumnName + ' as nodeDesc from ' + @objectName + ' where ' + @parentColumnName + ' is null) Level0Subselect'

set @currentLevel = 1
while @currentLevel  <= @levels
	begin
		set @sql = @sql + '
	left outer join (select ' + @childColumnName + ' as nodeId, ' + @childDescriptionColumnName + ' as nodeDesc from ' + @objectName + ') Level'+ cast(@currentLevel as varchar) + 'Subselect  on Level'+ cast(@currentLevel as varchar) + 'Subselect.nodeId = a.Level'+ cast(@currentLevel as varchar)
		set @currentLevel = @currentLevel + 1
	end

print @sql


