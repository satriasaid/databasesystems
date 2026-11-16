/* tourism_advanced.sql
   Name       : Satria Pamungkas
   Student ID : 21522611

   Purpose: Part 4 - advanced database features
            1. View       CountrySummary   (joins + derived attribute receiptsPerArrival)
            2. Index      idx_site_name    (faster search of heritage sites by name)
            3. Procedure  getCountryStats  (IN parameter)
            4. Procedure  arrivalGrowth    (IN + OUT parameters, IF-ELSE, user-defined variables)
            5. Procedure  listSitesByCategory (cursor + LOOP, OUT parameter)
            6. Procedure  addYearlyStat    (transaction: START TRANSACTION / COMMIT / ROLLBACK)
            7. Trigger    before_stat_insert (BEFORE INSERT, raises an error with SIGNAL)
            8. Trigger    after_stat_update  (AFTER UPDATE, writes an audit log row)
   Run    : mysql> SOURCE tourism_advanced.sql;   (after tourism_data.sql)
            The test statements are at the end of this file. */

USE Satria_Said;

-- Remove old versions so the script can be run again
DROP VIEW IF EXISTS CountrySummary;
DROP PROCEDURE IF EXISTS getCountryStats;
DROP PROCEDURE IF EXISTS arrivalGrowth;
DROP PROCEDURE IF EXISTS listSitesByCategory;
DROP PROCEDURE IF EXISTS addYearlyStat;
DROP TRIGGER IF EXISTS before_stat_insert;
DROP TRIGGER IF EXISTS after_stat_update;
DROP TABLE IF EXISTS StatChangeLog;

-- ==================================================================
-- 1. VIEW: CountrySummary
--    One row per country per year with region and income names, and the
--    DERIVED attribute receiptsPerArrival (income per tourist in US$).
--    It is calculated here instead of being stored in YearlyStat.
-- ==================================================================
CREATE VIEW CountrySummary AS
SELECT c.countryCode,
       c.countryName,
       r.regionName,
       i.incomeName,
       y.statYear,
       y.arrivals,
       y.receiptsUSD,
       ROUND(y.receiptsUSD / y.arrivals, 2) AS receiptsPerArrival,
       (SELECT COUNT(*) FROM SiteCountry sc
        WHERE sc.countryCode = c.countryCode) AS numHeritageSites
FROM Country c
INNER JOIN Region r      ON c.regionCode = r.regionCode
INNER JOIN IncomeGroup i ON c.incomeCode = i.incomeCode
INNER JOIN YearlyStat y  ON c.countryCode = y.countryCode;

-- ==================================================================
-- 2. INDEX: heritage sites are often searched by name (e.g. LIKE 'Great%')
-- ==================================================================
-- (tourism_create.sql rebuilds the table, so the index is created fresh.
--  If this file is run twice without rebuilding, this line gives a harmless
--  'Duplicate key name' error and the old index is kept.)
CREATE INDEX idx_site_name ON HeritageSite (siteName);

-- ==================================================================
-- Audit table used by the AFTER UPDATE trigger
-- ==================================================================
CREATE TABLE StatChangeLog (
    logId        INT         NOT NULL AUTO_INCREMENT,
    countryCode  CHAR(3)     NOT NULL,
    statYear     SMALLINT    NOT NULL,
    oldArrivals  BIGINT,
    newArrivals  BIGINT,
    changedBy    VARCHAR(100) NOT NULL,
    changedAt    DATETIME    NOT NULL,
    CONSTRAINT pk_statchangelog PRIMARY KEY (logId)
);

DELIMITER //

-- ==================================================================
-- 3. PROCEDURE getCountryStats (IN parameter)
--    Shows all yearly statistics of one country, newest year first.
--    Example: CALL getCountryStats('AUS');
-- ==================================================================
CREATE PROCEDURE getCountryStats(IN pCountry CHAR(3))
    COMMENT 'Show the yearly tourism statistics of a given country.'
BEGIN
    SELECT statYear, arrivals, departures, receiptsUSD, expenditureUSD
    FROM YearlyStat
    WHERE countryCode = pCountry
    ORDER BY statYear DESC;
END //

-- ==================================================================
-- 4. PROCEDURE arrivalGrowth (IN and OUT parameters, IF-ELSE)
--    Calculates the % change in arrivals of a country between two years
--    and returns it in pGrowth. pMessage says if it grew, dropped or if
--    data is missing.
--    Example: CALL arrivalGrowth('JPN', 2019, 2024, @g, @m); SELECT @g, @m;
-- ==================================================================
CREATE PROCEDURE arrivalGrowth(
    IN  pCountry  CHAR(3),
    IN  pFromYear SMALLINT,
    IN  pToYear   SMALLINT,
    OUT pGrowth   DECIMAL(8,2),
    OUT pMessage  VARCHAR(100)
)
    COMMENT 'Percentage change of arrivals between two years.'
BEGIN
    -- local variables
    DECLARE fromArr BIGINT DEFAULT NULL;
    DECLARE toArr   BIGINT DEFAULT NULL;

    SELECT arrivals INTO fromArr FROM YearlyStat
    WHERE countryCode = pCountry AND statYear = pFromYear;

    SELECT arrivals INTO toArr FROM YearlyStat
    WHERE countryCode = pCountry AND statYear = pToYear;

    IF fromArr IS NULL OR toArr IS NULL OR fromArr = 0 THEN
        SET pGrowth  = NULL;
        SET pMessage = 'No arrival data for one of the years';
    ELSE
        SET pGrowth = ROUND((toArr - fromArr) * 100 / fromArr, 2);
        IF pGrowth > 0 THEN
            SET pMessage = CONCAT(pCountry, ' arrivals GREW by ', pGrowth, '%');
        ELSEIF pGrowth < 0 THEN
            SET pMessage = CONCAT(pCountry, ' arrivals DROPPED by ', ABS(pGrowth), '%');
        ELSE
            SET pMessage = CONCAT(pCountry, ' arrivals did not change');
        END IF;
    END IF;
END //

-- ==================================================================
-- 5. PROCEDURE listSitesByCategory (cursor + LOOP)
--    Builds a comma separated list of the heritage sites of one country
--    and one category, and counts them. (based on Prac07 createProgList)
--    Example: CALL listSitesByCategory('AUS', 'Mixed', @list, @cnt); SELECT @cnt, @list;
-- ==================================================================
CREATE PROCEDURE listSitesByCategory(
    IN  pCountry  CHAR(3),
    IN  pCategory VARCHAR(10),
    OUT pList     TEXT,
    OUT pCount    INT
)
    COMMENT 'List the heritage sites of a country for a given category.'
BEGIN
    -- local variables
    DECLARE done  INT DEFAULT 0;
    DECLARE sName VARCHAR(200);

    -- cursor over the matching site names
    DECLARE curSites CURSOR FOR
        SELECT h.siteName
        FROM HeritageSite h
        INNER JOIN SiteCountry sc ON h.siteId = sc.siteId
        WHERE sc.countryCode = pCountry AND h.category = pCategory
        ORDER BY h.yearInscribed;

    -- when there are no more rows, set done = 1
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    SET pList  = '';
    SET pCount = 0;

    OPEN curSites;
    readSites: LOOP
        FETCH curSites INTO sName;
        IF done = 1 THEN
            LEAVE readSites;
        END IF;

        SET pCount = pCount + 1;
        IF pList = '' THEN
            SET pList = sName;
        ELSE
            SET pList = CONCAT(pList, '; ', sName);
        END IF;
    END LOOP readSites;
    CLOSE curSites;

    IF pCount = 0 THEN
        SET pList = 'No sites found';
    END IF;
END //

-- ==================================================================
-- 6. PROCEDURE addYearlyStat (TRANSACTION)
--    Adds a new yearly record for a country. The insert is done inside
--    a transaction. If any error happens (bad country code, duplicate
--    year, or the trigger rejects a negative value) the work is rolled
--    back, otherwise it is committed.
--    Example: CALL addYearlyStat('AUS', 2025, 8000000, @r); SELECT @r;
-- ==================================================================
CREATE PROCEDURE addYearlyStat(
    IN  pCountry  CHAR(3),
    IN  pYear     SMALLINT,
    IN  pArrivals BIGINT,
    OUT pResult   VARCHAR(100)
)
    COMMENT 'Insert a yearly record inside a transaction.'
BEGIN
    -- if any SQL error happens: undo the transaction and report it
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET pResult = CONCAT('ROLLBACK: record for ', pCountry, ' ', pYear, ' was NOT added');
    END;

    START TRANSACTION;
        INSERT INTO YearlyStat (countryCode, statYear, arrivals)
        VALUES (pCountry, pYear, pArrivals);
    COMMIT;
    SET pResult = CONCAT('COMMIT: record for ', pCountry, ' ', pYear, ' added');
END //

-- ==================================================================
-- NOTE: the server has binary logging on, so a user can only create
-- triggers with the SUPER privilege (the dsuser account has it) or when
-- log_bin_trust_function_creators = 1. Otherwise CREATE TRIGGER gives ERROR 1419.
-- ==================================================================

-- ==================================================================
-- 7. TRIGGER before_stat_insert (BEFORE INSERT)
--    Business rule: arrival numbers cannot be negative and the year
--    cannot be in the future. Raises a readable error with SIGNAL.
-- ==================================================================
CREATE TRIGGER before_stat_insert
    BEFORE INSERT ON YearlyStat
    FOR EACH ROW
BEGIN
    DECLARE errMsg VARCHAR(150);

    IF NEW.arrivals < 0 THEN
        SET errMsg = CONCAT('Arrivals cannot be negative: ', NEW.arrivals);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errMsg;
    END IF;

    IF NEW.statYear > YEAR(CURDATE()) THEN
        SET errMsg = CONCAT('Year ', NEW.statYear, ' is in the future');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = errMsg;
    END IF;
END //

-- ==================================================================
-- 8. TRIGGER after_stat_update (AFTER UPDATE)
--    When the arrivals value of a record is changed, keep a log row with
--    the old and new value, who changed it and when.
-- ==================================================================
CREATE TRIGGER after_stat_update
    AFTER UPDATE ON YearlyStat
    FOR EACH ROW
BEGIN
    IF NOT (OLD.arrivals <=> NEW.arrivals) THEN   -- <=> is NULL-safe equal
        INSERT INTO StatChangeLog (countryCode, statYear, oldArrivals, newArrivals, changedBy, changedAt)
        VALUES (NEW.countryCode, NEW.statYear, OLD.arrivals, NEW.arrivals, USER(), NOW());
    END IF;
END //

DELIMITER ;

-- ==================================================================
-- TESTS / DEMONSTRATION
-- ==================================================================
SHOW PROCEDURE STATUS WHERE Db = DATABASE();
SHOW TRIGGERS;

-- View: income per tourist for 2019, highest first
SELECT countryName, regionName, arrivals, receiptsUSD, receiptsPerArrival, numHeritageSites
FROM CountrySummary
WHERE statYear = 2019
ORDER BY receiptsPerArrival DESC;

-- Index: EXPLAIN shows that idx_site_name is used
EXPLAIN SELECT siteId, siteName FROM HeritageSite WHERE siteName LIKE 'Great%';

-- Procedure 3
CALL getCountryStats('AUS');

-- Procedure 4: recovery of Japan after COVID, the 2020 drop of Australia, and missing data
CALL arrivalGrowth('JPN', 2019, 2024, @growth, @msg);
SELECT @growth AS growthPct, @msg AS message;
CALL arrivalGrowth('AUS', 2019, 2020, @growth, @msg);
SELECT @growth AS growthPct, @msg AS message;
CALL arrivalGrowth('AUS', 2019, 2023, @growth, @msg);
SELECT @growth AS growthPct, @msg AS message;

-- Procedure 5: Mixed sites of Australia, Natural sites of Egypt, none case
CALL listSitesByCategory('AUS', 'Mixed', @list, @cnt);
SELECT @cnt AS numSites, @list AS sites;
CALL listSitesByCategory('EGY', 'Natural', @list, @cnt);
SELECT @cnt AS numSites, @list AS sites;
CALL listSitesByCategory('THA', 'Mixed', @list, @cnt);
SELECT @cnt AS numSites, @list AS sites;

-- Trigger 7: both inserts are rejected with our own error messages
INSERT INTO YearlyStat (countryCode, statYear, arrivals) VALUES ('AUS', 2025, -100);
INSERT INTO YearlyStat (countryCode, statYear, arrivals) VALUES ('AUS', 2099, 100);

-- Procedure 6 (transaction): first call COMMITs, the second one is a
-- duplicate key so it is ROLLED BACK, the third one is stopped by the trigger
CALL addYearlyStat('AUS', 2025, 8000000, @res);
SELECT @res AS result;
CALL addYearlyStat('AUS', 2025, 8000000, @res);
SELECT @res AS result;
CALL addYearlyStat('JPN', 2025, -1, @res);
SELECT @res AS result;
SELECT * FROM YearlyStat WHERE statYear = 2025;

-- Trigger 8: change arrivals, then look at the log
UPDATE YearlyStat SET arrivals = 8100000 WHERE countryCode = 'AUS' AND statYear = 2025;
SELECT * FROM StatChangeLog;

-- Transactions and triggers (Part 6a): the trigger runs inside the SAME
-- transaction as the UPDATE. After ROLLBACK both the update and the log
-- row written by the trigger are undone.
START TRANSACTION;
UPDATE YearlyStat SET arrivals = 9999999 WHERE countryCode = 'AUS' AND statYear = 2025;
SELECT COUNT(*) AS logRowsInsideTransaction FROM StatChangeLog;
ROLLBACK;
SELECT COUNT(*) AS logRowsAfterRollback FROM StatChangeLog;
SELECT arrivals AS arrivalsAfterRollback FROM YearlyStat WHERE countryCode = 'AUS' AND statYear = 2025;

-- Clean up the demo row so the data stays real (the log keeps its history)
DELETE FROM YearlyStat WHERE countryCode = 'AUS' AND statYear = 2025;
