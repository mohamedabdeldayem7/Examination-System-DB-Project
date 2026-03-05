USE ExamSystemDB;
GO 
-- VIEWS FOR [Academic].[Course]
CREATE OR ALTER VIEW V_Academic_Course 
AS 
SELECT [CourseID] , [CourseName] ,[Description]
FROM [Academic].[Course]
WHERE [IsDeleted] =0 ;
GO 
-- VIEWS FOR [Academic].[Course_Instructor]
CREATE OR ALTER VIEW V_Academic_Course_Instructor
AS 
SELECT  
[CourseName] , P.[FirstName] ,CI.[Year]
FROM [Academic].[Course_Instructor] AS CI
JOIN [Users].[Person]  AS P ON P.[PersonId] = CI.InstructorID
JOIN [Academic].[Course] AS C ON  C.[CourseID] = CI.CourseID

GO

--VIEWS FOR [Org].[Branch]
 CREATE OR ALTER VIEW V_Org_Branch
AS 
SELECT  [BranchId] , [BranchName]
from [Org].[Branch]
WHERE [IsDeleted] =0 ;

GO
--VIEWS FOR [Org].[Department]
 CREATE OR ALTER VIEW V_Org_Department
 AS 
 SELECT [DepartmentId] , [DepartmentName]
 FROM [Org].[Department]
 WHERE [IsDeleted] =0 ;

 GO 
 --VIEWS FOR [Org].[Intake]
 CREATE OR ALTER VIEW V_Org_Intake
 AS 
 SELECT [IntakeId] ,[IntakeYear] ,[IntakeSemester]
 FROM [Org].[Intake]
 WHERE [IsDeleted] =0 ;

 GO 
  --VIEWS FOR [Org].[Track]
 CREATE OR ALTER VIEW V_Org_Track
 AS 
 SELECT T.[TrackId] , D.[DepartmentName] ,T.[TrackName]
 FROM [Org].[Track] AS T
 JOIN [Org].[Department] AS D ON D.DepartmentId = T.DepartmentId
 WHERE T.[IsDeleted] =0 ;
 GO 
