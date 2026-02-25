use ExamSystemDB;

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
        REFERENCES Academic.Courses(CourseID),
    CONSTRAINT FK_Questions_Instructor FOREIGN KEY (InstructorID)
        REFERENCES Users.Instructors(InstructorID),
    CONSTRAINT CK_QuestionType CHECK (QuestionType IN ('MCQ','TrueFalse','Text'))
) ON FG_MasterData;
GO

CREATE TABLE Academic.Question_Choices (
    ChoiceID        INT IDENTITY(1,1),
    QuestionID      INT           NOT NULL,
    ChoiceText      NVARCHAR(MAX) NOT NULL,
    IsCorrectChoice BIT           NOT NULL DEFAULT 0,
    isDeleted       BIT           NOT NULL DEFAULT 0,
    CONSTRAINT PK_Choices PRIMARY KEY (ChoiceID) ON FG_MasterData,
    CONSTRAINT FK_Choices_Question FOREIGN KEY (QuestionID)
        REFERENCES Academic.Question_Pool(QuestionID)
) ON FG_MasterData;
GO

-- ================================================================
-- TABLES — ASSESSMENT SCHEMA (FG_Transactional)
-- ================================================================

CREATE TABLE Assessment.Exams (
    ExamID            INT IDENTITY(1,1),
    CourseID          INT           NOT NULL,
    InstructorID      INT           NOT NULL,
    BranchID          INT           NOT NULL,
    TrackID           INT           NOT NULL,
    IntakeID          INT           NOT NULL,
    ExamType          VARCHAR(20)   NOT NULL,
    Total_Time        INT           NOT NULL,
    Start_Time        DATETIME      NOT NULL,
    End_Time          DATETIME      NOT NULL,
    Allowance_Options NVARCHAR(200) NULL,
    isDeleted         BIT           NOT NULL DEFAULT 0,
    CONSTRAINT PK_Exams PRIMARY KEY (ExamID) ON FG_Transactional,
    CONSTRAINT FK_Exams_Course     FOREIGN KEY (CourseID)     REFERENCES Academic.Courses(CourseID),
    CONSTRAINT FK_Exams_Instructor FOREIGN KEY (InstructorID) REFERENCES Users.Instructors(InstructorID),
    CONSTRAINT FK_Exams_Branch     FOREIGN KEY (BranchID)     REFERENCES Org.Branch(BranchID),
    CONSTRAINT FK_Exams_Track      FOREIGN KEY (TrackID)      REFERENCES Org.Track(TrackID),
    CONSTRAINT FK_Exams_Intake     FOREIGN KEY (IntakeID)     REFERENCES Org.Intake(IntakeID),
    CONSTRAINT CK_ExamType CHECK (ExamType IN ('Exam','Corrective')),
    CONSTRAINT CK_ExamTime CHECK (End_Time > Start_Time)
) ON FG_Transactional;
GO

CREATE TABLE Assessment.Exam_Questions (
    ExamID          INT NOT NULL,
    QuestionID      INT NOT NULL,
    Question_Order  INT NOT NULL,
    Question_Degree DECIMAL(5,2) NOT NULL,
    CONSTRAINT PK_Exam_Questions PRIMARY KEY (ExamID, QuestionID) ON FG_Transactional,
    CONSTRAINT FK_EQ_Exam     FOREIGN KEY (ExamID)     REFERENCES Assessment.Exams(ExamID),
    CONSTRAINT FK_EQ_Question FOREIGN KEY (QuestionID) REFERENCES Academic.Question_Pool(QuestionID),
    CONSTRAINT CK_EQ_Degree CHECK (Question_Degree > 0)
) ON FG_Transactional;
GO

CREATE TABLE Assessment.Student_Exams (
    StudentID  INT      NOT NULL,
    ExamID     INT      NOT NULL,
    Exam_Date  DATE     NOT NULL,
    Start_Time DATETIME NOT NULL,
    End_Time   DATETIME NOT NULL,
    CONSTRAINT PK_Student_Exams PRIMARY KEY (StudentID, ExamID) ON FG_Transactional,
    CONSTRAINT FK_SE_Student FOREIGN KEY (StudentID) REFERENCES Students.Student(StudentID),
    CONSTRAINT FK_SE_Exam    FOREIGN KEY (ExamID)    REFERENCES Assessment.Exams(ExamID)
) ON FG_Transactional;
GO

CREATE TABLE Assessment.Answer_Students (
    Answer_ID      INT IDENTITY(1,1),
    StudentID      INT           NOT NULL,
    ExamID         INT           NOT NULL,
    QuestionID     INT           NOT NULL,
    Student_Answer NVARCHAR(MAX) NULL,
    Is_Correct     BIT           NULL,
    Earned_Degree  DECIMAL(5,2)  NULL DEFAULT 0,
    CONSTRAINT PK_Answer_Students PRIMARY KEY (Answer_ID) ON FG_Transactional,
    CONSTRAINT FK_AS_StudentExam FOREIGN KEY (StudentID, ExamID)
        REFERENCES Assessment.Student_Exams(StudentID, ExamID),
    CONSTRAINT FK_AS_ExamQuestion FOREIGN KEY (ExamID, QuestionID)
        REFERENCES Assessment.Exam_Questions(ExamID, QuestionID),
    CONSTRAINT UQ_Answer_Unique UNIQUE (StudentID, ExamID, QuestionID)
) ON FG_Transactional;
GO

CREATE TABLE Assessment.Results_Exam_Students (
    ResultID    INT IDENTITY(1,1),
    StudentID   INT           NOT NULL,
    ExamID      INT           NOT NULL,
    CourseID    INT           NOT NULL,
    Total_Score DECIMAL(5,2)  NOT NULL DEFAULT 0,
    Grade       VARCHAR(5)    NULL,
    Pass_Fail   BIT           NULL,
    CONSTRAINT PK_Results PRIMARY KEY (ResultID) ON FG_Transactional,
    CONSTRAINT FK_Results_StudentExam FOREIGN KEY (StudentID, ExamID)
        REFERENCES Assessment.Student_Exams(StudentID, ExamID),
    CONSTRAINT FK_Results_Course FOREIGN KEY (CourseID)
        REFERENCES Academic.Courses(CourseID),
    CONSTRAINT UQ_Results_Unique UNIQUE (StudentID, ExamID)
) ON FG_Transactional;
GO