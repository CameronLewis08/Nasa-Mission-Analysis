-- ============================================================
-- views.sql
-- VIEW 1: vw_cost          -- cost performance and budget analysis
-- VIEW 2: vw_cost_risk     -- cost risk combining financial and
--                             complexity/failure indicators
-- ============================================================


-- ------------------------------------------------------------
-- VIEW 1: COST VIEW
-- Full cost profile per mission including phase breakdown,
-- budget performance, schedule context, and era classification
-- Designed to feed Excel budget tab and Power BI cost visuals
-- ------------------------------------------------------------
DROP VIEW IF EXISTS vw_cost;

CREATE VIEW vw_cost AS
SELECT
    -- Identifiers
    Mission,
    Initiative,
    Destination,
    Mission_Type,
    LaunchY                                         AS Fiscal_Year,
    CASE
        WHEN LaunchY < 2000 THEN '1990s'
        WHEN LaunchY < 2010 THEN '2000s'
        WHEN LaunchY < 2020 THEN '2010s'
        ELSE                     '2020s'
    END                                             AS Mission_Era,

    -- Budget vs actual
    Proposed_Cost                                   AS Budget_Amount,
    Realized_Cost                                   AS Actual_Cost,
    Cost_Variance,
    Cost_Variance_Pct,
    CASE
        WHEN Cost_Variance_Pct > 50     THEN '5 - Critical Overrun  (>50%)'
        WHEN Cost_Variance_Pct > 20     THEN '4 - Major Overrun     (20-50%)'
        WHEN Cost_Variance_Pct > 0      THEN '3 - Minor Overrun     (0-20%)'
        WHEN Cost_Variance_Pct = 0      THEN '2 - On Budget'
        ELSE                                 '1 - Under Budget'
    END                                             AS Budget_Status,

    -- Cost phase breakdown (NSII inflation adjusted)
    Total_Mission_Cost,
    Total_Dev_Cost,
    Total_Launch_Cost,
    Total_Ops_Cost,
    Total_Extension_Cost,

    -- Cost share percentages per phase
    ROUND(Total_Dev_Cost
        / NULLIF(Total_Mission_Cost, 0) * 100, 1)   AS Dev_Cost_Share_Pct,
    ROUND(Total_Launch_Cost
        / NULLIF(Total_Mission_Cost, 0) * 100, 1)   AS Launch_Cost_Share_Pct,
    ROUND(Total_Ops_Cost
        / NULLIF(Total_Mission_Cost, 0) * 100, 1)   AS Ops_Cost_Share_Pct,
    ROUND(Total_Extension_Cost
        / NULLIF(Total_Mission_Cost, 0) * 100, 1)   AS Extension_Cost_Share_Pct,

    -- Annual ops cost rate
    ROUND(Total_Ops_Cost
        / NULLIF(Mission_Duration_Yrs, 0), 2)       AS Annual_Ops_Cost,

    -- Schedule context
    Mission_Duration_Yrs,
    Total_Program_Yrs,
    Schedule_Variance_Months,
    CASE
        WHEN Schedule_Variance_Months > 12  THEN 'Significantly Delayed'
        WHEN Schedule_Variance_Months > 0   THEN 'Slightly Delayed'
        WHEN Schedule_Variance_Months = 0   THEN 'On Schedule'
        ELSE                                     'Ahead of Schedule'
    END                                             AS Schedule_Status,

    -- Outcome
    Success,
    Is_Success,
    Is_Failure,
    Is_Operational

FROM missions_clean
WHERE Proposed_Cost IS NOT NULL
   OR Realized_Cost IS NOT NULL;

select * from vw_cost;
-- ------------------------------------------------------------
-- VIEW 2: COST RISK VIEW
-- Combines cost overrun performance with mission complexity,
-- mass, power, and failure indicators to surface what
-- drives budget risk
-- Designed to feed Power BI risk dashboard and Excel risk tab
-- ------------------------------------------------------------
DROP VIEW IF EXISTS vw_cost_risk;

CREATE VIEW vw_cost_risk AS
SELECT
    -- Identifiers
    Mission,
    Initiative,
    Destination,
    Mission_Type,
    Launch_Vehicle,
    LaunchY                                         AS Fiscal_Year,

    -- Outcome
    Success,
    Is_Success,
    Is_Failure,
    Is_Operational,

    -- Cost risk indicators
    Proposed_Cost                                   AS Budget_Amount,
    Realized_Cost                                   AS Actual_Cost,
    Cost_Variance,
    Cost_Variance_Pct,
    CASE
        WHEN Cost_Variance_Pct > 50     THEN '5 - Critical Overrun  (>50%)'
        WHEN Cost_Variance_Pct > 20     THEN '4 - Major Overrun     (20-50%)'
        WHEN Cost_Variance_Pct > 0      THEN '3 - Minor Overrun     (0-20%)'
        WHEN Cost_Variance_Pct = 0      THEN '2 - On Budget'
        ELSE                                 '1 - Under Budget'
    END                                             AS Budget_Status,

    -- Schedule risk indicators
    Schedule_Variance_Months,
    CASE
        WHEN Schedule_Variance_Months > 12  THEN 'Significantly Delayed'
        WHEN Schedule_Variance_Months > 0   THEN 'Slightly Delayed'
        WHEN Schedule_Variance_Months = 0   THEN 'On Schedule'
        ELSE                                     'Ahead of Schedule'
    END                                             AS Schedule_Status,
    PDR_to_CDR_Days,
    CDR_to_Launch_Days,

    -- Complexity risk indicators
    Complexity_Score,
    Has_AKM,
    Has_Probe,
    Has_Cruise,
    Has_Aeroshield,
    Has_Ballast,
    Has_Lander,
    Num_Deployments,
    Num_Instruments,
    Num_Objectives,

    -- Mass risk indicators
    Launch_Mass_kg,
    Dry_Mass_kg,
    Fuel_Mass_kg,
    Instrument_Mass_kg,
    ROUND(Fuel_Mass_kg
        / NULLIF(Launch_Mass_kg, 0) * 100, 2)       AS Fuel_Fraction_Pct,
    ROUND(Instrument_Mass_kg
        / NULLIF(Dry_Mass_kg, 0) * 100, 2)          AS Instrument_Mass_Fraction_Pct,

    -- Power risk indicators
    Power_Source,
    BOL_Power_W,
    BOM_Power_W,
    Instrument_Power_W,
    ROUND((BOL_Power_W - BOM_Power_W)
        / NULLIF(BOL_Power_W, 0) * 100, 2)          AS Power_Degradation_Pct,
    ROUND(Instrument_Power_W
        / NULLIF(BOM_Power_W, 0) * 100, 2)          AS Instrument_Power_Fraction_Pct,

    -- Composite risk score
    -- Combines complexity, cost overrun severity, and schedule delay
    -- into a single 0-10 index for easy sorting and filtering
    ROUND(
        (Complexity_Score / 6.0 * 4)                -- complexity worth up to 4 points
        + (CASE
            WHEN Cost_Variance_Pct > 50  THEN 3
            WHEN Cost_Variance_Pct > 20  THEN 2
            WHEN Cost_Variance_Pct > 0   THEN 1
            ELSE 0
           END)                                     -- cost overrun worth up to 3 points
        + (CASE
            WHEN Schedule_Variance_Months > 24 THEN 3
            WHEN Schedule_Variance_Months > 12 THEN 2
            WHEN Schedule_Variance_Months > 0  THEN 1
            ELSE 0
           END)                                     -- schedule delay worth up to 3 points
    , 2)                                            AS Composite_Risk_Score,

    Mission_Duration_Yrs

FROM missions_clean;

select * from vw_cost_risk;