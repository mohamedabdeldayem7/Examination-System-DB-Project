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

    -- for role validation
    IF Users.fn_ValidateRole(@Role) = 0
        BEGIN RAISERROR('Invalid role specified.', 16, 1); RETURN; END

    -- for password hashing
    DECLARE @salt VARBINARY(128) = CRYPT_GEN_RANDOM(32);
    DECLARE @iterations INT = 100; -- should be higher in production, but using a lower number here for demonstration and testing purposes to avoid long execution times
    DECLARE @hash VARBINARY(512) = [Users].[fn_PBKDF2_SHA512_OneBlock](@PlainPassword, @salt, @iterations, 64);

    -- for inserting the new account
    BEGIN TRY
        BEGIN TRAN;

            INSERT INTO Users.Account (Username, Email, PasswordHash, PasswordSalt, Role, CreatedBy, PasswordIterations)
            VALUES (@Username, @Email, @hash, @salt, @Role, @CreatedBy, 100);

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


-- This procedure allows users to change their password. It verifies the old password, checks the strength of the new password, and updates both the database user password and the Users.Account table with the new hash/salt.
CREATE OR ALTER PROCEDURE Users.usp_ChangePassword
(
    @OldPassword NVARCHAR(4000),
    @NewPassword NVARCHAR(4000),
    @Username NVARCHAR(100) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @Username IS NULL
    BEGIN
        set @Username = SUSER_NAME();
    END

    IF Users.fn_ValidatePassword(@NewPassword) = 0
    BEGIN
        RAISERROR('New password is too weak! Must include Upper, Lower, Number, and Special char.',16,1); RETURN;
    END

    -- Verify old password
    DECLARE @AccountId INT, @storedHash VARBINARY(8000), @salt VARBINARY(128), @iter INT;
    SELECT @AccountId = AccountId, @storedHash = PasswordHash, @salt = PasswordSalt, @iter = PasswordIterations
    FROM Users.Account WHERE Username = @Username;

    IF @AccountId IS NULL
    BEGIN
        RAISERROR('Account not found',16,1); RETURN;
    END

    DECLARE @oldAttempt VARBINARY(8000) = Users.fn_PBKDF2_SHA512_OneBlock(@OldPassword, @salt, @iter, DATALENGTH(@storedHash));
    IF @oldAttempt <> @storedHash
    BEGIN
        RAISERROR('Old password incorrect',16,1); RETURN;
    END

    -- Compute new salt/hash
    DECLARE @newSalt VARBINARY(128) = CRYPT_GEN_RANDOM(32);
    DECLARE @newIter INT = 100;
    DECLARE @newHash VARBINARY(8000) = Users.fn_PBKDF2_SHA512_OneBlock(@NewPassword, @newSalt, @newIter, 32);

    BEGIN TRY
        BEGIN TRAN;

        -- Update DB user password (contained user)
        DECLARE @sql NVARCHAR(MAX) = N'ALTER USER [' + REPLACE(@Username,']',']]') + N'] WITH PASSWORD = ' + QUOTENAME(@NewPassword,'''') + N';';
        EXEC sp_executesql @sql;

        -- Update account table
        UPDATE Users.Account
            SET PasswordHash = @newHash, PasswordSalt = @newSalt, PasswordIterations = @newIter
        WHERE AccountId = @AccountId;

        COMMIT TRAN;
        SELECT 1 AS Success;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRAN;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Password change failed: %s',16,1, @ErrorMessage);
    END CATCH
END;
GO