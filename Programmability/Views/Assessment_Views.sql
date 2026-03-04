USE ExamSystemDB;
GO

-- V1
CREATE OR ALTER VIEW Assessment.vw_ExamDetails
AS
SELECT
    e.ExamID, e.ExamType, e.isDeleted AS ExamDeleted,
    YEAR(e.Start_Time) AS ExamYear,
    c.CourseID, c.CourseName, c.Max_Degree, c.Min_Degree,
    e.InstructorID,
    p.FirstName + ' ' + p.LastName AS InstructorName,
    b.BranchID, b.BranchName,
    t.TrackID, t.TrackName,
    i.IntakeID, i.IntakeYear, i.IntakeSemester,
    e.Start_Time, e.End_Time, e.Total_Time, e.Allowance_Options,
    Assessment.fn_GetExamTotalDegree(e.ExamID)     AS AllocatedDegree,
    Assessment.fn_GetExamRemainingDegree(e.ExamID)  AS RemainingDegree,
    (SELECT COUNT(*) FROM Assessment.Exam_Questions eq WHERE eq.ExamID = e.ExamID) AS QuestionCount,
    (SELECT COUNT(*) FROM Assessment.Student_Exam se WHERE se.ExamID = e.ExamID)   AS AssignedStudents,
    Assessment.fn_ExamHasSubmissions(e.ExamID) AS HasSubmissions,
    Assessment.fn_IsExamActive(e.ExamID)       AS IsCurrentlyActive
FROM Assessment.Exam e
JOIN Academic.Course c ON e.CourseID = c.CourseID
JOIN Users.Person p    ON e.InstructorID = p.PersonID
JOIN Org.Branch b      ON e.BranchID = b.BranchID
JOIN Org.Track t       ON e.TrackID = t.TrackID
JOIN Org.Intake i      ON e.IntakeID = i.IntakeID;
GO

-- V2 (INSTRUCTOR ONLY)
CREATE OR ALTER VIEW Assessment.vw_ExamQuestionsDetail
AS
SELECT
    eq.ExamID, eq.QuestionID, eq.Question_Order, eq.Question_Degree,
    q.QuestionType, q.QuestionText, q.Best_Accepted_Answer,
    Academic.fn_GetCorrectAnswer(eq.QuestionID) AS CorrectAnswer,
    c.CourseID, c.CourseName
FROM Assessment.Exam_Questions eq
JOIN Academic.Question_Pool q ON eq.QuestionID = q.QuestionID
JOIN Assessment.Exam e        ON eq.ExamID = e.ExamID
JOIN Academic.Course c        ON e.CourseID = c.CourseID;
GO

-- V3
CREATE OR ALTER VIEW Assessment.vw_StudentExamAssignments
AS
SELECT
    se.StudentID, se.ExamID, se.Exam_Date, se.Start_Time, se.End_Time,
    p.FirstName + ' ' + p.LastName AS StudentName,
    e.ExamType, c.CourseName,
    Assessment.fn_IsStudentExamActive(se.StudentID, se.ExamID) AS IsWindowActive,
    Assessment.fn_GetStudentAnswerCount(se.StudentID, se.ExamID) AS AnsweredQuestions,
    (SELECT COUNT(*) FROM Assessment.Exam_Questions eq WHERE eq.ExamID = se.ExamID) AS TotalQuestions
FROM Assessment.Student_Exam se
JOIN Users.Person p    ON se.StudentID = p.PersonID
JOIN Assessment.Exam e ON se.ExamID = e.ExamID
JOIN Academic.Course c ON e.CourseID = c.CourseID;
GO

-- V4 (INSTRUCTOR ONLY — has correct answers)
CREATE OR ALTER VIEW Assessment.vw_StudentAnswerSheet
AS
SELECT
    ans.Answer_ID, ans.StudentID,
    p.FirstName + ' ' + p.LastName AS StudentName,
    ans.ExamID, e.ExamType, c.CourseName,
    ans.QuestionID, q.QuestionType, q.QuestionText,
    ans.Student_Answer,
    Academic.fn_GetCorrectAnswer(ans.QuestionID) AS CorrectAnswer,
    ans.Is_Correct,
    eq.Question_Degree AS MaxQuestionDegree,
    ans.Earned_Degree,
    CASE
        WHEN q.QuestionType = 'Text' AND ans.Is_Correct IS NULL THEN 'Pending Review'
        WHEN ans.Is_Correct = 1 THEN 'Correct'
        WHEN ans.Is_Correct = 0 THEN 'Incorrect'
    END AS [Status]
FROM Assessment.Student_Answer ans
JOIN Assessment.Exam_Questions eq ON ans.ExamID = eq.ExamID AND ans.QuestionID = eq.QuestionID
JOIN Academic.Question_Pool q     ON ans.QuestionID = q.QuestionID
JOIN Assessment.Exam e            ON ans.ExamID = e.ExamID
JOIN Academic.Course c            ON e.CourseID = c.CourseID
JOIN Users.Person p               ON ans.StudentID = p.PersonID;
GO

-- V5 (INSTRUCTOR ONLY)
CREATE OR ALTER VIEW Assessment.vw_TextAnswersForReview
AS
SELECT
    ans.Answer_ID, ans.StudentID,
    ps.FirstName + ' ' + ps.LastName AS StudentName,
    ans.ExamID, ans.QuestionID,
    q.QuestionText, q.Best_Accepted_Answer,
    ans.Student_Answer,
    Assessment.fn_TextSimilarity(ans.Student_Answer, q.Best_Accepted_Answer) AS SimilarityScore,
    eq.Question_Degree AS MaxDegree, ans.Earned_Degree,
    q.InstructorID,
    pi.FirstName + ' ' + pi.LastName AS InstructorName
FROM Assessment.Student_Answer ans
JOIN Academic.Question_Pool q      ON ans.QuestionID = q.QuestionID
JOIN Assessment.Exam_Questions eq  ON ans.ExamID = eq.ExamID AND ans.QuestionID = eq.QuestionID
JOIN Users.Person ps               ON ans.StudentID = ps.PersonID
JOIN Users.Person pi               ON q.InstructorID = pi.PersonID
WHERE q.QuestionType = 'Text' AND ans.Is_Correct IS NULL;
GO

-- V6
CREATE OR ALTER VIEW Assessment.vw_StudentExamResults
AS
SELECT
    r.ResultID, r.StudentID,
    p.FirstName + ' ' + p.LastName AS StudentName,
    r.ExamID, e.ExamType,
    r.CourseID, c.CourseName,
    r.Total_Score,
    x.ExamMaxDegree,
    c.Max_Degree AS CourseMaxDegree, c.Min_Degree AS CourseMinDegree,
    CASE WHEN x.ExamMaxDegree > 0
         THEN CAST(r.Total_Score * 100.0 / x.ExamMaxDegree AS DECIMAL(5,2))
         ELSE 0 END AS ScorePercentage,
    r.Grade, r.Pass_Fail,
    CASE WHEN r.Pass_Fail = 1 THEN 'PASSED' ELSE 'FAILED' END AS ResultText
FROM Assessment.Student_Exam_Result r
JOIN Assessment.Exam e ON r.ExamID = e.ExamID
JOIN Academic.Course c ON r.CourseID = c.CourseID
JOIN Users.Person p    ON r.StudentID = p.PersonID
CROSS APPLY (
    SELECT Assessment.fn_GetExamTotalDegree(r.ExamID) AS ExamMaxDegree
) x;
GO

-- V7
CREATE OR ALTER VIEW Assessment.vw_ExamStatistics
AS
SELECT
    e.ExamID, e.ExamType, e.CourseID, c.CourseName,
    e.InstructorID,
    p.FirstName + ' ' + p.LastName AS InstructorName,
    COUNT(DISTINCT se.StudentID) AS TotalStudents,
    COUNT(DISTINCT r.StudentID)  AS GradedStudents,
    CAST(AVG(r.Total_Score) AS DECIMAL(5,2)) AS AvgScore,
    MIN(r.Total_Score) AS MinScore, MAX(r.Total_Score) AS MaxScore,
    SUM(CASE WHEN r.Pass_Fail = 1 THEN 1 ELSE 0 END) AS PassCount,
    SUM(CASE WHEN r.Pass_Fail = 0 THEN 1 ELSE 0 END) AS FailCount,
    CASE WHEN COUNT(DISTINCT r.StudentID) > 0
         THEN CAST(SUM(CASE WHEN r.Pass_Fail = 1 THEN 1 ELSE 0 END) * 100.0
              / COUNT(DISTINCT r.StudentID) AS DECIMAL(5,2))
         ELSE 0 END AS PassRate
FROM Assessment.Exam e
JOIN Academic.Course c ON e.CourseID = c.CourseID
JOIN Users.Person p    ON e.InstructorID = p.PersonID
LEFT JOIN Assessment.Student_Exam se       ON e.ExamID = se.ExamID
LEFT JOIN Assessment.Student_Exam_Result r ON e.ExamID = r.ExamID
WHERE e.isDeleted = 0
GROUP BY e.ExamID, e.ExamType, e.CourseID, c.CourseName,
         e.InstructorID, p.FirstName, p.LastName;
GO

-- V8
CREATE OR ALTER VIEW Assessment.vw_AuditLog
AS
SELECT AuditId, SchemaName, TableName, Operation, [Key],
       [Values], ChangedBy, ChangedAt
FROM Ops.AuditLog;
GO

