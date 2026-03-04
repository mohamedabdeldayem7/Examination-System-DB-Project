-- This file contains stored procedures related to user management and security in the ExamSystemDB database.

-- Procedure to create a new database user and assign them to a role based on their specified role in the system.
CREATE OR ALTER PROCEDURE Users.usp_CreateDBUser
    @Username NVARCHAR(100),
    @PlainPassword NVARCHAR(4000),
    @Role NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @sql NVARCHAR(MAX) = N'CREATE USER [' + REPLACE(@Username,']',']]') + 
                                 N'] WITH PASSWORD = ' + QUOTENAME(@PlainPassword,'''') + N';';
    EXEC sp_executesql @sql;

    DECLARE @TargetRole NVARCHAR(100) = CASE 
        WHEN @Role = 'Admin' THEN 'db_Admin'
        WHEN @Role = 'TrainingManager' THEN 'db_TrainingManager'
        WHEN @Role = 'Instructor' THEN 'db_Instructor'
        WHEN @Role = 'Student' THEN 'db_Student'
        ELSE NULL
        END;

    IF @TargetRole IS NULL BEGIN
        RAISERROR('Invalid role specified.', 16, 1); RETURN; 
    END
    EXEC sp_addrolemember @TargetRole, @Username;
END;
GO
