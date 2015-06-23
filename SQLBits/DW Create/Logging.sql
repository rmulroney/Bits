

/****** Object:  Table [dbo].[LogETL]    Script Date: 22/02/2015 12:29:42 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING OFF
GO

CREATE TABLE [dbo].[LogETL](
	[LogID] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [varchar](50) NOT NULL,
	[ProcessStarted] [datetime] NOT NULL,
	[ProcessDurationSec] [money] NULL,
	[StoredProcedure] [varchar](500) NULL,
	[DataPoint] [varchar](8000) NULL,
	[SQLExecuted] [varchar](8000) NULL,
	[CodePath] [varchar](8000) NULL,
	[ProcessErrorMessage] [varchar](8000) NULL,
	[ProcessSuccesful] [smallint] NOT NULL,
 CONSTRAINT [PK_PlanningSysAdSecLogsProcs] PRIMARY KEY CLUSTERED 
(
	[LogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[LogETL] ADD  CONSTRAINT [DF_LogProcs_ProcessSuccesful]  DEFAULT ((0)) FOR [ProcessSuccesful]
GO



/****** Object:  UserDefinedTableType [Student].[LogProcs]    Script Date: 22/02/2015 12:30:48 PM ******/
CREATE TYPE [dbo].[LogProcs] AS TABLE(
	[LogID] [int] NULL,
	[UserID] [varchar](50) NOT NULL,
	[ProcessStarted] [datetime] NOT NULL,
	[ProcessDurationSec] [money] NULL,
	[StoredProcedure] [varchar](500) NULL,
	[DataPoint] [varchar](8000) NULL,
	[SQLExecuted] [varchar](8000) NULL,
	[CodePath] [varchar](8000) NULL,
	[ProcessErrorMessage] [varchar](8000) NULL,
	[ProcessSuccesful] [varchar](8000) NULL
)
GO






CREATE PROC [dbo].[uspProcLogging] (
	 @procName nvarchar(255) =  'uspDrillJournal'
	,@datapoint bit = 0
	,@loggingTable nvarchar(255) = '[dbo].[LogDrillWB]'

) as begin 

-- Uses the information schema to create the code necessary for procedure logging. 



	--############################################################
	-- Loggging Init
	--############################################################

	SELECT 
	'
--#################################################
-- Log Process
--#################################################

	Declare @Userid int = -1
	,@LogID int 
	,@RowsImpacted int

	Declare @Logtable dbo.LogProcs;


	INSERT INTO  @Logtable
			([UserID]
			,[ProcessStarted]
			,[ProcessDurationSec]
			,[StoredProcedure]
			,[DataPoint]
			,[SQLExecuted]
			,[CodePath]
			,[ProcessErrorMessage]
			,[ProcessSuccesful])
		VALUES
			(@loginId
			,getdate()
			,-1 '  as head 
		   
	UNION ALL 

	SELECT '		,''[' + SPECIFIC_SCHEMA + '].[' + SPECIFIC_NAME + ']'''
	FROM INFORMATION_SCHEMA.ROUTINES 
	WHERE	specific_name = @procName

	UNION ALL 

	
	SELECT case when @datapoint = 1 then '	,@datapoint' else '		,null' end
	

	UNION ALL 

	SELECT '		,''exec [' + SPECIFIC_SCHEMA + '].[' + SPECIFIC_NAME +  '] '''
	FROM INFORMATION_SCHEMA.ROUTINES 
	WHERE	specific_name = @procName

	UNION ALL

	SELECT '		+ '', '+ PARAMETER_NAME + ' = '' + convert(nvarchar(50), ' + PARAMETER_NAME + ')  '
	FROM INFORMATION_SCHEMA.PARAMETERS 
	WHERE	specific_name = @procName

	UNION ALL 

	SELECT 
' 		   ,''''
			,null
			,-1)


	INSERT INTO  '+ @loggingTable +' ([UserID] ,[ProcessStarted],[StoredProcedure], [ProcessSuccesful] )
		SELECT [UserID] ,[ProcessStarted] ,[StoredProcedure], [ProcessSuccesful]
		FROM  @Logtable

	SET @LogID = SCOPE_IDENTITY()

	UPDATE @Logtable SET LogID = @LogID 
	
BEGIN TRY'

	   
	--#########################################################
	-- Record outcome.
	--#########################################################


	SELECT 
'END TRY
BEGIN CATCH
    
	UPDATE @Logtable
	SET ProcessErrorMessage = error_message()
		,ProcessSuccesful = 0; 


END CATCH;



--#########################################################
-- Log proc success/failure
--#########################################################

	UPDATE @Logtable set [ProcessDurationSec] = datediff(ms, ProcessStarted, getdate()) / 1000.0000

	UPDATE l
	SET
			[ProcessDurationSec] = lt.[ProcessDurationSec]
		,[ProcessErrorMessage] = lt.ProcessErrorMessage
		,ProcessSuccesful =  case lt.[ProcessSuccesful] when 0 then 0 else 1 end 
		,[codePath] = lt.CodePath
		,[SQLExecuted] = lt.[SQLExecuted]
	FROM ' + @loggingTable + 'as l
	JOIN @Logtable as lt on lt.LogID = l.LogID
'

END 