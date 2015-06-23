CREATE TABLE [dbo].[HierEntity] (
    [EntityHierID] INT          IDENTITY (-10, -1) NOT NULL,
    [EntityName]   VARCHAR (30) NOT NULL,
    [ParentID]     INT          NULL,
    CONSTRAINT [PK_HierEntity] PRIMARY KEY CLUSTERED ([EntityHierID] ASC)
);

