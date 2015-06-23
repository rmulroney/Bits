sp_helptext '[dbo].[spCreateLinkedServer]'


-- or 


SELECT 
    ROUTINE_NAME, 
    ROUTINE_TYPE, 
    ROUTINE_DEFINITION as First4000, 
    OBJECT_DEFINITION(object_id(ROUTINE_NAME)) as FullDefinition
FROM 
    INFORMATION_SCHEMA.ROUTINES
WHERE 
    OBJECT_DEFINITION(object_id(ROUTINE_NAME)) LIKE @searchText
ORDER BY 
    ROUTINE_NAME