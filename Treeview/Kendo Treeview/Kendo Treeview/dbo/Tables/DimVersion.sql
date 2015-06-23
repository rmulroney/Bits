CREATE TABLE [dbo].[DimVersion] (
    [VersionID]       INT          NOT NULL,
    [VersionType]     VARCHAR (20) NOT NULL,
    [AllowsWriteback] BIT          NULL,
    CONSTRAINT [PK_DimVersion] PRIMARY KEY CLUSTERED ([VersionID] ASC)
);

