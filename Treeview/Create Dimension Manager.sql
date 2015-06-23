
/*****************************************************************/
-- 
--		Tables
--
/*****************************************************************/

/****** Object:  Table [dbo].[DMLookupTableTypes]    Script Date: 12/11/2013 10:25:40 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[DMLookupTableTypes](
	[TableType] [varchar](50) NOT NULL,
 CONSTRAINT [PK_DMTableTypes] PRIMARY KEY CLUSTERED 
(
	[TableType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO



/****** Object:  Table [dbo].[DMSchema]    Script Date: 12/11/2013 10:25:56 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[DMSchema](
	[Dimension] [varchar](50) NOT NULL,
	[Hierarchy] [varchar](50) NOT NULL,
	[TableType] [varchar](50) NOT NULL,
	[HierarchyTable] [varchar](50) NOT NULL,
	[ColNodeId] [varchar](50) NOT NULL,
	[ColParentId] [varchar](50) NOT NULL,
	[ColNodeDesc] [varchar](50) NOT NULL,
	[ColSortOrder] [varchar](50) NOT NULL,
	[ColIsLeaf] [varchar](50) NOT NULL,
	[Attributes] [varchar](50) NULL,
	[ProcessProc] [varchar](50) NULL,
 CONSTRAINT [PK_DMSchema] PRIMARY KEY CLUSTERED 
(
	[Dimension] ASC,
	[Hierarchy] ASC,
	[TableType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[DMSchema]  WITH CHECK ADD  CONSTRAINT [FK_DMSchema_DMTableTypes] FOREIGN KEY([TableType])
REFERENCES [dbo].[DMLookupTableTypes] ([TableType])
GO

ALTER TABLE [dbo].[DMSchema] CHECK CONSTRAINT [FK_DMSchema_DMTableTypes]
GO

/*****************************************************************/
-- 
--		Populate DM Lookups
--
/*****************************************************************/


-- Insert FK data for table types used by procs.
insert into [dbo].[DMLookupTableTypes] ([TableType]) values ('ParentChild')
insert into [dbo].[DMLookupTableTypes] ([TableType]) values ('Hier')
insert into [dbo].[DMLookupTableTypes] ([TableType]) values ('Leaf')



/*****************************************************************/
-- 
--		Stored Procedures
--
/*****************************************************************/


/****** Object:  StoredProcedure [dbo].[spDMAttributeUpdate]    Script Date: 12/11/2013 10:26:19 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE proc [dbo].[spDMAttributeUpdate](
	@dimension as varchar(50),
	@hierarchy as varchar(50),
	@tableType as varchar(50),
	@node as int,
	@AttributeColumn as varchar(50),
	@newValue as nvarchar(max)
) as




-- Escape single quotes in params.
select @dimension = replace(@dimension, '''', '''''')
select @hierarchy = replace(@hierarchy, '''', '''''')
select @tableType = replace(@tableType, '''', '''''')
select @AttributeColumn = replace(@AttributeColumn, '''', '''''')
select @newValue = replace(@newValue, '''', '''''')


declare @sql as nvarchar(max)

-- Prevent updates to protected columns such as ID's.
select @AttributeColumn = 
	Case when @AttributeColumn = 'label' then [ColNodeDesc]
		 when @AttributeColumn = 'ID' then null
		 when @AttributeColumn = [ColNodeId] then null
		 else @AttributeColumn 
	end
from [dbo].[DMSchema]
where dimension = @dimension
and [Hierarchy] = @hierarchy
and [TableType] = @tableType


IF not @AttributeColumn is null begin

	select @sql = ' UPDATE ' + [HierarchyTable] + 
				  ' SET ' + @AttributeColumn + ' = ''' + @newValue + '''
					WHERE ' + [ColNodeId] + ' = ' + convert(nvarchar(10), @node)
	from [dbo].[DMSchema]
	where [Dimension] = @dimension
	and [Hierarchy] = @hierarchy
	and [TableType] = @tableType

	exec sp_executesql @SQl
	print @sql


end else 
	select 'A node''s ID cannot be updated.' 


GO


/****** Object:  StoredProcedure [dbo].[spDMVerifyDelete]    Script Date: 12/11/2013 10:28:11 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE proc [dbo].[spDMVerifyDelete] (
	@Dimension as varchar(50),
	@Hierarchy as varchar(50),
	@node as int
) as



-- Escape single quotes in params.
select @Dimension = replace(@Dimension, '''', '''''')
select @hierarchy = replace(@hierarchy, '''', '''''')





	declare @sql as nvarchar(max),
			@result as varchar(50) = ''


/* 

	Add business logic in here to prevent delete's as appropriate. 

*/


/* 
	By default prevents delete's where a node has children.			   
*/

	select @sql = ' SELECT @result = ''Has Children'' 
					FROM '  + [HierarchyTable] + '
					WHERE ' + [ColParentId] + ' = ' + convert(nvarchar(10), @node)
	from [dbo].[DMSchema]
	where [Dimension] = @dimension
	and [Hierarchy] = @Hierarchy
	and [TableType] = 'parentChild'

	exec sp_executesql @SQl, N'@result varchar(50) OUTPUT', @result output
	
	
	if @result <> '' begin
		Raiserror('Selected node has children, delete cancelled.', 16, 1)
		return -1
	end

/*
	By default only delete Sumamry points in the Hierarchy - never source system nodes.
*/

	select @sql = ' SELECT @result = ''Is Source System Node.'' 
					FROM '  + [HierarchyTable] + '
					WHERE ' + [ColNodeId] + ' = ' + convert(nvarchar(10), @node) + '
					AND ' + [ColIsLeaf] + ' = 1' 

	from [dbo].[DMSchema]
	where [Dimension] = @dimension
	and [Hierarchy] = @Hierarchy
	and [TableType] = 'parentChild'

	exec sp_executesql @SQl, N'@result varchar(50) OUTPUT', @result output
	
	
	if @result <> '' begin
		Raiserror('Source system members cannot be deleted.', 16, 1)
		return -1
	end



GO


/****** Object:  StoredProcedure [dbo].[spDMDelete]    Script Date: 12/11/2013 10:28:41 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   proc [dbo].[spDMDelete] (
	@Dimension as varchar(50),
	@Hierarchy as varchar(50), 
	@node as int
) as


-- Escape single quotes in params.
select @dimension = replace(@dimension, '''', '''''')
select @hierarchy = replace(@hierarchy, '''', '''''')

	declare @sql as nvarchar(max),
			@result as varchar(50) = ''


	BEGIN TRY
		/* business logic to prevent deletion should be added to [spDMVerifyDelete] */
		exec spDMVerifyDelete @Dimension, @hierarchy, @node
	END TRY
	BEGIN CATCH
		Raiserror('Cannot Delete Dimension Member, verifying business logic failed.', 16, 1)
		return 
	END CATCH

	
	select @sql = ' DELETE FROM '  + [HierarchyTable] + '
					WHERE ' + [ColNodeId] + ' = ' + convert(nvarchar(10), @node)
	from [dbo].[DMSchema]
	where [Dimension] = @dimension
	and [Hierarchy] = @hierarchy
	and [TableType] = 'Hier' --> Don't delete source system members. 

	exec sp_executesql @SQl
	print @sql

GO


/****** Object:  StoredProcedure [dbo].[spDMDimensions]    Script Date: 12/11/2013 10:29:06 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[spDMDimensions]  
AS



select dimension
from [dbo].[DMSchema]
group by [dimension] 



GO


/****** Object:  StoredProcedure [dbo].[spDMHierachies]    Script Date: 12/11/2013 10:29:38 AM ******/

CREATE PROCEDURE [dbo].[spDMHierachies]
	@dimension as varchar(50)
AS

select 
	[Hierarchy] 
from [dbo].[DMSchema]
where Dimension = @dimension
group by [Hierarchy] 




GO



/****** Object:  StoredProcedure [dbo].[spDMForeignKeylookup]    Script Date: 12/11/2013 10:29:18 AM ******/

CREATE proc [dbo].[spDMForeignKeylookup](
	@FKTable as varchar(50),
	@FKColumn as varchar(50)
) as



-- Escape single quotes in params.
select @FKTable = replace(@FKTable, '''', '''''')
select @FKColumn = replace(@FKColumn, '''', '''''')



declare @sql as nvarchar(max)

select @sql = 'SELECT ' + [text] + ' as text, ' + [value] + ' as value
			   FROM ' + @FKTable
from (
	select lag(COLUMN_NAME, 1, null) OVER (ORDER BY ORDINAL_POSITION) as [Text]
		,COLUMN_NAME as value
	FROM information_schema.columns
	WHERE TABLE_NAME = @FKTable
) as a


exec sp_executesql @SQl
print @sql

GO



/****** Object:  StoredProcedure [dbo].[spDMLeafAttributes]    Script Date: 12/11/2013 10:30:01 AM ******/

CREATE proc [dbo].[spDMLeafAttributes] (	
	@dimension as varchar(50),
	@hierarchy as varchar(50),
	@node as int,
	@children as int
) as 


-- Escape single quotes in params.
select @dimension = replace(@dimension, '''', '''''')
select @hierarchy = replace(@hierarchy, '''', '''''')






DECLARE @SQL as nvarchar(max)


if @Children = 1 
	
	SELECT @SQL = N'
	
			SELECT
				value = leaf.' + leaf.ColNodeId + ',
				label = leaf.' + leaf.ColNodeDesc + '
				' + Case when coalesce(leaf.Attributes, '') <> '' then ',leaf.' + replace(coalesce(leaf.Attributes, ''), ',', ',leaf.') else '' end + ',
				leaf.' + leaf.ColSortOrder + '				
			FROM ' + leaf.[HierarchyTable] + ' as leaf
			INNER JOIN ' +  pc.[HierarchyTable] + ' as pc on leaf.' + leaf.[ColNodeId] + ' = pc.' + pc.[ColNodeId] +'
		    WHERE pc.' + pc.[ColParentId] + ' = ' + convert(nvarchar(10), @node) + '
			OR leaf.'+ leaf.[ColNodeId]+ ' = ' + + convert(nvarchar(10), @node) 
		FROM [DMSchema] as leaf
			 inner join [DMSchema] as pc on leaf.dimension = pc.Dimension and leaf.Hierarchy = pc.Hierarchy
		WHERE leaf.[Dimension] = @dimension		
		AND leaf.Hierarchy = @hierarchy
		AND leaf.[TableType] = 'Leaf'
		AND pc.[TableType] = 'ParentChild'

else

-- only current node

	SELECT @SQL = N'
	
			SELECT
				value = ' + leaf.ColNodeId + ',
				label = ' + leaf.ColNodeDesc + '
				' + Case when coalesce(leaf.Attributes, '') <> '' then ',' + coalesce(leaf.Attributes, '')  else '' end + ',
				' + leaf.ColSortOrder + '				
			FROM ' + leaf.[HierarchyTable] + ' 			
		    WHERE ' + leaf.ColNodeId + ' = ' + convert(nvarchar(10), @node)
		FROM [DMSchema] as leaf			 
		WHERE leaf.[Dimension] = @dimension
		AND leaf.Hierarchy = @hierarchy
		AND leaf.[TableType] = 'Leaf'
	

exec sp_executesql @SQl
print @sql





			
GO


/****** Object:  StoredProcedure [dbo].[spDMProcessDimension]    Script Date: 12/11/2013 10:30:15 AM ******/

CREATE proc [dbo].[spDMProcessDimension]
(
	@dimension as varchar(50)
)
 as

  
-- Escape single quotes in params.
select @dimension = replace(@dimension, '''', '''''')

declare @sql as nvarchar(max)

		-- Process the Dimension
		select @sql = N'exec ' + ProcessProc
		from [dbo].[DMSchema] 
		where not ProcessProc is null
		and [Dimension] = @dimension
		
		EXEC sp_executesql @SQL 
		
GO


/****** Object:  StoredProcedure [dbo].[spDMTableDefinition]    Script Date: 12/11/2013 10:30:26 AM ******/

CREATE proc [dbo].[spDMTableDefinition](
	@Dimension as varchar(50),
	@Hierarchy as varchar(50),
	@TableType as varchar(50)
) as



SELECT  col.column_name as ColumnName,
		col.DATA_TYPE as DataType,
		col.CHARACTER_MAXIMUM_LENGTH as LenghtText,
		col.numeric_precision as LenghtNumeric,
		col.COLUMN_DEFAULT as DefaultValue,
		FK.PK_Table as LookupTable, 
		FK.PK_Column as LookupColumn
FROM information_schema.columns as col
INNER JOIN [dbo].[DMSchema] as DMS on col.table_name = replace(replace(DMS.HierarchyTable,'[',''),']','')
LEFT OUTER JOIN ( 
	
	-- Get the DB's defined FK constraints.

	SELECT
		K_Table = FK.TABLE_NAME,
		FK_Column = CU.COLUMN_NAME,
		PK_Table = PK.TABLE_NAME,
		PK_Column = PT.COLUMN_NAME,
		Constraint_Name = C.CONSTRAINT_NAME
	FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS C
	INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS FK ON C.CONSTRAINT_NAME = FK.CONSTRAINT_NAME
	INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS PK ON C.UNIQUE_CONSTRAINT_NAME = PK.CONSTRAINT_NAME
	INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE CU ON C.CONSTRAINT_NAME = CU.CONSTRAINT_NAME
	INNER JOIN (
		SELECT i1.TABLE_NAME, i2.COLUMN_NAME
		FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS i1
		INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE i2 ON i1.CONSTRAINT_NAME = i2.CONSTRAINT_NAME
		WHERE i1.CONSTRAINT_TYPE = 'PRIMARY KEY'
	) PT ON PT.TABLE_NAME = PK.TABLE_NAME

) as FK on col.table_name = FK.K_Table and col.column_name = FK.FK_Column
WHERE DMS.Dimension = @Dimension 
and DMS.Hierarchy = @Hierarchy
and DMS.TableType = @TableType
ORDER BY ordinal_position






GO


/****** Object:  StoredProcedure [dbo].[spDMTreeHierarchy]    Script Date: 12/11/2013 10:30:39 AM ******/


CREATE PROCEDURE [dbo].[spDMTreeHierarchy]
    @parentId AS INTEGER,
	@HierView as varchar(50),
	@Hierarchy as varchar(50),
	@Children as int = 1
AS

-- Escape single quotes in params.
select @parentId = replace(@parentId, '''', '''''')
select @HierView = replace(@HierView, '''', '''''')





		-- Variables for Dimension's schema
	declare @ParentChildView as varchar(50), 			
			@ColNodeId as varchar(50),
			@ColParentId as varchar(50),
			@ColNodeDesc as varchar(50),
			@ColSortOrder as varchar(50),
			@ColIsLeaf as varchar(50), 
			@Attributes as varchar(50)
	
	DECLARE @SQL as nvarchar(max)


	select   @ParentChildView = HierarchyTable
			,@ColNodeId = [ColNodeId]
			,@ColParentId = [ColParentId]
			,@ColNodeDesc = [ColNodeDesc]
			,@ColSortOrder = [ColSortOrder]
			,@ColIsLeaf = [ColIsLeaf]
			,@Attributes = Attributes
	from [dbo].[DMSchema]
	where [Dimension] = @HierView
	and Hierarchy = @hierarchy
	and [TableType] = 'ParentChild'
	

	-- Show all the children of the current node. 
	if @Children  = 1 begin
			
		SET @parentId = NULLIF (@parentId, 0)

		SELECT @SQL = N'
	
			SELECT
				value = ' + @ColNodeId + ',
				label = ' + @ColNodeDesc + ',
				hasChildren = COALESCE (ca1.hasChildren, ''''''false''),			
				isCalculated = ''''''false'',			
				unaryOperator = ''''''+'',
				isLeaf = IIF (' + @ColIsLeaf + ' = 1, ''''''true'', ''''''false''),
				' + @ColSortOrder + '				
			FROM ' + @ParentChildView + ' p1

			OUTER APPLY (
				SELECT TOP 1 ''true'' hasChildren
				FROM '+ @ParentChildView +' c1 where c1.' + @ColParentId + ' = p1.'+ @ColNodeId +'
			) ca1

			WHERE (@parent IS NULL AND ' + @ColParentId + ' IS NULL)
				OR @parent = ' + @ColParentId + '
			ORDER BY ' + @ColSortOrder + ', ' + @ColNodeDesc 

			print @sql
	
	
	-- Show all the children of the current node where the Children are also parents. 
	end else if @Children  = 2 begin
	
		SET @parentId = NULLIF (@parentId, 0)

		SELECT @SQL = N'
	
			SELECT
				value = ' + @ColNodeId + ',
				label = ' + @ColNodeDesc + ',
				hasChildren = COALESCE (ca1.hasChildren, ''''''false''),			
				isCalculated = ''''''false'',			
				unaryOperator = ''''''+'',
				isLeaf = IIF (' + @ColIsLeaf + ' = 1, ''''''true'', ''''''false''),
				' + @ColSortOrder + '				
			FROM ' + @ParentChildView + ' p1

			OUTER APPLY (
				SELECT TOP 1 ''true'' hasChildren
				FROM '+ @ParentChildView +' c1 where c1.' + @ColParentId + ' = p1.'+ @ColNodeId +'
			) ca1

			WHERE ((@parent IS NULL AND ' + @ColParentId + ' IS NULL)
				OR @parent = ' + @ColParentId + ') 
			AND ' + @ColIsLeaf + ' = 0
			ORDER BY ' + @ColSortOrder + ', ' + @ColNodeDesc 

			print @sql
		
	
	-- @children = 0, show only the selected node. 	
	end else begin

		SELECT @SQL = N'
			SELECT
				value = ' + @ColNodeId + ',
				label = ' + @ColNodeDesc + ',
				hasChildren = COALESCE (ca1.hasChildren, ''''''false''),			
				isCalculated = ''''''false'',			
				unaryOperator = ''''''+'',
				isLeaf = IIF (' + @ColIsLeaf + ' = 1, ''''''true'', ''''''false''),
				' + @ColSortOrder + '				
			FROM ' + @ParentChildView + ' p1

			OUTER APPLY (
				SELECT TOP 1 ''true'' hasChildren
				FROM '+ @ParentChildView +' c1 where c1.' + @ColParentId + ' = p1.'+ @ColNodeId +'
			) ca1

			WHERE (@parent IS NULL AND ' + @ColNodeId + ' IS NULL)
				OR @parent = ' + @ColNodeId + '
			ORDER BY ' + @ColSortOrder + ', ' + @ColNodeDesc 
			
			print @sql
			

	end


	exec sp_executesql @SQl, N'@parent int', @parent = @parentID

	print @sql


GO


/****** Object:  StoredProcedure [dbo].[spDMTreeMove]    Script Date: 12/11/2013 10:30:55 AM ******/


CREATE proc [dbo].[spDMTreeMove](
	@dimensionHier as varchar(50),
	@hierarchy as varchar(50),
	@node as int,
	@targetNode as int,
	@position as varchar(50)
) as

	declare @AncestorAccounts as table (nodeId int)
	
	declare @lastAncestor as int, 
			@flag as int, 
			@newParent as int, 
			@newOrder as int, 
			@leaf as bit,
			@SQL as nvarchar(max)


-- Escape single quotes in params.
select @dimensionHier = replace(@dimensionHier, '''', '''''')
select @hierarchy = replace(@hierarchy, '''', '''''')
select @node = replace(@node, '''', '''''')
select @targetNode = replace(@targetNode, '''', '''''')
select @position = replace(@position, '''', '''''')



	select @flag =0, @lastAncestor = @newParent


-- Prevent Nodes from becoming thier own Parents.
	if @node = @targetNode begin
		-- no error message, it was probably a slip of the mouse.
		return 
	end
	



-- determine the action to be performed

	if @position = 'over' begin
	
		
		-- When node is dropped on another node it become the parent. 
		select @newParent = @targetNode

		-- as it's last child.		
		select @sql = N'select @newOrder = max(coalesce(' + ColSortOrder + ', 1)) + 1
						from ' + [HierarchyTable] + '
						where ' + ColParentId + ' = ' + convert(nvarchar(10), @targetNode)
		from [dbo].[DMSchema]
		where [TableType] = 'ParentChild'
		and [Dimension] = @dimensionHier
		and [Hierarchy] = @hierarchy

		EXEC sp_executesql @SQL, N'@newOrder int OUTPUT',@newOrder OUTPUT


	
	end else begin 
		-- when node is dropped before or after another node it inherits the target node's parent.

		select @sql = N'select @newParent = coalesce('+ ColParentId +', 1)
						from ' + [HierarchyTable] + '
						where ' + ColNodeId + ' = ' + convert(nvarchar(10), @targetNode)
		from [dbo].[DMSchema]
		where [TableType] = 'ParentChild'
		and [Dimension] = @dimensionHier
		and Hierarchy = @hierarchy
		
		EXEC sp_executesql @SQL, N'@newParent int OUTPUT',@newParent OUTPUT
				
		-- when dropped before a node	then take the node's Sort Order.
		-- when dropped after a node then take the position after the current node.

		--		select @newOrder = coalesce([SortOrder], 1) + 
		--				Case when @position = 'after' then 1 else 0 end
		--		from [dbo].[_HierAccount]	
		--		where [AccountID] = @targetNode

		select @sql = N'select @newOrder = coalesce(' + ColSortOrder + ', 1) +
							Case when ''' + @position + ''' = ''after'' then 1 else 0 end								
						from ' + HierarchyTable + '
						where ' + ColNodeId + ' = ' + convert(nvarchar(10), @targetNode)
		from [dbo].[DMSchema]
		where [TableType] = 'ParentChild'
		and [Dimension] = @dimensionHier
		and [Hierarchy] = @hierarchy


		EXEC sp_executesql @SQL, N'@newOrder int OUTPUT',@newOrder OUTPUT												
	end
	
-- Do not allow source system "Leaf" node to become parents.
	
	select @sql	= N'Select @leaf = isleaf from ' + HierarchyTable + ' where ' + ColNodeId + ' = ' + convert(nvarchar(10), @newParent) + ' and [isleaf] = 1'
	from [dbo].[DMSchema]
	where [TableType] = 'ParentChild' 
	and [Dimension] = @dimensionHier
	and [Hierarchy] = @hierarchy

	EXEC sp_executesql @SQL, N'@leaf bit OUTPUT',@leaf OUTPUT													
	
	if coalesce(@leaf, 0) = 1 begin
		select @newOrder as neworder, @newParent as newParent, @position as position
		print @sql
		Raiserror('Leaf nodes may not become parents.', 16, 1)
		return 
	end

	

-- Test to see if our new parent will cause a recurrsive loop.

	insert into @AncestorAccounts
			select @node


	WHILE @flag = 0 BEGIN

		-- select @lastAncestor = [AccountParentID]
		-- from [dbo].[_HierAccount]
		-- where AccountID = @lastAncestor

		select @sql	= N'select @lastAncestor = ' + ColParentId + '
						from ' + HierarchyTable + '
						where ' + ColNodeId + ' = ' + convert(nvarchar(10), @lastAncestor)
		from [dbo].[DMSchema]
		where [TableType] = 'ParentChild' 
		and [Dimension] = @dimensionHier
		and [Hierarchy] = @hierarchy

		EXEC sp_executesql @SQL, N'@lastAncestor int OUTPUT',@lastAncestor OUTPUT		

	
		if @lastAncestor in (select nodeid from @AncestorAccounts) begin
			select @Flag = -1 --Fail
		END ELSE IF @lastAncestor  is null BEGIN
			select @Flag = 1 -- Success
		END ELSE BEGIN
			insert into @AncestorAccounts
			select @lastAncestor
		END

	END
	
	
	IF @Flag < 0 BEGIN
		Raiserror('Accounts cannot be made thier own ancestor.', 16, 1)
		return  
	
	END ELSE BEGIN 	
	-- No Problem with recurrsion

		-- Move the node to it's new parent. 		
		--		Update _HierAccount
		--		set [AccountParentID] = @newParent,
		--			[SortOrder] = @newOrder
		--		where [AccountID] = @node			

		select @sql = N'Update ' + HierarchyTable + '
						set ' + ColParentId + ' = ' + convert(nvarchar(10), @newParent) + ',
							'+ ColSortOrder +' = ' + convert(nvarchar(10),coalesce(@newOrder, 1)) + ' 
						where ' + ColNodeId + ' = ' + convert(nvarchar(10), @node)
		from [dbo].[DMSchema]
		where [TableType] = 'Leaf' 
		and [Dimension] = @dimensionHier
		and [Hierarchy] = @hierarchy
		
		EXEC sp_executesql @SQL 

		select @sql = N'Update ' + HierarchyTable + '
						set ' + ColParentId + ' = ' + convert(nvarchar(10), @newParent) + ',
							'+ ColSortOrder +' = ' + convert(nvarchar(10),coalesce(@newOrder, 1)) + ' 
						where ' + ColNodeId + ' = ' + convert(nvarchar(10), @node)
		from [dbo].[DMSchema]
		where [TableType] = 'Hier' 
		and [Dimension] = @dimensionHier
		and [Hierarchy] = @hierarchy
		
		EXEC sp_executesql @SQL 
					
		-- Update the Sort order for nodes after the moving node.		
		--		Update _HierAccount
		--		set [SortOrder] = [SortOrder] + 1
		--		where [SortOrder]  >= @newOrder
		--		and [AccountID] <> @node


		select @sql = N'Update ' + HierarchyTable + '
						set ' + ColSortOrder + ' = ' + ColSortOrder + ' + 1
						where ' + ColSortOrder + '  >= ' + convert(nvarchar(10),coalesce(@newOrder, 1)) + '
						and ' + ColParentId + ' = ' + convert(nvarchar(10), @newParent) + '
						and ' + ColNodeId + ' <> ' + convert(nvarchar(10), @node)
		from [dbo].[DMSchema]
		where [TableType] = 'Leaf' 
		and [Dimension] = @dimensionHier
		and [Hierarchy] = @hierarchy

		select @sql = N'Update ' + HierarchyTable + '
						set ' + ColSortOrder + ' = ' + ColSortOrder + ' + 1
						where ' + ColSortOrder + '  >= ' + convert(nvarchar(10),coalesce(@newOrder, 1)) + '
						and ' + ColParentId + ' = ' + convert(nvarchar(10), @newParent) + '
						and ' + ColNodeId + ' <> ' + convert(nvarchar(10), @node)
		from [dbo].[DMSchema]
		where [TableType] = 'Hier' 
		and [Dimension] = @dimensionHier
		and [Hierarchy] = @hierarchy
		
		EXEC sp_executesql @SQL 

		/*
		-- Process the Dimension
		select @sql = N'exec ' + ProcessProc
		from [dbo].[DMSchema] 
		where not ProcessProc is null
		and [Dimension] = @dimensionHier
			
		EXEC sp_executesql @SQL */
		

	END

	


GO


/****** Object:  StoredProcedure [dbo].[spDMTreeNewNode]    Script Date: 12/11/2013 10:31:13 AM ******/

CREATE proc [dbo].[spDMTreeNewNode] (
	@dimensionHier as varchar(50),
	@Hierarchy as varchar(50),
	@targetNode as int,
	@position as varchar(50),
	@newName as varchar(100)
) as 


-- Escape single quotes in params.
select @dimensionHier = replace(@dimensionHier, '''', '''''')
select @hierarchy = replace(@hierarchy, '''', '''''')
select @position = replace(@position, '''', '''''')
select @newName = replace(@newName, '''', '''''')


	DECLARE @SQL as nvarchar(max),
			@newParent as int,
			@newID as int,
			@target as int,
			@targetIsLeaf as bit


	-- Check that the target node exists so we don't create any orphans children. 
	-- Calculate the new parent based on the target node and the position.
		
		select @sql = N'select @target = ' + [ColNodeId] + ',
								@newParent = case when ''' + @position + ''' = ''Child'' then ' + [ColNodeId] + '
											      else ' + [ColParentId] + ' end,	
								@targetIsLeaf = ' + [ColIsLeaf] + '														   
						from ' + [HierarchyTable] + '
						where ' + [ColNodeId] + ' = ' + convert(nvarchar(10), @targetNode)
		from [dbo].[DMSchema]
		where [TableType] = 'ParentChild'
		and [Dimension] = @dimensionHier
		and [Hierarchy] = @Hierarchy


		EXEC sp_executesql @SQL, N'@newParent int OUTPUT, @target int output, @targetIsLeaf bit OUTPUT',@newParent OUTPUT, @target OUTPUT, @targetIsLeaf OUTPUT

		if @newParent is null and not @target is null begin
			Raiserror('The Root node cannot be moved or changed.', 16, 1)
			return  
		end else if @target is null begin
			Raiserror('Target node not found.', 16, 1)
			return
		end else if @targetIsLeaf = 1 and  @position = 'Child' begin
			Raiserror('Leaf Nodes may not become Parents.', 16, 1)	
			return
		end else if @newParent is null and @target is null begin
			Raiserror('Error: new parent cannot be determined. Check Dimension Maintenance Schema.', 16, 1)
			return  
		end


	-- Insert the New Node
	select @sql = N'
		INSERT INTO ' + [HierarchyTable] + '
		(' + [ColParentId] + ',
		 ' + [ColNodeDesc] + ',
		 ' + [ColSortOrder] + '
		 )
		values (' + convert(nvarchar(10), @newParent)  + ',
				''' + @newName + ''',
				 null
		)'
	from [dbo].[DMSchema]
	where [Dimension] = @dimensionHier
	and [Hierarchy] = @Hierarchy
	and [TableType] = 'Hier'

	print @sql

	exec sp_executesql @SQl

	-- get the new node id
	SELECT @newID = @@IDENTITY 
	
	-- If inserting as a parent then set the new node as the parent of the targetNode.
	-- Runs against both Hier and Leaf, will only affect one. 

	if @position = 'Parent' begin 
		select @sql = N'
			UPDATE ' + [HierarchyTable] + '
			SET ' + [ColParentId] + ' = ' + convert(nvarchar(10), @newID) + '
			WHERE ' + [ColNodeId] + ' = ' + convert(nvarchar(10), @targetNode) 
		from [dbo].[DMSchema]
		where [Dimension] = @dimensionHier
		and [Hierarchy] = @Hierarchy
		and [TableType] = 'Hier'

		print @sql

		exec sp_executesql @SQl

		select @sql = N'
			UPDATE ' + [HierarchyTable] + '
			SET ' + [ColParentId] + ' = ' + convert(nvarchar(10), @newID) + '
			WHERE ' + [ColNodeId] + ' = ' + convert(nvarchar(10), @targetNode) 
		from [dbo].[DMSchema]
		where [Dimension] = @dimensionHier
		and [Hierarchy] = @Hierarchy
		and [TableType] = 'Leaf'

		exec sp_executesql @SQl
		print @sql

	end

	exec spDMTreeHierarchy @parentID = @newID, @HierView = @dimensionHier, @Hierarchy = @Hierarchy, @children = 0

	

GO

