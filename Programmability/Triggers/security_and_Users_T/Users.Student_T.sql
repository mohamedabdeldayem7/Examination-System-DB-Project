-- here we define triggers for the Users.Student table to log changes and handle cascading deletes to the Account table when a student is deleted.

-- INSERT Trigger
CREATE OR ALTER TRIGGER Users.trg_Student_Insert
ON Users.Student 
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Id INT, @vals NVARCHAR(MAX);
    SELECT @Id = StudentID FROM inserted;
    SELECT @vals = CONCAT('TrackID=', TrackID, '; IntakeID=', IntakeID, '; BranchID=', BranchID) FROM inserted;

    EXEC Ops.usp_LogAudit @SchemaName = 'Users', @TableName = 'Student', @Operation = 'INSERT', @KeyValue = @Id, @Values = @vals;
END;
GO

-- UPDATE Trigger
CREATE OR ALTER TRIGGER Users.trg_Student_Update
ON Users.Student 
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Id INT, @vals NVARCHAR(MAX);
    SELECT @Id = StudentID FROM inserted;
    SELECT @vals = CONCAT('Track Change: ', d.TrackID, ' -> ', i.TrackID, '; Branch Change: ', d.BranchID, ' -> ', i.BranchID) 
    FROM inserted i JOIN deleted d ON i.StudentID = d.StudentID;

    EXEC Ops.usp_LogAudit @SchemaName = 'Users', @TableName = 'Student', @Operation = 'UPDATE', @KeyValue = @Id, @Values = @vals;
END;
GO

-- INSTEAD OF DELETE Trigger: calls stored procedure to handle cascading deletes and soft-deletes
CREATE OR ALTER TRIGGER Users.trg_Student_INSTEAD_OF_DELETE
ON Users.Student
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StudentId INT;
    DECLARE @Username NVARCHAR(100);

    DECLARE del_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT d.StudentID, a.Username
    FROM deleted AS d
    LEFT JOIN Users.Person AS p ON p.PersonId = d.StudentID
    LEFT JOIN Users.Account AS a ON a.AccountId = p.AccountId;

    OPEN del_cursor;
    FETCH NEXT FROM del_cursor INTO @StudentId, @Username;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            EXEC Users.usp_DeleteStudent @StudentId = @StudentId, @Username = @Username;
        END TRY
        BEGIN CATCH
            DECLARE @err NVARCHAR(4000) = ERROR_MESSAGE();
            IF OBJECT_ID('Ops.usp_LogAudit','P') IS NOT NULL
                EXEC Ops.usp_LogAudit @SchemaName='Users', @TableName='Student', @Operation='DELETE_TRIGGER_ERROR', @KeyValue=@StudentId, @Values=@err;
        END CATCH
        FETCH NEXT FROM del_cursor INTO @StudentId, @Username;
    END
    CLOSE del_cursor; DEALLOCATE del_cursor;
END;
