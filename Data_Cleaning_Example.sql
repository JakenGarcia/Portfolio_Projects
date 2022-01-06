/*

Cleaning Data

*/

---------------------------------------------

-- Standardize Date Format
-- Convert function wasn't working so I used Alter Table

SELECT 
	SaleDateConverted
	,CONVERT(Date,SaleDate)
FROM
	Data_Cleaning_Housing..NashvilleHousing

Update
	NashvilleHousing
SET
	SaleDate = CONVERT(Date,SaleDate)

ALTER TABLE 
	NashvilleHousing
ADD SaleDateConverted Date;

Update 
	NashvilleHousing
SET
	SaleDateConverted = CONVERT(Date,SaleDate)

--------------------------------------------------

-- Populate Property Address data
-- In areas where the ParcellID is 
SELECT 
	a.ParcelID
	, a.PropertyAddress
	, b.ParcelID
	, b.PropertyAddress
	, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM
	Data_Cleaning_Housing..NashvilleHousing a
JOIN
	Data_Cleaning_Housing..NashvilleHousing b
ON
	a.ParcelID = b.ParcelID
	AND a.[UniqueID ]<> b.[UniqueID ]
WHERE
	a.PropertyAddress IS NULL

UPDATE 
	a
SET 
	Propertyaddress = ISNULL(a.propertyaddress, b.PropertyAddress)
FROM
	Data_Cleaning_Housing..NashvilleHousing a
JOIN
	Data_Cleaning_Housing..NashvilleHousing b
ON
	a.ParcelID = b.ParcelID
	AND a.[UniqueID ]<> b.[UniqueID ]
WHERE
	a.PropertyAddress IS NULL

------------------------------------------------
-- Breaking out address into individual columns (address, city, state)

SELECT
	SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress)-1) as Address
	, SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) +1, Len(propertyAddress)) as City
FROM
	Data_Cleaning_Housing..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255)

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress)-1) 

ALTER TABLE  NashvilleHousing
ADD PropertySplitCity Nvarchar(255)

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) +1, Len(propertyAddress)) 

SELECT
	*
FROM
	Data_Cleaning_Housing..NashvilleHousing
------------------------------------------------
-- Splitting out the Owner Address into its corresponding parts

SELECT
	OwnerAddress
FROM
	Data_Cleaning_Housing..NashvilleHousing

-- PARSENAME extracts data based on a period separator, but we had commas dividing up the address information. 
-- REPLACE function used to turn all commas into periods so that the Parsename function could do its job. 
SELECT
	PARSENAME(REPLACE(OwnerAddress,',','.'),3),
	PARSENAME(REPLACE(OwnerAddress,',','.'),2),
	PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM
	Data_Cleaning_Housing..NashvilleHousing

-- Updating table with new values

ALTER TABLE  Data_Cleaning_Housing..NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255)

UPDATE Data_Cleaning_Housing..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

ALTER TABLE  Data_Cleaning_Housing..NashvilleHousing
ADD OwnerSplitCity Nvarchar(255)

UPDATE Data_Cleaning_Housing..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

ALTER TABLE  Data_Cleaning_Housing..NashvilleHousing
ADD OwnerSplitState Nvarchar(255)

UPDATE Data_Cleaning_Housing..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

----------------------------------------
-- Change "Y" to "Yes" and "N" to "No" in Sold as Vacant field

SELECT Distinct
	Soldasvacant
FROM
	Data_Cleaning_Housing..NashvilleHousing

UPDATE Data_Cleaning_Housing..NashvilleHousing
SET SoldAsVacant = CASE
	WHEN SoldAsVacant = 'N' THEN 'No'
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	ELSE SoldAsVacant
		END
FROM
	Data_Cleaning_Housing..NashvilleHousing

-- Confirming the change worked

SELECT DISTINCT
	Soldasvacant
FROM
	Data_Cleaning_Housing..NashvilleHousing

-------------------------------------------------------
-- Remove Duplicates


WITH RowNumCTE AS(
	
SELECT 
	*,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
	ORDER BY
		UniqueID
		) row_num
FROM Data_Cleaning_Housing..NashvilleHousing
)
DELETE
FROM
	RowNumCTE
WHERE
	row_num > 1

----------------------------------------------------
-- Delete Unused columns to reduce strain on resources
-- Ensuring that this isn't the raw dataset, of course. It's always best to leave that untouched and work from a copy

ALTER TABLE 
	Data_Cleaning_Housing..NashvilleHousing
DROP COLUMN 
	OwnerAddress, 
	PropertyAddress,
	TaxDistrict,
	SaleDate

