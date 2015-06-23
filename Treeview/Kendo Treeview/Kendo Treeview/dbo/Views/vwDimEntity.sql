


CREATE VIEW [dbo].[vwDimEntity]
AS

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
	[ParentEntityID] as parentId, 
	[EntityID] as nodeId,
	null as Level1, 
	null as Level2, 
	null as Level3, 
	null as Level4, 
	null as Level5
FROM [dbo].[vwHierEntity] WHERE [ParentEntityID] is null 
UNION ALL 
SELECT 
	Level + 1, e.[ParentEntityID], e.[EntityID], 
	CASE Level WHEN 1 THEN e.[EntityID] ELSE Level1 END AS Level1, 
	CASE Level WHEN 2 THEN e.[EntityID] ELSE Level2 END AS Level2, 
	CASE Level WHEN 3 THEN e.[EntityID] ELSE Level3 END AS Level3, 
	CASE Level WHEN 4 THEN e.[EntityID] ELSE Level4 END AS Level4, 
	CASE Level WHEN 5 THEN e.[EntityID] ELSE Level5 END AS Level5
FROM 
	[dbo].[vwHierEntity] e INNER JOIN 
	PCStructure d ON e.[ParentEntityID] = d.nodeID)
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
	left outer join (select [EntityID] as nodeId, [EntityName] as nodeDesc from [dbo].[vwHierEntity]) keySubselect on keySubselect.nodeId = a.nodeId
	cross join		(select [EntityID] as nodeId, [EntityName] as nodeDesc from [dbo].[vwHierEntity] where [ParentEntityID] is null) Level0Subselect
	left outer join (select [EntityID] as nodeId, [EntityName] as nodeDesc from [dbo].[vwHierEntity]) Level1Subselect  on Level1Subselect.nodeId = a.Level1
	left outer join (select [EntityID] as nodeId, [EntityName] as nodeDesc from [dbo].[vwHierEntity]) Level2Subselect  on Level2Subselect.nodeId = a.Level2
	left outer join (select [EntityID] as nodeId, [EntityName] as nodeDesc from [dbo].[vwHierEntity]) Level3Subselect  on Level3Subselect.nodeId = a.Level3
	left outer join (select [EntityID] as nodeId, [EntityName] as nodeDesc from [dbo].[vwHierEntity]) Level4Subselect  on Level4Subselect.nodeId = a.Level4
	left outer join (select [EntityID] as nodeId, [EntityName] as nodeDesc from [dbo].[vwHierEntity]) Level5Subselect  on Level5Subselect.nodeId = a.Level5



GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPane1', @value = N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "DimEntity"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 145
               Right = 274
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'vwDimEntity';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPaneCount', @value = 1, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'vwDimEntity';

