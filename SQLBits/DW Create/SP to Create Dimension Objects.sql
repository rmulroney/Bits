
/****** Object:  StoredProcedure [stg].[uspGenerateDimension]    Script Date: 13/02/2015 6:34:07 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


--###########################################################################333
--	Rm 2015-02-13
--		Creates Dimension DB objects from source Table.

--###########################################################################333


/*


if exists ( select 1 from INFORMATION_SCHEMA.TABLES
			where TABLE_NAME = 'mstDebtor')
	drop table mstDebtor


if exists ( select 1 from INFORMATION_SCHEMA.TABLES
			where TABLE_NAME = 'hierDebtor')
	drop table hierDebtor



if exists ( select 1 from INFORMATION_SCHEMA.TABLES
			where TABLE_NAME = 'vwDimDebtor')
	drop view vwDimDebtor


declare 
	 @dimName as varchar(50)
	,@stgTable as varchar(50) 
	,@stgSchema as varchar(50) = 'stg'
	,@businessKey as nvarchar(50)
	,@descColumn as nvarchar(50)
	,@createHier bit = 0
	,@tablePrefix varchar(3) = 'dim'

	select @stgTable = 'CMF' 
	,@stgSchema = 'stg'
	,@tablePrefix = 'mst'
	,@dimName = 'Debtor'
*/

ALTER proc [stg].[uspGenerateDimension] (
	@dimName as varchar(50)
	,@stgTable as varchar(50) 
	,@stgSchema as varchar(50) = 'stg'
	,@businessKey as nvarchar(50)
	,@descColumn as nvarchar(50)
	,@createHier bit = 0
	,@tablePrefix varchar(3) = 'dim'
) as 

begin
 

declare @sql as nvarchar(max), 
	@codeDataType varchar(10),
	@codeLenght varchar(10),  
	@descDataType varchar(10),
	@descLenght varchar(10), 
	@ordinal int = 1

--########################################
-- Guess at the Business Key
--########################################


if @descColumn is null

	select top 1 @descColumn = Column_name
				,@descDataType = DATA_TYPE
				,@descLenght= coalesce(CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION)
	from INFORMATION_SCHEMA.COLUMNS
	where (
			TABLE_NAME = @stgTable
		and TABLE_SCHEMA = @stgSchema
	)
	and  ( 
		 Column_name like '%Desc%'
	  or column_name like '%Name%'
	  or COLUMN_name like '%Id' 
	  or (COLUMN_name like '%number%' and  COLUMN_name not like '%phone%' )
	)
	order by ORDINAL_POSITION

if @businessKey is null

	select top 1 @businessKey = Column_name
				,@codeDataType = DATA_TYPE
				,@codeLenght= coalesce(CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION)
	from INFORMATION_SCHEMA.COLUMNS
	where (
			TABLE_NAME = @stgTable
		and TABLE_SCHEMA = @stgSchema
	)
	and (
		 Column_name like '%code%'
	  or COLUMN_name like '%Id' 

	)
	order by ORDINAL_POSITION



--########################################
-- Create leaf Table
--########################################


select @sql = 'CREATE TABLE [dbo].[' + @tablePrefix + @dimName +'] (
	[' + @dimName + 'Key] [int] IDENTITY(1,1) NOT NULL,
	[' + @dimName + 'Code] [' + @codeDataType + ']' + case when @codeLenght is null then '' when @codeDataType = 'int' then '' else coalesce('(' + @codeLenght + ')', '') end + ' NOT NULL, 
	[' + @dimName + 'Desc] [' + @descDataType + ']' + case when @descLenght is null then '' when @descDataType = 'int' then '' else coalesce('(' + @descLenght  + ')', '') end + ' NOT NULL, '
	


while exists( select 1
			  from INFORMATION_SCHEMA.COLUMNS
				where TABLE_NAME = @stgTable
					and TABLE_SCHEMA = @stgSchema
					and ORDINAL_POSITION >= @ordinal   )
begin

	select  @sql = @sql + '[' + replace(COLUMN_NAME, '_', '') + '] [' + DATA_TYPE + ']' 
									+	case when DATA_TYPE = 'int' then '' else  coalesce(
											'(' + convert(varchar(10),CHARACTER_MAXIMUM_LENGTH) + ')', 
											'(' + convert(varchar(10), NUMERIC_PRECISION) +')'
											 , '') end + ' NULL, '
							
	from INFORMATION_SCHEMA.COLUMNS
	where TABLE_NAME = @stgTable
		and TABLE_SCHEMA = @stgSchema
		and ORDINAL_POSITION = @ordinal  
		and COLUMN_NAME not in ( @descColumn, @businessKey )

	
	select @ordinal = @ordinal + 1

end

-- Add Hierarchy
if @createHier = 1
	select @sql = @sql + '[' + @dimName + 'HierKey] [int] NULL, '


-- add key
select @sql = @sql + '
	 CONSTRAINT [PK_' + @tablePrefix + @dimName + '] PRIMARY KEY CLUSTERED 
	(
		[' + @dimName + 'Key] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]   '

print @sql 


exec sp_executeSql @sql


-- successfully Created?
if not exists ( select 1 from INFORMATION_SCHEMA.TABLES
			where TABLE_NAME = @tablePrefix + @dimName)
begin
	raiserror('Error Creating Dim Table', 16,1)
	return;
end


--########################################
-- Create Hier Table
--########################################

if @createHier = 1 
begin 
	select @sql = 'CREATE TABLE [dbo].[hier' + @dimName +'] (
		[HierKey] [int] IDENTITY(-10,-1) NOT NULL,
		[parentKey] [int] NULL,
		[sortOrder] [int] NULL CONSTRAINT [DF_hierAccount_sortOrder]  DEFAULT ((1)),
		[reportingScale] [int] NULL,
		[HierDesc] [varchar](250) NOT NULL CONSTRAINT [DF_hierAccount_accountHier]  DEFAULT (''N/A''),
		 CONSTRAINT [PK_HierAccount] PRIMARY KEY CLUSTERED 
	(
		[accountHierKey] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]'

	print @sql;
	exec sp_executeSql @sql;


	-- successfully Created?
	if not exists ( select 1 from INFORMATION_SCHEMA.TABLES
				where TABLE_NAME = 'hier' + @dimName )
	begin
		raiserror('Error Creating hier Table', 16,1)
		return;
	end

	-- create foreign key between hier and leaf

	select @sql = 'ALTER TABLE [dbo].[' + @tablePrefix + @dimName + ']  WITH CHECK ADD  CONSTRAINT [FK_' + @tablePrefix + @dimName + '_hier'+ @dimName +'] FOREIGN KEY([' + @dimName + 'HierKey])
					REFERENCES [dbo].[hier'+ @dimName + '] ([HierKey])'

	print @sql;
	exec sp_executeSql @sql;
	

end


--########################################
-- TBC Add Create Parent Child
--########################################

select 'Add Parent child View' as TBC


--########################################
-- TBC Populate Dimension Manager Tables
--########################################

select 'Populate Dimension Manager Tables' as TBC


--########################################
-- Create dim View
--########################################

select @ordinal = 1
select @sql = 'CREATE VIEW [vwDim'  + @dimName + '] as '
				+char(13) + char(9) + 
				'SELECT ' +char(13)


while exists( select 1
			  from INFORMATION_SCHEMA.COLUMNS
				where TABLE_NAME = @tablePrefix + @dimName
					and ORDINAL_POSITION >= @ordinal   )
begin

	select @sql = @sql + char(9) + char(9) + case when ORDINAL_POSITION = 1 then ' [' else ',[' end
				 + COLUMN_NAME + '] = d.[' + COLUMN_NAME + ']'  +char(13)
	from INFORMATION_SCHEMA.COLUMNS
	where TABLE_NAME = @tablePrefix + @dimName
		and ORDINAL_POSITION = @ordinal  

	select @ordinal = @ordinal + 1

end

--########################################
-- TBC Add parent Child Columns to view
--########################################


if @createHier = 1 
begin 

	select 'Add parent Child Columns to view' as TBC
-- a'la: 

	/*
	
	

		select @ordinal = 1
		while exists( select 1
					  from INFORMATION_SCHEMA.COLUMNS
						where TABLE_NAME = 'vw' + @dimName + 'ParentChild'
							and ORDINAL_POSITION >= @ordinal   )
		begin

			select @sql = @sql + case when ORDINAL_POSITION = 1 then '[' else ',[' end
						 + COLUMN_NAME + '] = h.[' + COLUMN_NAME + ']'
			from INFORMATION_SCHEMA.COLUMNS
			where TABLE_NAME = 'vwHier' + @dimName + 'ParentChild'
				and ORDINAL_POSITION = @ordinal  

			select @ordinal = @ordinal + 1

		end 

	*/

end


-- view from clause

select @sql = @sql + 
			char(9) + 'FROM [' + @tablePrefix + @dimName + '] d'  + char(13) 


if @createHier = 1 
	select @sql = @sql + 
			char(9) + char(9) + 'left outer join  [vwHier' + @dimName + 'ParentChild] h' + char(13) +
			char(9) +char(9) +char(9) +'on d.[' + @dimName + 'HierKey] = h.hierKey  '


-- execute script to create view

print @sql;
exec sp_executeSql @sql;
	


--########################################
-- Insert Unknown Hier  Member
--########################################


if @createHier = 1 
begin 
	select @sql = 'INSERT INTO [hier' + @dimName +'] (
		[HierKey]
		[parentKey]
		[sortOrder]
		[reportingScale]
		[HierDesc]) values (
		-2, null, 1, 1, ''Unknown'')'


	print @sql;
	exec sp_executeSql @sql;

end 


--########################################
-- Insert Unknown Member
--########################################

select @sql = 'set identity_insert [' + @tablePrefix + @dimName + '] on;   '

select @ordinal = 1
select @sql = @sql + 'INSERT INTO  [' + @tablePrefix + @dimName + '] ( 
	 [' + @dimName + 'Key]
	,[' + @dimName + 'Code]
	,[' + @dimName + 'Desc]'


while exists( select 1
			  from INFORMATION_SCHEMA.COLUMNS
				where TABLE_NAME = @tablePrefix + @dimName 
					and ORDINAL_POSITION >= @ordinal   )
begin


	select  @sql = @sql + ',[' + COLUMN_NAME + ']'							
	from INFORMATION_SCHEMA.COLUMNS
	where TABLE_NAME =  @tablePrefix + @dimName 
		and ORDINAL_POSITION = @ordinal  
		and COLUMN_NAME not in ( @dimName + 'Key', @dimName + 'Code', @dimName + 'Desc', @dimName + 'HierKey' )

	select @ordinal = @ordinal + 1

end

-- add column for Hier key
if @createHier = 1
	select ',[' + @dimName + 'HierKey]'


select @ordinal = 1
select @sql = @sql + ') values ( -1 ,''N/A'' ,''Unknown'''

while exists( select 1
			  from INFORMATION_SCHEMA.COLUMNS
				where TABLE_NAME = @tablePrefix + @dimName 
					and ORDINAL_POSITION >= @ordinal   )
begin


	select  @sql = @sql + ',''' + 
							case when DATA_TYPE = 'int' then '0' 
								 when DATA_TYPE = 'date' then '' 
								 when DATA_TYPE = 'datetime' then '' 
								 when c.CHARACTER_MAXIMUM_LENGTH >= len('Unknown') then 'Unknown' 
								 when c.CHARACTER_MAXIMUM_LENGTH >= len('N/A') then 'N/A' 
								 else '-'    
							end							
						 + ''''
	from INFORMATION_SCHEMA.COLUMNS c
	where TABLE_NAME =  @tablePrefix + @dimName 
		and ORDINAL_POSITION = @ordinal  
		and COLUMN_NAME not in ( @dimName + 'Key', @dimName + 'Code', @dimName + 'Desc' )

	select @ordinal = @ordinal + 1

end


-- add column for Hier key
if @createHier = 1
	select ',-2' -- default hier key for the unknow member.


 select @sql = @sql + ');   '



select @sql = @sql + 'set identity_insert [' + @tablePrefix + @dimName + '] off;'
print @sql;
exec sp_executeSql @sql;



--########################################
-- Create Merge Proc
--########################################

select 'Create merge proc' as tbc




end 
GO


