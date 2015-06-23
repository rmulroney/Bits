CREATE TABLE [dbo].[HierAccount] (
    [AccountHierID] INT          IDENTITY (-10, -1) NOT NULL,
    [AccountName]   VARCHAR (30) NOT NULL,
    [AccountNumber] VARCHAR (6)  NOT NULL,
    [ParentID]      INT          NULL,
    [SetbyEntity]   INT          NULL,
    CONSTRAINT [PK_HierAccount] PRIMARY KEY CLUSTERED ([AccountHierID] ASC)
);

