-- Here are some functions to validate user input for the Users schema, such as validating email addresses and password strength.

-- To validate email addresses
CREATE OR ALTER FUNCTION Users.fn_ValidateEmail (@Email NVARCHAR(256))
RETURNS BIT
AS
BEGIN
    IF @Email IS NULL RETURN 1;
    
    IF @Email LIKE '%_@__%.__%' 
       AND @Email NOT LIKE '%@%@%'
       AND @Email NOT LIKE '%..%' 
       RETURN 1;

    RETURN 0;
END;
GO

-- To validate password strength
CREATE OR ALTER FUNCTION Users.fn_ValidatePassword (@Password NVARCHAR(4000))
RETURNS BIT
AS
BEGIN
    IF LEN(@Password) >= 8
       AND @Password LIKE '%[A-Z]%' 
       AND @Password LIKE '%[a-z]%'
       AND @Password LIKE '%[0-9]%'
       AND @Password LIKE '%[!@#$%^&*()-_+=]%'
       RETURN 1;

    RETURN 0;
END;
GO

-- to validate Role
CREATE OR ALTER FUNCTION Users.fn_ValidateRole (@Role NVARCHAR(50))
RETURNS BIT
AS
BEGIN
    IF @Role IN ('Admin', 'TrainingManager', 'Instructor', 'Student')
       RETURN 1;
    RETURN 0;
END;
GO

-- validate phone number
CREATE FUNCTION Users.fn_ValidateEgyptianPhone (@Phone NVARCHAR(20))
RETURNS BIT
AS
BEGIN
    DECLARE @IsValid BIT = 0;

    IF @Phone LIKE '01[0125][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
    BEGIN
        SET @IsValid = 1;
    END

    RETURN @IsValid;
END;