----------------------------------------------------------
--											 --
--  Uses the standard format of Fact and Dimension	 --
--  star schemas to create foreign key constraints.	 --
--											 --
----------------------------------------------------------

    declare 
	   @tableName as nvarchar(50), 
	   @DimColumnIdentifier as nvarchar(20),
	   @sql as nvarchar(max), 
	   @keyColumn as nvarchar(200), 
	   @DimensionTable as nvarchar(200)

    
--------------------------------------------
    -- Set the Fact Table name here --
--------------------------------------------

    SET @tableName = 'DrillGLActuals'
    SET @DimColumnIdentifier = 'Key'

--------------------------------------------



    -- A temp table to hold the column names
    IF OBJECT_ID('tempdb..#factTable') IS NOT NULL
	   DROP TABLE #factTable

    -- Use the info schema to get the Dimension Columns. According to Calumo's standard
    -- schema the dimension columns are postfixed with 'Code' but may also be 'Id'
    SELECT 
	   convert(nvarchar(200), Column_name) as keyColumn, 
	   convert(nvarchar(200), 'Dim' + 
		  upper(left(replace(Column_name, 'Key', ''), 1)) +
		  right(replace(Column_name, 'Key', ''), len( replace(Column_name, 'Key', '')) -1)
	   )    as Dimension	   
    INTO #factTable
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = @tableName
    and Column_name like '%' + @DimColumnIdentifier


    DECLARE fkCursor CURSOR FOR 
	   SELECT keyColumn, Dimension
	   FROM #factTable
    OPEN fkCursor

    FETCH NEXT FROM fkCursor INTO @keyColumn, @DimensionTable

    WHILE @@FETCH_STATUS = 0
    BEGIN

	   IF exists( 
		  SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
		  WHERE TABLE_NAME = @DimensionTable
	   ) BEGIN

		  BEGIN TRY 

			-- Create the Forign Key
			select @sql = 'ALTER TABLE [dbo].['+ @tableName +']  WITH CHECK ADD  CONSTRAINT [FK_' + @tableName + '_' + @DimensionTable + '] FOREIGN KEY(['+ @keyColumn +'])
    					  REFERENCES [dbo].[' + @DimensionTable + '] ([' + @keyColumn + ']) ' 

			 print(@sql)
			 exec(@sql)


		  END TRY
		  BEGIN CATCH
			 SELECT @sql as [table]				
				,ERROR_MESSAGE() AS ErrorMessage;
		  END CATCH;


		  
	   END

	   FETCH NEXT FROM fkCursor 
	   INTO @keyColumn, @DimensionTable

    END


    CLOSE fkCursor;
    DEALLOCATE fkCursor;

