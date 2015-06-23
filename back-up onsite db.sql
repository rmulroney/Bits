
USE myob;
GO
BACKUP DATABASE MYOB
TO DISK = 'C:\Program Files (x86)\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\MYOB.Bak'
   WITH FORMAT,
      MEDIANAME = 'Z_SQLServerBackups',
      NAME = 'Calumo MYOB Backup';

GO
CHECKPOINT;
GO
CHECKPOINT; -- run twice to ensure file wrap-around
GO
DBCC SHRINKFILE(MYOB_log, 200 );
GO

ALTER DATABASE [MYOB_db] SET RECOVERY SIMPLE;