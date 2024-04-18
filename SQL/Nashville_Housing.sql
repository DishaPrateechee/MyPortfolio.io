--Assumption: Properties with No Owner Name or Address will be disregarded from the analysis.
--/*Use Cases*/
--1. Identify the Distribution of the LandUse to get an understanding of what type of Land is being sold.
--2. Year Built vs Price which gives information about the foundation of the property.

SELECT * FROM dbo.[Nashville Housing];

--Identify and normalize the date format for SaleDate column

SELECT SaleDate, CONVERT(Date, SaleDate)
FROM dbo.[Nashville Housing];

UPDATE dbo.[Nashville Housing]
SET SaleDate = CONVERT(Date, SaleDate) --Updating the SaleDate format

--Checking for any NULL values in ParcelID and Property Address

SELECT ParcelID, PropertyAddress FROM dbo.[Nashville Housing] WHERE PropertyAddress IS NULL; --29 Records.

--Checking for records which have same Parcel ID but different Unique ID and Property address is null.

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM dbo.[Nashville Housing] a
JOIN dbo.[Nashville Housing] b
ON a.ParcelID = b.ParcelID AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM dbo.[Nashville Housing] a
JOIN dbo.[Nashville Housing] b
	ON a.ParcelID = b.parcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null

-- Update PropertyAddress column using alias a.
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM dbo.[Nashville Housing] a
JOIN dbo.[Nashville Housing] b
	ON a.ParcelID = b.parcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null
--Cleaned out the NULL values of Property Address which had a matching Parcel ID.

----------

--For Property Address, we can separate the Address and City so that we can analyse the city where majority of the available properties are.

Select PropertyAddress
FROM dbo.[Nashville Housing]

--Splitting the Address into Address and City name

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as City
FROM dbo.[Nashville Housing];
-- PropertyAddress at position 1 until the comma ','. Then to remove the comma, -1. Name the column 'Address' 
--and post the comma will be the city

-- Add a column for the split address named AreaAddress.
ALTER TABLE [Nashville Housing]
ADD AreaAddress Nvarchar(255);

-- Input the data for the split address named AreaAddress column.
Update [Nashville Housing]
SET AreaAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1);

-- Add a column for the split address named City.
ALTER TABLE [Nashville Housing]
ADD City Nvarchar(255);

-- Input the data for the split address named City column.
Update [Nashville Housing]
SET City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress));

--Let's split OwnerAddress into separate columns for address, city, and state.

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM dbo.[Nashville Housing]

-- Add a column for OwnerAreaAddress.
ALTER TABLE [Nashville Housing]
ADD OwnerAreaAddress Nvarchar(255);

-- Input the data for OwnerAreaAddress column.
Update [Nashville Housing]
SET OwnerAreaAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)

-- Add a column for OwnerCityAddress.
ALTER TABLE [Nashville Housing]
ADD OwnerCityAddress Nvarchar(255);

-- Input the data for OwnerCityAddress column.
Update [Nashville Housing]
SET OwnerCityAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

-- Add a column for OwnerStateAddress.
ALTER TABLE [Nashville Housing]
ADD OwnerStateAddress Nvarchar(255);

-- Input the data for OwnerStateAddress column.
Update [Nashville Housing]
SET OwnerStateAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)

--Check the SoldAsVacant column.
SELECT DISTINCT(SoldAsVacant), COUNT (SoldAsVacant)
FROM dbo.[Nashville Housing]
GROUP BY SoldAsVacant
ORDER BY 2

--Alter the data type to varchar
ALTER TABLE [Nashville Housing]
ALTER COLUMN SoldAsVacant varchar(255)

--Update show as Yes/No in the Sold as Vacant field.
SELECT SoldAsVacant
, CASE 
	WHEN SoldAsVacant = '1' THEN 'Yes' 
	WHEN SoldAsVacant = '0' THEN 'No'
	ELSE SoldAsVacant
	END
FROM dbo.[Nashville Housing]

UPDATE dbo.[Nashville Housing]
SET SoldAsVacant = CASE 
	WHEN SoldAsVacant = '1' THEN 'Yes' 
	WHEN SoldAsVacant = '0' THEN 'No'
	ELSE SoldAsVacant
	END


--Check for any duplicate records.
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY UniqueID
				) AS row_num
FROM dbo.[Nashville Housing]
ORDER BY ParcelID

--Using CTE to view all the duplicates i.e. row_num value of 2 
WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY UniqueID
				) AS row_num
FROM dbo.[Nashville Housing])
SELECT *
FROM RowNumCTE 
WHERE row_num > 1
ORDER BY PropertyAddress

--Remove duplicates using CTE
WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY UniqueID
				) AS row_num
FROM dbo.[Nashville Housing])
DELETE
FROM RowNumCTE 
WHERE row_num > 1

--Identify the columns where there is no data related to Owner. 
--(It either can be used to do further investigation or can be disregarded from the analysis)
SELECT *
FROM dbo.[Nashville Housing]
WHERE OwnerName IS NULL AND OwnerAddress IS NULL --30,462 Records.

--Delete any unused columns
SELECT *
FROM dbo.[Nashville Housing]

ALTER TABLE [Nashville Housing]
DROP COLUMN OwnerAddress, PropertyAddress
