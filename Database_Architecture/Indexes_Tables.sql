--INDEX ON [Academic].[Course]
CREATE NONCLUSTERED INDEX IX_Course_Name
ON Academic.Course (CourseName)
WHERE IsDeleted = 0;

--INDEXES ON [Academic].[Course_Instructor]
CREATE NONCLUSTERED INDEX IX_CourseInstructor_Instructor
ON [Academic].[Course_Instructor] ([InstructorID],[Year]);

CREATE NONCLUSTERED INDEX IX_CourseInstructor_Course
ON [Academic].[Course_Instructor] ([CourseID]);

--INDEX ON [Academic].[Question_Choices]
CREATE NONCLUSTERED INDEX IX_Question_Choices_QuestionID
ON [Academic].[Question_Choices] ([QuestionID]);


--INDEXES ON [Academic].[Question_Pool]
CREATE NONCLUSTERED INDEX IX_Question_CourseID_Type
ON [Academic].[Question_Pool] ([CourseID],[QuestionType]);


CREATE NONCLUSTERED INDEX IX_Question_Pool_InstructorID
ON [Academic].[Question_Pool] ([InstructorID]);

--INDEX ON [Org].[Branch]
CREATE NONCLUSTERED INDEX IX_Branch_Name
ON [Org].[Branch]([BranchName]);

--INDEX ON [Org].[Department]
CREATE NONCLUSTERED INDEX IX_Department_Name
ON [Org].[Branch]([BranchName]);

--INDEX ON [Org].[Intake]
CREATE NONCLUSTERED INDEX IX_Intake_Year
ON [Org].[Intake]([IntakeYear]);

--INDEX ON [Org].[Track]
CREATE NONCLUSTERED INDEX IX_Track_DepartmentId
ON [Org].[Track]([DepartmentId]);

CREATE NONCLUSTERED INDEX IX_Track_Name
ON [Org].[Track]([TrackName]);

-- Users
-- Account indexes
CREATE NONCLUSTERED INDEX IX_Account_Username ON Users.Account(Username) ON FG_Indexes;
CREATE NONCLUSTERED INDEX IX_Account_Email ON Users.Account(Email) ON FG_Indexes;

-- Person indexes
CREATE NONCLUSTERED INDEX IX_Person_AccountId ON Users.Person(AccountId) ON FG_Indexes;
CREATE NONCLUSTERED INDEX IX_Person_LastName_FirstName ON Users.Person(LastName, FirstName) ON FG_Indexes;

-- Student indexes
CREATE NONCLUSTERED INDEX IX_Student_Track ON Users.Student([TrackID]) ON FG_Indexes;
CREATE NONCLUSTERED INDEX IX_Student_Intake ON Users.Student([IntakeID]) ON FG_Indexes;

-- Instructor indexes
CREATE NONCLUSTERED INDEX IX_Instructor_HireDate ON Users.Instructor([HireDate]) ON FG_Indexes;


-- Assessment Indexes
    CREATE NONCLUSTERED INDEX IX_Student_Answer_StudentExam
    ON Assessment.Student_Answer (StudentID, ExamID)
    INCLUDE (QuestionID, Is_Correct, Earned_Degree);
GO

-- I2: Exam_Questions —
    CREATE NONCLUSTERED INDEX IX_Exam_Questions_ExamID
    ON Assessment.Exam_Questions (ExamID)
    INCLUDE (QuestionID, Question_Order, Question_Degree);
GO

-- I3: Student_Exam — assignment lookups + bulk assign
    CREATE NONCLUSTERED INDEX IX_Student_Exam_ExamID
    ON Assessment.Student_Exam (ExamID)
    INCLUDE (StudentID, Start_Time, End_Time);
GO

-- I4: Question_Pool — random exam generation + grading
    CREATE NONCLUSTERED INDEX IX_Question_Pool_Course
    ON Academic.Question_Pool (CourseID, QuestionType, isDeleted)
    INCLUDE (QuestionID, Best_Accepted_Answer);
GO

-- I5: Student_Exam_Result — result lookup + statistics
    CREATE NONCLUSTERED INDEX IX_Student_Exam_Result_StudentExam
    ON Assessment.Student_Exam_Result (StudentID, ExamID)
    INCLUDE (Total_Score, Grade, Pass_Fail, CourseID);
GO

-- I6: Exam — search by course/instructor/branch (sp_SearchExams)
    CREATE NONCLUSTERED INDEX IX_Exam_Course_Instructor
    ON Assessment.Exam (CourseID, InstructorID, isDeleted)
    INCLUDE (ExamID, ExamType, Start_Time, End_Time);
GO




