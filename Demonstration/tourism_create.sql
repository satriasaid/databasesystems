/* tourism_create.sql
   Name       : Satria Pamungkas
   Student ID : 21522611
   Unit       : Database Systems (ISYS2014/ISYS5008) 2026 S2 - Assignment

   Purpose: creates the database and all tables of the tourism database,
            including primary keys, foreign keys and attribute constraints.
   Run    : mysql> SOURCE tourism_create.sql;
   Order  : 1st script (then tourism_data.sql, tourism_queries.sql,
            tourism_advanced.sql). Running it again rebuilds everything. */

-- ------------------------------------------------------------------
-- Part 2a: create the database <LastName>_<StudentID>
-- ------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS Pamungkas_21522611;
USE Pamungkas_21522611;

-- Drop old tables first, children before parents (because of the FKs)
DROP TABLE IF EXISTS StatChangeLog;
DROP TABLE IF EXISTS SiteCountry;
DROP TABLE IF EXISTS SiteCriteria;
DROP TABLE IF EXISTS HeritageSite;
DROP TABLE IF EXISTS YearlyStat;
DROP TABLE IF EXISTS Country;
DROP TABLE IF EXISTS IncomeGroup;
DROP TABLE IF EXISTS Region;

-- ------------------------------------------------------------------
-- Region: world geographic region (World Bank grouping)
-- ------------------------------------------------------------------
CREATE TABLE Region (
    regionCode CHAR(3)     NOT NULL,
    regionName VARCHAR(60) NOT NULL,
    CONSTRAINT pk_region PRIMARY KEY (regionCode),
    CONSTRAINT uq_region_name UNIQUE (regionName)
);

-- ------------------------------------------------------------------
-- IncomeGroup: World Bank income level of a country
-- ------------------------------------------------------------------
CREATE TABLE IncomeGroup (
    incomeCode CHAR(3)     NOT NULL,
    incomeName VARCHAR(30) NOT NULL,
    CONSTRAINT pk_income PRIMARY KEY (incomeCode),
    CONSTRAINT uq_income_name UNIQUE (incomeName)
);

-- ------------------------------------------------------------------
-- Country: a country we study. Each country belongs to exactly one
-- region and one income group (1:N relationships -> FKs here).
-- ------------------------------------------------------------------
CREATE TABLE Country (
    countryCode CHAR(3)     NOT NULL,   -- ISO 3166 alpha-3, e.g. AUS
    iso2Code    CHAR(2)     NOT NULL,   -- ISO 3166 alpha-2, e.g. AU
    countryName VARCHAR(50) NOT NULL,
    capitalCity VARCHAR(50),
    regionCode  CHAR(3)     NOT NULL,   -- total participation in 'belongs_to'
    incomeCode  CHAR(3)     NOT NULL,   -- total participation in 'classified_as'
    CONSTRAINT pk_country PRIMARY KEY (countryCode),
    CONSTRAINT uq_country_iso2 UNIQUE (iso2Code),
    CONSTRAINT fk_country_region FOREIGN KEY (regionCode)
        REFERENCES Region(regionCode) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_country_income FOREIGN KEY (incomeCode)
        REFERENCES IncomeGroup(incomeCode) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ------------------------------------------------------------------
-- YearlyStat: WEAK entity. One row per country per year.
-- Primary key = owner key (countryCode) + partial key (statYear).
-- If a country is deleted its yearly statistics are deleted too.
-- ------------------------------------------------------------------
CREATE TABLE YearlyStat (
    countryCode    CHAR(3)  NOT NULL,
    statYear       SMALLINT NOT NULL,
    arrivals       BIGINT,             -- international inbound tourists
    departures     BIGINT,             -- residents travelling abroad
    receiptsUSD    BIGINT,             -- international tourism income, current US$
    expenditureUSD BIGINT,             -- international tourism spending, current US$
    CONSTRAINT pk_yearlystat PRIMARY KEY (countryCode, statYear),
    CONSTRAINT fk_yearlystat_country FOREIGN KEY (countryCode)
        REFERENCES Country(countryCode) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_stat_year CHECK (statYear BETWEEN 1990 AND 2100),
    CONSTRAINT chk_stat_values CHECK (arrivals >= 0 AND departures >= 0
                                      AND receiptsUSD >= 0 AND expenditureUSD >= 0)
);

-- ------------------------------------------------------------------
-- HeritageSite: UNESCO World Heritage site (tourist attraction).
-- location is a composite attribute -> stored as latitude + longitude.
-- ------------------------------------------------------------------
CREATE TABLE HeritageSite (
    siteId        INT           NOT NULL,   -- UNESCO id_no
    siteName      VARCHAR(200)  NOT NULL,
    category      VARCHAR(10)   NOT NULL,
    yearInscribed SMALLINT      NOT NULL,
    areaHectares  DECIMAL(12,2),
    inDanger      CHAR(1)       NOT NULL DEFAULT 'N',
    latitude      DECIMAL(9,6),
    longitude     DECIMAL(9,6),
    CONSTRAINT pk_site PRIMARY KEY (siteId),
    CONSTRAINT chk_site_category CHECK (category IN ('Cultural', 'Natural', 'Mixed')),
    CONSTRAINT chk_site_year CHECK (yearInscribed >= 1978),   -- first sites were listed in 1978
    CONSTRAINT chk_site_danger CHECK (inDanger IN ('Y', 'N')),
    CONSTRAINT chk_site_area CHECK (areaHectares >= 0),
    CONSTRAINT chk_site_lat CHECK (latitude BETWEEN -90 AND 90),
    CONSTRAINT chk_site_lon CHECK (longitude BETWEEN -180 AND 180)
);

-- ------------------------------------------------------------------
-- SiteCriteria: the multivalued attribute 'criteria' of HeritageSite
-- (a site can meet several UNESCO criteria i..x) -> separate table.
-- ------------------------------------------------------------------
CREATE TABLE SiteCriteria (
    siteId    INT        NOT NULL,
    criterion VARCHAR(4) NOT NULL,   -- roman numeral i .. x
    CONSTRAINT pk_sitecriteria PRIMARY KEY (siteId, criterion),
    CONSTRAINT fk_sitecriteria_site FOREIGN KEY (siteId)
        REFERENCES HeritageSite(siteId) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_criterion CHECK (criterion IN
        ('i', 'ii', 'iii', 'iv', 'v', 'vi', 'vii', 'viii', 'ix', 'x'))
);

-- ------------------------------------------------------------------
-- SiteCountry: M:N relationship 'located_in' between HeritageSite and
-- Country (a transboundary site is located in more than one country).
-- ------------------------------------------------------------------
CREATE TABLE SiteCountry (
    siteId      INT     NOT NULL,
    countryCode CHAR(3) NOT NULL,
    CONSTRAINT pk_sitecountry PRIMARY KEY (siteId, countryCode),
    CONSTRAINT fk_sitecountry_site FOREIGN KEY (siteId)
        REFERENCES HeritageSite(siteId) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_sitecountry_country FOREIGN KEY (countryCode)
        REFERENCES Country(countryCode) ON UPDATE CASCADE ON DELETE CASCADE
);

-- Show the result
SHOW TABLES;
