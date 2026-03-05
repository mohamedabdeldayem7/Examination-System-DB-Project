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