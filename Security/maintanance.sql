USE master;
GO

-- configure database for contained users (optional, but allows easier user management without needing to create logins at the server level)
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'contained database authentication', 1;
RECONFIGURE;
GO

-- make sure no one else is connected to the database before changing containment settings
ALTER DATABASE [ExamSystemDB] 
SET SINGLE_USER 
WITH ROLLBACK IMMEDIATE;
GO

-- setting the database containment to PARTIAL to allow contained users
ALTER DATABASE [ExamSystemDB] 
SET CONTAINMENT = PARTIAL;
GO

-- After making changes, set the database back to multi-user mode
ALTER DATABASE [ExamSystemDB] 
SET MULTI_USER;
GO

-- Verify the containment setting
SELECT name, containment_desc 
FROM sys.databases 
WHERE name = 'ExamSystemDB';
GO