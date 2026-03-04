USE [ExamSystemDB];
GO 
-- Academic Stored Procedure
--STORED PROCEDURE FOR MAMAGER TO ADD COURSE
CREATE OR ALTER PROC Academic.sp_AddCourse
@CourseName VARCHAR(100) ,
@Description VARCHAR(500) =NULL ,
@Max_Degree DECIMAL (5,2) ,
@Min_Degree DECIMAL (5,2)
AS
BEGIN 
    SET NOCOUNT ON;

    BEGIN TRY
     -- VALIDATION FOR MANAGER 
    IF @CourseName IS NULL OR @Max_Degree IS NULL OR @Min_Degree IS NULL
            THROW 51000, 'Required fields are missing.', 1;
    IF @Min_Degree >= @Max_Degree
            THROW 51001, 'MinDegree must be less than MaxDegree.', 1;
     IF EXISTS (
            SELECT 1 FROM Academic.Course
            WHERE CourseName = @CourseName
              AND IsDeleted = 0
        )
            THROW 51002, 'Course already exists.', 1;
      INSERT INTO Academic.Course
        (CourseName, Description, Max_Degree, Min_Degree, IsDeleted)
        VALUES
        (@CourseName, @Description, @Max_Degree, @Min_Degree, 0);


    END TRY
    BEGIN CATCH 
        THROW
    END CATCH
END
GO
--STORED PROCEDURE FOR MAMAGER TO UPDATE COURSE
CREATE OR ALTER PROC Academic.sp_UpdateCourse
@CourseID INT ,
@CourseName VARCHAR(100)  =NULL ,
@Description VARCHAR(500) =NULL ,
@Max_Degree DECIMAL (5,2) =NULL ,
@Min_Degree DECIMAL (5,2) =NULL
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
    -- VALIDATION FOR MANAGER 
    IF NOT EXISTS (SELECT 1 FROM [Academic].[Course] WHERE [CourseID] = @CourseID AND IsDeleted = 0)
        THROW 51003, 'Course not exists.', 1;
     UPDATE Academic.Course
        SET
            CourseName = ISNULL(@CourseName, CourseName),
            Description = ISNULL(@Description, Description),
            Max_Degree = ISNULL(@Max_Degree, Max_Degree),
            Min_Degree = ISNULL(@Min_Degree, Min_Degree)
        WHERE CourseId = @CourseId;
     END TRY
    BEGIN CATCH 
        THROW
    END CATCH
END
GO
--STORED PROCEDURE FOR MAMAGER TO DELETE COURSE 
CREATE OR ALTER PROC Academic.sp_DeleteCourse
@CourseID INT
AS
BEGIN
    SET NOCOUNT ON ;
    BEGIN TRY 
     IF NOT EXISTS (SELECT 1 FROM [Academic].[Course] WHERE [CourseID] = @CourseID AND IsDeleted = 0)
        THROW 51004, 'Course not exists.', 1;
     IF EXISTS ( SELECT 1 FROM [Assessment].[Exam] WHERE CourseID = @CourseID AND IsDeleted = 0 )
            THROW 51005, 'Cannot delete course. Exams exist.', 1;
    UPDATE [Academic].[Course]
    SET [IsDeleted] =1 
    WHERE [CourseID] = @CourseID;
    END TRY
    BEGIN CATCH 
        THROW
    END CATCH
END
GO 
--[Academic].[Course_Instructor]-----------
CREATE OR ALTER PROC Academic.sp_AssignInstructorToCourse
@InstructorID INT ,
@CourseID INT ,
@YEAR INT 
AS 
BEGIN 
    SET NOCOUNT ON ;
    --VALIDATION FOR MANAGER 
    BEGIN TRY 
      IF NOT EXISTS (
            SELECT 1 FROM Academic.Course
            WHERE [CourseID] = @CourseID
              AND [IsDeleted] = 0
        )
            THROW 51005, 'Course not found.', 1;

        IF NOT EXISTS (
            SELECT 1 FROM Users.Instructor
            WHERE InstructorID = @InstructorID
            
        )
            THROW 51006, 'Instructor not found.', 1;
        IF EXISTS (
        SELECT 1 FROM [Academic].[Course_Instructor] 
        WHERE [InstructorID] = @InstructorID AND [CourseID] = @CourseID AND  [Year]=@Year 
        )
        THROW 51007, 'Course already has instructor for this year.', 1;
        INSERT INTO [Academic].[Course_Instructor] (CourseID, InstructorID, [Year])
        VALUES
        (@CourseID, @InstructorID, @Year);
        

    END TRY
    BEGIN CATCH 
        THROW
    END CATCH
END
GO 
-- QUESTION POOL AND Question_Choices -----------
-- CREATE STORED PROCEDURE TO ADD QUESTION
CREATE or ALTER PROC Academic.sp_AddQuestionWithChoices
    @CourseID INT,
    @InstructorID INT,
    @QuestionType VARCHAR(20),   -- MCQ / TF / TEXT
    @QuestionText NVARCHAR(MAX),
    @BestAcceptedAnswer NVARCHAR(MAX) = NULL ,
    @Choice1 NVARCHAR(MAX) = NULL,
    @Choice2 NVARCHAR(MAX) = NULL,
    @Choice3 NVARCHAR(MAX) = NULL,
    @Choice4 NVARCHAR(MAX) = NULL,
    @CorrectChoiceNumber INT = NULL  -- 1,2,3,4
AS 
BEGIN
    SET NOCOUNT ON ;

    BEGIN TRY 
        IF @QuestionType NOT IN ('MCQ','TrueFalse','Text')
            THROW 51008, 'Invalid Question Type.', 1;
        BEGIN TRANSACTION;
          INSERT INTO [Academic].[Question_Pool] ([CourseID],[InstructorID],[QuestionType], [QuestionText],[Best_Accepted_Answer] ,[isDeleted])
          VALUES(
            @CourseID,
            @InstructorID,
            @QuestionType,
            @QuestionText,
            @BestAcceptedAnswer,
            0
            );
            DECLARE @NewQuestionID INT = SCOPE_IDENTITY();
           
                

            IF @QuestionType = 'MCQ'
            BEGIN
                 IF @CorrectChoiceNumber NOT BETWEEN 1 AND 4
                THROW 51009, 'MCQ must have one correct choice (1-4)', 1;

                INSERT INTO [Academic].[Question_Choices] ([QuestionID],[ChoiceText],[IsCorrectChoice],[isDeleted])
                VALUES (@NewQuestionID, @Choice1, CASE WHEN @CorrectChoiceNumber = 1 THEN 1 ELSE 0 END, 0),
                       (@NewQuestionID, @Choice2, CASE WHEN @CorrectChoiceNumber = 2 THEN 1 ELSE 0 END, 0),
                       (@NewQuestionID, @Choice3, CASE WHEN @CorrectChoiceNumber = 3 THEN 1 ELSE 0 END, 0),
                       (@NewQuestionID, @Choice4, CASE WHEN @CorrectChoiceNumber = 4 THEN 1 ELSE 0 END, 0);

            END
            IF @QuestionType = 'TF'
                 BEGIN
                    IF @BestAcceptedAnswer NOT IN ('True','False')
                        THROW 51010, 'TF must be True or False.', 1;
                 END
             IF @QuestionType = 'TEXT'
                BEGIN
                    IF @BestAcceptedAnswer IS NULL
                        THROW 52006, 'TEXT question must have Best Accepted Answer.', 1;
                END

  COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH
END
GO
-------------------------------------------------------------------------
----UpdateQuestion-------------
CREATE OR ALTER PROC Academic.sp_UpdateQuestion
    @QuestionID INT,
    @QuestionText NVARCHAR(MAX) = NULL,
    @BestAcceptedAnswer NVARCHAR(MAX) = NULL,
    @Choice1 NVARCHAR(MAX) = NULL,
    @Choice2 NVARCHAR(MAX) = NULL,
    @Choice3 NVARCHAR(MAX) = NULL,
    @Choice4 NVARCHAR(MAX) = NULL,
    @CorrectChoiceNumber INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        -- Check Question Exists
        IF NOT EXISTS (
            SELECT 1 
            FROM Academic.Question_Pool
            WHERE QuestionID = @QuestionID
              AND IsDeleted = 0
        )
            THROW 51007, 'Question not found.', 1;

        DECLARE @QuestionType VARCHAR(20);

        SELECT @QuestionType = QuestionType
        FROM Academic.Question_Pool
        WHERE QuestionID = @QuestionID;

        BEGIN TRANSACTION;

        --------------------------------------------------
        -- Update Question Main Data
        --------------------------------------------------
        UPDATE Academic.Question_Pool
        SET
            QuestionText = ISNULL(@QuestionText, QuestionText),
            Best_Accepted_Answer = ISNULL(@BestAcceptedAnswer, Best_Accepted_Answer)
        WHERE QuestionID = @QuestionID;

        --------------------------------------------------
        -- If MCQ → Replace All Choices
        --------------------------------------------------
        IF @QuestionType = 'MCQ'
        BEGIN
            IF @CorrectChoiceNumber NOT BETWEEN 1 AND 4
                THROW 51008, 'MCQ must have one correct choice (1-4).', 1;

            -- Delete old choices
            DELETE  FROM  Academic.Question_Choices
            WHERE QuestionID = @QuestionID;

            -- Insert new choices
            INSERT INTO Academic.Question_Choices
            (QuestionID, ChoiceText, IsCorrectChoice, isDeleted)
            VALUES
            (@QuestionID, @Choice1, CASE WHEN @CorrectChoiceNumber = 1 THEN 1 ELSE 0 END, 0),
            (@QuestionID, @Choice2, CASE WHEN @CorrectChoiceNumber = 2 THEN 1 ELSE 0 END, 0),
            (@QuestionID, @Choice3, CASE WHEN @CorrectChoiceNumber = 3 THEN 1 ELSE 0 END, 0),
            (@QuestionID, @Choice4, CASE WHEN @CorrectChoiceNumber = 4 THEN 1 ELSE 0 END, 0);
        END

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END
GO
--Stored Procedure To Delete Question
CREATE OR ALTER PROC Academic.sp_DeleteQuestion
@QuestionID INT,
@QuestionType NVARCHAR (20)
AS 
BEGIN
    SET NOCOUNT ON ;
    SET XACT_ABORT ON ;
    BEGIN TRY
    IF NOT EXISTS (
            SELECT 1 
            FROM Academic.Question_Pool
            WHERE QuestionID = @QuestionID
              AND IsDeleted = 0
        )
            THROW 51009, 'Question not found.', 1;
  BEGIN TRANSACTION;
  UPDATE [Academic].[Question_Pool]
  SET [isDeleted]=1
  WHERE [QuestionID] = @QuestionID;
  IF (@QuestionType = 'MCQ')
  BEGIN
   UPDATE [Academic].[Question_Choices]
  SET [isDeleted]=1
  WHERE [QuestionID] = @QuestionID;
  END
  COMMIT TRANSACTION;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
     THROW;
  END CATCH

END
