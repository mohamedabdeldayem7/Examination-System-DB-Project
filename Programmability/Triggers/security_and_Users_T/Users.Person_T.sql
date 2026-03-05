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

-- INSTEAD OF DELETE triggers (prevent physical deletes; route to stored procedures)
CREATE OR ALTER TRIGGER Users.trg_Person_INSTEAD_OF_DELETE
ON Users.Person
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PersonId INT;
    DECLARE @Username NVARCHAR(100);

    DECLARE del_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT d.PersonId, a.Username
    FROM deleted AS d
        LEFT JOIN Users.Account AS a ON a.AccountId = d.AccountId;

    OPEN del_cursor;
    FETCH NEXT FROM del_cursor INTO @PersonId, @Username;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            EXEC Users.usp_DeletePerson @PersonId = @PersonId, @Username = @Username;
        END TRY
        BEGIN CATCH
            DECLARE @err NVARCHAR(4000) = ERROR_MESSAGE();
            IF OBJECT_ID('Ops.usp_LogAudit','P') IS NOT NULL
                EXEC Ops.usp_LogAudit @SchemaName='Users', @TableName='Person', @Operation='DELETE_TRIGGER_ERROR', @KeyValue=@PersonId, @Values=@err;
        END CATCH
        FETCH NEXT FROM del_cursor INTO @PersonId, @Username;
    END
    CLOSE del_cursor; DEALLOCATE del_cursor;
END;
GO