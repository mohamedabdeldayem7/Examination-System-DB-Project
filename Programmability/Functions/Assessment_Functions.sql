USE ExamSystemDB;
GO

-- F1
CREATE OR ALTER FUNCTION Assessment.fn_GetExamTotalDegree(@ExamID INT)
RETURNS DECIMAL(5,2)
AS
BEGIN
    DECLARE @T DECIMAL(5,2);
    SELECT @T = ISNULL(SUM(Question_Degree), 0)
    FROM Assessment.Exam_Questions WHERE ExamID = @ExamID;
    RETURN @T;
END;
GO

-- F2
CREATE OR ALTER FUNCTION Assessment.fn_GetExamRemainingDegree(@ExamID INT)
RETURNS DECIMAL(5,2)
AS
BEGIN
    DECLARE @Max DECIMAL(5,2), @Used DECIMAL(5,2);
    SELECT @Max = c.Max_Degree
    FROM Assessment.Exam e JOIN Academic.Course c ON e.CourseID = c.CourseID
    WHERE e.ExamID = @ExamID;
    SET @Used = Assessment.fn_GetExamTotalDegree(@ExamID);
    RETURN ISNULL(@Max - @Used, 0);
END;
GO

-- F3
CREATE OR ALTER FUNCTION Assessment.fn_IsExamActive(@ExamID INT)
RETURNS BIT
AS
BEGIN
    DECLARE @A BIT = 0;
    IF EXISTS (
        SELECT 1 FROM Assessment.Exam
        WHERE ExamID = @ExamID AND isDeleted = 0
          AND GETDATE() BETWEEN Start_Time AND End_Time
    ) SET @A = 1;
    RETURN @A;
END;
GO

-- F4
CREATE OR ALTER FUNCTION Assessment.fn_IsStudentExamActive(@StudentID INT, @ExamID INT)
RETURNS BIT
AS
BEGIN
    DECLARE @A BIT = 0;
    IF EXISTS (
        SELECT 1 FROM Assessment.Student_Exam se
        JOIN Assessment.Exam e ON se.ExamID = e.ExamID
        WHERE se.StudentID = @StudentID AND se.ExamID = @ExamID
          AND e.isDeleted = 0
          AND GETDATE() BETWEEN se.Start_Time AND se.End_Time
    ) SET @A = 1;
    RETURN @A;
END;
GO

-- F5
CREATE OR ALTER FUNCTION Academic.fn_GetCorrectAnswer(@QuestionID INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @Ans NVARCHAR(MAX), @QT VARCHAR(20);
    SELECT @QT = QuestionType FROM Academic.Question_Pool WHERE QuestionID = @QuestionID;

    IF @QT IN ('MCQ','TrueFalse')
        SELECT TOP 1 @Ans = ChoiceText
        FROM Academic.Question_Choices
        WHERE QuestionID = @QuestionID AND IsCorrectChoice = 1 AND isDeleted = 0;
    ELSE
        SELECT @Ans = Best_Accepted_Answer
        FROM Academic.Question_Pool WHERE QuestionID = @QuestionID;

    RETURN @Ans;
END;
GO

-- F6
CREATE OR ALTER FUNCTION Assessment.fn_CalculateGrade(@Score DECIMAL(5,2), @MaxDegree DECIMAL(5,2))
RETURNS VARCHAR(5)
AS
BEGIN
    IF @MaxDegree = 0 RETURN 'F';
    DECLARE @Pct FLOAT = (@Score / @MaxDegree) * 100.0;
    RETURN CASE
        WHEN @Pct >= 85 THEN 'A'
        WHEN @Pct >= 75 THEN 'B'
        WHEN @Pct >= 65 THEN 'C'
        WHEN @Pct >= 50 THEN 'D'
        ELSE 'F'
    END;
END;
GO

-- F7
CREATE OR ALTER FUNCTION Assessment.fn_TextSimilarity(
    @StudentAnswer NVARCHAR(MAX), @BestAnswer NVARCHAR(MAX)
)
RETURNS DECIMAL(5,2)
AS
BEGIN
    IF @StudentAnswer IS NULL OR @BestAnswer IS NULL RETURN 0;
    DECLARE @S NVARCHAR(MAX) = LOWER(LTRIM(RTRIM(@StudentAnswer)));
    DECLARE @B NVARCHAR(MAX) = LOWER(LTRIM(RTRIM(@BestAnswer)));
    DECLARE @Score DECIMAL(5,2) = 0;

    IF @S = @B RETURN 100.00;

    IF CHARINDEX(@S, @B) > 0 OR CHARINDEX(@B, @S) > 0
        SET @Score = @Score + 30;

    IF SOUNDEX(@S) = SOUNDEX(@B)
        SET @Score = @Score + 10;

    DECLARE @Ratio FLOAT = CASE WHEN LEN(@B) > 0
        THEN 1.0 - ABS(LEN(@S) - LEN(@B)) * 1.0 / LEN(@B) ELSE 0 END;
    IF @Ratio < 0 SET @Ratio = 0;
    SET @Score = @Score + (@Ratio * 20);

    DECLARE @WordCount INT = 0, @MatchCount INT = 0;
    DECLARE @Pos INT = 1, @Word NVARCHAR(100), @NextSpace INT;
    WHILE @Pos <= LEN(@B)
    BEGIN
        SET @NextSpace = CHARINDEX(' ', @B, @Pos);
        IF @NextSpace = 0 SET @NextSpace = LEN(@B) + 1;
        SET @Word = SUBSTRING(@B, @Pos, @NextSpace - @Pos);
        IF LEN(@Word) > 3
        BEGIN
            SET @WordCount = @WordCount + 1;
            IF PATINDEX('%' + @Word + '%', @S) > 0
                SET @MatchCount = @MatchCount + 1;
        END
        SET @Pos = @NextSpace + 1;
    END
    IF @WordCount > 0
        SET @Score = @Score + (CAST(@MatchCount AS FLOAT) / @WordCount * 40);

    IF @Score > 100 SET @Score = 100;
    RETURN @Score;
END;
GO

-- F8
CREATE OR ALTER FUNCTION Assessment.fn_GetStudentAnswerCount(@StudentID INT, @ExamID INT)
RETURNS INT
AS
BEGIN
    DECLARE @C INT;
    SELECT @C = COUNT(*) FROM Assessment.Student_Answer
    WHERE StudentID = @StudentID AND ExamID = @ExamID;
    RETURN ISNULL(@C, 0);
END;
GO

-- F9
CREATE OR ALTER FUNCTION Assessment.fn_GetStudentExamScore(@StudentID INT, @ExamID INT)
RETURNS DECIMAL(5,2)
AS
BEGIN
    DECLARE @S DECIMAL(5,2);
    SELECT @S = ISNULL(SUM(Earned_Degree), 0)
    FROM Assessment.Student_Answer
    WHERE StudentID = @StudentID AND ExamID = @ExamID;
    RETURN @S;
END;
GO

-- F10
CREATE OR ALTER FUNCTION Assessment.fn_ExamHasSubmissions(@ExamID INT)
RETURNS BIT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Assessment.Student_Answer WHERE ExamID = @ExamID) RETURN 1;
    RETURN 0;
END;
GO
