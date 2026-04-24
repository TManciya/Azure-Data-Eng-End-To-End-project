-- CREATE EXTERNAL TABLE EXTSALES
---------------------------------

CREATE EXTERNAL TABLE gold.extsales
WITH
(
    LOCATION = 'extsales',
    DATA_SOURCE = source_gold,
    FILE_FORMAT = format_parquet
)

SELECT * FROM gold.sales


-- CREATE EXTERNAL TABLE EXTCUSTOMERS
---------------------------------

CREATE EXTERNAL TABLE gold.extcustomers
WITH
(
    LOCATION = 'extcustomers',
    DATA_SOURCE = source_gold,
    FILE_FORMAT = format_parquet
)

SELECT * FROM gold.customers

-- CREATE EXTERNAL TABLE EXTRETURNS
---------------------------------

CREATE EXTERNAL TABLE gold.extreturns
WITH
(
    LOCATION = 'extreturns',
    DATA_SOURCE = source_gold,
    FILE_FORMAT = format_parquet
)

SELECT * FROM gold.returns

-- CREATE EXTERNAL TABLE EXTPRODUCTS

---------------------------------

CREATE EXTERNAL TABLE gold.extproducts
WITH
(
    LOCATION = 'extproducts',
    DATA_SOURCE = source_gold,
    FILE_FORMAT = format_parquet
)

SELECT * FROM gold.products