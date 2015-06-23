-- =============================================
-- Author:		Robert Mulroney
-- Create date: 2013-07-05
-- Description:	Process Cube
-- =============================================
CREATE PROCEDURE [dbo].[spProcessBudgetPartition]	
AS
Begin

	Declare @myXMLA nvarchar(max)
	

Set @myXMLA ='<Batch xmlns="http://schemas.microsoft.com/analysisservices/2003/engine">
			  <Parallel>
				<Process xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:ddl2="http://schemas.microsoft.com/analysisservices/2003/engine/2" xmlns:ddl2_2="http://schemas.microsoft.com/analysisservices/2003/engine/2/2" xmlns:ddl100_100="http://schemas.microsoft.com/analysisservices/2008/engine/100/100" xmlns:ddl200="http://schemas.microsoft.com/analysisservices/2010/engine/200" xmlns:ddl200_200="http://schemas.microsoft.com/analysisservices/2010/engine/200/200" xmlns:ddl300="http://schemas.microsoft.com/analysisservices/2011/engine/300" xmlns:ddl300_300="http://schemas.microsoft.com/analysisservices/2011/engine/300/300">
				  <Object>
					<DatabaseID>MYOB</DatabaseID>
					<CubeID>MYOB</CubeID>
				  </Object>
				  <Type>ProcessFull</Type>
				  <WriteBackTableCreation>UseExisting</WriteBackTableCreation>
				</Process>
			  </Parallel>
			</Batch>'

Exec (@myXMLA) At ssasCloud;

END

