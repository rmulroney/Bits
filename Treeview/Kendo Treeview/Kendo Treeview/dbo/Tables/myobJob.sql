CREATE TABLE [dbo].[myobJob] (
    [CustomerID]              INT           NULL,
    [IsInactive]              VARCHAR (1)   NULL,
    [JobID]                   INT           NULL,
    [ParentJobID]             INT           NULL,
    [JobName]                 VARCHAR (25)  NULL,
    [JobNumber]               VARCHAR (15)  NULL,
    [IsHeader]                VARCHAR (1)   NULL,
    [JobLevel]                SMALLINT      NULL,
    [IsTrackingReimburseable] VARCHAR (1)   NULL,
    [JobDescription]          VARCHAR (255) NULL,
    [ContactName]             VARCHAR (25)  NULL,
    [Manager]                 VARCHAR (25)  NULL,
    [PercentCompleted]        FLOAT (53)    NULL,
    [StartDate]               DATE          NULL,
    [FinishDate]              DATE          NULL,
    [EntityID]                SMALLINT      NULL
);

