
DECLARE @TempPassword NVARCHAR(4000), @rand VARBINARY(16) = CRYPT_GEN_RANDOM(16);
SET @TempPassword =  CONVERT(VARCHAR(8), HASHBYTES('SHA2_256', @rand), 2); -- not ideal for production

select @TempPassword as TempPassword, @rand;

select CRYPT_GEN_RANDOM(16)

select SUSER_NAME()

begin try
	if 5 > 3
	begin
		RAISERROR('Username already taken.', 16, 1);
	end
	select 5
end try
begin catch
	print ERROR_MESSAGE()
end catch


-- test Create Accout procedure

-- email validation test
EXEC [Users].[usp_CreateAccount]
    @Username = N'Invalid_Email', 
    @Email = N'wrong.email.com', -- no @ in email
    @PlainPassword = N'Secure@P4ss', 
    @Role = N'Student';

-- validate password strength
EXEC Users.usp_CreateAccount
    @Username = N'Weak_Pass', 
    @Email = N'test@test.com', 
    @PlainPassword = N'Password123',
    @Role = N'Student';

-- validate username length
EXEC Users.usp_CreateAccount
    @Username = N'Ab',
    @Email = N'ab@test.com', 
    @PlainPassword = N'Secure@P4ss', 
    @Role = N'Student';


-- if repeat the same username or email, should get error about duplicates
EXEC Users.usp_CreateAccount 
    @Username = N'Ahmed_IT', 
    @Email = N'another@email.com', 
    @PlainPassword = N'Secure@P4ss', 
    @Role = N'Student';

EXEC Users.usp_CreateAccount 
    @Username = N'Ahmed_IT2', 
    @Email = N'another@email.com', 
    @PlainPassword = N'Secure@P4ss', 
    @Role = N'Student';

-- invalid role test - should fail due to CHECK constraint on Role column
EXEC Users.usp_CreateAccount 
    @Username = N'Hacker_User', 
    @Email = N'hacker@iti.com', 
    @PlainPassword = N'Secure@P4ss', 
    @Role = N'GodMode';


select * from Users.Account

