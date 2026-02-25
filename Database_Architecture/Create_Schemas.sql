USE [ExamSystemDB];
GO

CREATE SCHEMA Org AUTHORIZATION dbo;        -- Branch, Department, Track, Intake, Intake_Track
GO

CREATE SCHEMA Users AUTHORIZATION dbo;      -- Account, Person, Student, Instructor
GO

CREATE SCHEMA Academic AUTHORIZATION dbo;   -- Course, Course_Instructor, Question_Pool, Question_Choice
GO

CREATE SCHEMA Assessment AUTHORIZATION dbo; -- Exam, Exam_Question, Student_Exam, Student_Answer, Student_Exam_Result
GO

CREATE SCHEMA Ops AUTHORIZATION dbo;        -- AuditLog, Maintenance objects
GO

