USE msdb;
GO


IF EXISTS (SELECT job_id FROM dbo.sysjobs WHERE name = N'Daily_Differential_Backup')
BEGIN
    EXEC dbo.sp_delete_job @job_name = N'Daily_Differential_Backup', @delete_unused_schedule = 1;
END
GO

EXEC dbo.sp_add_job @job_name = N'Daily_Differential_Backup';

EXEC sp_add_jobstep 
    @job_name = N'Daily_Differential_Backup', 
    @step_name = N'Execute Diff Backup', 
    @subsystem = N'TSQL', 
    @command = N'BACKUP DATABASE [ExamSystemDB] TO DISK = N''C:\SQLProject\Backups\ExamSystemDB_Diff.bak'' WITH DIFFERENTIAL, INIT, COMPRESSION', 
    @retry_attempts = 5, @retry_interval = 5;

EXEC dbo.sp_add_jobschedule 
    @job_name = N'Daily_Differential_Backup', 
    @name = N'DailyDiffSchedule', 
    @freq_type = 4, -- Daily
    @freq_interval = 1, 
    @freq_recurrence_factor = 1,  
    @active_start_time = 010000; -- 01:00 AM

EXEC dbo.sp_add_jobserver @job_name = N'Daily_Differential_Backup';