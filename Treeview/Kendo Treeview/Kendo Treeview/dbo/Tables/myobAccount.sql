﻿CREATE TABLE [dbo].[myobAccount] (
    [AccountID]                  INT           NULL,
    [ParentAccountID]            INT           NULL,
    [IsInactive]                 VARCHAR (1)   NULL,
    [AccountName]                VARCHAR (30)  NULL,
    [AccountNumber]              VARCHAR (6)   NULL,
    [TaxCodeID]                  INT           NULL,
    [CurrencyID]                 INT           NULL,
    [CurrencyExchangeAccountID]  INT           NULL,
    [AccountClassificationID]    VARCHAR (4)   NULL,
    [SubAccountClassificationID] VARCHAR (3)   NULL,
    [AccountLevel]               SMALLINT      NULL,
    [AccountTypeID]              VARCHAR (1)   NULL,
    [LastChequeNumber]           INT           NULL,
    [IsReconciled]               VARCHAR (1)   NULL,
    [LastReconciledDate]         DATE          NULL,
    [StatementBalance]           FLOAT (53)    NULL,
    [IsCreditBalance]            VARCHAR (1)   NULL,
    [OpeningAccountBalance]      FLOAT (53)    NULL,
    [CurrentAccountBalance]      FLOAT (53)    NULL,
    [PreLastYearActivity]        FLOAT (53)    NULL,
    [LastYearOpeningBalance]     FLOAT (53)    NULL,
    [ThisYearOpeningBalance]     FLOAT (53)    NULL,
    [PostThisYearActivity]       FLOAT (53)    NULL,
    [AccountDescription]         VARCHAR (255) NULL,
    [IsTotal]                    VARCHAR (1)   NULL,
    [CashFlowClassificationID]   VARCHAR (3)   NULL,
    [BSBCode]                    VARCHAR (9)   NULL,
    [BankAccountNumber]          VARCHAR (20)  NULL,
    [BankAccountName]            VARCHAR (32)  NULL,
    [CompanyTradingName]         VARCHAR (50)  NULL,
    [CreateBankFiles]            VARCHAR (1)   NULL,
    [BankCode]                   VARCHAR (3)   NULL,
    [DirectEntryUserID]          VARCHAR (6)   NULL,
    [IsSelfBalancing]            VARCHAR (1)   NULL,
    [StatementParticulars]       VARCHAR (12)  NULL,
    [StatementCode]              VARCHAR (12)  NULL,
    [StatementReference]         VARCHAR (12)  NULL,
    [AccountantLinkCode]         VARCHAR (9)   NULL,
    [EntityID]                   SMALLINT      NULL
);
