CREATE TABLE [dbo].[FactOpeningBal] (
    [TransactionDate]   INT           NOT NULL,
    [AccountID]         INT           NOT NULL,
    [JournalAmount]     FLOAT (53)    NOT NULL,
    [JobID]             INT           NOT NULL,
    [EntityID]          SMALLINT      NOT NULL,
    [VersionID]         INT           NOT NULL,
    [JournalDesc]       VARCHAR (255) NULL,
    [TransactionNumber] VARCHAR (10)  NULL,
    CONSTRAINT [FK_FactOpeningBal_DimAccount] FOREIGN KEY ([AccountID]) REFERENCES [dbo].[DimAccount] ([AccountID]),
    CONSTRAINT [FK_FactOpeningBal_DimDate] FOREIGN KEY ([TransactionDate]) REFERENCES [dbo].[DimDate] ([dateId]),
    CONSTRAINT [FK_FactOpeningBal_DimJob] FOREIGN KEY ([JobID]) REFERENCES [dbo].[DimJob] ([JobID]),
    CONSTRAINT [FK_FactOpeningBal_DimVersion] FOREIGN KEY ([VersionID]) REFERENCES [dbo].[DimVersion] ([VersionID])
);

