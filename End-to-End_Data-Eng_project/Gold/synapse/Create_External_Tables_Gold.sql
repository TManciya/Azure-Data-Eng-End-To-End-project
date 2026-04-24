CREATE DATABASE SCOPED CREDENTIAL tmancreds
WITH
    IDENTITY = 'Managed Identity';


---CREATE EXTERNAL DATA SOURCE
CREATE EXTERNAL DATA SOURCE silver_ext_source
WITH 
(
    LOCATION = 'https://tmandalake.dfs.core.windows.net/silver',
    CREDENTIAL = tmancreds

)

---CREATE EXTERNAL DATA SOURCE
CREATE EXTERNAL DATA SOURCE gold_ext_source
WITH 
(
    LOCATION = 'https://tmandalake.dfs.core.windows.net/gold',
    CREDENTIAL = tmancreds

)

-- CREATE PARQUET FILE FORMAT

CREATE EXTERNAL FILE FORMAT parquet_format
WITH
(
    FORMAT_TYPE = PARQUET,
    DATA_COMPRESSION = 'org.apache.hadoop.io.compress.SnappyCodec'
);