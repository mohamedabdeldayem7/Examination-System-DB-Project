USE [ExamSystemDB] ;
GO 
-- Drop Tables First 
DROP TABLE IF EXISTS Academic.Course_Instructor ;
GO
DROP TABLE IF EXISTS Academic.Course;
GO
DROP TABLE IF EXISTS Academic.Course_Instructor;
GO

DROP TABLE IF EXISTS Academic.Question_Choices;
GO

DROP TABLE IF EXISTS Academic.Question_Pool;
GO

DROP TABLE IF EXISTS Academic.Course;
GO

--CREATE Academic.Course
CREATE TABLE Academic.Course
(	
	CourseID int IDENTITY(1,1) PRIMARY KEY ,
	CourseName varchar(100) NOT NULL ,
	Description nvarchar(500) NULL ,
	Max_Degree decimal(5,2) NOT NULL ,
	Min_Degree decimal(5,2) NOT NULL ,
	IsDeleted BIT NOT NULL DEFAULT 0

)ON FG_MasterData;
-- CREATE Academic.Course_Instructor 
CREATE TABLE Academic.Course_Instructor 
(
	InstructorID INT ,
	CourseID INT ,
	Year INT ,
	CONSTRAINT PK_Course_Instructor PRIMARY KEY (InstructorID,CourseID,Year),
	CONSTRAINT FK_CI_Instructor FOREIGN KEY (InstructorID) REFERENCES [Users].[Instructor]([InstructorID]) ON DELETE CASCADE ,
	CONSTRAINT FK_CI_Course FOREIGN KEY (CourseID) REFERENCES Academic.Course(CourseID)  ON DELETE CASCADE



)ON FG_MasterData;

CREATE TABLE Academic.Question_Pool (
    QuestionID           INT IDENTITY(1,1),
    CourseID             INT           NOT NULL,
    InstructorID         INT           NOT NULL,
    QuestionType         VARCHAR(20)   NOT NULL,
    QuestionText         NVARCHAR(MAX) NOT NULL,
    Best_Accepted_Answer NVARCHAR(MAX) NULL,
    isDeleted            BIT           NOT NULL DEFAULT 0,
    CONSTRAINT PK_Questions PRIMARY KEY (QuestionID) ON FG_MasterData,
    CONSTRAINT FK_Questions_Course FOREIGN KEY (CourseID)
        REFERENCES Academic.Course(CourseID),
    CONSTRAINT FK_Questions_Instructor FOREIGN KEY (InstructorID)
        REFERENCES Users.Instructor(InstructorID),
    CONSTRAINT CK_QuestionType CHECK (QuestionType IN ('MCQ','TrueFalse','Text'))
) ON FG_MasterData;


CREATE TABLE Academic.Question_Choices (
    ChoiceID        INT IDENTITY(1,1),
    QuestionID      INT           NOT NULL,
    ChoiceText      NVARCHAR(MAX) NOT NULL,
    IsCorrectChoice BIT           NOT NULL DEFAULT 0,
    isDeleted       BIT           NOT NULL DEFAULT 0,
    CONSTRAINT PK_Choices PRIMARY KEY (ChoiceID) ON FG_MasterData,
    CONSTRAINT FK_Choices_Questions FOREIGN KEY (QuestionID)
        REFERENCES Academic.Question_Pool(QuestionID)
) ON FG_MasterData;


ALTER TABLE Academic.Course_Instructor
ADD IsDeleted BIT NOT NULL DEFAULT 0;