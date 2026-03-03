
-- This trigger captures the last login time of users in the ExamSystemDB database. It updates the LastLoginTime column in the Users.Account table whenever a user logs in to the database. If there is an error during the update, it simply skips updating the last login time to avoid blocking logins.
CREATE OR ALTER TRIGGER tr_CaptureLastLogin_ExamSystem
ON ALL SERVER
WITH EXECUTE AS 'sa'
FOR LOGON
AS
BEGIN
    BEGIN TRY
        DECLARE @LoginName NVARCHAR(100) = ORIGINAL_LOGIN();
        --DECLARE @DatabaseName NVARCHAR(100) = EVENTDATA().value('(/EVENT_INSTANCE/DatabaseName)[1]', 'NVARCHAR(100)');

        --IF @DatabaseName = 'ExamSystemDB'
        IF @LoginName IN (SELECT Username FROM [ExamSystemDB].Users.Account)
        BEGIN
            UPDATE [ExamSystemDB].Users.Account
            SET LastLoginTime = getDate()
            WHERE Username = @LoginName;
        END
    END TRY
    BEGIN CATCH
        UPDATE [ExamSystemDB].Users.Account
            SET CreatedBy = 55
        WHERE Username = @LoginName;
        RETURN; -- on error, just skip updating last login time to avoid blocking logins
    END CATCH
END;
GO