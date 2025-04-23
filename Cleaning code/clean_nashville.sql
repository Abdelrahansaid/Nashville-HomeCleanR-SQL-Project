-- DATA CLEANING PROJECT: Nashville Housing Data
-- Author: Abdelrahman Said Mohamed
-- Date: 4/23/2025


----------------------------------------------------------------------------------------------------
-- 1. STANDARDIZE SALE DATE FORMAT
----------------------------------------------------------------------------------------------------

-- Create new standardized date column
ALTER TABLE Potfolio_Project.dbo.Nashville_data
ADD SaleDateConverted DATE;

UPDATE Potfolio_Project.dbo.Nashville_data
SET SaleDateConverted = CONVERT(DATE, SaleDate);

-- Verify conversion
SELECT 
    SaleDate, 
    SaleDateConverted
FROM Potfolio_Project.dbo.Nashville_data;


----------------------------------------------------------------------------------------------------
-- 2. HANDLE MISSING PROPERTY ADDRESSES
----------------------------------------------------------------------------------------------------

-- Identify records with missing PropertyAddress
SELECT *
FROM Potfolio_Project.dbo.Nashville_data
WHERE PropertyAddress IS NULL;

-- Populate missing addresses using ParcelID matches
WITH AddressCTE AS (
    SELECT 
        a.ParcelID,
        a.PropertyAddress,
        b.ParcelID AS MatchParcelID,
        b.PropertyAddress AS MatchPropertyAddress
    FROM Potfolio_Project.dbo.Nashville_data a
    JOIN Potfolio_Project.dbo.Nashville_data b
        ON a.ParcelID = b.ParcelID
        AND a.UniqueID <> b.UniqueID
    WHERE a.PropertyAddress IS NULL
)

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Potfolio_Project.dbo.Nashville_data a
JOIN Potfolio_Project.dbo.Nashville_data b
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;


----------------------------------------------------------------------------------------------------
-- 3. SPLIT ADDRESS FIELDS INTO COMPONENTS
----------------------------------------------------------------------------------------------------

-- Split PropertyAddress into Street and City
ALTER TABLE Potfolio_Project.dbo.Nashville_data
ADD PropertyStreet NVARCHAR(255),
    PropertyCity NVARCHAR(255);

UPDATE Potfolio_Project.dbo.Nashville_data
SET 
    PropertyStreet = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
    PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));

-- Split OwnerAddress into Street, City, State
ALTER TABLE Potfolio_Project.dbo.Nashville_data
ADD OwnerStreet NVARCHAR(255),
    OwnerCity NVARCHAR(255),
    OwnerState NVARCHAR(255);

UPDATE Potfolio_Project.dbo.Nashville_data
SET 
    OwnerStreet = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
    OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);


----------------------------------------------------------------------------------------------------
-- 4. STANDARDIZE SOLDASVACANT VALUES
----------------------------------------------------------------------------------------------------

-- Check current distribution
SELECT 
    SoldAsVacant, 
    COUNT(*) AS RecordCount
FROM Potfolio_Project.dbo.Nashville_data
GROUP BY SoldAsVacant
ORDER BY 2 DESC;

-- Update Y/N to Yes/No
UPDATE Potfolio_Project.dbo.Nashville_data
SET SoldAsVacant = CASE 
                    WHEN SoldAsVacant = 'Y' THEN 'Yes'
                    WHEN SoldAsVacant = 'N' THEN 'No'
                    ELSE SoldAsVacant
                   END;


----------------------------------------------------------------------------------------------------
-- 5. REMOVE DUPLICATE RECORDS
----------------------------------------------------------------------------------------------------

WITH RowNumCTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID,
                         PropertyAddress,
                         SalePrice,
                         SaleDateConverted,
                         LegalReference
            ORDER BY UniqueID
        ) AS row_num
    FROM Potfolio_Project.dbo.Nashville_data
)

DELETE FROM RowNumCTE
WHERE row_num > 1;


----------------------------------------------------------------------------------------------------
-- 6. CLEAN UP UNUSED COLUMNS
----------------------------------------------------------------------------------------------------

ALTER TABLE Potfolio_Project.dbo.Nashville_data
DROP COLUMN 
    OwnerAddress,
    TaxDistrict,
    PropertyAddress,
    SaleDate;


	----------------------------------------------------------------------------------------------------
-- 7. STANDARDIZE LAND USE CATEGORIES
----------------------------------------------------------------------------------------------------

-- Check distinct values
SELECT DISTINCT LandUse 
FROM Potfolio_Project.dbo.Nashville_data;

-- Standardize variations
UPDATE Potfolio_Project.dbo.Nashville_data
SET LandUse = CASE 
                WHEN LandUse LIKE '%VACANT%' THEN 'VACANT LAND'
                WHEN LandUse LIKE '%SINGLE%' THEN 'SINGLE FAMILY'
                WHEN LandUse LIKE '%DUPLEX%' THEN 'MULTI-FAMILY'
                WHEN LandUse LIKE '%CONDO%' THEN 'CONDOMINIUM'
                ELSE LandUse
              END;


----------------------------------------------------------------------------------------------------
-- 8. VALIDATE YEAR BUILT
----------------------------------------------------------------------------------------------------

-- Flag invalid years
SELECT * 
FROM Potfolio_Project.dbo.Nashville_data
WHERE YearBuilt < 1800 OR YearBuilt > YEAR(GETDATE());


----------------------------------------------------------------------------------------------------
-- 9. CLEAN MONETARY VALUES
----------------------------------------------------------------------------------------------------

-- Remove non-numeric characters and convert
UPDATE Potfolio_Project.dbo.Nashville_data
SET SalePrice = TRY_CAST(REPLACE(REPLACE(SalePrice, '$', ''), ',', '') AS MONEY),
    LandValue = TRY_CAST(REPLACE(REPLACE(LandValue, '$', ''), ',', '') AS MONEY),
    BuildingValue = TRY_CAST(REPLACE(REPLACE(BuildingValue, '$', ''), ',', '') AS MONEY),
    TotalValue = TRY_CAST(REPLACE(REPLACE(TotalValue, '$', ''), ',', '') AS MONEY);


----------------------------------------------------------------------------------------------------
-- 10. VALIDATE BEDROOM/BATH COUNTS
----------------------------------------------------------------------------------------------------

-- Flag unrealistic values
SELECT *
FROM Potfolio_Project.dbo.Nashville_data
WHERE Bedrooms > 10 OR FullBath > 10 OR HalfBath > 5;


----------------------------------------------------------------------------------------------------
-- 11. CLEAN LEGAL REFERENCE
----------------------------------------------------------------------------------------------------

-- Split into date and reference number
ALTER TABLE Potfolio_Project.dbo.Nashville_data
ADD LegalDate DATE,
    LegalRefNum VARCHAR(50);

UPDATE Potfolio_Project.dbo.Nashville_data
SET LegalDate = TRY_CONVERT(DATE, LEFT(LegalReference, 8)),
    LegalRefNum = SUBSTRING(LegalReference, 9, LEN(LegalReference));

-- Remove hyphens from LegalRefNum
UPDATE Potfolio_Project.dbo.Nashville_data
SET LegalRefNum = REPLACE(LegalRefNum, '-', '');

-- Check The Data
SELECT *
FROM Potfolio_Project.dbo.Nashville_data;


----------------------------------------------------------------------------------------------------
-- 12. FINAL DATA QUALITY CHECK
----------------------------------------------------------------------------------------------------

-- Check for remaining NULLs
SELECT 
    SUM(CASE WHEN PropertyStreet IS NULL THEN 1 ELSE 0 END) AS PropertyStreet_Null,
    SUM(CASE WHEN OwnerStreet IS NULL THEN 1 ELSE 0 END) AS OwnerStreet_Null,
    SUM(CASE WHEN YearBuilt IS NULL THEN 1 ELSE 0 END) AS YearBuilt_Null
FROM Potfolio_Project.dbo.Nashville_data;

--we see that (OwnerStreet)and (YearBuilt) Have alot of nulls more than 3000 NULL we can delet it but we will Not


----------------------------------------------------------------------------------------------------
-- 13. CREATE FINAL INDEXES
----------------------------------------------------------------------------------------------------

CREATE INDEX idx_PropertyAddress 
ON Potfolio_Project.dbo.Nashville_data(PropertyStreet, PropertyCity);

CREATE INDEX idx_SaleDate 
ON Potfolio_Project.dbo.Nashville_data(SaleDateConverted);


----------------------------------------------------------------------------------------------------
-- See The Final Result 
----------------------------------------------------------------------------------------------------

SELECT *
FROM Potfolio_Project.dbo.Nashville_data;
