# World Life Expectancy Project (Data Cleaning)
 
SELECT * 
FROM world_life_expectancy;

-- DELETE DUPLICATES

-- Look for duplicates (the database is lacking a 'employee_id' column so it needs to be created a column that works alike)

SELECT Country, Year, CONCAT(Country, Year), COUNT(CONCAT(Country, Year))
FROM world_life_expectancy
GROUP BY Country, Year, CONCAT(Country, Year)
HAVING COUNT(CONCAT(Country, Year)) > 1;

-- DELETE DUPLICATES by giving them a row_number and deleting the extra ones

SELECT *
FROM (SELECT Row_ID,
        CONCAT(Country, Year),
        ROW_NUMBER() OVER (PARTITION BY CONCAT(Country, Year) ORDER BY Row_ID) AS row_num
        FROM world_life_expectancy) AS numbered
WHERE row_num > 1;

-- Delete the rows using the previous query as reference

DELETE FROM world_life_expectancy 
WHERE Row_ID IN (
                SELECT Row_ID
                FROM (SELECT Row_ID,
                    CONCAT(Country, Year),
                    ROW_NUMBER() OVER (PARTITION BY CONCAT(Country, Year) ORDER BY Row_ID) AS row_num
                    FROM world_life_expectancy) AS numbered
                WHERE row_num > 1
                );

-- POPULATE STATUS COLUMN
-- Check 'Status' column for missing values
SELECT * 
FROM world_life_expectancy
WHERE Status = '' 
    OR Status IS NULL; -- there are only blank values

-- See what values the column contains
SELECT DISTINCT (status)
FROM world_life_expectancy
WHERE Status <> '';

-- Look what countries have 'developing' value
SELECT DISTINCT (country)
FROM world_life_expectancy
WHERE Status = 'Developing';

-- Populate the blank rows using the previous countries as reference
UPDATE world_life_expectancy t1
    JOIN world_life_expectancy t2
    ON t1.Country = t2.Country -- match the cases through their country
SET t1.Status = 'Developing'
WHERE t1.Status = '' -- keep the blank rows to be populated
    AND t2.Status = 'Developing' AND t2.Status <> '' -- select only the value that needs to be used to populate;

-- Check all blank values are gone
SELECT * 
FROM world_life_expectancy
WHERE Status = ''; -- United States has one case of blank value

-- Look at the single case with 'Developed' value
SELECT *
FROM world_life_expectancy
WHERE Country = 'United States of America';

-- Populate the 'Developed' countries using the same procedure
UPDATE world_life_expectancy t1
    JOIN world_life_expectancy t2
    ON t1.Country = t2.Country 
SET t1.Status = 'Developed'
WHERE t1.Status = ''
    AND t2.Status = 'Developed' AND t2.Status <> '' ;

-- POPULATE LIFEEXPECTANCY COLUMN
-- Check 'Lifeexpectancy' column for missing values
SELECT * 
FROM world_life_expectancy
WHERE Lifeexpectancy = '' 
    OR Lifeexpectancy IS NULL; -- there are only two blank values

-- Exists an upwards trend of Lifeexpectancy values overtime. 
-- Missing values will be populated with the average value between its previous and following values.

-- Calculate new_values

SELECT *, ROUND(((following + previous)/2),1) new_value
FROM (SELECT Country, Year, Lifeexpectancy,
     LAG(Lifeexpectancy) OVER (PARTITION BY Country ORDER BY Year ASC) previous,
     LEAD(Lifeexpectancy) OVER (PARTITION BY Country ORDER BY Year ASC) following
FROM world_life_expectancy) Lifeexpectancy_values
;

-- Populate the blank values

WITH av AS
(SELECT *, ROUND(((following + previous)/2),1) new_value
FROM (SELECT Country, Year, Lifeexpectancy,
     LAG(Lifeexpectancy) OVER (PARTITION BY Country ORDER BY Year ASC) previous,
     LEAD(Lifeexpectancy) OVER (PARTITION BY Country ORDER BY Year ASC) following
FROM world_life_expectancy) Lifeexpectancy_values
)

UPDATE world_life_expectancy wle
JOIN av ON wle.Country = av.Country 
        AND wle.Year = av.Year
SET wle.Lifeexpectancy = av.new_value
WHERE wle.Lifeexpectancy = ''
;