USE ExamSystemDB
GO


DROP TABLE IF EXISTS Users.Person;
GO 

DROP TABLE IF EXISTS Users.Account;
GO

-- Users.Account
CREATE TABLE Users.Account (
    AccountId INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(50) NOT NULL UNIQUE,
    Email NVARCHAR(50) NULL UNIQUE,
    Password VARBINARY(20) NOT NULL,
    Role NVARCHAR(20) NOT NULL,           -- Admin, Instructor, Student, Manager
    IsActive BIT NOT NULL DEFAULT 1,
    LastLoginTime DATETIME NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE()
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