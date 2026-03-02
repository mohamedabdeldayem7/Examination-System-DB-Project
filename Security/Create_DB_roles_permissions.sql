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

