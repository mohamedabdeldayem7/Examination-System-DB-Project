USE ExamSystemDB;
GO
--Department Trigger Audit Log ---------------
CREATE OR ALTER TRIGGER Org.trg_DepartmentAudit
ON Org.Department
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Ops.AuditLog (SchemaName, TableName, Operation, [Key],[Values] )
        SELECT 
            'Org', 'Department', 'INSERT', 
            i.DepartmentId ,
            'Added Department: ' + ISNULL (i.DepartmentName, '')
        FROM inserted i;
    END

    -- UPDATE
    ELSE IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Ops.AuditLog (SchemaName, TableName, Operation,[Key] , [Values])
        SELECT 
            'Org', 'Department', 'UPDATE', 
            i.DepartmentId ,
            'Changed Name from [' +ISNULL( d.DepartmentName,'') + '] to [' + ISNULL(i.DepartmentName ,'') + ']'
        FROM inserted i
        JOIN deleted d ON i.DepartmentId = d.DepartmentId
        WHERE i.DepartmentName <> d.DepartmentName;
    END

    --DELETE
    ELSE IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO Ops.AuditLog (SchemaName, TableName, Operation,[Key] , [Values])
        SELECT 
            'Org', 'Department', 'DELETE', 
            d.DepartmentId,
            'Deleted Department: ' + d.DepartmentName
        FROM deleted d;
    END
END
GO

--Branch Trigger Audit Log ---------------
CREATE OR ALTER TRIGGER Org.trg_BranchAudit
ON [Org].[Branch]
AFTER INSERT , UPDATE ,DELETE 
AS 
BEGIN
   SET NOCOUNT ON;

    -- INSERT
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    begin
        INSERT INTO [Ops].[AuditLog] ([SchemaName],[TableName],[Operation],[Key],[Values])
        SELECT 'Org','Branch' ,'INSERT' , 
        i.BranchId  ,
        'Added Branch : ' + ISNULL (i.BranchName, '')
        FROM inserted AS i
    end
    --UPDATE
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    begin
        INSERT INTO [Ops].[AuditLog] ([SchemaName],[TableName],[Operation],[Key],[Values])
        SELECT 'Org','Branch' ,'UPDATE', 
        i.BranchId  ,
        'UPDATE Branch from[' + ISNULL (d.BranchName, '') +'] To [' + ISNULL (i.BranchName, '')
        FROM inserted as i 
        JOIN deleted as d ON i.BranchId = d.BranchId
        WHERE i.BranchName <> d.BranchName;
    END
    --DELETE 
     IF NOT EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    begin
        INSERT INTO [Ops].[AuditLog] ([SchemaName],[TableName],[Operation],[Key],[Values])
        SELECT 'Org','Branch' ,'INSERT' , 
        d.BranchId ,
        'Deleted Branch: ' + ISNULL (d.BranchName, '')
        FROM deleted AS d
    end
        
END 
GO
---AUDIT TRIGGER FOR INTAKE ----------
CREATE OR ALTER TRIGGER Org.trg_IntakeAudit
ON [Org].[Intake]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT
    IF EXISTS (SELECT 1 FROM inserted)
       AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO [Ops].[AuditLog]
        ([SchemaName],[TableName],[Operation],[Key],[Values])
        SELECT 
            'Org',
            'Intake',
            'INSERT',
             i.IntakeID,
            'Added Intake: Year = ' + CAST(i.IntakeYear AS NVARCHAR(10)) +
            ', Semester = ' + ISNULL(i.IntakeSemester,'')
        FROM inserted i;
    END
    -- UPDATE
    IF EXISTS (SELECT 1 FROM inserted)
       AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO [Ops].[AuditLog]
        ([SchemaName],[TableName],[Operation],[Key],[Values])
        SELECT 
            'Org',
            'Intake',
            'UPDATE',
            i.IntakeID,
            'Updated Intake From [Year=' + CAST(d.IntakeYear AS NVARCHAR(10)) +
            ', Semester=' + ISNULL(d.IntakeSemester,'') +
            '] To [Year=' + CAST(i.IntakeYear AS NVARCHAR(10)) +
            ', Semester=' + ISNULL(i.IntakeSemester,'') + ']'
        FROM inserted i
        JOIN deleted d 
            ON i.IntakeID = d.IntakeID
        WHERE 
            i.IntakeYear <> d.IntakeYear
            OR i.IntakeSemester <> d.IntakeSemester;
    END
    -- DELETE
    IF NOT EXISTS (SELECT 1 FROM inserted)
       AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO [Ops].[AuditLog]
        ([SchemaName],[TableName],[Operation],[Key],[Values])
        SELECT 
            'Org',
            'Intake',
            'DELETE',
            d.IntakeID ,
            'Deleted Intake: Year = ' + CAST(d.IntakeYear AS NVARCHAR(10)) +
            ', Semester = ' + ISNULL(d.IntakeSemester,'')
        FROM deleted d;
    END

END
GO
---AUDIT TRIGGER FOR INTAKE------------------------
CREATE OR ALTER TRIGGER Org.trg_TrackAudit
ON [Org].[Track]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT -------------------------
    IF EXISTS (SELECT 1 FROM inserted)
       AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO [Ops].[AuditLog]
        ([SchemaName],[TableName],[Operation],[Key],[Values])
        SELECT 
            'Org',
            'Track',
            'INSERT',
            --'TrackID ' + CAST(i.TrackId AS NVARCHAR(50)),
            i.TrackId,
            'Added Track: Name = ' + ISNULL(i.TrackName,'') +
            ', DepartmentID = ' + ISNULL(CAST(i.DepartmentId AS NVARCHAR(50)),'NULL')
        FROM inserted i;
    END
    -- UPDATE ------------------------
    IF EXISTS (SELECT 1 FROM inserted)
       AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO [Ops].[AuditLog]
        ([SchemaName],[TableName],[Operation],[Key],[Values])
        SELECT 
            'Org',
            'Track',
            'UPDATE',
            'TrackID ' + CAST(i.TrackId AS NVARCHAR(50)),
            'Updated Track From [Name=' + ISNULL(d.TrackName,'') +
            ', DeptID=' + ISNULL(CAST(d.DepartmentId AS NVARCHAR(50)),'NULL') +
            '] To [Name=' + ISNULL(i.TrackName,'') +
            ', DeptID=' + ISNULL(CAST(i.DepartmentId AS NVARCHAR(50)),'NULL') + ']'
        FROM inserted i
        JOIN deleted d
            ON i.TrackId = d.TrackId
        WHERE 
            ISNULL(i.TrackName,'') <> ISNULL(d.TrackName,'')
            OR ISNULL(i.DepartmentId, -1) <> ISNULL(d.DepartmentId, -1);
    END
    -- DELETE------------------------------
    IF NOT EXISTS (SELECT 1 FROM inserted)
       AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO [Ops].[AuditLog]
        ([SchemaName],[TableName],[Operation],[Key],[Values])
        SELECT 
            'Org',
            'Track',
            'DELETE',
            'TrackID ' + CAST(d.TrackId AS NVARCHAR(50)),
            'Deleted Track: Name = ' + ISNULL(d.TrackName,'') +
            ', DepartmentID = ' + ISNULL(CAST(d.DepartmentId AS NVARCHAR(50)),'NULL')
        FROM deleted d;
    END

END
GO