CREATE TABLE [dbo].[DimEntity] (
    [EntityID]       INT          NOT NULL,
    [EntityName]     VARCHAR (50) NULL,
    [ParentEntityID] INT          NULL,
    CONSTRAINT [PK_DimEntity] PRIMARY KEY CLUSTERED ([EntityID] ASC)
);

