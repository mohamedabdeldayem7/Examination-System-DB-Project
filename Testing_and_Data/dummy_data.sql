SET NOCOUNT ON;

-- Variables for dynamic data generation
DECLARE @Counter INT;
DECLARE @Username NVARCHAR(100);
DECLARE @Email NVARCHAR(256);
DECLARE @FirstName NVARCHAR(50);
DECLARE @LastName NVARCHAR(50);
DECLARE @SSN NVARCHAR(14);

PRINT '--- Creating 20 Instructors ---'
SET @Counter = 1;

WHILE @Counter <= 20
BEGIN
    -- Generate unique dummy data for Instructors
    SET @Username = 'instructor_' + CAST(@Counter AS NVARCHAR(10));
    SET @Email = @Username + '@traininginstitute.com';
    SET @FirstName = 'InstFirst' + CAST(@Counter AS NVARCHAR(10));
    SET @LastName = 'InstLast' + CAST(@Counter AS NVARCHAR(10));
    SET @SSN = '12345678910'

    EXEC Users.usp_RegisterInstructor
        @Username = @Username,
        @Email = @Email,
        @PlainPassword = 'StrongPassword123!',
        @FirstName = @FirstName,
        @LastName = @LastName,
        @Salary = 55000.00,
        @Office = 'Room A',
        @Is_Manager = 0; -- 0 Sets role to 'Instructor'

    SET @Counter = @Counter + 1;
END

PRINT '--- Creating 5 Training Managers ---'
SET @Counter = 1;

WHILE @Counter <= 5
BEGIN
    -- Generate unique dummy data for Training Managers
    SET @Username = 'manager_' + CAST(@Counter AS NVARCHAR(10));
    SET @Email = @Username + '@traininginstitute.com';
    SET @FirstName = 'MgrFirst' + CAST(@Counter AS NVARCHAR(10));
    SET @LastName = 'MgrLast' + CAST(@Counter AS NVARCHAR(10));

    EXEC Users.usp_RegisterInstructor
        @Username = @Username,
        @Email = @Email,
        @PlainPassword = 'StrongPassword123!',
        @FirstName = @FirstName,
        @LastName = @LastName,
        @Salary = 85000.00,
        @Office = 'Management Suite',
        @Is_Manager = 1; -- 1 Sets role to 'TrainingManager'

    SET @Counter = @Counter + 1;
END

PRINT '--- Data Generation Complete ---'
GO