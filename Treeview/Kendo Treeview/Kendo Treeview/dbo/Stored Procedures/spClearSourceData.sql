
-- =============================================
-- Author:		Robert Mulroney
-- Create date: 2012-07-01
-- Description:	Clear the existing MYOB data
-- =============================================
CREATE PROCEDURE [dbo].[spClearSourceData]
	
AS
BEGIN
	
	truncate table [dbo].[myobAccount]
	--truncate table [dbo].[myobAccountClassification]	
	--truncate table [dbo].[myobCustomer]
	--truncate table [dbo].[myobJob]
	truncate table [dbo].[myobJournalRecords]
	truncate table [dbo].[myobJournalSets]
	truncate table [dbo].[myobJournalTypes]
	truncate table [dbo].[myobSubAccountTypes]
	truncate table [dbo].[myobDataFileInformation]

END


