CREATE TABLE [dbo].[wbFactBudget] (
    [TransactionDate] INT        NOT NULL,
    [AccountID]       INT        NOT NULL,
    [JournalAmount]   FLOAT (53) NOT NULL,
    [JobID]           INT        NOT NULL,
    [EntityID]        SMALLINT   NOT NULL,
    [VersionID]       INT        NOT NULL,
    CONSTRAINT [FK_FactBudget_DimDate] FOREIGN KEY ([TransactionDate]) REFERENCES [dbo].[DimDate] ([dateId]),
    CONSTRAINT [FK_FactBudget_DimVersion] FOREIGN KEY ([VersionID]) REFERENCES [dbo].[DimVersion] ([VersionID]),
    CONSTRAINT [FK_wbFactBudget_DimAccount] FOREIGN KEY ([AccountID]) REFERENCES [dbo].[DimAccount] ([AccountID]),
    CONSTRAINT [FK_wbFactBudget_DimJob] FOREIGN KEY ([JobID]) REFERENCES [dbo].[DimJob] ([JobID])
);

