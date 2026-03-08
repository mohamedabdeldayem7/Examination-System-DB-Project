USE [ExamSystemDB];
GO

-- SECTION 1 : VALIDATION FUNCTIONS
-- 1.1  Users.fn_ValidateEmail

SELECT 'Valid email'               AS [TestCase],
Users.fn_ValidateEmail('ahmed.hassan@gmail.com')      AS [Result],
1                          AS [Expected];

SELECT 'Valid email with subdomain' AS [TestCase],
Users.fn_ValidateEmail('sara.ali@cs.cairo.edu.eg')    AS [Result],
1                          AS [Expected];

SELECT 'NULL email (treated valid)' AS [TestCase],
Users.fn_ValidateEmail(NULL)                          AS [Result],
1                          AS [Expected];

SELECT 'Missing @ sign'            AS [TestCase],
Users.fn_ValidateEmail('invalidemail.com')            AS [Result],
0                          AS [Expected];

SELECT 'Double @'                  AS [TestCase],
Users.fn_ValidateEmail('a@@b.com')                    AS [Result],
0                          AS [Expected];

SELECT 'Double dot'                AS [TestCase],
Users.fn_ValidateEmail('a@b..com')                    AS [Result],
0                          AS [Expected];
GO

-- 1.2  Users.fn_ValidatePassword

PRINT '-- 1.2  fn_ValidatePassword';

SELECT 'Strong password'           AS [TestCase],
Users.fn_ValidatePassword('Exam@2025!')               AS [Result],
1                          AS [Expected];

SELECT 'All lowercase (weak)'      AS [TestCase],
Users.fn_ValidatePassword('password1!')               AS [Result],
0                          AS [Expected];

SELECT 'No digit (weak)'           AS [TestCase],
Users.fn_ValidatePassword('Password!')                AS [Result],
0                          AS [Expected];

SELECT 'No special char (weak)'    AS [TestCase],
Users.fn_ValidatePassword('Password1')                AS [Result],
0                          AS [Expected];

SELECT 'Too short (weak)'          AS [TestCase],
Users.fn_ValidatePassword('Ab1!')                     AS [Result],
0                          AS [Expected];
GO

-- 1.3  Users.fn_ValidateRole

PRINT '-- 1.3  fn_ValidateRole';

SELECT 'Admin'          AS [TestCase], Users.fn_ValidateRole('Admin')           AS [Result], 1 AS [Expected];
SELECT 'TrainingManager' AS [TestCase], Users.fn_ValidateRole('TrainingManager') AS [Result], 1 AS [Expected];
SELECT 'Instructor'     AS [TestCase], Users.fn_ValidateRole('Instructor')      AS [Result], 1 AS [Expected];
SELECT 'Student'        AS [TestCase], Users.fn_ValidateRole('Student')         AS [Result], 1 AS [Expected];
SELECT 'InvalidRole'    AS [TestCase], Users.fn_ValidateRole('Manager')         AS [Result], 0 AS [Expected];
GO

-- 1.4  Users.fn_ValidateEgyptianPhone

PRINT '-- 1.4  fn_ValidateEgyptianPhone';

SELECT 'Vodafone (010)'   AS [TestCase], Users.fn_ValidateEgyptianPhone('01012345678') AS [Result], 1 AS [Expected];
SELECT 'Etisalat (011)'   AS [TestCase], Users.fn_ValidateEgyptianPhone('01112345678') AS [Result], 1 AS [Expected];
SELECT 'Orange (012)'     AS [TestCase], Users.fn_ValidateEgyptianPhone('01212345678') AS [Result], 1 AS [Expected];
SELECT 'WE (015)'         AS [TestCase], Users.fn_ValidateEgyptianPhone('01512345678') AS [Result], 1 AS [Expected];
SELECT 'NULL (allowed)'   AS [TestCase], Users.fn_ValidateEgyptianPhone(NULL)          AS [Result], 1 AS [Expected];
SELECT 'Landline (invalid)' AS [TestCase], Users.fn_ValidateEgyptianPhone('0223456789') AS [Result], 0 AS [Expected];
SELECT 'Too short'        AS [TestCase], Users.fn_ValidateEgyptianPhone('0101234567')  AS [Result], 0 AS [Expected];
GO


/*
================================================================================
SECTION 2 : CRYPTOGRAPHIC HELPER FUNCTIONS
Test the XOR helper and the PBKDF2-SHA512 implementation.
================================================================================
*/
PRINT '';
PRINT REPLICATE('-', 72);
PRINT '  SECTION 2 : Cryptographic Helper Functions';
PRINT REPLICATE('-', 72);
GO


-- SECTION 3 : ORG STORED PROCEDURES


-- 3.1  DEPARTMENT

-- 3.1.1  Insert 5 real departments
EXEC Org.sp_InsertDepartment @DepartmentName = N'Computer Science';
EXEC Org.sp_InsertDepartment @DepartmentName = N'Information Technology';
EXEC Org.sp_InsertDepartment @DepartmentName = N'Data Science and AI';
EXEC Org.sp_InsertDepartment @DepartmentName = N'Cybersecurity';
EXEC Org.sp_InsertDepartment @DepartmentName = N'Software Engineering';

-- 3.1.2  Select all departments (should return 5 rows)
EXEC Org.sp_SelectDepartment;

-- 3.1.3  Update a department name
EXEC Org.sp_UpdateDepartment
    @DepartmentID   = 9002,
    @DepartmentName = N'Computer Science & Engineering';

-- Verify update
EXEC Org.sp_SelectDepartment;

-- 3.1.4  Soft-delete a department and verify it disappears from the SELECT SP
PRINT '-- Soft-delete Department 5';
EXEC Org.sp_DeleteDepartment @DepartmentID = 9002;


-- Confirm row is still physically present with IsDeleted = 1
SELECT DepartmentId, DepartmentName, IsDeleted
FROM   Org.Department
WHERE  DepartmentId = 9002;                       -- Expected: IsDeleted = 1

-- 3.2  BRANCH

-- 3.2.1  Insert 5 real branches
EXEC Org.sp_InsertBranch @BranchName = N'Cairo Main Branch';
EXEC Org.sp_InsertBranch @BranchName = N'Alexandria Branch';
EXEC Org.sp_InsertBranch @BranchName = N'Giza Branch';
EXEC Org.sp_InsertBranch @BranchName = N'Mansoura Branch';
EXEC Org.sp_InsertBranch @BranchName = N'Assiut Branch';

-- 3.2.2  Select all active branches (should return 5 rows)
EXEC Org.sp_SelectBranch;

-- 3.2.3  Update a branch name
PRINT '-- Update Branch 3 name';
EXEC Org.sp_UpdateBranch
    @BranchID   = 3,
    @BranchName = N'6th October Giza Branch';

-- Verify update
EXEC Org.sp_SelectBranch;

-- 3.2.4  Soft-delete a branch
EXEC Org.sp_DeleteBranch @BranchID = 5;

-- Verify: 4 active branches remain
EXEC Org.sp_SelectBranch;


-- 3.3  TRACK

EXEC Org.sp_InsertTrack @DepartmentID = 1, @TrackName = N'Backend Web Development';
EXEC Org.sp_InsertTrack @DepartmentID = 1, @TrackName = N'Frontend Web Development';
EXEC Org.sp_InsertTrack @DepartmentID = 2, @TrackName = N'Database Administration';
EXEC Org.sp_InsertTrack @DepartmentID = 3, @TrackName = N'Machine Learning and Deep Learning';
EXEC Org.sp_InsertTrack @DepartmentID = 4, @TrackName = N'Network Security and Ethical Hacking';

-- 3.3.2  Select all active tracks
PRINT '-- Select all active tracks';
EXEC Org.sp_SelectTrack;

-- 3.3.3  Update track name and department
PRINT '-- Update Track 2';
EXEC Org.sp_UpdateTrack
@TrackID      = 2,
@DepartmentID = 1,
@TrackName    = N'Full-Stack Web Development';

-- Verify update
EXEC Org.sp_SelectTrack;

-- 3.3.4  Soft-delete Track 5
PRINT '-- Soft-delete Track 5';
EXEC Org.sp_DeleteTrack @TrackID = 5;

-- Verify: 4 active tracks remain
EXEC Org.sp_SelectTrack;
GO

-- 3.4  INTAKE

-- 3.4.1  Insert 5 real intakes
EXEC Org.sp_InsertIntake @IntakeYear = 2023, @IntakeSemester = N'Spring';
EXEC Org.sp_InsertIntake @IntakeYear = 2023, @IntakeSemester = N'Fall';
EXEC Org.sp_InsertIntake @IntakeYear = 2024, @IntakeSemester = N'Spring';
EXEC Org.sp_InsertIntake @IntakeYear = 2024, @IntakeSemester = N'Fall';
EXEC Org.sp_InsertIntake @IntakeYear = 2025, @IntakeSemester = N'Spring';

-- 3.4.2  Select all active intakes (should return 5 rows)
EXEC Org.sp_SelectIntake;

-- 3.4.3  Update Intake 1
EXEC Org.sp_UpdateIntake
            @IntakeID       = 1,
            @IntakeYear     = 2023,
            @IntakeSemester = N'Summer';

-- Verify update
EXEC Org.sp_SelectIntake;

-- 3.4.4  Soft-delete Intake 5
EXEC Org.sp_DeleteIntake @IntakeID = 5;

-- Verify: 4 active intakes remain
EXEC Org.sp_SelectIntake;

-- 3.5  INTAKE_TRACK  (junction / linking table)
PRINT '-- 3.5  Intake_Track SPs';

-- 3.5.1  Link 5 real Intake-Track combinations
--        Active intakes: 1 (2023 Summer), 2 (2023 Fall), 3 (2024 Spring), 4 (2024 Fall)
--        Active tracks : 1 (Backend), 2 (Full-Stack), 3 (DBA), 4 (ML)
EXEC Org.sp_InsertIntack_Track @IntakeID = 1, @TrackID = 1;
EXEC Org.sp_InsertIntack_Track @IntakeID = 1, @TrackID = 2;
EXEC Org.sp_InsertIntack_Track @IntakeID = 2, @TrackID = 3;
EXEC Org.sp_InsertIntack_Track @IntakeID = 3, @TrackID = 4;
EXEC Org.sp_InsertIntack_Track @IntakeID = 4, @TrackID = 2;

-- 3.5.2  Select all active Intake_Track links (should return 5 rows)
EXEC Org.sp_SelectIntack_Track;

-- 3.5.3  Soft-delete one link
EXEC Org.sp_DeleteIntack_Track @IntakeID = 4, @TrackID = 2;

-- Verify: 4 active links remain
EXEC Org.sp_SelectIntack_Track;
GO

-- SECTION 5 : ORG VIEWS

-- 5.1  V_Org_Branch
SELECT * FROM V_Org_Branch;                   -- Expected: non-deleted branches only

-- 5.2  V_Org_Department
SELECT * FROM V_Org_Department;               -- Expected: non-deleted departments

-- 5.3  V_Org_Track  (with DepartmentName from JOIN)
SELECT * FROM V_Org_Track;                    -- Expected: TrackId, DepartmentName, TrackName

-- 5.4  V_Org_Intake
SELECT * FROM V_Org_Intake;                   -- Expected: active intakes


-- SECTION 6 : REGISTER USERS (Training Managers, Instructors, Students)

-- TM 1 – Dr. Amira Mahmoud (Head of CS&Eng)
EXEC Users.usp_RegisterInstructor
@Username     = N'amira.mahmoud',
@Email        = N'amira.mahmoud@examdb.edu.eg',
@PlainPassword= N'Amira@2025!',
@FirstName    = N'Amira',
@LastName     = N'Mahmoud',
@SSN          = N'28901012345001',
@Phone        = N'01012345601',
@CreatedBy    = NULL,
@Salary       = 18500.00,
@HireDate     = '2018-09-01',
@Office       = N'A101',
@Is_Manager   = 1;

-- TM 2 – Dr. Khaled Naguib (Head of IT)
EXEC Users.usp_RegisterInstructor
@Username     = N'khaled.naguib',
@Email        = N'khaled.naguib@examdb.edu.eg',
@PlainPassword= N'Khaled@2025!',
@FirstName    = N'Khaled',
@LastName     = N'Naguib',
@SSN          = N'28501015678002',
@Phone        = N'01112345602',
@CreatedBy    = NULL,
@Salary       = 19000.00,
@HireDate     = '2016-01-15',
@Office       = N'B205',
@Is_Manager   = 1;

-- TM 3 – Dr. Rania Fouad (Head of Data Science)
EXEC Users.usp_RegisterInstructor
@Username     = N'rania.fouad',
@Email        = N'rania.fouad@examdb.edu.eg',
@PlainPassword= N'Rania@2025!',
@FirstName    = N'Rania',
@LastName     = N'Fouad',
@SSN          = N'29001023456003',
@Phone        = N'01212345603',
@CreatedBy    = NULL,
@Salary       = 17800.00,
@HireDate     = '2019-03-01',
@Office       = N'C310',
@Is_Manager   = 1;

-- TM 4 – Dr. Hassan El-Sayed (Head of Cybersecurity)
EXEC Users.usp_RegisterInstructor
@Username     = N'hassan.elsayed',
@Email        = N'hassan.elsayed@examdb.edu.eg',
@PlainPassword= N'Hassan@2025!',
@FirstName    = N'Hassan',
@LastName     = N'El-Sayed',
@SSN          = N'27801034567004',
@Phone        = N'01512345604',
@CreatedBy    = NULL,
@Salary       = 20000.00,
@HireDate     = '2015-07-01',
@Office       = N'D415',
@Is_Manager   = 1;

-- TM 5 – Dr. Nadia Rashad (Head of Software Engineering)
EXEC Users.usp_RegisterInstructor
@Username     = N'nadia.rashad',
@Email        = N'nadia.rashad@examdb.edu.eg',
@PlainPassword= N'Nadia@2025!',
@FirstName    = N'Nadia',
@LastName     = N'Rashad',
@SSN          = N'29301045678005',
@Phone        = N'01012345605',
@CreatedBy    = NULL,
@Salary       = 17500.00,
@HireDate     = '2020-02-01',
@Office       = N'E520',
@Is_Manager   = 1;

-- Verify 5 Training Managers were registered
SELECT
    I.InstructorID,
    A.Username,
    A.Email,
    A.Role,
    I.Salary,
    I.HireDate,
    I.Office,
    I.Is_Manager
FROM   Users.Instructor I
    JOIN   Users.Person     P ON I.InstructorID = P.PersonId
    JOIN   Users.Account    A ON P.AccountId    = A.AccountId
WHERE  I.Is_Manager = 1;
GO


-- Instructor 1 – Eng. Omar Samir (Backend Development)
EXEC Users.usp_RegisterInstructor
                @Username     = N'omar.samir',
                @Email        = N'omar.samir@examdb.edu.eg',
                @PlainPassword= N'Omar@2025!',
                @FirstName    = N'Omar',
                @LastName     = N'Samir',
                @SSN          = N'29501056789006',
                @Phone        = N'01012345606',
                @CreatedBy    = NULL,
                @Salary       = 12000.00,
                @HireDate     = '2021-09-01',
                @Office       = N'A102',
                @Is_Manager   = 0;

-- Instructor 2 – Eng. Dina Kamal (Database Administration)
EXEC Users.usp_RegisterInstructor
                @Username     = N'dina.kamal',
                @Email        = N'dina.kamal@examdb.edu.eg',
                @PlainPassword= N'Dina@2025!',
                @FirstName    = N'Dina',
                @LastName     = N'Kamal',
                @SSN          = N'29801067890007',
                @Phone        = N'01112345607',
                @CreatedBy    = NULL,
                @Salary       = 11500.00,
                @HireDate     = '2022-01-15',
                @Office       = N'B206',
                @Is_Manager   = 0;

-- Instructor 3 – Dr. Mostafa Ibrahim (Machine Learning)
EXEC Users.usp_RegisterInstructor
                @Username     = N'mostafa.ibrahim',
                @Email        = N'mostafa.ibrahim@examdb.edu.eg',
                @PlainPassword= N'Mostafa@2025!',
                @FirstName    = N'Mostafa',
                @LastName     = N'Ibrahim',
                @SSN          = N'28701078901008',
                @Phone        = N'01212345608',
                @CreatedBy    = NULL,
                @Salary       = 14000.00,
                @HireDate     = '2020-09-01',
                @Office       = N'C311',
                @Is_Manager   = 0;

-- Instructor 4 – Eng. Sara Tarek (Full-Stack Development)
EXEC Users.usp_RegisterInstructor
                @Username     = N'sara.tarek',
                @Email        = N'sara.tarek@examdb.edu.eg',
                @PlainPassword= N'Sara@T2025!',
                @FirstName    = N'Sara',
                @LastName     = N'Tarek',
                @SSN          = N'30001089012009',
                @Phone        = N'01512345609',
                @CreatedBy    = NULL,
                @Salary       = 12500.00,
                @HireDate     = '2022-09-01',
                @Office       = N'A103',
                @Is_Manager   = 0;

-- Instructor 5 – Dr. Youssef Gamal (Network Security)
EXEC Users.usp_RegisterInstructor
                @Username     = N'youssef.gamal',
                @Email        = N'youssef.gamal@examdb.edu.eg',
                @PlainPassword= N'Youssef@2025!',
                @FirstName    = N'Youssef',
                @LastName     = N'Gamal',
                @SSN          = N'28301090123010',
                @Phone        = N'01012345610',
                @CreatedBy    = NULL,
                @Salary       = 13500.00,
                @HireDate     = '2019-09-01',
                @Office       = N'D416',
                @Is_Manager   = 0;

-- Verify 5 Instructors registered (Is_Manager = 0)
SELECT
    I.InstructorID,
    A.Username,
    A.Email,
    A.Role,
    I.Salary,
    I.HireDate,
    I.Office,
    I.Is_Manager
FROM   Users.Instructor I
    JOIN   Users.Person     P ON I.InstructorID = P.PersonId
    JOIN   Users.Account    A ON P.AccountId    = A.AccountId
WHERE  I.Is_Manager = 0;
GO



-- Register 10 Students
-- Student 1 – Ahmed Sayed Ali
EXEC Users.usp_RegisterStudent
                @Username     = N'ahmed.ali',
                @Email        = N'ahmed.ali@student.examdb.edu.eg',
                @PlainPassword= N'Ahmed@2025!',
                @FirstName    = N'Ahmed',
                @LastName     = N'Ali',
                @SSN          = N'20301101234011',
                @Phone        = N'01012345611',
                @CreatedBy    = NULL,
                @TrackID      = 1,
                @IntakeID     = 1,
                @BranchID     = 1;

-- Student 2 – Mona Hossam Fawzy
EXEC Users.usp_RegisterStudent
                @Username     = N'mona.fawzy',
                @Email        = N'mona.fawzy@student.examdb.edu.eg',
                @PlainPassword= N'Mona@2025!',
                @FirstName    = N'Mona',
                @LastName     = N'Fawzy',
                @SSN          = N'20301112345012',
                @Phone        = N'01112345612',
                @CreatedBy    = NULL,
                @TrackID      = 2,
                @IntakeID     = 1,
                @BranchID     = 2;

-- Student 3 – Karim Adel Mansour
EXEC Users.usp_RegisterStudent
                @Username     = N'karim.mansour',
                @Email        = N'karim.mansour@student.examdb.edu.eg',
                @PlainPassword= N'Karim@2025!',
                @FirstName    = N'Karim',
                @LastName     = N'Mansour',
                @SSN          = N'20301123456013',
                @Phone        = N'01212345613',
                @CreatedBy    = NULL,
                @TrackID      = 3,
                @IntakeID     = 2,
                @BranchID     = 1;

-- Student 4 – Nour Essam Badawi
EXEC Users.usp_RegisterStudent
                @Username     = N'nour.badawi',
                @Email        = N'nour.badawi@student.examdb.edu.eg',
                @PlainPassword= N'Nour@2025!',
                @FirstName    = N'Nour',
                @LastName     = N'Badawi',
                @SSN          = N'20301134567014',
                @Phone        = N'01512345614',
                @CreatedBy    = NULL,
                @TrackID      = 4,
                @IntakeID     = 2,
                @BranchID     = 3;

-- Student 5 – Yara Mahmoud Sorour
EXEC Users.usp_RegisterStudent
                @Username     = N'yara.sorour',
                @Email        = N'yara.sorour@student.examdb.edu.eg',
                @PlainPassword= N'Yara@2025!',
                @FirstName    = N'Yara',
                @LastName     = N'Sorour',
                @SSN          = N'20301145678015',
                @Phone        = N'01012345615',
                @CreatedBy    = NULL,
                @TrackID      = 1,
                @IntakeID     = 3,
                @BranchID     = 2;

-- Student 6 – Tamer Nabil El-Husseini
EXEC Users.usp_RegisterStudent
                @Username     = N'tamer.husseini',
                @Email        = N'tamer.husseini@student.examdb.edu.eg',
                @PlainPassword= N'Tamer@2025!',
                @FirstName    = N'Tamer',
                @LastName     = N'El-Husseini',
                @SSN          = N'20301156789016',
                @Phone        = N'01112345616',
                @CreatedBy    = NULL,
                @TrackID      = 2,
                @IntakeID     = 3,
                @BranchID     = 4;

-- Student 7 – Salma Wagdy Barakat
EXEC Users.usp_RegisterStudent
                @Username     = N'salma.barakat',
                @Email        = N'salma.barakat@student.examdb.edu.eg',
                @PlainPassword= N'Salma@2025!',
                @FirstName    = N'Salma',
                @LastName     = N'Barakat',
                @SSN          = N'20301167890017',
                @Phone        = N'01212345617',
                @CreatedBy    = NULL,
                @TrackID      = 3,
                @IntakeID     = 4,
                @BranchID     = 1;

-- Student 8 – Mohamed Ashraf El-Naggar
EXEC Users.usp_RegisterStudent
                @Username     = N'mohamed.elnaggar',
                @Email        = N'mohamed.elnaggar@student.examdb.edu.eg',
                @PlainPassword= N'Mohamed@2025!',
                @FirstName    = N'Mohamed',
                @LastName     = N'El-Naggar',
                @SSN          = N'20301178901018',
                @Phone        = N'01512345618',
                @CreatedBy    = NULL,
                @TrackID      = 4,
                @IntakeID     = 4,
                @BranchID     = 2;

-- Student 9 – Laila Hesham Khorshid
EXEC Users.usp_RegisterStudent
                @Username     = N'laila.khorshid',
                @Email        = N'laila.khorshid@student.examdb.edu.eg',
                @PlainPassword= N'Laila@2025!',
                @FirstName    = N'Laila',
                @LastName     = N'Khorshid',
                @SSN          = N'20301189012019',
                @Phone        = N'01012345619',
                @CreatedBy    = NULL,
                @TrackID      = 1,
                @IntakeID     = 1,
                @BranchID     = 3;

-- Student 10 – Amr Saeed Qasem
EXEC Users.usp_RegisterStudent
                @Username     = N'amr.qasem',
                @Email        = N'amr.qasem@student.examdb.edu.eg',
                @PlainPassword= N'Amr@Qasem2025!',
                @FirstName    = N'Amr',
                @LastName     = N'Qasem',
                @SSN          = N'20301190123020',
                @Phone        = N'01112345620',
                @CreatedBy    = NULL,
                @TrackID      = 2,
                @IntakeID     = 2,
                @BranchID     = 4;

-- Verify 10 students registered
SELECT
    S.StudentID,
    A.Username,
    A.Email,
    A.Role,
    P.FirstName,
    P.LastName,
    S.TrackID,
    S.IntakeID,
    S.BranchID
FROM   Users.Student S
    JOIN   Users.Person  P ON S.StudentID  = P.PersonId
    JOIN   Users.Account A ON P.AccountId = A.AccountId;
GO


-- ----------------------------------------------------------------
-- SECTION 7 : ACCOUNT MANAGEMENT STORED PROCEDURES

-- 7.1  usp_ListAccountsByRole
--      Tests: filter by role, pagination, include inactive flag.
EXEC Users.usp_ListAccountsByRole
                    @Role           = NULL,
                    @PageNumber     = 1,
                    @PageSize       = 5,
                    @IncludeInactive= 0;

-- List only Students, page 1, 10 per page
EXEC Users.usp_ListAccountsByRole
                    @Role       = N'Student',
                    @PageNumber = 1,
                    @PageSize   = 10;

-- List only TrainingManagers
EXEC Users.usp_ListAccountsByRole
                    @Role       = N'TrainingManager',
                    @PageNumber = 1,
                    @PageSize   = 10;

-- List only Instructors
EXEC Users.usp_ListAccountsByRole
                    @Role       = N'Instructor',
                    @PageNumber = 1,
                    @PageSize   = 10;

-- Page 2 of all accounts, 5 per page
EXEC Users.usp_ListAccountsByRole
                    @Role           = NULL,
                    @PageNumber     = 2,
                    @PageSize       = 5,
                    @IncludeInactive= 0;
GO

-- ----------------------------------------------------------------
-- 7.3  usp_ChangePassword
--      Test password change for an existing account.
-- (Old password was set during usp_RegisterStudent as 'Mona@2025!')
EXEC Users.usp_ChangePassword
            @OldPassword = N'Mona@2025!',
            @NewPassword = N'MonaNew@2026!',
            @Username    = N'mona.fawzy';

-- ----------------------------------------------------------------

-- SECTION 8 : PERSON MANAGEMENT STORED PROCEDURES

-- 8.1  usp_UpdateProfile  (self-update simulation using @TargetUsername)

-- Update phone and last name for student karim.mansour
EXEC Users.usp_UpdateProfile
            @FirstName      = N'Karim',
            @LastName       = N'Mansour El-Sayed',
            @Phone          = N'01212345699',
            @SSN            = N'20301123456013',
            @TargetUsername = N'karim.mansour';

-- Verify update
SELECT P.FirstName, P.LastName, P.Phone, P.SSN
FROM   Users.Person P
    JOIN   Users.Account A ON P.AccountId = A.AccountId
WHERE  A.Username = N'karim.mansour';

-- ----------------------------------------------------------------
-- SECTION 9 : STUDENT MANAGEMENT STORED PROCEDURES

-- 9.1  usp_GetStudent
-- Retrieve by username
EXEC Users.usp_GetStudent @Username = N'ahmed.ali';

-- ----------------------------------------------------------------
-- 9.2  usp_UpdateStudent  – change Track and Intake assignments

-- Move nour.badawi to Track 1 and Intake 3
EXEC Users.usp_UpdateStudent
            @TargetUsername = N'nour.badawi',
            @TrackID        = 1,
            @IntakeID       = 3,
            @BranchID       = 2;

-- Verify
SELECT S.StudentID, S.TrackID, S.IntakeID, S.BranchID
FROM   Users.Student S
    JOIN   Users.Person  P ON S.StudentID = P.PersonId
    JOIN   Users.Account A ON P.AccountId = A.AccountId
WHERE  A.Username = N'nour.badawi';
GO

-- ----------------------------------------------------------------
-- 9.3  usp_DeleteStudent  – soft delete one student

-- Delete student amr.qasem (Student 10)
EXEC Users.usp_DeleteStudent @Username = N'amr.qasem';

-- Verify: IsDeleted = 1 in Person, IsActive = 0 in Account
SELECT A.Username, A.IsActive, P.IsDeleted
FROM   Users.Account A
    JOIN   Users.Person  P ON A.AccountId = P.AccountId
WHERE  A.Username = N'amr.qasem';         -- Expected: IsActive=0, IsDeleted=1
GO

-- ----------------------------------------------------------------
-- SECTION 10 : INSTRUCTOR MANAGEMENT STORED PROCEDURES

-- 10.1  usp_GetInstructor
EXEC Users.usp_GetInstructor @Username = N'mostafa.ibrahim';

-- ----------------------------------------------------------------
-- 10.2  usp_UpdateInstructor  – update salary, office

-- Give omar.samir a salary raise and new office
EXEC Users.usp_UpdateInstructor
                @TargetUsername = N'omar.samir',
                @Salary         = 14000.00,
                @Office         = N'A110',
                @Is_Manager     = 0;

-- Verify
SELECT I.Salary, I.Office, I.Is_Manager
FROM   Users.Instructor I
    JOIN   Users.Person     P ON I.InstructorID = P.PersonId
    JOIN   Users.Account    A ON P.AccountId    = A.AccountId
WHERE  A.Username = N'omar.samir';

-- 10.3  Promote an instructor to Training Manager via usp_UpdateInstructor
EXEC Users.usp_UpdateInstructor
                @TargetUsername = N'dina.kamal',
                @Salary         = 16000.00,
                @Office         = N'B210',
                @Is_Manager     = 1;

-- Verify role updated in Account table too
SELECT A.Username, A.Role, I.Is_Manager
FROM   Users.Instructor I
    JOIN   Users.Person     P ON I.InstructorID = P.PersonId
    JOIN   Users.Account    A ON P.AccountId    = A.AccountId
WHERE  A.Username = N'dina.kamal';           -- Expected: Role = TrainingManager, Is_Manager = 1
GO

-- ----------------------------------------------------------------
-- 10.4  usp_DeleteInstructor  – soft delete one instructor

-- Delete instructor youssef.gamal
EXEC Users.usp_DeleteInstructor @Username = N'youssef.gamal';

-- Verify soft-delete
SELECT A.Username, A.IsActive, P.IsDeleted
FROM   Users.Account A
JOIN   Users.Person  P ON A.AccountId = P.AccountId
WHERE  A.Username = N'youssef.gamal';        -- Expected: IsActive=0, IsDeleted=1
GO

-- ----------------------------------------------------------------
-- SECTION 12 : USERS VIEWS

-- 12.1  Users.vw_StudentDetails
SELECT *
FROM   Users.vw_StudentDetails;

-- ----------------------------------------------------------------
-- 12.2  Users.vw_InstructorDetails

SELECT *
FROM   Users.vw_InstructorDetails;

-- ----------------------------------------------------------------
-- 12.3  Users.vw_ActiveContactList
SELECT *
FROM   Users.vw_ActiveContactList
ORDER  BY UserCategory, FullName;

-- ----------------------------------------------------------------
-- SECTION 15 : SECURITY & PERMISSION TESTS

-- ----------------------------------------------------------------
-- 15.1  Test as db_Student role member
--       Students can: ChangePassword, UpdateProfile, GetStudent
--       Students CANNOT: GetInstructor, RegisterStudent,
--                        ListAccountsByRole, direct DML on AuditLog
-- ----------------------------------------------------------------
-- ALLOWED: get own student record
EXEC Users.usp_GetStudent

-- ALLOWED: update own profile
EXEC Users.usp_UpdateProfile
            @Phone = N'01012345698'

-- ----------------------------------------------------------------
-- 15.2  Simulate db_Student: DENIED operations

-- DENIED: a student should NOT be able to call usp_ListAccountsByRole
EXEC Users.usp_ListAccountsByRole @Role = N'Instructor';

-- DENIED: a student should NOT be able to delete another student
EXEC Users.usp_DeleteStudent @Username = N'mona.fawzy';

-- -- ----------------------------------------------------------------
-- 15.3  Test as db_Instructor role member
--       Instructors can: GetInstructor, UpdateProfile, ChangePassword
--       (They also inherit TrainingManager if promoted)
-- -- ----------------------------------------------------------------

-- ALLOWED: get own instructor record
EXEC Users.usp_GetInstructor @Username = N'Mina_';

-- ALLOWED: update own profile
EXEC Users.usp_UpdateProfile
            @Phone          = N'01012345697',
            @TargetUsername = N'Mina_';

-- ----------------------------------------------------------------
-- DENIED: instructor cannot delete
EXEC Users.usp_DeleteInstructor @Username = N'student_1';

-- ----------------------------------------------------------------
-- 15.5  Test as db_TrainingManager role member
--       Training Managers CAN register, update, delete instructors & students.
-- -- ----------------------------------------------------------------

-- ALLOWED: list all student accounts
EXEC Users.usp_ListAccountsByRole @Role = N'Student', @PageNumber = 1, @PageSize = 5;

-- ALLOWED: get any student record
EXEC Users.usp_GetStudent @Username = N'student_';

-- ALLOWED: update a student enrollment
EXEC Users.usp_UpdateStudent
                @TargetUsername = N'mona.fawzy',
                @TrackID        = 2,
                @IntakeID       = 2,
                @BranchID       = 3;

-- ALLOWED: read Org data via views
SELECT * FROM V_Org_Branch;
SELECT * FROM V_Org_Department;

-- ================================================================
-- 15.6  Test self-deletion prevention
--       A user should not be able to delete their own account.
-- ================================================================
-- 15.6  Self-deletion prevention
EXEC Users.usp_DeleteAccount @TargetUsername = N'Mina_';


-- Select audit log rows';
SELECT TOP 20
Operation,
[Values],
ChangedAt
FROM   Ops.AuditLog
-- WHERE  SchemaName = 'Users' AND TableName = 'Account' AND Operation = 'UPDATE'
ORDER  BY ChangedAt DESC;