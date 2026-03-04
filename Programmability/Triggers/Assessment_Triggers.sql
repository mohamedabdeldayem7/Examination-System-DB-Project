USE ExamSystemDB;
GO

-- T1: Prevent exam degrees exceeding course max
---------------------------------------------------
CREATE OR ALTER TRIGGER Assessment.trg_CheckExamDegree
ON Assessment.Exam_Questions
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(CAST(SESSION_CONTEXT(N'BypassDegreeCheck') AS INT), 0) = 1 RETURN;

    DECLARE @ExamID INT, @Total DECIMAL(10,2), @MaxDeg DECIMAL(5,2), @CourseName NVARCHAR(100);
    
    DECLARE exam_cursor CURSOR FOR
    SELECT DISTINCT ExamID FROM inserted;
    
    OPEN exam_cursor;
    FETCH NEXT FROM exam_cursor INTO @ExamID;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @Total = SUM(CAST(Question_Degree AS DECIMAL(10,2)))
        FROM Assessment.Exam_Questions 
        WHERE ExamID = @ExamID;
        
        SELECT @MaxDeg = c.Max_Degree, @CourseName = c.CourseName
        FROM Assessment.Exam e
        JOIN Academic.Course c ON e.CourseID = c.CourseID
        WHERE e.ExamID = @ExamID;
        
        IF @Total > @MaxDeg
        BEGIN
            CLOSE exam_cursor;
            DEALLOCATE exam_cursor;
            DECLARE @Msg NVARCHAR(500);
            SET @Msg = 'Exam ' + CAST(@ExamID AS VARCHAR) + 
                       ': Total=' + CAST(@Total AS VARCHAR) + 
                       ' exceeds Max=' + CAST(@MaxDeg AS VARCHAR) + 
                       ' for ' + @CourseName;
            
            RAISERROR(@Msg, 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        FETCH NEXT FROM exam_cursor INTO @ExamID;
    END
    
    CLOSE exam_cursor;
    DEALLOCATE exam_cursor;
END;
GO

-- T2: Auto-grade on INSERT and UPDATE
--     Guard: skip re-grade if Student_Answer column was NOT changed
--    (protects sp_GradeTextAnswer from being overwritten)
------------------------------------------------------------------
CREATE OR ALTER TRIGGER Assessment.trg_AutoGradeAnswer
ON Assessment.Student_Answer
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    -- On UPDATE: only re-grade if student actually changed their answer text
    -- sp_GradeTextAnswer only touches Is_Correct + Earned_Degree - safely skipped
    IF EXISTS (SELECT 1 FROM deleted) AND NOT UPDATE(Student_Answer) RETURN;

    -- MCQ / TrueFalse: auto-grade
    UPDATE ans SET
        ans.Is_Correct = CASE
            WHEN LTRIM(RTRIM(LOWER(ans.Student_Answer))) =
                 LTRIM(RTRIM(LOWER(Academic.fn_GetCorrectAnswer(ans.QuestionID))))
            THEN 1 ELSE 0 END,
        ans.Earned_Degree = CASE
            WHEN LTRIM(RTRIM(LOWER(ans.Student_Answer))) =
                 LTRIM(RTRIM(LOWER(Academic.fn_GetCorrectAnswer(ans.QuestionID))))
            THEN eq.Question_Degree ELSE 0 END
    FROM Assessment.Student_Answer ans
    INNER JOIN inserted              i  ON ans.Answer_ID  = i.Answer_ID
    INNER JOIN Academic.Question_Pool q ON ans.QuestionID = q.QuestionID
    INNER JOIN Assessment.Exam_Questions eq
        ON ans.ExamID = eq.ExamID AND ans.QuestionID = eq.QuestionID
    WHERE q.QuestionType IN ('MCQ', 'TrueFalse');

    -- Text: reset to pending review
    UPDATE ans SET ans.Is_Correct = NULL, ans.Earned_Degree = 0
    FROM Assessment.Student_Answer ans
    INNER JOIN inserted              i  ON ans.Answer_ID  = i.Answer_ID
    INNER JOIN Academic.Question_Pool q ON ans.QuestionID = q.QuestionID
    WHERE q.QuestionType = 'Text';
END;
GO

-- T3: Student exam time must fall within the exam window
-----------------------------------------------------------------
CREATE OR ALTER TRIGGER Assessment.trg_ValidateStudentExamTime
ON Assessment.Student_Exam
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(CAST(SESSION_CONTEXT(N'BypassStudentTimeCheck') AS INT), 0) = 1 RETURN;

    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN Assessment.Exam e ON i.ExamID = e.ExamID
        WHERE i.Start_Time < e.Start_Time OR i.End_Time > e.End_Time
    )
    BEGIN
        RAISERROR('Student exam time must fall within the exam time window.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- T4: Block modifying exam questions after students have answered
-----------------------------------------------------------------
CREATE OR ALTER TRIGGER Assessment.trg_PreventExamQuestionChangeAfterAnswers
ON Assessment.Exam_Questions
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(CAST(SESSION_CONTEXT(N'BypassAnswerProtection') AS INT), 0) = 1 RETURN;

    IF EXISTS (
        SELECT 1 FROM deleted d
        JOIN Assessment.Student_Answer a ON d.ExamID = a.ExamID AND d.QuestionID = a.QuestionID
    )
    BEGIN
        RAISERROR('Cannot modify/remove exam questions that students have already answered.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- T5: AUDIT — Student_Exam_Result (scores, grades, pass/fail)
-----------------------------------------------------------------
CREATE OR ALTER TRIGGER Assessment.trg_Audit_StudentExamResult
ON Assessment.Student_Exam_Result
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Action VARCHAR(10) = CASE
        WHEN EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted) THEN 'UPDATE'
        WHEN EXISTS (SELECT 1 FROM inserted) THEN 'INSERT'
        ELSE 'DELETE' END;

    IF @Action = 'INSERT'
        INSERT INTO Ops.AuditLog (SchemaName, TableName, Operation, [Key], [Values])
        SELECT 'Assessment', 'Student_Exam_Result', 'INSERT', i.ResultID,
            (SELECT i2.ResultID, i2.StudentID, i2.ExamID, i2.CourseID,
                    i2.Total_Score, i2.Grade, i2.Pass_Fail
             FROM inserted i2 WHERE i2.ResultID = i.ResultID
             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)
        FROM inserted i;

    ELSE IF @Action = 'UPDATE'
        INSERT INTO Ops.AuditLog (SchemaName, TableName, Operation, [Key], [Values])
        SELECT 'Assessment', 'Student_Exam_Result', 'UPDATE', i.ResultID,
            CONCAT(
                'OLD:', (SELECT d2.ResultID, d2.StudentID, d2.ExamID, d2.CourseID,
                                d2.Total_Score, d2.Grade, d2.Pass_Fail
                         FROM deleted d2 WHERE d2.ResultID = i.ResultID
                         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES),
                ' | NEW:', (SELECT i2.ResultID, i2.StudentID, i2.ExamID, i2.CourseID,
                                   i2.Total_Score, i2.Grade, i2.Pass_Fail
                            FROM inserted i2 WHERE i2.ResultID = i.ResultID
                            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)
            )
        FROM inserted i;

    ELSE
        INSERT INTO Ops.AuditLog (SchemaName, TableName, Operation, [Key], [Values])
        SELECT 'Assessment', 'Student_Exam_Result', 'DELETE', d.ResultID,
            (SELECT d2.ResultID, d2.StudentID, d2.ExamID, d2.CourseID,
                    d2.Total_Score, d2.Grade, d2.Pass_Fail
             FROM deleted d2 WHERE d2.ResultID = d.ResultID
             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)
        FROM deleted d;
END;
GO

-- T6: AUDIT — Exam (creation, updates, soft-delete)
-----------------------------------------------------------------
CREATE OR ALTER TRIGGER Assessment.trg_Audit_Exam
ON Assessment.Exam
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Action VARCHAR(10) = CASE
        WHEN EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted) THEN 'UPDATE'
        WHEN EXISTS (SELECT 1 FROM inserted) THEN 'INSERT'
        ELSE 'DELETE' END;

    IF @Action = 'INSERT'
        INSERT INTO Ops.AuditLog (SchemaName, TableName, Operation, [Key], [Values])
        SELECT 'Assessment', 'Exam', 'INSERT', i.ExamID,
            (SELECT i2.ExamID, i2.CourseID, i2.InstructorID, i2.BranchID,
                    i2.TrackID, i2.IntakeID, i2.ExamType, i2.Total_Time,
                    i2.Start_Time, i2.End_Time, i2.Allowance_Options, i2.isDeleted
             FROM inserted i2 WHERE i2.ExamID = i.ExamID
             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)
        FROM inserted i;

    ELSE IF @Action = 'UPDATE'
        INSERT INTO Ops.AuditLog (SchemaName, TableName, Operation, [Key], [Values])
        SELECT 'Assessment', 'Exam', 'UPDATE', i.ExamID,
            CONCAT(
                'OLD:', (SELECT d2.ExamID, d2.CourseID, d2.InstructorID, d2.BranchID,
                                d2.TrackID, d2.IntakeID, d2.ExamType, d2.Total_Time,
                                d2.Start_Time, d2.End_Time, d2.Allowance_Options, d2.isDeleted
                         FROM deleted d2 WHERE d2.ExamID = i.ExamID
                         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES),
                ' | NEW:', (SELECT i2.ExamID, i2.CourseID, i2.InstructorID, i2.BranchID,
                                   i2.TrackID, i2.IntakeID, i2.ExamType, i2.Total_Time,
                                   i2.Start_Time, i2.End_Time, i2.Allowance_Options, i2.isDeleted
                            FROM inserted i2 WHERE i2.ExamID = i.ExamID
                            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)
            )
        FROM inserted i;

    ELSE
        INSERT INTO Ops.AuditLog (SchemaName, TableName, Operation, [Key], [Values])
        SELECT 'Assessment', 'Exam', 'DELETE', d.ExamID,
            (SELECT d2.ExamID, d2.CourseID, d2.InstructorID, d2.BranchID,
                    d2.TrackID, d2.IntakeID, d2.ExamType, d2.Total_Time,
                    d2.Start_Time, d2.End_Time, d2.Allowance_Options, d2.isDeleted
             FROM deleted d2 WHERE d2.ExamID = d.ExamID
             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)
        FROM deleted d;
END;
GO

-- T7: AUDIT — Student_Answer (manual grading + deletions ONLY)
--     Guard 1: TRIGGER_NESTLEVEL > 1 → skip (suppresses auto-grade noise)
--     Guard 2: Only log if Is_Correct or Earned_Degree actually changed
-----------------------------------------------------------------
CREATE OR ALTER TRIGGER Assessment.trg_Audit_StudentAnswer
ON Assessment.Student_Answer
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;

    DECLARE @Action VARCHAR(10) = CASE
        WHEN EXISTS (SELECT 1 FROM inserted) THEN 'UPDATE'
        ELSE 'DELETE' END;

    IF @Action = 'UPDATE'
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM inserted i JOIN deleted d ON i.Answer_ID = d.Answer_ID
            WHERE ISNULL(CAST(i.Is_Correct AS INT), -1) != ISNULL(CAST(d.Is_Correct AS INT), -1)
               OR i.Earned_Degree != d.Earned_Degree
        ) RETURN;

        INSERT INTO Ops.AuditLog (SchemaName, TableName, Operation, [Key], [Values])
        SELECT 'Assessment', 'Student_Answer', 'UPDATE', i.Answer_ID,
            CONCAT(
                'OLD:', (SELECT d2.Answer_ID, d2.StudentID, d2.ExamID, d2.QuestionID,
                                d2.Student_Answer, d2.Is_Correct, d2.Earned_Degree
                         FROM deleted d2 WHERE d2.Answer_ID = i.Answer_ID
                         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES),
                ' | NEW:', (SELECT i2.Answer_ID, i2.StudentID, i2.ExamID, i2.QuestionID,
                                   i2.Student_Answer, i2.Is_Correct, i2.Earned_Degree
                            FROM inserted i2 WHERE i2.Answer_ID = i.Answer_ID
                            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)
            )
        FROM inserted i JOIN deleted d ON i.Answer_ID = d.Answer_ID
        WHERE ISNULL(CAST(i.Is_Correct AS INT), -1) != ISNULL(CAST(d.Is_Correct AS INT), -1)
           OR i.Earned_Degree != d.Earned_Degree;
    END
    ELSE
        INSERT INTO Ops.AuditLog (SchemaName, TableName, Operation, [Key], [Values])
        SELECT 'Assessment', 'Student_Answer', 'DELETE', d.Answer_ID,
            (SELECT d2.Answer_ID, d2.StudentID, d2.ExamID, d2.QuestionID,
                    d2.Student_Answer, d2.Is_Correct, d2.Earned_Degree
             FROM deleted d2 WHERE d2.Answer_ID = d.Answer_ID
             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)
        FROM deleted d;
END;
GO
