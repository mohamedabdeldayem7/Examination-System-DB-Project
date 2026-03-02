-- Create database roles

if not exists (select 1 from sys.database_principals where name = 'db_admin')
	create role db_admin;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'db_TrainingManager') 
    CREATE ROLE db_TrainingManager;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'db_Instructor') 
    CREATE ROLE db_Instructor;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'db_Student') 
    CREATE ROLE db_Student;
GO

-- Grant permissions to database roles

-- Admin: full DDL/DML
GRANT CONTROL ON SCHEMA::[dbo] TO db_admin;


-- Training manager: manage Org and Students via stored procedures
GRANT EXECUTE ON SCHEMA::ORG TO db_TrainingManager;
GRANT EXECUTE ON SCHEMA::USERS TO db_TrainingManager;
GRANT SELECT ON SCHEMA::ORG TO db_TrainingManager;
GRANT SELECT ON SCHEMA::Users TO db_TrainingManager;


-- Instructor: allowed to execute Academic/Assessment SPs
GRANT EXECUTE ON SCHEMA::ACADEMIC TO db_Instructor;
GRANT EXECUTE ON SCHEMA::ASSESSMENT TO db_Instructor;
GRANT SELECT ON SCHEMA::ACADEMIC TO db_Instructor;
GRANT SELECT ON SCHEMA::ASSESSMENT TO db_Instructor;


-- Student: limited read via views and execute allowed SPs
GRANT SELECT ON SCHEMA::Users TO db_Student;
GRANT EXECUTE ON SCHEMA::Assessment TO db_Student;


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