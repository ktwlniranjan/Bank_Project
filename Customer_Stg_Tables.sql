USE BANK_PROJECT
--STAGGING
/**************************** AUDIT TABLE *******************************************************/

SELECT* FROM DATA_LOAD_AUDIT_TABLE
--TRUNCATE TABLE DATA_LOAD_AUDIT_TABLE

--ALTER TABLE DATA_LOAD_AUDIT_TABLE
--ALTER COLUMN File_Name VARCHAR(300)

CREATE TABLE DATA_LOAD_AUDIT_TABLE(
								 AuditLogID INT IDENTITY(1,1)
								 ,File_Name VARCHAR(50)
								 ,TotalRecordInSource INT
								 ,NewRecords INT
								 ,ExistingRecords INT
								 ,Error_Records INT
								 ,LoadedInTarget INT
								 ,LoadedDateTime DATETIME
								 )

------------------------------------------------------------------------------------------------------


select * from STG_CUSTOMER_DETAILS 
--TRUNCATE TABLE STG_CUSTOMER_DETAILS
GO
CREATE TABLE STG_CUSTOMER_DETAILS(
									Client_id VARCHAR(50),
									Sex VARCHAR(50),
									FullDate VARCHAR(50),
									Day VARCHAR(50),
									Month VARCHAR(50),
									Year VARCHAR(50),
									Age VARCHAR(50),
									Social VARCHAR(50),
									First VARCHAR(50),
									Middle VARCHAR(50),
									Last VARCHAR(50),
									Phone VARCHAR(50),
									Email VARCHAR(50),
									Address1 VARCHAR(50),
									Address2 VARCHAR(50),
									City VARCHAR(50),
									State VARCHAR(50),
									Zipcode VARCHAR(50),
									District_id VARCHAR(50),
									Education VARCHAR(50),
									MaritalStatus VARCHAR(50),
									Household_Size VARCHAR(50),
									Retired VARCHAR(50),
									)
----------------------------------------------------------------------------------------------------------------

select * from stg_Customer_Details_Success
--TRUNCATE TABLE stg_Customer_Details_Success
								
CREATE TABLE stg_Customer_Details_Success(
											Client_id VARCHAR(50),
									Sex VARCHAR(50),
									FullDate VARCHAR(50),
									Day VARCHAR(50),
									Month VARCHAR(50),
									Year VARCHAR(50),
									Age VARCHAR(50),
									Social VARCHAR(50),
									First VARCHAR(50),
									Middle VARCHAR(50),
									Last VARCHAR(50),
									Phone VARCHAR(50),
									Email VARCHAR(50),
									Address1 VARCHAR(50),
									Address2 VARCHAR(50),
									City VARCHAR(50),
									State VARCHAR(50),
									Zipcode VARCHAR(50),
									District_id VARCHAR(50),
									Education VARCHAR(50),
									MaritalStatus VARCHAR(50),
									Household_Size VARCHAR(50),
									Retired VARCHAR(50),

									)

----------------------------------------------------------------------------------------------------------------

select * from stg_Customer_Details_Discard
--TRUNCATE TABLE stg_Customer_Details_Discard
									
CREATE TABLE stg_Customer_Details_Discard(
											Client_id VARCHAR(50),
									Sex VARCHAR(50),
									FullDate VARCHAR(50),
									Day VARCHAR(50),
									Month VARCHAR(50),
									Year VARCHAR(50),
									Age VARCHAR(50),
									Social VARCHAR(50),
									First VARCHAR(50),
									Middle VARCHAR(50),
									Last VARCHAR(50),
									Phone VARCHAR(50),
									Email VARCHAR(50),
									Address1 VARCHAR(50),
									Address2 VARCHAR(50),
									City VARCHAR(50),
									State VARCHAR(50),
									Zipcode VARCHAR(50),
									District_id VARCHAR(50),
									Education VARCHAR(50),
									MaritalStatus VARCHAR(50),
									Household_Size VARCHAR(50),
									Retired VARCHAR(50),
									Error_Reson VARCHAR(1000)
									)

/*******************************************************************************************************************************************************************************/
---- CUSTOMER DETAILS AUDIT TABLE LOAD SP -----------------------------------

--GO
--CREATE PROC SP_AUDIT_TABLE_CUSTOMER_DETAILS
--(
--@FileName VARCHAR(50)
--)
--AS
--BEGIN
--	DECLARE @Total_Records INT,
--			@Error_Records INT,
--			@Success_Records INT

--	SELECT @Total_Records=COUNT(1) FROM STG_CUSTOMER_DETAILS 
--	SELECT @Error_Records =COUNT(*) FROM stg_Customer_Details_Discard
--	SELECT @Success_Records =COUNT(*) FROM stg_Customer_Details_Success

--	INSERT INTO DATA_LOAD_AUDIT_table(File_Name,TotalRecordInSource,NewRecords,ExistingRecords,Error_Records,LoadedInTarget,LoadedDateTime)
--	VALUES (@FileName,@Total_Records,@Success_Records,0,@Error_Records,@Success_Records,GETDATE())

--END

--EXEC SP_AUDIT_TABLE_CUSTOMER_DETAILS 'NIRANJAN' 
/***************************************************************************************************************************************************/
--------------------------- CUSTOMER VALIDATION ---------------------------------------------------------------
--REVISED/LATEST USED ONE --

GO
ALTER PROC Customer_Data_Validations
(
    @FileName VARCHAR(50)
)
AS
BEGIN
    DECLARE @Total_Records INT,
            @Error_Records INT,
            @Success_Records INT

    -- Clear the discard table to ensure no residual data exists
    TRUNCATE TABLE stg_Customer_Details_Discard

    -- Insert invalid date of birth records
    INSERT INTO stg_Customer_Details_Discard
    SELECT *, 'INVALID DATE OF BIRTH' 
    FROM STG_CUSTOMER_DETAILS
    WHERE ISDATE(FullDate) = 0

    -- Insert invalid gender records
    INSERT INTO stg_Customer_Details_Discard
    SELECT *, 'INVALID GENDER'
    FROM STG_CUSTOMER_DETAILS
    WHERE Sex NOT IN ('MALE', 'FEMALE')

    -- Insert invalid SSN records
    INSERT INTO stg_Customer_Details_Discard
    SELECT *, 'INVALID SSN'
    FROM STG_CUSTOMER_DETAILS
    WHERE LEN(REPLACE(SOCIAL, '-', '')) <> 9

    -- Insert invalid email records
    INSERT INTO stg_Customer_Details_Discard
    SELECT *, 'INVALID EMAIL'
    FROM STG_CUSTOMER_DETAILS
    WHERE 
        Email NOT LIKE '%@gmail.%' AND 
        Email NOT LIKE '%@outlook.%' AND 
        Email NOT LIKE '%@yahoo.%' AND 
        Email NOT LIKE '%@hotmail.%'

    -- Insert valid records into success table
    INSERT INTO stg_Customer_Details_Success
    SELECT S1.* 
    FROM STG_CUSTOMER_DETAILS S1
    LEFT JOIN stg_Customer_Details_Discard SD
    ON S1.Client_id = SD.Client_id
    WHERE SD.Client_id IS NULL

    -- Get counts
    SELECT @Total_Records = COUNT(1) FROM STG_CUSTOMER_DETAILS
    SELECT @Error_Records = COUNT(*) FROM stg_Customer_Details_Discard
    SELECT @Success_Records = COUNT(*) FROM stg_Customer_Details_Success

    -- Insert audit record
    INSERT INTO DATA_LOAD_AUDIT_table
    (
        File_Name,
        TotalRecordInSource,
        NewRecords,
        ExistingRecords,
        Error_Records,
        LoadedInTarget,
        LoadedDateTime
    )
    VALUES 
    (
        @FileName,
        @Total_Records,
        @Success_Records,
        0,  -- Assuming ExistingRecords is not used
        @Error_Records,
        @Success_Records,
        GETDATE()
    )
END

EXEC Customer_Data_Validations ?

/*************************************************************************************************************************/


--GO
--ALTER PROC Customer_Data_Validations
--AS 
--BEGIN

--	INSERT INTO stg_Customer_Details_Discard		
--	SELECT *, 'INVALID DATE OF BIRTH' 
--	FROM STG_CUSTOMER_DETAILS
--	WHERE ISDATE(FullDate)=0
	
--	INSERT INTO stg_Customer_Details_Discard
--	SELECT *,'INVALID GENDER'
--	FROM STG_CUSTOMER_DETAILS
--	WHERE Sex NOT IN ('MALE','FEMALE')
	
--	INSERT INTO stg_Customer_Details_Discard
--	SELECT *,'INVALID SSN'
--	FROM STG_CUSTOMER_DETAILS
--	WHERE LEN(REPLACE(SOCIAL,'-',''))<>9
	
	
--	INSERT INTO stg_Customer_Details_Discard
--	--SELECT *,'INVALID EMAIL'
--	--FROM STG_CUSTOMER_DETAILS
--	--WHERE SUBSTRING(Email,CHARINDEX('@',Email)+1,(CHARINDEX('.',Email,CHARINDEX('@',EMAIL)+1)-(CHARINDEX('@',Email)+1) )) NOT IN ('gmail','outlook','yahoo','hotmail')
	
--	SELECT *, 'INVALID EMAIL'
--	FROM STG_CUSTOMER_DETAILS
--	WHERE 
--	    Email NOT LIKE '%@gmail.%' AND 
--	    Email NOT LIKE '%@outlook.%' AND 
--	    Email NOT LIKE '%@yahoo.%' AND 
--	    Email NOT LIKE '%@hotmail.%';
	
	
--	INSERT INTO stg_Customer_Details_Success
--	SELECT S1.* 
--	FROM STG_CUSTOMER_DETAILS S1
--	LEFT JOIN stg_Customer_Details_Discard SD
--	ON S1.Client_id=SD.Client_id
--	WHERE SD.Client_id IS NULL
	

--END 

--EXEC Customer_Data_Validations

/************************************************ STAGGING BANK ********************************************************/

CREATE TABLE STG_Bank(
						BankId VARCHAR(50)
						,BankCode VARCHAR(50)
						,BankName VARCHAR(100)
						)


TRUNCATE TABLE STG_Bank

SELECT * FROM STG_Bank

/******************************BRANCH STAGGING TABLE********************************************************/

TRUNCATE TABLE Stg_Branch
GO
TRUNCATE TABLE Stg_Branch_Sucess
GO
TRUNCATE TABLE Stg_Branch_Discard

SELECT * FROM BANK_PROJECT_ODS..Branch
SELECT * FROM Stg_Branch
SELECT * FROM Stg_Branch_Discard
SELECT * FROM Stg_Branch_Sucess

SELECT * FROM DATA_LOAD_AUDIT_TABLE


CREATE TABLE Stg_Branch(
						BranchId VARCHAR(50)
						,BranchCode VARCHAR(50)
						,BranchName VARCHAR(50)
						,Bankcode VARCHAR(50)
						,BranchType VARCHAR(50)
						,Branch_Address VARCHAR(50)
						,Country VARCHAR(50)
						,State VARCHAR(50)
						,County VARCHAR(50)
						,IFSC_Code VARCHAR(50)
						,Town VARCHAR(50)
						,BranchOpenDate VARCHAR(50)
						)


CREATE TABLE Stg_Branch_Sucess(
						BranchId VARCHAR(50)
						,BranchCode VARCHAR(50)
						,BranchName VARCHAR(50)
						,Bankcode VARCHAR(50)
						,BranchType VARCHAR(50)
						,Branch_Address VARCHAR(50)
						,Country VARCHAR(50)
						,State VARCHAR(50)
						,County VARCHAR(50)
						,IFSC_Code VARCHAR(50)
						,Town VARCHAR(50)
						,BranchOpenDate VARCHAR(50)
						)
						
CREATE TABLE Stg_Branch_Discard(
						BranchId VARCHAR(50)
						,BranchCode VARCHAR(50)
						,BranchName VARCHAR(50)
						,Bankcode VARCHAR(50)
						,BranchType VARCHAR(50)
						,Branch_Address VARCHAR(50)
						,Country VARCHAR(50)
						,State VARCHAR(50)
						,County VARCHAR(50)
						,IFSC_Code VARCHAR(50)
						,Town VARCHAR(50)
						,BranchOpenDate VARCHAR(50)
						,Error_Reason VARCHAR(1000)
						)

-----Branch Data Validation ---------------------------------


--GO
--ALTER PROC Branch_Data_Validations
--(
--    @FileName VARCHAR(50)
--)
--AS
--BEGIN
--    DECLARE @Total_Records INT,
--            @Error_Records INT,
--            @Success_Records INT

--    -- Clear the discard table to ensure no residual data exists
--    TRUNCATE TABLE Stg_Branch_Discard

--    -- Insert invalid bankcode records
--   	INSERT INTO Stg_Branch_Discard		
--	SELECT *, 'INVALID BANKCODE NUMBER'
--	FROM Stg_Branch
--	WHERE ISNUMERIC(Bankcode)=0

--    -- Insert invalid datetype records
--	INSERT INTO Stg_Branch_Discard		
--	SELECT *, 'INVALID DATE TYPE'
--	FROM Stg_Branch
--	WHERE ISDATE(BranchOpenDate)=0

--    -- Insert valid records into success table
--    INSERT INTO Stg_Branch_Sucess
--    SELECT B1.* 
--    FROM Stg_Branch_Sucess B1
--    LEFT JOIN Stg_Branch_Discard SD
--    ON B1.Client_id = SD.Client_id
--    WHERE SD.Client_id IS NULL

--    -- Get counts
--    SELECT @Total_Records = COUNT(1) FROM STG_CUSTOMER_DETAILS
--    SELECT @Error_Records = COUNT(*) FROM stg_Customer_Details_Discard
--    SELECT @Success_Records = COUNT(*) FROM stg_Customer_Details_Success

--    -- Insert audit record
--    INSERT INTO DATA_LOAD_AUDIT_table
--    (
--        File_Name,
--        TotalRecordInSource,
--        NewRecords,
--        ExistingRecords,
--        Error_Records,
--        LoadedInTarget,
--        LoadedDateTime
--    )
--    VALUES 
--    (
--        @FileName,
--        @Total_Records,
--        @Success_Records,
--        0,  -- Assuming ExistingRecords is not used
--        @Error_Records,
--        @Success_Records,
--        GETDATE()
--    )
--END

	--INSERT INTO Stg_Branch_Discard		
	--SELECT *, 'INVALID BANKCODE NUMBER'
	--FROM Stg_Branch
	--WHERE ISNUMERIC(Bankcode)=0

	--INSERT INTO Stg_Branch_Discard		
	--SELECT *, 'INVALID DATE TYPE'
	--FROM Stg_Branch
	--WHERE ISDATE(BranchOpenDate)=0

/*IN BRANCH TABLE BANKCODE IS BRANCH_ID*/
/******************************************************** ACCOUNT STAGGING TABLE ****************************************************/

CREATE TABLE STG_ACCOUNT(
    AccountId VARCHAR(50),
    AccountNumber VARCHAR(50),
    AccountType VARCHAR(50),
    ProductCode VARCHAR(50),
    BranchCode VARCHAR(50),
    CIF_Number VARCHAR(50),
    Balance VARCHAR(50),
    AccountOpenDate VARCHAR(50),
    Status VARCHAR(50),
    ATMCardNumber VARCHAR(50),
    ATMPin VARCHAR(50),
    NB_UserId VARCHAR(50),
    NB_Password VARCHAR(50)
);

CREATE TABLE STG_ACCOUNT_SUCCESS(
    AccountId VARCHAR(50),
    AccountNumber VARCHAR(50),
    AccountType VARCHAR(50),
    ProductCode VARCHAR(50),
    BranchCode VARCHAR(50),
    CIF_Number VARCHAR(50),
    Balance VARCHAR(50),
    AccountOpenDate VARCHAR(50),
    Status VARCHAR(50),
    ATMCardNumber VARCHAR(50),
    ATMPin VARCHAR(50),
    NB_UserId VARCHAR(50),
    NB_Password VARCHAR(50)
);

CREATE TABLE STG_ACCOUNT_DISCARD(
    AccountId VARCHAR(50),
    AccountNumber VARCHAR(50),
    AccountType VARCHAR(50),
    ProductCode VARCHAR(50),
    BranchCode VARCHAR(50),
    CIF_Number VARCHAR(50),
    Balance VARCHAR(50),
    AccountOpenDate VARCHAR(50),
    Status VARCHAR(50),
    ATMCardNumber VARCHAR(50),
    ATMPin VARCHAR(50),
    NB_UserId VARCHAR(50),
    NB_Password VARCHAR(50),
    Error_Reason VARCHAR(1000)
);

SELECT * FROM STG_ACCOUNT

SELECT * FROM STG_ACCOUNT_DISCARD

SELECT * FROM STG_ACCOUNT_SUCCESS

--TRUNCATE TABLE STG_ACCOUNT
--GO
--TRUNCATE TABLE STG_ACCOUNT_DISCARD
--GO
--TRUNCATE TABLE STG_ACCOUNT_SUCCESS

SELECT * FROM BANK_PROJECT_ODS..ACCOUNT

--TRUNCATE TABLE BANK_PROJECT_ODS..ACCOUNT

-------------------------------------------------------------------------------------------------------------------------------------------
-------ACCOUNT VALIDATION----------------------
--GO
--CREATE PROC ACCOUNT_DATA_VALIDATION
--AS 
--BEGIN

--	INSERT INTO STG_ACCOUNT_DISCARD		
--	SELECT *, 'INVALID ACCOUNT NUMBER'
--	FROM STG_ACCOUNT
--	WHERE LEN(CAST(AccountNumber AS VARCHAR)) != 16

--	INSERT INTO STG_ACCOUNT_DISCARD		
--	SELECT *, 'INVALID ATM NUMBER'
--	FROM STG_ACCOUNT
--	WHERE LEN(CAST(ATMCardNumber AS VARCHAR)) != 16
	
--	INSERT INTO STG_ACCOUNT_DISCARD		
--	SELECT *, 'INVALID ACCOUNT NUMBER' 
--	FROM STG_ACCOUNT
--	WHERE AccountNumber NOT IN (SELECT ATMCardNumber FROM STG_ACCOUNT)

--	INSERT INTO STG_ACCOUNT_DISCARD		
--	SELECT *, 'INVALID ACCOUNT OPEN DATE' 
--	FROM STG_ACCOUNT
--	WHERE ISDATE(AccontOpenDate)=0 

--	INSERT INTO STG_ACCOUNT_SUCESS		
--	SELECT *, 'VALID ATM NUMBER'
--	FROM STG_ACCOUNT
--	WHERE LEN(CAST(ATMCardNumber AS VARCHAR)) = 16

--	INSERT INTO STG_ACCOUNT_SUCESS
--	SELECT A1.* 
--	FROM STG_ACCOUNT A1
--	LEFT JOIN STG_ACCOUNT_DISCARD A2
--	ON A1.AccountId=A2.AccountId
--	WHERE A2.AccountId IS NULL
	

--END

--EXEC ACCOUNT_DATA_VALIDATION



TRUNCATE STG_ACCOUNT
GO
TRUNCATE STG_ACCOUNT_SUCESS
GO
TRUNCATE STG_ACCOUNT_DISCARD
 
/****************************************** STAG TABLE FOR PRODUCT MASTER ***********************************************************************************/
select * from STG_PRODUCT_MASTER


--TRUNCATE TABLE STG_PRODUCT_MASTER

CREATE TABLE STG_PRODUCT_MASTER(
								 ProductID VARCHAR(50)
								,PRODUCT_TYPE VARCHAR(50)
								,DESCRIPTION_OF_THE_PRODUCT VARCHAR(100)
								)


CREATE TABLE STG_PRODUCT_MASTER_DISCARD(
								 ProductID VARCHAR(50)
								,PRODUCT_TYPE VARCHAR(50)
								,DESCRIPTION_OF_THE_PRODUCT VARCHAR(100)
								)


CREATE TABLE STG_PRODUCT_MASTER_SUCESS(
								 ProductID VARCHAR(50)
								,PRODUCT_TYPE VARCHAR(50)
								,DESCRIPTION_OF_THE_PRODUCT VARCHAR(100)
								)



/****************************************** STAG TABLE FOR CHANNEL MASTER ***********************************************************************************/
SELECT * FROM STG_CHANNEL_MASTER
SELECT * FROM STG_CHANNEL_MASTER_SUCCESS
SELECT * FROM STG_CHANNEL_MASTER_DISCARD

--TRUNCATE TABLE STG_CHANNEL_MASTER
--GO
--TRUNCATE TABLE STG_CHANNEL_MASTER_SUCCESS
--GO
--TRUNCATE TABLE STG_CHANNEL_MASTER_DISCARD


--DROP TABLE STG_CHANNEL_MASTER
--DROP TABLE STG_CHANNEL_MASTER_DISCARD
--DROP TABLE STG_CHANNEL_MASTER_SUCCESS


TRUNCATE TABLE STG_CHANNEL_MASTER


CREATE TABLE STG_CHANNEL_MASTER(
								ChannelID VARCHAR(50)
								,Channel_Type VARCHAR(50)
								,Description_Of_The_Channel NVARCHAR(100)
								)

CREATE TABLE STG_CHANNEL_MASTER_DISCARD(
								ChannelID VARCHAR(50)
								,Channel_Type VARCHAR(50)
								,Description_Of_The_Channel NVARCHAR(100)
								)

CREATE TABLE STG_CHANNEL_MASTER_SUCCESS(
								ChannelID VARCHAR(50)
								,Channel_Type VARCHAR(50)
								,Description_Of_The_Channel NVARCHAR(100)
								)

/***************************************************************************************************************************/
/************************************** STAGGING CUSTOMER_ACCOUNT TABLE *************************************************************************************/

CREATE TABLE STG_CUSTOMER_ACCOUNT(
								 Customer_Acc_ID VARCHAR(50)
								,Customer_ID VARCHAR(50)
								,AccountID VARCHAR(50)
								,CustomerContactID VARCHAR(50)
								)

CREATE TABLE STG_CUSTOMER_ACCOUNT_DISCARD(
								 Customer_Acc_ID VARCHAR(50)
								,Customer_ID VARCHAR(50)
								,AccountID VARCHAR(50)
								,CustomerContactID VARCHAR(50)
								)

CREATE TABLE STG_CUSTOMER_ACCOUNT_SUCCESS(
								 Customer_Acc_ID VARCHAR(50)
								,Customer_ID VARCHAR(50)
								,AccountID VARCHAR(50)
								,CustomerContactID VARCHAR(50)
								)

SELECT * FROM STG_CUSTOMER_ACCOUNT

--TRUNCATE TABLE STG_CUSTOMER_ACCOUNT
--GO
--TRUNCATE TABLE STG_CUSTOMER_ACCOUNT_DISCARD
--GO
--TRUNCATE TABLE STG_CUSTOMER_ACCOUNT_SUCCESS

SELECT * FROM STG_CUSTOMER_DETAILS

SELECT * FROM STG_CUSTOMER_ACCOUNT
SELECT * FROM STG_CUSTOMER_ACCOUNT_DISCARD
SELECT * FROM STG_CUSTOMER_ACCOUNT_SUCCESS

/***************************************************** TRANSACTION TYPEMASTER ************************************************************************************************************/
SELECT * FROM STG_TransacationTypemaster
--TRUNCATE TABLE BANK_PROJECT..STG_TransacationTypemaster

CREATE TABLE STG_TransacationTypemaster(
									 TransactionTypeID VARCHAR(50)
									,TransactionName VARCHAR(50)
									,TransactionDescription VARCHAR(50)
								   )

TRUNCATE TABLE STG_TransacationTypemaster



/***************************************************************************************************************************************/
-- STAGGING FACT BANK TRANSACTION TABLE 

CREATE TABLE STG_BANK_TRANSACTION(
							  Trans_id VARCHAR(50)
							 ,Account_id VARCHAR(50)
							 ,Type VARCHAR(50)
							 ,Operation VARCHAR(50)
							 ,TransactionType VARCHAR(50)
							 ,Debit VARCHAR(50)
							 ,Credit VARCHAR(50)
							 ,Amount VARCHAR(50)
							 ,Balance VARCHAR(50)
							 ,BankId VARCHAR(50)
							 ,Channel VARCHAR(50)
							 ,TransactionDate VARCHAR(50)
							 )

CREATE TABLE STG_BANK_TRANSACTION_SUCCESS(
							  Trans_id VARCHAR(50)
							 ,Account_id VARCHAR(50)
							 ,Type VARCHAR(50)
							 ,Operation VARCHAR(50)
							 ,TransactionType VARCHAR(50)
							 ,Debit VARCHAR(50)
							 ,Credit VARCHAR(50)
							 ,Amount VARCHAR(50)
							 ,Balance VARCHAR(50)
							 ,BankId VARCHAR(50)
							 ,Channel VARCHAR(50)
							 ,TransactionDate VARCHAR(50)
							 )

CREATE TABLE STG_BANK_TRANSACTION_DISCARD(
							  Trans_id VARCHAR(50)
							 ,Account_id VARCHAR(50)
							 ,Type VARCHAR(50)
							 ,Operation VARCHAR(50)
							 ,TransactionType VARCHAR(50)
							 ,Debit VARCHAR(50)
							 ,Credit VARCHAR(50)
							 ,Amount VARCHAR(50)
							 ,Balance VARCHAR(50)
							 ,BankId VARCHAR(50)
							 ,Channel VARCHAR(50)
							 ,TransactionDate VARCHAR(50)
							 )

SELECT * FROM STG_BANK_TRANSACTION
SELECT * FROM STG_BANK_TRANSACTION_SUCCESS
SELECT * FROM STG_BANK_TRANSACTION_DISCARD



--TRUNCATE TABLE STG_BANK_TRANSACTION
--GO
--TRUNCATE TABLE STG_BANK_TRANSACTION_SUCCESS
--GO
--TRUNCATE TABLE STG_BANK_TRANSACTION_DISCARD

/***************************************************************************************************************************************/

THIS IS MY STAGGING TABLE 

CREATE TABLE STG_BANK_TRANSACTION(
							  Trans_id VARCHAR(50)
							 ,Account_id VARCHAR(50)
							 ,Type VARCHAR(50)
							 ,Operation VARCHAR(50)
							 ,TransactionType VARCHAR(50)
							 ,Debit VARCHAR(50)
							 ,Credit VARCHAR(50)
							 ,Amount VARCHAR(50)
							 ,Balance VARCHAR(50)
							 ,BankId VARCHAR(50)
							 ,Channel VARCHAR(50)
							 ,TransactionDate VARCHAR(50)
							 )

CREATE TABLE STG_BANK_TRANSACTION_SUCCESS(
							  Trans_id VARCHAR(50)
							 ,Account_id VARCHAR(50)
							 ,Type VARCHAR(50)
							 ,Operation VARCHAR(50)
							 ,TransactionType VARCHAR(50)
							 ,Debit VARCHAR(50)
							 ,Credit VARCHAR(50)
							 ,Amount VARCHAR(50)
							 ,Balance VARCHAR(50)
							 ,BankId VARCHAR(50)
							 ,Channel VARCHAR(50)
							 ,TransactionDate VARCHAR(50)
							 )

CREATE TABLE STG_BANK_TRANSACTION_DISCARD(
							  Trans_id VARCHAR(50)
							 ,Account_id VARCHAR(50)
							 ,Type VARCHAR(50)
							 ,Operation VARCHAR(50)
							 ,TransactionType VARCHAR(50)
							 ,Debit VARCHAR(50)
							 ,Credit VARCHAR(50)
							 ,Amount VARCHAR(50)
							 ,Balance VARCHAR(50)
							 ,BankId VARCHAR(50)
							 ,Channel VARCHAR(50)
							 ,TransactionDate VARCHAR(50)
							 )

AND THIS IS MY ODS DATABASE TABLE


CREATE TABLE BANK_TRANSACTION(
							  Branch_TransactionId BIGINT PRIMARY KEY IDENTITY(1,1)
							 ,Customer_Acc_Id INT FOREIGN KEY REFERENCES CUSTOMER_ACCOUNT(Customer_Acc_ID)
							 ,ChannelID INT FOREIGN KEY REFERENCES Channel_Master(ChannelID)
							 ,TransactionTypeID SMALLINT FOREIGN KEY REFERENCES TransacationTypemaster(TransactionTypeID)
							 ,BankId INT FOREIGN KEY REFERENCES Bank(BankId)
							 ,BranchId INT FOREIGN KEY REFERENCES Branch(BranchId)
							 ,TransactionDate DATETIME 
							 ,Balance MONEY
							 ,Credit MONEY
							 ,Debit MONEY
							 )

THIS IS MY ODS DATA LOAD STORED PROCEDURES 



 GO
CREATE PROC SP_BANK_TRANSACTION_DATA_LOAD
(
    @FileName VARCHAR(250)
)
AS
BEGIN
UPDATE BT
SET 
	 BT.Customer_Acc_Id=CA.Customer_Acc_ID
	,BT.ChannelID=CM.ChannelID
	,BT.TransactionTypeID=TT.TransactionTypeID
	,BT.BankId=B.BankId
	,BT.BranchId=BR.BranchId
	,BT.TransactionDate=SBT.TransactionDate
	,BT.Balance=SBT.Balance
	,BT.Credit=SBT.Credit
	,BT.Debit=SBT.Debit
FROM BANK_TRANSACTION BT
JOIN CUSTOMER_ACCOUNT CA
ON BT.Customer_Acc_Id=CA.Customer_Acc_ID
JOIN CHANNEL_MASTER CM
ON BT.ChannelID=CM.ChannelID
JOIN TransacationTypemaster TT
ON BT.TransactionTypeID=TT.TransactionTypeID
JOIN Bank B
ON BT.BankId=B.BankId
JOIN Branch BR
ON BT.BranchId=BR.BranchId
JOIN BANK_PROJECT..STG_BANK_TRANSACTION SBT
ON BT.TransactionDate=SBT.TransactionDate

INSERT INTO BANK_TRANSACTION(Customer_Acc_Id,ChannelID,TransactionTypeID,BankId,BranchId,TransactionDate,Balance,Credit,Debit)
SELECT CA.Customer_Acc_ID,CM.ChannelID,TT.TransactionTypeID,B.BankId,BR.BranchId,SBT.TransactionDate,SBT.Balance,SBT.Credit,SBT.Debit 
FROM BANK_TRANSACTION BT
JOIN 
	CUSTOMER_ACCOUNT CA
ON 
	BT.Customer_Acc_Id=CA.Customer_Acc_ID
JOIN 
	CHANNEL_MASTER CM
ON
	BT.ChannelID=CM.ChannelID
JOIN
	TransacationTypemaster TT
ON BT.TransactionTypeID=TT.TransactionTypeID
JOIN
	Bank B
ON 
	BT.BankId=B.BankId
JOIN 
	Branch BR
ON
	BT.BranchId=BR.BranchId
JOIN
	BANK_PROJECT..STG_BANK_TRANSACTION SBT
ON
	BT.TransactionDate=SBT.TransactionDate


 -- Insert audit record
        INSERT INTO BANK_PROJECT..DATA_LOAD_AUDIT_table
        (
            File_Name,
			LoadedDateTime
        )
        VALUES 
        (
            @FileName,
            GETDATE()
        )


END


FIX IT 

/**************************************************************************************************************************************/