
/****** Object:  Table [stg].[ETLImportTables]    Script Date: 13/02/2015 9:59:32 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [stg].[ETLImportTables](
	[ETLImportTablesKey] [int] IDENTITY(1,1) NOT NULL,
	[ImportGroup] [nvarchar](20) NOT NULL,
	[SourceTableSchema] [nvarchar](50) NOT NULL,
	[SourceTableName] [nvarchar](50) NOT NULL,
	[TargetTableSchema] [nvarchar](50) NOT NULL,
	[TargetTableName] [nvarchar](50) NOT NULL,
	[SourceWhereClause] [nvarchar](max) NULL,
	[ClearTableStatement] [nvarchar](max) NULL,
 CONSTRAINT [PK_stgImportTables] PRIMARY KEY CLUSTERED 
(
	[ETLImportTablesKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [AK_stgImportTables] UNIQUE NONCLUSTERED 
(
	[SourceTableSchema] ASC,
	[SourceTableName] ASC,
	[TargetTableSchema] ASC,
	[TargetTableName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO


/****** Object:  Table [stg].[ETLImportColumns]    Script Date: 13/02/2015 9:59:44 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [stg].[ETLImportColumns](
	[ETLImportColumnKey] [int] IDENTITY(1,1) NOT NULL,
	[ETLImportTablesKey] [int] NOT NULL,
	[SourceColumnName] [nvarchar](50) NOT NULL,
	[TargetColumnName] [nvarchar](50) NULL,
	[DataType] [varchar](20) NULL,
	[DataMaxLenght] [int] NULL,
 CONSTRAINT [PK_ETLImportColumns] PRIMARY KEY CLUSTERED 
(
	[ETLImportColumnKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [AK_ETLImportColumns] UNIQUE NONCLUSTERED 
(
	[ETLImportTablesKey] ASC,
	[TargetColumnName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [stg].[ETLImportColumns]  WITH CHECK ADD  CONSTRAINT [FK_ETLImportColumns_ETLImportTables] FOREIGN KEY([ETLImportTablesKey])
REFERENCES [stg].[ETLImportTables] ([ETLImportTablesKey])
GO

ALTER TABLE [stg].[ETLImportColumns] CHECK CONSTRAINT [FK_ETLImportColumns_ETLImportTables]
GO





/****** Object:  StoredProcedure [stg].[uspETLAutoImport]    Script Date: 13/02/2015 10:00:34 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*
exec [stg].[uspETLAutoImport] 'tonnage', 3, 11, 2014
*/

CREATE  proc [stg].[uspETLAutoImport] (
	@group nvarchar(50), 
	@sourceSystem int, 
	@month int,
	@yr int
) as BEGIN

	declare @sql nvarchar(max), 
			@currentTable int,
			@currentColumn int, 
			@tableCount int, 
			@TargetColumnList nvarchar(max),
			@SourceColumnList nvarchar(max),
			@fromClause nvarchar(max),
			@whereClause nvarchar(max),
			@LinkeDB nvarchar(50), 
		    @LinkServerName nvarchar(50)
	
					
--#############################################
-- temp tables 
--#############################################
	if not OBJECT_ID('tempdb..#ETLMissingTables') is null
		drop table #ETLMissingTables

	if not OBJECT_ID('tempdb..#ETLMissingColumns') is null
		drop table #ETLMissingColumns

	if not OBJECT_ID('tempdb..#ETLClearQueries') is null
		drop table #ETLClearQueries

	CREATE TABLE #ETLMissingTables (
		tableKey int not null, 
		tableSchema nvarchar(50) null, 
		tableName nvarchar(50) not null,
		processed bit null
	)

	CREATE TABLE #ETLMissingColumns (
		tableKey int not null, 
		columnKey int not null,
		tableSchema nvarchar(50) null, 
		tableName nvarchar(50) not null,
		columnName nvarchar(50) not null,
		dataType varchar(50),
		dataMaxLenght int,
		processed bit null
	)

	CREATE TABLE #ETLClearQueries (
		tableKey int not null, 
		query nvarchar(max),
		processed bit null
	)

--#############################################
-- Find missing ETL tables and create them.
--#############################################

	-- Which ETL tables are missing?

	INSERT INTO #ETLMissingTables (
		tableKey, 
		tableSchema, 
		tableName,
		processed	)

	SELECT 
		 e.ETLImportTablesKey
		,TargetTableSchema
		,TargetTableName
		,processed = convert(bit, 0)

	FROM [stg].[ETLImportTables] e

		left outer join INFORMATION_SCHEMA.tables  s
			on e.TargetTableName = s.TABLE_NAME
				and e.TargetTableSchema = s.TABLE_SCHEMA
				and TABLE_TYPE = 'BASE TABLE'

	WHERE s.TABLE_NAME is null
	and ImportGroup = @group



	-- Loop through missing tables and create them.

	WHILE exists( select 1 from #ETLMissingTables where coalesce(processed, 0) = 0) BEGIN

		SELECT top 1 @sql = 'CREATE TABLE [' + coalesce(tableSchema, 'stg') + '].[' + tableName + '] ( '
			,@currentTable = tableKey
		FROM #ETLMissingTables t
		WHERE coalesce(processed, 0) = 0


		SELECT top 10  @sql = @sql + 
			case 
				when len(@sql) > 7800 then '' -- ensures that we don't over run the nvarchar(max) charater limit.
				else '[' + c.TargetColumnName + '] ' + c.DataType + 
							case 
								 when c.DataMaxLenght is null then '' 
								 when c.DataMaxLenght = -1 then '(max)'
								 else '(' + convert(nvarchar(5), c.DataMaxLenght) +')' 
							end 
				+ ',' + CHAR(13) + CHAR(10)
			end 
		FROM #ETLMissingTables t
			inner join [stg].[ETLImportColumns] c
				on t.tableKey = c.ETLImportTablesKey
		where t.tableKey = @currentTable


		SELECT @sql = substring(@sql, 1,len(@sql)-3) + ') ON [PRIMARY]'

		print @sql 
		exec sp_executesql @sql

		UPDATE #ETLMissingTables
		SET processed = 1
		WHERE @currentTable = tableKey
		  

	END




--#############################################
-- Execute Clear Queries 
--#############################################

	-- We clear before checking for missing Columns as it will make adding columns faster.

	INSERT INTO #ETLClearQueries (
		tableKey, 
		query,
		processed
	)
	SELECT 
		[ETLImportTablesKey],
		replace([ClearTableStatement], '@SourceSystemKey', convert(nvarchar(10), @sourceSystem)),
		convert(bit, 0)
	FROM [stg].[ETLImportTables]
	where [ImportGroup] = @group

	

	-- Loop through and run the clear table queries

	SET @currentTable = 0 

	WHILE exists( select 1 from #ETLClearQueries where coalesce(processed, 0) = 0) BEGIN


		SELECT TOP 1 @sql  = e.query,
					@currentTable = e.tableKey
		FROM #ETLClearQueries e
		where processed = 0

		
		print @sql 

		if @sql <> ''
			exec sp_executesql @sql
		

		UPDATE #ETLClearQueries
		SET processed = 1 
		WHERE tableKey = @currentTable


	END





--#############################################
-- Find missing ETL Columns and create them.
--#############################################

	-- Which ETL Columns are missing?
	INSERT INTO  #ETLMissingColumns (
		tableKey,
		columnKey, 
		tableSchema,
		tableName,
		columnName,
		dataType,
		dataMaxLenght,
		processed
	)

	SELECT 
		 e.ETLImportTablesKey
		,c.ETLImportColumnKey
		,e.TargetTableSchema
		,e.TargetTableName
		,c.TargetColumnName
		,c.[DataType]
		,c.[DataMaxLenght]
		,processed = convert(bit, 0)

	FROM [stg].[ETLImportTables] e
		
		inner join stg.ETLImportColumns c
			on e.ETLImportTablesKey = c.ETLImportTablesKey

		left outer join INFORMATION_SCHEMA.COLUMNS  s
			on e.TargetTableName = s.TABLE_NAME
				and e.TargetTableSchema = s.TABLE_SCHEMA
				and s.COLUMN_NAME = c.TargetColumnName

	WHERE s.TABLE_NAME is null
	  and e.ImportGroup = @group

	UNION ALL 

	SELECT 
		tableKey = e.ETLImportTablesKey,
		columnKey = -1 * ROW_NUMBER() over( order by TargetTableName ) + 10 , 
		tableSchema = e.TargetTableSchema,
		tableName = e.TargetTableName,
		columnName = 'SourceSystemKey',
		dataType = 'int',
		dataMaxLenght = null,
		processed = convert(bit, 0)
	FROM [stg].[ETLImportTables] e
				
		left outer join INFORMATION_SCHEMA.COLUMNS  s
			on e.TargetTableName = s.TABLE_NAME
				and e.TargetTableSchema = s.TABLE_SCHEMA
				and s.COLUMN_NAME = 'SourceSystemKey'
	WHERE s.TABLE_NAME is null
	  and e.ImportGroup = @group

	
	WHILE exists( select 1 from #ETLMissingColumns where coalesce(processed, 0) = 0) BEGIN


		SELECT TOP 1 @sql  = 
					'ALTER TABLE [' + tableSchema + '].[' + tableName +'] 
				     ADD [' + columnName +'] ' + dataType + 
							case 
								 when c.dataMaxLenght is null then '' 
								 when c.dataMaxLenght = -1 then '(max)'
								 else '(' + convert(nvarchar(5), c.DataMaxLenght) +')' 
							end , 
					@currentColumn = c.columnKey
		FROM #ETLMissingColumns c
		where processed = 0

		
		print @sql 
		exec sp_executesql @sql
		

		UPDATE #ETLMissingColumns
		SET processed = 1 
		WHERE columnKey = @currentColumn

	END


--#############################################
-- Process imports
--#############################################

	set @currentTable = 0

	SELECT @tableCount = max([ETLImportTablesKey])
	FROM [stg].[ETLImportTables]

	SELECT @LinkeDB = db.sourceDatabaseName
		  ,@LinkServerName = ss.linkedServer 
	FROM dbo.mstSourceSystem ss
		inner join dbo.mstSourceDatabase db
			on ss.sourceSystemKey = db.sourceSystemKey
	WHERE ss.sourceSystemKey = @sourceSystem
		and db.isActive = 1
	

	set @currentTable = 0
	
	WHILE  @currentTable < @tableCount BEGIN 

		print '@CurrentTable: ' +convert(nvarchar(5), @currentTable)

		set @sql = '';
		set @SourceColumnList = '';
		set @TargetColumnList = '';

		-- get the list of source Columns
		
		SELECT @SourceColumnList = @SourceColumnList + c.[SourceColumnName] + ',',
				@TargetColumnList = @TargetColumnList + [TargetColumnName] + ','
		FROM [stg].[ETLImportColumns] c
		WHERE [ETLImportTablesKey] = @currentTable
		ORDER BY [ETLImportColumnKey];

		
		IF exists (select 1 
					where not nullif(@SourceColumnList, '') is null 
						and not  nullif(@TargetColumnList, '') is null
					)
		BEGIN
			
			-- trim off last comma
			SELECT @SourceColumnList = substring(@SourceColumnList, 1, len(@SourceColumnList)-1),
				@TargetColumnList = substring(@TargetColumnList, 1, len(@TargetColumnList)-1)
			
			-- generate insert statment
			SELECT @sql = N'INSERT INTO [' + [TargetTableSchema] + '].[' + [TargetTableName] + '] ( ', 
					@fromClause  = 'From ['+
										case when @LinkeDB is null then '' 
											 else @LinkeDB +'].['
										end  
									+ e.SourceTableSchema + '].[' + e.SourceTableName + ']',
					@whereClause = e.SourceWhereClause
			FROM [stg].[ETLImportTables] e
			WHERE [ETLImportTablesKey] = @currentTable;

			
			SELECT @sql = @sql + @TargetColumnList + ', SourceSystemKey ) SELECT ' + @SourceColumnList + ', SourceSystemKey = ' + convert(nvarchar(2), @sourceSystem)

			SELECT @sql = @sql + ' FROM openquery(' + @LinkServerName
									+  ',  '' SELECT ' + @SourceColumnList
			
			SELECT @sql = @sql + ' ' + @fromClause + ' ' 
			
					+ replace( replace(coalesce(@whereClause , '') , '@month', convert(nvarchar(2), @month)), '@yr', convert(nvarchar(4), @yr))
					
					
					+ ''')'

			print @sql

			exec sp_executesql @sql
		
		END


		select @currentTable = @currentTable + 1
		
	END



END


GO



/****** Object:  StoredProcedure [stg].[uspPopulateETLImportTable]    Script Date: 13/02/2015 10:01:07 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE proc [stg].[uspPopulateETLImportTable] (
	@group nvarchar(50), 
	@SourceTableName nvarchar(50), 
	@SourceTableSchema nvarchar(50) = 'dbo',
	@TargetTableName nvarchar(50) = null,    -- used to populate columns.
	@TargetTableSchema nvarchar(50) = 'stg', 
	@sourceFilterColumn nvarchar(50) = null
) as begin 


declare @sql as nvarchar(max), 
	@tablesID int = 0

if exists ( select 1 from [stg].[ETLImportTables]
				where [SourceTableSchema] = @SourceTableSchema
					and [SourceTableName] = @SourceTableName
					and [TargetTableName] =  coalesce(@TargetTableName,  @SourceTableName)
					and [TargetTableSchema] = coalesce(@TargetTableSchema,  @SourceTableSchema) ) 
BEGIN
	
	SELECT @tablesID = [ETLImportTablesKey]
	FROM [stg].[ETLImportTables]
	WHERE [SourceTableSchema] = @SourceTableSchema
		and [SourceTableName] = @SourceTableName
		and [TargetTableName] =  coalesce(@TargetTableName,  @SourceTableName)
		and [TargetTableSchema] = coalesce(@TargetTableSchema,  @SourceTableSchema)

END ELSE BEGIN

		INSERT INTO [stg].[ETLImportTables]
           ([ImportGroup]
           ,[SourceTableSchema]
           ,[SourceTableName]
           ,[TargetTableSchema]
           ,[TargetTableName]
           ,[SourceWhereClause]
           ,[ClearTableStatement])
		SELECT
			[ImportGroup] = @group
           ,[SourceTableSchema] = @SourceTableSchema
           ,[SourceTableName] = @SourceTableName
           ,[TargetTableSchema] = coalesce(@TargetTableSchema,  @SourceTableSchema)
           ,[TargetTableName] = coalesce(@TargetTableName,  @SourceTableName)
           ,[SourceWhereClause] = null
           ,[ClearTableStatement] = 'DELETE FROM ' + coalesce(@TargetTableSchema,  @SourceTableSchema) + '.' + coalesce(@TargetTableName,  @SourceTableName) + 
										coalesce('WHERE ' + @sourceFilterColumn +' = @sourceSystemKey ', '')

		SELECT @tablesID = @@IDENTITY

END

	INSERT INTO [stg].[ETLImportColumns]
           ([ETLImportTablesKey]
           ,[SourceColumnName]
           ,[TargetColumnName]
           ,[DataType]
           ,[DataMaxLenght])	
	SELECT  [ETLImportTablesKey] = convert(nvarchar(5), @tablesID) 
           ,[SourceColumnName] = COLUMN_NAME
           ,[TargetColumnName] = COLUMN_NAME
           ,[DataType] = DATA_TYPE
           ,[DataMaxLenght]	 = CHARACTER_MAXIMUM_LENGTH 
		
	FROM INFORMATION_SCHEMA.COLUMNS i
		left outer join [ETLImportColumns] t
			on t.[TargetColumnName] = i.COLUMN_NAME
				and t.ETLImportTablesKey = @tablesID
	WHERE TABLE_NAME =  @TargetTableName
	 and TABLE_SCHEMA = @TargetTableSchema
	 and i.COLUMN_NAME <> @sourceFilterColumn
	 and t.ETLImportColumnKey is null	 ;



select * from [stg].[ETLImportColumns]
where ETLImportTablesKey = @tablesID

select * from [stg].[ETLImportTables]
where ETLImportTablesKey = @tablesID


end


GO





