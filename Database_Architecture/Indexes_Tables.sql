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



