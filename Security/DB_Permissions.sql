USE ExamSystemDB;
GO

-- Grant permissions to database roles

----------------INSTRUCTOR -------
-- Assessment
GRANT EXECUTE ON Assessment.sp_CreateExam                TO db_Instructor;
GRANT EXECUTE ON Assessment.sp_ReadExam                  TO db_Instructor;
GRANT EXECUTE ON Assessment.sp_UpdateExam                TO db_Instructor;
GRANT EXECUTE ON Assessment.sp_DeleteExam                TO db_Instructor;
GRANT EXECUTE ON Assessment.sp_UpsertExamQuestion        TO db_Instructor;
GRANT EXECUTE ON Assessment.sp_DeleteExamQuestion        TO db_Instructor;
GRANT EXECUTE ON Assessment.sp_GenerateRandomExam        TO db_Instructor;
GRANT EXECUTE ON Assessment.sp_AssignStudentToExam       TO db_Instructor;
GRANT EXECUTE ON Assessment.sp_BulkAssignStudentsToExam  TO db_Instructor;
GRANT EXECUTE ON Assessment.sp_UpdateStudentExam         TO db_Instructor;
GRANT EXECUTE ON Assessment.sp_RemoveStudentFromExam     TO db_Instructor;
GRANT EXECUTE ON Assessment.sp_DeleteAnswer              TO db_Instructor;
GRANT EXECUTE ON Assessment.sp_GradeTextAnswer           TO db_Instructor;
GRANT EXECUTE ON Assessment.sp_GetStudentExamQuestions   TO db_Instructor;
GRANT EXECUTE ON Assessment.sp_CalculateResult           TO db_Instructor;
GRANT EXECUTE ON Assessment.sp_CalculateAllExamResults   TO db_Instructor;
GRANT EXECUTE ON Assessment.sp_SearchExams               TO db_Instructor;
GRANT EXECUTE ON Assessment.sp_SearchExamResults         TO db_Instructor;
GRANT EXECUTE ON Assessment.sp_GetExamAnswerSheet        TO db_Instructor;
GRANT EXECUTE ON Assessment.sp_GetPendingTextReviews     TO db_Instructor;
GRANT EXECUTE ON Assessment.sp_GetExamStatistics         TO db_Instructor;
GRANT EXECUTE ON Assessment.sp_GetStudentExamHistory     TO db_Instructor;
GRANT EXECUTE ON Assessment.sp_GetAuditLog               TO db_Instructor;
GRANT SELECT  ON Assessment.vw_ExamDetails               TO db_Instructor;
GRANT SELECT  ON Assessment.vw_ExamQuestionsDetail       TO db_Instructor;
GRANT SELECT  ON Assessment.vw_StudentExamAssignments    TO db_Instructor;
GRANT SELECT  ON Assessment.vw_StudentAnswerSheet        TO db_Instructor;
GRANT SELECT  ON Assessment.vw_TextAnswersForReview      TO db_Instructor;
GRANT SELECT  ON Assessment.vw_StudentExamResults        TO db_Instructor;
GRANT SELECT  ON Assessment.vw_ExamStatistics            TO db_Instructor;
GRANT SELECT  ON Assessment.vw_AuditLog                  TO db_Instructor;

------STUDENT -------
-- Student: limited read via views and execute allowed SPs
-- Assessment
-- NO access to: vw_StudentAnswerSheet, vw_TextAnswersForReview,
--               vw_ExamQuestionsDetail, vw_AuditLog
GRANT EXECUTE ON Assessment.sp_UpsertAnswer              TO db_Student;
GRANT EXECUTE ON Assessment.sp_DeleteAnswer              TO db_Student;
GRANT EXECUTE ON Assessment.sp_GetStudentExamQuestions   TO db_Student;
GRANT EXECUTE ON Assessment.sp_StudentPostExamReview     TO db_Student;
GRANT EXECUTE ON Assessment.sp_GetStudentExamHistory     TO db_Student;
GRANT EXECUTE ON Assessment.sp_SearchExamResults         TO db_Student;
GRANT SELECT  ON Assessment.vw_StudentExamAssignments    TO db_Student;
GRANT SELECT  ON Assessment.vw_StudentExamResults        TO db_Student;




----- TRAINING MANAGER-----
-- Training manager: manage Org and Students via stored procedures
ALTER ROLE db_Instructor ADD MEMBER db_TrainingManager; -- each Training Manager is also an Instructor, so they can execute all Instructor SPs
GO

-- Org
GRANT EXECUTE ON SCHEMA::ORG TO db_TrainingManager

 -- Assessment
GRANT EXECUTE ON Assessment.sp_UpdateExam                TO db_TrainingManager;
GRANT EXECUTE ON Assessment.sp_DeleteExam                TO db_TrainingManager;
GRANT EXECUTE ON Assessment.sp_SearchExams               TO db_TrainingManager;
GRANT EXECUTE ON Assessment.sp_SearchExamResults         TO db_TrainingManager;
GRANT EXECUTE ON Assessment.sp_GetExamStatistics         TO db_TrainingManager;
GRANT EXECUTE ON Assessment.sp_GetExamAnswerSheet        TO db_TrainingManager;
GRANT EXECUTE ON Assessment.sp_GetStudentExamHistory     TO db_TrainingManager;
GRANT EXECUTE ON Assessment.sp_GetAuditLog               TO db_TrainingManager;
GRANT SELECT  ON Assessment.vw_ExamDetails               TO db_TrainingManager;
GRANT SELECT  ON Assessment.vw_StudentExamResults        TO db_TrainingManager;
GRANT SELECT  ON Assessment.vw_ExamStatistics            TO db_TrainingManager;
GRANT SELECT  ON Assessment.vw_StudentExamAssignments    TO db_TrainingManager;
GRANT SELECT  ON Assessment.vw_AuditLog                  TO db_TrainingManager;
GO


-- Deny direct DML on critical tables to all users, even those with higher privileges, to enforce the use of stored procedures for data modifications which include necessary business logic and auditing.
DENY INSERT, UPDATE, DELETE ON Ops.AuditLog TO public;












