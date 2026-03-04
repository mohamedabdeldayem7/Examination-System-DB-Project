

-----------------------------------------------------------------------------------
--Department---------------------------------------------------------------------------------------
--create stored procedure to select Department table 
CREATE OR ALTER PROC Org.sp_SelectDepartment
AS
BEGIN
    SET NOCOUNT ON;
    SELECT [DepartmentId], [DepartmentName],[IsDeleted]
    FROM [Org].[Department]
    WHERE [IsDeleted] = 0;
END
GO
--create stored procedure to Insert New Department 
CREATE OR ALTER PROC Org.sp_InsertDepartment
    @DepartmentName NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
    IF @DepartmentName IS NULL
        THROW 50001, 'DepartmentName is required.', 1;
	IF EXISTS (SELECT 1 FROM [Org].[Department] WHERE [DepartmentName] = @DepartmentName AND IsDeleted = 0)
		 THROW 50002, 'DepartmentName is EXIST', 1;

    INSERT INTO [Org].[Department] ([DepartmentName], [IsDeleted])
    VALUES (@DepartmentName, 0);
    PRINT 'Department Created Successfully';
	END TRY 
	BEGIN CATCH
        THROW;
    END CATCH
END
GO
--create stored procedure to Update New Department 
CREATE OR ALTER PROC Org.sp_UpdateDepartment
    @DepartmentID INT,
    @DepartmentName NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
    
    IF @DepartmentID IS NULL
        THROW 50003, 'DepartmentID is required.', 1;
	IF NOT EXISTS (
    SELECT 1 
    FROM [Org].[Department] 
    WHERE [DepartmentId] = @DepartmentID 
      AND [IsDeleted] = 0
    )
    THROW 50020, 'Department not found.', 1;

    UPDATE [Org].[Department]
    SET [DepartmentName] = ISNULL(@DepartmentName, [DepartmentName])
    WHERE [DepartmentId] = @DepartmentID
      AND [IsDeleted] = 0;
    PRINT 'Department Updated Successfully';
	END TRY 
	BEGIN CATCH
        THROW;
    END CATCH
END
GO
--create stored procedure to Delete Department 
CREATE OR ALTER PROC Org.sp_DeleteDepartment
    @DepartmentID INT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
    IF @DepartmentID IS NULL
        THROW 50004, 'DepartmentID is required.', 1;
	IF NOT EXISTS (
    SELECT 1 
    FROM [Org].[Department] 
    WHERE [DepartmentId] = @DepartmentID
      AND [IsDeleted] = 0
   )
    THROW 50021, 'Department not found.', 1;
    UPDATE [Org].[Department]
    SET [IsDeleted] = 1
    WHERE [DepartmentId] = @DepartmentID;
	PRINT 'Department Deleted (Soft Delete) Successfully';
	END TRY
	BEGIN CATCH
        THROW;
    END CATCH
END
GO
---Branch-----------------------------------------------------------------------------------------
--create stored procedure to select Branch table 
CREATE OR ALTER PROC Org.sp_SelectBranch
AS
BEGIN
    SET NOCOUNT ON;
    SELECT [BranchId], [BranchName]
    FROM [Org].[Branch]
    WHERE [IsDeleted] = 0;
END
GO
--create stored procedure to Insert New Branch
CREATE OR ALTER PROC Org.sp_InsertBranch
    @BranchName NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
    IF @BranchName IS NULL
        THROW 50005, 'BranchName is required.', 1;
	IF EXISTS (SELECT 1 FROM [Org].[Branch] WHERE [BranchName] = @BranchName AND IsDeleted = 0)
		 THROW 50006, 'BranchName is EXIST', 1;

    INSERT INTO [Org].[Branch] ([BranchName], [IsDeleted])
    VALUES (@BranchName, 0);
    PRINT 'Branch Created Successfully';
	END TRY 
	BEGIN CATCH
        THROW;
    END CATCH
END
GO
--create stored procedure to Update New Branch 
CREATE OR ALTER PROC Org.sp_UpdateBranch
    @BranchID INT,
    @BranchName NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
    
    IF @BranchID IS NULL
        THROW 50007, 'BranchID is required.', 1;
	IF NOT EXISTS (
    SELECT 1 
    FROM [Org].[Branch] 
    WHERE [BranchId] = @BranchID 
      AND [IsDeleted] = 0
    )
	THROW 50022, 'Branch not found.', 1;


    UPDATE [Org].[Branch]
    SET [BranchName] = ISNULL(@BranchName, [BranchName])
    WHERE [BranchId] = @BranchID
      AND [IsDeleted] = 0;
    PRINT 'Branch Updated Successfully';
	END TRY 
	BEGIN CATCH
        THROW;
    END CATCH
END
GO
--create stored procedure to Delete Branch
CREATE OR ALTER PROC Org.sp_DeleteBranch
    @BranchID INT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
    IF @BranchID IS NULL
        THROW 50008, 'BranchID is required.', 1;
	IF NOT EXISTS (
    SELECT 1 
    FROM [Org].[Branch] 
    WHERE [BranchId] = @BranchID 
      AND [IsDeleted] = 0
    )
	THROW 50023, 'Branch not found.', 1;

    UPDATE [Org].[Branch]
    SET [IsDeleted] = 1
    WHERE [BranchId] = @BranchID;
	PRINT 'Branch Deleted (Soft Delete) Successfully';
	END TRY
	BEGIN CATCH
        THROW;
    END CATCH
END
GO
---Track----------------------------------------------------------------------------------------
--create stored procedure to select Track table 
CREATE OR ALTER PROC Org.sp_SelectTrack
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [TrackId], [DepartmentId], [TrackName]
    FROM [Org].[Track]
    WHERE [IsDeleted] = 0;
END
GO
--create stored procedure to Insert New Track
CREATE OR ALTER PROC Org.sp_InsertTrack
    @DepartmentID INT ,
    @TrackName NVARCHAR(50) 
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
    IF @DepartmentID IS NULL
        THROW 50010, 'DepartmentID is required.', 1;
	IF @TrackName IS NULL
        THROW 50011, 'TrackName is required.', 1;
IF NOT EXISTS (
    SELECT 1 
    FROM [Org].[Department]
    WHERE [DepartmentId] = @DepartmentID
      AND IsDeleted = 0
)
    THROW 50024, 'Department does not exist.', 1;

	IF EXISTS (SELECT 1 FROM [Org].[Track] WHERE [TrackName]= @TrackName AND IsDeleted = 0)
		 THROW 50012, 'TrackName is EXIST', 1;
	INSERT INTO [Org].[Track]( [DepartmentId], [TrackName],[IsDeleted])
		VALUES (@DepartmentID,@TrackName, 0)
		PRINT 'Track Created Successfully';
	END TRY 
	BEGIN CATCH
        THROW;
    END CATCH
END
GO
--create stored procedure to Update New Track 
CREATE OR ALTER PROC Org.sp_UpdateTrack
	@TrackID INT ,
    @DepartmentID INT,
    @TrackName NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
    
    IF @TrackID IS NULL
        THROW 50013, 'BranchID is required.', 1;

    UPDATE [Org].[Track]
	SET

	[DepartmentId] = ISNULL(@DepartmentID,[DepartmentId]),
	[TrackName] = ISNULL(@TrackName, [TrackName])

	WHERE [TrackId] = @TrackID AND [IsDeleted] = 0 ;
	PRINT 'Track Updated Successfully';
	END TRY 
	BEGIN CATCH
        THROW;
    END CATCH
END
GO
--create stored procedure to Delete Track
CREATE OR ALTER PROC Org.sp_DeleteTrack
    @TrackID INT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
    IF @TrackID IS NULL
        THROW 50014, 'TrackID is required.', 1;
   UPDATE [Org].[Track]
		SET 
        [IsDeleted] = 1
		WHERE [TrackId] = @TrackID  ;
		PRINT 'Track Deleted (Soft Delete) Successfully';
	END TRY
	BEGIN CATCH
        THROW;
    END CATCH
END
GO
--Intake ---------------------------------------------------------------------
--create stored procedure to select Intake table 
CREATE OR ALTER PROC Org.sp_SelectIntake
AS
BEGIN
    SET NOCOUNT ON;
	SELECT [IntakeId] ,[IntakeYear] ,[IntakeSemester] 
			FROM [Org].[Intake]
			WHERE [IsDeleted] =0 ;
END
GO
--create stored procedure to Insert New Track
CREATE OR ALTER PROC Org.sp_InsertIntake
   @IntakeYear INT ,
   @IntakeSemester NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
    IF  @IntakeYear IS NULL
        THROW 50030, 'IntakeYear is required.', 1;
	IF @IntakeSemester IS NULL
        THROW 50031, 'IntakeSemester is required.', 1;

	INSERT INTO [Org].[Intake] ([IntakeYear],[IntakeSemester],[IsDeleted])
			VALUES (@IntakeYear,@IntakeSemester,0);
			PRINT 'Intake Created Successfully';
	END TRY 
	BEGIN CATCH
        THROW;
    END CATCH
END
GO
--create stored procedure to Update New Intake 
CREATE OR ALTER PROC Org.sp_UpdateIntake
   @IntakeID INT ,
   @IntakeYear INT ,
   @IntakeSemester NVARCHAR(20) 
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
    
    IF @IntakeID IS NULL
        THROW 50032, 'IntakeID is required.', 1;
	IF NOT EXISTS (
    SELECT 1 
    FROM  [Org].[Intake]
    WHERE [IntakeId] = @IntakeID
      AND [IsDeleted] = 0
    )
	THROW 50033, 'Intake not found.', 1;

     UPDATE [Org].[Intake]
		SET [IntakeYear] = ISNULL(@IntakeYear,[IntakeYear]),
		[IntakeSemester] = ISNULL(@IntakeSemester,[IntakeSemester])
		WHERE [IntakeId] = @IntakeID AND [IsDeleted] = 0 ;
		PRINT 'Intake Updated Successfully' ;
	END TRY 
	BEGIN CATCH
        THROW;
    END CATCH
END 
GO
--create stored procedure to Delete Intake 
CREATE OR ALTER PROC Org.sp_DeleteIntake 
    @IntakeID INT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
    IF @IntakeID IS NULL
        THROW 50014, 'TrackID is required.', 1;
   UPDATE [Org].[Intake]
		SET 
        [IsDeleted] = 1
		WHERE [IntakeId] = @IntakeID  ;
		PRINT 'Intake Deleted (Soft Delete) Successfully';
	END TRY
	BEGIN CATCH
        THROW;
    END CATCH
END
GO

--Intack_Track--------------------------------------------------------------------------
--create stored procedure to select Intack_Track table 
CREATE OR ALTER PROC Org.sp_SelectIntack_Track
AS
BEGIN
    SET NOCOUNT ON;
	SELECT [IntakeId],[TrackId]
			FROM [Org].[Intake_Track]
			WHERE [IsDeleted] =0 ;
END
GO
--create stored procedure to Insert New Intack_Track
CREATE OR ALTER PROC Org.sp_InsertIntack_Track
@IntakeID INT ,
@TrackID INT 
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRY
    IF @IntakeID IS NULL
        THROW 50035, 'IntakeID is required.', 1;
    IF @TrackID IS NULL
       THROW 50036, 'TrackID is required.', 1;
    INSERT INTO [Org].[Intake_Track] ([IntakeId],[TrackId],[IsDeleted])
    VALUES (@IntakeID,@TrackID,0);


    END TRY
    BEGIN CATCH
        THROW;
    END CATCH

END
GO
--create stored procedure to Update New Intack_Track 
CREATE OR ALTER PROC Org.sp_UpdateIntack_Track
  @IntakeID INT =NULL,
  @TrackID INT =NULL
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
    
    
	IF NOT EXISTS (
    SELECT 1 
    FROM  [Org].[Intake]
    WHERE [IntakeId] = @IntakeID
      AND [IsDeleted] = 0
    )
	THROW 50033, 'Intake not found.', 1;

     UPDATE [Org].[Intake_Track]
		SET [TrackId] = ISNULL(@TrackID,[TrackId])
		WHERE [IntakeId] = @IntakeID AND [IsDeleted] = 0 ;
		PRINT 'TrackId Updated Successfully' ;
     UPDATE [Org].[Intake_Track]
		SET  [IntakeId]= ISNULL(@IntakeID,[IntakeId])
		WHERE [IntakeId]= @TrackID AND [IsDeleted] = 0 ;
		PRINT 'TrackId Updated Successfully' ;

	END TRY 
	BEGIN CATCH
        THROW;
    END CATCH
END 
GO 
--create stored procedure to Delete Intack_Track
CREATE OR ALTER PROC Org.sp_DeleteIntack_Track
  @IntakeID INT ,
  @TrackID INT 
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
    IF @IntakeID IS NULL
        THROW 50014, 'TrackID is required.', 1;
    IF @TrackID  IS NULL
        THROW 50014, 'TrackID  is required.', 1;
   UPDATE [Org].[Intake_Track]
		SET 
        [IsDeleted] = 1
		WHERE [IntakeId] = @IntakeID AND [TrackId]= @TrackID ;
		PRINT 'Intack_Track Deleted (Soft Delete) Successfully';
	END TRY
	BEGIN CATCH
        THROW;
    END CATCH
END
GO