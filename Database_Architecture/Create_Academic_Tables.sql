USE [ExamSystemDB] ;
GO 
-- Drop Tables First 
DROP TABLE IF EXISTS Academic.Course_Instructor ;
GO
DROP TABLE IF EXISTS Academic.Course;
GO

--CREATE Academic.Course
CREATE TABLE Academic.Course
(	
	CourseID int PRIMARY KEY ,
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
