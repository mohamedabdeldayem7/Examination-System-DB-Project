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

-- INSTEAD OF DELETE Trigger: calls stored procedure to handle cascading deletes and soft-deletes
CREATE OR ALTER TRIGGER Users.trg_Instructor_INSTEAD_OF_DELETE
ON Users.Instructor
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @InstructorId INT;
    DECLARE @Username NVARCHAR(100);

    DECLARE del_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT d.InstructorID, a.Username
    FROM deleted AS d
    LEFT JOIN Users.Person AS p ON p.PersonId = d.InstructorID
    LEFT JOIN Users.Account AS a ON a.AccountId = p.AccountId;

    OPEN del_cursor;
    FETCH NEXT FROM del_cursor INTO @InstructorId, @Username;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            EXEC Users.usp_DeleteInstructor @InstructorId = @InstructorId, @Username = @Username;
        END TRY
        BEGIN CATCH
            DECLARE @err NVARCHAR(4000) = ERROR_MESSAGE();
            IF OBJECT_ID('Ops.usp_LogAudit','P') IS NOT NULL
                EXEC Ops.usp_LogAudit @SchemaName='Users', @TableName='Instructor', @Operation='DELETE_TRIGGER_ERROR', @KeyValue=@InstructorId, @Values=@err;
        END CATCH
        FETCH NEXT FROM del_cursor INTO @InstructorId, @Username;
    END
    CLOSE del_cursor; DEALLOCATE del_cursor;
END;
GO
