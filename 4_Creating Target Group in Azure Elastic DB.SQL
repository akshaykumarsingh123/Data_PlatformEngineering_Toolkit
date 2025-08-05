-- Create a target group
EXEC jobs.sp_add_target_group @target_group_name = N'<Target Group>';

-- Add a server to the target group (example: all user databases on a server)
EXEC jobs.sp_add_target_group_member
    @target_group_name = N'<Target Group>',
    @target_type = N'SqlServer',
    @server_name = N'<Server Name>';
    --@refresh_credential_name = NULL; -- Not needed for UMI

-- Optionally, exclude a specific database
EXEC jobs.sp_add_target_group_member
    @target_group_name = N'<Target Group>',
    @target_type = N'SqlDatabase',
    @server_name = N'<Server Name>',
    @database_name = N'<Database Name>';

-- Query the Target Groups
SELECT *
FROM jobs.target_groups
WHERE target_group_name = '<Target Group>';

-- Query the Target Group Members
SELECT *
FROM jobs.target_group_members
WHERE target_group_name = '<Target Group>';


  