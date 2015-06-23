

CREATE proc [dbo].[spCreateTally] (
@tallyLength int = 100000
)as 

begin

	IF OBJECT_ID('dbo.Tally') IS NOT NULL 
	DROP TABLE dbo.Tally

	declare @sql varchar(max)
	set @sql = '
		SELECT TOP ' + cast(@tallyLength as varchar) + ' 
		IDENTITY(INT,0,1) AS N
		INTO dbo.Tally
		FROM Master.dbo.SysColumns sc1,
		Master.dbo.SysColumns sc2'

	exec (@sql)

	ALTER TABLE dbo.Tally
		ADD CONSTRAINT PK_Tally_N 
		PRIMARY KEY CLUSTERED (N) WITH FILLFACTOR = 100

	GRANT SELECT, REFERENCES ON dbo.Tally TO PUBLIC
end


