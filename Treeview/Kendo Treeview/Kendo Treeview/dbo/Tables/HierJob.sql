CREATE TABLE [dbo].[HierJob] (
    [JobHierID]   INT          IDENTITY (-10, -1) NOT NULL,
    [JobName]     VARCHAR (50) NOT NULL,
    [JobNumber]   VARCHAR (15) NOT NULL,
    [ParentID]    INT          NULL,
    [SetbyEntity] INT          NULL,
    CONSTRAINT [PK_HierJob] PRIMARY KEY CLUSTERED ([JobHierID] ASC)
);

