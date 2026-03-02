
-- This script creates helper functions for cryptographic operations, such as hashing passwords and generating salts.

-- function to perform XOR operation on two VARBINARY inputs, used in PBKDF2 implementation
CREATE OR ALTER FUNCTION Users.fn_VarbinaryXOR
(
    @a VARBINARY(8000),
    @b VARBINARY(8000)
)
RETURNS VARBINARY(8000)
AS
BEGIN
    DECLARE @result VARBINARY(8000) = 0x;
    DECLARE @i INT = 1;
    DECLARE @len INT = DATALENGTH(@a);

    WHILE @i <= @len
    BEGIN
        -- Make XOR between each byte of @a and @b, and concatenate the result 
        SET @result = @result + CAST(CAST(SUBSTRING(@a, @i, 1) AS TINYINT) ^ CAST(SUBSTRING(@b, @i, 1) AS TINYINT) AS BINARY(1));
        SET @i = @i + 1;
    END
    RETURN @result;
END;
GO


-- PBKDF2 (Password-Based Key Derivation Function 2) implementation using SHA512, for demonstration purposes. In production, consider using a more robust approach or external library.
CREATE OR ALTER FUNCTION Users.fn_PBKDF2_SHA512_OneBlock
(
    @password NVARCHAR(4000),
    @salt VARBINARY(128),
    @iterations INT,
    @dkLen INT = 32     -- derived key length in bytes must be <= 64
)
RETURNS VARBINARY(8000)
AS
BEGIN
    DECLARE @hashLen INT = 64; -- SHA512 output bytes
    IF @dkLen > @hashLen  -- check if requested derived key length is greater than hash output
    BEGIN
        RETURN NULL
    END

    DECLARE @blockIndexBytes VARBINARY(4) = 0x00000001; -- INT_32_BE(1) for the first block -> 4 bytes * 8 bits = 32 bits
    DECLARE @u VARBINARY(8000);
    DECLARE @t VARBINARY(8000);
    DECLARE @i INT = 2; -- start from 2 because U1 is calculated before the loop

    -- U1 
    SET @u = HASHBYTES('SHA2_512', @salt + CONVERT(VARBINARY(MAX), @password) + @blockIndexBytes);
    SET @t = @u;

    WHILE @i <= @iterations
    BEGIN
        SET @u = HASHBYTES('SHA2_512', @u);
        -- use XOR operation on each byte
        SET @t = Users.fn_VarbinaryXOR(@t, @u);
        SET @i = @i + 1;
    END

    RETURN SUBSTRING(@t, 1, @dkLen);
END;
GO
