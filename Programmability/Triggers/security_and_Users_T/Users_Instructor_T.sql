-- here we create triggers for the Instructor table to log changes and handle cascading deletes to maintain data integrity and auditability.

-- INSERT Trigger
CREATE OR ALTER TRIGGER Users.trg_Instructor_Insert
ON Users.Instructor 
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Id INT, @vals NVARCHAR(MAX);
    SELECT @Id = InstructorID FROM inserted;
    SELECT @vals = CONCAT('Salary=', Salary, '; Office=', ISNULL(Office,''), '; IsManager=', Is_Manager) FROM inserted;

    EXEC Ops.usp_LogAudit @SchemaName = 'Users', @TableName = 'Instructor', @Operation = 'INSERT', @KeyValue = @Id, @Values = @vals;
END;
GO

-- UPDATE Trigger
CREATE OR ALTER TRIGGER Users.trg_Instructor_Update
ON Users.Instructor 
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Id INT, @vals NVARCHAR(MAX);
    SELECT @Id = InstructorID FROM inserted;
    SELECT @vals = CONCAT('New Sal=', i.Salary, '; Office=', i.Office, ' | Old Sal=', d.Salary) 
    FROM inserted i JOIN deleted d ON i.InstructorID = d.InstructorID;

    EXEC Ops.usp_LogAudit @SchemaName = 'Users', @TableName = 'Instructor', @Operation = 'UPDATE', @KeyValue = @Id, @Values = @vals;
END;
GO

-- DELETE Trigger (Cascading to Person/Account)
CREATE OR ALTER TRIGGER Users.trg_Instructor_Delete
ON Users.Instructor 
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsId INT;
    DECLARE delete_cursor CURSOR FOR SELECT InstructorID FROM deleted;

    OPEN delete_cursor;
    FETCH NEXT FROM delete_cursor INTO @InsId;
    WHILE @@FETCH_STATUS = 0
    BEGIN

        DECLARE @AccId INT = (SELECT AccountId FROM Users.Person WHERE PersonId = @InsId);
        
        EXEC Users.usp_DeleteAccount @TargetAccountId = @AccId;

        EXEC Ops.usp_LogAudit @SchemaName = 'Users', @TableName = 'Instructor', @Operation = 'DELETE', @KeyValue = @InsId, @Values = 'Instructor deleted via cascading Account SP';
        FETCH NEXT FROM delete_cursor INTO @InsId;
    END;
    CLOSE delete_cursor; DEALLOCATE delete_cursor;
END;
GO