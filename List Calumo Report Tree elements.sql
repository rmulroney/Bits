alter proc [dbo].[spGetUploadedDoc] (
    @folderId as int  = 15, 
    @calumoDBName as varchar(50) = '[calumo_savills]'
) as  

begin 


-- In future releases the ApplicationNode table will be called DocumentNode
-- in this section we're checking which version of calumo we're using.

    declare @calumoTreeTable varchar(20),
		  @sql nvarchar(max)



    set @sql = @calumoDBName + '..ApplicationNodes'
    if OBJECT_ID(@sql) IS NOT NULL    begin
	  set @calumoTreeTable  = 'ApplicationNodes'

    end else begin

	   set @sql = @calumoDBName + '..DocumentNode'
        if OBJECT_ID(@sql) IS NOT NULL    	  
		  set @calumoTreeTable  = 'DocumentNode'
	   else RAISERROR ('Cannot Find Calumo Nodes Table', 16, 1, N'abcde'); -- First argument supplies the string.

    end


-- Get the folder list. 
    select @SQL = 'select [Name] 
				from ' + @calumoDBName + '.[dbo].' + @calumoTreeTable + '
				where NodeType in (8)
				and ParentID = ' + convert( varchar(4), @folderId)

    exec( @sql)
    print @sql

end