-- CREATE TABLE scripts for LAPD Crime Data Warehouse
-- Generated: 2026-04-11
-- Purpose: initial DDL to create staging, dimension, fact and supporting tables
-- Notes:
--  - Dimensional modeling: star schema with a FactCrimeIncident fact table
--  - SCD policy: DimArea is implemented as SCD Type-2 (valid_from/valid_to/is_current)
--            Other small lookup dims are modelled as Type-1 (overwrites) by default.
--  - FK constraints are intentionally omitted (or disabled) during initial bulk loads
--    because ETL currently emits sentinel values (-1) for unmatched lookups. Add
--    referential constraints after data quality checks if desired.

SET NOCOUNT ON;

-- ==========================
-- Date dimension (DimDate)
-- date_sk uses YYYYMMDD integer surrogate used by packages and cube
-- ==========================
IF OBJECT_ID('dbo.DimDate') IS NOT NULL DROP TABLE dbo.DimDate;
CREATE TABLE dbo.DimDate (
    date_sk      INT            NOT NULL PRIMARY KEY, -- YYYYMMDD
    full_date    DATE           NOT NULL,
    day_of_month TINYINT        NULL,
    day_of_week  TINYINT        NULL,
    month_num    TINYINT        NULL,
    month_name   NVARCHAR(20)   NULL,
    quarter      TINYINT        NULL,
    year_num     SMALLINT       NULL,
    is_weekend   BIT            NULL,
    fiscal_year  SMALLINT       NULL,
    created_ts   DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME()
);

-- ==========================
-- Area dimension (DimArea) - SCD Type-2
-- Evidence: LoadDimensions.dtsx sets valid_from / valid_to / is_current
-- ==========================
IF OBJECT_ID('dbo.DimArea') IS NOT NULL DROP TABLE dbo.DimArea;
CREATE TABLE dbo.DimArea (
    area_sk      INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    area_id      INT                NULL, -- natural key from source (AREA)
    area_name    NVARCHAR(200)      NULL,
    division     NVARCHAR(100)      NULL,
    valid_from   DATE               NOT NULL DEFAULT('1900-01-01'),
    valid_to     DATE               NOT NULL DEFAULT('9999-12-31'),
    is_current   BIT                NOT NULL DEFAULT(1),
    created_ts   DATETIME2          NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE INDEX IX_DimArea_Natural_Current ON dbo.DimArea(area_id) INCLUDE(is_current);

-- ==========================
-- Crime dimension (DimCrime) - Lookup table (Type-1 by default)
-- Populated from CrimeCategories.xlsx produced by scripts/extract_lapd_lookups.py
-- ==========================
IF OBJECT_ID('dbo.DimCrime') IS NOT NULL DROP TABLE dbo.DimCrime;
CREATE TABLE dbo.DimCrime (
    crime_sk         INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    crime_code       INT                NULL, -- natural code (Crm Cd)
    crime_description NVARCHAR(500)     NULL,
    crime_category   NVARCHAR(100)      NULL,
    crime_group      NVARCHAR(100)      NULL,
    load_ts          DATETIME2          NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE UNIQUE INDEX UQ_DimCrime_Code ON dbo.DimCrime(crime_code) WHERE crime_code IS NOT NULL;

-- ==========================
-- Weapon dimension / lookup (DimWeapon)
-- Populated from WeaponLookup.csv output by the lookup script
-- Use Type-1 (code -> description/type mapping)
-- ==========================
IF OBJECT_ID('dbo.DimWeapon') IS NOT NULL DROP TABLE dbo.DimWeapon;
CREATE TABLE dbo.DimWeapon (
    weapon_sk         INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    weapon_code       INT                NULL,
    weapon_description NVARCHAR(500)     NULL,
    weapon_type       NVARCHAR(100)      NULL,
    load_ts           DATETIME2          NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE UNIQUE INDEX UQ_DimWeapon_Code ON dbo.DimWeapon(weapon_code) WHERE weapon_code IS NOT NULL;

-- ==========================
-- Premise dimension (DimPremise)
-- Small lookup (Premis Cd / Premis Desc) - Type-1
-- ==========================
IF OBJECT_ID('dbo.DimPremise') IS NOT NULL DROP TABLE dbo.DimPremise;
CREATE TABLE dbo.DimPremise (
    premise_sk        INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    premise_code      INT                NULL,
    premise_desc      NVARCHAR(500)      NULL,
    load_ts           DATETIME2          NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE UNIQUE INDEX UQ_DimPremise_Code ON dbo.DimPremise(premise_code) WHERE premise_code IS NOT NULL;

-- ==========================
-- Victim dimension (DimVictim)
-- De-duplicates common victim attributes (age, sex, descent) and provides a surrogate key
-- ==========================
IF OBJECT_ID('dbo.DimVictim') IS NOT NULL DROP TABLE dbo.DimVictim;
CREATE TABLE dbo.DimVictim (
    victim_sk         INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    victim_age        SMALLINT           NULL,
    victim_sex        NVARCHAR(10)       NULL,
    victim_descent    NVARCHAR(50)       NULL,
    load_ts           DATETIME2          NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE UNIQUE INDEX UQ_DimVictim_Natural ON dbo.DimVictim(victim_age, victim_sex, victim_descent);

-- ==========================
-- Staging table - raw CSV layout
-- Column names below are normalized (snake_case) from the CSV headers
-- Map: "DR_NO" -> dr_no, "Date Rptd" -> date_rptd, "DATE OCC" -> date_occ, etc.
-- ==========================
IF OBJECT_ID('dbo.LAPD_Staging') IS NOT NULL DROP TABLE dbo.LAPD_Staging;
CREATE TABLE dbo.LAPD_Staging (
    dr_no            BIGINT          NULL,
    date_rptd        DATE            NULL,
    date_occ         DATE            NULL,
    time_occ         NVARCHAR(20)    NULL,
    area             NVARCHAR(50)    NULL,
    area_name        NVARCHAR(200)   NULL,
    rpt_dist_no      INT             NULL,
    part_1_2         NVARCHAR(50)    NULL,
    crm_cd           INT             NULL,
    crm_cd_desc      NVARCHAR(500)   NULL,
    mocodes          NVARCHAR(500)   NULL,
    vict_age         SMALLINT        NULL,
    vict_sex         NVARCHAR(10)    NULL,
    vict_descent     NVARCHAR(50)    NULL,
    premis_cd        INT             NULL,
    premis_desc      NVARCHAR(500)   NULL,
    weapon_used_cd   INT             NULL,
    weapon_desc      NVARCHAR(500)   NULL,
    status           NVARCHAR(50)    NULL,
    status_desc      NVARCHAR(500)   NULL,
    crm_cd_1         INT             NULL,
    crm_cd_2         INT             NULL,
    crm_cd_3         INT             NULL,
    crm_cd_4         INT             NULL,
    location         NVARCHAR(500)   NULL,
    cross_street     NVARCHAR(500)   NULL,
    lat              DECIMAL(10,7)   NULL,
    lon              DECIMAL(10,7)   NULL,
    load_ts          DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME()
);

-- ==========================
-- Supporting table for accumulating updates (used by LoadAccumulating.dtsx)
-- Contains final completion timestamps per incident (by dr_no).
-- ==========================
IF OBJECT_ID('dbo.AccumulatingUpdates') IS NOT NULL DROP TABLE dbo.AccumulatingUpdates;
CREATE TABLE dbo.AccumulatingUpdates (
    dr_no                  BIGINT      NOT NULL PRIMARY KEY,
    accm_txn_complete_time DATETIME2    NULL,
    updated_ts             DATETIME2    NOT NULL DEFAULT SYSUTCDATETIME()
);

-- ==========================
-- Fact table: FactCrimeIncident
-- Accumulating fact that records events (one row per incident). ETL populates
-- area_sk, crime_sk, premise_sk, victim_sk, weapon_sk using lookups to dims.
-- Note: we intentionally avoid enforcing FK constraints here to allow -1 sentinel
-- values during initial loads; add FKs after QA if desired.
-- ==========================
IF OBJECT_ID('dbo.FactCrimeIncident') IS NOT NULL DROP TABLE dbo.FactCrimeIncident;
CREATE TABLE dbo.FactCrimeIncident (
    fact_id                 INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    dr_no                   BIGINT          NULL,
    date_sk                 INT             NULL,
    area_sk                 INT             NULL,
    crime_sk                INT             NULL,
    premise_sk              INT             NULL,
    victim_sk               INT             NULL,
    weapon_sk               INT             NULL,
    location                NVARCHAR(500)   NULL,
    cross_street            NVARCHAR(500)   NULL,
    latitude                DECIMAL(10,7)   NULL,
    longitude               DECIMAL(10,7)   NULL,
    accm_txn_create_time    DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME(),
    accm_txn_complete_time  DATETIME2        NULL,
    txn_process_time_hours  DECIMAL(8,2)    NULL,
    created_ts              DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE UNIQUE INDEX UQ_FactCrimeIncident_DrNo ON dbo.FactCrimeIncident(dr_no) WHERE dr_no IS NOT NULL;
CREATE INDEX IX_Fact_DateArea ON dbo.FactCrimeIncident(date_sk, area_sk);

-- End of DDL

PRINT 'DDL script created: please review types and adjust nullability/indexes for your environment.';
