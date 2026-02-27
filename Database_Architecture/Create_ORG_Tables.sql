USE [ExamSystemDB];
GO

-- Drop tables first
DROP TABLE IF EXISTS Org.Intake_Track;
GO

DROP TABLE IF EXISTS Org.Intake;
GO

DROP TABLE IF EXISTS Org.Track;
GO

DROP TABLE IF EXISTS Org.Department;
GO

DROP TABLE IF EXISTS Org.Branch;
GO

-- Org.Branch 
CREATE TABLE Org.Branch (
    BranchId INT IDENTITY(1,1) PRIMARY KEY,
    BranchName NVARCHAR(100) NOT NULL,
    IsDeleted BIT NOT NULL DEFAULT 0
) ON FG_Lookup;
GO

-- Org.Department
CREATE TABLE Org.Department (
    DepartmentId INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentName NVARCHAR(100) NOT NULL,
    IsDeleted BIT NOT NULL DEFAULT 0,
) ON FG_Lookup;
GO

-- Org.Track
CREATE TABLE Org.Track (
    TrackId INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentId INT NULL,
    TrackName NVARCHAR(200) NOT NULL,
    IsDeleted BIT NOT NULL DEFAULT 0,
    CONSTRAINT FK_Track_Department FOREIGN KEY (DepartmentId) REFERENCES Org.Department(DepartmentId) ON DELETE SET NULL,
) ON FG_Lookup;
GO


-- Org.Intake
CREATE TABLE Org.Intake (
    IntakeId INT IDENTITY(1,1) PRIMARY KEY,
    IntakeYear INT NOT NULL,
    IntakeSemester NVARCHAR(20) NOT NULL,
    IsDeleted BIT NOT NULL DEFAULT 0,
) ON FG_Lookup;
GO

-- Org.Intake_Track
CREATE TABLE Org.Intake_Track (
    IntakeId    INT NOT NULL,
    TrackId     INT NOT NULL,
    IsDeleted BIT NOT NULL DEFAULT 0,
    CONSTRAINT PK_Intake_Track PRIMARY KEY (IntakeId, TrackId),
    CONSTRAINT FK_IntakeTrack_Intake FOREIGN KEY (IntakeId) REFERENCES Org.Intake(IntakeId) ON DELETE CASCADE,
    CONSTRAINT FK_IntakeTrack_Track FOREIGN KEY (TrackId) REFERENCES Org.Track(TrackId) ON DELETE CASCADE
) ON FG_Lookup;
GO

