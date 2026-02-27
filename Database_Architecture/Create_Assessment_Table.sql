use ExamSystemDB;

-------------------------------------------------------
-- TABLES — ASSESSMENT SCHEMA (FG_Transactional)
--------------------------------------------------------

CREATE TABLE Assessment.Exam(
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
    CONSTRAINT PK_Exam PRIMARY KEY (ExamID) ON FG_Transactional,
    CONSTRAINT FK_Exam_Course     FOREIGN KEY (CourseID)     REFERENCES Academic.Course(CourseID),
    CONSTRAINT FK_Exam_Instructor FOREIGN KEY (InstructorID) REFERENCES Users.Instructor(InstructorID),
    CONSTRAINT FK_Exam_Branch     FOREIGN KEY (BranchID)     REFERENCES Org.Branch(BranchID),
    CONSTRAINT FK_Exam_Track      FOREIGN KEY (TrackID)      REFERENCES Org.Track(TrackID),
    CONSTRAINT FK_Exam_Intake     FOREIGN KEY (IntakeID)     REFERENCES Org.Intake(IntakeID),
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
    CONSTRAINT FK_EQ_Exam     FOREIGN KEY (ExamID)     REFERENCES Assessment.Exam(ExamID),
    CONSTRAINT FK_EQ_Question FOREIGN KEY (QuestionID) REFERENCES Academic.Question_Pool(QuestionID),
    CONSTRAINT CK_EQ_Degree CHECK (Question_Degree > 0)
) ON FG_Transactional;
GO

CREATE TABLE Assessment.Student_Exam (
    StudentID  INT      NOT NULL,
    ExamID     INT      NOT NULL,
    Exam_Date  DATE     NOT NULL,
    Start_Time DATETIME NOT NULL,
    End_Time   DATETIME NOT NULL,
    CONSTRAINT PK_Student_Exam PRIMARY KEY (StudentID, ExamID) ON FG_Transactional,
    CONSTRAINT FK_SE_Student FOREIGN KEY (StudentID) REFERENCES Users.Student(StudentID),
    CONSTRAINT FK_SE_Exam    FOREIGN KEY (ExamID)    REFERENCES Assessment.Exam(ExamID)
) ON FG_Transactional;
GO

CREATE TABLE Assessment.Student_Answer (
    Answer_ID      INT IDENTITY(1,1),
    StudentID      INT           NOT NULL,
    ExamID         INT           NOT NULL,
    QuestionID     INT           NOT NULL,
    Student_Answer NVARCHAR(MAX) NULL,
    Is_Correct     BIT           NULL,
    Earned_Degree  DECIMAL(5,2)  NULL DEFAULT 0,
    CONSTRAINT PK_Student_Answer PRIMARY KEY (Answer_ID) ON FG_Transactional,
    CONSTRAINT FK_AS_StudentExam FOREIGN KEY (StudentID, ExamID)
        REFERENCES Assessment.Student_Exam(StudentID, ExamID),
    CONSTRAINT FK_AS_ExamQuestions FOREIGN KEY (ExamID, QuestionID)
        REFERENCES Assessment.Exam_Questions(ExamID, QuestionID),
    CONSTRAINT UQ_Answer_Unique UNIQUE (StudentID, ExamID, QuestionID)
) ON FG_Transactional;
GO

CREATE TABLE Assessment.Student_Exam_Result(
    ResultID    INT IDENTITY(1,1),
    StudentID   INT           NOT NULL,
    ExamID      INT           NOT NULL,
    CourseID    INT           NOT NULL,
    Total_Score DECIMAL(5,2)  NOT NULL DEFAULT 0,
    Grade       VARCHAR(5)    NULL,
    Pass_Fail   BIT           NULL,
    CONSTRAINT PK_Results PRIMARY KEY (ResultID) ON FG_Transactional,
    CONSTRAINT FK_Student_Exam_Result FOREIGN KEY (StudentID, ExamID)
        REFERENCES Assessment.Student_Exam(StudentID, ExamID),
    CONSTRAINT FK_Results_Course FOREIGN KEY (CourseID)
        REFERENCES Academic.Course(CourseID),
    CONSTRAINT UQ_Results_Unique UNIQUE (StudentID, ExamID)
) ON FG_Transactional;
GO


