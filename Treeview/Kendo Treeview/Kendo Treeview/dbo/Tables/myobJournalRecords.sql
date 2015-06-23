CREATE TABLE [dbo].[myobJournalRecords] (
    [SetID]                  INT         NULL,
    [JournalRecordID]        INT         NULL,
    [LineNumber]             INT         NULL,
    [Date]                   DATE        NULL,
    [TransactionDate]        DATE        NULL,
    [IsThirteenthPeriod]     VARCHAR (1) NULL,
    [AccountID]              INT         NULL,
    [TaxExclusiveAmount]     FLOAT (53)  NULL,
    [JobID]                  INT         NULL,
    [EntryIsPurged]          VARCHAR (1) NULL,
    [IsForeignTransaction]   VARCHAR (1) NULL,
    [IsExchangeConversion]   VARCHAR (1) NULL,
    [ReconciliationStatusID] VARCHAR (1) NULL,
    [DateReconciled]         DATE        NULL,
    [UserID]                 INT         NULL,
    [RecordSessionDate]      DATE        NULL,
    [RecordSessionTime]      VARCHAR (8) NULL,
    [IsMultipleJob]          VARCHAR (1) NULL,
    [EntityID]               SMALLINT    NULL
);

