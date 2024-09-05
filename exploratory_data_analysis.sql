# World Life Expectancy Project (Exploratory Data Analysis)

SELECT * 
FROM world_life_expectancy;

-- Period of time recorded of data
SELECT MIN(Year) Start_of_records, 
    MAX(Year) End_of_records,
    MAX(Year) - MIN(Year) Years_of_records 
FROM world_life_expectancy;

-- Evolution of Life Expectancy over the years by country
SELECT Country, 
    MIN(Lifeexpectancy) Min, 
    MAX(Lifeexpectancy) Max,
    ROUND((MAX(Lifeexpectancy) - MIN(Lifeexpectancy)),1) Variation
FROM world_life_expectancy
GROUP BY Country
HAVING Min <> 0
AND Max <> 0 -- There are cases with zeros
ORDER BY Variation DESC; 

-- Average Life Expectancy in the world by Year
SELECT Year, ROUND(AVG(Lifeexpectancy),2)
FROM world_life_expectancy
WHERE Lifeexpectancy <> 0
AND Lifeexpectancy <> 0 -- There are cases with zeros
GROUP BY Year
ORDER BY Year;

-- Look for posible correlation between Life_Exp and GDP
SELECT Country, ROUND(AVG(Lifeexpectancy),1) Life_Exp, ROUND(AVG(GDP),1) AS GDP
FROM world_life_expectancy
GROUP BY Country
HAVING GDP <> 0
    AND Life_Exp <> 0
ORDER BY GDP DESC;

-- Correlation of High and Low Life_Exp and GDP 
SELECT 
    ROUND(SUM(CASE WHEN GDP >= 1500 THEN 1 ELSE 0 END),1) AS High_GDP_Count,
    ROUND(AVG(CASE WHEN GDP >= 1500 THEN Lifeexpectancy ELSE NULL END),1) AS High_GDP_Lifeexpectancy_Avg,
    ROUND(SUM(CASE WHEN GDP < 1500 THEN 1 ELSE 0 END),1) AS Low_GDP_Count,
    ROUND(AVG(CASE WHEN GDP < 1500 THEN Lifeexpectancy ELSE NULL END),1) AS Low_GDP_Lifeexpectancy_Avg
FROM world_life_expectancy
ORDER BY GDP;

-- Life_Exp by Status of Country
SELECT Status, 
    COUNT(DISTINCT Country) Num_Countries, 
    ROUND(AVG(Lifeexpectancy),1) Avg_Life_Exp
FROM world_life_expectancy
GROUP BY Status;

-- Look for posible correlation between Life_Exp and BMI
SELECT Country, Status, ROUND(AVG(Lifeexpectancy),1) Life_Exp, ROUND(AVG(BMI),1) AS BMI
FROM world_life_expectancy
GROUP BY Country, Status
HAVING BMI <> 0
    AND Life_Exp <> 0
ORDER BY BMI DESC;

-- Rolling Total
SELECT Country,
Year,
Lifeexpectancy,
AdultMortality,
SUM(AdultMortality) OVER(PARTITION BY Country ORDER BY Year) AS Rolling_Total
FROM world_life_expectancy
WHERE Country LIKE '%United%'
;
