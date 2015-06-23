USE [dreamDW]
GO
/****** Object:  StoredProcedure [dbo].[spUTIL_ObjectsThatUseTheseCharacters]    Script Date: 10/12/2013 4:17:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[spUTIL_ObjectsThatUseTheseCharacters] ( @ChartoFind nvarchar(2000) )
AS

begin
    SET NOCOUNT ON

  SELECT    DISTINCT USER_NAME(o.uid) + '.' + OBJECT_NAME(c.id) AS 'Object name',
        CASE 
             WHEN OBJECTPROPERTY(c.id, 'IsReplProc') = 1 
                THEN 'Replication stored procedure'
             WHEN OBJECTPROPERTY(c.id, 'IsExtendedProc') = 1 
                THEN 'Extended stored procedure'                
            WHEN OBJECTPROPERTY(c.id, 'IsProcedure') = 1 
                THEN 'Stored Procedure' 
            WHEN OBJECTPROPERTY(c.id, 'IsTrigger') = 1 
                THEN 'Trigger' 
            WHEN OBJECTPROPERTY(c.id, 'IsTableFunction') = 1 
                THEN 'Table-valued function' 
            WHEN OBJECTPROPERTY(c.id, 'IsScalarFunction') = 1 
                THEN 'Scalar-valued function'
             WHEN OBJECTPROPERTY(c.id, 'IsInlineFunction') = 1 
                THEN 'Inline function'    
             WHEN OBJECTPROPERTY(c.id, 'IsView') = 1 
                THEN 'View'    
        END AS 'Object type',
        'EXEC sp_helptext ''' + USER_NAME(o.uid) + '.' + OBJECT_NAME(c.id) + '''' AS 'Run this command to see the object text'
    FROM    syscomments c
        INNER JOIN
        sysobjects o
        ON c.id = o.id
    WHERE    c.text LIKE '%' + @ChartoFind + '%'    AND
        encrypted = 0                AND
        (
        OBJECTPROPERTY(c.id, 'IsReplProc') = 1        OR
        OBJECTPROPERTY(c.id, 'IsExtendedProc') = 1    OR
        OBJECTPROPERTY(c.id, 'IsProcedure') = 1        OR
        OBJECTPROPERTY(c.id, 'IsTrigger') = 1        OR
        OBJECTPROPERTY(c.id, 'IsTableFunction') = 1    OR
        OBJECTPROPERTY(c.id, 'IsScalarFunction') = 1    OR
        OBJECTPROPERTY(c.id, 'IsInlineFunction') = 1    OR
        OBJECTPROPERTY(c.id, 'IsView') = 1    
        )

    ORDER BY    'Object type', 'Object name'

--    SET @RowsReturned = @@ROWCOUNT

end
