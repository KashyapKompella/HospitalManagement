/* UDF  -- DATE DIFFERENCE*/
CREATE FUNCTION DateDifference(@x as date, @y as date)
RETURNS int
AS 
BEGIN
DECLARE @Days AS INT 
SET @Days = DATEDIFF(DY,@x,@y)
RETURN @Days
END


/* UDF  -- TIME DIFFERENCE*/
CREATE FUNCTION TimeDifference(@x as DATETIME, @y as DATETIME)
RETURNS DECIMAL
AS 
BEGIN
DECLARE @HR AS DECIMAL 
SET @HR = DATEDIFF(HH,@x,@y)
RETURN @HR
END


/* UDF MULTIPLY*/
CREATE FUNCTION Multiply(@x as int, @y as int)
RETURNS int
AS 
BEGIN
DECLARE @Billing_Amount AS INT 
SET @Billing_Amount = @x*@y
RETURN @Billing_Amount
END

ALTER TABLE RECORD
ADD BILLINGFEE INT;

/* CALCULATE BILING DAYS -- STORED PROCEDURE */

CREATE PROCEDURE BillingDays
AS
BEGIN
    alter table Record ADD BillingDays as (dbo.DateDifference(RECORD.ADMIT_DATE, RECORD.DISCHARGEDATE))
END;

exec BillingDays


ALTER TABLE BILLING
ADD BILLINGFEE INT;


ALTER TABLE RECORD
ADD BILLINGFEE INT;

/* CALCULATE INPATIENT BILLING FEE -- STORED PROCEDURE*/


CREATE PROCEDURE Calculate_IP_Billing
AS
BEGIN
     UPDATE Record SET BILLINGFEE = dbo.Multiply(100, dbo.DateDifference(RECORD.ADMIT_DATE, RECORD.DISCHARGEDATE)) WHERE
     PATIENT_TYPE = 'I'
END;

exec Calculate_IP_Billing

SELECT * FROM INFORMATION_SCHEMA.TABLES
SELECT * FROM BILLING

/* CALCULATE OUTPATIENT BILLING FEE -- STORED PROCEDURE*/

CREATE PROCEDURE Calculate_OP_Billing
AS
BEGIN
    UPDATE BILLING SET BILLINGFEE = dbo.Multiply(10, dbo.TimeDifference(RECORD.ADMIT_DATE, RECORD.DISCHARGEDATE)) WHERE
     PATIENT_TYPE = 'O'
END;

exec Calculate_OP_Billing


/* CALCULATE BILLING FEE STORED PROCEDURE*/

drop procedure Calculate_Billing
CREATE PROCEDURE Calculate_Billing
AS
BEGIN 
   
    IF EXISTS (SELECT Patient_Type from APPOINTMENT_SCHEDULING WHERE PATIENT_TYPE = 'I')
    Begin
            EXEC Calculate_IP_Billing
    End
    IF EXISTS (SELECT Patient_Type from APPOINTMENT_SCHEDULING WHERE PATIENT_TYPE = 'O')
    Begin
            EXEC Calculate_OP_Billing
    End
END

EXEC Calculate_Billing


/*COLUMN BASED ENCRYPTION*/

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'GROUP07_PASSWORD';


CREATE CERTIFICATE GROUP07_CERTIFICATE
WITH SUBJECT = 'GROUP07 HOSPITAL MANAGEMENT',
EXPIRY_DATE= '2022-08-30';

CREATE SYMMETRIC KEY GROUP07_Symmetrickey
WITH ALGORITHM= AES_128
ENCRYPTION BY CERTIFICATE GROUP07_Certificate;
OPEN SYMMETRIC KEY
GROUP07_Symmetrickey
DECRYPTION BY CERTIFICATE GROUP07_CERTIFICATE;


ALTER TABLE DBO.PATIENT
    ADD EncryptedEmail varbinary(128);   
GO  

UPDATE DBO.PATIENT
SET EncryptedEmail = EncryptByKey(Key_GUID('GROUP07_Symmetrickey'), EMAIL_ID);  
GO  


