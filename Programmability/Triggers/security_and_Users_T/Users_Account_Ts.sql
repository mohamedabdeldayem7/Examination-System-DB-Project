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
        '; IsActive=', i.IsActive, 'Last login time=', ISNULL(CONVERT(NVARCHAR(20), i.LastLoginTime, 120), 'NULL'), 
        'Old values: Username=', d.Username, '; Email=', ISNULL(d.Email,''), '; Role=', d.Role,
        '; IsActive=', d.IsActive, 'Last login time=', ISNULL(CONVERT(NVARCHAR(20), d.LastLoginTime, 120), 'NULL')
    )
    FROM inserted i, deleted d;

    EXEC Ops.usp_LogAudit @SchemaName = 'Users', @TableName = 'Account', @Operation = 'UPDATE', @KeyValue = @AccountId, @Values = @vals;
END;
GO

-- DELETE trigger
CREATE OR ALTER TRIGGER Users.trg_Account_Delete
ON Users.Account
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @AccountId INT, @vals NVARCHAR(MAX);

    SELECT @AccountId = AccountId FROM deleted;

    SELECT @vals = CONCAT('Deleted Username=', Username, '; Role=', Role)
    FROM deleted;

    EXEC Ops.usp_LogAudit @SchemaName = 'Users', @TableName = 'Account', @Operation = 'DELETE', @KeyValue = @AccountId, @Values = @vals;
END;
GO