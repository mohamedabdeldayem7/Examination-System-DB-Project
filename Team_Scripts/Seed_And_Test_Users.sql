/* Created by GitHub Copilot in SSMS - review carefully before executing
   Purpose: Idempotent seed of Org.* lookup data, register sample Instructors/TrainingManagers/Students
            via existing Users registration SPs, then exercise Users objects (SPs, functions, views)
            to produce verification output for your supervisor.
*/

SET NOCOUNT ON;

-- Use a local date variable (consistent across registrations)
DECLARE @Today DATE = CONVERT(date, GETDATE());

--------------------------------------------------------------------------------
-- 1) Seed Org lookup tables (idempotent)
--------------------------------------------------------------------------------
BEGIN TRY
    BEGIN TRAN;

    -- Branches (5)
    IF NOT EXISTS (SELECT 1 FROM Org.Branch WHERE BranchName = N'Smart Village')
        INSERT INTO Org.Branch (BranchName, IsDeleted) VALUES (N'Smart Village', 0);
    IF NOT EXISTS (SELECT 1 FROM Org.Branch WHERE BranchName = N'Cairo - Nasr City')
        INSERT INTO Org.Branch (BranchName, IsDeleted) VALUES (N'Cairo - Nasr City', 0);
    IF NOT EXISTS (SELECT 1 FROM Org.Branch WHERE BranchName = N'Alexandria')
        INSERT INTO Org.Branch (BranchName, IsDeleted) VALUES (N'Alexandria', 0);
    IF NOT EXISTS (SELECT 1 FROM Org.Branch WHERE BranchName = N'Mansoura')
        INSERT INTO Org.Branch (BranchName, IsDeleted) VALUES (N'Mansoura', 0);
    IF NOT EXISTS (SELECT 1 FROM Org.Branch WHERE BranchName = N'Assiut')
        INSERT INTO Org.Branch (BranchName, IsDeleted) VALUES (N'Assiut', 0);

    -- Departments (5)
    IF NOT EXISTS (SELECT 1 FROM Org.Department WHERE DepartmentName = N'Software Development')
        INSERT INTO Org.Department (DepartmentName, IsDeleted) VALUES (N'Software Development', 0);
    IF NOT EXISTS (SELECT 1 FROM Org.Department WHERE DepartmentName = N'Data Science')
        INSERT INTO Org.Department (DepartmentName, IsDeleted) VALUES (N'Data Science', 0);
    IF NOT EXISTS (SELECT 1 FROM Org.Department WHERE DepartmentName = N'Cyber Security')
        INSERT INTO Org.Department (DepartmentName, IsDeleted) VALUES (N'Cyber Security', 0);
    IF NOT EXISTS (SELECT 1 FROM Org.Department WHERE DepartmentName = N'Business Solutions')
        INSERT INTO Org.Department (DepartmentName, IsDeleted) VALUES (N'Business Solutions', 0);
    IF NOT EXISTS (SELECT 1 FROM Org.Department WHERE DepartmentName = N'Network Administration')
        INSERT INTO Org.Department (DepartmentName, IsDeleted) VALUES (N'Network Administration', 0);

    -- Tracks (5) mapped to departments
    IF NOT EXISTS (SELECT 1 FROM Org.Track WHERE TrackName = N'Full Stack Web Development (ASP.NET)')
        INSERT INTO Org.Track (DepartmentId, TrackName, IsDeleted) VALUES (
            (SELECT TOP(1) DepartmentId FROM Org.Department WHERE DepartmentName = N'Software Development'),
            N'Full Stack Web Development (ASP.NET)', 0);
    IF NOT EXISTS (SELECT 1 FROM Org.Track WHERE TrackName = N'Mobile Application Development (Flutter)')
        INSERT INTO Org.Track (DepartmentId, TrackName, IsDeleted) VALUES (
            (SELECT TOP(1) DepartmentId FROM Org.Department WHERE DepartmentName = N'Software Development'),
            N'Mobile Application Development (Flutter)', 0);
    IF NOT EXISTS (SELECT 1 FROM Org.Track WHERE TrackName = N'Data Analysis')
        INSERT INTO Org.Track (DepartmentId, TrackName, IsDeleted) VALUES (
            (SELECT TOP(1) DepartmentId FROM Org.Department WHERE DepartmentName = N'Data Science'),
            N'Data Analysis', 0);
    IF NOT EXISTS (SELECT 1 FROM Org.Track WHERE TrackName = N'Ethical Hacking')
        INSERT INTO Org.Track (DepartmentId, TrackName, IsDeleted) VALUES (
            (SELECT TOP(1) DepartmentId FROM Org.Department WHERE DepartmentName = N'Cyber Security'),
            N'Ethical Hacking', 0);
    IF NOT EXISTS (SELECT 1 FROM Org.Track WHERE TrackName = N'ERP Solutions (Odoo)')
        INSERT INTO Org.Track (DepartmentId, TrackName, IsDeleted) VALUES (
            (SELECT TOP(1) DepartmentId FROM Org.Department WHERE DepartmentName = N'Business Solutions'),
            N'ERP Solutions (Odoo)', 0);

    -- Intakes (5)
    IF NOT EXISTS (SELECT 1 FROM Org.Intake WHERE IntakeYear = 2023 AND IntakeSemester = N'Q1')
        INSERT INTO Org.Intake (IntakeYear, IntakeSemester, IsDeleted) VALUES (2023, N'Q1', 0);
    IF NOT EXISTS (SELECT 1 FROM Org.Intake WHERE IntakeYear = 2023 AND IntakeSemester = N'Q3')
        INSERT INTO Org.Intake (IntakeYear, IntakeSemester, IsDeleted) VALUES (2023, N'Q3', 0);
    IF NOT EXISTS (SELECT 1 FROM Org.Intake WHERE IntakeYear = 2024 AND IntakeSemester = N'Winter')
        INSERT INTO Org.Intake (IntakeYear, IntakeSemester, IsDeleted) VALUES (2024, N'Winter', 0);
    IF NOT EXISTS (SELECT 1 FROM Org.Intake WHERE IntakeYear = 2024 AND IntakeSemester = N'Summer')
        INSERT INTO Org.Intake (IntakeYear, IntakeSemester, IsDeleted) VALUES (2024, N'Summer', 0);
    IF NOT EXISTS (SELECT 1 FROM Org.Intake WHERE IntakeYear = 2025 AND IntakeSemester = N'Q1')
        INSERT INTO Org.Intake (IntakeYear, IntakeSemester, IsDeleted) VALUES (2025, N'Q1', 0);

    -- Intake_Track explicit mapping (guard duplicates)
    IF NOT EXISTS (
        SELECT 1 FROM Org.Intake_Track it
        JOIN Org.Intake i ON it.IntakeId = i.IntakeId
        JOIN Org.Track t ON it.TrackId = t.TrackId
        WHERE i.IntakeYear = 2023 AND i.IntakeSemester = N'Q1' AND t.TrackName = N'Full Stack Web Development (ASP.NET)')
    BEGIN
        INSERT INTO Org.Intake_Track (IntakeId, TrackId, IsDeleted)
        VALUES (
            (SELECT TOP(1) IntakeId FROM Org.Intake WHERE IntakeYear = 2023 AND IntakeSemester = N'Q1'),
            (SELECT TOP(1) TrackId FROM Org.Track WHERE TrackName = N'Full Stack Web Development (ASP.NET)'),
            0);
    END;

    IF NOT EXISTS (
        SELECT 1 FROM Org.Intake_Track it
        JOIN Org.Intake i ON it.IntakeId = i.IntakeId
        JOIN Org.Track t ON it.TrackId = t.TrackId
        WHERE i.IntakeYear = 2023 AND i.IntakeSemester = N'Q3' AND t.TrackName = N'Mobile Application Development (Flutter)')
    BEGIN
        INSERT INTO Org.Intake_Track (IntakeId, TrackId, IsDeleted)
        VALUES (
            (SELECT TOP(1) IntakeId FROM Org.Intake WHERE IntakeYear = 2023 AND IntakeSemester = N'Q3'),
            (SELECT TOP(1) TrackId FROM Org.Track WHERE TrackName = N'Mobile Application Development (Flutter)'),
            0);
    END;

    IF NOT EXISTS (
        SELECT 1 FROM Org.Intake_Track it
        JOIN Org.Intake i ON it.IntakeId = i.IntakeId
        JOIN Org.Track t ON it.TrackId = t.TrackId
        WHERE i.IntakeYear = 2024 AND i.IntakeSemester = N'Winter' AND t.TrackName = N'Data Analysis')
    BEGIN
        INSERT INTO Org.Intake_Track (IntakeId, TrackId, IsDeleted)
        VALUES (
            (SELECT TOP(1) IntakeId FROM Org.Intake WHERE IntakeYear = 2024 AND IntakeSemester = N'Winter'),
            (SELECT TOP(1) TrackId FROM Org.Track WHERE TrackName = N'Data Analysis'),
            0);
    END;

    IF NOT EXISTS (
        SELECT 1 FROM Org.Intake_Track it
        JOIN Org.Intake i ON it.IntakeId = i.IntakeId
        JOIN Org.Track t ON it.TrackId = t.TrackId
        WHERE i.IntakeYear = 2024 AND i.IntakeSemester = N'Summer' AND t.TrackName = N'Ethical Hacking')
    BEGIN
        INSERT INTO Org.Intake_Track (IntakeId, TrackId, IsDeleted)
        VALUES (
            (SELECT TOP(1) IntakeId FROM Org.Intake WHERE IntakeYear = 2024 AND IntakeSemester = N'Summer'),
            (SELECT TOP(1) TrackId FROM Org.Track WHERE TrackName = N'Ethical Hacking'),
            0);
    END;

    IF NOT EXISTS (
        SELECT 1 FROM Org.Intake_Track it
        JOIN Org.Intake i ON it.IntakeId = i.IntakeId
        JOIN Org.Track t ON it.TrackId = t.TrackId
        WHERE i.IntakeYear = 2025 AND i.IntakeSemester = N'Q1' AND t.TrackName = N'ERP Solutions (Odoo)')
    BEGIN
        INSERT INTO Org.Intake_Track (IntakeId, TrackId, IsDeleted)
        VALUES (
            (SELECT TOP(1) IntakeId FROM Org.Intake WHERE IntakeYear = 2025 AND IntakeSemester = N'Q1'),
            (SELECT TOP(1) TrackId FROM Org.Track WHERE TrackName = N'ERP Solutions (Odoo)'),
            0);
    END;

    COMMIT TRAN;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRAN;
    THROW;
END CATCH;

--------------------------------------------------------------------------------
-- 2) Register Instructors (5 total) and TrainingManagers (2 of them)
--    Uses your existing stored procedures. All fields non-null and realistic.
--------------------------------------------------------------------------------
DECLARE @rc INT;

EXEC @rc = Users.usp_RegisterInstructor
    @Username = N'instr_demo1',
    @Email = N'instr_demo1@example.com',
    @PlainPassword = N'InstrDemo1!A',
    @FirstName = N'Adam',
    @LastName = N'Baker',
    @SSN = N'10000000000001',
    @Phone = N'01010000001',
    @CreatedBy = NULL,
    @Salary = 45000.00,
    @HireDate = @Today,
    @Office = N'Room 101',
    @Is_Manager = 0;

EXEC @rc = Users.usp_RegisterInstructor
    @Username = N'instr_demo2',
    @Email = N'instr_demo2@example.com',
    @PlainPassword = N'InstrDemo2!A',
    @FirstName = N'Beth',
    @LastName = N'Clark',
    @SSN = N'10000000000002',
    @Phone = N'01010000002',
    @CreatedBy = NULL,
    @Salary = 47000.50,
    @HireDate = @Today,
    @Office = N'Room 102',
    @Is_Manager = 0;

-- Training managers
EXEC @rc = Users.usp_RegisterInstructor
    @Username = N'tmgr_demo1',
    @Email = N'tmgr_demo1@example.com',
    @PlainPassword = N'TMgrDemo1!A',
    @FirstName = N'Carl',
    @LastName = N'Diaz',
    @SSN = N'10000000000003',
    @Phone = N'01010000003',
    @CreatedBy = NULL,
    @Salary = 90000.00,
    @HireDate = @Today,
    @Office = N'Admin 1',
    @Is_Manager = 1;

EXEC @rc = Users.usp_RegisterInstructor
    @Username = N'tmgr_demo2',
    @Email = N'tmgr_demo2@example.com',
    @PlainPassword = N'TMgrDemo2!A',
    @FirstName = N'Diana',
    @LastName = N'Evans',
    @SSN = N'10000000000004',
    @Phone = N'01010000004',
    @CreatedBy = NULL,
    @Salary = 88000.00,
    @HireDate = @Today,
    @Office = N'Admin 2',
    @Is_Manager = 1;

EXEC @rc = Users.usp_RegisterInstructor
    @Username = N'instr_demo3',
    @Email = N'instr_demo3@example.com',
    @PlainPassword = N'InstrDemo3!A',
    @FirstName = N'Elena',
    @LastName = N'Fox',
    @SSN = N'10000000000005',
    @Phone = N'01010000005',
    @CreatedBy = NULL,
    @Salary = 48000.00,
    @HireDate = @Today,
    @Office = N'Room 103',
    @Is_Manager = 0;

--------------------------------------------------------------------------------
-- 3) Register 10 Students (all non-null fields)
--------------------------------------------------------------------------------
DECLARE @idx INT = 1;
DECLARE @trackCount INT = (SELECT COUNT(*) FROM Org.Track);
DECLARE @intakeCount INT = (SELECT COUNT(*) FROM Org.Intake);
DECLARE @branchCount INT = (SELECT COUNT(*) FROM Org.Branch);

WHILE @idx <= 10
BEGIN
    DECLARE @susername NVARCHAR(200) = N'stud_demo' + RIGHT(N'00' + CAST(@idx AS NVARCHAR(2)), 2);
    DECLARE @semail NVARCHAR(512) = @susername + N'@example.com';
    DECLARE @spwd NVARCHAR(4000) = N'StudDemo' + CAST(4000 + @idx AS NVARCHAR(10)) + N'!A';
    DECLARE @sfirst NVARCHAR(100) = N'StudentF' + CAST(@idx AS NVARCHAR(3));
    DECLARE @slast NVARCHAR(100) = N'StudentL' + CAST(@idx AS NVARCHAR(3));

    DECLARE @pick INT = ((@idx - 1) % (CASE WHEN @trackCount=0 THEN 1 ELSE @trackCount END)) + 1;
    DECLARE @TrackId INT = (SELECT TrackId FROM (SELECT TrackId, ROW_NUMBER() OVER (ORDER BY TrackId) AS rn FROM Org.Track) t WHERE rn = @pick);

    DECLARE @pick2 INT = ((@idx - 1) % (CASE WHEN @intakeCount=0 THEN 1 ELSE @intakeCount END)) + 1;
    DECLARE @IntakeId INT = (SELECT IntakeId FROM (SELECT IntakeId, ROW_NUMBER() OVER (ORDER BY IntakeId) AS rn FROM Org.Intake) x WHERE rn = @pick2);

    DECLARE @pick3 INT = ((@idx - 1) % (CASE WHEN @branchCount=0 THEN 1 ELSE @branchCount END)) + 1;
    DECLARE @BranchId INT = (SELECT BranchId FROM (SELECT BranchId, ROW_NUMBER() OVER (ORDER BY BranchId) AS rn FROM Org.Branch) b WHERE rn = @pick3);


 -- 1. Declare local variables to hold the calculated values
DECLARE @GeneratedSSN NVARCHAR(14);
DECLARE @GeneratedPhone NVARCHAR(11);

-- 2. Perform the logic outside of the EXEC call
SET @GeneratedSSN = N'200000' + RIGHT(N'00' + CAST(@idx AS NVARCHAR(2)), 2);
SET @GeneratedPhone = N'0110000' + RIGHT(N'000' + CAST(@idx AS NVARCHAR(3)), 3);


    EXEC @rc = Users.usp_RegisterStudent
        @Username = @susername,
        @Email = @semail,
        @PlainPassword = @spwd,
        @FirstName = @sfirst,
        @LastName = @slast,
        @SSN = @GeneratedSSN,
        @Phone = @GeneratedPhone,
        @CreatedBy = NULL,
        @TrackID = @TrackId,
        @IntakeID = @IntakeId,
        @BranchID = @BranchId;

    SET @idx = @idx + 1;
END;

--------------------------------------------------------------------------------
-- 4) Verification / Tests (read-only) — resultsets produced for review
--------------------------------------------------------------------------------

-- Summary counts for report
SELECT 'AccountTotals' AS ReportItem, COUNT(*) AS TotalAccounts FROM Users.Account;
SELECT 'PersonTotals' AS ReportItem, COUNT(*) AS TotalPersons FROM Users.Person WHERE IsDeleted = 0;
SELECT 'StudentTotals' AS ReportItem, COUNT(*) AS TotalStudents FROM Users.Student;
SELECT 'InstructorTotals' AS ReportItem, COUNT(*) AS TotalInstructors FROM Users.Instructor;

-- Sample rows for review
SELECT TOP (10) AccountId, Username, Email, [Role], IsActive, CreatedAt FROM Users.Account ORDER BY CreatedAt DESC;
SELECT TOP (10) PersonId, AccountId, FirstName, LastName, SSN, Phone FROM Users.Person WHERE IsDeleted = 0 ORDER BY PersonId DESC;
SELECT TOP (10) StudentID, TrackID, IntakeID, BranchID FROM Users.Student ORDER BY StudentID DESC;
SELECT TOP (10) InstructorID, Salary, HireDate, Office, Is_Manager FROM Users.Instructor ORDER BY InstructorID DESC;

-- Exercise list/get SPs
EXEC Users.usp_ListAccountsByRole @Role = N'Instructor', @PageNumber = 1, @PageSize = 100;
EXEC Users.usp_ListAccountsByRole @Role = N'TrainingManager', @PageNumber = 1, @PageSize = 100;
EXEC Users.usp_ListAccountsByRole @Role = N'Student', @PageNumber = 1, @PageSize = 200;

EXEC Users.usp_GetInstructor @Username = N'instr_demo1';
EXEC Users.usp_GetInstructor @Username = N'tmgr_demo1';
EXEC Users.usp_GetStudent @Username = N'stud_demo01';

-- Validate functions (expected boolean-like or 0/1)
SELECT Users.fn_ValidateEmail(N'test@example.com') AS EmailGood, Users.fn_ValidateEmail(N'invalid.email') AS EmailBad;
SELECT Users.fn_ValidatePassword(N'GoodP@ssw0rd!') AS PasswordGood, Users.fn_ValidatePassword(N'weakpass') AS PasswordBad;

-- Views (if present)
IF OBJECT_ID(N'Users.vw_StudentDetails','V') IS NOT NULL
    SELECT TOP (10) * FROM Users.vw_StudentDetails;
IF OBJECT_ID(N'Users.vw_InstructorDetails','V') IS NOT NULL
    SELECT TOP (10) * FROM Users.vw_InstructorDetails;
IF OBJECT_ID(N'Users.vw_ActiveContactList','V') IS NOT NULL
    SELECT TOP (10) * FROM Users.vw_ActiveContactList;

-- Update role test (round-trip)
EXEC Users.usp_UpdateInstructor @TargetUsername = N'instr_demo1', @Is_Manager = 1;
EXEC Users.usp_UpdateInstructor @TargetUsername = N'instr_demo1', @Is_Manager = 0;

-- Duplicate-account attempt (expected to fail and be handled by SP)
BEGIN TRY
    EXEC Users.usp_CreateAccount @Username = N'instr_demo1', @Email = N'dup@example.com', @PlainPassword = N'DupPass!1', @Role = N'Instructor';
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS ExpectedDuplicateError;
END CATCH;

-- Audit log sample if exists
IF OBJECT_ID(N'Ops.AuditLog','U') IS NOT NULL
    SELECT TOP (20) * FROM Ops.AuditLog ORDER BY ChangedAt DESC;

-- final note
SELECT N'Seed + verification script completed. Inspect resultsets above and adjust as required before use in production.' AS ScriptStatus;