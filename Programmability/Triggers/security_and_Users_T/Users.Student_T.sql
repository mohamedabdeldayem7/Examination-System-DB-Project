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

-- DELETE Trigger (Cascading to Account)
CREATE OR ALTER TRIGGER Users.trg_Student_Delete
ON Users.Student INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @StdId INT;
    DECLARE delete_cursor CURSOR FOR SELECT StudentID FROM deleted;

    OPEN delete_cursor;
    FETCH NEXT FROM delete_cursor INTO @StdId;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @AccId INT = (SELECT AccountId FROM Users.Person WHERE PersonId = @StdId);
        EXEC Users.usp_DeleteAccount @TargetAccountId = @AccId;

        EXEC Ops.usp_LogAudit @SchemaName = 'Users', @TableName = 'Student', @Operation = 'DELETE', @KeyValue = @StdId, @Values = 'Student deleted via cascading Account SP';
        FETCH NEXT FROM delete_cursor INTO @StdId;
    END;
    CLOSE delete_cursor; DEALLOCATE delete_cursor;
END;
GO