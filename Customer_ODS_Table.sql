use BANK_PROJECT_ODS
--ODS
select * from Customer

TRUNCATE TABLE Customer

CREATE TABLE Customer(
						customer_Id INT IDENTITY(1,1) PRIMARY KEY
						,Client_id VARCHAR(50)
						,FirstName VARCHAR(50)
						,MiddleName VARCHAR(50)
						,LastName VARCHAR(50)
						,Gender VARCHAR(10)
						,SSN VARCHAR(20)
						,DOB DATE
						)

/*************************************************************************************************************************/

select * from BANK_PROJECT_ODS..Customer_Contact_Details


						
CREATE TABLE BANK_PROJECT_ODS..Customer_Contact_Details (
    Customer_Contact_ID INT IDENTITY(1,1) PRIMARY KEY
    ,Customer_Id INT FOREIGN KEY REFERENCES Customer(customer_Id)
    ,Phone VARCHAR(50)
    ,Email VARCHAR(50)
    ,Address_1 VARCHAR(50)
    ,Address_2 VARCHAR(50)
    ,City VARCHAR(50)
    ,State VARCHAR(50)
    ,Zipcode VARCHAR(50)
    ,District_Id VARCHAR(50)
    ,EducationStatus VARCHAR(50)
    ,MartialStatus VARCHAR(50)
    ,Household_Size VARCHAR(50)
    ,Retired VARCHAR(50)
)
/*************************************************************************************************************************/

GO
ALTER PROC CUSTOMER_DATA_LOAD
AS
BEGIN

		UPDATE C SET C.FirstName=CS.FIRST,
					 C.LastName=CS.Last,
					 C.MiddleName=CS.Middle,
					 C.Gender=CS.Sex,
					 C.DOB=CS.FullDate
		FROM Customer C
		INNER JOIN BANK_PROJECT..stg_Customer_Details_Success CS
		ON CS.Client_id=C.Client_id
	
	INSERT INTO Customer (Client_id,FirstName,MiddleName,LastName,Gender,SSN,DOB)
	SELECT CS.Client_id, CS.First,CS.Middle,CS.Last,CS.Sex,CS.Social,CS.FullDate
	FROM BANK_PROJECT..stg_Customer_Details_Success CS
	LEFT JOIN Customer C 
	ON CS.Client_id=C.Client_id
	WHERE C.Client_id IS NULL
	
END

EXEC CUSTOMER_DATA_LOAD

/*************************************************************************************************************************/

GO
ALTER PROC Customer_Contact_Details_Data_Load
AS 
BEGIN

	UPDATE CC SET Email=CS.Email,Phone=CS.Phone,Address_1=CS.Address1,MartialStatus=CS.MaritalStatus
	FROM Customer_Contact_Details CC
	INNER JOIN Customer C 
	ON CC.Customer_Id=C.customer_Id
	INNER JOIN BANK_PROJECT..stg_Customer_Details_Success CS
	ON CS.Client_id=C.Client_id
	
	
	INSERT INTO Customer_Contact_Details(
										Customer_Id
										,Phone
										,Email
										,Address_1
										,Address_2
										,City
										,State
										,Zipcode
										,District_Id
										,EducationStatus
										,MartialStatus
										,Household_Size
										,Retired
										)
	
	SELECT C.customer_Id
		   ,CS.Phone
		   ,CS.Email
		   ,CS.Address1
		   ,CS.Address2
		   ,CS.City
		   ,CS.State
		   ,CS.Zipcode
		   ,CS.District_id
		   ,CS.Education
		   ,CS.MaritalStatus
		   ,CS.Household_Size
		   ,CS.Retired
	FROM BANK_PROJECT..stg_Customer_Details_Success CS
	INNER JOIN Customer C 
	ON CS.Client_id=C.Client_id
	LEFT JOIN Customer_Contact_Details CC 
	ON CC.Customer_Id=C.customer_Id
	WHERE CC.Customer_Contact_ID IS NULL 
	
END


EXEC Customer_Contact_Details_Data_Load


/************************************************ ODS BANK TABLE********************************************************/
SELECT * FROM Bank

CREATE TABLE Bank(
				  BankId INT PRIMARY KEY IDENTITY(1,1)
						,BankCode VARCHAR(20)
						,BankName VARCHAR(100)
						)



/*******************************BANK STAGE TO ODS LOAD *****************/
SELECT * FROM Bank

GO
ALTER PROC BANK_DATA_LOAD
AS
BEGIN
	INSERT INTO Bank
	SELECT BankCode,BankName 
	FROM BANK_PROJECT..STG_Bank
END

EXEC BANK_DATA_LOAD




/******************************BRANCH ODS TABLE********************************************************/
/*---------VALIDATION REQUIREMENT-------------------------------------------------------------------
•	Branchid should be an auto genetrated PK (DONE)
•	BankId should be a foreign key of Bank table (DONE)
•	Bancode should be numeric []
•	Branch name should be unique (DONE)
•	Branch opendate is date column (DONE)
-------------------------------------------------------------------------------------------------*/
SELECT * FROM Branch

CREATE TABLE Branch(
						BranchId INT PRIMARY KEY IDENTITY(1,1)
						,BranchCode VARCHAR(20)
						,BranchName VARCHAR(20) UNIQUE NOT NULL
						,Bankcode  INT
						,BankId INT FOREIGN KEY REFERENCES BANK(BankId)
						,BranchType VARCHAR(50)
						,Branch_Address VARCHAR(500)
						,Country VARCHAR(50)
						,State VARCHAR(50)
						,District VARCHAR(50)
						,Region VARCHAR(50)
						,City VARCHAR(50)					
						,IFSC_Code VARCHAR(50)
						,BranchOpenDate DATE
						)


ALTER TABLE Branch
ALTER COLUMN BranchName VARCHAR(100)


--THE CREATE TABLE BRANCH NEED TO BE RUN IT HAS NOT BEEN EXECUTED CAUSE VALIDATION POINT 3 IS NOT DONE YET AND THERE IS FOREIGN KEY THATS WHY|

------------------------BRANCH DATA ODS DATA LOAD-------------------------------------------------------------------

--SELECT 
--    LTRIM(RTRIM(SUBSTRING(B2.Branch_Address, LEN(B2.Branch_Address) - CHARINDEX(',', REVERSE(B2.Branch_Address)) + 2, LEN(B2.Branch_Address)))) AS District
--FROM 
--    BANK_PROJECT..Stg_Branch B2
--------------------------------Branch data validation and audit table --------------------------------------------

GO
ALTER PROC Branch_Data_Validations
(
    @FileName VARCHAR(50)
)
AS
BEGIN
    DECLARE @Total_Records INT,
            @Error_Records INT,
            @Success_Records INT

    -- Clear the discard table to ensure no residual data exists
    TRUNCATE TABLE BANK_PROJECT..Stg_Branch_Discard

 --   -- Insert invalid bankcode records
 --  	INSERT INTO BANK_PROJECT..Stg_Branch_Discard		
	--SELECT *, 'INVALID BANKCODE NUMBER'
	--FROM BANK_PROJECT..Stg_Branch
	--WHERE ISNUMERIC(Bankcode)=0



    -- Insert invalid datetype records
	INSERT INTO BANK_PROJECT..Stg_Branch_Discard		
	SELECT *, 'INVALID DATE TYPE'
	FROM BANK_PROJECT..Stg_Branch
	WHERE ISDATE(BranchOpenDate)=0

    -- Insert valid records into success table
    INSERT INTO BANK_PROJECT..Stg_Branch_Sucess
    SELECT B1.* 
    FROM BANK_PROJECT..Stg_Branch B1
    LEFT JOIN BANK_PROJECT..Stg_Branch_Discard SD
    ON B1.BranchId = SD.BranchId
    WHERE SD.Bankcode IS NULL

    -- Get counts
    SELECT @Total_Records = COUNT(1) FROM BANK_PROJECT..Stg_Branch
    SELECT @Error_Records = COUNT(*) FROM BANK_PROJECT..Stg_Branch_Discard
    SELECT @Success_Records = COUNT(*) FROM BANK_PROJECT..Stg_Branch_Sucess

    -- Insert audit record
    INSERT INTO BANK_PROJECT..DATA_LOAD_AUDIT_table
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

EXEC Branch_Data_Validations ?

/***********************************************************************************************************************************/
select * from Branch
select * from Bank
--UPDATED ONE

GO
ALTER PROC SP_ODS_BRANCH_DATA_LOAD
(
    @FileName VARCHAR(100)
)
AS
BEGIN
    DECLARE @Success_Records INT,
            @Total_Records INT,
            @NewRecords INT,
            @ExistingRecords INT

    BEGIN TRY
        -- Update existing records
        UPDATE B1
        SET 
               B1.BranchCode = B2.BranchCode,
               B1.BranchName = B2.BranchName + B2.BranchCode,
               B1.BankId = BK.BankId,
               B1.BranchType = B2.BranchType,
               B1.Branch_Address = B2.Branch_Address,
               B1.Country = B2.Country,
               B1.State = B2.State,
               B1.District = B2.County,
               B1.City = B2.Town,
               B1.IFSC_Code = B2.IFSC_Code,
               B1.BranchOpenDate = TRY_CAST(B2.BranchOpenDate AS DATE)
        FROM Branch B1
        INNER JOIN BANK_PROJECT..Stg_Branch_Sucess B2
            ON B1.BranchCode = B2.BranchCode
        INNER JOIN Bank BK
            ON B2.BankCode = BK.BankCode

        -- Inserting new records
        INSERT INTO Branch 
        (
            BranchCode,
            BranchName,
            BankId,
            BranchType,
            Branch_Address,
            Country,
            State,
            District,
            City,
            IFSC_Code,
            BranchOpenDate
        )
        SELECT 
            B2.BranchCode,
            B2.BranchName + B2.BranchCode,
            BK.BankId,
            B2.BranchType,
            B2.Branch_Address,
            B2.Country,
            B2.State,
            B2.County,
            B2.Town,
            B2.IFSC_Code,
            TRY_CAST(B2.BranchOpenDate AS DATE)
        FROM BANK_PROJECT..Stg_Branch_Sucess B2
        LEFT JOIN Branch B1 
            ON B2.BranchCode = B1.BranchCode
        INNER JOIN Bank BK
            ON B2.BankCode = BK.BankCode
        WHERE B1.BranchId IS NULL

        -- Getting counts for audit table
        SELECT @Total_Records = COUNT(1) FROM BANK_PROJECT..Stg_Branch
        SELECT @Success_Records = COUNT(1) FROM BANK_PROJECT..Stg_Branch_Sucess
        SELECT @NewRecords = COUNT(1)
        FROM BANK_PROJECT..Stg_Branch_Sucess B2
        LEFT JOIN Branch B1 
            ON B2.BranchCode = B1.BranchCode
        WHERE B1.BranchId IS NULL

        SELECT @ExistingRecords = @Success_Records - @NewRecords

        -- Inserting in audit table record
        INSERT INTO BANK_PROJECT..DATA_LOAD_AUDIT_table
        (
            File_Name,
            NewRecords,
            TotalRecordInSource,
            LoadedInTarget,
            ExistingRecords,
            LoadedDateTime
        )
        VALUES 
        (
            @FileName,
            @NewRecords,
            @Total_Records,
            @Success_Records,
            @ExistingRecords,
            GETDATE()
        )
    END TRY
    BEGIN CATCH
        -- Handleling errors
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE()
        RAISERROR (@ErrorMessage, 16, 1)
    END CATCH
END

EXEC SP_ODS_BRANCH_DATA_LOAD ?

SELECT * FROM Bank
SELECT * FROM Branch

--THE SP HAS NOT BEEN RUN BECAUSE OF THE 3RD NO. VALIDATION



--------------------------------------------------------------------------------------------------------------------------------------
/*************************** ACCOUNT ODS TABLE**************************************************************************************/
/* VALIDATION LIST
•	AccountId should be an auto generated identity PK column
•	should have productid and branchid foreign keys
•	Account number should be a sixteen digits number
•	ATM number should be a sixteen digits number
•	Account number <> ATM number
•	Account opendate should be a valid date
*/
select * from ACCOUNT


CREATE TABLE ACCOUNT(
						AccountId INT PRIMARY KEY IDENTITY(1,1) 
						,AccountNumber BIGINT
						,AccountType VARCHAR(20)
						,ProductId INT FOREIGN KEY REFERENCES Product_Master(ProductId) --validation requirement
						,BranchId INT FOREIGN KEY REFERENCES Branch(BranchId)  --validation requirement
						,CIF_Number VARCHAR(50)
						,Balance MONEY
						,AccontOpenDate DATETIME
						,Status CHAR(6)
						,ATMCardNumber BIGINT
						,ATMPin SMALLINT
						,NB_UserId VARCHAR(20)
						,NB_Password VARCHAR(20)
						)
--NEED TO BE EXECUTE


/*********************** ACCOUNT DATA VALIDATION ***************************************************************************************************/
select * from ACCOUNT
--LATEST ONE

GO
ALTER PROC ACCOUNT_DATA_VALIDATION
(
    @FileName VARCHAR(50)
)
AS
BEGIN
    DECLARE @Total_Records INT,
            @Error_Records INT,
            @Success_Records INT;

    -- Invalid Account Number
    INSERT INTO BANK_PROJECT..STG_ACCOUNT_DISCARD
    (AccountId, AccountNumber, AccountType, ProductCode, BranchCode, CIF_Number, Balance, AccountOpenDate, Status, ATMCardNumber, ATMPin, NB_UserId, NB_Password, Error_Reason)
    SELECT
        SA1.AccountId,SA1.AccountNumber,SA1.AccountType,SA1.ProductCode,SA1.BranchCode,SA1.CIF_Number,SA1.Balance,SA1.AccountOpenDate,SA1.Status,SA1.ATMCardNumber,
		SA1.ATMPin,SA1.NB_UserId,SA1.NB_Password,'INVALID ACCOUNT NUMBER' AS Error_Reason
    FROM BANK_PROJECT..STG_ACCOUNT SA1
    WHERE LEN(SA1.AccountNumber) != 14;

    -- Invalid ATM Card Number  
    INSERT INTO BANK_PROJECT..STG_ACCOUNT_DISCARD
    (AccountId, AccountNumber, AccountType, ProductCode, BranchCode, CIF_Number, Balance, AccountOpenDate, Status, ATMCardNumber, ATMPin, NB_UserId, NB_Password, Error_Reason)
    SELECT
        SA2.AccountId,SA2.AccountNumber,SA2.AccountType,SA2.ProductCode,SA2.BranchCode,SA2.CIF_Number,SA2.Balance,SA2.AccountOpenDate,SA2.Status,SA2.ATMCardNumber,
        SA2.ATMPin,SA2.NB_UserId,SA2.NB_Password,'INVALID ATM NUMBER' AS Error_Reason
    FROM BANK_PROJECT..STG_ACCOUNT SA2
    WHERE LEN(SA2.ATMCardNumber) != 15;

    -- Account Number not in ATM Card Number
    INSERT INTO BANK_PROJECT..STG_ACCOUNT_DISCARD
    (AccountId, AccountNumber, AccountType, ProductCode, BranchCode, CIF_Number, Balance, AccountOpenDate, Status, ATMCardNumber, ATMPin, NB_UserId, NB_Password, Error_Reason)
    SELECT
        SA3.AccountId,SA3.AccountNumber,SA3.AccountType,SA3.ProductCode,SA3.BranchCode,SA3.CIF_Number,SA3.Balance,SA3.AccountOpenDate,SA3.Status,SA3.ATMCardNumber,
        SA3.ATMPin,SA3.NB_UserId,SA3.NB_Password,'ACCOUNT NUMBER NOT IN ATM CARD NUMBERS' AS Error_Reason
    FROM BANK_PROJECT..STG_ACCOUNT SA3
    WHERE SA3.AccountNumber IN (SELECT SA4.ATMCardNumber FROM BANK_PROJECT..STG_ACCOUNT SA4);

    ---- Invalid Account Open Date
    --INSERT INTO BANK_PROJECT..STG_ACCOUNT_DISCARD
    --(AccountId, AccountNumber, AccountType, ProductCode, BranchCode, CIF_Number, Balance, AccountOpenDate, Status, ATMCardNumber, ATMPin, NB_UserId, NB_Password, Error_Reason)
    --SELECT
    --    SA4.AccountId,SA4.AccountNumber,SA4.AccountType,SA4.ProductCode,SA4.BranchCode,SA4.CIF_Number,SA4.Balance,SA4.AccountOpenDate,SA4.Status,
    --    SA4.ATMCardNumber,SA4.ATMPin,SA4.NB_UserId,SA4.NB_Password,'INVALID ACCOUNT OPEN DATE' AS Error_Reason
    --FROM BANK_PROJECT..STG_ACCOUNT SA4
    --WHERE ISDATE(SA4.AccountOpenDate)= 0;

    -- Valid Records
    INSERT INTO BANK_PROJECT..STG_ACCOUNT_SUCCESS
    (AccountId, AccountNumber, AccountType, ProductCode, BranchCode, CIF_Number, Balance, AccountOpenDate, Status, ATMCardNumber, ATMPin, NB_UserId, NB_Password)
    SELECT
        A1.AccountId,A1.AccountNumber,A1.AccountType,A1.ProductCode,A1.BranchCode,A1.CIF_Number,A1.Balance,A1.AccountOpenDate,A1.Status,A1.ATMCardNumber,
        A1.ATMPin,A1.NB_UserId,A1.NB_Password
    FROM BANK_PROJECT..STG_ACCOUNT A1
    --WHERE NOT EXISTS (
    --    SELECT 1
    --    FROM BANK_PROJECT..STG_ACCOUNT_DISCARD A2
    --    WHERE A1.AccountId = A2.AccountId
    --);
	 LEFT JOIN BANK_PROJECT..STG_ACCOUNT_DISCARD A2
  ON A1.AccountNumber=A2.AccountNumber
  WHERE A2.AccountId IS NULL

    -- Get counts
    SELECT @Total_Records = COUNT(1) FROM BANK_PROJECT..STG_ACCOUNT;
    SELECT @Error_Records = COUNT(*) FROM BANK_PROJECT..STG_ACCOUNT_DISCARD;
    SELECT @Success_Records = COUNT(*) FROM BANK_PROJECT..STG_ACCOUNT_SUCCESS;

    -- Insert audit record
    INSERT INTO BANK_PROJECT..DATA_LOAD_AUDIT_table
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
    );

END

EXEC ACCOUNT_DATA_VALIDATION

-----ACCOUNT ODS DATA LOAD --------------------------------------------------------------------------------------------------------------
--LATEST ONE

GO
ALTER PROC ACCOUNT_ODS_DATA_LOAD
(
    @FileName VARCHAR(50)
)
AS
BEGIN
    DECLARE @Total_Records INT,
            @Error_Records INT,
            @Success_Records INT
	
	-- Update existing records
	UPDATE A1
	SET
		 AccountNumber = A2.AccountNumber,
		 AccountType = A2.AccountType,
		 ProductId = PM1.ProductId,
		 BranchId = B.BranchId,
		 CIF_Number = A2.CIF_Number,
		 Balance = A2.Balance,
		 AccontOpenDate = A2.AccountOpenDate,
		 Status = A2.Status,
		 ATMCardNumber = A2.ATMCardNumber,
		 ATMPin = A2.ATMPin,
		 NB_UserId = A2.NB_UserId,
		 NB_Password = A2.NB_Password
	FROM ACCOUNT A1
	INNER JOIN BANK_PROJECT..STG_ACCOUNT_SUCCESS A2
	ON A1.AccountNumber = A2.AccountNumber  -- Assume this is the correct join condition
	JOIN PRODUCT_MASTER PM1
	ON A2.ProductCode = PM1.PRODUCT_TYPE  -- Adjust join condition to use ProductCode from STG_ACCOUNT_SUCCESS
	JOIN Branch B
	ON A2.BranchCode = B.BranchCode  -- Adjust join condition to use BranchCode from STG_ACCOUNT_SUCCESS

	-- Insert new records
	INSERT INTO ACCOUNT
	(AccountNumber, AccountType, ProductId, BranchId, CIF_Number, Balance, AccontOpenDate, Status, ATMCardNumber,
	ATMPin, NB_UserId, NB_Password)
	SELECT 
		A2.AccountNumber, A2.AccountType, PM1.ProductId, B.BranchId, A2.CIF_Number, A2.Balance, A2.AccountOpenDate, A2.Status,
		A2.ATMCardNumber, A2.ATMPin, A2.NB_UserId, A2.NB_Password
	FROM BANK_PROJECT..STG_ACCOUNT_SUCCESS A2
	LEFT JOIN ACCOUNT A1
	ON A1.AccountNumber = A2.AccountNumber
	JOIN PRODUCT_MASTER PM1
	ON A2.ProductCode = PM1.PRODUCT_TYPE   -- Adjust join condition to use ProductCode from STG_ACCOUNT_SUCCESS
	JOIN Branch B
	ON A2.BranchCode = B.BranchCode  -- Adjust join condition to use BranchCode from STG_ACCOUNT_SUCCESS
	WHERE A1.AccountNumber IS NULL

	-- Get counts
    SELECT @Total_Records = COUNT(1) FROM BANK_PROJECT..STG_ACCOUNT
    SELECT @Error_Records = COUNT(*) FROM BANK_PROJECT..STG_ACCOUNT_DISCARD
    SELECT @Success_Records = COUNT(*) FROM BANK_PROJECT..STG_ACCOUNT_SUCCESS

    -- Insert audit record
    INSERT INTO BANK_PROJECT..DATA_LOAD_AUDIT_table
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

EXEC ACCOUNT_ODS_DATA_LOAD

/******************************************** ODS TABLE FOR PRODUCT MASTER ********************************************************************************/
select * from PRODUCT_MASTER



CREATE TABLE PRODUCT_MASTER(
							 ProductID INT PRIMARY KEY IDENTITY(1,1)
							,PRODUCT_TYPE VARCHAR(30) UNIQUE NOT NULL
							,DESCRIPTION_OF_THE_PRODUCT VARCHAR(100)
							)

/********************* PRODUCT MASTER ODS DATA LOAD  *******************************************************************/

GO
ALTER PROC SP_PRODUCT_MASTER_ODS_DATA_LOAD

(
    @FileName VARCHAR(100)
)
AS
BEGIN
    DECLARE @Total_Records INT,
            @Error_Records INT,
            @Success_Records INT

UPDATE PM1
	SET 
		 PRODUCT_TYPE=PM2.PRODUCT_TYPE
		,DESCRIPTION_OF_THE_PRODUCT=PM2.DESCRIPTION_OF_THE_PRODUCT
	FROM PRODUCT_MASTER PM1
	INNER JOIN BANK_PROJECT..STG_PRODUCT_MASTER PM2
	ON PM1.PRODUCT_TYPE=PM2.PRODUCT_TYPE
	
	INSERT INTO PRODUCT_MASTER(PRODUCT_TYPE,DESCRIPTION_OF_THE_PRODUCT)
	SELECT PM2.PRODUCT_TYPE,PM2.DESCRIPTION_OF_THE_PRODUCT 
	FROM BANK_PROJECT..STG_PRODUCT_MASTER PM2
	--JOIN PRODUCT_MASTER PM1
	--ON PM1.PRODUCT_TYPE=PM2.PRODUCT_TYPE


	  -- Get counts
    SELECT @Total_Records = COUNT(1) FROM BANK_PROJECT..STG_PRODUCT_MASTER
    SELECT @Error_Records = COUNT(*) FROM BANK_PROJECT..STG_PRODUCT_MASTER_DISCARD
    SELECT @Success_Records = COUNT(*) FROM BANK_PROJECT..STG_PRODUCT_MASTER_SUCESS

    -- Insert audit record
    INSERT INTO BANK_PROJECT..DATA_LOAD_AUDIT_table
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

	

END


EXEC SP_PRODUCT_MASTER_ODS_DATA_LOAD


/****************************************** ODS TABLE FOR CHANNEL MASTER ***********************************************************************************/
SELECT * FROM CHANNEL_MASTER
--DROP TABLE CHANNEL_MASTER

CREATE TABLE CHANNEL_MASTER(
								ChannelID INT PRIMARY KEY IDENTITY(1,1)
								,Channel_Name VARCHAR(150)
								)

--- CHANNEL MASTER ODS DATA LOAD SP--------------------------

GO
ALTER PROC SP_CHANNEL_MASTER_DATA_LOAD
(
    @FileName VARCHAR(150)
)
AS
BEGIN
    DECLARE @Total_Records INT,
            @Error_Records INT,
            @Success_Records INT,
            @NewRecords INT,
            @ExistingRecords INT

    -- Update existing records
    UPDATE CM
    SET
        Channel_Name = CM2.Channel_Type 
    FROM
        CHANNEL_MASTER CM
    INNER JOIN
        BANK_PROJECT..STG_CHANNEL_MASTER CM2
    ON
        CM.Channel_Name = CM2.Channel_Type

    -- Insert new records
    INSERT INTO CHANNEL_MASTER (Channel_Name)
    SELECT CM2.Channel_Type
    FROM BANK_PROJECT..STG_CHANNEL_MASTER CM2
    LEFT JOIN CHANNEL_MASTER CM
    ON CM.Channel_Name = CM2.Channel_Type
    WHERE CM.ChannelID IS NULL

    -- Get counts
    SELECT @Total_Records = COUNT(1) FROM BANK_PROJECT..STG_CHANNEL_MASTER
    SELECT @Error_Records = COUNT(*) FROM BANK_PROJECT..STG_CHANNEL_MASTER_DISCARD 
    SELECT @Success_Records = COUNT(1) FROM CHANNEL_MASTER

    -- Calculate new records
    SELECT @NewRecords = COUNT(*) FROM BANK_PROJECT..STG_CHANNEL_MASTER CM2
    LEFT JOIN CHANNEL_MASTER CM
    ON CM.Channel_Name = CM2.Channel_Type
    WHERE CM.ChannelID IS NULL

    -- Calculate existing records (updated records)
    SELECT @ExistingRecords = COUNT(*) FROM BANK_PROJECT..STG_CHANNEL_MASTER CM2
    INNER JOIN CHANNEL_MASTER CM
    ON CM.Channel_Name = CM2.Channel_Type

    -- Insert audit record
    INSERT INTO BANK_PROJECT..DATA_LOAD_AUDIT_table
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
        @NewRecords,
        @ExistingRecords,
        @Error_Records,
        @Success_Records,
        GETDATE()
    )
END

EXEC SP_CHANNEL_MASTER_DATA_LOAD 

SELECT * FROM Customer
/**************************** CUSTOMER ACCOUNT *********************************************************************************************************************************************/
SELECT * FROM CUSTOMER_ACCOUNT

--DROP TABLE CUSTOMER_ACCOUNT

CREATE TABLE CUSTOMER_ACCOUNT(
								 Customer_Acc_ID INT PRIMARY KEY IDENTITY(1,1)
								,Customer_ID INT FOREIGN KEY REFERENCES CUSTOMER(CUSTOMER_ID)
								,AccountID INT FOREIGN KEY REFERENCES ACCOUNT(ACCOUNTID)
								,CustomerContactID INT FOREIGN KEY REFERENCES Customer_Contact_Details(Customer_contact_Id)
								)

/*************************************************** CUSTOMER ACCOUNT ODS DATA LOAD ********************************************************************************************************/
--RECENT ONE (IN USE)

go 
ALTER PROC SP_CUSTOMER_ACCOUNT_DATA_LOAD
(
    @FileName VARCHAR(250)
)
AS
BEGIN
	
	insert into CUSTOMER_ACCOUNT(Customer_ID,AccountID,CustomerContactID)
	select CA.Customer_ID, 
		   CA.AccountID,
		   CA.CustomerContactID 
	from BANK_PROJECT..STG_CUSTOMER_ACCOUNT CA
	JOIN 
		Customer C
	ON
		C.customer_Id=CA.Customer_ID
	JOIN 
		ACCOUNT A
	ON
		A.AccountId=CA.AccountID
	JOIN
		Customer_Contact_Details CCD
	ON
		CCD.Customer_Contact_ID=CA.CustomerContactID
	WHERE 
        NOT EXISTS (
            SELECT 1 
            FROM CUSTOMER_ACCOUNT CA 
            WHERE CA.Customer_ID = C.Customer_ID 
              AND CA.AccountID = A.AccountID 
              AND CA.CustomerContactID = CCD.Customer_Contact_ID
        )


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

/***********************************************************************************************************************/
--OLD ONE 

--GO
--ALTER PROC SP_CUSTOMER_ACCOUNT_DATA_LOAD
--(
--    @FileName VARCHAR(150)
--)
--AS
--BEGIN
--    DECLARE @Total_Records INT,
--            @Error_Records INT,
--            @Success_Records INT,
--            @NewRecords INT,
--            @ExistingRecords INT

--    -- Update existing records
--    UPDATE CA
--    SET
--        Customer_ID = CA2.Customer_ID,
--        AccountID = CA2.AccountID,
--        CustomerContactID = CA2.CustomerContactID
--    FROM
--        CUSTOMER_ACCOUNT CA
--    INNER JOIN
--        BANK_PROJECT..STG_CUSTOMER_ACCOUNT CA2
--    ON
--        CA.Customer_Acc_ID = CA2.Customer_Acc_ID

--    -- Insert new records
--    INSERT INTO CUSTOMER_ACCOUNT (Customer_ID, AccountID, CustomerContactID)
--    SELECT  
--        CA2.Customer_ID, 
--        CA2.AccountID, 
--        CA2.CustomerContactID
--    FROM 
--        BANK_PROJECT..STG_CUSTOMER_ACCOUNT CA2
--    LEFT JOIN 
--        CUSTOMER_ACCOUNT CA
--    ON 
--        CA.Customer_Acc_ID = CA2.Customer_Acc_ID
--    WHERE 
--        CA.Customer_Acc_ID IS NOT NULL

--    -- Get counts
--    SELECT @Total_Records = COUNT(1) FROM BANK_PROJECT..STG_CUSTOMER_ACCOUNT
--    SELECT @Error_Records = COUNT(1) FROM BANK_PROJECT..STG_CUSTOMER_ACCOUNT_DISCARD
--    SELECT @Success_Records = COUNT(1) FROM BANK_PROJECT..STG_CUSTOMER_ACCOUNT_SUCCESS

--    -- Calculate new records
--    SELECT @NewRecords = COUNT(1) FROM BANK_PROJECT..STG_CUSTOMER_ACCOUNT CA2
--    LEFT JOIN CUSTOMER_ACCOUNT CA
--    ON CA.Customer_Acc_ID = CA2.Customer_Acc_ID
--    WHERE CA.Customer_Acc_ID IS NULL

--    -- Calculate existing records (updated records)
--    SELECT @ExistingRecords = COUNT(1) FROM BANK_PROJECT..STG_CUSTOMER_ACCOUNT CA2
--    INNER JOIN CUSTOMER_ACCOUNT CA
--    ON CA.Customer_Acc_ID = CA2.Customer_Acc_ID

--    -- Insert audit record
--    INSERT INTO BANK_PROJECT..DATA_LOAD_AUDIT_table
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
--        @NewRecords,
--        @ExistingRecords,
--        @Error_Records,
--        @Success_Records,
--        GETDATE()
--    )

--END

--EXEC SP_CUSTOMER_ACCOUNT_DATA_LOAD

/********************************************************** TRANSACTION TYPE MASTER *************************************************************************************************************************/

CREATE TABLE TransacationTypemaster(
									 TransactionTypeID SMALLINT PRIMARY KEY IDENTITY(1,1)
									,TransactionName VARCHAR(200)
									,TransactionDescription VARCHAR(300)
								   )

----------------------- TRANSACTION TYPEMASTER ODS DATA LOAD ----------------------------------------------------
--IN USE 
GO
ALTER PROC SP_TRANSACTION_TYPEMASTER_DATA_LOAD
(
    @FileName VARCHAR(250)
)
AS
BEGIN

	UPDATE TT 
	SET
		 TT.TransactionName=STT.TransactionName
		,TT.TransactionDescription=STT.TransactionDescription  
	FROM TransacationTypemaster TT
	JOIN BANK_PROJECT..STG_TransacationTypemaster STT
	ON TT.TransactionTypeID=STT.TransactionTypeID

	INSERT INTO TransacationTypemaster (TransactionName, TransactionDescription)
    SELECT 
        STT.TransactionName,
        STT.TransactionDescription  
    FROM BANK_PROJECT..STG_TransacationTypemaster STT
    LEFT JOIN TransacationTypemaster TT
        ON TT.TransactionTypeID = STT.TransactionTypeID
    WHERE TT.TransactionTypeID IS NULL

	
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

EXEC SP_TRANSACTION_TYPEMASTER_DATA_LOAD ''


SELECT * FROM TransacationTypemaster

SELECT * FROM BANK_PROJECT..STG_TransacationTypemaster

SELECT * FROM TransacationTypemaster

/**********************************************************************************************************************************************************************/
-- ODS FACT BANK TRANSACTION TABLE 

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

/************************************************************************************************************************************************************************/
--ODS BANK_TRANSACTION DATA LOAD STORED PROCEURES

 GO
ALTER PROC SP_BANK_TRANSACTION_DATA_LOAD
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
	,BT.TransactionDate=CAST(SBT.TransactionDate AS DATETIME)
	,BT.Balance=CAST(SBT.Balance AS MONEY)
	,BT.Credit= CAST(SBT.Credit AS MONEY)
	,BT.Debit=CAST(SBT.Debit AS MONEY)
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
SELECT CAST(CA.Customer_Acc_ID AS INT),
	   CAST(CM.ChannelID AS INT),
	   CAST(TT.TransactionTypeID AS SMALLINT),
	   CAST(B.BankId AS INT),
	   CAST(BR.BranchId AS INT),
	   CAST(SBT.TransactionDate AS DATETIME), 
       CAST(SBT.Balance AS MONEY), 
       CAST(SBT.Credit AS MONEY), 
       CAST(SBT.Debit AS MONEY)
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

WHERE BT.Branch_TransactionId IS NOT NULL

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

EXEC SP_BANK_TRANSACTION_DATA_LOAD ?

SELECT * FROM BANK_TRANSACTION

SELECT * FROM BANK_PROJECT..STG_BANK_TRANSACTION
SELECT * FROM BANK_PROJECT..STG_BANK_TRANSACTION_DISCARD
SELECT * FROM BANK_PROJECT..STG_BANK_TRANSACTION_SUCCESS


/*****************************************************************************************************************************************/
--WORKING ON IT 

/*************************************************************************************************************************************/
--CURRENT WORK


 GO
ALTER PROC SP_BANK_TRANSACTION_DATA_LOAD
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
	,BT.TransactionDate=CAST(SBT.TransactionDate AS DATETIME)
	,BT.Balance=CAST(SBT.Balance AS MONEY)
	,BT.Credit= CAST(SBT.Credit AS MONEY)
	,BT.Debit=CAST(SBT.Debit AS MONEY)
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

INSERT INTO BANK_TRANSACTION (Customer_Acc_Id, ChannelID, TransactionTypeID, BankId, BranchId, TransactionDate, Balance, Credit, Debit)
SELECT CAST(CA.Customer_Acc_ID AS INT),
	   CAST(CM.ChannelID AS INT),
	   CAST(TT.TransactionTypeID AS SMALLINT),
	   CAST(B.BankId AS INT),
	   CAST(BR.BranchId AS INT),
	   CAST(SBT.TransactionDate AS DATETIME), 
       CAST(SBT.Balance AS MONEY), 
       CAST(SBT.Credit AS MONEY), 
       CAST(SBT.Debit AS MONEY)
FROM 
    BANK_PROJECT..STG_BANK_TRANSACTION SBT
JOIN 
    CUSTOMER_ACCOUNT CA
ON 
    CAST(SBT.Account_id AS INT)= CA.AccountID
JOIN 
    CHANNEL_MASTER CM
ON
    CAST(SBT.Channel AS INT)= CM.ChannelID
JOIN
    TransacationTypemaster TT
ON 
    CAST(SBT.TransactionType AS SMALLINT) = TT.TransactionTypeID
JOIN
    Bank B
ON 
    CAST(SBT.BankId AS INT) = B.BankId
JOIN 
    Branch BR
ON
    CAST(B.BankId AS INT) = BR.BankId
LEFT JOIN 
    BANK_TRANSACTION BT
ON 
    CAST(SBT.Trans_id AS INT)= BT.Branch_TransactionId
WHERE 
    SBT.Trans_id IS NOT NULL


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

SELECT * FROM BANK_TRANSACTION

SELECT * FROM BANK_PROJECT..STG_BANK_TRANSACTION
SELECT * FROM BANK_PROJECT..STG_BANK_TRANSACTION_DISCARD
SELECT * FROM BANK_PROJECT..STG_BANK_TRANSACTION_SUCCESS
