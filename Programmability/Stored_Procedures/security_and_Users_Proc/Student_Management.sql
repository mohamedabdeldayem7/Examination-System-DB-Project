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