USE ExamSystemDB;
GO


-------------------------------------------------------------
IF OBJECT_ID('Assessment.sp_SubmitAnswer',      'P') IS NOT NULL DROP PROCEDURE Assessment.sp_SubmitAnswer;
IF OBJECT_ID('Assessment.sp_UpdateAnswer',       'P') IS NOT NULL DROP PROCEDURE Assessment.sp_UpdateAnswer;
IF OBJECT_ID('Assessment.sp_AddExamQuestion',    'P') IS NOT NULL DROP PROCEDURE Assessment.sp_AddExamQuestion;
IF OBJECT_ID('Assessment.sp_UpdateExamQuestion', 'P') IS NOT NULL DROP PROCEDURE Assessment.sp_UpdateExamQuestion;
GO

--  EXAM CRUD  [1-4]
----------------------------------------------------------------

-- [1] CREATE EXAM
CREATE OR ALTER PROCEDURE Assessment.sp_CreateExam
    @CourseID          INT,
    @InstructorID      INT,
    @BranchID          INT,
    @TrackID           INT,
    @IntakeID          INT,
    @ExamType          VARCHAR(20),
    @Total_Time        INT,
    @Start_Time        DATETIME,
    @End_Time          DATETIME,
    @Allowance_Options NVARCHAR(200) = NULL,
    @ExamID            INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @ExamType NOT IN ('Exam', 'Corrective')
            RAISERROR('ExamType must be Exam or Corrective.', 16, 1);
        IF @Total_Time <= 0
            RAISERROR('Total_Time must be greater than 0.', 16, 1);
        IF NOT EXISTS (SELECT 1 FROM Academic.Course  WHERE CourseID  = @CourseID  AND isDeleted = 0)
            RAISERROR('Course %d not found or deleted.', 16, 1, @CourseID);
        IF NOT EXISTS (SELECT 1 FROM Org.Branch        WHERE BranchID  = @BranchID  AND isDeleted = 0)
            RAISERROR('Branch %d not found or deleted.', 16, 1, @BranchID);
        IF NOT EXISTS (
            SELECT 1 FROM Academic.Course_Instructor
            WHERE InstructorID = @InstructorID AND CourseID = @CourseID AND IsDeleted = 0)
            RAISERROR('Instructor %d not assigned to Course %d.', 16, 1, @InstructorID, @CourseID);
        IF NOT EXISTS (SELECT 1 FROM Org.Intake_Track WHERE IntakeID = @IntakeID AND TrackID = @TrackID)
            RAISERROR('Track %d not offered in Intake %d.', 16, 1, @TrackID, @IntakeID);
        IF @End_Time <= @Start_Time
            RAISERROR('End_Time must be after Start_Time.', 16, 1);

        INSERT INTO Assessment.Exam
            (CourseID, InstructorID, BranchID, TrackID, IntakeID,
             ExamType, Total_Time, Start_Time, End_Time, Allowance_Options)
        VALUES
            (@CourseID, @InstructorID, @BranchID, @TrackID, @IntakeID,
             @ExamType, @Total_Time, @Start_Time, @End_Time, @Allowance_Options);

        SET @ExamID = SCOPE_IDENTITY();
        COMMIT TRANSACTION;
        SELECT * FROM Assessment.vw_ExamDetails WHERE ExamID = @ExamID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- [2] READ EXAM
CREATE OR ALTER PROCEDURE Assessment.sp_ReadExam
    @ExamID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM Assessment.vw_ExamDetails            WHERE ExamID = @ExamID;
    SELECT * FROM Assessment.vw_ExamQuestionsDetail    WHERE ExamID = @ExamID ORDER BY Question_Order;
    SELECT * FROM Assessment.vw_StudentExamAssignments WHERE ExamID = @ExamID;
END;
GO

-- [3] UPDATE EXAM
CREATE OR ALTER PROCEDURE Assessment.sp_UpdateExam
    @ExamID            INT,
    @InstructorID      INT           = NULL,
    @CourseID          INT           = NULL,
    @BranchID          INT           = NULL,
    @TrackID           INT           = NULL,
    @IntakeID          INT           = NULL,
    @ExamType          VARCHAR(20)   = NULL,
    @Total_Time        INT           = NULL,
    @Start_Time        DATETIME      = NULL,
    @End_Time          DATETIME      = NULL,
    @Allowance_Options NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Assessment.Exam WHERE ExamID = @ExamID AND isDeleted = 0)
            RAISERROR('Exam %d not found or deleted.', 16, 1, @ExamID);

        -- Block CourseID change after creation
        IF @CourseID IS NOT NULL
        BEGIN
            DECLARE @CurrentCourseID INT;
            SELECT @CurrentCourseID = CourseID FROM Assessment.Exam WHERE ExamID = @ExamID;
            IF @CourseID != @CurrentCourseID
                RAISERROR('Cannot change CourseID after creation. Create a new exam.', 16, 1);
        END

        -- Ownership check
        DECLARE @OwnerID INT;
        SELECT @OwnerID = InstructorID FROM Assessment.Exam WHERE ExamID = @ExamID;
        IF @InstructorID IS NOT NULL AND @InstructorID != @OwnerID
        BEGIN
            DECLARE @IsManager BIT = 0;
            SELECT @IsManager = Is_Manager FROM Users.Instructor WHERE InstructorID = @InstructorID;
            IF @IsManager = 0
                RAISERROR('Only exam owner (ID=%d) or Training Manager can update.', 16, 1, @OwnerID);
        END

        IF @ExamType IS NOT NULL AND @ExamType NOT IN ('Exam', 'Corrective')
            RAISERROR('ExamType must be Exam or Corrective.', 16, 1);
        IF @Total_Time IS NOT NULL AND @Total_Time <= 0
            RAISERROR('Total_Time must be greater than 0.', 16, 1);

        DECLARE @FinalStart DATETIME, @FinalEnd DATETIME;
        SELECT @FinalStart = ISNULL(@Start_Time, Start_Time),
               @FinalEnd   = ISNULL(@End_Time,   End_Time)
        FROM Assessment.Exam WHERE ExamID = @ExamID;
        IF @FinalEnd <= @FinalStart
            RAISERROR('End_Time must be after Start_Time.', 16, 1);

        IF @TrackID IS NOT NULL OR @IntakeID IS NOT NULL
        BEGIN
            DECLARE @CheckTrack INT, @CheckIntake INT;
            SELECT @CheckTrack  = ISNULL(@TrackID,  TrackID),
                   @CheckIntake = ISNULL(@IntakeID, IntakeID)
            FROM Assessment.Exam WHERE ExamID = @ExamID;
            IF NOT EXISTS (SELECT 1 FROM Org.Intake_Track WHERE IntakeID = @CheckIntake AND TrackID = @CheckTrack)
                RAISERROR('Track %d not offered in Intake %d.', 16, 1, @CheckTrack, @CheckIntake);
        END

        UPDATE Assessment.Exam SET
            BranchID          = ISNULL(@BranchID,         BranchID),
            TrackID           = ISNULL(@TrackID,           TrackID),
            IntakeID          = ISNULL(@IntakeID,          IntakeID),
            ExamType          = ISNULL(@ExamType,          ExamType),
            Total_Time        = ISNULL(@Total_Time,        Total_Time),
            Start_Time        = ISNULL(@Start_Time,        Start_Time),
            End_Time          = ISNULL(@End_Time,          End_Time),
            Allowance_Options = ISNULL(@Allowance_Options, Allowance_Options)
        WHERE ExamID = @ExamID;

        COMMIT TRANSACTION;
        SELECT * FROM Assessment.vw_ExamDetails WHERE ExamID = @ExamID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- [4] DELETE EXAM
-- FIX: Also cleans up Student_Exam assignments that have no answers
--      to prevent orphan records after soft-delete
CREATE OR ALTER PROCEDURE Assessment.sp_DeleteExam
    @ExamID INT, @InstructorID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Assessment.Exam WHERE ExamID = @ExamID AND isDeleted = 0)
            RAISERROR('Exam %d not found or already deleted.', 16, 1, @ExamID);

        DECLARE @OwnerID INT;
        SELECT @OwnerID = InstructorID FROM Assessment.Exam WHERE ExamID = @ExamID;
        IF @InstructorID IS NOT NULL AND @InstructorID != @OwnerID
        BEGIN
            DECLARE @IsManager BIT = 0;
            SELECT @IsManager = Is_Manager FROM Users.Instructor WHERE InstructorID = @InstructorID;
            IF @IsManager = 0
                RAISERROR('Only exam owner (ID=%d) or Training Manager can delete.', 16, 1, @OwnerID);
        END

        IF Assessment.fn_ExamHasSubmissions(@ExamID) = 1
            RAISERROR('Cannot delete Exam %d — student answers exist.', 16, 1, @ExamID);

        -- FIX: Remove unstarted student assignments before soft-delete
        -- to prevent orphan Student_Exam records pointing to a deleted exam
        DELETE FROM Assessment.Student_Exam
        WHERE ExamID = @ExamID
          AND StudentID NOT IN (
              SELECT DISTINCT StudentID FROM Assessment.Student_Answer WHERE ExamID = @ExamID
          );

        UPDATE Assessment.Exam SET isDeleted = 1 WHERE ExamID = @ExamID;

        COMMIT TRANSACTION;
        SELECT @ExamID AS DeletedExamID, 'Exam soft-deleted.' AS [Message];
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

--  EXAM QUESTIONS  [5-6]
----------------------------------------------------------------

-- [5] UPSERT EXAM QUESTION
CREATE OR ALTER PROCEDURE Assessment.sp_UpsertExamQuestion
    @ExamID          INT,
    @QuestionID      INT,
    @Question_Degree DECIMAL(5,2),
    @Question_Order  INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @CourseID INT, @MaxDeg DECIMAL(5,2);
        SELECT @CourseID = CourseID FROM Assessment.Exam WHERE ExamID = @ExamID AND isDeleted = 0;

        IF @CourseID IS NULL
            RAISERROR('Exam %d not found or deleted.', 16, 1, @ExamID);

        SELECT @MaxDeg = Max_Degree FROM Academic.Course WHERE CourseID = @CourseID;

        IF NOT EXISTS (
            SELECT 1 FROM Academic.Question_Pool
            WHERE QuestionID = @QuestionID AND CourseID = @CourseID AND isDeleted = 0)
            RAISERROR('Question %d does not belong to Course %d or is deleted.', 16, 1, @QuestionID, @CourseID);

        IF @Question_Degree <= 0
            RAISERROR('Question_Degree must be greater than 0.', 16, 1);

        DECLARE @Exists BIT = 0, @OldDeg DECIMAL(5,2) = 0, @OldOrder INT = NULL;
        IF EXISTS (SELECT 1 FROM Assessment.Exam_Questions WHERE ExamID = @ExamID AND QuestionID = @QuestionID)
        BEGIN
            SET @Exists = 1;
            SELECT @OldDeg = Question_Degree, @OldOrder = Question_Order
            FROM Assessment.Exam_Questions WHERE ExamID = @ExamID AND QuestionID = @QuestionID;
        END

        DECLARE @CurrentTotal DECIMAL(5,2) = Assessment.fn_GetExamTotalDegree(@ExamID);
        DECLARE @EffectiveTotal DECIMAL(5,2) = CASE
            WHEN @Exists = 1 THEN @CurrentTotal - @OldDeg + @Question_Degree
            ELSE @CurrentTotal + @Question_Degree END;

        IF @EffectiveTotal > @MaxDeg
        BEGIN
            DECLARE @Remaining DECIMAL(5,2) = @MaxDeg - @CurrentTotal + CASE WHEN @Exists = 1 THEN @OldDeg ELSE 0 END;
            DECLARE @sTotal VARCHAR(10) = CAST(@EffectiveTotal AS VARCHAR(10));
            DECLARE @sMax   VARCHAR(10) = CAST(@MaxDeg         AS VARCHAR(10));
            DECLARE @sRem   VARCHAR(10) = CAST(@Remaining       AS VARCHAR(10));
            RAISERROR('Exceeds capacity. NewTotal=%s, Max=%s, Available=%s', 16, 1, @sTotal, @sMax, @sRem);
        END

        IF @Exists = 1
        BEGIN
            IF EXISTS (SELECT 1 FROM Assessment.Student_Answer WHERE ExamID = @ExamID AND QuestionID = @QuestionID)
                RAISERROR('Cannot modify — students already answered Question %d.', 16, 1, @QuestionID);

            IF @Question_Order IS NOT NULL AND @Question_Order != @OldOrder
                UPDATE Assessment.Exam_Questions SET Question_Order = @OldOrder
                WHERE ExamID = @ExamID AND Question_Order = @Question_Order AND QuestionID != @QuestionID;

            EXEC sp_set_session_context @key = N'BypassDegreeCheck',      @value = 1;
            EXEC sp_set_session_context @key = N'BypassAnswerProtection', @value = 1;

            UPDATE Assessment.Exam_Questions SET
                Question_Degree = @Question_Degree,
                Question_Order  = ISNULL(@Question_Order, Question_Order)
            WHERE ExamID = @ExamID AND QuestionID = @QuestionID;

            EXEC sp_set_session_context @key = N'BypassDegreeCheck',      @value = 0;
            EXEC sp_set_session_context @key = N'BypassAnswerProtection', @value = 0;
        END
        ELSE
        BEGIN
            IF @Question_Order IS NULL
                SELECT @Question_Order = ISNULL(MAX(Question_Order), 0) + 1
                FROM Assessment.Exam_Questions WHERE ExamID = @ExamID;

            IF EXISTS (SELECT 1 FROM Assessment.Exam_Questions WHERE ExamID = @ExamID AND Question_Order = @Question_Order)
                UPDATE Assessment.Exam_Questions SET Question_Order = Question_Order + 1
                WHERE ExamID = @ExamID AND Question_Order >= @Question_Order;

            EXEC sp_set_session_context @key = N'BypassDegreeCheck', @value = 1;

            INSERT INTO Assessment.Exam_Questions (ExamID, QuestionID, Question_Order, Question_Degree)
            VALUES (@ExamID, @QuestionID, @Question_Order, @Question_Degree);

            EXEC sp_set_session_context @key = N'BypassDegreeCheck', @value = 0;
        END

        COMMIT TRANSACTION;

        SELECT @ExamID AS ExamID, @QuestionID AS QuestionID,
               CASE WHEN @Exists = 1 THEN 'Degree updated.' ELSE 'Question added.' END AS [Action],
               CASE WHEN @Exists = 1 THEN @OldDeg ELSE NULL END AS PreviousDegree,
               @Question_Degree AS NewDegree,
               Assessment.fn_GetExamTotalDegree(@ExamID)     AS NewTotal,
               Assessment.fn_GetExamRemainingDegree(@ExamID) AS Remaining,
               (SELECT COUNT(*) FROM Assessment.Exam_Questions WHERE ExamID = @ExamID) AS QuestionCount;

    END TRY
    BEGIN CATCH
        EXEC sp_set_session_context @key = N'BypassDegreeCheck',      @value = 0;
        EXEC sp_set_session_context @key = N'BypassAnswerProtection', @value = 0;
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- [6] DELETE EXAM QUESTION
CREATE OR ALTER PROCEDURE Assessment.sp_DeleteExamQuestion
    @ExamID INT, @QuestionID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Assessment.Exam_Questions WHERE ExamID = @ExamID AND QuestionID = @QuestionID)
            RAISERROR('Question %d not in Exam %d.', 16, 1, @QuestionID, @ExamID);
        IF EXISTS (SELECT 1 FROM Assessment.Student_Answer WHERE ExamID = @ExamID AND QuestionID = @QuestionID)
            RAISERROR('Cannot remove — students already answered.', 16, 1);

        DECLARE @DeletedOrder INT;
        SELECT @DeletedOrder = Question_Order FROM Assessment.Exam_Questions
        WHERE ExamID = @ExamID AND QuestionID = @QuestionID;

        EXEC sp_set_session_context @key = N'BypassAnswerProtection', @value = 1;

        DELETE FROM Assessment.Exam_Questions WHERE ExamID = @ExamID AND QuestionID = @QuestionID;
        UPDATE Assessment.Exam_Questions SET Question_Order = Question_Order - 1
        WHERE ExamID = @ExamID AND Question_Order > @DeletedOrder;

        EXEC sp_set_session_context @key = N'BypassAnswerProtection', @value = 0;

        COMMIT TRANSACTION;
        SELECT @ExamID AS ExamID, @QuestionID AS RemovedQuestionID,
               Assessment.fn_GetExamTotalDegree(@ExamID)     AS NewTotal,
               Assessment.fn_GetExamRemainingDegree(@ExamID) AS Remaining,
               (SELECT COUNT(*) FROM Assessment.Exam_Questions WHERE ExamID = @ExamID) AS QuestionsLeft;
    END TRY
    BEGIN CATCH
        EXEC sp_set_session_context @key = N'BypassAnswerProtection', @value = 0;
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

--  RANDOM EXAM GENERATION  [7]
----------------------------------------------------------------

-- [7] GENERATE RANDOM EXAM
-- FIX: Added per-type availability warning in result message
CREATE OR ALTER PROCEDURE Assessment.sp_GenerateRandomExam
    @ExamID            INT,
    @NumMCQ            INT           = 0,
    @NumTF             INT           = 0,
    @NumText           INT           = 0,
    @DegreePerQuestion DECIMAL(5,2)  = 5.00
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @CourseID INT, @MaxDeg DECIMAL(5,2);
        SELECT @CourseID = CourseID FROM Assessment.Exam WHERE ExamID = @ExamID AND isDeleted = 0;
        IF @CourseID IS NULL RAISERROR('Exam not found or deleted.', 16, 1);

        SELECT @MaxDeg = Max_Degree FROM Academic.Course WHERE CourseID = @CourseID;

        DECLARE @CurrentTotal DECIMAL(5,2) = Assessment.fn_GetExamTotalDegree(@ExamID);
        DECLARE @TotalNeeded  DECIMAL(5,2) = (@NumMCQ + @NumTF + @NumText) * @DegreePerQuestion;

        IF @CurrentTotal + @TotalNeeded > @MaxDeg
        BEGIN
            DECLARE @CalculatedTotal DECIMAL(5,2) = @CurrentTotal + @TotalNeeded;
            DECLARE @s_Total VARCHAR(20) = CAST(@CalculatedTotal AS VARCHAR(20));
            DECLARE @s_Max   VARCHAR(20) = CAST(@MaxDeg           AS VARCHAR(20));
            RAISERROR('Total would be %s, exceeding max %s.', 16, 1, @s_Total, @s_Max);
        END

        -- FIX: Check per-type availability and warn specifically which type is short
        DECLARE @AvailMCQ  INT = (SELECT COUNT(*) FROM Academic.Question_Pool
            WHERE CourseID = @CourseID AND QuestionType = 'MCQ'       AND isDeleted = 0
              AND QuestionID NOT IN (SELECT QuestionID FROM Assessment.Exam_Questions WHERE ExamID = @ExamID));
        DECLARE @AvailTF   INT = (SELECT COUNT(*) FROM Academic.Question_Pool
            WHERE CourseID = @CourseID AND QuestionType = 'TrueFalse' AND isDeleted = 0
              AND QuestionID NOT IN (SELECT QuestionID FROM Assessment.Exam_Questions WHERE ExamID = @ExamID));
        DECLARE @AvailText INT = (SELECT COUNT(*) FROM Academic.Question_Pool
            WHERE CourseID = @CourseID AND QuestionType = 'Text'      AND isDeleted = 0
              AND QuestionID NOT IN (SELECT QuestionID FROM Assessment.Exam_Questions WHERE ExamID = @ExamID));

        DECLARE @Selected TABLE (QuestionID INT);
        DECLARE @BaseOrder INT;
        SELECT @BaseOrder = ISNULL(MAX(Question_Order), 0) FROM Assessment.Exam_Questions WHERE ExamID = @ExamID;

        INSERT INTO @Selected
        SELECT TOP (@NumMCQ) QuestionID FROM Academic.Question_Pool
        WHERE CourseID = @CourseID AND QuestionType = 'MCQ' AND isDeleted = 0
          AND QuestionID NOT IN (SELECT QuestionID FROM Assessment.Exam_Questions WHERE ExamID = @ExamID)
        ORDER BY NEWID();

        INSERT INTO @Selected
        SELECT TOP (@NumTF) QuestionID FROM Academic.Question_Pool
        WHERE CourseID = @CourseID AND QuestionType = 'TrueFalse' AND isDeleted = 0
          AND QuestionID NOT IN (SELECT QuestionID FROM Assessment.Exam_Questions WHERE ExamID = @ExamID)
          AND QuestionID NOT IN (SELECT QuestionID FROM @Selected)
        ORDER BY NEWID();

        INSERT INTO @Selected
        SELECT TOP (@NumText) QuestionID FROM Academic.Question_Pool
        WHERE CourseID = @CourseID AND QuestionType = 'Text' AND isDeleted = 0
          AND QuestionID NOT IN (SELECT QuestionID FROM Assessment.Exam_Questions WHERE ExamID = @ExamID)
          AND QuestionID NOT IN (SELECT QuestionID FROM @Selected)
        ORDER BY NEWID();

        DECLARE @Requested INT = @NumMCQ + @NumTF + @NumText;
        DECLARE @Actual    INT = (SELECT COUNT(*) FROM @Selected);

        IF @Actual = 0
            RAISERROR('No questions available in the pool for Course %d.', 16, 1, @CourseID);

        EXEC sp_set_session_context @key = N'BypassDegreeCheck', @value = 1;

        INSERT INTO Assessment.Exam_Questions (ExamID, QuestionID, Question_Order, Question_Degree)
        SELECT @ExamID, QuestionID,
               @BaseOrder + ROW_NUMBER() OVER (ORDER BY (SELECT NEWID())),
               @DegreePerQuestion
        FROM @Selected;

        EXEC sp_set_session_context @key = N'BypassDegreeCheck', @value = 0;

        COMMIT TRANSACTION;

        -- FIX: Build detailed warning showing which type was short
        DECLARE @WarnMsg NVARCHAR(500) = 'All questions added.';
        IF @Actual < @Requested
        BEGIN
            SET @WarnMsg = 'WARNING: Only ' + CAST(@Actual AS VARCHAR) + ' of ' +
                           CAST(@Requested AS VARCHAR) + ' added. Shortfall detail — ' +
                           'MCQ: requested=' + CAST(@NumMCQ  AS VARCHAR) + ' available=' + CAST(@AvailMCQ  AS VARCHAR) + '; ' +
                           'TF: requested='  + CAST(@NumTF   AS VARCHAR) + ' available=' + CAST(@AvailTF   AS VARCHAR) + '; ' +
                           'Text: requested='+ CAST(@NumText AS VARCHAR) + ' available=' + CAST(@AvailText AS VARCHAR) + '.';
        END

        SELECT @Actual    AS QuestionsAdded,
               @Requested AS QuestionsRequested,
               @WarnMsg   AS [Message],
               Assessment.fn_GetExamTotalDegree(@ExamID)     AS NewTotal,
               Assessment.fn_GetExamRemainingDegree(@ExamID) AS Remaining;

        SELECT * FROM Assessment.vw_ExamQuestionsDetail WHERE ExamID = @ExamID ORDER BY Question_Order;

    END TRY
    BEGIN CATCH
        EXEC sp_set_session_context @key = N'BypassDegreeCheck', @value = 0;
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

--  STUDENT EXAM ASSIGNMENT  [8-11]
----------------------------------------------------------------

-- [8] ASSIGN STUDENT TO EXAM
-- FIX: Added check that exam has not already ended.
CREATE OR ALTER PROCEDURE Assessment.sp_AssignStudentToExam
    @StudentID  INT,
    @ExamID     INT,
    @Exam_Date  DATE,
    @Start_Time DATETIME,
    @End_Time   DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1 FROM Users.Student s JOIN Users.Person p ON s.StudentID = p.PersonID
            WHERE s.StudentID = @StudentID AND p.isDeleted = 0)
            RAISERROR('Student %d not found or inactive.', 16, 1, @StudentID);

        IF NOT EXISTS (SELECT 1 FROM Assessment.Exam WHERE ExamID = @ExamID AND isDeleted = 0)
            RAISERROR('Exam %d not found or deleted.', 16, 1, @ExamID);

        -- FIX: Block assignment to a past exam
        IF EXISTS (SELECT 1 FROM Assessment.Exam WHERE ExamID = @ExamID AND End_Time < GETDATE())
            RAISERROR('Cannot assign students to Exam %d — the exam has already ended.', 16, 1, @ExamID);

        IF EXISTS (SELECT 1 FROM Assessment.Student_Exam WHERE StudentID = @StudentID AND ExamID = @ExamID)
            RAISERROR('Student %d already assigned to Exam %d.', 16, 1, @StudentID, @ExamID);

        DECLARE @ExBranch INT, @ExTrack INT, @ExIntake INT;
        SELECT @ExBranch = BranchID, @ExTrack = TrackID, @ExIntake = IntakeID
        FROM Assessment.Exam WHERE ExamID = @ExamID;

        DECLARE @StBranch INT, @StTrack INT, @StIntake INT;
        SELECT @StBranch = BranchID, @StTrack = TrackID, @StIntake = IntakeID
        FROM Users.Student WHERE StudentID = @StudentID;

        IF @StBranch != @ExBranch
            RAISERROR('Student branch (%d) does not match exam branch (%d).', 16, 1, @StBranch, @ExBranch);
        IF @StTrack != @ExTrack
            RAISERROR('Student track (%d) does not match exam track (%d).', 16, 1, @StTrack, @ExTrack);
        IF @StIntake != @ExIntake
            RAISERROR('Student intake (%d) does not match exam intake (%d).', 16, 1, @StIntake, @ExIntake);

        IF NOT EXISTS (SELECT 1 FROM Assessment.Exam_Questions WHERE ExamID = @ExamID)
            RAISERROR('Exam %d has no questions. Add questions first.', 16, 1, @ExamID);
        IF @End_Time <= @Start_Time
            RAISERROR('End_Time must be after Start_Time.', 16, 1);

        INSERT INTO Assessment.Student_Exam (StudentID, ExamID, Exam_Date, Start_Time, End_Time)
        VALUES (@StudentID, @ExamID, @Exam_Date, @Start_Time, @End_Time);

        COMMIT TRANSACTION;
        SELECT * FROM Assessment.vw_StudentExamAssignments WHERE StudentID = @StudentID AND ExamID = @ExamID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- [9] BULK ASSIGN
-- FIX: Added check that exam has not already ended.
CREATE OR ALTER PROCEDURE Assessment.sp_BulkAssignStudentsToExam
    @ExamID     INT,
    @Exam_Date  DATE,
    @Start_Time DATETIME,
    @End_Time   DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Assessment.Exam WHERE ExamID = @ExamID AND isDeleted = 0)
            RAISERROR('Exam %d not found or deleted.', 16, 1, @ExamID);

        -- FIX: Block bulk assignment to a past exam
        IF EXISTS (SELECT 1 FROM Assessment.Exam WHERE ExamID = @ExamID AND End_Time < GETDATE())
            RAISERROR('Cannot assign students to Exam %d — the exam has already ended.', 16, 1, @ExamID);

        IF NOT EXISTS (SELECT 1 FROM Assessment.Exam_Questions WHERE ExamID = @ExamID)
            RAISERROR('Exam %d has no questions. Add questions first.', 16, 1, @ExamID);
        IF @End_Time <= @Start_Time
            RAISERROR('End_Time must be after Start_Time.', 16, 1);

        DECLARE @BranchID INT, @TrackID INT, @IntakeID INT;
        SELECT @BranchID = BranchID, @TrackID = TrackID, @IntakeID = IntakeID
        FROM Assessment.Exam WHERE ExamID = @ExamID;

        INSERT INTO Assessment.Student_Exam (StudentID, ExamID, Exam_Date, Start_Time, End_Time)
        SELECT s.StudentID, @ExamID, @Exam_Date, @Start_Time, @End_Time
        FROM Users.Student s JOIN Users.Person p ON s.StudentID = p.PersonID
        WHERE s.BranchID = @BranchID AND s.TrackID = @TrackID AND s.IntakeID = @IntakeID
          AND p.isDeleted = 0
          AND s.StudentID NOT IN (SELECT StudentID FROM Assessment.Student_Exam WHERE ExamID = @ExamID);

        DECLARE @Count INT = @@ROWCOUNT;
        COMMIT TRANSACTION;
        SELECT @Count AS StudentsAssigned, @ExamID AS ExamID, 'All matching students assigned.' AS [Message];
        SELECT * FROM Assessment.vw_StudentExamAssignments WHERE ExamID = @ExamID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- [10] UPDATE STUDENT EXAM
CREATE OR ALTER PROCEDURE Assessment.sp_UpdateStudentExam
    @StudentID  INT,
    @ExamID     INT,
    @Exam_Date  DATE     = NULL,
    @Start_Time DATETIME = NULL,
    @End_Time   DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Assessment.Student_Exam WHERE StudentID = @StudentID AND ExamID = @ExamID)
            RAISERROR('Assignment not found.', 16, 1);
        IF EXISTS (SELECT 1 FROM Assessment.Student_Answer WHERE StudentID = @StudentID AND ExamID = @ExamID)
            RAISERROR('Cannot modify — student already submitted answers.', 16, 1);

        DECLARE @FS DATETIME, @FE DATETIME;
        SELECT @FS = ISNULL(@Start_Time, Start_Time),
               @FE = ISNULL(@End_Time,   End_Time)
        FROM Assessment.Student_Exam WHERE StudentID = @StudentID AND ExamID = @ExamID;
        IF @FE <= @FS RAISERROR('End_Time must be after Start_Time.', 16, 1);

        EXEC sp_set_session_context @key = N'BypassStudentTimeCheck', @value = 1;
        UPDATE Assessment.Student_Exam SET
            Exam_Date  = ISNULL(@Exam_Date,  Exam_Date),
            Start_Time = ISNULL(@Start_Time, Start_Time),
            End_Time   = ISNULL(@End_Time,   End_Time)
        WHERE StudentID = @StudentID AND ExamID = @ExamID;
        EXEC sp_set_session_context @key = N'BypassStudentTimeCheck', @value = 0;

        COMMIT TRANSACTION;
        SELECT * FROM Assessment.vw_StudentExamAssignments WHERE StudentID = @StudentID AND ExamID = @ExamID;
    END TRY
    BEGIN CATCH
        EXEC sp_set_session_context @key = N'BypassStudentTimeCheck', @value = 0;
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- [11] REMOVE STUDENT FROM EXAM
CREATE OR ALTER PROCEDURE Assessment.sp_RemoveStudentFromExam
    @StudentID INT, @ExamID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM Assessment.Student_Exam WHERE StudentID = @StudentID AND ExamID = @ExamID)
            RAISERROR('Assignment not found.', 16, 1);
        IF EXISTS (SELECT 1 FROM Assessment.Student_Answer WHERE StudentID = @StudentID AND ExamID = @ExamID)
            RAISERROR('Cannot remove — student has answers. Delete answers first.', 16, 1);

        DELETE FROM Assessment.Student_Exam WHERE StudentID = @StudentID AND ExamID = @ExamID;
        COMMIT TRANSACTION;
        SELECT @StudentID AS RemovedStudent, @ExamID AS FromExam, 'Removed.' AS [Message];
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

--  STUDENT ANSWERS  [12-14]
----------------------------------------------------------------

-- [12] UPSERT ANSWER
CREATE OR ALTER PROCEDURE Assessment.sp_UpsertAnswer
    @StudentID      INT,
    @ExamID         INT,
    @QuestionID     INT,
    @Student_Answer NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Assessment.Student_Exam WHERE StudentID = @StudentID AND ExamID = @ExamID)
            RAISERROR('Student %d not assigned to Exam %d.', 16, 1, @StudentID, @ExamID);
        IF Assessment.fn_IsStudentExamActive(@StudentID, @ExamID) = 0
            RAISERROR('Exam window is not active for this student.', 16, 1);
        IF NOT EXISTS (SELECT 1 FROM Assessment.Exam_Questions WHERE ExamID = @ExamID AND QuestionID = @QuestionID)
            RAISERROR('Question %d not part of Exam %d.', 16, 1, @QuestionID, @ExamID);

        DECLARE @Action VARCHAR(20);

        IF EXISTS (
            SELECT 1 FROM Assessment.Student_Answer
            WHERE StudentID = @StudentID AND ExamID = @ExamID AND QuestionID = @QuestionID)
        BEGIN
            UPDATE Assessment.Student_Answer
            SET Student_Answer = @Student_Answer
            WHERE StudentID = @StudentID AND ExamID = @ExamID AND QuestionID = @QuestionID;
            SET @Action = 'Answer updated.';
        END
        ELSE
        BEGIN
            INSERT INTO Assessment.Student_Answer
                (StudentID, ExamID, QuestionID, Student_Answer, Is_Correct, Earned_Degree)
            VALUES (@StudentID, @ExamID, @QuestionID, @Student_Answer, NULL, 0);
            SET @Action = 'Answer submitted.';
        END

        COMMIT TRANSACTION;

        -- STUDENT-SAFE: No correct answer, no score, no Is_Correct
        SELECT
            @StudentID      AS StudentID,
            @ExamID         AS ExamID,
            @QuestionID     AS QuestionID,
            @Student_Answer AS YourAnswer,
            @Action         AS [Action],
            Assessment.fn_GetStudentAnswerCount(@StudentID, @ExamID) AS AnsweredSoFar,
            (SELECT COUNT(*) FROM Assessment.Exam_Questions WHERE ExamID = @ExamID) AS TotalQuestions;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- [13] DELETE ANSWER
CREATE OR ALTER PROCEDURE Assessment.sp_DeleteAnswer
    @StudentID  INT,
    @ExamID     INT,
    @QuestionID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (
            SELECT 1 FROM Assessment.Student_Answer
            WHERE StudentID = @StudentID AND ExamID = @ExamID AND QuestionID = @QuestionID)
            RAISERROR('Answer not found.', 16, 1);
        IF Assessment.fn_IsStudentExamActive(@StudentID, @ExamID) = 0
            RAISERROR('Exam window is closed. Cannot delete answer.', 16, 1);

        DELETE FROM Assessment.Student_Answer
        WHERE StudentID = @StudentID AND ExamID = @ExamID AND QuestionID = @QuestionID;

        COMMIT TRANSACTION;
        SELECT @StudentID AS StudentID, @ExamID AS ExamID,
               @QuestionID AS DeletedQuestionID, 'Answer deleted.' AS [Message];
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- [14] GRADE TEXT ANSWER (Instructor)
-- FIX: Added check to block grading while exam is still active.
CREATE OR ALTER PROCEDURE Assessment.sp_GradeTextAnswer
    @Answer_ID    INT,
    @Is_Correct   BIT,
    @Earned_Degree DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1 FROM Assessment.Student_Answer a
            JOIN Academic.Question_Pool q ON a.QuestionID = q.QuestionID
            WHERE a.Answer_ID = @Answer_ID AND q.QuestionType = 'Text')
            RAISERROR('Answer %d is not a text question or does not exist.', 16, 1, @Answer_ID);

        -- FIX: Cannot grade while exam is still active
        DECLARE @ChkStudentID INT, @ChkExamID INT;
        SELECT @ChkStudentID = StudentID, @ChkExamID = ExamID
        FROM Assessment.Student_Answer WHERE Answer_ID = @Answer_ID;

        IF Assessment.fn_IsStudentExamActive(@ChkStudentID, @ChkExamID) = 1
            RAISERROR('Cannot grade Answer %d — exam is still active for this student.', 16, 1, @Answer_ID);

        DECLARE @MaxDeg DECIMAL(5,2);
        SELECT @MaxDeg = eq.Question_Degree
        FROM Assessment.Student_Answer a
        JOIN Assessment.Exam_Questions eq ON a.ExamID = eq.ExamID AND a.QuestionID = eq.QuestionID
        WHERE a.Answer_ID = @Answer_ID;

        IF @Earned_Degree < 0 RAISERROR('Earned degree cannot be negative.', 16, 1);
        IF @Earned_Degree > @MaxDeg
        BEGIN
            DECLARE @sEarned VARCHAR(10) = CAST(@Earned_Degree AS VARCHAR(10));
            DECLARE @sMaxQ   VARCHAR(10) = CAST(@MaxDeg        AS VARCHAR(10));
            RAISERROR('Earned (%s) cannot exceed max (%s).', 16, 1, @sEarned, @sMaxQ);
        END

        UPDATE Assessment.Student_Answer SET
            Is_Correct    = @Is_Correct,
            Earned_Degree = @Earned_Degree
        WHERE Answer_ID = @Answer_ID;

        COMMIT TRANSACTION;
        SELECT * FROM Assessment.vw_StudentAnswerSheet WHERE Answer_ID = @Answer_ID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO


--  STUDENT-FACING  [15-16]
----------------------------------------------------------------

-- [15] GET EXAM QUESTIONS (during exam — NO correct answers)
CREATE OR ALTER PROCEDURE Assessment.sp_GetStudentExamQuestions
    @StudentID INT, @ExamID INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Assessment.Student_Exam WHERE StudentID = @StudentID AND ExamID = @ExamID)
    BEGIN RAISERROR('You are not assigned to this exam.', 16, 1); RETURN; END
    IF Assessment.fn_IsStudentExamActive(@StudentID, @ExamID) = 0
    BEGIN RAISERROR('Exam is not available at this time.', 16, 1); RETURN; END

    SELECT eq.Question_Order, eq.QuestionID, q.QuestionType, q.QuestionText, eq.Question_Degree,
        (SELECT qc.ChoiceID, qc.ChoiceText
         FROM Academic.Question_Choices qc
         WHERE qc.QuestionID = eq.QuestionID AND qc.isDeleted = 0
         FOR JSON PATH) AS Choices,
        sa.Student_Answer AS CurrentAnswer
    FROM Assessment.Exam_Questions eq
    JOIN Academic.Question_Pool q ON eq.QuestionID = q.QuestionID
    LEFT JOIN Assessment.Student_Answer sa
        ON sa.ExamID = eq.ExamID AND sa.QuestionID = eq.QuestionID AND sa.StudentID = @StudentID
    WHERE eq.ExamID = @ExamID
    ORDER BY eq.Question_Order;
END;
GO

-- [16] POST-EXAM REVIEW
-- FIX: Added PendingTextAnswers column to warn student if text answers still ungraded.
CREATE OR ALTER PROCEDURE Assessment.sp_StudentPostExamReview
    @StudentID INT, @ExamID INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Assessment.Student_Exam WHERE StudentID = @StudentID AND ExamID = @ExamID)
    BEGIN RAISERROR('You are not assigned to this exam.', 16, 1); RETURN; END

    DECLARE @EndTime DATETIME;
    SELECT @EndTime = End_Time FROM Assessment.Student_Exam
    WHERE StudentID = @StudentID AND ExamID = @ExamID;
    IF GETDATE() < @EndTime
    BEGIN RAISERROR('Exam still in progress. Review available after exam ends.', 16, 1); RETURN; END

    IF NOT EXISTS (SELECT 1 FROM Assessment.Student_Exam_Result WHERE StudentID = @StudentID AND ExamID = @ExamID)
    BEGIN RAISERROR('Results not yet calculated. Wait for instructor to finalize.', 16, 1); RETURN; END

    SELECT
        r.StudentID,
        p.FirstName + ' ' + p.LastName AS StudentName,
        c.CourseName,
        e.ExamType,
        r.Total_Score,
        Assessment.fn_GetExamTotalDegree(r.ExamID) AS ExamMaxDegree,
        CASE WHEN Assessment.fn_GetExamTotalDegree(r.ExamID) > 0
             THEN CAST(r.Total_Score * 100.0 / Assessment.fn_GetExamTotalDegree(r.ExamID) AS DECIMAL(5,2))
             ELSE 0 END AS ScorePercentage,
        r.Grade,
        r.Pass_Fail,
        CASE WHEN r.Pass_Fail = 1 THEN 'PASSED' ELSE 'FAILED' END AS ResultText,
        -- FIX: Warn student if text answers are still pending review
        (SELECT COUNT(*)
         FROM Assessment.Student_Answer a
         JOIN Academic.Question_Pool q ON a.QuestionID = q.QuestionID
         WHERE a.StudentID = @StudentID AND a.ExamID = @ExamID
           AND q.QuestionType = 'Text' AND a.Is_Correct IS NULL) AS PendingTextAnswers
    FROM Assessment.Student_Exam_Result r
    JOIN Assessment.Exam e     ON r.ExamID    = e.ExamID
    JOIN Academic.Course c     ON r.CourseID  = c.CourseID
    JOIN Users.Person p        ON r.StudentID = p.PersonID
    WHERE r.StudentID = @StudentID AND r.ExamID = @ExamID;
END;
GO

--  RESULT CALCULATION  [17-18]
----------------------------------------------------------------

-- [17] CALCULATE SINGLE RESULT
CREATE OR ALTER PROCEDURE Assessment.sp_CalculateResult
    @StudentID INT, @ExamID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Assessment.Student_Exam WHERE StudentID = @StudentID AND ExamID = @ExamID)
            RAISERROR('Student %d not assigned to Exam %d.', 16, 1, @StudentID, @ExamID);

        DECLARE @Pending INT;
        SELECT @Pending = COUNT(*)
        FROM Assessment.Student_Answer a
        JOIN Academic.Question_Pool q ON a.QuestionID = q.QuestionID
        WHERE a.StudentID = @StudentID AND a.ExamID = @ExamID
          AND q.QuestionType = 'Text' AND a.Is_Correct IS NULL;

        IF @Pending > 0
            RAISERROR('Cannot calculate result — %d text answer(s) still pending review. Grade them first.', 16, 1, @Pending);

        DECLARE @CourseID  INT,
                @ExamMax   DECIMAL(5,2),
                @MinDeg    DECIMAL(5,2),
                @MaxDeg    DECIMAL(5,2),
                @TotalScore DECIMAL(5,2),
                @Grade     VARCHAR(5),
                @PassFail  BIT;

        SELECT @CourseID = CourseID FROM Assessment.Exam WHERE ExamID = @ExamID;
        SELECT @MaxDeg = Max_Degree, @MinDeg = Min_Degree FROM Academic.Course WHERE CourseID = @CourseID;

        SET @ExamMax    = Assessment.fn_GetExamTotalDegree(@ExamID);
        SET @TotalScore = Assessment.fn_GetStudentExamScore(@StudentID, @ExamID);
        SET @Grade      = Assessment.fn_CalculateGrade(@TotalScore, @ExamMax);

        DECLARE @ScaledMin DECIMAL(5,2) = CASE WHEN @MaxDeg > 0 THEN (@MinDeg / @MaxDeg) * @ExamMax ELSE 0 END;
        SET @PassFail = CASE WHEN @TotalScore >= @ScaledMin THEN 1 ELSE 0 END;

        IF EXISTS (SELECT 1 FROM Assessment.Student_Exam_Result WHERE StudentID = @StudentID AND ExamID = @ExamID)
            UPDATE Assessment.Student_Exam_Result SET
                Total_Score = @TotalScore, Grade = @Grade, Pass_Fail = @PassFail
            WHERE StudentID = @StudentID AND ExamID = @ExamID;
        ELSE
            INSERT INTO Assessment.Student_Exam_Result (StudentID, ExamID, CourseID, Total_Score, Grade, Pass_Fail)
            VALUES (@StudentID, @ExamID, @CourseID, @TotalScore, @Grade, @PassFail);

        COMMIT TRANSACTION;

        SELECT @StudentID  AS StudentID,
               @ExamID     AS ExamID,
               @TotalScore AS TotalScore,
               @ExamMax    AS ExamMaxDegree,
               CASE WHEN @ExamMax > 0 THEN CAST(@TotalScore * 100.0 / @ExamMax AS DECIMAL(5,2)) ELSE 0 END AS ScorePercentage,
               @Grade      AS Grade,
               @PassFail   AS PassFail,
               CASE WHEN @PassFail = 1 THEN 'PASSED' ELSE 'FAILED' END AS ResultText,
               @ScaledMin  AS RequiredMinimum,
               @Pending    AS PendingTextAnswers;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- [18] CALCULATE ALL RESULTS FOR EXAM
-- FIX: Replaced Cursor with SET-based INSERT/UPDATE to avoid multiple Result Sets
--      and drastically improve performance with large student counts.
CREATE OR ALTER PROCEDURE Assessment.sp_CalculateAllExamResults
    @ExamID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Assessment.Exam WHERE ExamID = @ExamID AND isDeleted = 0)
            RAISERROR('Exam %d not found or deleted.', 16, 1, @ExamID);

        DECLARE @CourseID INT;
        SELECT @CourseID = CourseID FROM Assessment.Exam WHERE ExamID = @ExamID;

        DECLARE @MaxDeg  DECIMAL(5,2), @MinDeg DECIMAL(5,2);
        SELECT @MaxDeg = Max_Degree, @MinDeg = Min_Degree FROM Academic.Course WHERE CourseID = @CourseID;

        DECLARE @ExamMax   DECIMAL(5,2) = Assessment.fn_GetExamTotalDegree(@ExamID);
        DECLARE @ScaledMin DECIMAL(5,2) = CASE WHEN @MaxDeg > 0 THEN (@MinDeg / @MaxDeg) * @ExamMax ELSE 0 END;

        -- Build a staging table with all students' calculated results
        DECLARE @Staged TABLE (
            StudentID  INT,
            TotalScore DECIMAL(5,2),
            Grade      VARCHAR(5),
            PassFail   BIT
        );

        INSERT INTO @Staged (StudentID, TotalScore, Grade, PassFail)
        SELECT
            se.StudentID,
            Assessment.fn_GetStudentExamScore(se.StudentID, @ExamID),
            Assessment.fn_CalculateGrade(Assessment.fn_GetStudentExamScore(se.StudentID, @ExamID), @ExamMax),
            CASE WHEN Assessment.fn_GetStudentExamScore(se.StudentID, @ExamID) >= @ScaledMin THEN 1 ELSE 0 END
        FROM Assessment.Student_Exam se
        WHERE se.ExamID = @ExamID;

        -- UPDATE existing results
        UPDATE r SET
            Total_Score = s.TotalScore,
            Grade       = s.Grade,
            Pass_Fail   = s.PassFail
        FROM Assessment.Student_Exam_Result r
        JOIN @Staged s ON r.StudentID = s.StudentID AND r.ExamID = @ExamID;

        -- INSERT new results
        INSERT INTO Assessment.Student_Exam_Result (StudentID, ExamID, CourseID, Total_Score, Grade, Pass_Fail)
        SELECT s.StudentID, @ExamID, @CourseID, s.TotalScore, s.Grade, s.PassFail
        FROM @Staged s
        WHERE NOT EXISTS (
            SELECT 1 FROM Assessment.Student_Exam_Result r
            WHERE r.StudentID = s.StudentID AND r.ExamID = @ExamID
        );

        COMMIT TRANSACTION;

        SELECT * FROM Assessment.vw_ExamStatistics     WHERE ExamID = @ExamID;
        SELECT * FROM Assessment.vw_StudentExamResults WHERE ExamID = @ExamID ORDER BY Total_Score DESC;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
--  SEARCH  [19-24]
----------------------------------------------------------------

-- [19] SEARCH EXAMS
CREATE OR ALTER PROCEDURE Assessment.sp_SearchExams
    @CourseID       INT         = NULL,
    @InstructorID   INT         = NULL,
    @BranchID       INT         = NULL,
    @TrackID        INT         = NULL,
    @IntakeID       INT         = NULL,
    @ExamType       VARCHAR(20) = NULL,
    @Year           INT         = NULL,
    @ActiveOnly     BIT         = 0,
    @IncludeDeleted BIT         = 0
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM Assessment.vw_ExamDetails
    WHERE (@CourseID       IS NULL OR CourseID         = @CourseID)
      AND (@InstructorID   IS NULL OR InstructorID     = @InstructorID)
      AND (@BranchID       IS NULL OR BranchID         = @BranchID)
      AND (@TrackID        IS NULL OR TrackID           = @TrackID)
      AND (@IntakeID       IS NULL OR IntakeID          = @IntakeID)
      AND (@ExamType       IS NULL OR ExamType          = @ExamType)
      AND (@Year           IS NULL OR ExamYear          = @Year)
      AND (@ActiveOnly     = 0     OR IsCurrentlyActive = 1)
      AND (@IncludeDeleted = 1     OR ExamDeleted       = 0)
    ORDER BY Start_Time DESC;
END;
GO

-- [20] SEARCH EXAM RESULTS
CREATE OR ALTER PROCEDURE Assessment.sp_SearchExamResults
    @StudentID INT         = NULL,
    @CourseID  INT         = NULL,
    @ExamType  VARCHAR(20) = NULL,
    @Grade     VARCHAR(5)  = NULL,
    @PassOnly  BIT         = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM Assessment.vw_StudentExamResults
    WHERE (@StudentID IS NULL OR StudentID = @StudentID)
      AND (@CourseID  IS NULL OR CourseID  = @CourseID)
      AND (@ExamType  IS NULL OR ExamType  = @ExamType)
      AND (@Grade     IS NULL OR Grade     = @Grade)
      AND (@PassOnly  IS NULL OR @PassOnly = 0 OR Pass_Fail = 1)
    ORDER BY StudentName, CourseName;
END;
GO

-- [21] GET EXAM ANSWER SHEET (Instructor)
CREATE OR ALTER PROCEDURE Assessment.sp_GetExamAnswerSheet
    @ExamID    INT,
    @StudentID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM Assessment.vw_StudentAnswerSheet
    WHERE ExamID = @ExamID AND (@StudentID IS NULL OR StudentID = @StudentID)
    ORDER BY StudentName, QuestionID;
END;
GO

-- [22] GET PENDING TEXT REVIEWS (Instructor)
CREATE OR ALTER PROCEDURE Assessment.sp_GetPendingTextReviews
    @InstructorID INT = NULL,
    @ExamID       INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM Assessment.vw_TextAnswersForReview
    WHERE (@InstructorID IS NULL OR InstructorID = @InstructorID)
      AND (@ExamID       IS NULL OR ExamID       = @ExamID)
    ORDER BY SimilarityScore DESC;
END;
GO

-- [23] GET EXAM STATISTICS
CREATE OR ALTER PROCEDURE Assessment.sp_GetExamStatistics
    @ExamID       INT = NULL,
    @InstructorID INT = NULL,
    @CourseID     INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM Assessment.vw_ExamStatistics
    WHERE (@ExamID       IS NULL OR ExamID       = @ExamID)
      AND (@InstructorID IS NULL OR InstructorID = @InstructorID)
      AND (@CourseID     IS NULL OR CourseID     = @CourseID)
    ORDER BY ExamID;

    IF @ExamID IS NOT NULL
        SELECT * FROM Assessment.vw_StudentExamResults WHERE ExamID = @ExamID ORDER BY Total_Score DESC;
END;
GO

-- [24] GET STUDENT EXAM HISTORY
CREATE OR ALTER PROCEDURE Assessment.sp_GetStudentExamHistory
    @StudentID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM Assessment.vw_StudentExamAssignments WHERE StudentID = @StudentID;
    SELECT * FROM Assessment.vw_StudentExamResults     WHERE StudentID = @StudentID;
END;
GO

--  AUDIT  [25]
----------------------------------------------------------------

-- [25] SEARCH AUDIT LOG
CREATE OR ALTER PROCEDURE Assessment.sp_GetAuditLog
    @TableName  NVARCHAR(128) = NULL,
    @Operation  NVARCHAR(10)  = NULL,
    @Key        INT           = NULL,
    @ChangedBy  NVARCHAR(128) = NULL,
    @FromDate   DATETIME      = NULL,
    @ToDate     DATETIME      = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM Assessment.vw_AuditLog
    WHERE (@TableName IS NULL OR TableName  = @TableName)
      AND (@Operation  IS NULL OR Operation  = @Operation)
      AND (@Key        IS NULL OR [Key]      = @Key)
      AND (@ChangedBy  IS NULL OR ChangedBy  = @ChangedBy)
      AND (@FromDate   IS NULL OR ChangedAt >= @FromDate)
      AND (@ToDate     IS NULL OR ChangedAt <= @ToDate)
    ORDER BY ChangedAt DESC;
END;
GO
