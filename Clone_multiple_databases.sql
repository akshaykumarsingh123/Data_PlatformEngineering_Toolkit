CREATE OR REPLACE PROCEDURE clone_database()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    CUR CURSOR FOR 
        SELECT DATABASE_NAME FROM INFORMATION_SCHEMA.DATABASES where DATABASE_NAME='POC_TEST';
    DB_NAME STRING;
    SQL_STMT STRING;
BEGIN
    -- Open the cursor
    OPEN CUR;
    
    -- Loop through each record in the cursor
    FOR RECORD IN CUR DO
        -- Construct the SQL statement to clone the database
        DB_NAME := RECORD.DATABASE_NAME;
        SQL_STMT := 'CREATE OR REPLACE DATABASE ' || DB_NAME || '_Backup CLONE ' || DB_NAME;
       
        
        -- Print the SQL statement (for debugging purposes)
        -- Uncomment the following line if you want to see the statements being executed
        --CALL SYSTEM$PRINT('Executing: ' || SQL_STMT); Print will not work
        
        -- Execute the SQL statement
        EXECUTE IMMEDIATE SQL_STMT;
    END FOR;
    
    -- Close the cursor
    CLOSE CUR;
    
    RETURN 'CURSOR PROCESSING COMPLETED';
END;
$$;