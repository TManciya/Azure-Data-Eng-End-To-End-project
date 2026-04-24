-- CREATE EXTERNAL DATA TABLE

CREATE EXTERNAL TABLE Rivenue_ext_table 
(
   Dealer_ID VARCHAR (4000),
   Model_ID VARCHAR (4000),
   Branch_ID VARCHAR (4000),
   Date_ID VARCHAR (4000),
   Units_Sold VARCHAR (4000),
   Revenue VARCHAR (4000)
 
)
WITH
(
    LOCATION = 'revenue',
    DATA_SOURCE = row_ext_source,
    FILE_FORMAT = csv_format
)

SELECT * FROM Rivenue_ext_table;