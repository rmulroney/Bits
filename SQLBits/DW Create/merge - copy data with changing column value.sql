
-- Rm 2013-12-02 

-- Returns a table representing a merge statement for a given table.
-- The merge statment copies the data within that table into it's self changed
-- with the @changingColumn equal to @changingValue.
		
-- pre fix with  --> 
--		BEGIN TRANSACTION;

-- post fix with -->
--	IF @@TRANCOUNT > 0
--	    COMMIT TRANSACTION;
--	GO

--******************* this needs to be updated to allow for identity columns  ******************************************--

declare @tbl as varchar(50),			-- which table are we copying the data within
		@deleteWhere as nvarchar(max), -- additional param for deleteing
		@selectWhere as nvarchar(max), -- where clause for the select statment
		@changingColumn as nvarchar(max),  -- Which column in the source is changing.
		@changingValue as nvarchar(max),  -- what is it's new value.
		@includeDelete as bit = 0


set @tbl = 'factSales'


set @selectWhere = 'scenarioId = @sourceScenario  and [dateId] between @copyFrom and @copyTo'
set @deleteWhere = 'scenarioId = @targetScenario'

set @changingColumn = 'scenarioId'
set @changingValue  = '@targetScenario'

		select 'DECLARE @SummaryOfChanges TABLE(Change VARCHAR(20));  ' 

	union all 

		select 'BEGIN TRY ' 


	union all

		select 'MERGE  ' + @tbl + ' AS target USING		(			' as result


	union all

		select '    SELECT ' 
				  

	union all

	
		SELECT Case when row_number() over (order by  Column_name) <> 1 then '      ,' else '       ' end + Column_name
			+ case when Column_name = @changingColumn then ' = ' + @changingValue else '' end
		FROM information_schema.columns
		WHERE TABLE_NAME = @tbl

	union all

		select '    FROM ' + @tbl 

	union all

		select Case when coalesce(@selectWhere, '') = '' then '' else '    WHERE ' + @selectWhere end

	union all

		select ') AS SOURCE ON  '


	union all
	
		--  Match on Primay key
		select Case when row_number() over (order by  Column_name) <> 1 then '    AND ' else '        ' end + 
				'target.' + Column_name + ' = source.' + Column_name 
		from information_schema.table_constraints pk 
			inner join information_schema.key_column_usage c on c.table_name = pk.table_name 
				and c.constraint_name = pk.constraint_name
		where pk.table_name = @tbl
			and constraint_type = 'primary key'

	union all

		select 'WHEN MATCHED THEN UPDATE SET ' 

	union all

		SELECT Case when row_number() over (order by  Column_name) <> 1 then '      ,' else '       ' end + 
						 'target.' + Column_name + ' = source.' + column_name 
		FROM information_schema.columns
		WHERE TABLE_NAME = @tbl

	union all

		select 'WHEN NOT MATCHED THEN INSERT 		(	'

	union all

		SELECT  Case when row_number() over (order by  Column_name) <> 1 then '      ,' else '       ' end + Column_name 
			FROM information_schema.columns
		WHERE TABLE_NAME = @tbl

	union all

		select ') 		VALUES 		(' 

	union all

		SELECT  Case when row_number() over (order by  Column_name) <> 1 then '      ,' else '       ' end + 
					'source.' + Column_name
		FROM information_schema.columns
		WHERE TABLE_NAME = @tbl

	union all

		select ') WHEN NOT MATCHED BY SOURCE '
		where @includeDelete = 1

	union all 

		select ')  '
		where @includeDelete = 0

	union all 

		select Case when coalesce(@selectWhere, '') = '' then '' else 'and ' + @deleteWhere end
		where @includeDelete = 1

	union all 

		select 'THEN DELETE '
		where @includeDelete = 1

	union all 

		select ' OUTPUT $action INTO @SummaryOfChanges;
	SELECT ''' + @tbl +''' as [table], Change, COUNT(*) AS CountPerChange
	FROM @SummaryOfChanges
	GROUP BY Change; '

union all 

	select 'END TRY
BEGIN CATCH
    SELECT ''' + @tbl + ''' as [table]
        ,ERROR_NUMBER() AS ErrorNumber
        ,ERROR_SEVERITY() AS ErrorSeverity
        ,ERROR_STATE() AS ErrorState
        ,ERROR_PROCEDURE() AS ErrorProcedure
        ,ERROR_LINE() AS ErrorLine
        ,ERROR_MESSAGE() AS ErrorMessage;

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
END CATCH;
'




