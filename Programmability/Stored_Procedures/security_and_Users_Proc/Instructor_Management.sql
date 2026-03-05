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