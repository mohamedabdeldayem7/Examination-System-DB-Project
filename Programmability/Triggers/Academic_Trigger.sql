USE ExamSystemDB ;
GO
-- CREATE AUDIT TRIGGER ON COURSE-------------------------------------
CREATE OR ALTER TRIGGER Academic.trg_CourseAudit
ON Academic.Course
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Ops.AuditLog (SchemaName, TableName, Operation, [Key], [Values])
        SELECT 
            'Academic',
            'Course',
            'INSERT',
            i.CourseID,
            'Added Course: ' + ISNULL(i.CourseName,'')
        FROM inserted i;
    END

    -- UPDATE
    ELSE IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Ops.AuditLog (SchemaName, TableName, Operation, [Key], [Values])
        SELECT 
            'Academic',
            'Course',
            'UPDATE',
            i.CourseID,
            'Name changed from [' + ISNULL(d.CourseName,'') + 
            '] to [' + ISNULL(i.CourseName,'') + ']'
        FROM inserted i
        JOIN deleted d 
            ON i.CourseID = d.CourseID
        WHERE ISNULL(i.CourseName,'') <> ISNULL(d.CourseName,'');
    END

    -- DELETE
    ELSE IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO Ops.AuditLog (SchemaName, TableName, Operation, [Key], [Values])
        SELECT 
            'Academic',
            'Course',
            'DELETE',
            d.CourseID,
            'Deleted Course: ' + ISNULL(d.CourseName,'')
        FROM deleted d;
    END
END
GO
-- CREATE AUDIT TRIGGER ON Course_Instructor-------------------------------------
CREATE OR ALTER TRIGGER Academic.trg_CourseInstructorAudit
ON Academic.Course_Instructor
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Ops.AuditLog (SchemaName, TableName, Operation, [Key], [Values])
        SELECT 
            'Academic',
            'Course_Instructor',
            'INSERT',
            i.CourseID,
            'Assigned Instructor [' + CAST(i.InstructorID AS VARCHAR) +
            '] for Year [' + CAST(i.Year AS VARCHAR) + ']'
        FROM inserted i;
    END
    
    -- UPDATE YEAR
    ELSE IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Ops.AuditLog (SchemaName, TableName, Operation, [Key], [Values])
        SELECT 
            'Academic',
            'Course_Instructor',
            'UPDATE',
            i.CourseID,
            'Year changed from [' + CAST(d.Year AS VARCHAR) +
            '] to [' + CAST(i.Year AS VARCHAR) + ']'
        FROM inserted i
        JOIN deleted d
            ON i.CourseID = d.CourseID
           AND i.InstructorID = d.InstructorID
        WHERE ISNULL(i.Year,0) <> ISNULL(d.Year,0);
    END

    -- DELETE
    ELSE IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO Ops.AuditLog (SchemaName, TableName, Operation, [Key], [Values])
        SELECT 
            'Academic',
            'Course_Instructor',
            'DELETE',
            d.CourseID,
            'Removed Instructor [' + CAST(d.InstructorID AS VARCHAR) +
            '] for Year [' + CAST(d.Year AS VARCHAR) + ']'
        FROM deleted d;
    END
END
GO
-- CREATE AUDIT TRIGGER ON Question_Pool -------------------------------------
CREATE OR ALTER TRIGGER Academic.trg_QuestionPoolAudit
ON Academic.Question_Pool
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Ops.AuditLog (SchemaName, TableName, Operation, [Key], [Values])
        SELECT 
            'Academic',
            'Question_Pool',
            'INSERT',
            i.QuestionID,
            'Added Question for CourseID [' + 
            CAST(i.CourseID AS VARCHAR) + ']'
        FROM inserted i;
    END

    -- UPDATE QuestionText
    ELSE IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Ops.AuditLog (SchemaName, TableName, Operation, [Key], [Values])
        SELECT 
            'Academic',
            'Question_Pool',
            'UPDATE',
            i.QuestionID,
            'Question text changed'
        FROM inserted i
        JOIN deleted d
            ON i.QuestionID = d.QuestionID
        WHERE ISNULL(i.QuestionText,'') <> ISNULL(d.QuestionText,'');
    END

    -- DELETE
    ELSE IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO Ops.AuditLog (SchemaName, TableName, Operation, [Key], [Values])
        SELECT 
            'Academic',
            'Question_Pool',
            'DELETE',
            d.QuestionID,
            'Deleted Question for CourseID [' + 
            CAST(d.CourseID AS VARCHAR) + ']'
        FROM deleted d;
    END
END
GO
--CREATE AUDIT TRIGGER ON Question_Choices -------------------------------------
CREATE OR ALTER TRIGGER Academic.trg_QuestionChoicesAudit
ON Academic.Question_Choices
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Ops.AuditLog (SchemaName, TableName, Operation, [Key], [Values])
        SELECT 
            'Academic',
            'Question_Choices',
            'INSERT',
            i.ChoiceID,
            'Added Choice for QuestionID [' +
            CAST(i.QuestionID AS VARCHAR) + ']'
        FROM inserted i;
    END

    -- UPDATE IsCorrectChoice
    ELSE IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Ops.AuditLog (SchemaName, TableName, Operation, [Key], [Values])
        SELECT 
            'Academic',
            'Question_Choices',
            'UPDATE',
            i.ChoiceID,
            'Correct flag changed from [' +
            CAST(d.IsCorrectChoice AS VARCHAR) +
            '] to [' +
            CAST(i.IsCorrectChoice AS VARCHAR) + ']'
        FROM inserted i
        JOIN deleted d
            ON i.ChoiceID = d.ChoiceID
        WHERE ISNULL(i.IsCorrectChoice,0) <> ISNULL(d.IsCorrectChoice,0);
    END

    -- DELETE
    ELSE IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO Ops.AuditLog (SchemaName, TableName, Operation, [Key], [Values])
        SELECT 
            'Academic',
            'Question_Choices',
            'DELETE',
            d.ChoiceID,
            'Deleted Choice for QuestionID [' +
            CAST(d.QuestionID AS VARCHAR) + ']'
        FROM deleted d;
    END
END
GO
