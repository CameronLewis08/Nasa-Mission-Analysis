-- ============================================================
-- analysis.sql
-- All queries run against missions_clean
-- Note on Success field:
--   Is_Failure = 0 and Is_Success = 0 means mission is still
--   Operational -- treated as non-failure throughout
-- ============================================================


-- ============================================================
-- SECTION 1: GROUPING / EXPLORATION QUERIES
-- ============================================================

-- Mission identification
WITH Mission_Identification AS (
    SELECT
        Mission,
        Initiative,
        Destination,
        Mission_Type,
        Num_Objectives,
        Success
    FROM missions_clean
)
SELECT * FROM Mission_Identification;


-- Schedule milestones
WITH Schedule_Milestones AS (
    SELECT
        Mission,
        StartY,
        LaunchY,
        Preliminary_Design_Review_Date,
        Critical_Design_Review_Date,
        Launch_Date,
        End_of_Mission,
        Proposed_Design_Schedule_Months,
        Proposed_Mission_Schedule_Yrs,
        Realized_Design_Schedule_Months,
        Calculated_Design_Schedule_Months,
        Realized_Mission_Schedule_Yrs,
        Calculated_Mission_Schedule_Yrs,
        PDR_to_CDR_Days,
        CDR_to_Launch_Days,
        Mission_Duration_Yrs,
        Total_Program_Yrs,
        Schedule_Variance_Months
    FROM missions_clean
)
SELECT * FROM Schedule_Milestones;


-- Cost summary (NSII inflation adjusted only)
WITH Total_Cost_Categories AS (
    SELECT
        Mission,
        Proposed_Cost,
        Realized_Cost,
        Cost_Variance,
        Cost_Variance_Pct,
        Total_Mission_Cost,
        Total_Dev_Cost,
        Total_Launch_Cost,
        Total_Ops_Cost,
        Total_Extension_Cost
    FROM missions_clean
)
SELECT * FROM Total_Cost_Categories;


-- Program management
WITH Program_Management AS (
    SELECT
        Mission,
        Proposed_Cost,
        Realized_Cost,
        Proposed_Design_Schedule_Months,
        Proposed_Mission_Schedule_Yrs,
        Realized_Design_Schedule_Months,
        Calculated_Design_Schedule_Months,
        Realized_Mission_Schedule_Yrs,
        Calculated_Mission_Schedule_Yrs,
        Funding_Date
    FROM missions_clean
)
SELECT * FROM Program_Management;


-- Launch vehicle and mass info
WITH Launch_Vehicle_Info AS (
    SELECT
        Mission,
        Launch_Vehicle,
        Launch_Mass_kg,
        Fuel_Mass_kg
    FROM missions_clean
)
SELECT * FROM Launch_Vehicle_Info;


-- Spacecraft mass breakdown
WITH Spacecraft_Mass_Breakdown AS (
    SELECT
        Mission,
        Dry_Mass_kg,
        Bus_Mass_kg,
        Payload_Mass_kg,
        Lander_Mass_kg,
        Has_AKM,
        Has_Probe,
        Has_Cruise,
        Has_Aeroshield,
        Has_Ballast,
        Has_Lander,
        Complexity_Score
    FROM missions_clean
)
SELECT * FROM Spacecraft_Mass_Breakdown;


-- Instrumentation
WITH Instrumentation AS (
    SELECT
        Mission,
        Num_Instruments,
        Instrument_Mass_kg,
        Instrument_Power_W,
        Num_Deployments
    FROM missions_clean
)
SELECT * FROM Instrumentation;


-- Power systems
WITH Power_Systems AS (
    SELECT
        Mission,
        Bus_Volume_m3,
        Power_Source,
        BOL_Power_W,
        BOM_Power_W,
        BOS_Power_W,
        Solar_Array_Area_m2,
        Solar_Array_Type
    FROM missions_clean
)
SELECT * FROM Power_Systems;


-- Risk and outcome indicators
WITH Risk_Outcome_Indicators AS (
    SELECT
        Mission,
        Success,
        Is_Success,
        Is_Failure,
        Is_Operational,
        Complexity_Score,
        Cost_Variance,
        Cost_Variance_Pct,
        Schedule_Variance_Months,
        Funding_Date
    FROM missions_clean
)
SELECT * FROM Risk_Outcome_Indicators;


-- ============================================================
--     SUMMARY QUERIES FOR EXCEL / POWER BI EXPORT
-- ============================================================

-- Summary by Initiative (Department equivalent)
SELECT
    Initiative,
    COUNT(*)                                        AS Num_Missions,
    ROUND(AVG(Proposed_Cost), 2)                    AS Avg_Budget,
    ROUND(AVG(Realized_Cost), 2)                    AS Avg_Actual_Cost,
    ROUND(AVG(Cost_Variance), 2)                    AS Avg_Cost_Variance,
    ROUND(AVG(Cost_Variance_Pct), 2)                AS Avg_Variance_Pct,
    ROUND(AVG(Complexity_Score), 2)                 AS Avg_Complexity,
    SUM(Is_Success)                                 AS Successes,
    SUM(Is_Failure)                                 AS Failures,
    SUM(Is_Operational)                             AS Still_Operational,
    ROUND(SUM(Is_Failure) / COUNT(*) * 100, 1)      AS Failure_Rate_Pct,
    ROUND((SUM(Is_Success) + SUM(Is_Operational))
        / COUNT(*) * 100, 1)                        AS Non_Failure_Rate_Pct
FROM missions_clean
GROUP BY Initiative
ORDER BY Num_Missions DESC;


-- Summary by Launch Year
SELECT
    LaunchY                                         AS Fiscal_Year,
    COUNT(*)                                        AS Num_Missions,
    ROUND(AVG(Proposed_Cost), 2)                    AS Avg_Budget,
    ROUND(AVG(Realized_Cost), 2)                    AS Avg_Actual_Cost,
    ROUND(AVG(Cost_Variance), 2)                    AS Avg_Cost_Variance,
    ROUND(AVG(Mission_Duration_Yrs), 2)             AS Avg_Duration_Yrs,
    SUM(Is_Success)                                 AS Successes,
    SUM(Is_Failure)                                 AS Failures,
    SUM(Is_Operational)                             AS Still_Operational
FROM missions_clean
GROUP BY LaunchY
ORDER BY LaunchY;


-- Full table check
SELECT * FROM missions_clean;
