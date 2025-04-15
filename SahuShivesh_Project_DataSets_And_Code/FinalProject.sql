
--Dataset 1 for the informations on the hospitals
CREATE TABLE hospital_dimension (
    Year INT,
    County VARCHAR(255),
    Hospital VARCHAR(255),
    OSHPDID INT,
    System VARCHAR(255),
    Type_of_Report VARCHAR(255),
    Performance_Measure VARCHAR(255),
    Number_of_Adverse_Events FLOAT,
    Number_of_Cases FLOAT,
    Risk_adjusted_Rate FLOAT,
    Hospital_Ratings VARCHAR(255),
    Longitude FLOAT,
    Latitude FLOAT
);
SELECT * FROM hospital_dimension LIMIT 5;


--Dataset 2 for hospital locations
CREATE TABLE hospital_locations (
    X FLOAT,
    Y FLOAT,
    FID INT,
    ID BIGINT,
    NAME VARCHAR(255),
    ADDRESS VARCHAR(255),
    CITY VARCHAR(255),
    STATE VARCHAR(50),
    ZIP VARCHAR(20),
    ZIP4 VARCHAR(20),
    TYPE VARCHAR(100),
    STATUS VARCHAR(100),
    POPULATION INT,
    COUNTY VARCHAR(255),
    COUNTYFIPS VARCHAR(50),
    COUNTRY VARCHAR(100),
    LATITUDE FLOAT,
    LONGITUDE FLOAT,
    NAICS_CODE VARCHAR(50),
    NAICS_DESC VARCHAR(255),
    SOURCE VARCHAR(255),
    SOURCEDATE TIMESTAMP,
    VAL_METHOD VARCHAR(255),
    VAL_DATE TIMESTAMP,
    WEBSITE VARCHAR(255),
    STATE_ID VARCHAR(100),
    ALT_NAME VARCHAR(255),
    ST_FIPS VARCHAR(20),
    OWNER VARCHAR(255),
    TTL_STAFF INT,
    BEDS INT,
    TRAUMA VARCHAR(50),
    HELIPAD VARCHAR(10)
);


SELECT * FROM hospital_locations LIMIT 5;

--Fact Tables
--FactHospitalPerformance (Snapshot Fact Table):
CREATE TABLE FactHospitalPerformance (
    PerformanceID SERIAL PRIMARY KEY,
    HospitalID INT,
    TimeID INT,
    AdverseEventRate FLOAT,
    RiskAdjustedRate FLOAT,
    HospitalRating VARCHAR(50),
    FOREIGN KEY (HospitalID) REFERENCES DimHospital(HospitalID),
    FOREIGN KEY (TimeID) REFERENCES DimTime(TimeID)
);
-- Create a sequence if it doesn't exist
CREATE SEQUENCE IF NOT EXISTS FactHospitalPerformance_PerformanceID_seq;

-- Set the default value of TimeID to use the sequence
ALTER TABLE FactHospitalPerformance
ALTER COLUMN PerformanceID SET DEFAULT nextval('FactHospitalPerformance_PerformanceID_seq');

INSERT INTO FactHospitalPerformance (adverseeventrate,riskadjustedrate,hospitalrating)
SELECT DISTINCT hospital_dimension."# of Adverse Events",hospital_dimension."Risk-adjusted Rate",hospital_dimension."Hospital Ratings"
FROM hospital_dimension,hospital_locations;
SELECT * FROM FactHospitalPerformance;

--FactHospitalTransactions (Transactional Fact Table):
CREATE TABLE FactHospitalTransactions (
    TransactionID SERIAL PRIMARY KEY,
    HospitalID INT,
    PatientID INT,
    TreatmentID INT,
    TimeID INT,
    NumberOfAdmissions INT,
    FOREIGN KEY (HospitalID) REFERENCES DimHospital(HospitalID),
    FOREIGN KEY (PatientID) REFERENCES DimPatient(PatientID),
    FOREIGN KEY (TreatmentID) REFERENCES DimTreatment(TreatmentID),
    FOREIGN KEY (TimeID) REFERENCES DimTime(TimeID)
);

INSERT INTO FactHospitalTransactions (numberofadmissions)
SELECT DISTINCT hospital_dimension."# of Cases"
FROM hospital_dimension,hospital_locations;
SELECT * FROM FactHospitalTransactions;


--FactHospitalCumulative (Cumulative Fact Table):
CREATE TABLE FactHospitalCumulative (
    CumulativeID SERIAL PRIMARY KEY,
    HospitalID INT,
    TimeID INT,
    TotalProcedures INT,
    TotalPatients INT,
    FOREIGN KEY (HospitalID) REFERENCES DimHospital(HospitalID),
    FOREIGN KEY (TimeID) REFERENCES DimTime(TimeID)
);
INSERT INTO FactHospitalCumulative (totalprocedures,totalpatients)
SELECT DISTINCT hospital_dimension."# of Adverse Events", hospital_dimension."# of Cases"
FROM hospital_dimension,hospital_locations;
SELECT * FROM FactHospitalCumulative;

-- Create DimHospitalSystem Table(SCD Type 1)
CREATE TABLE DimHospitalSystem (
    SystemID INT PRIMARY KEY,
    SystemName VARCHAR(255),
    Size VARCHAR(100)
);
SELECT * FROM DimHospitalSystem;

--Dimension Tables
--DimHospital (SCD Type 2):
CREATE TABLE DimHospital (
    HospitalID INT PRIMARY KEY,
    HospitalName VARCHAR(255),
    System VARCHAR(255),
    Address VARCHAR(255),
    StartDate DATE,
    EndDate DATE,
    IsActive BOOLEAN
);

--Populate DimHospital:
--Extract unique hospital information from hospital_dimension and hospital_locations:

SELECT * FROM DimHospital;INSERT INTO DimHospital (HospitalID, HospitalName, System, Address)
SELECT DISTINCT "OSHPDID", "Hospital", "system",hospital_dimension."County"
FROM hospital_dimension,hospital_locations;

UPDATE DimHospital
SET StartDate = (CURRENT_DATE - (ROUND(RANDOM() * 3650))::INTEGER)::DATE
WHERE StartDate IS NULL;

UPDATE DimHospital
SET EndDate = CURRENT_DATE  
WHERE EndDate IS NULL;

UPDATE DimHospital
SET IsActive = TRUE
WHERE IsActive IS NULL;

SELECT * FROM DimHospital LIMIT 5;



--DimLocation (SCD Type 3):
CREATE TABLE DimLocation (
     LocationID SERIAL PRIMARY KEY,
    City VARCHAR(100),
    State VARCHAR(100),
    Region VARCHAR(100),
    PreviousRegion VARCHAR(100),
    ZIPCode VARCHAR(20)
);
--Populate DimLocation:
--Extract unique hospital information from hospital_dimension and hospital_locations:

SELECT * FROM DimLocation;INSERT INTO DimLocation ( city, state, region, previousregion, zipcode)
SELECT DISTINCT hospital_locations."CITY", hospital_locations."STATE",hospital_locations."ADDRESS",hospital_locations."ADDRESS", hospital_locations."ZIP"
FROM hospital_dimension,hospital_locations;

SELECT * FROM DimLocation;

--DimTime(lets keep this as SCD type 0 
--for now as I'm not making any changes here):
CREATE TABLE DimTime (
    TimeID SERIAL PRIMARY KEY,
    Date DATE,
    Month INT,
    Year INT,
    Quarter INT,
    DayOfWeek VARCHAR(20)
);
-- Create a sequence if it doesn't exist
CREATE SEQUENCE IF NOT EXISTS dimtime_timeid_seq;

-- Set the default value of TimeID to use the sequence
ALTER TABLE DimTime
ALTER COLUMN TimeID SET DEFAULT nextval('dimtime_timeid_seq');

INSERT INTO DimTime (Date, Month, Year, Quarter, DayOfWeek)
SELECT DISTINCT
    random_date,
    EXTRACT(MONTH FROM random_date) AS Month,
    hd."Year",
    EXTRACT(QUARTER FROM random_date) AS Quarter,
    TO_CHAR(random_date, 'Day') AS DayOfWeek
FROM 
    hospital_dimension hd,DimLocation,
    LATERAL (SELECT (DATE '2010-01-01' + (RANDOM() * (DATE '2020-12-31' - DATE '2010-01-01'))::INTEGER)::DATE AS random_date) AS rd;


SELECT * FROM DimTime;

--DimHospitalSystem:
CREATE TABLE DimHospitalSystem (
    SystemID INT PRIMARY KEY,
    SystemName VARCHAR(255),
    Size VARCHAR(100)
);

-- Create a sequence if it doesn't exist
CREATE SEQUENCE IF NOT EXISTS DimHospitalSystem_SystemID_seq;

-- Set the default value of TimeID to use the sequence
ALTER TABLE DimHospitalSystem
ALTER COLUMN SystemID SET DEFAULT nextval('DimHospitalSystem_SystemID_seq');

INSERT INTO DimHospitalSystem (systemname,size)
SELECT DISTINCT hd."system", hd."# of Cases"
FROM hospital_dimension hd,DimLocation;
SELECT * FROM DimHospitalSystem;

--DimPatient:
CREATE TABLE DimPatient (
    PatientID INT PRIMARY KEY,
    PatientName VARCHAR(255),
    Age INT,
    Gender VARCHAR(50)
);

-- since i cannot access Patient details due to privacy 
-- i will manually create to fill out the tabel 
-- this table might be useful in the future 
INSERT INTO DimPatient (PatientID, PatientName, Age, Gender)
VALUES 
    (1, 'John Doe', 30, 'Male'),
    (2, 'Jane Smith', 25, 'Female'),
    (3, 'Alex Johnson', 40, 'Male'),
    (4, 'Emma Wilson', 28, 'Female'),
    (5, 'Liam Brown', 35, 'Male'),
    (6, 'Olivia Johnson', 42, 'Female'),
    (7, 'Noah Miller', 30, 'Male'),
    (8, 'Ava Davis', 22, 'Female'),
    (9, 'Ethan Garcia', 55, 'Male'),
    (10, 'Sophia Martinez', 33, 'Female'),
    (11, 'Mason Rodriguez', 45, 'Male'),
    (12, 'Isabella Lopez', 26, 'Female'),
    (13, 'Jacob Gonzalez', 60, 'Male'),
    (14, 'Mia Hernandez', 37, 'Female'),
    (15, 'William Smith', 48, 'Male'),
    (16, 'Amelia Hall', 29, 'Female'),
    (17, 'Michael Allen', 50, 'Male'),
    (18, 'Charlotte Young', 32, 'Female'),
    (19, 'Benjamin King', 39, 'Male'),
    (20, 'Harper Lee', 41, 'Female'),
    (21, 'Alexander Wright', 36, 'Male'),
    (22, 'Evelyn Scott', 27, 'Female'),
    (23, 'James Hill', 52, 'Male'),
	(24, 'Lucas Clark', 38, 'Male'),
    (25, 'Grace Lewis', 31, 'Female'),
    (26, 'Logan Robinson', 47, 'Male'),
    (27, 'Lily Walker', 29, 'Female'),
    (28, 'Aiden Young', 34, 'Male'),
    (29, 'Zoe Green', 40, 'Female'),
    (30, 'Daniel Adams', 44, 'Male'),
    (31, 'Ella Baker', 26, 'Female'),
    (32, 'Henry Nelson', 53, 'Male'),
    (33, 'Avery Edwards', 37, 'Female')
;

SELECT * FROM DimPatient;

--DimTreatment:
CREATE TABLE DimTreatment (
    TreatmentID INT PRIMARY KEY,
    TreatmentType VARCHAR(255),
    Description VARCHAR(500)
);
-- since i cannot access Patient Treatment details due to privacy 
-- i will manually create to fill out the tabel 
-- this table might be useful in the future 
INSERT INTO DimTreatment (TreatmentID, TreatmentType, Description)
VALUES 
    (1, 'Physical Therapy', 'Treatment to improve movement and manage pain.'),
    (2, 'Chemotherapy', 'Use of drugs to treat cancer.'),
    (3, 'Radiation Therapy', 'Use of high-energy particles to destroy cancer cells.'),
    (4, 'Cognitive Behavioral Therapy', 'A type of psychotherapy that treats mental health disorders.'),
    (5, 'Dialysis', 'Process to remove waste products from the blood in kidney failure.'),
    (6, 'Angioplasty', 'Procedure to open narrowed or blocked blood vessels of the heart.'),
    (7, 'Bypass Surgery', 'Surgery to improve blood flow to the heart.'),
    (8, 'Cataract Surgery', 'Procedure to remove the lens of the eye and replace it with an artificial lens.'),
    (9, 'Tonsillectomy', 'Surgical removal of the tonsils.'),
    (10, 'Appendectomy', 'Surgical removal of the appendix.'),
    (11, 'Hernia Repair', 'Surgery to repair an abnormal exit of tissue or an organ.'),
    (12, 'Hip Replacement', 'Surgical procedure to replace a hip joint.'),
    (13, 'Knee Replacement', 'Surgery to replace a knee joint.'),
    (14, 'Gastric Bypass', 'Surgery that helps with weight loss.'),
    (15, 'Laparoscopy', 'A minimally invasive surgical procedure.'),
    (16, 'Hysterectomy', 'Surgery to remove a woman’s uterus.'),
    (17, 'Lumpectomy', 'Surgical removal of a breast tumor and a small margin of surrounding tissue.'),
    (18, 'Mastectomy', 'Surgical removal of one or both breasts.'),
    (19, 'Coronary Stent', 'Procedure to keep coronary arteries open.'),
    (20, 'Heart Transplant', 'Surgical procedure to replace a damaged heart with a healthy one.'),
    (21, 'Liver Transplant', 'Surgery to replace a diseased liver with a healthy liver.'),
    (22, 'Kidney Transplant', 'Surgical procedure to place a healthy kidney from a donor into a patient.'),
    (23, 'LASIK', 'Laser eye surgery to correct vision.'),
    (24, 'Blood Transfusion', 'Process of transferring blood into one’s circulation.'),
    (25, 'Root Canal', 'Dental procedure to treat infection at the center of a tooth.'),
    (26, 'Gallbladder Removal', 'Surgical removal of the gallbladder.'),
    (27, 'Varicose Vein Treatment', 'Procedures to treat enlarged veins.'),
    (28, 'Pacemaker Insertion', 'Implantation of a pacemaker to control abnormal heart rhythms.'),
    (29, 'Skin Grafting', 'Transplanting skin to cover damaged areas.'),
    (30, 'Liposuction', 'Cosmetic surgery to remove fat.'),
    (31, 'Rhinoplasty', 'Cosmetic surgery to change the shape of the nose.'),
    (32, 'Chemical Peel', 'Skin-resurfacing procedure.'),
    (33, 'Acupuncture', 'Traditional Chinese medicine technique for balancing the flow of energy.');


SELECT * FROM DimTreatment;

--Now Lets Answer the Business Questions 

--1. Trend Analysis: 
--How have hospital performance metrics, such as adverse event
--rates and risk-adjusted rates, evolved over the years from 2016 to 2020?
SELECT 
    "Year",
    AVG("# of Adverse Events") AS AverageAdverseEventRate,
    AVG("Risk-adjusted Rate") AS AverageRiskAdjustedRate
FROM 
    hospital_dimension
WHERE 
    "Year" BETWEEN 2016 AND 2020
GROUP BY 
    "Year"
ORDER BY 
    "Year";



--2. Regional Comparison: 
--Are there significant regional variations in 
--hospital performance metrics, and what might be contributing 
--to these differences?
SELECT 
    hospital_dimension."County" AS Region,
    AVG(hospital_dimension."# of Adverse Events") AS AverageAdverseEventRate,
    AVG(hospital_dimension."Risk-adjusted Rate") AS AverageRiskAdjustedRate
FROM 
    hospital_dimension
GROUP BY 
    hospital_dimension."County"
ORDER BY 
    hospital_dimension."County";


--3. Performance and Ratings Correlation: 
--How does the risk-adjusted rate correlate with overall 
--hospital ratings, and do higher adverse event rates typically
--correlate with lower hospital ratings?
SELECT 
    "Hospital Ratings",
    AVG("Risk-adjusted Rate") AS AverageRiskAdjustedRate,
    AVG("# of Adverse Events") AS AverageAdverseEventRate
FROM 
    hospital_dimension
GROUP BY 
    "Hospital Ratings"
ORDER BY 
    "Hospital Ratings";


--4. Impact of Hospital Systems: 
--Do hospitals belonging to larger systems 
--perform differently in terms of safety and 
--quality metrics compared to independent hospitals?
SELECT 
    hospital_dimension."system",
    COUNT(hospital_dimension."Hospital") AS NumberOfHospitals,
    AVG(hospital_dimension."# of Adverse Events") AS AverageAdverseEventRate,
    AVG(hospital_dimension."Risk-adjusted Rate") AS AverageRiskAdjustedRate
FROM 
    hospital_dimension
GROUP BY 
    hospital_dimension."system"
ORDER BY 
    AverageAdverseEventRate, AverageRiskAdjustedRate;



--5. Predictive Insights: 
--Impact of Hospital Type on Performance Metrics
SELECT 
    System,
    AVG("# of Adverse Events") AS AvgAdverseEventRate,
    AVG("# of Cases") AS AvgNumberOfCases,
    AVG("Risk-adjusted Rate") AS AvgRiskAdjustedRate
FROM 
    hospital_dimension
GROUP BY 
    System
ORDER BY 
    AvgAdverseEventRate, AvgRiskAdjustedRate;



--Visualization and Analytics
--Analytical Queries
--Trend Analysis:
--Business Question: How have hospital performance metrics evolved over the years?
SELECT 
    "Year",
    AVG("# of Adverse Events") AS YearlyAvgAdverseEvents,
    AVG("Risk-adjusted Rate") AS YearlyAvgRiskAdjustedRate
FROM 
    hospital_dimension
GROUP BY 
    "Year"
ORDER BY 
    "Year";


--Regional Comparison with CTE and Aggregation:
--Business Question: Are there significant regional variations in hospital performance metrics?
SELECT 
    hospital_dimension."County" AS Region,
    AVG("# of Adverse Events") AS AvgAdverseEventRate,
    AVG("Risk-adjusted Rate") AS AvgRiskAdjustedRate
FROM 
    hospital_dimension
GROUP BY 
    hospital_dimension."County"
ORDER BY 
    hospital_dimension."County";

SELECT * FROM hospital_dimension LIMIT 5;

--To demonstrate Slowly Changing Dimension (SCD) Type 2 maintenance in my project, 
--I need to show how historical data is preserved when changes occur in your source data.
-- Create a temporary table with simulated updates
CREATE TEMP TABLE new_hospital_data AS
SELECT * FROM hospital_dimension;

-- Simulate updates in the new_hospital_data table
-- Example: Changing HospitalName, System, and Address for specific HospitalID
-- Assuming new_hospital_data is a temporary table with a copy of hospital_dimension

-- Simulate updates in the new_hospital_data table for Alameda Hospital
UPDATE new_hospital_data
SET "Hospital" = 'Updated Alameda Hospital', 
    "system" = 'Updated Health System',
    "Performance Measure" = 'Updated Performance Measure'
WHERE "OSHPDID" = 106010735
AND "Performance Measure" = 'Acute Stroke';

--Now that I have simulated changes in the hospital data, 
--I can proceed with the next steps of the SCD Type 2 process. 
--This involves updating your DimHospital table to reflect these 
--changes while maintaining historical data.

--The next steps would typically be:
--Mark Existing Records as Historical: 
--Update the records in DimHospital that correspond to the 
--changed records in new_hospital_data, setting their 
--EndDate to the current date and IsActive to FALSE.
--Insert New Records with Updated Data: 
--Insert new records into DimHospital for the updated data in new_hospital_data.

-- Step 1: Mark existing records as historical if there's a change
UPDATE DimHospital
SET EndDate = CURRENT_DATE, IsActive = FALSE
FROM new_hospital_data
WHERE DimHospital.HospitalID = new_hospital_data."OSHPDID"
AND (DimHospital.HospitalName != new_hospital_data."Hospital"
     OR DimHospital.System != new_hospital_data."system");

-- Step 2: Insert new records for changed data with manually generated HospitalID
-- Create a sequence for HospitalID
CREATE SEQUENCE hospital_id_seq;

-- Use the sequence to generate new HospitalID
INSERT INTO DimHospital (HospitalID, HospitalName, System, Address, StartDate, IsActive)
SELECT 
    NEXTVAL('hospital_id_seq'), -- Generates a new unique HospitalID
    n."Hospital", 
    n."system", 
    d.Address, 
    CURRENT_DATE, 
    TRUE
FROM 
    new_hospital_data n
JOIN 
    DimHospital d ON n."OSHPDID" = d.HospitalID
WHERE 
    EXISTS (SELECT 1
            FROM DimHospital
            WHERE DimHospital.HospitalID = n."OSHPDID"
            AND (DimHospital.HospitalName != n."Hospital"
                 OR DimHospital.System != n."system"));

-- Select records from DimHospital to display the results of SCD Type 2 implementation
SELECT 
    HospitalID, 
    HospitalName, 
    System, 
    Address, 
    StartDate, 
    EndDate, 
    IsActive
FROM 
    DimHospital
ORDER BY 
    HospitalID, StartDate;













