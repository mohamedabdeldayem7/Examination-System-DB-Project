
-- implementing views for user profiles
-- Student profile view (no SSN)
CREATE OR ALTER VIEW Users.vw_StudentDetails
WITH SCHEMABINDING
AS
SELECT 
    P.SSN,
    P.FirstName + N' ' + P.LastName AS FullName,
    A.Username,
    A.Email,
    P.Phone,
    S.TrackID,
    S.IntakeID,
    S.BranchID,
    A.CreatedAt AS RegistrationDate
FROM Users.Account A
    INNER JOIN Users.Person P ON A.AccountId = P.AccountId
    INNER JOIN Users.Student S ON P.PersonId = S.StudentID
WHERE P.IsDeleted = 0 AND A.IsActive = 1;
GO

-- Instructor profile view
CREATE OR ALTER VIEW Users.vw_InstructorDetails
WITH SCHEMABINDING
AS
SELECT 
    P.SSN,
    P.FirstName + N' ' + P.LastName AS FullName,
    A.Username,
    A.Email,
    P.Phone,
    I.Salary,
    I.HireDate,
    I.Office,
    CASE WHEN I.Is_Manager = 1 THEN 'Yes' ELSE 'No' END AS IsManager,
    A.IsActive
FROM Users.Account A
    INNER JOIN Users.Person P ON A.AccountId = P.AccountId
    INNER JOIN Users.Instructor I ON P.PersonId = I.InstructorID
WHERE P.IsDeleted = 0 AND A.IsActive = 1;
GO


-- Users contact list view (includes both students and instructors, no SSN)
CREATE OR ALTER VIEW Users.vw_ActiveContactList
WITH SCHEMABINDING
AS
SELECT 
    P.SSN,
    P.FirstName + N' ' + P.LastName AS FullName,
    A.Email,
    P.Phone,
    A.Role,
    CASE 
        WHEN S.StudentID IS NOT NULL THEN 'Student'
        WHEN I.InstructorID IS NOT NULL THEN 'Instructor'
        ELSE A.Role 
    END AS UserCategory
FROM Users.Account A
    INNER JOIN Users.Person P ON A.AccountId = P.AccountId
    LEFT JOIN Users.Student S ON P.PersonId = S.StudentID
    LEFT JOIN Users.Instructor I ON P.PersonId = I.InstructorID
WHERE A.IsActive = 1 AND P.IsDeleted = 0;
GO