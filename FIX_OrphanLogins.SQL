

 DECLARE @UserCount INT
    DECLARE @UserCurr INT
    DECLARE @userName VARCHAR(100)
    DECLARE @vsql NVARCHAR(4000)
    DECLARE @Users TABLE
        (
        id INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
        userName VARCHAR(100) NOT NULL
        )
    INSERT INTO @Users(UserName) 
    SELECT 
        [name] 
    FROM 
        [master].[dbo].[syslogins] --depreciated?
    SELECT
        @UserCount = MAX([id])
    FROM
        @Users

    SET @UserCurr = 1

    WHILE(@UserCurr <= @UserCount)

        BEGIN
            SELECT
                @userName = [userName]
            FROM
                @Users
            WHERE [id] = @UserCurr
            SET @vsql = '[dbo].[sp_change_users_login] ''AUTO_FIX'',''' + @userName + ''''
            EXEC (@vsql)

            SET @UserCurr = @UserCurr + 1
        END