-- Triggers for Users.Person table

-- INSERT Trigger
CREATE OR ALTER TRIGGER Users.trg_Person_Insert
ON Users.Person AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Id INT, @vals NVARCHAR(MAX);
    SELECT @Id = PersonId FROM inserted;
    SELECT @vals = CONCAT('Name=', FirstName, ' ', LastName, '; SSN=', ISNULL(SSN,''), '; Phone=', ISNULL(Phone,'')) FROM inserted;

    EXEC Ops.usp_LogAudit @SchemaName = 'Users', @TableName = 'Person', @Operation = 'INSERT', @KeyValue = @Id, @Values = @vals;
END;
GO

-- UPDATE Trigger
CREATE OR ALTER TRIGGER Users.trg_Person_Update
ON Users.Person 
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Id INT, @vals NVARCHAR(MAX);
    SELECT @Id = PersonId FROM inserted;
    SELECT @vals = CONCAT(
        'New: ', i.FirstName, ' ', i.LastName, '; Phone=', i.Phone, 
        ' | Old: ', d.FirstName, ' ', d.LastName, '; Phone=', d.Phone
    ) FROM inserted i JOIN deleted d ON i.PersonId = d.PersonId;

    EXEC Ops.usp_LogAudit @SchemaName = 'Users', @TableName = 'Person', @Operation = 'UPDATE', @KeyValue = @Id, @Values = @vals;
END;
GO

-- DELETE Trigger (Cascading to Account)
CREATE OR ALTER TRIGGER Users.trg_Person_Delete
ON Users.Person 
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @PId INT, @AccId INT;
    DECLARE delete_cursor CURSOR FOR SELECT PersonId, AccountId FROM deleted;

    OPEN delete_cursor;
    FETCH NEXT FROM delete_cursor INTO @PId, @AccId;
    WHILE @@FETCH_STATUS = 0
    BEGIN

        EXEC Users.usp_DeleteAccount @TargetAccountId = @AccId;
        
        DECLARE @vals NVARCHAR(MAX);
        SELECT @vals = CONCAT('PersonId=', @PId, '; AccountId=', @AccId, '; Deleted');
        EXEC Ops.usp_LogAudit @SchemaName = 'Users', @TableName = 'Person', @Operation = 'DELETE', @KeyValue = @PId, @Values = 'Person entry processed via Account Delete logic';
        FETCH NEXT FROM delete_cursor INTO @PId, @AccId;
    END;
    CLOSE delete_cursor; DEALLOCATE delete_cursor;
END;
GO