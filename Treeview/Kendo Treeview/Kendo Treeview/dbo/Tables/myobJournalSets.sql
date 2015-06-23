CREATE TABLE [dbo].[myobJournalSets] (
    [SetID]                   INT           NULL,
    [JournalTypeID]           VARCHAR (3)   NULL,
    [SourceID]                INT           NULL,
    [TransactionNumber]       VARCHAR (10)  NULL,
    [Memo]                    VARCHAR (255) NULL,
    [CurrencyID]              INT           NULL,
    [TransactionExchangeRate] FLOAT (53)    NULL,
    [EntityID]                SMALLINT      NULL
);

