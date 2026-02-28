-- ============================================================
-- cost_profiles.sql
-- Three query sets based on missions_clean schema:
--   1. Historical cost profile (by year and category)
--   2. Out-year budget projection (3-5 years)
--   3. Scenario + variance view (plan vs actual + what-if)
-- ============================================================


-- ============================================================
-- PART 1: HISTORICAL COST PROFILE
-- Breaks down spending by launch year and cost category
-- Uses NSII inflation-adjusted costs for fair cross-year comparison
-- ============================================================

-- 1A: Cost by category per launch year
-- Shows how the mix of dev/launch/ops/extension spending
-- has shifted across decades of NASA missions
SELECT
    LaunchY                                         AS Launch_Year,
    COUNT(*)                                        AS Num_Missions,
    ROUND(SUM(Total_Dev_Cost), 2)                   AS Total_Dev_Cost,
    ROUND(SUM(Total_Launch_Cost), 2)                AS Total_Launch_Cost,
    ROUND(SUM(Total_Ops_Cost), 2)                   AS Total_Ops_Cost,
    ROUND(SUM(Total_Extension_Cost), 2)             AS Total_Extension_Cost,
    ROUND(SUM(Total_Mission_Cost), 2)               AS Total_Mission_Cost,
    -- Cost category share percentages
    ROUND(SUM(Total_Dev_Cost)
        / NULLIF(SUM(Total_Mission_Cost), 0) * 100, 1)       AS Dev_Cost_Share_Pct,
    ROUND(SUM(Total_Launch_Cost)
        / NULLIF(SUM(Total_Mission_Cost), 0) * 100, 1)       AS Launch_Cost_Share_Pct,
    ROUND(SUM(Total_Ops_Cost)
        / NULLIF(SUM(Total_Mission_Cost), 0) * 100, 1)       AS Ops_Cost_Share_Pct,
    ROUND(SUM(Total_Extension_Cost)
        / NULLIF(SUM(Total_Mission_Cost), 0) * 100, 1)       AS Extension_Cost_Share_Pct
FROM missions_clean
WHERE LaunchY IS NOT NULL
  AND Total_Mission_Cost IS NOT NULL
GROUP BY LaunchY
ORDER BY LaunchY;


-- 1B: Historical cost profile by mission type
-- Reveals which mission types are most expensive per category
SELECT
    Mission_Type,
    COUNT(*)                                        AS Num_Missions,
    ROUND(AVG(Total_Dev_Cost), 2)                   AS Avg_Dev_Cost,
    ROUND(AVG(Total_Launch_Cost), 2)                AS Avg_Launch_Cost,
    ROUND(AVG(Total_Ops_Cost), 2)                   AS Avg_Ops_Cost,
    ROUND(AVG(Total_Extension_Cost), 2)             AS Avg_Extension_Cost,
    ROUND(AVG(Total_Mission_Cost), 2)               AS Avg_Total_Cost,
    ROUND(MIN(Total_Mission_Cost), 2)               AS Min_Mission_Cost,
    ROUND(MAX(Total_Mission_Cost), 2)               AS Max_Mission_Cost
FROM missions_clean
WHERE Mission_Type IS NOT NULL
  AND Total_Mission_Cost IS NOT NULL
GROUP BY Mission_Type
ORDER BY Avg_Total_Cost DESC;


-- 1C: Historical cost profile by destination
-- Useful for understanding how destination drives cost category mix
SELECT
    Destination,
    COUNT(*)                                        AS Num_Missions,
    ROUND(AVG(Total_Dev_Cost), 2)                   AS Avg_Dev_Cost,
    ROUND(AVG(Total_Launch_Cost), 2)                AS Avg_Launch_Cost,
    ROUND(AVG(Total_Ops_Cost), 2)                   AS Avg_Ops_Cost,
    ROUND(AVG(Total_Extension_Cost), 2)             AS Avg_Extension_Cost,
    ROUND(AVG(Total_Mission_Cost), 2)               AS Avg_Total_Cost,
    -- Average duration helps contextualize ops and extension costs
    ROUND(AVG(Mission_Duration_Yrs), 2)             AS Avg_Mission_Duration_Yrs,
    -- Cost per year of mission operation
    ROUND(AVG(Total_Ops_Cost)
        / NULLIF(AVG(Mission_Duration_Yrs), 0), 2)  AS Avg_Annual_Ops_Cost
FROM missions_clean
WHERE Destination IS NOT NULL
  AND Total_Mission_Cost IS NOT NULL
GROUP BY Destination
ORDER BY Avg_Total_Cost DESC;


-- 1D: Per mission cost profile with era classification
-- Classifies missions into decades for trend analysis
SELECT
    Mission,
    Initiative,
    Destination,
    Mission_Type,
    LaunchY,
    CASE
        WHEN LaunchY < 2000 THEN '1990s'
        WHEN LaunchY < 2010 THEN '2000s'
        WHEN LaunchY < 2020 THEN '2010s'
        ELSE                     '2020s'
    END                                             AS Mission_Era,
    Proposed_Cost,
    Realized_Cost,
    Total_Dev_Cost,
    Total_Launch_Cost,
    Total_Ops_Cost,
    Total_Extension_Cost,
    Total_Mission_Cost,
    Cost_Variance_Pct,
    Mission_Duration_Yrs
FROM missions_clean
WHERE Total_Mission_Cost IS NOT NULL
ORDER BY LaunchY;


-- ============================================================
-- PART 2: OUT-YEAR BUDGET PROJECTION (3-5 YEARS)
-- Projects future mission costs based on historical averages
-- Uses LaunchY to simulate a rolling forward-looking budget
-- Baseline year is set to the most recent launch year in the data
-- ============================================================

-- 2A: Establish cost baselines by mission type
-- These averages become the foundation for projections
WITH Cost_Baselines AS (
    SELECT
        Mission_Type,
        COUNT(*)                                        AS Historical_Missions,
        ROUND(AVG(Total_Dev_Cost), 2)                   AS Avg_Dev_Cost,
        ROUND(AVG(Total_Launch_Cost), 2)                AS Avg_Launch_Cost,
        ROUND(AVG(Total_Ops_Cost), 2)                   AS Avg_Ops_Cost,
        ROUND(AVG(Total_Extension_Cost), 2)             AS Avg_Extension_Cost,
        ROUND(AVG(Total_Mission_Cost), 2)               AS Avg_Total_Cost,
        -- Cost growth rate: average % variance as a proxy for year-over-year inflation
        ROUND(AVG(Cost_Variance_Pct), 2)                AS Avg_Historical_Overrun_Pct
    FROM missions_clean
    WHERE Total_Mission_Cost IS NOT NULL
      AND Mission_Type IS NOT NULL
    GROUP BY Mission_Type
)
SELECT * FROM Cost_Baselines
ORDER BY Avg_Total_Cost DESC;


-- 2B: Out-year projection (Year +1 through +5)
-- Projects budget requirements for each mission type
-- Applies a 3% annual cost escalation (NASA historical average)
-- and adds the historical overrun rate as a risk buffer
WITH Cost_Baselines AS (
    SELECT
        Mission_Type,
        ROUND(AVG(Total_Dev_Cost), 2)                   AS Avg_Dev_Cost,
        ROUND(AVG(Total_Launch_Cost), 2)                AS Avg_Launch_Cost,
        ROUND(AVG(Total_Ops_Cost), 2)                   AS Avg_Ops_Cost,
        ROUND(AVG(Total_Mission_Cost), 2)               AS Avg_Total_Cost,
        ROUND(AVG(Cost_Variance_Pct) / 100, 4)          AS Overrun_Rate
    FROM missions_clean
    WHERE Total_Mission_Cost IS NOT NULL
      AND Mission_Type IS NOT NULL
    GROUP BY Mission_Type
),
Projection_Years AS (
    -- Generates Year +1 through +5 rows per mission type
    SELECT Mission_Type, Avg_Dev_Cost, Avg_Launch_Cost,
           Avg_Ops_Cost, Avg_Total_Cost, Overrun_Rate,
           1 AS Projection_Year
    FROM Cost_Baselines
    UNION ALL
    SELECT Mission_Type, Avg_Dev_Cost, Avg_Launch_Cost,
           Avg_Ops_Cost, Avg_Total_Cost, Overrun_Rate,
           2 FROM Cost_Baselines
    UNION ALL
    SELECT Mission_Type, Avg_Dev_Cost, Avg_Launch_Cost,
           Avg_Ops_Cost, Avg_Total_Cost, Overrun_Rate,
           3 FROM Cost_Baselines
    UNION ALL
    SELECT Mission_Type, Avg_Dev_Cost, Avg_Launch_Cost,
           Avg_Ops_Cost, Avg_Total_Cost, Overrun_Rate,
           4 FROM Cost_Baselines
    UNION ALL
    SELECT Mission_Type, Avg_Dev_Cost, Avg_Launch_Cost,
           Avg_Ops_Cost, Avg_Total_Cost, Overrun_Rate,
           5 FROM Cost_Baselines
)
SELECT
    Mission_Type,
    Projection_Year                                 AS Years_Out,
    -- Base projection with 3% annual escalation
    ROUND(Avg_Total_Cost
        * POW(1.03, Projection_Year), 2)            AS Base_Projection,
    -- Conservative estimate adds historical overrun rate on top
    ROUND(Avg_Total_Cost
        * POW(1.03, Projection_Year)
        * (1 + GREATEST(Overrun_Rate, 0)), 2)       AS Risk_Adjusted_Projection,
    -- Dev and ops cost projections separately
    ROUND(Avg_Dev_Cost
        * POW(1.03, Projection_Year), 2)            AS Projected_Dev_Cost,
    ROUND(Avg_Ops_Cost
        * POW(1.03, Projection_Year), 2)            AS Projected_Ops_Cost,
    ROUND(Overrun_Rate * 100, 2)                    AS Historical_Overrun_Pct
FROM Projection_Years
ORDER BY Mission_Type, Projection_Year;


-- 2C: Portfolio-level out-year projection
-- Total projected spend across all mission types per year
WITH Cost_Baselines AS (
    SELECT
        Mission_Type,
        COUNT(*)                                        AS Avg_Missions_Per_Era,
        ROUND(AVG(Total_Mission_Cost), 2)               AS Avg_Total_Cost,
        ROUND(AVG(Cost_Variance_Pct) / 100, 4)          AS Overrun_Rate
    FROM missions_clean
    WHERE Total_Mission_Cost IS NOT NULL
    GROUP BY Mission_Type
),
Portfolio_Base AS (
    SELECT
        SUM(Avg_Total_Cost)                             AS Portfolio_Baseline,
        SUM(Avg_Total_Cost * GREATEST(Overrun_Rate, 0)) AS Risk_Buffer
    FROM Cost_Baselines
)
SELECT
    yr.Projection_Year                              AS Years_Out,
    ROUND(p.Portfolio_Baseline
        * POW(1.03, yr.Projection_Year), 2)         AS Base_Portfolio_Projection,
    ROUND((p.Portfolio_Baseline + p.Risk_Buffer)
        * POW(1.03, yr.Projection_Year), 2)         AS Risk_Adjusted_Portfolio,
    ROUND(p.Risk_Buffer
        * POW(1.03, yr.Projection_Year), 2)         AS Risk_Buffer_Amount
FROM Portfolio_Base p
JOIN (
    SELECT 1 AS Projection_Year UNION ALL
    SELECT 2 UNION ALL
    SELECT 3 UNION ALL
    SELECT 4 UNION ALL
    SELECT 5
) yr ON 1=1
ORDER BY yr.Projection_Year;


-- ============================================================
-- PART 3: SCENARIO + VARIANCE VIEW (PLAN VS ACTUAL + WHAT-IF)
-- ============================================================

-- 3A: Plan vs actual variance per mission
-- Core budget performance view
SELECT
    Mission,
    Initiative,
    Destination,
    Mission_Type,
    LaunchY,
    Proposed_Cost                                   AS Planned_Budget,
    Realized_Cost                                   AS Actual_Cost,
    Cost_Variance                                   AS Variance_Amount,
    Cost_Variance_Pct                               AS Variance_Pct,
    CASE
        WHEN Cost_Variance_Pct > 50     THEN '5 - Critical Overrun  (>50%)'
        WHEN Cost_Variance_Pct > 20     THEN '4 - Major Overrun     (20-50%)'
        WHEN Cost_Variance_Pct > 0      THEN '3 - Minor Overrun     (0-20%)'
        WHEN Cost_Variance_Pct = 0      THEN '2 - On Budget'
        ELSE                                 '1 - Under Budget'
    END                                             AS Variance_Category,
    -- Schedule context alongside cost variance
    Schedule_Variance_Months,
    CASE
        WHEN Schedule_Variance_Months > 12  THEN 'Significantly Delayed'
        WHEN Schedule_Variance_Months > 0   THEN 'Slightly Delayed'
        WHEN Schedule_Variance_Months = 0   THEN 'On Schedule'
        ELSE                                     'Ahead of Schedule'
    END                                             AS Schedule_Status,
    Success,
    Complexity_Score
FROM missions_clean
WHERE Proposed_Cost IS NOT NULL
  AND Realized_Cost IS NOT NULL
ORDER BY Cost_Variance_Pct DESC;


-- 3B: Variance summary by category
-- Shows which variance bands contain the most missions
-- and their average cost and schedule behavior
SELECT
    CASE
        WHEN Cost_Variance_Pct > 50     THEN '5 - Critical Overrun  (>50%)'
        WHEN Cost_Variance_Pct > 20     THEN '4 - Major Overrun     (20-50%)'
        WHEN Cost_Variance_Pct > 0      THEN '3 - Minor Overrun     (0-20%)'
        WHEN Cost_Variance_Pct = 0      THEN '2 - On Budget'
        ELSE                                 '1 - Under Budget'
    END                                             AS Variance_Category,
    COUNT(*)                                        AS Num_Missions,
    SUM(Is_Success)                                 AS Successes,
    SUM(Is_Failure)                                 AS Failures,
    SUM(Is_Operational)                             AS Still_Operational,
    ROUND(AVG(Cost_Variance_Pct), 2)                AS Avg_Variance_Pct,
    ROUND(AVG(Schedule_Variance_Months), 2)         AS Avg_Schedule_Variance_Months,
    ROUND(AVG(Complexity_Score), 2)                 AS Avg_Complexity_Score,
    ROUND(AVG(Mission_Duration_Yrs), 2)             AS Avg_Mission_Duration_Yrs
FROM missions_clean
WHERE Proposed_Cost IS NOT NULL
  AND Realized_Cost IS NOT NULL
GROUP BY Variance_Category
ORDER BY Variance_Category;


-- 3C: What-if scenario model
-- Applies adjustable multipliers to simulate different budget scenarios
-- Adjust the multiplier values in the CASE blocks to model scenarios:
--   Optimistic  = costs come in 10% under historical average overrun
--   Base        = costs follow historical average overrun exactly
--   Pessimistic = costs come in 20% above historical average overrun
WITH Mission_Scenarios AS (
    SELECT
        Mission,
        Initiative,
        Destination,
        Mission_Type,
        LaunchY,
        Proposed_Cost,
        Realized_Cost,
        Cost_Variance_Pct,
        -- Historical overrun rate per mission type as a decimal
        AVG(Cost_Variance_Pct) OVER (
            PARTITION BY Mission_Type
        ) / 100                                     AS Type_Avg_Overrun_Rate
    FROM missions_clean
    WHERE Proposed_Cost IS NOT NULL
)
SELECT
    Mission,
    Initiative,
    Mission_Type,
    LaunchY,
    Proposed_Cost                                   AS Original_Budget,
    Realized_Cost                                   AS Actual_Cost,
    Cost_Variance_Pct                               AS Actual_Variance_Pct,

    -- Optimistic scenario: 50% of historical overrun rate
    ROUND(Proposed_Cost
        * (1 + (Type_Avg_Overrun_Rate * 0.50)), 2)  AS Optimistic_Scenario,

    -- Base scenario: matches historical overrun rate exactly
    ROUND(Proposed_Cost
        * (1 + Type_Avg_Overrun_Rate), 2)           AS Base_Scenario,

    -- Pessimistic scenario: 150% of historical overrun rate
    ROUND(Proposed_Cost
        * (1 + (Type_Avg_Overrun_Rate * 1.50)), 2)  AS Pessimistic_Scenario,

    -- Dollar difference between scenarios
    ROUND(Proposed_Cost
        * (1 + (Type_Avg_Overrun_Rate * 1.50))
        - Proposed_Cost
        * (1 + (Type_Avg_Overrun_Rate * 0.50)), 2)  AS Scenario_Range,

    ROUND(Type_Avg_Overrun_Rate * 100, 2)           AS Type_Historical_Overrun_Pct
FROM Mission_Scenarios
ORDER BY Proposed_Cost DESC;


-- 3D: What-if scenario summary by mission type + portfolio total
-- Matrix format: mission types as rows, three scenarios as columns
-- Designed for grouped bar chart in Excel
WITH Mission_Scenarios AS (
    SELECT
        Mission_Type,
        Proposed_Cost,
        Realized_Cost,
        AVG(Cost_Variance_Pct) OVER (
            PARTITION BY Mission_Type
        ) / 100                                     AS Type_Avg_Overrun_Rate,
        COUNT(*) OVER (
            PARTITION BY Mission_Type
        )                                           AS Type_Mission_Count
    FROM missions_clean
    WHERE Proposed_Cost IS NOT NULL
),
Type_Summary AS (
    SELECT
        Mission_Type                                AS Row_Label,
        Type_Mission_Count                          AS Num_Missions,
        ROUND(SUM(Proposed_Cost), 2)                AS Total_Original_Budget,
        -- Optimistic: 50% of historical overrun rate
        ROUND(SUM(Proposed_Cost
            * (1 + (Type_Avg_Overrun_Rate * 0.50))), 2) AS Optimistic_Projected,
        ROUND(SUM(Proposed_Cost
            * (Type_Avg_Overrun_Rate * 0.50)), 2)   AS Optimistic_Exposure,
        -- Base: matches historical overrun exactly
        ROUND(SUM(Proposed_Cost
            * (1 + Type_Avg_Overrun_Rate)), 2)      AS Base_Projected,
        ROUND(SUM(Proposed_Cost
            * Type_Avg_Overrun_Rate), 2)            AS Base_Exposure,
        -- Pessimistic: 150% of historical overrun rate
        ROUND(SUM(Proposed_Cost
            * (1 + (Type_Avg_Overrun_Rate * 1.50))), 2) AS Pessimistic_Projected,
        ROUND(SUM(Proposed_Cost
            * (Type_Avg_Overrun_Rate * 1.50)), 2)   AS Pessimistic_Exposure,
        -- Scenario spread: difference between best and worst case
        ROUND(SUM(Proposed_Cost
            * (1 + (Type_Avg_Overrun_Rate * 1.50)))
            - SUM(Proposed_Cost
            * (1 + (Type_Avg_Overrun_Rate * 0.50))), 2) AS Scenario_Range,
        ROUND(AVG(Type_Avg_Overrun_Rate) * 100, 2)  AS Historical_Overrun_Pct,
        1                                           AS Sort_Order
    FROM Mission_Scenarios
    GROUP BY Mission_Type, Type_Mission_Count, Type_Avg_Overrun_Rate
)
-- Mission type rows
SELECT * FROM Type_Summary

UNION ALL

-- Portfolio total row at the bottom
SELECT
    'TOTAL PORTFOLIO'                              AS Row_Label,
    COUNT(*)                                        AS Num_Missions,
    ROUND(SUM(Proposed_Cost), 2)                    AS Total_Original_Budget,
    ROUND(SUM(Proposed_Cost
        * (1 + (Type_Avg_Overrun_Rate * 0.50))), 2) AS Optimistic_Projected,
    ROUND(SUM(Proposed_Cost
        * (Type_Avg_Overrun_Rate * 0.50)), 2)       AS Optimistic_Exposure,
    ROUND(SUM(Proposed_Cost
        * (1 + Type_Avg_Overrun_Rate)), 2)          AS Base_Projected,
    ROUND(SUM(Proposed_Cost
        * Type_Avg_Overrun_Rate), 2)                AS Base_Exposure,
    ROUND(SUM(Proposed_Cost
        * (1 + (Type_Avg_Overrun_Rate * 1.50))), 2) AS Pessimistic_Projected,
    ROUND(SUM(Proposed_Cost
        * (Type_Avg_Overrun_Rate * 1.50)), 2)       AS Pessimistic_Exposure,
    ROUND(SUM(Proposed_Cost
        * (1 + (Type_Avg_Overrun_Rate * 1.50)))
        - SUM(Proposed_Cost
        * (1 + (Type_Avg_Overrun_Rate * 0.50))), 2) AS Scenario_Range,
    ROUND(AVG(Type_Avg_Overrun_Rate) * 100, 2)      AS Historical_Overrun_Pct,
    2                                               AS Sort_Order
FROM Mission_Scenarios

ORDER BY Sort_Order, Total_Original_Budget DESC;
