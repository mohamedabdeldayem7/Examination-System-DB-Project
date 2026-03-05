-- This script creates triggers for the Users.Account table to log changes to an audit log.

-- INSERT trigger
CREATE OR ALTER TRIGGER Users.trg_Account_Insert
ON Users.Account
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @AccountId INT, @vals NVARCHAR(MAX);

    SELECT @AccountId = AccountId FROM inserted;

    -- Build a concise values string 
    SELECT @vals = CONCAT('Username=', Username, '; Email=', ISNULL(Email,''), '; Role=', Role, '; IsActive=', IsActive)
    FROM inserted;

    EXEC Ops.usp_LogAudit @SchemaName = 'Users', @TableName = 'Account', @Operation = 'INSERT', @KeyValue = @AccountId, @Values = @vals;
END;
GO

-- UPDATE trigger
CREATE OR ALTER TRIGGER Users.trg_Account_Update
ON Users.Account
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @AccountId INT, @vals NVARCHAR(MAX);

    SELECT @AccountId = AccountId FROM inserted;

    -- Log which columns changed (simple approach)
    SELECT @vals = CONCAT(
        'Username=', i.Username, '; Email=', ISNULL(i.Email,''), '; Role=', i.Role,
        '; IsActive=', i.IsActive, '; Last login time=', ISNULL(CONVERT(NVARCHAR(20), i.LastLoginTime, 120), 'NULL'), 
        ' | Old values: Username=', d.Username, '; Email=', ISNULL(d.Email,''), '; Role=', d.Role,
        '; IsActive=', d.IsActive, 'Last login time=', ISNULL(CONVERT(NVARCHAR(20), d.LastLoginTime, 120), 'NULL')
    )
    FROM inserted i, deleted d;

    EXEC Ops.usp_LogAudit @SchemaName = 'Users', @TableName = 'Account', @Operation = 'UPDATE', @KeyValue = @AccountId, @Values = @vals;
END;
GO

-- DELETE trigger
CREATE OR ALTER TRIGGER Users.trg_Account_Delete
ON Users.Account
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- declare variables to hold deleted values
    DECLARE @Id INT, @User NVARCHAR(100), @Role NVARCHAR(50), @LogVals NVARCHAR(MAX);

    DECLARE delete_cursor CURSOR FOR 
    SELECT AccountId, Username, [Role] FROM deleted;

    OPEN delete_cursor;
    FETCH NEXT FROM delete_cursor INTO @Id, @User, @Role;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- excute the delete stored procedure to handle cascading deletes and business logic
        EXEC Users.usp_DeleteAccount @TargetUsername = @User, @TargetAccountId = @Id;

        -- for audit log, we can only log the username and role since the account will be deleted
        SET @LogVals = CONCAT('Deleted Username=', @User, '; Role=', @Role);

        -- log the delete operation with the account id as key value and the username and role in values
        EXEC Ops.usp_LogAudit 
            @SchemaName = 'Users', 
            @TableName = 'Account', 
            @Operation = 'DELETE', 
            @KeyValue = @Id, 
            @Values = @LogVals;

        FETCH NEXT FROM delete_cursor INTO @Id, @User, @Role;
    END;

    CLOSE delete_cursor;
    DEALLOCATE delete_cursor;
END;
GO