
-- =============================================
Create FUNCTION [dbo].[fnSplitParameters2] 
( 
 @inputstring Varchar(max),
 @delim varchar(10)
)
returns @result TABLE (Value varchar(max))
AS
Begin

 Declare @temp as varchar(max)
 Declare @xml as xml
 
 Set @temp=('<x>' + replace(@inputstring ,@delim, '</x><x>') + '</x>' )
 --Select @temp

 Set @xml=Cast(@temp as xml)
 --select @xml

 Insert Into @result
 Select N.value('.', 'varchar(10)') as value 
 From @xml.nodes('x') as T(N)
 
 Return
End




