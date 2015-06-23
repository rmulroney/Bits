--http://www.jhmcconnell.com/2012/04/16/sql-server-stored-procedure-to-return-json/

CREATE PROCEDURE dbo._ReturnJSON
 
@table_name nvarchar(50),
@WhereColumn nvarchar(256) = N'',
@WhereId nvarchar(256) = N'-1'
 
AS
 
DECLARE @i int
SET @i = 1 
 
DECLARE @TableColumns TABLE
(
  ColumnID int IDENTITY (1,1),
  Column_Name nvarchar(256),
  Data_Type nvarchar(256)
)
 
INSERT INTO @TableColumns
(Column_Name, Data_Type)
SELECT column_name, DATA_TYPE 
FROM information_schema.columns I
WHERE TABLE_NAME = @table_name
 
DECLARE @first bit
SET @first = 1
DECLARE @column_name nvarchar(256)
DECLARE @data_type nvarchar(256)
DECLARE @sql nvarchar(4000)
SET @sql = 'SELECT DISTINCT ''{'
 
WHILE @i < (SELECT MAX(ColumnID) FROM @TableColumns)
BEGIN
 SELECT @column_name = Column_Name, @data_type = Data_Type FROM @TableColumns WHERE ColumnID = @i
 SET @i = @i + 1
 
 IF @first = 1
    SET @sql += '"' + @column_name
 ELSE
    SET @sql += ', "' + @column_name
 
 SET @first = 0
 
 IF @data_type <> 'nvarchar' AND @data_type <> 'varchar'
        SET @sql += '":"'' + CAST(' + 'ISNULL(X.' + @column_name + ', '''') AS nvarchar(50)) + ''"'
     ELSE
        SET @sql += '":"'' + ' + 'ISNULL(X.' + @column_name + ', '''') + ''"'
END
 
SET @sql += + '}'' FROM information_schema.columns I INNER JOIN '
    + @table_name + ' X ON I.table_name = ''' + @table_name + ''''
 
IF @WhereColumn <> N''
    SET @sql += ' WHERE X.' + @WhereColumn + ' = ''' + @WhereId + ''''
 
EXECUTE sp_executesql @sql
 
