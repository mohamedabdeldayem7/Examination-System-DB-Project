-- this file contains stored procedures related to person management in the Users schema, including creating a person along with their account and handling necessary validations and transactions.

-- Create Person Base Procedure
CREATE OR ALTER PROCEDURE Users.usp_CreatePersonBase
(
    -- Account Parameters
    @Username NVARCHAR(100),
    @Email NVARCHAR(256) = NULL,
    @PlainPassword NVARCHAR(4000),
    @Role NVARCHAR(50),
    @CreatedBy INT = NULL,
    
    -- Person Parameters
    @SSN NVARCHAR(14) = NULL,
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @Phone NVARCHAR(11) = NULL,
    
    -- Output Parameter
    @NewPersonId INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate Person Parameters

    -- Validate FirstName and LastName are not empty or whitespace
    IF TRIM(@FirstName) = '' OR TRIM(@LastName) = ''
    BEGIN
        RAISERROR('First Name and Last Name cannot be empty.', 16, 1);
        RETURN;
    END

    -- validate SSN format 
    IF LEN(@SSN) <> 14 OR @SSN IS NULL
    BEGIN
        RAISERROR('Invalid SSN format.', 16, 1);
        RETURN;
    END

    -- validate Phone 
    IF Users.fn_ValidateEgyptianPhone(@Phone) = 0
    BEGIN
        RAISERROR('Invalid Phone format.', 16, 1);
        RETURN;
    END

    DECLARE @IsNestedTransaction BIT = 0;
    IF @@TRANCOUNT > 0 
        SET @IsNestedTransaction = 1;

    BEGIN TRY
        IF @IsNestedTransaction = 0 
            BEGIN TRAN;
        ELSE
            SAVE TRANSACTION SavePoint_CreatePerson;

        DECLARE @CreatedAccountId INT;
        
        EXEC Users.usp_CreateAccount 
            @Username = @Username,
            @Email = @Email,
            @PlainPassword = @PlainPassword,
            @Role = @Role,
            @CreatedBy = @CreatedBy,
            @NewAccountId = @CreatedAccountId OUTPUT; 
        
        -- insert person record with the created account id
        INSERT INTO Users.Person (AccountId, SSN, FirstName, LastName, Phone, IsDeleted)
        VALUES (@CreatedAccountId, @SSN, @FirstName, @LastName, @Phone, 0);

        SET @NewPersonId = SCOPE_IDENTITY();

        IF @IsNestedTransaction = 0 
            COMMIT TRAN;
            
    END TRY
    BEGIN CATCH

        IF @IsNestedTransaction = 0 
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRAN;
        END
        ELSE
        BEGIN
            IF XACT_STATE() = 1 ROLLBACK TRANSACTION SavePoint_CreatePerson;
        END;
        
        -- send error to top level
        THROW;
    END CATCH
END;
GO

-- Update Profile Procedure
CREATE OR ALTER PROCEDURE Users.usp_UpdateProfile
(
    @FirstName NVARCHAR(50) = NULL,
    @LastName NVARCHAR(50) = NULL,
    @Phone NVARCHAR(11) = NULL,
    @SSN NVARCHAR(14) = NULL,
    @TargetUsername NVARCHAR(100) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @TargetUsername IS NULL
        SET @TargetUsername = SUSER_SNAME(); -- default to caller's username if not provided
    
    -- get target person's id and account id
    DECLARE @TargetPersonId INT, @TargetAccountId INT;
    SELECT @TargetPersonId = P.PersonId, @TargetAccountId = A.AccountId
    FROM Users.Account A
    JOIN Users.Person P ON A.AccountId = P.AccountId
    WHERE A.Username = @TargetUsername AND A.IsActive = 1;

    IF @TargetPersonId IS NULL
    BEGIN
        SELECT 0 AS Success, 'User not found or inactive.' AS Status;
        RETURN;
    END

    -- 2. Security Check: Allow if caller is updating their own profile or has admin/manager role
    DECLARE @CallerUsername NVARCHAR(100) = SUSER_SNAME();

    IF (@CallerUsername <> @TargetUsername) 
       AND IS_ROLEMEMBER('db_Admin') <> 1 
       AND IS_ROLEMEMBER('db_TrainingManager') <> 1
    BEGIN
        SELECT 0 AS Success, 'Action Denied: You can only update your own profile.' AS Status;
        RETURN;
    END

    -- validate inputs if they are provided
    IF @FirstName IS NOT NULL AND TRIM(@FirstName) = ''
    BEGIN
        SELECT 0 AS Success, 'First Name cannot be empty.' AS Status;
        RETURN;
    END

    IF @LastName IS NOT NULL AND TRIM(@LastName) = ''
    BEGIN
        SELECT 0 AS Success, 'Last Name cannot be empty.' AS Status;
        RETURN;
    END

    IF @SSN IS NOT NULL AND (LEN(@SSN) <> 14)
    BEGIN
        SELECT 0 AS Success, 'Invalid SSN format.' AS Status;
        RETURN;
    END

    IF @Phone IS NOT NULL AND Users.fn_ValidateEgyptianPhone(@Phone) = 0
    BEGIN
        SELECT 0 AS Success, 'Invalid Phone format.' AS Status;
        RETURN;
    END

    BEGIN TRY
        UPDATE Users.Person
        SET 
            FirstName = COALESCE(@FirstName, FirstName),
            LastName  = COALESCE(@LastName, LastName),
            Phone     = COALESCE(@Phone, Phone),
            SSN       = COALESCE(@SSN, SSN)
        WHERE PersonId = @TargetPersonId;

        SELECT 1 AS Success, 'Profile Updated Successfully' AS Status;
    END TRY
    BEGIN CATCH
        SELECT 0 AS Success, ERROR_MESSAGE() AS Status;
    END CATCH
END;
GO