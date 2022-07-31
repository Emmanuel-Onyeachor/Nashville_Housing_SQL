CREATE DATABASE Nashville;

USE Nashville;

-- Use data import wizard to import Nashville housing data

SELECT * FROM housingdata;

-- Only column headers were imported. Use Load data infile in command line to import records
SET SQL_SAFE_UPDATES = 0;
DELETE FROM housingdata;
SET SQL_SAFE_UPDATES = 1;

SET GLOBAL LOCAL_INFILE = 1;

LOAD DATA LOCAL INFILE 'C:/Users/name/Desktop/Folder/Alex Covid SQL/Project 3/HousingData.csv'
INTO TABLE housingdata
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

SELECT * FROM housingdata;

-- Standardize date format
SELECT Saledate, Convert(SaleDate, date)
From housingdata;

ALTER TABLE housingdata
ADD COLUMN Newsaledate date AFTER saledate;

UPDATE housingdata
SET Newsaledate = Convert(SaleDate, date);

SELECT ifnull(Newsaledate, Convert(SaleDate, date)) FROM housingdata;

-- Populate property address data
SELECT Propertyaddress
From housingdata;

SELECT Propertyaddress
From housingdata
WHERE propertyaddress is null
or propertyaddress = '';

-- To clear null and blank values, use self join to populate the missing records
SELECT a.parcelID, a.propertyaddress, b.parcelID, b.propertyaddress, ifnull(nullif(a.propertyaddress, ''), b.propertyaddress)
From housingdata a
JOIN housingdata b
	ON a.parcelID = b.parcelID
    AND a.uniqueID <> b.uniqueID
    WHERE a.propertyaddress = '';

UPDATE housingdata a
JOIN housingdata b
	ON a.parcelID = b.parcelID
    AND a.uniqueID <> b.uniqueID
SET a.propertyaddress = ifnull(nullif(a.propertyaddress, ''), b.propertyaddress)
WHERE a.propertyaddress = '';

-- Break property address into individual columns
SELECT *
FROM housingdata;

SELECT
SUBSTRING_iNDEX(propertyaddress, '-', 1) as address, SUBSTRING_iNDEX(propertyaddress, '-', -1) as city
FROM housingdata;

ALTER TABLE housingdata
ADD COLUMN PropertySplitAddress varchar(255) AFTER LandUse;

ALTER TABLE housingdata
ADD COLUMN PropertySplitCity varchar(255) AFTER PropertySplitAddress;

UPDATE housingdata
SET PropertySplitAddress = SUBSTRING_iNDEX(propertyaddress, '-', 1);

UPDATE housingdata
SET PropertySplitCity = SUBSTRING_iNDEX(propertyaddress, '-', -1);

-- Break owner address into individual columns
SELECT *
FROM housingdata;

SELECT
SUBSTRING_iNDEX(owneraddress, '-', 1) as address, SUBSTRING_iNDEX(SUBSTRING_INDEX(owneraddress, '-', 2), '-', -1) as city, 
SUBSTRING_iNDEX(owneraddress, '-', -1) as state
FROM housingdata;

ALTER TABLE housingdata
ADD COLUMN OwnerSplitAddress VARCHAR(255) AFTER owneraddress;

ALTER TABLE housingdata
ADD COLUMN OwnerSplitCity VARCHAR(255) AFTER OwnerSplitAddress;

ALTER TABLE housingdata
ADD COLUMN OwnerSplitState VARCHAR(255) AFTER OwnerSplitCity;

UPDATE housingdata
SET OwnerSplitAddress = SUBSTRING_iNDEX(owneraddress, '-', 1);

UPDATE housingdata
SET OwnerSplitCity = SUBSTRING_iNDEX(SUBSTRING_INDEX(owneraddress, '-', 2), '-', -1);

UPDATE housingdata
SET OwnerSplitState = SUBSTRING_iNDEX(owneraddress, '-', -1);

-- Change Y and N to Yes and No in "Sold as Vacant" field
Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From housingdata
Group by SoldAsVacant;

Select SoldAsVacant,
CASE SoldAsVacant WHEN 'Y' THEN 'Yes'
WHEN 'N' THEN 'No'
Else SoldAsVacant
end AS SAV2
FROM housingdata;

Update housingdata
SET SoldAsVacant = CASE SoldAsVacant WHEN 'Y' THEN 'Yes'
WHEN 'N' THEN 'No'
Else SoldAsVacant
end;

-- Remove Duplicates
WITH ROWNUMCTE AS(
Select *,
	ROW_NUMBER() OVER(
    PARTITION BY ParcelID,
				PropertyAddress,
                SalePrice,
                SaleDate,
                LegalReference
                ORDER BY
					UniqueID
                    ) row_num
	FROM housingdata
    )
    Select * from RownumCTE
    Where row_num > 1
    Order by propertyaddress;
    
    WITH ROWNUMCTE AS(
Select *,
	ROW_NUMBER() OVER(
    PARTITION BY ParcelID,
				PropertyAddress,
                SalePrice,
                SaleDate,
                LegalReference
                ORDER BY
					UniqueID
                    ) row_num
	FROM housingdata
    )
    Delete from RownumCTE
    Where row_num > 1;

-- delete rows with error entries
delete from housingdata
where uniqueid = 0;

delete from housingdata
where saledate = 'hosp';

-- Delete unused columns
Select * from housingdata;

ALTER TABLE housingdata
DROP COLUMN OwnerAddress, DROP COLUMN TaxDistrict, DROP COLUMN PropertyAddress, DROP COLUMN Saledate;