CREATE TABLE [dbo].[FactJournal] (
    [TransactionDate]   INT           NOT NULL,
    [AccountID]         INT           NOT NULL,
    [JournalAmount]     FLOAT (53)    NOT NULL,
    [JobID]             INT           NOT NULL,
    [EntityID]          INT           NOT NULL,
    [VersionID]         INT           NOT NULL,
    [JournalDesc]       VARCHAR (255) NULL,
    [TransactionNumber] VARCHAR (10)  NULL,
    CONSTRAINT [FK_FactJournal_DimAccount] FOREIGN KEY ([AccountID]) REFERENCES [dbo].[DimAccount] ([AccountID]),
    CONSTRAINT [FK_FactJournal_DimDate] FOREIGN KEY ([TransactionDate]) REFERENCES [dbo].[DimDate] ([dateId]),
    CONSTRAINT [FK_FactJournal_DimJob] FOREIGN KEY ([JobID]) REFERENCES [dbo].[DimJob] ([JobID]),
    CONSTRAINT [FK_FactJournal_DimVersion] FOREIGN KEY ([VersionID]) REFERENCES [dbo].[DimVersion] ([VersionID])
);

