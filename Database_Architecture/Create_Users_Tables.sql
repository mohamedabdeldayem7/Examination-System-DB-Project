USE ExamSystemDB
GO

DROP TABLE IF EXISTS [Users].[Student]
GO

DROP TABLE IF EXISTS [Users].[Instructor]
GO

DROP TABLE IF EXISTS Users.Person;
GO 

DROP TABLE IF EXISTS Users.Account;
GO

-- Users.Account

CREATE TABLE Users.Account
(
    AccountId INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(100) COLLATE Latin1_General_CI_AS NOT NULL,
    Email NVARCHAR(256) COLLATE Latin1_General_CI_AS NULL,
    PasswordHash VARBINARY(512) NOT NULL, 
    PasswordSalt VARBINARY(128) NOT NULL,
    PasswordAlgo NVARCHAR(50)  NOT NULL DEFAULT('PBKDF2-SHA512'),
    PasswordIterations INT NOT NULL DEFAULT(100000), 
    IsActive BIT NOT NULL DEFAULT(1),
    LastLoginTime DATETIME2 NULL,
    Role NVARCHAR(50) NOT NULL, -- Admin, TrainingManager, Instructor, Student
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CreatedBy INT NULL,
    CONSTRAINT UQ_Account_Username UNIQUE (Username),
    CONSTRAINT UQ_Account_Email UNIQUE (Email),
    CONSTRAINT CHK_Account_Role CHECK (Role IN ('Admin','TrainingManager','Instructor','Student'))
) ON FG_MasterData;
GO


-- Users.Person
CREATE TABLE Users.Person (
    PersonId INT IDENTITY(1,1) PRIMARY KEY,
    AccountId INT NOT NULL,
    SSN NVARCHAR(14) NULL,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Phone NVARCHAR(11) NULL,
    IsDeleted BIT NOT NULL DEFAULT 0,
    CONSTRAINT FK_Person_Account FOREIGN KEY (AccountId) REFERENCES Users.Account(AccountId) ON DELETE CASCADE
) ON FG_MasterData;
GO


-- alter Person table to add unique constraints on Phone and SSN
ALTER TABLE Users.Person
ADD CONSTRAINT UQ_Person_Phone UNIQUE (Phone),
    CONSTRAINT UQ_Person_SSN UNIQUE (SSN);
GO
--Users.Student 
CREATE TABLE Users.Student 
( 
    StudentID INT PRIMARY KEY ,
    TrackID INT NULL,
    IntakeID INT NULL,
    BranchID INT NULL,
    CONSTRAINT FK_Student_Person FOREIGN KEY (StudentID) REFERENCES Users.Person(PersonId) ON DELETE CASCADE,
    CONSTRAINT FK_Student_Track FOREIGN KEY (TrackID) REFERENCES Org.Track(TrackId) ON DELETE SET NULL ,
    CONSTRAINT FK_Student_Intake FOREIGN KEY (IntakeID) REFERENCES Org.Intake(IntakeId) ON DELETE SET NULL,
    CONSTRAINT FK_Student_Branch FOREIGN KEY (BranchID) REFERENCES Org.Branch(BranchId) ON DELETE SET NULL

) ON FG_MasterData;

--Users.Instructor 
CREATE TABLE Users.Instructor 
( 
    InstructorID INT PRIMARY KEY ,
    Salary DECIMAL(10,2) NOT NULL ,
    HireDate DATE DEFAULT GETDATE(),
    Office varchar(50) ,
    Is_Manager BIT DEFAULT 0 
) ON FG_MasterData;

-- alter Instructor table to add foreign key constraint to Person table
ALTER TABLE Users.Instructor
ADD CONSTRAINT FK_Instructor_Person 
FOREIGN KEY (InstructorID) REFERENCES Users.Person (PersonID)
ON DELETE CASCADE
ON UPDATE CASCADE;

