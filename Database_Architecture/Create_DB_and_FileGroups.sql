IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = N'ExamSystemDB')
BEGIN
    
    CREATE DATABASE [ExamSystemDB]
    ON 
    PRIMARY (
        NAME = N'ExamSystemDB_Primary',
        FILENAME = N'C:\SQLProject\SQLData\ExamSystemDB_Primary.mdf', 
        SIZE = 64MB,
        MAXSIZE = 2048MB,
        FILEGROWTH = 32MB
    ),
    FILEGROUP FG_Lookup (
        NAME = N'ExamSystemDB_FG_Lookup',
        FILENAME = N'C:\SQLProject\SQLData\ExamSystemDB_FG_Lookup.ndf',
        SIZE = 32MB,
        MAXSIZE = 512MB,
        FILEGROWTH = 16MB
    ),
    FILEGROUP FG_MasterData (
        NAME = N'ExamSystemDB_FG_MasterData',
        FILENAME = N'C:\SQLProject\SQLData\ExamSystemDB_FG_MasterData.ndf',
        SIZE = 64MB,
        MAXSIZE = 2048MB,
        FILEGROWTH = 32MB
    ),
    FILEGROUP FG_Transactional (
        NAME = N'ExamSystemDB_FG_Transactional',
        FILENAME = N'C:\SQLProject\SQLData\ExamSystemDB_FG_Transactional.ndf',
        SIZE = 64MB,
        MAXSIZE = 2048MB,
        FILEGROWTH = 32MB
    ),
    FILEGROUP FG_Indexes (
        NAME = N'ExamSystemDB_FG_Indexes',
        FILENAME = N'C:\SQLProject\SQLData\ExamSystemDB_FG_Indexes.ndf', 
        SIZE = 32MB,
        MAXSIZE = 1024MB,
        FILEGROWTH = 16MB
    )
    LOG ON (
        NAME = N'ExamSystemDB_Log',
        FILENAME = N'C:\SQLProject\SQLLogs\ExamSystemDB_Log.ldf', 
        SIZE = 64MB,
        MAXSIZE = 512MB,
        FILEGROWTH = 32MB
    );
END
GO

-- Set default filegroup for new objects to FG_MasterData
ALTER DATABASE [ExamSystemDB] MODIFY FILEGROUP FG_MasterData DEFAULT;
GO
