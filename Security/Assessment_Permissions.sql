USE ExamSystemDB;
GO

----------------INSTRUCTOR -------
GRANT EXECUTE ON Assessment.sp_CreateExam               TO InstructorRole;
GRANT EXECUTE ON Assessment.sp_ReadExam                  TO InstructorRole;
GRANT EXECUTE ON Assessment.sp_UpdateExam                TO InstructorRole;
GRANT EXECUTE ON Assessment.sp_DeleteExam                TO InstructorRole;
GRANT EXECUTE ON Assessment.sp_UpsertExamQuestion        TO InstructorRole;
GRANT EXECUTE ON Assessment.sp_DeleteExamQuestion        TO InstructorRole;
GRANT EXECUTE ON Assessment.sp_GenerateRandomExam        TO InstructorRole;
GRANT EXECUTE ON Assessment.sp_AssignStudentToExam       TO InstructorRole;
GRANT EXECUTE ON Assessment.sp_BulkAssignStudentsToExam  TO InstructorRole;
GRANT EXECUTE ON Assessment.sp_UpdateStudentExam         TO InstructorRole;
GRANT EXECUTE ON Assessment.sp_RemoveStudentFromExam     TO InstructorRole;
GRANT EXECUTE ON Assessment.sp_DeleteAnswer              TO InstructorRole;
GRANT EXECUTE ON Assessment.sp_GradeTextAnswer           TO InstructorRole;
GRANT EXECUTE ON Assessment.sp_GetStudentExamQuestions   TO InstructorRole;
GRANT EXECUTE ON Assessment.sp_CalculateResult           TO InstructorRole;
GRANT EXECUTE ON Assessment.sp_CalculateAllExamResults   TO InstructorRole;
GRANT EXECUTE ON Assessment.sp_SearchExams               TO InstructorRole;
GRANT EXECUTE ON Assessment.sp_SearchExamResults         TO InstructorRole;
GRANT EXECUTE ON Assessment.sp_GetExamAnswerSheet        TO InstructorRole;
GRANT EXECUTE ON Assessment.sp_GetPendingTextReviews     TO InstructorRole;
GRANT EXECUTE ON Assessment.sp_GetExamStatistics         TO InstructorRole;
GRANT EXECUTE ON Assessment.sp_GetStudentExamHistory     TO InstructorRole;
GRANT EXECUTE ON Assessment.sp_GetAuditLog               TO InstructorRole;
GRANT SELECT  ON Assessment.vw_ExamDetails               TO InstructorRole;
GRANT SELECT  ON Assessment.vw_ExamQuestionsDetail       TO InstructorRole;
GRANT SELECT  ON Assessment.vw_StudentExamAssignments    TO InstructorRole;
GRANT SELECT  ON Assessment.vw_StudentAnswerSheet        TO InstructorRole;
GRANT SELECT  ON Assessment.vw_TextAnswersForReview      TO InstructorRole;
GRANT SELECT  ON Assessment.vw_StudentExamResults        TO InstructorRole;
GRANT SELECT  ON Assessment.vw_ExamStatistics            TO InstructorRole;
GRANT SELECT  ON Assessment.vw_AuditLog                  TO InstructorRole;

------STUDENT -------
-- NO access to: vw_StudentAnswerSheet, vw_TextAnswersForReview,
--               vw_ExamQuestionsDetail, vw_AuditLog
GRANT EXECUTE ON Assessment.sp_UpsertAnswer              TO StudentRole;
GRANT EXECUTE ON Assessment.sp_DeleteAnswer              TO StudentRole;
GRANT EXECUTE ON Assessment.sp_GetStudentExamQuestions   TO StudentRole;
GRANT EXECUTE ON Assessment.sp_StudentPostExamReview     TO StudentRole;
GRANT EXECUTE ON Assessment.sp_GetStudentExamHistory     TO StudentRole;
GRANT EXECUTE ON Assessment.sp_SearchExamResults         TO StudentRole;
GRANT SELECT  ON Assessment.vw_StudentExamAssignments    TO StudentRole;
GRANT SELECT  ON Assessment.vw_StudentExamResults        TO StudentRole;

----- TRAINING MANAGER-----
GRANT EXECUTE ON Assessment.sp_UpdateExam                TO TrainingMgrRole;
GRANT EXECUTE ON Assessment.sp_DeleteExam                TO TrainingMgrRole;
GRANT EXECUTE ON Assessment.sp_SearchExams               TO TrainingMgrRole;
GRANT EXECUTE ON Assessment.sp_SearchExamResults         TO TrainingMgrRole;
GRANT EXECUTE ON Assessment.sp_GetExamStatistics         TO TrainingMgrRole;
GRANT EXECUTE ON Assessment.sp_GetExamAnswerSheet        TO TrainingMgrRole;
GRANT EXECUTE ON Assessment.sp_GetStudentExamHistory     TO TrainingMgrRole;
GRANT EXECUTE ON Assessment.sp_GetAuditLog               TO TrainingMgrRole;
GRANT SELECT  ON Assessment.vw_ExamDetails               TO TrainingMgrRole;
GRANT SELECT  ON Assessment.vw_StudentExamResults        TO TrainingMgrRole;
GRANT SELECT  ON Assessment.vw_ExamStatistics            TO TrainingMgrRole;
GRANT SELECT  ON Assessment.vw_StudentExamAssignments    TO TrainingMgrRole;
GRANT SELECT  ON Assessment.vw_AuditLog                  TO TrainingMgrRole;
GO

