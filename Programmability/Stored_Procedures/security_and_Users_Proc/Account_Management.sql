-- This procedure creates a new user account in the Users.Account table
CREATE OR ALTER PROCEDURE Users.usp_CreateAccount
(
    @Username NVARCHAR(100),
    @Email NVARCHAR(256) = NULL,
    @PlainPassword NVARCHAR(4000),
    @Role NVARCHAR(50),
    @CreatedBy INT = NULL,
    @NewAccountId INT OUTPUT 
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

    -- Transaction Management
    DECLARE @IsNestedTransaction BIT = 0;
    IF @@TRANCOUNT > 0 
        SET @IsNestedTransaction = 1;

    BEGIN TRY
        IF @IsNestedTransaction = 0 
            BEGIN TRAN;
        ELSE
            SAVE TRANSACTION SavePoint_CreateAccount;

        -- for inserting the new account
        INSERT INTO Users.Account (Username, Email, PasswordHash, PasswordSalt, Role, CreatedBy, PasswordIterations)
        VALUES (@Username, @Email, @hash, @salt, @Role, @CreatedBy, @iterations);

        SET @NewAccountId = SCOPE_IDENTITY(); 

        EXEC Users.usp_CreateDBUser @Username, @PlainPassword, @Role;

        IF @IsNestedTransaction = 0 
            COMMIT TRAN; 
            
    END TRY
    BEGIN CATCH
        -- close trans
        IF @IsNestedTransaction = 0 
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRAN;
        END
        ELSE
        BEGIN
            IF XACT_STATE() = 1 ROLLBACK TRANSACTION SavePoint_CreateAccount;
        END;
        
        THROW; 
    END CATCH
END;
GO

-- This procedure updates a user account's email and/or role. It checks for appropriate permissions, validates inputs, and only updates provided fields. If the role changes, it also updates the contained database user's role membership accordingly.
CREATE OR ALTER PROCEDURE Users.usp_UpdateAccount
(
    @TargetUsername NVARCHAR(100),
    @NewEmail NVARCHAR(256) = NULL,
    @NewRole NVARCHAR(50) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Security Check: only Admin or TrainingManager may update accounts
    IF IS_ROLEMEMBER('db_Admin') <> 1 AND IS_ROLEMEMBER('db_TrainingManager') <> 1
    BEGIN
        RAISERROR('Access Denied.', 16, 1);
        RETURN;
    END;

    -- Validate inputs
    IF @NewEmail IS NOT NULL AND Users.fn_ValidateEmail(@NewEmail) = 0
    BEGIN
        RAISERROR('Invalid Email format.', 16, 1);
        RETURN;
    END;

    IF @NewRole IS NOT NULL AND Users.fn_ValidateRole(@NewRole) = 0
    BEGIN
        RAISERROR('Invalid role specified.', 16, 1);
        RETURN;
    END;

    -- Ensure target account exists and active
    IF NOT EXISTS (SELECT 1 FROM Users.Account WHERE Username = @TargetUsername AND IsActive = 1)
    BEGIN
        RAISERROR('Account not found or is inactive.', 16, 1);
        RETURN;
    END;

    DECLARE @OldRole NVARCHAR(50);
    SELECT @OldRole = [Role] FROM Users.Account WHERE Username = @TargetUsername;

    DECLARE @IsNestedTransaction BIT = 0;
    IF @@TRANCOUNT > 0 SET @IsNestedTransaction = 1;

    DECLARE @sql NVARCHAR(MAX);

    BEGIN TRY
        IF @IsNestedTransaction = 0
            BEGIN TRAN;
        ELSE
            SAVE TRANSACTION SavePoint_UpdateAccount;

        -- Update only provided columns
        UPDATE Users.Account
        SET
            Email = CASE WHEN @NewEmail IS NOT NULL THEN @NewEmail ELSE Email END,
            [Role] = CASE WHEN @NewRole IS NOT NULL THEN @NewRole ELSE [Role] END
        WHERE Username = @TargetUsername;

        -- If role changed, update contained DB user role membership
        IF @NewRole IS NOT NULL AND @NewRole <> @OldRole
        BEGIN
            -- Only proceed if a contained database user with that name exists
            IF USER_ID(@TargetUsername) IS NOT NULL
            BEGIN
                -- Remove from old role if it exists and user is member
                IF @OldRole IS NOT NULL
                   AND EXISTS (
                        SELECT 1
                        FROM sys.database_role_members drm
                        JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
                        JOIN sys.database_principals u ON drm.member_principal_id = u.principal_id
                        WHERE r.name = @OldRole AND u.name = @TargetUsername
                   )
                BEGIN
                    SET @sql = N'ALTER ROLE ' + QUOTENAME(@OldRole) + N' DROP MEMBER ' + QUOTENAME(@TargetUsername) + N';';
                    EXEC sp_executesql @sql;
                END;

                -- Add to new role if the role exists and user is not already a member
                IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @NewRole AND type = 'R')
                BEGIN
                    IF NOT EXISTS (
                        SELECT 1
                        FROM sys.database_role_members drm
                        JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
                        JOIN sys.database_principals u ON drm.member_principal_id = u.principal_id
                        WHERE r.name = @NewRole AND u.name = @TargetUsername
                    )
                    BEGIN
                        SET @sql = N'ALTER ROLE ' + QUOTENAME(@NewRole) + N' ADD MEMBER ' + QUOTENAME(@TargetUsername) + N';';
                        EXEC sp_executesql @sql;
                    END;
                END
                ELSE
                BEGIN
                    -- Optionally raise a warning if new DB role doesn't exist
                    RAISERROR('Target DB role %s does not exist; role membership not updated.', 10, 1, @NewRole);
                END;
            END
            ELSE
            BEGIN
                -- DB user not present; caller may want to create a contained user separately
                RAISERROR('Contained DB user [%s] does not exist. Create DB user before assigning role.', 10, 1, @TargetUsername) WITH NOWAIT;
            END;
        END;

        IF @IsNestedTransaction = 0
            COMMIT TRAN;

        SELECT 1 AS Success, @TargetUsername AS UpdatedUsername;
    END TRY
    BEGIN CATCH
        IF @IsNestedTransaction = 0
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRAN;
        END
        ELSE
        BEGIN
            IF XACT_STATE() = 1 ROLLBACK TRANSACTION SavePoint_UpdateAccount;
        END;

        THROW;
    END CATCH
END;
GO

-- This procedure performs a soft delete of a user account by setting IsActive to 0. It also attempts to drop the associated database user if it exists. Only users in the db_Admin or db_TrainingManager roles can execute this procedure.
CREATE OR ALTER PROCEDURE Users.usp_DeleteAccount
(
    @TargetAccountId INT = NULL,
    @TargetUsername NVARCHAR(100) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Security Check
    IF IS_ROLEMEMBER('db_Admin') <> 1 AND IS_ROLEMEMBER('db_TrainingManager') <> 1 AND IS_ROLEMEMBER('db_Owner') <> 1
    BEGIN
        RAISERROR('Permission denied. Admin or TrainingManager required.', 16, 1);
        RETURN;
    END

    -- Validate Inputs
    IF @TargetAccountId IS NULL AND @TargetUsername IS NULL
    BEGIN
        RAISERROR('You must provide either a TargetAccountId or TargetUsername.', 16, 1);
        RETURN;
    END

    -- Resolve Identity (Fetch both ID and Username regardless of what was passed)
    SELECT @TargetAccountId = AccountId, @TargetUsername = Username
    FROM Users.Account
    WHERE (AccountId = @TargetAccountId OR @TargetAccountId IS NULL)
      AND (Username = @TargetUsername OR @TargetUsername IS NULL)
      AND IsActive = 1; -- Only target active accounts

    IF @TargetAccountId IS NULL
    BEGIN
        RAISERROR('Account not found or is already deleted.', 16, 1);
        RETURN;
    END

    DECLARE @CallerAccountId INT;
    SELECT @CallerAccountId = AccountId FROM Users.Account
    WHERE Username = SUSER_NAME();

    -- Prevent self-deletion 
    IF @TargetAccountId = @CallerAccountId
    BEGIN
        RAISERROR('Action denied: You cannot delete your own account.', 16, 1);
        RETURN;
    END

    -- Execute Deletion
    BEGIN TRY
        BEGIN TRAN;

            -- Soft Delete the Account Row
            UPDATE Users.Account
                SET IsActive = 0
            WHERE AccountId = @TargetAccountId;

            -- Hard Delete the Contained Database User
            IF USER_ID(@TargetUsername) IS NOT NULL
            BEGIN
                DECLARE @Sql NVARCHAR(MAX) = N'';

                -- Build the ALTER ROLE scripts dynamically
                SELECT @Sql += N'ALTER ROLE ' + QUOTENAME(dp.name) + N' DROP MEMBER ' + QUOTENAME(@TargetUsername) + N'; '
                FROM sys.database_role_members drm
                    JOIN sys.database_principals dp ON drm.role_principal_id = dp.principal_id
                    JOIN sys.database_principals u ON drm.member_principal_id = u.principal_id
                WHERE u.name = @TargetUsername;

                -- Append the final DROP USER command
                SET @Sql += N'DROP USER ' + QUOTENAME(@TargetUsername) + N';';

                -- Execute the clean, concatenated script
                EXEC sp_executesql @Sql;
            END

            -- C. Audit Log
            EXEC Ops.usp_LogAudit
                @SchemaName = 'Users', 
                @TableName = 'Account', 
                @Operation = 'SOFT_DELETE', 
                @KeyValue = @TargetAccountId, 
                @Values = 'Status changed to Inactive; DB User Dropped';

        COMMIT TRAN;
        
        -- Return success info
        SELECT 1 AS Success, @TargetAccountId AS DeletedAccountId, @TargetUsername AS DeletedUsername;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRAN;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('DeleteAccount failed: %s', 16, 1, @ErrorMessage);
    END CATCH
END;
GO

-- This procedure lists user accounts with optional filtering by role, pagination, and the option to include inactive accounts. It returns total count for pagination metadata.
CREATE OR ALTER PROCEDURE Users.usp_ListAccountsByRole
(
    @Role NVARCHAR(50) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 5,
    @IncludeInactive BIT = 0 
)
AS
BEGIN
    SET NOCOUNT ON;

    -- input validation
    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize < 1 SET @PageSize = 5;

    -- SELECT statement with pagination and optional filtering
    SELECT 
        AccountId, 
        Username, 
        Email, 
        [Role], 
        IsActive, 
        LastLoginTime, 
        CreatedAt,
        -- Total count for pagination metadata
        COUNT(*) OVER() AS TotalCount 
    FROM Users.Account
    WHERE (@Role IS NULL OR [Role] = @Role)
      AND (IsActive = 1 OR @IncludeInactive = 1)
    ORDER BY Username 
    OFFSET (@PageNumber - 1) * @PageSize ROWS 
    FETCH NEXT @PageSize ROWS ONLY;

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