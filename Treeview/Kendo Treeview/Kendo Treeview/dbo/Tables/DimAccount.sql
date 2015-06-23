CREATE TABLE [dbo].[DimAccount] (
    [AccountID]     INT          IDENTITY (1, 1) NOT NULL,
    [AccountName]   VARCHAR (50) NOT NULL,
    [AccountNumber] VARCHAR (10) NOT NULL,
    [AccountHierID] INT          NULL,
    CONSTRAINT [PK_DimAccount] PRIMARY KEY CLUSTERED ([AccountID] ASC),
    CONSTRAINT [FK_DimAccount_HierAccount] FOREIGN KEY ([AccountHierID]) REFERENCES [dbo].[HierAccount] ([AccountHierID])
);

