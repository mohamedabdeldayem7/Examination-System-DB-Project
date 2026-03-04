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

-- Grant permissions to database roles
-- Instructor: allowed to execute Academic/Assessment SPs
GRANT EXECUTE ON SCHEMA::ACADEMIC TO db_Instructor;
GRANT EXECUTE ON SCHEMA::ASSESSMENT TO db_Instructor;
GRANT SELECT ON SCHEMA::ACADEMIC TO db_Instructor;
GRANT SELECT ON SCHEMA::ASSESSMENT TO db_Instructor;


-- Student: limited read via views and execute allowed SPs
GRANT SELECT ON SCHEMA::Users TO db_Student;
GRANT EXECUTE ON SCHEMA::Assessment TO db_Student;

-- Training manager: manage Org and Students via stored procedures
ALTER ROLE db_Instructor ADD MEMBER db_TrainingManager; -- each Training Manager is also an Instructor, so they can execute all Instructor SPs
GRANT EXECUTE ON SCHEMA::ORG TO db_TrainingManager;
GRANT EXECUTE ON SCHEMA::USERS TO db_TrainingManager;
GRANT SELECT ON SCHEMA::ORG TO db_TrainingManager;
GRANT SELECT ON SCHEMA::Users TO db_TrainingManager;

-- Deny direct DML on critical tables to all users, even those with higher privileges, to enforce the use of stored procedures for data modifications which include necessary business logic and auditing.
DENY INSERT, UPDATE, DELETE ON Ops.AuditLog TO public;
