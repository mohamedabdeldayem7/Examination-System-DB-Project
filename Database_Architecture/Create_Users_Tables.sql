USE ExamSystemDB
GO


DROP TABLE IF EXISTS Users.Person;
GO 

DROP TABLE IF EXISTS Users.Account;
GO

-- Users.Account
USE [ExamSystemDB];
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'Users.Account') AND type = 'U')
BEGIN
    CREATE TABLE Users.Account (
        AccountId INT IDENTITY(1,1) PRIMARY KEY,
        Username NVARCHAR(50) NOT NULL UNIQUE,
        Email NVARCHAR(256) NULL UNIQUE,
        Password NVARCHAR(256) NOT NULL,
        Role NVARCHAR(20) NOT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        LastLoginTime DATETIME2 NULL,
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT CHK_Account_Role CHECK (Role IN ('Admin','Instructor','Student','Manager'))
    ) ON FG_MasterData;
END
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