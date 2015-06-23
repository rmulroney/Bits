CREATE TABLE [dbo].[DimJob] (
    [JobID]     INT          IDENTITY (1, 1) NOT NULL,
    [JobName]   VARCHAR (50) NOT NULL,
    [JobNumber] VARCHAR (15) NOT NULL,
    [JobHierID] INT          NULL,
    CONSTRAINT [PK_DimJob] PRIMARY KEY CLUSTERED ([JobID] ASC),
    CONSTRAINT [FK_DimJob_HierJob] FOREIGN KEY ([JobHierID]) REFERENCES [dbo].[HierJob] ([JobHierID])
);

