-- this file contains stored procedures related to managing instructors in the system, including registration, updating details, and retrieving information. The procedures ensure secure handling of sensitive data and maintain data integrity across related tables.

-- 1. Registering a new instructor involves creating an account, inserting personal details, and then adding instructor-specific information such as salary and hire date. The procedure uses transactions to ensure that all operations succeed or fail together, maintaining data consistency.
CREATE OR ALTER PROCEDURE Users.usp_RegisterInstructor
(
    -- data for both account and person
    @Username NVARCHAR(100),
    @Email NVARCHAR(256) = NULL,
    @PlainPassword NVARCHAR(4000),
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @SSN NVARCHAR(14) = NULL,
    @Phone NVARCHAR(11) = NULL,
    @CreatedBy INT = NULL,

    -- data specific to instructor
    @Salary DECIMAL(10,2) = 0.0,
    @HireDate DATE = NULL,
    @Office VARCHAR(50) = NULL,
    @Is_Manager BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @INSTRUCTOR_ROLE NVARCHAR(50) = 'Instructor';
    IF @Is_Manager = 1
        SET @INSTRUCTOR_ROLE = 'TrainingManager';

    DECLARE @NewPersonId INT;
    DECLARE @IsNestedTransaction BIT = 0;
    
    IF @@TRANCOUNT > 0 SET @IsNestedTransaction = 1;

    BEGIN TRY
        IF @IsNestedTransaction = 0 BEGIN TRAN;
        ELSE SAVE TRANSACTION SavePoint_RegisterInstructor;

        -- execute the base procedure to create the person and account, and get the new PersonID
        EXEC Users.usp_CreatePersonBase
            @Username = @Username,
            @Email = @Email,
            @PlainPassword = @PlainPassword,
            @Role = @INSTRUCTOR_ROLE, 
            @CreatedBy = @CreatedBy,
            @FirstName = @FirstName,
            @LastName = @LastName,
            @SSN = @SSN,
            @Phone = @Phone,
            @NewPersonId = @NewPersonId OUTPUT;

        IF @HireDate IS NULL SET @HireDate = CAST(GETDATE() AS DATE);

        -- insert into the Instructor table using the new PersonID and instructor-specific data
        INSERT INTO Users.Instructor (InstructorID, Salary, HireDate, Office, Is_Manager)
        VALUES (@NewPersonId, @Salary, @HireDate, @Office, @Is_Manager);

        IF @IsNestedTransaction = 0 COMMIT TRAN;

        -- Return the new InstructorID and a success message
        SELECT @NewPersonId AS InstructorId, 'Instructor Registered Successfully' AS StatusMessage;

    END TRY
    BEGIN CATCH
        IF @IsNestedTransaction = 0 
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRAN;
        END
        ELSE
        BEGIN
            IF XACT_STATE() = 1 ROLLBACK TRANSACTION SavePoint_RegisterInstructor;
        END;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        -- Return the error message and a failure status
        SELECT 
            @ErrorState AS Success, 
            'Registration Failed' AS Status,
            @ErrorMessage AS TechnicalError,
            @ErrorSeverity AS Severity;
    END CATCH
END;
GO


-- Update Instructor: updates Instructor row; when @Is_Manager changes, update Users.Account.Role and contained DB role membership
CREATE OR ALTER PROCEDURE Users.usp_UpdateInstructor
(
    @TargetUsername NVARCHAR(100),
    @Salary DECIMAL(10,2) = NULL,
    @Office VARCHAR(50) = NULL,
    @Is_Manager BIT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Authorization
    IF IS_ROLEMEMBER('db_admin') <> 1 AND IS_ROLEMEMBER('db_TrainingManager') <> 1
    BEGIN
        RAISERROR('Access Denied.',16,1); RETURN;
    END;

    -- resolve account and instructor
    DECLARE @AccountId INT;
    SELECT @AccountId = AccountId FROM Users.Account
    WHERE Username = @TargetUsername AND IsActive = 1;

    IF @AccountId IS NULL
    BEGIN
        RAISERROR('Account not found or inactive.',16,1); RETURN;
    END;

    DECLARE @InstructorId INT;
    SELECT @InstructorId = I.InstructorID
    FROM Users.Instructor I
        INNER JOIN Users.Person P ON I.InstructorID = P.PersonId
    WHERE P.AccountId = @AccountId;

    IF @InstructorId IS NULL
    BEGIN
        RAISERROR('Instructor record not found for this account.',16,1); RETURN;
    END;

    DECLARE @OldIsManager BIT = (
                                SELECT Is_Manager FROM Users.Instructor 
                                WHERE InstructorID = @InstructorId
                            );
    DECLARE @OldRoleLogical NVARCHAR(128) = (
                                SELECT [Role] FROM Users.Account 
                                WHERE AccountId = @AccountId
                            );

    DECLARE @NewRoleLogical NVARCHAR(128) = NULL;
    IF @Is_Manager IS NOT NULL
        SET @NewRoleLogical = CASE WHEN @Is_Manager = 1 THEN 'TrainingManager' ELSE 'Instructor' END;

    DECLARE @IsNestedTransaction BIT = 0;
    IF @@TRANCOUNT > 0 SET @IsNestedTransaction = 1;

    DECLARE @sql NVARCHAR(MAX);

    BEGIN TRY
        IF @IsNestedTransaction = 0 
            BEGIN TRAN;
        ELSE
            SAVE TRANSACTION SavePoint_UpdateInstructor;

        -- update Instructor row (only provided fields)
        UPDATE Users.Instructor
        SET Salary = COALESCE(@Salary, Salary),
            Office = COALESCE(@Office, Office),
            Is_Manager = COALESCE(@Is_Manager, Is_Manager)
        WHERE InstructorID = @InstructorId;

        -- If management flag changed, update Users.Account.Role and DB role membership
        -- this will update the logical role in Users.Account
        EXEC Users.usp_UpdateAccount @TargetUsername = @TargetUsername, @NewRole = @NewRoleLogical; 
     
        IF @IsNestedTransaction = 0 
            COMMIT TRAN;

        SELECT @@ROWCOUNT AS RecordsUpdated;
    END TRY
    BEGIN CATCH
        IF @IsNestedTransaction = 0
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRAN;
        END
        ELSE
        BEGIN
            IF XACT_STATE() = 1 ROLLBACK TRANSACTION SavePoint_UpdateInstructor;
        END;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        -- Return the error message and a failure status
        SELECT 
            @ErrorState AS Success, 
            'Registration Failed' AS Status,
            @ErrorMessage AS TechnicalError,
            @ErrorSeverity AS Severity;

    END CATCH
END;
GO


-- Delete Instructor: deletes from Users.Person (which will cascade to Instructor and Account); accepts either InstructorId or Username; checks permissions; uses the same underlying procedure as deleting any person to ensure consistent handling of related data and audit logging
CREATE OR ALTER PROCEDURE Users.usp_DeleteInstructor
(
    @InstructorId INT = NULL,
    @Username NVARCHAR(100) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    IF IS_ROLEMEMBER('db_Admin') <> 1 AND IS_ROLEMEMBER('db_TrainingManager') <> 1
    BEGIN
        RAISERROR('Permission denied. Admin or TrainingManager required.',16,1); RETURN;
    END;

    IF @InstructorId IS NULL AND @Username IS NULL
    BEGIN
        RAISERROR('Provide either InstructorId or Username.',16,1); RETURN;
    END;

    DECLARE @ResolvedPersonId INT;
    DECLARE @ResolvedUsername NVARCHAR(100);

    SELECT TOP (1)
        @ResolvedPersonId = P.PersonId,
        @ResolvedUsername = A.Username
    FROM Users.Instructor AS I
        JOIN Users.Person AS P ON I.InstructorID = P.PersonId
        LEFT JOIN Users.Account AS A ON A.AccountId = P.AccountId
    WHERE (I.InstructorID = @InstructorId OR @InstructorId IS NULL)
      AND (A.Username = @Username OR @Username IS NULL)
      AND P.IsDeleted = 0;

    IF @ResolvedPersonId IS NULL
    BEGIN
        RAISERROR('Instructor not found or already deleted.',16,1); RETURN;
    END;

    EXEC Users.usp_DeletePerson @PersonId = @ResolvedPersonId, @Username = @ResolvedUsername;
END;
GO

-- Get Instructor: retrieves instructor details by either InstructorId or Username; joins with Person and Account to return comprehensive information; checks that at least one identifier is provided
CREATE OR ALTER PROCEDURE Users.usp_GetInstructor
(
    @InstructorId INT = NULL,
    @Username NVARCHAR(100) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @InstructorId IS NULL AND @Username IS NULL
    BEGIN
        SET @Username = SUSER_NAME(); -- default to current user if no identifier provided
    END

    SELECT 
        I.InstructorID,
        P.SSN,
        A.Username,
        A.Email,
        P.FirstName,
        P.LastName,
        P.Phone,
        I.Salary,
        I.HireDate,
        I.Office,
        I.Is_Manager
    FROM Users.Instructor AS I
        JOIN Users.Person AS P ON I.InstructorID = P.PersonId
        LEFT JOIN Users.Account AS A ON P.AccountId = A.AccountId
    WHERE (I.InstructorID = @InstructorId OR @InstructorId IS NULL)
      AND (A.Username = @Username OR @Username IS NULL);
END;
GO



