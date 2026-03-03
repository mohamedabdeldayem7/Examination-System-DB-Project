USE [ExamSystemDB];
GO

CREATE OR ALTER PROCEDURE Ops.usp_LogAudit
(
    @SchemaName NVARCHAR(50),
    @TableName NVARCHAR(50),
    @Operation NVARCHAR(10),      -- 'INSERT','UPDATE','DELETE','SP'
    @KeyValue INT,               -- primary key value
    @Values NVARCHAR(MAX) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    -- Insert audit row. ChangedBy and ChangedAt have defaults in table.
    INSERT INTO Ops.AuditLog ([SchemaName], [TableName], [Operation], [Key], [Values])
    VALUES (@SchemaName, @TableName, @Operation, @KeyValue, @Values);
END;
GO