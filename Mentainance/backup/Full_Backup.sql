USE msdb;
GO

IF EXISTS (SELECT job_id FROM dbo.sysjobs WHERE name = N'Weekly_Full_Backup')
BEGIN
    EXEC dbo.sp_delete_job @job_name = N'Weekly_Full_Backup', @delete_unused_schedule = 1;
END
GO

-- create Job
EXEC dbo.sp_add_job @job_name = N'Weekly_Full_Backup';

-- add step
EXEC sp_add_jobstep 
    @job_name = N'Weekly_Full_Backup', 
    @step_name = N'Execute Full Backup', 
    @subsystem = N'TSQL', 
    @command = N'BACKUP DATABASE [ExamSystemDB] TO DISK = N''C:\SQLProject\Backups\ExamSystemDB_Full.bak'' WITH INIT, COMPRESSION, STATS = 10', 
    @retry_attempts = 5, @retry_interval = 5;

-- create Jobschedule in Friday On 12:00 every week
EXEC dbo.sp_add_jobschedule 
    @job_name = N'Weekly_Full_Backup', 
    @name = N'WeeklyFullSchedule', 
    @freq_type = 8,               
    @freq_interval = 32,           
    @freq_recurrence_factor = 1,   
    @active_start_time = 000000;   


EXEC dbo.sp_add_jobserver @job_name = N'Weekly_Full_Backup';