
CREATE TABLE [dbo].[DimRelativePeriod](
	[relativePeriodCode] [int] NOT NULL,
	[relativePeriodId] [varchar](10) NOT NULL,
	[relativePeriodDescription] [varchar](50) NOT NULL,
	[sortOrder] [int] NULL,
 CONSTRAINT [PK_DimRelativePeriod] PRIMARY KEY CLUSTERED 
(
	[relativePeriodCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO



INSERT INTO [dbo].[DimRelativePeriod]
           ([relativePeriodCode]
           ,[relativePeriodId]
           ,[relativePeriodDescription]
           ,[sortOrder])
     VALUES
	
           (1
           ,'CUR'
           ,'Current Period'
           ,1),

		 (2
           ,'YTD'
           ,'Year to Date'
           ,2),

		 (3
           ,'FY'
           ,'Full Year'
           ,3),

		 (4
           ,'PY'
           ,'Prior Year'
           ,4),

		 (5
           ,'PYTD'
           ,'Prior Year To Date'
           ,5),

		 (6
           ,'PYF'
           ,'Prior Year Full Year'
           ,6)

    
GO

Create view vwDimRelativePeriod as 



SELECT [relativePeriodCode]
      ,[relativePeriodId]
      ,[relativePeriodDescription]
      ,[sortOrder]
  FROM [dbo].[DimRelativePeriod]


