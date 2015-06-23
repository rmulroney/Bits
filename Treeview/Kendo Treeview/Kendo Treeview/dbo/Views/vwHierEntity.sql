

CREATE view [dbo].[vwHierEntity] as

SELECT [EntityID]
      ,[EntityName]
      ,[ParentEntityID]
  FROM [dbo].[DimEntity]
	


union all 

SELECT [EntityHierID]
      ,[EntityName]
      ,[ParentID]
  FROM [dbo].[HierEntity]


  union 

  SELECT [EntityHierID]
      ,[EntityName]
      ,[ParentID]
  FROM [dbo].[HierEntity]







