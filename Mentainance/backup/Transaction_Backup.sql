	USE msdb;
GO

IF EXISTS (SELECT job_id FROM dbo.sysjobs WHERE name = N'ExamSystemDB_TLog_Backup')
BEGIN
    EXEC dbo.sp_delete_job @job_name = N'ExamSystemDB_TLog_Backup', @delete_unused_schedule = 1;
END
GO

-- create Job
EXEC dbo.sp_add_job 
    @job_name = N'ExamSystemDB_TLog_Backup',
    @enabled = 1,
    @description = N'Hourly Transaction Log Backup with Dynamic Naming.';

-- add step
DECLARE @tlog_command NVARCHAR(MAX) = N'
DECLARE @FilePath NVARCHAR(255);
DECLARE @FileName NVARCHAR(255);

SET @FileName = ''ExamSystemDB_Log_'' + 
                REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR, GETDATE(), 120), ''-'', ''''), '' '', ''_''), '':'', '''') + 
                ''.trn'';
SET @FilePath = N''C:\SQLProject\Backups\'' + @FileName;

BACKUP LOG [ExamSystemDB] 
TO DISK = @FilePath 
WITH NOINIT, COMPRESSION, STATS = 10;
';

EXEC sp_add_jobstep 
    @job_name = N'ExamSystemDB_TLog_Backup', 
    @step_name = N'Dynamic T-Log Backup', 
    @subsystem = N'TSQL', 
    @command = @tlog_command, 
    @retry_attempts = 3, 
    @retry_interval = 2;

-- create Jobschedule every 1 H
EXEC dbo.sp_add_jobschedule 
    @job_name = N'ExamSystemDB_TLog_Backup', 
    @name = N'HourlyTLogSchedule', 
    @freq_type = 4,                
    @freq_interval = 1,            
    @freq_subday_type = 8,        
    @freq_subday_interval = 2,    
    @active_start_time = 000000;   

-- assign job to server
EXEC dbo.sp_add_jobserver @job_name = N'ExamSystemDB_TLog_Backup';
GO