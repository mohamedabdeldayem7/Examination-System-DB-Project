# Examination System DB

An enterprise-grade SQL Server relational database designed to manage the complete lifecycle of an examination system, featuring advanced security, automated grading, and high availability.

---

## 🚀 Advanced Highlights

- **Optimized Storage Architecture:** Utilizes **5 distinct FileGroups** to segregate system objects, lookup tables, master data, transactional data, and indexes, boosting I/O performance.
- **Custom Cryptography:** Implements a custom **PBKDF2-SHA512** hashing algorithm with unique salting for passwords directly in T-SQL, ensuring zero plain-text storage.
- **Role-Based Access Control (RBAC):** Native database-level security with Contained DB Users. Roles (`db_admin`, `db_TrainingManager`, `db_Instructor`, `db_Student`) strictly enforce access without relying on an application layer.
- **Comprehensive Audit Trail:** 15+ automated triggers track every `INSERT`, `UPDATE`, and `DELETE` operation across all schemas, logging them immutably into `Ops.AuditLog`.
- **Automated Backup Strategy:** Scheduled via SQL Server Agent Jobs:
  - **Weekly Full Backup** (Fridays at Midnight)
  - **Daily Differential Backup** (1:00 AM)
  - **Hourly Transaction Log Backup** (Dynamic naming, prevents data loss)
- **High Availability (HA) Ready:** Designed for SQL Server Always On Availability Groups. Uses `CONTAINMENT = PARTIAL` to allow seamless failover of users and roles without orphaned logins.

---

## 🗄️ Schema Overview (5 Schemas)

1. **`Org`**: Institutional structure (Branches, Departments, Tracks, Intakes).
2. **`Users`**: Authentication and profiles (Accounts, Persons, Instructors, Students).
3. **`Academic`**: Courses and Question Pools (MCQ, True/False, Text).
4. **`Assessment`**: Exams, Student Assignments, Submissions, and Results.
5. **`Ops`**: Operational tables including the system-wide `AuditLog`.

---

## ⚙️ Business Logic & Triggers

All database interactions flow exclusively through **Stored Procedures** and are protected by **Triggers**:
- **Account & Security:** `usp_CreateAccount` (atomic creation of account and DB user), `usp_ChangePassword`, `usp_DeleteAccount` (soft-delete + DB user cleanup), Logon triggers for activity tracking.
- **Exam Management:** `sp_CreateExam`, `sp_GenerateRandomExam` (auto-builds exams from question pools), `sp_BulkAssignStudentsToExam`.
- **Grading Automation:** `sp_UpsertAnswer` (blocked outside exam window), automatic background grading via `trg_AutoGradeAnswer`, `sp_CalculateAllExamResults`.

---

## 🚀 How to Run

Execute the SQL scripts sequentially starting with `Database_Architecture/` to create the structure and FileGroups. Next, configure `Security/` (Containment and Roles). Then build `Programmability/` (Functions, Stored Procedures, Triggers, Views). Finally, configure the SQL Server Agent Jobs from `Mentainance/backup/`. 

---

## 👥 Team

- **mohamedabdeldayem7**: DB architecture, FileGroups, Security system, PBKDF2 encryption, RBAC, Account management, Audit infrastructure.
- **Mena Magdy**: Assessment stored procedures, exam grading logic, views.
- **salmamomen128-eng**: Org and Academic stored procedures and triggers.

---

## License

This project was developed as part of the MCIT Information Technology Institute (ITI) Intensive Training Program — Full Stack .NET & Generative AI Track.
