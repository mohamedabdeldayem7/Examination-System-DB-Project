-- this file contains stored procedures related to student management, including registration and data updates.

-- Register Student Procedure
CREATE OR ALTER PROCEDURE Users.usp_RegisterStudent
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

    -- data specific to student
    @TrackID INT = NULL,
    @IntakeID INT = NULL,
    @BranchID INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NewPersonId INT;
    DECLARE @IsNestedTransaction BIT = 0;
    
    IF @@TRANCOUNT > 0 SET @IsNestedTransaction = 1;

    BEGIN TRY
        IF @IsNestedTransaction = 0 BEGIN TRAN;
        ELSE SAVE TRANSACTION SavePoint_RegisterStudent;

        -- execute the base procedure to create the person and account, and get the new PersonID
        EXEC Users.usp_CreatePersonBase
            @Username = @Username,
            @Email = @Email,
            @PlainPassword = @PlainPassword,
            @Role = 'Student',
            @CreatedBy = @CreatedBy,
            @FirstName = @FirstName,
            @LastName = @LastName,
            @SSN = @SSN,
            @Phone = @Phone,
            @NewPersonId = @NewPersonId OUTPUT;

        -- insert into the Student table using the new PersonID and student-specific data
        INSERT INTO Users.Student (StudentID, TrackID, IntakeID, BranchID)
        VALUES (@NewPersonId, @TrackID, @IntakeID, @BranchID);

        IF @IsNestedTransaction = 0 COMMIT TRAN;
        
        -- Return the new StudentID and a success message
        SELECT @NewPersonId AS StudentId, 'Student Registered Successfully' AS StatusMessage;

    END TRY
    BEGIN CATCH
        IF @IsNestedTransaction = 0 
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRAN;
        END
        ELSE
        BEGIN
            IF XACT_STATE() = 1 ROLLBACK TRANSACTION SavePoint_RegisterStudent;
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

-- Update Student: update Track/Intake/Branch and audit
CREATE OR ALTER PROCEDURE Users.usp_UpdateStudent
(
    @TargetUsername NVARCHAR(100),
    @TrackID INT = NULL,
    @IntakeID INT = NULL,
    @BranchID INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    IF IS_ROLEMEMBER('db_admin') <> 1 AND IS_ROLEMEMBER('db_TrainingManager') <> 1
    BEGIN
        RAISERROR('Access Denied.',16,1); RETURN;
    END;

    -- validate target user and get their StudentID
    DECLARE @AccountId INT;
    SELECT @AccountId = AccountId FROM Users.Account 
    WHERE Username = @TargetUsername AND IsActive = 1;
    
    IF @AccountId IS NULL
    BEGIN
        RAISERROR('Account not found or inactive.',16,1); RETURN;
    END;

    -- get StudentID for the account
    DECLARE @StudentId INT;
    SELECT @StudentId = S.StudentID
    FROM Users.Student S
        INNER JOIN Users.Person P ON S.StudentID = P.PersonId
    WHERE P.AccountId = @AccountId;

    IF @StudentId IS NULL
    BEGIN
        RAISERROR('Student record not found for this account.',16,1); RETURN;
    END;
     
    DECLARE @IsNestedTransactionStudent BIT = 0;
    IF @@TRANCOUNT > 0 
        SET @IsNestedTransactionStudent = 1;

    BEGIN TRY
        IF @IsNestedTransactionStudent = 0 
            BEGIN TRAN; 
        ELSE
            SAVE TRANSACTION SavePoint_UpdateStudent;

        UPDATE Users.Student
        SET TrackID = COALESCE(@TrackID, TrackID),
            IntakeID = COALESCE(@IntakeID, IntakeID),
            BranchID = COALESCE(@BranchID, BranchID)
        WHERE StudentID = @StudentId;

        
        IF @IsNestedTransactionStudent = 0 
            COMMIT TRAN;

        SELECT @@ROWCOUNT AS RecordsUpdated;
    END TRY
    BEGIN CATCH
        IF @IsNestedTransactionStudent = 0
        BEGIN
            IF XACT_STATE() <> 0 ROLLBACK TRAN;
        END
        ELSE
        BEGIN
            IF XACT_STATE() = 1 ROLLBACK TRANSACTION SavePoint_UpdateStudent;
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

-- Delete Student
CREATE OR ALTER PROCEDURE Users.usp_DeleteStudent
(
    @StudentId INT = NULL,
    @Username NVARCHAR(100) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    IF IS_ROLEMEMBER('db_Admin') <> 1 AND IS_ROLEMEMBER('db_TrainingManager') <> 1
    BEGIN
        RAISERROR('Permission denied. Admin or TrainingManager required.',16,1); RETURN;
    END;

    IF @StudentId IS NULL AND @Username IS NULL
    BEGIN
        RAISERROR('Provide either StudentId or Username.',16,1); RETURN;
    END;

    DECLARE @ResolvedPersonId INT;
    DECLARE @ResolvedUsername NVARCHAR(100);

    SELECT TOP (1)
        @ResolvedPersonId = P.PersonId,
        @ResolvedUsername = A.Username
    FROM Users.Student AS S
        JOIN Users.Person AS P ON S.StudentID = P.PersonId
        LEFT JOIN Users.Account AS A ON A.AccountId = P.AccountId
    WHERE (S.StudentID = @StudentId OR @StudentId IS NULL)
      AND (A.Username = @Username OR @Username IS NULL)
      AND P.IsDeleted = 0;

    IF @ResolvedPersonId IS NULL
    BEGIN
        RAISERROR('Student not found or already deleted.',16,1); RETURN;
    END;

    EXEC Users.usp_DeletePerson @PersonId = @ResolvedPersonId, @Username = @ResolvedUsername;
END;
GO

-- Get Student: retrieve student details by StudentId or Username; returns join of Account, Person and Student data (non-sensitive)
CREATE OR ALTER PROCEDURE Users.usp_GetStudent
(
    @StudentId INT = NULL,
    @Username NVARCHAR(100) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @StudentId IS NULL AND @Username IS NULL
    BEGIN
        SET @Username = SUSER_NAME(); -- default to current user if no identifier provided
    END

    SELECT 
        S.StudentID,
        P.SSN,
        A.Username,
        A.Email,
        A.IsActive,
        P.FirstName,
        P.LastName,
        P.Phone,
        S.TrackID,
        S.IntakeID,
        S.BranchID
    FROM Users.Student AS S
    JOIN Users.Person AS P ON S.StudentID = P.PersonId
    LEFT JOIN Users.Account AS A ON P.AccountId = A.AccountId
    WHERE (S.StudentID = @StudentId OR @StudentId IS NULL)
      AND (A.Username = @Username OR @Username IS NULL);
END;
GO