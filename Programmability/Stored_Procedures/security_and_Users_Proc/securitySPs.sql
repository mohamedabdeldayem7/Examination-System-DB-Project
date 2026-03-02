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
        ELSE 'db_Student' END;

    EXEC sp_addrolemember @TargetRole, @Username;
END;
GO

-- This procedure creates a new user account in the Users.Account table
CREATE OR ALTER PROCEDURE Users.usp_CreateAccount
(
    @Username NVARCHAR(100),
    @Email NVARCHAR(256) = NULL,
    @PlainPassword NVARCHAR(4000),
    @Role NVARCHAR(50),
    @CreatedBy INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    -- for validation and error handling
    IF LEN(@Username) < 3
        BEGIN RAISERROR('Username too short.', 16, 1); RETURN; END

    IF Users.fn_ValidateEmail(@Email) = 0
        BEGIN RAISERROR('Invalid Email format.', 16, 1); RETURN; END

    IF Users.fn_ValidatePassword(@PlainPassword) = 0
        BEGIN RAISERROR('Password too weak! Must include Upper, Lower, Number, and Special char.', 16, 1); RETURN; END

    -- for duplicate username
    IF EXISTS (SELECT 1 FROM Users.Account WHERE Username = @Username)
        BEGIN RAISERROR('Username already taken.', 16, 1); RETURN; END

    -- for duplicate email
    IF EXISTS (SELECT 1 FROM Users.Account WHERE Email = @Email)
        BEGIN RAISERROR('Email already taken.', 16, 1); RETURN; END

    -- for password hashing
    DECLARE @salt VARBINARY(128) = CRYPT_GEN_RANDOM(32);
    DECLARE @iterations INT = 100; -- should be higher in production, but using a lower number here for demonstration and testing purposes to avoid long execution times
    DECLARE @hash VARBINARY(512) = [Users].[fn_PBKDF2_SHA512_OneBlock](@PlainPassword, @salt, @iterations, 64);

    -- for inserting the new account
    BEGIN TRY
        BEGIN TRAN;

            INSERT INTO Users.Account (Username, Email, PasswordHash, PasswordSalt, Role, CreatedBy)
            VALUES (@Username, @Email, @hash, @salt, @Role, @CreatedBy);

            DECLARE @NewId INT = SCOPE_IDENTITY();

            EXEC Users.usp_CreateDBUser @Username, @PlainPassword, @Role;

        COMMIT TRAN;
        
        SELECT @NewId AS AccountId, 'Success' AS Status;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRAN;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        raiserror(@ErrorMessage, 16, 1);
        RAISERROR('An internal error occurred. Please contact support.', 16, 1);
    END CATCH
END;
GO