# World Life Expectancy Analysis: Data Cleaning and Exploratory Data Analysis with SQL

## Introduction

This project is part of my data analysis portfolio, demonstrating my skills in both *Data Cleaning (DC)* and *Exploratory Data Analysis (EDA)* using **SQL**. The analysis focuses on life expectancy data from countries around the world, covering various factors such as mortality, healthcare expenditure, and economic indicators.

## Dataset Overview

The dataset used in this project consists of life expectancy records from multiple countries over different years. The dataset includes the following columns:

- `Country`: Name of the country.
- `Year`: Year of the record.
- `Status`: Economic classification of the country (e.g., Developed, Developing).
- `Lifeexpectancy`: Life expectancy at birth in years.
- `AdultMortality`: Adult mortality rate per 1000 adults.
- `infantdeaths`: Number of infant deaths per 1000 births.
- `percentageexpenditure`: Government health expenditure as a percentage of GDP.
- `Measles`: Number of reported measles cases.
- `BMI`: Average body mass index of the population.
- `under-fivedeaths`: Number of deaths in children under five per 1000 births.
- `Polio`: Percentage of children immunized against polio.
- `Diphtheria`: Percentage of children immunized against diphtheria.
- `HIVAIDS`: HIV/AIDS-related deaths per 1000 adults.
- `GDP`: Gross Domestic Product of the country.
- `thinness1-19years`: Prevalence of thinness among children aged 1-19.
- `thinness5-9years`: Prevalence of thinness among children aged 5-9.
- `Schooling`: Average number of years of schooling.
- `Row_ID`: Unique identifier for each row.

---

## Phase 1: Data Cleaning

Before performing any analysis, it’s crucial to clean and standardize the data. This phase focuses on removing inconsistencies, handling missing or erroneous values, and ensuring that the dataset is ready for meaningful analysis.

1. **Removing duplicates**: Identifying and eliminating duplicate records.
2. **Handling null or incorrect values**: Dealing with missing or incorrect data entries.
3. **Standardizing formats**: Ensuring consistency in columns such as `Lifeexpectancy` and `GDP`.

### Removing Duplicates

In this step, I identified and removed duplicate records from the `world_life_expectancy` table. The dataset lacked a unique employee ID, so I used a combination of `Country` and `Year` to detect duplicates.

```sql
-- DELETE DUPLICATES by giving them a row_number and deleting the extra ones
DELETE FROM world_life_expectancy 
WHERE Row_ID IN (
                SELECT Row_ID
                FROM (SELECT Row_ID,
                    CONCAT(Country, Year),
                    ROW_NUMBER() OVER (PARTITION BY CONCAT(Country, Year) ORDER BY Row_ID) AS row_num
                    FROM world_life_expectancy) AS numbered
                WHERE row_num > 1
                );
```

#### Explanation

This query first assigns a `ROW_NUMBER()` to each record partitioned by the combination of `Country` and `Year`. It then deletes all rows where the row number is greater than 1, effectively removing duplicates. The use of `ROW_NUMBER()` ensures that only the first instance of each duplicate record is retained.

### Populating the `Status` Column

In this step, the goal was to fill in missing values in the `Status` column by using the existing values for the same country from other rows.

```sql
-- POPULATE STATUS COLUMN
-- Populate the blank rows using the previous countries as reference
UPDATE world_life_expectancy t1
    JOIN world_life_expectancy t2
    ON t1.Country = t2.Country -- match the cases through their country
SET t1.Status = 'Developing'
WHERE t1.Status = '' -- keep the blank rows to be populated
    AND t2.Status = 'Developing' AND t2.Status <> ''; -- select only the value that needs to be used to populate;
```

#### Explanation

This query uses a `JOIN` operation to match rows based on the `Country` column. The query fills in blank `Status` values for countries by using the existing `Status` value (in this case, "Developing") from other rows for the same country. The condition ensures that only blank rows are updated, while valid `Status` values remain unchanged.

### Populating the `Lifeexpectancy` Column

In this step, the goal was to fill in missing values in the `Lifeexpectancy` column by averaging the values from the previous and following years for the same country.

```sql
-- POPULATE LIFEEXPECTANCY COLUMN

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
WHERE wle.Lifeexpectancy = '';
```

#### Explanation

This query uses a `WITH` clause (common table expression, or CTE) to calculate the average life expectancy for each country by taking the values from the previous and following years using `LAG()` and `LEAD()`. It then updates the `Lifeexpectancy` column for rows where the value is missing (blank) with the calculated average. This method helps fill gaps in the data by interpolating between existing values.

## Phase 2: Exploratory Data Analysis (EDA)

Once the data has been cleaned, we can move on to __Exploratory Data Analysis (EDA)__ to discover patterns and trends in the life expectancy data. In this phase, we use SQL queries to explore how factors such as economic status, healthcare spending, and education level affect life expectancy across countries.

### Evolution of Life Expectancy by Country

The first analysis focuses on the evolution of life expectancy over the years for each country. This helps identify countries where life expectancy has improved or declined significantly over time.

```sql
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
```

#### Explanation

This query calculates the minimum (`MIN`) and maximum (`MAX`) life expectancy for each country, then computes the variation between the two values to show how life expectancy has evolved over time. The `HAVING` clause ensures that countries with zero values (missing data) are excluded. The results are ordered by the largest variation, helping to highlight the countries with the most significant changes in life expectancy.

### Life Expectancy Comparison Based on GDP

This analysis aims to compare the life expectancy of countries with high and low GDP. Countries are grouped into two categories: those with a GDP greater than or equal to 1500, and those with a GDP below 1500.

```sql
SELECT 
    SUM(CASE WHEN GDP >= 1500 THEN 1 ELSE 0 END) AS High_GDP_Count,
    ROUND(AVG(CASE WHEN GDP >= 1500 THEN Lifeexpectancy ELSE NULL END),1) AS High_GDP_Lifeexpectancy_Avg,
    SUM(CASE WHEN GDP < 1500 THEN 1 ELSE 0 END) AS Low_GDP_Count,
    ROUND(AVG(CASE WHEN GDP < 1500 THEN Lifeexpectancy ELSE NULL END),1) AS Low_GDP_Lifeexpectancy_Avg
FROM world_life_expectancy
ORDER BY GDP;
```

#### Explanation

This query categorizes countries into two groups based on their GDP: those with a GDP greater than or equal to 1500 (`High_GDP`) and those with a GDP lower than 1500 (`Low_GDP`). It calculates both the number of countries in each category and the average life expectancy for those countries. The `CASE` statement helps to segment the data, and the results offer insight into how economic status (as measured by GDP) correlates with life expectancy.

### Life Expectancy by Country Status

This analysis compares the average life expectancy based on the economic classification of countries (developed vs. developing). It also shows how many countries fall into each category.

```sql
-- Life_Exp by Status of Country
SELECT Status, 
    COUNT(DISTINCT Country) Num_Countries, 
    ROUND(AVG(Lifeexpectancy),1) Avg_Life_Exp
FROM world_life_expectancy
GROUP BY Status;
```

##### Explanation

This query groups countries by their Status (developed or developing) and calculates the number of countries in each category as well as the average life expectancy (`AVG(Lifeexpectancy)`). The results help reveal the differences in life expectancy between developed and developing countries, providing insights into how economic classification impacts overall health and longevity.

### Example Code Block 4: Rolling Total of Adult Mortality by Country

This analysis calculates the rolling total of adult mortality over time for each country, providing insight into how mortality rates have accumulated year after year.

```sql
-- Rolling Total
SELECT Country,
Year,
Lifeexpectancy,
AdultMortality,
SUM(AdultMortality) OVER(PARTITION BY Country ORDER BY Year) AS Rolling_Total
FROM world_life_expectancy;
```

#### Explanation

This query calculates a rolling total of adult mortality for each country using the `SUM() OVER()` window function. It partitions the data by `Country` and orders it by `Year`, allowing us to see how the total adult mortality has changed over time for each country. This provides a cumulative view of mortality rates, which can be useful for detecting long-term trends in public health.

