use [ExamSystemDB];
GO 
-- DROP TABLE FIRST 
DROP TABLE IF EXISTS Ops.AuditLog ;
GO 
-- CREATE AUDIT LOG TABLE 
CREATE TABLE Ops.AuditLog
(
	AuditId INT IDENTITY (1,1) PRIMARY KEY ,
	SchemaName NVARCHAR(50) NOT NULL,
	TableName NVARCHAR(50) NOT NULL,
	Operation NVARCHAR(10) NOT NULL,
	KeyValues NVARCHAR(MAX) NOT NULL,
	ChangedBy NVARCHAR(100) NOT NULL DEFAULT SUSER_SNAME()  ,
	ChangedAt DATETIME  NOT NULL DEFAULT GETDATE(),
	Details NVARCHAR(MAX) NULL
);
GO

--create stored procedure Org.sp_ManageBranch CRUD with soft-delete
CREATE OR ALTER PROC Org.sp_ManageBranch
	@ACTION NVARCHAR(10),
	@BranchID INT = NULL ,
	@BranchName NVARCHAR(50) = NULL
AS 
begin 
	SET NOCOUNT ON ;
	IF @ACTION = 'INSERT'
		BEGIN 
		INSERT INTO [Org].[Branch] ([BranchName] ,[IsDeleted])
		VALUES (@BranchName, 0)
		PRINT 'Branch Created Successfully';
	END 
	IF @ACTION ='UPDATE'
	BEGIN 
	UPDATE [Org].[Branch]
	SET
	[BranchName] = ISNULL(@BranchName,[BranchName])
	WHERE [BranchId] = @BranchID AND [IsDeleted] = 0
	PRINT 'Branch Updated Successfully';
	END
	IF @ACTION ='DELETE'
	BEGIN 
		UPDATE [Org].[Branch] 
		SET 
        [IsDeleted] = 1
		WHERE [BranchId] = @BranchID
		PRINT 'Branch Deleted (Soft Delete) Successfully';
	END
	IF @ACTION ='SELECT'
	BEGIN 
		SELECT [BranchId],[BranchName] 
		FROM [Org].[Branch]
		WHERE [IsDeleted] = 0 ;
		END
END
GO 
--create stored procedure Org.sp_ManageDepartment CRUD with soft-delete
CREATE OR ALTER PROC Org.sp_ManageDepartment 
	@ACTION NVARCHAR(10),
	@DepartmentID INT = NULL ,
	@DepartmentName NVARCHAR(50) = NULL
AS 
BEGIN 
	SET NOCOUNT ON ;
	IF @ACTION = 'INSERT'
		BEGIN 
		INSERT INTO  [Org].[Department]([DepartmentName] ,[IsDeleted])
		VALUES (@DepartmentName, 0)
		PRINT 'Department Created Successfully';
	END 
	IF @ACTION ='UPDATE'
	BEGIN 
	UPDATE [Org].[Department]
	SET
	 [DepartmentName]= ISNULL(@DepartmentName,[DepartmentName])
	WHERE [DepartmentId] = @DepartmentID AND [IsDeleted] = 0 ;
	PRINT 'Department Updated Successfully';
	end
	IF @ACTION ='DELETE'
	BEGIN 
		UPDATE [Org].[Department]
		SET 
        [IsDeleted] = 1
		WHERE [DepartmentId] = @DepartmentID ;
		PRINT 'Department Deleted (Soft Delete) Successfully';
	END
	IF @ACTION ='SELECT'
	BEGIN
	SELECT [DepartmentId],[DepartmentName]
	FROM [Org].[Department]
	WHERE [IsDeleted] = 0;
	END
END
GO 
--create stored procedure Org.sp_ManageTrack CRUD with soft-delete
CREATE OR ALTER PROC Org.sp_ManageTrack
@ACTION NVARCHAR(10),
@TrackID INT =NULL,
@DepartmentID INT = NULL,
@TrackName NVARCHAR(50)= NULL
AS
BEGIN 
	SET NOCOUNT ON;
	IF @ACTION = 'INSERT'
		BEGIN 
		INSERT INTO [Org].[Track]( [DepartmentId], [TrackName],[IsDeleted])
		VALUES (@DepartmentID,@TrackName, 0)
		PRINT 'Track Created Successfully';
	END 
	IF @ACTION ='UPDATE'
	BEGIN 
	UPDATE [Org].[Track]
	SET

	[DepartmentId] = ISNULL(@DepartmentID,[DepartmentId]),
	[TrackName] = ISNULL(@TrackName, [TrackName])

	WHERE [TrackId] = @TrackID AND [IsDeleted] = 0 ;
	PRINT 'Track Updated Successfully';
	end
	IF @ACTION ='DELETE'
	BEGIN 
		UPDATE [Org].[Track]
		SET 
        [IsDeleted] = 1
		WHERE [TrackId] = @TrackID  ;
		PRINT 'Track Deleted (Soft Delete) Successfully';
	END
	IF @ACTION ='SELECT'
	BEGIN
	SELECT [TrackId],[DepartmentId],[TrackName]
	FROM [Org].[Track]
	WHERE [IsDeleted] =0;
	END
END
GO 
--create stored procedure Org.sp_ManageIntake CRUD with soft-delete
CREATE OR ALTER PROC Org.sp_ManageIntake
@ACTION NVARCHAR(10),
@IntakeID INT = NULL,
@IntakeYear INT = NULL,
@IntakeSemester NVARCHAR(20) = NULL 
AS 
BEGIN 
	SET NOCOUNT ON ;
	IF @ACTION = 'INSERT'
		BEGIN 
			INSERT INTO [Org].[Intake] ([IntakeYear],[IntakeSemester],[IsDeleted])
			VALUES (@IntakeYear,@IntakeSemester,0);
			PRINT 'Intake Created Successfully'
		END
		IF @ACTION ='UPDATE'
		BEGIN
			UPDATE [Org].[Intake]
			SET [IntakeYear] = ISNULL(@IntakeYear,[IntakeYear]),
			[IntakeSemester] = ISNULL(@IntakeSemester,[IntakeSemester])
			WHERE [IntakeId] = @IntakeID AND [IsDeleted] = 0 ;
			PRINT 'Intake Updated Successfully' ;
			END 
		IF @ACTION = 'DELETE '
		BEGIN
			UPDATE [Org].[Intake]
			SET [IsDeleted] =1 
			WHERE [IntakeId] = @IntakeID
			PRINT 'Intake Deleted Successfully' ;
			
		END
		IF @ACTION ='SELECT'
		BEGIN
			SELECT [IntakeId] ,[IntakeYear] ,[IntakeSemester] 
			FROM [Org].[Intake]
			WHERE [IsDeleted] =0 ;
		END
END
GO
--create stored procedure Org.sp_ManageIntakeTrack CRUD with soft-delete
CREATE OR ALTER PROC Org.sp_ManageIntakeTrack
@ACTION NVARCHAR(10) ,
@IntakeID INT =NULL ,
@TrackID INT = NULL
AS 
BEGIN
	SET NOCOUNT ON ;
	IF @ACTION = 'INSERT'
	BEGIN
		IF EXISTS(SELECT 1 FROM[Org].[Intake_Track] WHERE [IntakeId] =@IntakeID AND [TrackId] = @TrackID )
		BEGIN 
			UPDATE [Org].[Intake_Track] 
			SET [IsDeleted] =0;

			
		END
		ELSE
		BEGIN
			INSERT INTO [Org].[Intake_Track] ([IntakeId],[TrackId] ,[IsDeleted])
			VALUES (@IntakeID,@TrackID ,0);
			PRINT 'IntakeTrack Created Successfully ';
		END
	END
	IF @ACTION ='DELETE'
	BEGIN 
			UPDATE [Org].[Intake_Track] 
			SET [IsDeleted] =1
			WHERE [IntakeId]= @IntakeID AND [TrackId] =@TrackID;
			PRINT 'IntakeTrack Deleted Successfully ';
	end
	IF @ACTION ='SELECT'
	BEGIN
		SELECT [IntakeId] ,[TrackId] FROM [Org].[Intake_Track]
		WHERE [IsDeleted] =0 ;
	END
	
	
END
GO 

