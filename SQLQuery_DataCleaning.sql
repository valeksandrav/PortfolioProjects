SELECT *
FROM [PortfolioProject].[dbo].[NashvilleHousing]

-- Standardize date format
ALTER TABLE NashvilleHousing
ADD SaleDateConverted DATE 

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

-- Populate property address data
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, 
    ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a 
JOIN PortfolioProject..NashvilleHousing b 
    ON a.ParcelID = b.ParcelID 
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL 

UPDATE a 
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a 
JOIN PortfolioProject..NashvilleHousing b 
    ON a.ParcelID = b.ParcelID 
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL 

-- Breaking out address into individual columns (address, city, state)
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255) 

UPDATE NashvilleHousing 
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255)

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

ALTER TABLE NashvilleHousing 
ADD OwnerSplitAddress NVARCHAR(255)

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255)

UPDATE NashvilleHousing 
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) 

ALTER TABLE NashvilleHousing
ADD OwnerSplitState NVARCHAR(255)

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-- Change y and n to yes and no in sold as vacant field 
SELECT DISTINCT(SoldAsVacant), 
COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY COUNT(SoldAsVacant)

UPDATE NashvilleHousing 
SET SoldAsVacant = 
    CASE    WHEN SoldAsVacant = 'Y' THEN 'Yes'
            WHEN SoldAsVacant = 'N' THEN 'No'
            ELSE SoldAsVacant
            END

-- Remove duplicates 
WITH RowNumCTE AS (
    SELECT *,
        ROW_NUMBER() OVER(
            PARTITION BY ParcelID,
                         PropertyAddress,
                         SalePrice,
                         SaleDate,
                         LegalReference
            ORDER BY UniqueID
        ) row_num
    FROM PortfolioProject..NashvilleHousing
    --ORDER BY ParcelID 
)
DELETE 
FROM RowNumCTE
WHERE row_num > 1

-- Delete unused columns 
ALTER TABLE PortfolioProject..NashvilleHousing 
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate 
