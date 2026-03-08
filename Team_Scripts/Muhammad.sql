
DECLARE @TempPassword NVARCHAR(4000), @rand VARBINARY(16) = CRYPT_GEN_RANDOM(16);
SET @TempPassword =  CONVERT(VARCHAR(8), HASHBYTES('SHA2_256', @rand), 2); -- not ideal for production

select @TempPassword as TempPassword, @rand;

select CRYPT_GEN_RANDOM(16)

select SUSER_NAME()

begin try
	if 5 > 3
	begin
		RAISERROR('Username already taken.', 16, 1);
	end
	select 5
end try
begin catch
	print ERROR_MESSAGE()
end catch


-- test Create Accout procedure

-- email validation test
EXEC [Users].[usp_CreateAccount]
    @Username = N'Invalid_Email', 
    @Email = N'wrong.email.com', -- no @ in email
    @PlainPassword = N'Secure@P4ss', 
    @Role = N'Student';

-- validate password strength
EXEC Users.usp_CreateAccount
    @Username = N'Weak_Pass', 
    @Email = N'test@test.com', 
    @PlainPassword = N'Password123',
    @Role = N'Student';

-- validate username length
EXEC Users.usp_CreateAccount
    @Username = N'Ab',
    @Email = N'ab@test.com', 
    @PlainPassword = N'Secure@P4ss', 
    @Role = N'Student';


-- if repeat the same username or email, should get error about duplicates
EXEC Users.usp_CreateAccount 
    @Username = N'Ahmed_IT', 
    @Email = N'another@email.com', 
    @PlainPassword = N'Secure@P4ss', 
    @Role = N'Student';

EXEC Users.usp_CreateAccount 
    @Username = N'Ahmed_IT2', 
    @Email = N'another@email.com', 
    @PlainPassword = N'Secure@P4ss', 
    @Role = N'Student';

-- invalid role test - should fail due to CHECK constraint on Role column
EXEC Users.usp_CreateAccount 
    @Username = N'Hacker_User', 
    @Email = N'hacker@iti.com', 
    @PlainPassword = N'Secure@P4ss', 
    @Role = N'GodMode';


EXEC Users.usp_CreateAccount 
    @Username = N'Muhammad_IT', 
    @Email = N'muhammad@email.com', 
    @PlainPassword = N'Muhammad@123', 
    @Role = N'Admin';

DECLARE @AccountId INT
EXEC Users.usp_CreateAccount 
    @Username = N'Muhammad_', 
    @Email = N'muhammad_2@email.com', 
    @PlainPassword = N'Muhammad@123', 
    @Role = N'Admin',
    @NewAccountId = @AccountId OUTPUT;

SELECT @AccountId AS NewAccountId;

    
EXEC Users.usp_CreateAccount 
    @Username = N'minaa', 
    @Email = N'minaa@email.com', 
    @PlainPassword = N'Mina@123', 
    @Role = N'Instructora';

EXEC Users.usp_CreateAccount 
    @Username = N'arwa', 
    @Email = N'arwa@email.com', 
    @PlainPassword = N'Arwa@123', 
    @Role = N'TrainingManager';

select * from Users.Account

update Users.Account
    set PasswordIterations = 100


-- test change password procedure
EXEC Users.usp_ChangePassword
    @OldPassword = 'Abdo@123', 
    @NewPassword = 'Abdo@1234', 
    @Username = 'abdo';


select SUSER_NAME()


select Username, [Role], IS_ROLEMEMBER('db_Student', Username)
from Users.Account

select Username, [Role], IS_ROLEMEMBER('db_Instructor', Username)
from Users.Account

select Username, [Role], IS_ROLEMEMBER('db_TrainingManager', Username)
from Users.Account

select Username, [Role], IS_ROLEMEMBER('db_Admin', Username)
from Users.Account

select * from Ops.AuditLog

select USER_ID('MUHAMMED\Lenovo'), SUSER_NAME()

-- test delete account procedure
EXEC Users.usp_DeleteAccount Null, 'arwa'

select * from Users.Account

-- test pagination
EXEC Users.usp_ListAccountsByRole  @Role = NULL, @PageNumber = 1, @IncludeInactive = 1, @PageSize = 3


-- insert some ORG data for the foreign keys
USE [ExamSystemDB];
GO

-- 1. إدخال بيانات في جدول الفروع (Org.Branch)
INSERT INTO Org.Branch (BranchName)
VALUES 
(N'Smart Village'),
(N'Cairo - Nasr City'),
(N'Alexandria'),
(N'Mansoura'),
(N'Assiut');
GO

-- 2. إدخال بيانات في جدول الأقسام (Org.Department)
INSERT INTO Org.Department (DepartmentName)
VALUES 
(N'Software Development'),
(N'Data Science'),
(N'Cyber Security'),
(N'Business Solutions'),
(N'Network Administration');
GO

-- 3. إدخال بيانات في جدول المسارات (Org.Track) 
-- (ملاحظة: تعتمد على الـ DepartmentId الناتجة من الجدول السابق)
INSERT INTO Org.Track (DepartmentId, TrackName)
VALUES 
(1, N'Full Stack Web Development (ASP.NET)'),
(1, N'Mobile Application Development (Flutter)'),
(2, N'Data Analysis'),
(3, N'Ethical Hacking'),
(4, N'ERP Solutions (Odoo)');
GO

-- 4. إدخال بيانات في جدول الدفعات (Org.Intake)
INSERT INTO Org.Intake (IntakeYear, IntakeSemester)
VALUES 
(2023, N'Q1'),
(2023, N'Q3'),
(2024, N'Winter'),
(2024, N'Summer'),
(2025, N'Q1');
GO

-- 5. إدخال بيانات في جدول الربط بين الدفعة والمسار (Org.Intake_Track)
-- (ملاحظة: تربط المعرفات من جدول Intake و Track)
INSERT INTO Org.Intake_Track (IntakeId, TrackId)
VALUES 
(1, 7), -- الدفعة الأولى بمسار Web Development
(1, 8), -- الدفعة الأولى بمسار Mobile Development
(2, 9), -- الدفعة الثانية بمسار Data Analysis
(3, 10), -- الدفعة الثالثة بمسار Ethical Hacking
(4, 11); -- الدفعة الرابعة بمسار ERP Solutions
GO

delete from ORG.Track

select * from Org.Branch
select * from Org.Department
select * from Org.Track
select * from Org.Intake
select * from Org.Intake_Track

-- test create Student
EXEC Users.usp_RegisterStudent 
    @Username = 'ahmed_student5', 
    @Email = 'ahmed2@example.com', 
    @PlainPassword = 'Password@123', 
    @FirstName = 'Ahmed', @LastName = 'Ali', 
    @SSN = '12345678901234', @Phone = '01012345678',
    @TrackID = 7, @IntakeID = 1, @BranchID = 1;

-- test create Instructor
EXEC Users.usp_RegisterInstructor 
    @Username = 'sara_instructor5', 
    @Email = 'saraaa2@example.com', 
    @PlainPassword = 'SafePassworddd@2026', 
    @FirstName = 'Sara', @LastName = 'Hassan', 
    @SSN = '12345678901236', @Phone = '01012345671',
    @Salary = 15000.50, @Office = 'Room 302', @Is_Manager = 1;


exec Users.usp_DeleteAccount 19, NULL
exec Users.usp_DeleteAccount 20, NULL
exec Users.usp_DeleteAccount 22, NULL
delete from Users.Person
delete from Users.Student
delete from Users.Instructor

-- check the created accounts and related person records
select * from Users.Account
select * from Users.Person
select * from Users.Student
select * from Users.Instructor

-- test Users views
select * from Users.vw_StudentDetails

select * from Users.vw_InstructorDetails

select * from Users.vw_ActiveContactList

delete from Users.Account
where [Role] = 'Student' and IsActive = 1


DECLARE @InstructorID INT = 12
        DECLARE @InstructorUsername NVARCHAR(100);
        SELECT A.Username
        FROM Users.Account A
            JOIN Users.Person P ON A.AccountId = P.AccountId
        WHERE P.PersonId = @InstructorID
          AND A.IsActive = 1;


select NEWID(), SUBSTRING(CONVERT(VARCHAR(36), NEWID()), 1, 14) as RandomString






-- test
-- usp_RegisterInstructor
 EXEC Users.usp_RegisterInstructor
        @Username = 'Mina_',
        @Email = 'mina_@gamil.com',
        @PlainPassword = 'Mina@123',
        @FirstName = 'Mina',
        @LastName = 'Mina',
        @SSN = '99999998888866',
        @Phone = '01277777711',
        @CreatedBy = NULL,
        @Salary = 60000.00,
        @HireDate = NULL,
        @Office = N'Main Campus',
        @Is_Manager = 1;

-- test usp_RegisterStudent
EXEC Users.usp_RegisterStudent
        @Username = 'student_1',
        @Email = 'student_1@test.com',
        @PlainPassword = 'Student@123',
        @FirstName = 'Student',
        @LastName = 'Student',
        @SSN = '44444445555555',
        @Phone = '01099999922',
        @CreatedBy = NULL,
        @TrackID = 9001,
        @IntakeID = 9001,
        @BranchID = 9001





select * from Users.Account

        -- Admin : 
        -- username : Muhammad_
        -- password : Muhammad@123        

        -- Training Manager :
        -- username : Mina_
        -- password : Mina@123 

        -- Instructor :
        -- username : Salma_
        -- password : Salma@123

        -- Student :
        -- username : student_1
        -- password : Student@123 

        select * from Users.Account


select p.personID
from Users.Account A
    JOIN Users.Person P ON A.AccountId = P.AccountId
WHERE A.Username = SUSER_NAME()


select SUSER_SNAME()


DECLARE @currentUserID int, @currentUsername NVARCHAR(100)

select P.PersonId, S.StudentID
from Users.Student AS S
JOIN Users.Person AS P
    ON S.StudentID = P.PersonId
JOIN Users.Account AS A ON P.AccountId = A.AccountId
WHERE A.Username = 'student_1' OR S.StudentID = NULL

SELECT @currentUserID AS [Student ID], @currentUsername AS USERNAME  
 

  EXEC Users.usp_GetStudent @Username = 'stud_demo01', @StudentId = 55;-- Current user looks up own record


select SUSER_NAME()


select @@version


select [StudentName], [Student_Answer]
from Assessment.vw_StudentAnswerSheet
where [StudentID] = 37

select * from Assessment.vw_StudentExamResults  
where StudentID = 37


exec Assessment.sp_SearchExamResults 


EXEC Assessment.sp_UpsertAnswer
    @StudentID = 37, @ExamID = @EID8,
    @QuestionID = 9001,
    @Student_Answer = 'Structured Query Language';   
                

select S.*, A.Username
from Users.Student S JOIN Users.Person p 
ON S.StudentID = P.PersonId JOIN Users.Account A
ON A.AccountId = P.AccountId
where P.IsDeleted = 0


select I.*, A.Username
from Users.Instructor I JOIN Users.Person p 
ON I.InstructorID = P.PersonId JOIN Users.Account A
ON A.AccountId = P.AccountId
where P.IsDeleted = 0


select * from Users.Instructor


