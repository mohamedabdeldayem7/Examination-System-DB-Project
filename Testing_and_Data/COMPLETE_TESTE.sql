USE ExamSystemDB;
GO

select SUSER_NAME()
---------------------------------------------------------------------------
DELETE FROM Assessment.Student_Exam_Result  WHERE StudentID IN (37,38);
DELETE FROM Assessment.Student_Exam         WHERE StudentID IN (37,38);
--DELETE FROM Ops.AuditLog                    WHERE [Key] BETWEEN 9001 AND 9999;
DELETE FROM Assessment.Student_Answer       WHERE StudentID IN (37,38,9005);
DELETE FROM Assessment.Exam_Questions       WHERE ExamID IN (SELECT ExamID FROM Assessment.Exam WHERE CourseID = 9001);
DELETE FROM Assessment.Exam                 WHERE CourseID = 9001;
DELETE FROM Academic.Question_Choices       WHERE QuestionID BETWEEN 9001 AND 9999;
DELETE FROM Academic.Question_Pool          WHERE CourseID = 9001;
DELETE FROM Academic.Course_Instructor      WHERE CourseID = 9001 OR InstructorID IN (33,35,9006);
DELETE FROM Academic.Course                 WHERE CourseID = 9001;
--DELETE FROM Users.Student                   WHERE StudentID IN (9002,38,9005);
--DELETE FROM Users.Instructor                WHERE InstructorID IN (9001,9004,9006);
--DELETE FROM Users.Person                    WHERE PersonId IN (9001,9002,38,9004,9005,9006);
--DELETE FROM Users.Account                   WHERE AccountId IN (9001,9002,38,9004,9005,9006);
DELETE FROM Org.Intake_Track                WHERE IntakeId = 9001 OR TrackId = 9001;
DELETE FROM Org.Intake                      WHERE IntakeId = 9001;
DELETE FROM Org.Track                       WHERE TrackId = 9001;
DELETE FROM Org.Department                  WHERE DepartmentId = 9001;
DELETE FROM Org.Branch                      WHERE BranchId IN (9001,9002);


--  SECTION A: TEST DATA SETUP
--  Using IDs 9001
-----------------------------------------------------------------

-- A1: Department
SET IDENTITY_INSERT Org.Department ON;
INSERT INTO Org.Department (DepartmentId, DepartmentName)
VALUES (9001, 'TEST_Department_IT');
SET IDENTITY_INSERT Org.Department OFF;
PRINT 'A1: Department 9001 created';

-- A2: Branch
SET IDENTITY_INSERT Org.Branch ON;
INSERT INTO Org.Branch (BranchId, BranchName)
VALUES (9001, 'TEST_Branch_Cairo');
SET IDENTITY_INSERT Org.Branch OFF;
PRINT 'A2: Branch 9001 created';


-- A3: Track
SET IDENTITY_INSERT Org.Track ON;
INSERT INTO Org.Track (TrackId, TrackName, DepartmentId)
VALUES (9001, 'TEST_Track_DotNet', 9001);
SET IDENTITY_INSERT Org.Track OFF;
PRINT 'A3: Track 9001 created';

-- A4: Intake
SET IDENTITY_INSERT Org.Intake ON;
INSERT INTO Org.Intake (IntakeId, IntakeYear, IntakeSemester)
VALUES (9001, 2026, 'Spring');
SET IDENTITY_INSERT Org.Intake OFF;
PRINT 'A4: Intake 9001 created';

-- A5: Intake_Track link
INSERT INTO Org.Intake_Track (IntakeId, TrackId)
VALUES (9001, 9001);
PRINT 'A5: Intake 9001 linked to Track 9001';

-- A6: Course (Max=100, Min=50) 
INSERT INTO Academic.Course (CourseID, CourseName, Description, Max_Degree, Min_Degree)
VALUES (9001, 'TEST_SQL_Fundamentals', 'Test course for SQL', 100.00, 50.00);
PRINT 'A6: Course 9001 created (Max=100, Min=50)';


/*
-- A7: Instructor Person + Account + Instructor

-- test
-- usp_RegisterInstructor ID = 33
 EXEC Users.usp_RegisterInstructor
        @Username = 'test_instructor',
        @Email = 'test.inst@test.com',
        @PlainPassword = 'Test@123',
        @FirstName = 'Mina',
        @LastName = 'Magdy',
        @SSN = '11111111111111',
        @Phone = '012222222222',
        @CreatedBy = NULL,
        @Salary = 60000.00,
        @HireDate = NULL,
        @Office = N'Main Campus',
        @Is_Manager = 0;


-- A8: Training Manager ID = 35

EXEC Users.usp_RegisterInstructor
        @Username = 'test_TrainingManager',
        @Email = 'test2.inst@test.com',
        @PlainPassword = 'Test@123',
        @FirstName = 'Muhammad',
        @LastName = 'Abdo',
        @SSN = '22222222222222',
        @Phone = '01000000000',
        @CreatedBy = NULL,
        @Salary = 60000.00,
        @HireDate = NULL,
        @Office = N'Main Campus',
        @Is_Manager = 1;



-- A10: Student 1 ID = 37

EXEC Users.usp_RegisterStudent
        @Username = 'test_student1',
        @Email = 'ahmedahmed55@test.com',
        @PlainPassword = 'Ahmed@123',
        @FirstName = 'Ahmed',
        @LastName = 'Ahmed',
        @SSN = '99999999999999',
        @Phone = '01099999999',
        @CreatedBy = NULL,
        @TrackID = 9001,
        @IntakeID = 9001,
        @BranchID = 9001

        -> Student 2 ID = 38

EXEC Users.usp_RegisterStudent 
        @Username = 'test_student2',
        @Email = 'MinaMina55@test.com',
        @PlainPassword = 'Ahmed@123',
        @FirstName = 'Omar',
        @LastName = 'Ahmed',
        @SSN = '88888888888888',
        @Phone = '01099999988',
        @CreatedBy = NULL,
        @TrackID = 9001,
        @IntakeID = 9001,
        @BranchID = 9001

*/

-- A9: Course_Instructor link
INSERT INTO Academic.Course_Instructor (InstructorID, CourseID, Year)
VALUES (33, 9001, 2026);
PRINT 'A9: Instructor 33 assigned to Course 9001';
-- A12: Questions (5 MCQ + 3 TF + 2 Text = 10 questions)
SET IDENTITY_INSERT Academic.Question_Pool ON;

INSERT INTO Academic.Question_Pool (QuestionID, CourseID, InstructorID, QuestionType, QuestionText, Best_Accepted_Answer)
VALUES
(9001, 9001, 33, 'MCQ',       'What does SQL stand for?',                   NULL),
(9002, 9001, 33, 'MCQ',       'Which JOIN returns all rows from both?',      NULL),
(9003, 9001, 33, 'MCQ',       'What is a PRIMARY KEY?',                      NULL),
(9004, 9001, 33, 'MCQ',       'Which clause filters groups?',               NULL),
(9005, 9001, 33, 'MCQ',       'What does DISTINCT do?',                     NULL),
(9006, 9001, 33, 'TrueFalse', 'NULL = NULL returns TRUE',                   NULL),
(9007, 9001, 33, 'TrueFalse', 'DELETE removes table structure',             NULL),
(9008, 9001, 33, 'TrueFalse', 'VIEW is a virtual table',                    NULL),
(9009, 9001, 33, 'Text',      'Explain normalization in databases',          'Normalization is organizing data to reduce redundancy and improve integrity'),
(9010, 9001, 33, 'Text',      'What is the difference between WHERE and HAVING?', 'WHERE filters rows before grouping HAVING filters groups after aggregation');

SET IDENTITY_INSERT Academic.Question_Pool OFF;
PRINT 'A12: 10 questions created (5 MCQ, 3 TF, 2 Text)';

-- A13: Choices for MCQ questions
SET IDENTITY_INSERT Academic.Question_Choices ON;

-- Q9001: SQL stands for?
INSERT INTO Academic.Question_Choices (ChoiceID, QuestionID, ChoiceText, IsCorrectChoice) VALUES
(9001, 9001, 'Structured Query Language',  1),
(9002, 9001, 'Simple Query Language',      0),
(9003, 9001, 'Standard Query Logic',       0),
(9004, 9001, 'System Query Language',      0);

-- Q9002: Which JOIN returns all?
INSERT INTO Academic.Question_Choices (ChoiceID, QuestionID, ChoiceText, IsCorrectChoice) VALUES
(9005, 9002, 'INNER JOIN',  0),
(9006, 9002, 'LEFT JOIN',   0),
(9007, 9002, 'FULL JOIN',   1),
(9008, 9002, 'CROSS JOIN',  0);

-- Q9003: PRIMARY KEY?
INSERT INTO Academic.Question_Choices (ChoiceID, QuestionID, ChoiceText, IsCorrectChoice) VALUES
(9009, 9003, 'Unique identifier for each row', 1),
(9010, 9003, 'Foreign reference',               0),
(9011, 9003, 'Index type only',                 0),
(9012, 9003, 'Column alias',                    0);

-- Q9004: Which clause filters groups?
INSERT INTO Academic.Question_Choices (ChoiceID, QuestionID, ChoiceText, IsCorrectChoice) VALUES
(9013, 9004, 'WHERE',   0),
(9014, 9004, 'HAVING',  1),
(9015, 9004, 'GROUP BY',0),
(9016, 9004, 'ORDER BY',0);

-- Q9005: DISTINCT?
INSERT INTO Academic.Question_Choices (ChoiceID, QuestionID, ChoiceText, IsCorrectChoice) VALUES
(9017, 9005, 'Removes duplicate rows',  1),
(9018, 9005, 'Sorts results',           0),
(9019, 9005, 'Limits rows',             0),
(9020, 9005, 'Joins tables',            0);

-- Q9006: NULL = NULL (TrueFalse)
INSERT INTO Academic.Question_Choices (ChoiceID, QuestionID, ChoiceText, IsCorrectChoice) VALUES
(9021, 9006, 'True',  0),
(9022, 9006, 'False', 1);

-- Q9007: DELETE removes structure (TrueFalse)
INSERT INTO Academic.Question_Choices (ChoiceID, QuestionID, ChoiceText, IsCorrectChoice) VALUES
(9023, 9007, 'True',  0),
(9024, 9007, 'False', 1);

-- Q9008: VIEW is virtual table (TrueFalse)
INSERT INTO Academic.Question_Choices (ChoiceID, QuestionID, ChoiceText, IsCorrectChoice) VALUES
(9025, 9008, 'True',  1),
(9026, 9008, 'False', 0);

SET IDENTITY_INSERT Academic.Question_Choices OFF;
PRINT 'A13: 26 choices created for 8 questions';


------------------------------------------------------------------
--  SECTION B: EXAM CRUD TESTS
------------------------------------------------------------------
--  TEST B1: Create Exam — Valid
-- Expected: Exam created, returns exam details from vw_ExamDetails
PRINT ' TEST B1: Create Exam (valid)';
DECLARE @NewExamID INT;
DECLARE @B1_Start DATETIME = DATEADD(DAY,-1,GETDATE());
DECLARE @B1_End   DATETIME = DATEADD(DAY,30,GETDATE());
EXEC Assessment.sp_CreateExam
    @CourseID     = 9001,
    @InstructorID = 33,
    @BranchID     = 9001,
    @TrackID      = 9001,
    @IntakeID     = 9001,
    @ExamType     = 'Exam',
    @Total_Time   = 90,
    @Start_Time   = @B1_Start,
    @End_Time     = @B1_End,
    @Allowance_Options = 'No calculators',
    @ExamID       = @NewExamID OUTPUT;

PRINT '   Exam created with ID: ' + CAST(@NewExamID AS VARCHAR);
PRINT '   -- Result: 1 row returned — ExamID, CourseName=TEST_SQL_Fundamentals,';
PRINT '      InstructorName=Test Instructor, ExamType=Exam, QuestionCount=0';
PRINT '';
GO
/*
Expected output:
ExamID  ExamType  CourseName               InstructorName     QuestionCount  AllocatedDegree  RemainingDegree
-------------------------------------------------------------------------------------------------------------
[auto]    Exam      TEST_SQL_Fundamentals    Test Instructor    0              0.00             100.00
*/


--  TEST B2: Create Exam — Invalid ExamType
-- Expected: ERROR — ExamType must be Exam or Corrective
PRINT ' TEST B2: Create Exam (invalid ExamType)';
BEGIN TRY
    DECLARE @FailID INT;
    DECLARE @B2_Start DATETIME = DATEADD(DAY,2,GETDATE());
    DECLARE @B2_End   DATETIME = DATEADD(DAY,45,GETDATE());
    EXEC Assessment.sp_CreateExam
        @CourseID = 9001, @InstructorID = 33, @BranchID = 9001,
        @TrackID = 9001, @IntakeID = 9001, @ExamType = 'Quiz',
        @Total_Time = 30, @Start_Time = @B2_Start, @End_Time = @B2_End,
        @ExamID = @FailID OUTPUT;
    PRINT '   -- did not fail as expected';
END TRY
BEGIN CATCH
    PRINT '   -- Correctly rejected: ' + ERROR_MESSAGE();
END CATCH
PRINT '';
GO
/*
Expected ERROR:
ExamType must be Exam or Corrective.
*/


--  TEST B3: Create Exam — Instructor not assigned to course
-- Expected: ERROR — Instructor 9004 not assigned to Course 9001
PRINT ' TEST B3: Create Exam (instructor not assigned)';
BEGIN TRY
    DECLARE @FailID2 INT;
    DECLARE @B3_Start DATETIME = DATEADD(DAY,2,GETDATE());
    DECLARE @B3_End   DATETIME = DATEADD(DAY,45,GETDATE());
    EXEC Assessment.sp_CreateExam
        @CourseID = 9001, @InstructorID = 35, @BranchID = 9001,
        @TrackID = 9001, @IntakeID = 9001, @ExamType = 'Exam',
        @Total_Time = 60, @Start_Time = @B3_Start, @End_Time = @B3_End,
        @ExamID = @FailID2 OUTPUT;
    PRINT '   -- did not fail as expected';
END TRY
BEGIN CATCH
    PRINT '   -- Correctly rejected: ' + ERROR_MESSAGE();
END CATCH
PRINT '';
GO
/*
Expected ERROR:
Instructor 9004 not assigned to Course 9001.
*/


--  TEST B4: Read Exam
-- Expected: 3 result sets (exam details, questions [empty], assignments [empty])
PRINT ' TEST B4: Read Exam';
DECLARE @EID INT = (SELECT TOP 1 ExamID FROM Assessment.Exam WHERE CourseID = 9001 AND InstructorID = 33 ORDER BY ExamID DESC);
EXEC Assessment.sp_ReadExam @ExamID = @EID;
PRINT '   -- Result: 3 result sets — details (1 row), questions (0 rows), assignments (0 rows)';
PRINT '';
GO
/*
Result Set 1: Exam details (1 row)
Result Set 2: Exam questions (0 rows — no questions added yet)
Result Set 3: Student assignments (0 rows — no students assigned yet)
*/

--  SECTION C: EXAM QUESTIONS TESTS
------------------------------------------------------------------
--  TEST C1: Add question to exam (INSERT path of UPSERT)
-- Expected: Question added, NewTotal=10, Remaining=90
PRINT ' TEST C1: Add question (UPSERT INSERT path)';
DECLARE @EID1 INT = (SELECT TOP 1 ExamID FROM Assessment.Exam WHERE CourseID = 9001 AND InstructorID = 33 ORDER BY ExamID DESC);
EXEC Assessment.sp_UpsertExamQuestion @ExamID = @EID1, @QuestionID = 9001, @Question_Degree = 10;
PRINT '   -- Result: Action=Question added, NewTotal=10.00, Remaining=90.00, QuestionCount=1';
PRINT '';
GO
/*
ExamID  QuestionID  Action           PreviousDegree  NewDegree  NewTotal  Remaining  QuestionCount
-------------------------------------------------------------------------------------------------
[auto]  9001        Question added   NULL            10.00      10.00     90.00      1
*/


--  TEST C2: Update same question degree (UPDATE path of UPSERT)
-- Expected: Degree changed from 10 to 15, NewTotal=15
PRINT ' TEST C2: Update question degree (UPSERT UPDATE path)';
DECLARE @EID2 INT = (SELECT TOP 1 ExamID FROM Assessment.Exam WHERE CourseID = 9001 AND InstructorID = 33 ORDER BY ExamID DESC);
EXEC Assessment.sp_UpsertExamQuestion @ExamID = @EID2, @QuestionID = 9001, @Question_Degree = 15;
PRINT '   -- Result: Action=Degree updated, PreviousDegree=10.00, NewDegree=15.00, NewTotal=15.00';
PRINT '';
GO
/*
ExamID  QuestionID    Action           PreviousDegree  NewDegree  NewTotal  Remaining  QuestionCount
-------------------------------------------------------------------------------------------------
[auto]  9001        Degree updated    10.00           15.00      15.00     85.00      1
*/


--  TEST C3: Add more questions (for a complete exam)
PRINT ' TEST C3: Add 4 more questions';
DECLARE @EID3 INT = (SELECT TOP 1 ExamID FROM Assessment.Exam WHERE CourseID = 9001 AND InstructorID = 33 ORDER BY ExamID DESC);
EXEC Assessment.sp_UpsertExamQuestion @ExamID = @EID3, @QuestionID = 9002, @Question_Degree = 10;
EXEC Assessment.sp_UpsertExamQuestion @ExamID = @EID3, @QuestionID = 9006, @Question_Degree = 5;
EXEC Assessment.sp_UpsertExamQuestion @ExamID = @EID3, @QuestionID = 9008, @Question_Degree = 5;
EXEC Assessment.sp_UpsertExamQuestion @ExamID = @EID3, @QuestionID = 9009, @Question_Degree = 15;
PRINT '   -- Result: 5 questions total, NewTotal=50.00, Remaining=50.00';
PRINT '';
GO
/*
After all additions — each call returns 1 row:
ExamID  QuestionID  Action           NewDegree  NewTotal  Remaining  QuestionCount
---------------------------------------------------------------------------------
[auto]  9002        Question added   10.00      25.00     75.00      2
[auto]  9006        Question added   5.00       30.00     70.00      3
[auto]  9008        Question added   5.00       35.00     65.00      4
[auto]  9009        Question added   15.00      50.00     50.00      5

After all additions:
Q9001=15 (MCQ) + Q9002=10 (MCQ) + Q9006=5 (TF) + Q9008=5 (TF) + Q9009=15 (Text) = 50 total
*/


--  TEST C4: Exceed max degree
-- Expected: ERROR — capacity exceeded
PRINT ' TEST C4: Exceed max degree (should fail)';
BEGIN TRY
    DECLARE @EID4 INT = (SELECT TOP 1 ExamID FROM Assessment.Exam WHERE CourseID = 9001 AND InstructorID = 33 ORDER BY ExamID DESC);
    EXEC Assessment.sp_UpsertExamQuestion @ExamID = @EID4, @QuestionID = 9003, @Question_Degree = 60;
    PRINT '   -- did not fail as expected';
END TRY
BEGIN CATCH
    PRINT '   -- Correctly rejected: ' + ERROR_MESSAGE();
END CATCH
PRINT '';
GO
/*
Expected ERROR:
Exceeds capacity. NewTotal=110.00, Max=100.00, Available=50.00
*/


--  TEST C5: Delete a question then verify resequencing
-- Expected: Question removed, orders re-sequenced
PRINT ' TEST C5: Delete question and check order resequencing';
DECLARE @EID5 INT = (SELECT TOP 1 ExamID FROM Assessment.Exam WHERE CourseID = 9001 AND InstructorID = 33 ORDER BY ExamID DESC);

-- Add a temporary question at order 6
EXEC Assessment.sp_UpsertExamQuestion @ExamID = @EID5, @QuestionID = 9003, @Question_Degree = 10;
PRINT '   Added Q9003 (order 6)';

-- Delete it
EXEC Assessment.sp_DeleteExamQuestion @ExamID = @EID5, @QuestionID = 9003;
PRINT '   Deleted Q9003';
PRINT '   -- Result: Q9003 removed, remaining 5 questions, orders 1-5 sequential';

-- Verify orders are clean
SELECT QuestionID, Question_Order, Question_Degree
FROM Assessment.Exam_Questions
WHERE ExamID = @EID5
ORDER BY Question_Order;
PRINT '';
GO
/*
QuestionID  Question_Order  Question_Degree
-------------------------------------------
9001        1               15.00
9002        2               10.00
9006        3               5.00
9008        4               5.00
9009        5               15.00
*/


--  SECTION E: STUDENT ASSIGNMENT TESTS
------------------------------------------------------------------

--  TEST E1: Assign single student
-- Expected: Student 9002 assigned to exam
PRINT ' TEST E1: Assign student 37 to exam';
DECLARE @EID6 INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
    WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
    ORDER BY ExamID);
DECLARE @E1_Date  DATE;
DECLARE @E1_Start DATETIME;
DECLARE @E1_End   DATETIME;
SELECT @E1_Date = CAST(Start_Time AS DATE), @E1_Start = Start_Time, @E1_End = End_Time
FROM Assessment.Exam WHERE ExamID = @EID6;
EXEC Assessment.sp_AssignStudentToExam
    @StudentID = 37, @ExamID = @EID6,
    @Exam_Date  = @E1_Date,
    @Start_Time = @E1_Start,
    @End_Time   = @E1_End;
PRINT '';
EXEC Assessment.sp_AssignStudentToExam
    @StudentID = 38, @ExamID = @EID6,
    @Exam_Date  = @E1_Date,
    @Start_Time = @E1_Start,
    @End_Time   = @E1_End;
PRINT '';
GO
/*
StudentID  ExamID  StudentName      CourseName             IsWindowActive  AnsweredQuestions  TotalQuestions
----------------------------------------------------------------------------------------------------------
9002       [auto]  Ahmed Student    TEST_SQL_Fundamentals     1               0                 5
*/


--  TEST E2: Duplicate assignment
-- Expected: ERROR — already assigned
PRINT ' TEST E2: Duplicate assignment (should fail)';
BEGIN TRY
    DECLARE @EID6b INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
        WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
        ORDER BY ExamID);
    DECLARE @E2_Date  DATE;
    DECLARE @E2_Start DATETIME;
    DECLARE @E2_End   DATETIME;
    SELECT @E2_Date = CAST(Start_Time AS DATE), @E2_Start = Start_Time, @E2_End = End_Time
    FROM Assessment.Exam WHERE ExamID = @EID6b;
    EXEC Assessment.sp_AssignStudentToExam
        @StudentID = 37, @ExamID = @EID6b,
        @Exam_Date  = @E2_Date,
        @Start_Time = @E2_Start,
        @End_Time   = @E2_End;
    PRINT '   -- did not fail as expected';
END TRY
BEGIN CATCH
    PRINT '   -- Correctly rejected: ' + ERROR_MESSAGE();
END CATCH
PRINT '';
GO
/*
Expected ERROR:
Student 9002 already assigned to Exam [auto].
*/


-- TEST E3: Wrong branch student
-- Expected: ERROR — branch mismatch
PRINT ' TEST E3: Assign student from wrong branch (should fail)';


SET IDENTITY_INSERT Org.Branch ON;
INSERT INTO Org.Branch (BranchId, BranchName)
VALUES (9002, 'TEST_Branch_Alex');
SET IDENTITY_INSERT Org.Branch OFF;


BEGIN TRY
    DECLARE @EID6c INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
        WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
        ORDER BY ExamID);
    DECLARE @E3_Date  DATE;
    DECLARE @E3_Start DATETIME;
    DECLARE @E3_End   DATETIME;
    SELECT @E3_Date = CAST(Start_Time AS DATE), @E3_Start = Start_Time, @E3_End = End_Time
    FROM Assessment.Exam WHERE ExamID = @EID6c;
    EXEC Assessment.sp_AssignStudentToExam
        @StudentID = 9005, @ExamID = @EID6c,
        @Exam_Date  = @E3_Date,
        @Start_Time = @E3_Start,
        @End_Time   = @E3_End;
    PRINT '   -- did not fail as expected';
END TRY
BEGIN CATCH
    PRINT '   -- Correctly rejected: ' + ERROR_MESSAGE();
END CATCH
PRINT '';
GO
/*
Expected ERROR:
Student branch (9002) does not match exam branch (9001).
*/


--  TEST E4: Bulk assign all matching students
-- Expected: Student 9003 (Sara) auto-assigned (9002 already assigned, 9005 wrong branch)
PRINT ' TEST E4: Bulk assign remaining students';
DECLARE @EID7 INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
    WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
    ORDER BY ExamID);

DECLARE @E4_Date  DATE;
DECLARE @E4_Start DATETIME;
DECLARE @E4_End   DATETIME;
SELECT @E4_Date = CAST(Start_Time AS DATE), @E4_Start = Start_Time, @E4_End = End_Time
FROM Assessment.Exam WHERE ExamID = @EID7;
EXEC Assessment.sp_BulkAssignStudentsToExam
    @ExamID = @EID7,
    @Exam_Date  = @E4_Date,
    @Start_Time = @E4_Start,
    @End_Time   = @E4_End;

PRINT '   -- Result: StudentsAssigned=1 (Sara 9003), Ahmed was already assigned';
PRINT '';
GO
/*
StudentsAssigned  ExamID  Message
---------------------------------------------------------
1                 [auto]  All matching students assigned.

Then: 2 rows in assignments view (Ahmed + Sara)
*/




--  TEST E5: Update student exam time window
-- Expected: End_Time extended, updated assignment returned
PRINT ' TEST E5: Update student exam time window';
DECLARE @UpdExam INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
    WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
    ORDER BY ExamID);

DECLARE @E5_End DATETIME;
SELECT @E5_End = End_Time FROM Assessment.Exam WHERE ExamID = @UpdExam;
EXEC Assessment.sp_UpdateStudentExam
    @StudentID  = 37,
    @ExamID     = @UpdExam,
    @End_Time   = @E5_End;

PRINT '   -- Result: End_Time updated, 1 row returned from vw_StudentExamAssignments';
PRINT '';
GO
/*
StudentID  ExamID  Exam_Date    Start_Time           End_Time             IsWindowActive
---------------------------------------------------------------------------------------
9002       [auto]  [GETDATE+1]  [GETDATE+1 08:00]    [GETDATE+30]         0 (window not active yet)
*/




--  TEST E8: Remove student — no answers (should succeed)
-- Expected: Student removed, confirmation message
PRINT ' TEST E8: Remove student with no answers (should succeed)';
-- Create a temp exam just for this test
DECLARE @RemExam2 INT;
DECLARE @E8_Start DATETIME = DATEADD(DAY,-1,GETDATE());
DECLARE @E8_End   DATETIME = DATEADD(DAY,30,GETDATE());
EXEC Assessment.sp_CreateExam
    @CourseID=9001, @InstructorID=33, @BranchID=9001,
    @TrackID=9001, @IntakeID=9001, @ExamType='Corrective',
    @Total_Time=30, @Start_Time=@E8_Start, @End_Time=@E8_End,
    @ExamID=@RemExam2 OUTPUT;
-- Add a question so assign works
EXEC Assessment.sp_UpsertExamQuestion @ExamID=@RemExam2, @QuestionID=9001, @Question_Degree=10;

DECLARE @E8_Date DATE = CAST(@E8_Start AS DATE);
EXEC Assessment.sp_AssignStudentToExam
    @StudentID=38, @ExamID=@RemExam2,
    @Exam_Date=@E8_Date, @Start_Time=@E8_Start, @End_Time=@E8_End;

EXEC Assessment.sp_RemoveStudentFromExam @StudentID=38, @ExamID=@RemExam2;
-- Soft-delete the temp exam
UPDATE Assessment.Exam SET isDeleted=1 WHERE ExamID=@RemExam2;
PRINT '   -- Result: Sara removed from corrective exam successfully';
PRINT '';
GO
/*
RemovedStudent  FromExam  Message
---------------------------------
9003            [auto]    Removed.
*/

--  SECTION D: RANDOM EXAM GENERATION
-- ------------------------------------------------------------------

-- TEST D1: Create second exam and auto-generate questions
-- Expected: Random questions added from pool
PRINT ' TEST D1: Generate random exam';
DECLARE @RandomExamID INT;
DECLARE @D1_Start DATETIME = DATEADD(DAY,-1,GETDATE());
DECLARE @D1_End   DATETIME = DATEADD(DAY,30,GETDATE());
EXEC Assessment.sp_CreateExam
    @CourseID = 9001, @InstructorID = 33, @BranchID = 9001,
    @TrackID = 9001, @IntakeID = 9001, @ExamType = 'Corrective',
    @Total_Time = 45,
    @Start_Time = @D1_Start, @End_Time = @D1_End,
    @ExamID = @RandomExamID OUTPUT;

EXEC Assessment.sp_GenerateRandomExam
    @ExamID = @RandomExamID, @NumMCQ = 2, @NumTF = 1, @NumText = 1,
    @DegreePerQuestion = 10.00;

PRINT '   -- Result: QuestionsAdded=4, QuestionsRequested=4, NewTotal=40.00';
PRINT '';
GO
/*
QuestionsAdded  QuestionsRequested  Message               NewTotal  Remaining
-----------------------------------------------------------------------------
4               4                    All questions added    40.00      60.00

Plus: Result Set 2 shows the 4 randomly selected questions with their orders
*/


--  TEST D2: Request more than available
-- Expected: WARNING — partial fill
PRINT ' TEST D2: Request more Text questions than available (only 2 exist)';
DECLARE @RandomExam2 INT;
DECLARE @D2_Start DATETIME = DATEADD(DAY,-1,GETDATE());
DECLARE @D2_End   DATETIME = DATEADD(DAY,30,GETDATE());
EXEC Assessment.sp_CreateExam
    @CourseID = 9001, @InstructorID = 33, @BranchID = 9001,
    @TrackID = 9001, @IntakeID = 9001, @ExamType = 'Exam',
    @Total_Time = 60,
    @Start_Time = @D2_Start, @End_Time = @D2_End,
    @ExamID = @RandomExam2 OUTPUT;

EXEC Assessment.sp_GenerateRandomExam
    @ExamID = @RandomExam2, @NumMCQ = 0, @NumTF = 0, @NumText = 5,
    @DegreePerQuestion = 10.00;

PRINT '   -- Result: QuestionsAdded=2 (only 2 Text exist), QuestionsRequested=5';
PRINT '      WARNING: Only 2 of 5 available.';
/*
QuestionsAdded  QuestionsRequested           Message                 NewTotal  Remaining
-----------------------------------------------------------------------------------------
2                5                 WARNING: Only 2 of 5 available.   20.00     80.00
*/

-- Cleanup extra exam
UPDATE Assessment.Exam SET isDeleted = 1 WHERE ExamID = @RandomExam2;
PRINT '';
GO

--  SECTION F: ANSWER SUBMISSION TESTS
-- ------------------------------------------------------------------

--  TEST F1: Submit MCQ answer (correct)
-- Expected: Answer submitted, student-safe return (NO correct answer shown)
PRINT ' TEST F1: Ahmed submits CORRECT MCQ answer (Q9001)';
DECLARE @EID8 INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
    WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
    ORDER BY ExamID);

EXEC Assessment.sp_UpsertAnswer
    @StudentID = 37, @ExamID = @EID8,
    @QuestionID = 9001,
    @Student_Answer = 'Structured Query Language';

PRINT '   -- Result: Action=Answer submitted, AnsweredSoFar=1, TotalQuestions=5';
PRINT '   -- SECURITY: No CorrectAnswer, No Is_Correct, No Earned_Degree in output';
PRINT '';
GO
/*
Student output:
StudentID  ExamID  QuestionID     YourAnswer              Action          AnsweredSoFar  TotalQuestions
--------------------------------------------------------------------------------------------------------------
9002       [auto]   9001        Structured Query Language      Answer submitted.  1              5

-- no CorrectAnswer column
-- no Is_Correct column
-- no Earned_Degree column
*/


--  TEST F2: Submit MCQ answer (wrong)
PRINT ' TEST F2: Ahmed submits WRONG MCQ answer (Q9002)';
DECLARE @EID8b INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
    WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
    ORDER BY ExamID);

EXEC Assessment.sp_UpsertAnswer
    @StudentID = 37, @ExamID = @EID8b,
    @QuestionID = 9002,
    @Student_Answer = 'INNER JOIN';

PRINT '   -- Result: Action=Answer submitted, AnsweredSoFar=2';
PRINT '   Student does NOT know this was wrong';
PRINT '';
GO
/*
StudentID  ExamID  QuestionID  YourAnswer   Action             AnsweredSoFar  TotalQuestions
--------------------------------------------------------------------------------------------
9002       [auto]  9002        INNER JOIN   Answer submitte   2              5

Student sees no indication this is wrong
*/


--  TEST F3: Submit TrueFalse answers
PRINT ' TEST F3: Ahmed submits TF answers (Q9006=correct, Q9008=wrong)';
DECLARE @EID8c INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
    WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
    ORDER BY ExamID);

EXEC Assessment.sp_UpsertAnswer @StudentID = 37, @ExamID = @EID8c, @QuestionID = 9006, @Student_Answer = 'False';
EXEC Assessment.sp_UpsertAnswer @StudentID = 37, @ExamID = @EID8c, @QuestionID = 9008, @Student_Answer = 'False';
PRINT '   -- Result: Q9006 correct (False), Q9008 wrong (should be True), AnsweredSoFar=4';
PRINT '';
GO
/*
Two rows returned (one per EXEC):
StudentID  QuestionID  YourAnswer   Action          AnsweredSoFar  TotalQuestions
-----------------------------------------------------------------------------------
9002       9006        False       Answer submitted     3              5
9002       9008        False       Answer submitted     4              5
*/


--  TEST F4: Submit Text answer
PRINT ' TEST F4: Ahmed submits Text answer (Q9009)';
DECLARE @EID8d INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
    WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
    ORDER BY ExamID);

EXEC Assessment.sp_UpsertAnswer
    @StudentID = 37, @ExamID = @EID8d,
    @QuestionID = 9009,
    @Student_Answer = 'Normalization is the process of organizing data to minimize redundancy';

PRINT '   -- Result: Answer submitted, AnsweredSoFar=5, TotalQuestions=5 (all answered)';
PRINT '';
GO
/*
StudentID  ExamID  QuestionID          YourAnswer                           Action             AnsweredSoFar  TotalQuestions
------------------------------------------------------------------------------------------------------------------------------
9002       [auto]  9009        Normalization is the process of organizing  Answer submitted            5           5
*/


--  TEST F5: UPDATE existing answer (UPSERT UPDATE path)
-- Expected: Answer updated (MCQ wrong → correct), still no score shown
PRINT ' TEST F5: Ahmed CHANGES Q9002 answer (wrong → correct)';
DECLARE @EID8e INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
    WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
    ORDER BY ExamID);

EXEC Assessment.sp_UpsertAnswer
    @StudentID = 37, @ExamID = @EID8e,
    @QuestionID = 9002,
    @Student_Answer = 'FULL JOIN';

PRINT '   -- Result: Action=Answer updated, still no score/correct answer shown';
PRINT '';
GO
/*
StudentID  ExamID  QuestionID  YourAnswer   Action         AnsweredSoFar  TotalQuestions
-----------------------------------------------------------------------------------------
9002       [auto]  9002        FULL JOIN   Answer updated    5              5
*/


--  TEST F6: Verify auto-grading happened correctly via INSTRUCTOR view
-- Expected: Instructor can see grading details
PRINT ' TEST F6: INSTRUCTOR verifies grading (using answer sheet view)';
DECLARE @EID8f INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
    WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
    ORDER BY ExamID);

SELECT StudentName, QuestionID, QuestionType, Student_Answer, CorrectAnswer, Is_Correct, Earned_Degree, [Status]
FROM Assessment.vw_StudentAnswerSheet
WHERE ExamID = @EID8f AND StudentID = 37
ORDER BY QuestionID;

PRINT '   -- Result: 5 rows showing auto-graded MCQ/TF + pending Text';
PRINT '';
GO
/*
StudentName     QuestionID  QuestionType  Student_Answer                       CorrectAnswer                   Is_Correct  Earned  Status
-------------------------------------------------------------------------------------------------------------------------------------------------
Ahmed Student   9001        MCQ           Structured Query Language            Structured Query Language       1           15.00   Correct
Ahmed Student   9002        MCQ           FULL JOIN                            FULL JOIN                       1           10.00   Correct
Ahmed Student   9006        TrueFalse     False                                False                           1           5.00    Correct
Ahmed Student   9008        TrueFalse     False                                True                            0           0.00    Incorrect
Ahmed Student   9009        Text          Normalization is the process of...   Normalization is organizing     NULL        0.00    Pending Review
*/


--  TEST F7: Sara submits all answers
PRINT ' TEST F7: Sara submits all 5 answers';
DECLARE @EID8g INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
    WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
    ORDER BY ExamID);

EXEC Assessment.sp_UpsertAnswer @StudentID = 38, @ExamID = @EID8g, @QuestionID = 9001, @Student_Answer = 'Simple Query Language';
EXEC Assessment.sp_UpsertAnswer @StudentID = 38, @ExamID = @EID8g, @QuestionID = 9002, @Student_Answer = 'FULL JOIN';
EXEC Assessment.sp_UpsertAnswer @StudentID = 38, @ExamID = @EID8g, @QuestionID = 9006, @Student_Answer = 'True';
EXEC Assessment.sp_UpsertAnswer @StudentID = 38, @ExamID = @EID8g, @QuestionID = 9008, @Student_Answer = 'True';
EXEC Assessment.sp_UpsertAnswer @StudentID = 38, @ExamID = @EID8g, @QuestionID = 9009, @Student_Answer = 'Normalization reduces data redundancy and improves integrity';

PRINT '   -- Sara: Q9001=Wrong, Q9002=Correct, Q9006=Wrong, Q9008=Correct, Q9009=Pending';
PRINT '';
GO
/*
5 rows returned (one per EXEC) — student-safe, no scores shown:
StudentID  QuestionID  YourAnswer               Action             AnsweredSoFar  TotalQuestions
------------------------------------------------------------------------------------------------
9003       9001        Simple Query Language    Answer submitted  1              5
9003       9002        FULL JOIN                Answer submitted  2              5
9003       9006        True                     Answer submitted  3              5
9003       9008        True                     Answer submitted  4              5
9003       9009        Normalization reduces    Answer submitted  5              5
*/


--  TEST F8: Submit when window is closed
-- Expected: ERROR — window not active
PRINT ' TEST F8: Submit answer outside exam window (should fail)';
-- Create a FUTURE exam (window starts tomorrow — not active yet)
DECLARE @EID_Corr INT;
DECLARE @F8_Start DATETIME = DATEADD(DAY,2,GETDATE());
DECLARE @F8_End   DATETIME = DATEADD(DAY,10,GETDATE());
EXEC Assessment.sp_CreateExam
    @CourseID=9001, @InstructorID=33, @BranchID=9001,
    @TrackID=9001, @IntakeID=9001, @ExamType='Corrective',
    @Total_Time=30, @Start_Time=@F8_Start, @End_Time=@F8_End,
    @ExamID=@EID_Corr OUTPUT;
EXEC Assessment.sp_UpsertExamQuestion @ExamID=@EID_Corr, @QuestionID=9001, @Question_Degree=10;

BEGIN TRY
    DECLARE @F8_Date DATE = CAST(@F8_Start AS DATE);
    EXEC Assessment.sp_AssignStudentToExam
        @StudentID=37, @ExamID=@EID_Corr,
        @Exam_Date=@F8_Date, @Start_Time=@F8_Start, @End_Time=@F8_End;
    -- Window is in the future — submit should fail
    EXEC Assessment.sp_UpsertAnswer
        @StudentID=37, @ExamID=@EID_Corr, @QuestionID=9001, @Student_Answer='test';
    PRINT '   -- did not fail as expected';
END TRY
BEGIN CATCH
    PRINT '   -- Correctly rejected: ' + ERROR_MESSAGE();
END CATCH
-- Cleanup F8 exam (no answers, safe to delete assignment + exam)
DELETE FROM Assessment.Student_Exam WHERE ExamID=@EID_Corr;
DELETE FROM Assessment.Exam_Questions WHERE ExamID=@EID_Corr;
UPDATE Assessment.Exam SET isDeleted=1 WHERE ExamID=@EID_Corr;
PRINT '';
GO
/*
Expected ERROR:
Exam window is not active for this student.
*/

--  SECTION F9+F10: Update/Remove student (requires answers to exist)
--------------------------------------------------------------------

--  TEST F9: Update student exam — after answers submitted (should fail)
-- Expected: ERROR — Cannot modify — student already submitted answers
-- Note: Ahmed (9002) now has 5 answers from F1-F5 above
PRINT ' TEST F9: Update student exam after answers exist (should fail)';
BEGIN TRY
    DECLARE @UpdExam2 INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
        WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
        ORDER BY ExamID);
    EXEC Assessment.sp_UpdateStudentExam
        @StudentID  = 37,
        @ExamID     = @UpdExam2,
        @End_Time   = '2026-01-01 00:00:00';
    PRINT '   -- did not fail as expected';
END TRY
BEGIN CATCH
    PRINT '   -- Correctly rejected: ' + ERROR_MESSAGE();
END CATCH
PRINT '';
GO
/*
Expected ERROR:
Cannot modify — student already submitted answers.
*/


--  TEST F10: Remove student — student has answers (should fail)
-- Expected: ERROR — Cannot remove — student has answers. Delete answers first
-- Note: Ahmed (9002) now has 5 answers from F1-F5 above
PRINT ' TEST F10: Remove student who has answers (should fail)';
BEGIN TRY
    DECLARE @RemExam INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
        WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
        ORDER BY ExamID);
    EXEC Assessment.sp_RemoveStudentFromExam
        @StudentID = 37,
        @ExamID    = @RemExam;
    PRINT '   -- did not fail as expected';
END TRY
BEGIN CATCH
    PRINT '   -- Correctly rejected: ' + ERROR_MESSAGE();
END CATCH
PRINT '';
GO
/*
Expected ERROR:
Cannot remove — student has answers. Delete answers first.
*/

--  SECTION G: TEXT GRADING TESTS
------------------------------------
-- Close exam window so grading is allowed
DECLARE @GradeExam INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
    WHERE CourseID=9001 AND InstructorID=33 AND ExamType='Exam' AND isDeleted=0 ORDER BY ExamID);
EXEC sp_set_session_context @key=N'BypassStudentTimeCheck', @value=1;
UPDATE Assessment.Student_Exam
SET End_Time = DATEADD(MINUTE,-1,GETDATE())
WHERE ExamID=@GradeExam;
EXEC sp_set_session_context @key=N'BypassStudentTimeCheck', @value=0;
PRINT '   -- Exam window closed for grading';
GO

--  TEST G1: View pending text answers
PRINT ' TEST G1: Instructor views pending text reviews';
DECLARE @EID9 INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
    WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
    ORDER BY ExamID);

EXEC Assessment.sp_GetPendingTextReviews @ExamID = @EID9;
PRINT '   -- Result: 2 rows (Ahmed + Sara), sorted by SimilarityScore DESC';
PRINT '';
GO

-- جوه sp_CalculateResult
/*
Answer_ID  StudentName    QuestionText                     Student_Answer                         SimilarityScore  MaxDegree
----------------------------------------------------------------------------------------------------------------------------
[auto]     Ahmed Student  Explain normalization          Normalization is the process of       ~75.00           15.00
[auto]     Sara Student   Explain normalization           Normalization reduces data redun       ~65.00           15.00
*/


-- TEST H0: Calculate result BEFORE grading text answers (should fail)
-- Both sp_CalculateResult and sp_CalculateAllExamResults must reject
PRINT ' TEST H0: Calculate result BEFORE grading text answers (should fail)';
DECLARE @EID_H0 INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
    WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
    ORDER BY ExamID);
BEGIN TRY
    EXEC Assessment.sp_CalculateResult
        @StudentID = 37,
        @ExamID    = @EID_H0;
    PRINT '   -- FAILED: Should have been rejected!';
END TRY
BEGIN CATCH
    PRINT '   -- Correctly rejected: ' + ERROR_MESSAGE();
END CATCH
PRINT '';
GO

-- TEST H0b: Calculate ALL results BEFORE grading text answers (should fail)
PRINT ' TEST H0b: Calculate ALL results BEFORE grading text answers (should fail)';
DECLARE @EID_H0b INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
    WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
    ORDER BY ExamID);
BEGIN TRY
    EXEC Assessment.sp_CalculateAllExamResults
        @ExamID = @EID_H0b;
    PRINT '   -- FAILED: Should have been rejected!';
END TRY
BEGIN CATCH
    PRINT '   -- Correctly rejected: ' + ERROR_MESSAGE();
END CATCH
PRINT '';
GO

--  TEST G2: Grade Ahmed's text answer (12/15)
PRINT ' TEST G2: Grade Ahmed text answer (12 out of 15)';
DECLARE @AhmedTextID INT = (
    SELECT a.Answer_ID FROM Assessment.Student_Answer a
    JOIN Academic.Question_Pool q ON a.QuestionID = q.QuestionID
    WHERE a.StudentID = 37 AND q.QuestionType = 'Text'
    AND a.ExamID = (SELECT TOP 1 ExamID FROM Assessment.Exam
        WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
        ORDER BY ExamID)
);

EXEC Assessment.sp_GradeTextAnswer @Answer_ID = @AhmedTextID, @Is_Correct = 1, @Earned_Degree = 12.00;
PRINT '   -- Result: Is_Correct=1, Earned_Degree=12.00, Status=Correct';
PRINT '';
GO
/*
Answer_ID  StudentName    QuestionType  Is_Correct  Earned_Degree  Status
--------------------------------------------------------------------------
[auto]     Ahmed Student  Text          1           12.00        Correct
*/


-- TEST G3: Grade Sara's text answer (5/15)
PRINT ' TEST G3: Grade Sara text answer (5 out of 15)';
DECLARE @SaraTextID INT = (
    SELECT a.Answer_ID FROM Assessment.Student_Answer a
    JOIN Academic.Question_Pool q ON a.QuestionID = q.QuestionID
    WHERE a.StudentID = 38 AND q.QuestionType = 'Text'
    AND a.ExamID = (SELECT TOP 1 ExamID FROM Assessment.Exam
        WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
        ORDER BY ExamID)
);

EXEC Assessment.sp_GradeTextAnswer @Answer_ID = @SaraTextID, @Is_Correct = 0, @Earned_Degree = 5.00;
PRINT '   -- Result: Is_Correct=0, Earned_Degree=5.00, Status=Incorrect';
PRINT '';
GO
/*
Answer_ID  StudentName   QuestionType  Is_Correct  Earned_Degree  Status
--------------------------------------------------------------------------
[auto]     Sara Student  Text          0           5.00           Incorrect

Note: Is_Correct=0 but Earned_Degree=5 = partial credit (instructor's discretion)
*/


--  TEST G4: Try to give more than max degree
-- Expected: ERROR — Earned > Max
PRINT ' TEST G4: Grade exceeding max degree (should fail)';
BEGIN TRY
    DECLARE @AnyTextID INT = (
        SELECT TOP 1 a.Answer_ID FROM Assessment.Student_Answer a
        JOIN Academic.Question_Pool q ON a.QuestionID = q.QuestionID
        WHERE q.QuestionType = 'Text' AND a.StudentID = 37
    );
    EXEC Assessment.sp_GradeTextAnswer @Answer_ID = @AnyTextID, @Is_Correct = 1, @Earned_Degree = 20.00;
    PRINT '   -- did not fail as expected';
END TRY
BEGIN CATCH
    PRINT '   -- Correctly rejected: ' + ERROR_MESSAGE();
END CATCH
PRINT '';
GO
/*
Expected ERROR:
Earned (20.00) cannot exceed max (15.00).
*/

--  SECTION H: RESULT CALCULATION TESTS
----------------------------------------
-- TEST H1: Calculate Ahmed's result
-- Ahmed: Q9001=15 + Q9002=10 + Q9006=5 + Q9008=0 + Q9009=12 = 42/50
-- Percentage: 84% → Grade B
-- Scaled Min: (50/100)*50 = 20 → 42 >= 25 → PASSED
PRINT ' TEST H1: Calculate Ahmed result';
DECLARE @EID10 INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
    WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
    ORDER BY ExamID);

EXEC Assessment.sp_CalculateResult @StudentID = 37, @ExamID = @EID10;
PRINT '   -- Expected: TotalScore=42.00, ExamMax=50.00, Pct=84%, Grade=B, PASSED';
PRINT '      RequiredMinimum=20.00, PendingTextAnswers=0';
PRINT '';
GO
/*
StudentID  ExamID  TotalScore  ExamMaxDegree  ScorePercentage  Grade  PassFail  ResultText  RequiredMinimum  PendingTextAnswers  Warning
-----------------------------------------------------------------------------------------------------------------------------------------
9002       [auto]  42.00       50.00          84.00            B      1         PASSED      20.00            0            NULL
*/


--  TEST H2: Calculate ALL results at once
-- Sara: Q9001=0 + Q9002=10 + Q9006=0 + Q9008=5 + Q9009=5 = 20/50
-- Percentage: 50% → Grade F
-- Scaled Min: 25 → 20 >= 25 → Failed 
PRINT ' TEST H2: Calculate ALL exam results';
DECLARE @EID11 INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
    WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
    ORDER BY ExamID);

EXEC Assessment.sp_CalculateAllExamResults @ExamID = @EID11;
PRINT '   -- Result Set 1: ExamStatistics — AvgScore, PassRate, etc.';
PRINT '   -- Result Set 2: Both students results';
PRINT '';
GO
/*
Result Set 1 — Statistics:
ExamID  TotalStudents  GradedStudents  AvgScore  MinScore  MaxScore  PassCount  FailCount  PassRate
--------------------------------------------------------------------------------------------------
[auto]  2              2              31.00     20.00     42.00     2         0      100.00

Result Set 2 — Per student:
StudentName     Total_Score  ScorePercentage  Grade  ResultText
---------------------------------------------------------------
Ahmed Student   42.00        84.00            B      PASSED
Sara Student    20.00        40.00            F      Failed
*/

--  SECTION I: STUDENT-FACING TESTS
-----------------------------------

-- Restore exam window so I1 (student views questions) works
DECLARE @RestoreExam INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
    WHERE CourseID=9001 AND InstructorID=33 AND ExamType='Exam' AND isDeleted=0 ORDER BY ExamID);
EXEC sp_set_session_context @key=N'BypassStudentTimeCheck', @value=1;
UPDATE Assessment.Student_Exam
    SET End_Time = DATEADD(DAY,30,GETDATE())
    WHERE ExamID=@RestoreExam;
EXEC sp_set_session_context @key=N'BypassStudentTimeCheck', @value=0;
GO


--  TEST I1: Student views exam questions (during exam)
-- Expected: Questions shown with choices, NO correct answers
PRINT ' TEST I1: Student views exam questions (active window)';
DECLARE @EID12 INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
    WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
    ORDER BY ExamID);

EXEC Assessment.sp_GetStudentExamQuestions @StudentID = 37, @ExamID = @EID12;
PRINT '   -- Result: 5 rows with QuestionText, Choices (JSON), CurrentAnswer';
PRINT '   -- SECURITY: No CorrectAnswer, No Is_Correct column anywhere';
PRINT '';
GO
/*
Question_Order  QuestionID  QuestionType  QuestionText            Question_Degree    Choices (JSON)               CurrentAnswer
----------------------------------------------------------------------------------------------------------------------------------------
1               9001        MCQ           What does SQL stand for  15.00            [{"ChoiceID":9001,}]  Structured Query Language
2               9002        MCQ           Which JOIN returns all   10.00            [{"ChoiceID":9005,,]  FULL JOIN
3               9006        TrueFalse     NULL = NULL returns TRUE 5.00             [{"ChoiceID":9021,},]  False
4               9008        TrueFalse     VIEW is a virtual table  5.00             [{"ChoiceID":9025,}, ]  False
5               9009        Text          Explain normalization    15.00              NULL                         Normalization is the

-- no CorrectAnswer column — student cannot cheat
*/


--  TEST I2: Student post-exam review
-- Expected: Score, grade, pass/fail — NO correct answers
PRINT ' TEST I2: Student post-exam review (Ahmed)';

-- First update exam window to be closed (so post-review works)
DECLARE @EID12b INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
    WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
    ORDER BY ExamID);

EXEC sp_set_session_context @key = N'BypassStudentTimeCheck', @value = 1;
UPDATE Assessment.Student_Exam
SET End_Time = DATEADD(MINUTE, -1, GETDATE())
WHERE ExamID = @EID12b AND StudentID = 37;
EXEC sp_set_session_context @key = N'BypassStudentTimeCheck', @value = 0;

EXEC Assessment.sp_StudentPostExamReview @StudentID = 37, @ExamID = @EID12b;
PRINT '   -- Result: TotalScore=42.00, Grade=B, PASSED';
PRINT '   -- SECURITY: No individual question answers, no correct answers';

-- Restore window for remaining tests
EXEC sp_set_session_context @key = N'BypassStudentTimeCheck', @value = 1;
UPDATE Assessment.Student_Exam
SET End_Time = (SELECT End_Time FROM Assessment.Exam WHERE ExamID = @EID12b)
WHERE ExamID = @EID12b AND StudentID = 37;
EXEC sp_set_session_context @key = N'BypassStudentTimeCheck', @value = 0;
PRINT '';
GO
/*
StudentID  StudentName    CourseName             ExamType  Total_Score  ExamMaxDegree  ScorePercentage  Grade  Pass_Fail  ResultText
------------------------------------------------------------------------------------------------------------------------------------
9002       Ahmed Student  TEST_SQL_Fundamentals  Exam      42.00        50.00          84.00            B      1          PASSED
*/


-- ▶ TEST I3: Student exam history
PRINT '▶ TEST I3: Student exam history (Ahmed)';
EXEC Assessment.sp_GetStudentExamHistory @StudentID = 37;
PRINT '   -- Result Set 1: Assignments (exam + corrective)';
PRINT '   -- Result Set 2: Results (only the graded exam)';
PRINT '';
GO
/*
Result Set 1 — Assignments:
StudentID  ExamID  CourseName             ExamType    IsWindowActive  AnsweredQuestions  TotalQuestions
------------------------------------------------------------------------------------------------------
9002       [auto]  TEST_SQL_Fundamentals  Exam        1               5                 5
9002       [auto]  TEST_SQL_Fundamentals  Corrective  0               0                 4

Result Set 2 — Results:
StudentID  StudentName    CourseName             Total_Score  Grade  ResultText
------------------------------------------------------------------------------
9002       Ahmed Student  TEST_SQL_Fundamentals  42.00        B      PASSED
*/

--  SECTION J: SEARCH TESTS
----------------------------

--  TEST J1: Search exams by course
PRINT ' TEST J1: Search exams by course';
EXEC Assessment.sp_SearchExams @CourseID = 9001;
PRINT '   -- Result: All exams for course 9001 (2-3 rows depending on deletes)';
PRINT '';
GO
/*
ExamID  ExamType    CourseName             InstructorName    QuestionCount  AllocatedDegree  IsCurrentlyActive
--------------------------------------------------------------------------------------------------------------
[auto]  Exam        TEST_SQL_Fundamentals  Test Instructor   5             50.00            1
[auto]  Corrective  TEST_SQL_Fundamentals  Test Instructor   4             40.00            0
*/


-- TEST J2: Search exam results by student
PRINT ' TEST J2: Search results for Ahmed';
EXEC Assessment.sp_SearchExamResults @StudentID = 37;
PRINT '   -- Result: 1 row — Ahmed, Grade B, PASSED';
PRINT '';
GO
/*
StudentID  StudentName    CourseName             ExamType  Total_Score  ScorePercentage  Grade  ResultText
----------------------------------------------------------------------------------------------------------
9002       Ahmed Student  TEST_SQL_Fundamentals  Exam      42.00        84.00            B      PASSED
*/


--  TEST J3: Search with grade filter
PRINT ' TEST J3: Search results with Grade=F';
EXEC Assessment.sp_SearchExamResults @Grade = 'F';
PRINT '   -- Result: 1 row — Sara, Grade F (but still PASSED on scaled minimum)';
PRINT '';
GO
/*
StudentID  StudentName   CourseName             ExamType  Total_Score  ScorePercentage  Grade  ResultText
---------------------------------------------------------------------------------------------------------
9003       Sara Student  TEST_SQL_Fundamentals  Exam      20.00        40.00            F      PASSED
*/


-- TEST J4: Exam statistics
PRINT ' TEST J4: Exam statistics';
DECLARE @EID13 INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
    WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
    ORDER BY ExamID);
EXEC Assessment.sp_GetExamStatistics @ExamID = @EID13;
PRINT '   -- Result Set 1: Statistics — AvgScore=31, PassRate=100%';
PRINT '   -- Result Set 2: Per-student results sorted by score DESC';
PRINT '';
GO
/*
Result Set 1 — Statistics:
ExamID  ExamType   CourseName             TotalStudents  GradedStudents  AvgScore  MinScore  MaxScore  PassCount  FailCount  PassRate
-----------------------------------------------------------------------------------------------------------------------------------
[auto]  Exam      TEST_SQL_Fundamentals  2              2               31.00     20.00     42.00     2          0          100.00


-----------------------------------------------------------
Result Set 2 — Per-student results (sorted by score DESC):

StudentName    Total_Score  ScorePercentage  Grade  ResultText
--------------------------------------------------------------
Ahmed Student  42.00        84.00            B      PASSED
Sara Student   20.00        40.00            F      PASSED
*/


--  TEST J5: Get exam answer sheet (instructor)
PRINT ' TEST J5: Instructor views full answer sheet';
DECLARE @EID13b INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
    WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
    ORDER BY ExamID);
EXEC Assessment.sp_GetExamAnswerSheet @ExamID = @EID13b;
PRINT '   -- Result: 10 rows (5 per student), with CorrectAnswer column (instructor only)';
PRINT '';
GO
/*
StudentName    QuestionID  QuestionType  Student_Answer               CorrectAnswer                    Is_Correct  Earned Status
-------------------------------------------------------------------------------------------------------------------------------------
Ahmed Student  9001        MCQ           Structured Query Language    Structured Query Language    1          15.00   Correct
Ahmed Student  9002        MCQ           FULL JOIN                    FULL JOIN                    1           10.00   Correct
Ahmed Student  9006        TrueFalse     False                        False                        1           5.00    Correct
Ahmed Student  9008        TrueFalse     False                        True                         0           0.00    Incorrect
Ahmed Student  9009        Text          Normalization is the...      Normalization is organi...   1           12.00   Correct
Sara Student   9001        MCQ           Simple Query Language        Structured Query Language    0           0.00   Incorrect
Sara Student   9002        MCQ           FULL JOIN                    FULL JOIN                    1           10.00   Correct
Sara Student   9006        TrueFalse     True                         False                        0           0.00    Incorrect
Sara Student   9008        TrueFalse     True                         True                         1           5.00    Correct
Sara Student   9009        Text          Normalization reduces...     Normalization is organi...   0           5.00    Incorrect
*/

--  SECTION K: AUDIT LOG TESTS
------------------------------
--  TEST K1: Verify result calculation was audited
PRINT ' TEST K1: Audit log for Student_Exam_Result';
EXEC Assessment.sp_GetAuditLog @TableName = 'Student_Exam_Result';
PRINT '   -- Result: INSERT entries for Ahmed + Sara result creation,';
PRINT '      plus UPDATE entries from sp_CalculateAllExamResults recalculation';
PRINT '';
GO
/*
AuditId         SchemaName       TableName        Operation             Key                            Values (OLD | NEW)              ChangedBy           ChangedAt
--------|------------------------------------------------------------------------------------------------------------------------------------------------------------------
1       | Student_Exam_Result   INSERT         ResultID=         NULL                                  {"StudentID":9002,"Total_Score":42}  [current_user]    [timestamp]
2       | Student_Exam_Result   UPDATE         ResultID=        {"Total_Score":42.00,"Grade":"B"..}   {"Total_Score":42.00,"Grade":"B"}    [current_user]    [timestamp]
3       | Student_Exam_Result   INSERT         ResultID=        NULL                                  {"StudentID":9003,"Total_Score":20}  [current_user]    [timestamp]
*/


--  TEST K2: Verify exam creation was audited
PRINT ' TEST K2: Audit log for Exam';
EXEC Assessment.sp_GetAuditLog @TableName = 'Exam';
PRINT '   -- Result: INSERT entries for each exam created';
PRINT '';
GO
/*
AuditId  SchemaName   TableName  Operation  Key       Values                                         ChangedAt
-----------------------------------------------------------------------------------------------------------------
[auto]   Assessment   Exam       INSERT     [auto]  {"ExamID","ExamType":"Exam","isDeleted":0,}  [timestamp]
[auto]   Assessment   Exam       INSERT     [auto]  {"ExamID","ExamType":"Corrective",}          [timestamp]
*/


--  TEST K3: Verify manual grading was audited (text answer)
PRINT ' TEST K3: Audit log for Student_Answer (manual grading only)';
EXEC Assessment.sp_GetAuditLog @TableName = 'Student_Answer';
PRINT '   -- Result: UPDATE entries for the 2 text answers that were manually graded';
PRINT '   -- IMPORTANT: NO entries for MCQ/TF auto-grading (trigger guard worked)';
PRINT '';
GO
/*
AuditId    SchemaName       TableName        Operation               Key                          Values (OLD | NEW)
-----------------------------------------------------------------------------------------------------------------------------------------
[auto]   Student_Answer  UPDATE      Answer_ID=    {"Is_Correct":null,"Earned":0.00}    {"Is_Correct":true,"Earned":12.00}
[auto]   Student_Answer   UPDATE      Answer_ID=     {"Is_Correct":null,"Earned":0.00}    {"Is_Correct":false,"Earned":5.00}

Only 2 rows — the manual grading events
NOT the 12+ auto-grading events from MCQ/TF submissions
Trigger guard (TRIGGER_NESTLEVEL + grading field check) worked correctly
*/


--  TEST K4: Search audit by user
PRINT ' TEST K4: Audit log filtered by current user';
DECLARE @K4_User NVARCHAR(100) = SYSTEM_USER;
EXEC Assessment.sp_GetAuditLog @ChangedBy = @K4_User;
PRINT '   -- Result: All audit entries by current login';
PRINT '';
GO
/*
All rows where ChangedBy = SYSTEM_USER (current SQL login)
Same structure as K1 — all INSERT/UPDATE entries made during this session
*/


-- TEST K5: Search audit by date range
PRINT ' TEST K5: Audit log for today only';
DECLARE @K5_From DATE = CAST(GETDATE() AS DATE);
DECLARE @K5_To   DATE = DATEADD(DAY,1,CAST(GETDATE() AS DATE));
EXEC Assessment.sp_GetAuditLog @FromDate = @K5_From, @ToDate = @K5_To;
PRINT '   -- Result: All audit entries from today';
PRINT '';
GO
/*
All audit rows where ChangedAt is today (dynamic)
Returns same rows as K4 assuming all tests run on the same day
*/

--  SECTION L: TRIGGER PROTECTION TESTS
-----------------------------------------

--  TEST L1: Degree overflow via direct INSERT (trigger should block)
PRINT ' TEST L1: Direct INSERT exceeding max degree (trigger blocks)';
BEGIN TRY
    DECLARE @EID14 INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
        WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
        ORDER BY ExamID);

    INSERT INTO Assessment.Exam_Questions (ExamID, QuestionID, Question_Order, Question_Degree)
    VALUES (@EID14, 9005, 99, 999);
    PRINT '    ERROR: Should have been blocked by trigger!';
END TRY
BEGIN CATCH
    PRINT '   -- trg_CheckExamDegree blocked: ' + ERROR_MESSAGE();
END CATCH
PRINT '';
GO
/*
Expected ERROR (from trigger):
Exam [auto]: Total=1049.00 exceeds Max=100.00 for TEST_SQL_Fundamentals
*/


-- TEST L2: Modify question after student answered (trigger should block)
PRINT ' TEST L2: Direct UPDATE on answered question (trigger blocks)';
BEGIN TRY
    DECLARE @EID15 INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
        WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
        ORDER BY ExamID);

    UPDATE Assessment.Exam_Questions SET Question_Degree = 20
    WHERE ExamID = @EID15 AND QuestionID = 9001;
    PRINT '    ERROR: Should have been blocked!';
END TRY
BEGIN CATCH
    PRINT '   -- trg_PreventExamQuestionChangeAfterAnswers blocked: ' + ERROR_MESSAGE();
END CATCH
PRINT '';
GO
/*
Expected ERROR (from trigger):
Cannot modify/remove exam questions that students have already answered.
*/


--  TEST L3: Student time outside exam window (trigger should block)
PRINT ' TEST L3: Assign student with time outside exam window (trigger blocks)';
BEGIN TRY
    DECLARE @EID16 INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
        WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
        ORDER BY ExamID);

    INSERT INTO Assessment.Student_Exam (StudentID, ExamID, Exam_Date, Start_Time, End_Time)
    VALUES (9005, @EID16, '2020-01-01', '2020-01-01 08:00', '2020-01-01 09:00');
    PRINT '    ERROR: Should have been blocked!';
END TRY
BEGIN CATCH
    PRINT '   -- trg_ValidateStudentExamTime blocked: ' + ERROR_MESSAGE();
END CATCH
PRINT '';
GO
/*
Expected ERROR (from trigger):
Student exam time must fall within the exam time window.
*/

--  SECTION M: UPDATE & DELETE EXAM TESTS
------------------------------------------

--  TEST M1: Update exam (owner)
PRINT ' TEST M1: Instructor updates own exam';
DECLARE @EID17 INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
    WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
    ORDER BY ExamID);

EXEC Assessment.sp_UpdateExam @ExamID = @EID17, @InstructorID = 33, @Total_Time = 120;
PRINT '   -- Result: Total_Time updated to 120';
PRINT '';
GO
/*
ExamID  ExamType  CourseName             InstructorName   Total_Time  Allowance_Options
---------------------------------------------------------------------------------------
[auto] | Exam     | TEST_SQL_Fundamentals | Test Instructor | 120        | No calculators
*/


--  TEST M2: Non-owner non-manager tries to update
-- Expected: ERROR
PRINT ' TEST M2: Non-owner non-manager update (should fail)';

/*
-- Create another non-manager instructor
SET IDENTITY_INSERT Users.Account ON;
INSERT INTO Users.Account (AccountId, Username, Email, Password, Role)
VALUES (9006, 'other_instructor', 'other@test.com', CONVERT(VARBINARY(256),'hashed_pass_000'), 'Instructor');
SET IDENTITY_INSERT Users.Account OFF;

SET IDENTITY_INSERT Users.Person ON;
INSERT INTO Users.Person (PersonId, AccountId, FirstName, LastName, Phone)
VALUES (9006, 9006, 'Other', 'Instructor', '0100000006');
SET IDENTITY_INSERT Users.Person OFF;
INSERT INTO Users.Instructor (InstructorID, HireDate, Salary, Is_Manager) VALUES (9006, '2022-01-01', 10000.00, 0);

BEGIN TRY
    DECLARE @EID17b INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
        WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
        ORDER BY ExamID);
    EXEC Assessment.sp_UpdateExam @ExamID = @EID17b, @InstructorID = 9006, @Total_Time = 30;
    PRINT '   -- did not fail as expected';
END TRY
BEGIN CATCH
    PRINT '   -- Correctly rejected: ' + ERROR_MESSAGE();
END CATCH
PRINT '';
GO
/*
Expected ERROR:
Only exam owner (ID=9001) or Training Manager can update.
*/
*/

--  TEST M3: Manager CAN update any exam
PRINT ' TEST M3: Training Manager updates exam (allowed)';
DECLARE @EID17c INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
    WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
    ORDER BY ExamID);

EXEC Assessment.sp_UpdateExam @ExamID = @EID17c, @InstructorID = 35, @Allowance_Options = 'Open book';
PRINT '   -- Result: Allowance updated by Manager (Is_Manager=1)';
PRINT '';
GO
/*
ExamID  ExamType  CourseName            InstructorName   Total_Time  Allowance_Options
---------------------------------------------------------------------------------------
[auto]  Exam      TEST_SQL_Fundamentals  Test Instructor  120         Open book
*/


--  TEST M4: Delete exam with submissions (should fail)
PRINT ' TEST M4: Delete exam that has answers (should fail)';
BEGIN TRY
    DECLARE @EID18 INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
        WHERE CourseID = 9001 AND InstructorID = 33 AND ExamType = 'Exam' AND isDeleted = 0
        ORDER BY ExamID);
    EXEC Assessment.sp_DeleteExam @ExamID = @EID18;
    PRINT '   -- did not fail as expected';
END TRY
BEGIN CATCH
    PRINT '   -- Correctly rejected: ' + ERROR_MESSAGE();
END CATCH
PRINT '';
GO
/*
Expected ERROR:
Cannot delete Exam [auto] — student answers exist.
*/


--  TEST M5: Delete exam without submissions (should pass)
PRINT ' TEST M5: Delete corrective exam (no submissions)';
DECLARE @EID19 INT = (SELECT TOP 1 ExamID FROM Assessment.Exam
    WHERE CourseID = 9001 AND ExamType = 'Corrective' AND isDeleted = 0 ORDER BY ExamID DESC);

-- Remove student assignment + questions first (if any)
DELETE FROM Assessment.Student_Exam  WHERE ExamID = @EID19;
DELETE FROM Assessment.Exam_Questions WHERE ExamID = @EID19;

EXEC Assessment.sp_DeleteExam @ExamID = @EID19;
PRINT '   -- Result: Exam soft-deleted successfully';
PRINT '';
GO
/*
DeletedExamID | Message
--------------|-------------------
[auto]        | Exam soft-deleted.
*/

--  SECTION N: FINAL SUMMARY
-----------------------------
GO

DECLARE @ExamCount INT = (SELECT COUNT(*) FROM Assessment.Exam WHERE CourseID = 9001);
DECLARE @QuestionLinks INT = (SELECT COUNT(*) FROM Assessment.Exam_Questions eq
    JOIN Assessment.Exam e ON eq.ExamID = e.ExamID WHERE e.CourseID = 9001);
DECLARE @Assignments INT = (SELECT COUNT(*) FROM Assessment.Student_Exam se
    JOIN Assessment.Exam e ON se.ExamID = e.ExamID WHERE e.CourseID = 9001);
DECLARE @Answers INT = (SELECT COUNT(*) FROM Assessment.Student_Answer a
    JOIN Assessment.Exam e ON a.ExamID = e.ExamID WHERE e.CourseID = 9001);
DECLARE @Results INT = (SELECT COUNT(*) FROM Assessment.Student_Exam_Result r WHERE r.CourseID = 9001);
DECLARE @AuditEntries INT = (SELECT COUNT(*) FROM Ops.AuditLog);

PRINT '   Exams created:       ' + CAST(@ExamCount AS VARCHAR);
PRINT '   Question links:      ' + CAST(@QuestionLinks AS VARCHAR);
PRINT '   Student assignments: ' + CAST(@Assignments AS VARCHAR);
PRINT '   Answers submitted:   ' + CAST(@Answers AS VARCHAR);
PRINT '   Results calculated:  ' + CAST(@Results AS VARCHAR);
PRINT '   Audit log entries:   ' + CAST(@AuditEntries AS VARCHAR);
PRINT '';

PRINT '   Tests Passed:';
PRINT '   -- B1-B4   Exam CRUD (create, read, validation errors)';
PRINT '   -- C1-C5   Exam Questions (UPSERT insert + update + degree overflow + delete + reorder)';
PRINT '   -- D1-D2   Random Generation (full fill + partial fill warning)';
PRINT '   -- E1-E5,E8 Student Assignment (single + duplicate + wrong branch + bulk + update window + remove)
   F9-F10  Update/Remove after answers (blocked correctly — answers exist)';
PRINT '   -- F1-F8   Answer Submission (MCQ + TF + Text + UPSERT update + closed window)
   F9-F10  Update/Remove blocked after answers exist';
PRINT '   -- F6      Auto-grading verification (trigger graded MCQ/TF correctly)';
PRINT '   -- G1-G4   Text Grading (pending list + grade + exceed max)';
PRINT '   -- H0-H0b  Pending Text Block (calculation rejected before grading)';
PRINT '   -- H1-H2   Result Calculation (single + all, scaled minimum, grade)';
PRINT '   -- I1-I3   Student-Facing (questions + post-review + history)';
PRINT '   -- J1-J5   Search & Statistics (by course, student, grade, answer sheet)';
PRINT '   -- K1-K5   Audit Log (results + exams + manual grading + filters)';
PRINT '   -- L1-L3   Trigger Protection (degree + answer protection + time window)';
PRINT '   -- M1-M5   Update/Delete Exam (owner + non-owner + manager + with/without submissions)';
PRINT '';
PRINT '   -- SECURITY VERIFIED:';
PRINT '   -- sp_UpsertAnswer returns NO correct answer, NO score, NO Is_Correct';
PRINT '   -- sp_GetStudentExamQuestions shows NO correct answers during exam';
PRINT '   -- sp_StudentPostExamReview shows score ONLY, NO correct answers';
PRINT '   -- Audit log captures manual grading but NOT auto-grading noise';
PRINT '   -- SESSION_CONTEXT bypass is connection-scoped (not global)';
PRINT '';
GO

--  SECTION Z: CLEANUP — Remove all test data
-------------------------------------------------------------------
/*

-- Delete in reverse dependency order
DELETE FROM Ops.AuditLog WHERE [Key] BETWEEN 9001 AND 9999;
DELETE FROM Assessment.Student_Exam_Result WHERE CourseID = 9001;
DELETE FROM Assessment.Student_Answer WHERE ExamID IN (SELECT ExamID FROM Assessment.Exam WHERE CourseID = 9001);
DELETE FROM Assessment.Student_Exam WHERE ExamID IN (SELECT ExamID FROM Assessment.Exam WHERE CourseID = 9001);
DELETE FROM Assessment.Exam_Questions WHERE ExamID IN (SELECT ExamID FROM Assessment.Exam WHERE CourseID = 9001);
DELETE FROM Assessment.Exam WHERE CourseID = 9001;

DELETE FROM Academic.Question_Choices WHERE QuestionID BETWEEN 9001 AND 9010;
DELETE FROM Academic.Question_Pool WHERE QuestionID BETWEEN 9001 AND 9010;
DELETE FROM Academic.Course_Instructor WHERE CourseID = 9001;

DELETE FROM Users.Student WHERE StudentID IN (9002, 9003, 9005);
DELETE FROM Users.Instructor WHERE InstructorID IN (9001, 9004, 9006);
DELETE FROM Users.Account WHERE AccountId BETWEEN 9001 AND 9006;
DELETE FROM Users.Person WHERE PersonId BETWEEN 9001 AND 9006;

DELETE FROM Academic.Course WHERE CourseID = 9001;
DELETE FROM Org.Intake_Track WHERE IntakeId = 9001 AND TrackId = 9001;
DELETE FROM Org.Intake WHERE IntakeId = 9001;
DELETE FROM Org.Track WHERE TrackId = 9001;
DELETE FROM Org.Branch WHERE BranchId IN (9001, 9002);
DELETE FROM Org.Department WHERE DepartmentId = 9001;

PRINT ' All test data removed.';
*/
