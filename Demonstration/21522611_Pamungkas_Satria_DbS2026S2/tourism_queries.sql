/* tourism_queries.sql
   Name       : Satria Pamungkas
   Student ID : 21522611

   Purpose: Part 3 - questions about tourism answered with SQL queries.
            Q1-Q5  = Level 1 (single table, WHERE, numeric, date-time and string functions)
            Q6-Q10 = Level 2 (joins, sub-queries, GROUP BY, HAVING, ORDER BY, aggregates)
   Run    : mysql> SOURCE tourism_queries.sql;   (after tourism_create.sql and tourism_data.sql) */

USE Pamungkas_21522611;

-- ==================================================================
-- LEVEL 1
-- ==================================================================

-- Q1. Which countries received more than 50 million international tourists
--     in 2019 (the last year before COVID-19)? Show arrivals in millions.
--     (numeric condition, arithmetic, ROUND, ORDER BY)
SELECT countryCode,
       statYear,
       ROUND(arrivals / 1000000, 2) AS arrivalsMillions
FROM YearlyStat
WHERE statYear = 2019
  AND arrivals > 50000000
ORDER BY arrivals DESC;

-- Q2. Which heritage sites have a name containing 'Cathedral' or 'Temple'?
--     Show the name in upper case and its length.
--     (string comparison with LIKE, UPPER, CHAR_LENGTH)
SELECT siteId,
       UPPER(siteName)      AS siteNameUpper,
       CHAR_LENGTH(siteName) AS nameLength
FROM HeritageSite
WHERE siteName LIKE '%Cathedral%'
   OR siteName LIKE '%Temple%'
ORDER BY nameLength;

-- Q3. Which Natural heritage sites were inscribed between 2000 and 2015,
--     and how many years ago (from today) were they inscribed?
--     (BETWEEN, date-time functions YEAR() and CURDATE())
SELECT siteName,
       yearInscribed,
       YEAR(CURDATE()) - yearInscribed AS yearsOnList
FROM HeritageSite
WHERE category = 'Natural'
  AND yearInscribed BETWEEN 2000 AND 2015
ORDER BY yearInscribed;

-- Q4. Which yearly records are missing the tourism receipts value?
--     (useful to know where the data source has gaps; IS NULL)
SELECT countryCode,
       statYear,
       arrivals
FROM YearlyStat
WHERE receiptsUSD IS NULL
ORDER BY countryCode, statYear;

-- Q5. Give a short label for every large heritage site (over 1 million hectares),
--     e.g. 'Natural: Great Barrier Reef...' using only the first 25 characters,
--     and its area in square kilometres (1 km2 = 100 ha).
--     (CONCAT, SUBSTRING, numeric calculation, FORMAT)
SELECT CONCAT(category, ': ', SUBSTRING(siteName, 1, 25), '...') AS siteLabel,
       FORMAT(areaHectares / 100, 0) AS areaKm2
FROM HeritageSite
WHERE areaHectares > 1000000
ORDER BY areaHectares DESC;

-- ==================================================================
-- LEVEL 2
-- ==================================================================

-- Q6. For each country show its region and income group, and the
--     tourism receipts in 2019 in billions of US$.
--     (INNER JOIN of four tables)
SELECT c.countryName,
       r.regionName,
       i.incomeName,
       ROUND(y.receiptsUSD / 1000000000, 2) AS receiptsBillionUSD
FROM Country c
INNER JOIN Region r      ON c.regionCode = r.regionCode
INNER JOIN IncomeGroup i ON c.incomeCode = i.incomeCode
INNER JOIN YearlyStat y  ON c.countryCode = y.countryCode
WHERE y.statYear = 2019
ORDER BY y.receiptsUSD DESC;

-- Q7. How many heritage sites of each category does each country have?
--     Only show countries with at least 20 sites in total.
--     (JOIN, GROUP BY, conditional SUM, HAVING)
SELECT c.countryName,
       COUNT(*) AS totalSites,
       SUM(h.category = 'Cultural') AS cultural,
       SUM(h.category = 'Natural')  AS natural_,
       SUM(h.category = 'Mixed')    AS mixed
FROM Country c
INNER JOIN SiteCountry sc ON c.countryCode = sc.countryCode
INNER JOIN HeritageSite h ON sc.siteId = h.siteId
GROUP BY c.countryName
HAVING COUNT(*) >= 20
ORDER BY totalSites DESC;

-- Q8. What was the average yearly number of arrivals of each region
--     before COVID-19 (2015-2019)? Regions without countries in our
--     data are also shown (LEFT JOIN gives NULL for them).
--     (LEFT JOIN, AVG, MAX, GROUP BY)
SELECT r.regionName,
       COUNT(DISTINCT c.countryCode)         AS numCountries,
       ROUND(AVG(y.arrivals) / 1000000, 2)   AS avgArrivalsMillions,
       ROUND(MAX(y.arrivals) / 1000000, 2)   AS maxArrivalsMillions
FROM Region r
LEFT JOIN Country c    ON r.regionCode = c.regionCode
LEFT JOIN YearlyStat y ON c.countryCode = y.countryCode
                      AND y.statYear BETWEEN 2015 AND 2019
GROUP BY r.regionName
ORDER BY avgArrivalsMillions DESC;

-- Q9. Which countries earned more tourism income in 2019 than the
--     average of all our countries in 2019?
--     (sub-query in WHERE with an aggregate)
SELECT c.countryName,
       ROUND(y.receiptsUSD / 1000000000, 2) AS receiptsBillionUSD
FROM Country c
INNER JOIN YearlyStat y ON c.countryCode = y.countryCode
WHERE y.statYear = 2019
  AND y.receiptsUSD > (SELECT AVG(receiptsUSD)
                       FROM YearlyStat
                       WHERE statYear = 2019)
ORDER BY y.receiptsUSD DESC;

-- Q10. For each country, in which year did it have its highest number of
--      arrivals, and how far did arrivals drop in 2020 compared with 2019?
--      (correlated sub-query, self LEFT JOIN of YearlyStat with aliases)
SELECT c.countryName,
       (SELECT y1.statYear
        FROM YearlyStat y1
        WHERE y1.countryCode = c.countryCode
        ORDER BY y1.arrivals DESC
        LIMIT 1) AS peakYear,
       ROUND(100 * (y20.arrivals - y19.arrivals) / y19.arrivals, 1) AS changePct2020
FROM Country c
LEFT JOIN YearlyStat y19 ON c.countryCode = y19.countryCode AND y19.statYear = 2019
LEFT JOIN YearlyStat y20 ON c.countryCode = y20.countryCode AND y20.statYear = 2020
ORDER BY changePct2020;

-- Q11 (extra). Which transboundary heritage sites are shared by more than
--      one of our countries, and which countries share them?
--      (sub-query with IN, GROUP_CONCAT)
SELECT h.siteName,
       GROUP_CONCAT(c.countryName ORDER BY c.countryName SEPARATOR ', ') AS sharedBy
FROM HeritageSite h
INNER JOIN SiteCountry sc ON h.siteId = sc.siteId
INNER JOIN Country c      ON sc.countryCode = c.countryCode
WHERE h.siteId IN (SELECT siteId
                   FROM SiteCountry
                   GROUP BY siteId
                   HAVING COUNT(*) > 1)
GROUP BY h.siteId, h.siteName;
