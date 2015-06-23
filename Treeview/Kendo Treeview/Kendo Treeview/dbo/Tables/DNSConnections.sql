CREATE TABLE [dbo].[DNSConnections] (
    [DNS]      VARCHAR (50) NOT NULL,
    [EntityID] INT          IDENTITY (1, 1) NOT NULL,
    [Active]   BIT          NOT NULL,
    CONSTRAINT [PK_DNSConnections] PRIMARY KEY CLUSTERED ([DNS] ASC)
);

