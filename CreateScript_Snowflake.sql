CREATE DATABASE database_name;

CREATE SCHEMA schema_name;

CREATE USER user_name
PASSWORD = 'password'
DEFAULT_ROLE = role_name;


CREATE ROLE role_name;

CREATE WAREHOUSE warehouse_name
WAREHOUSE_SIZE = 'XSMALL'
WAREHOUSE_TYPE = 'STANDARD';


CREATE FILE FORMAT file_format_name
TYPE = CSV
FIELD_DELIMITER = ','
SKIP_HEADER = 1;


CREATE FILE FORMAT file_format_name
TYPE = CSV
FIELD_DELIMITER = ','
SKIP_HEADER = 1;


CREATE EXTERNAL TABLE external_table_name (
    column1 datatype,
    column2 datatype,
    ...
)
USING (
    DATA_SOURCE = external_stage_name
    FILE_FORMAT = (FORMAT_NAME = file_format_name)
);
