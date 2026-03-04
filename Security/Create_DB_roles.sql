USE [ExamSystemDB]
GO

-- Create database roles and Grant permissions to database roles
-- Admin: full DDL/DML -> DB Owner role
if not exists (select 1 from sys.database_principals where name = 'db_admin')
BEGIN
    create role db_admin;
END
GO

ALTER ROLE db_owner ADD MEMBER db_admin;
GO 

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'db_TrainingManager') 
BEGIN
    CREATE ROLE db_TrainingManager;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'db_Instructor') 
BEGIN
    CREATE ROLE db_Instructor;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'db_Student') 
BEGIN
    CREATE ROLE db_Student;
END
GO
