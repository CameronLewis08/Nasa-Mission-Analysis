-- ============================================================
-- SECTION 4: RISK ANALYSIS
-- Operational missions counted as non-failures throughout
-- ============================================================

-- Success rate by mission type
SELECT
    Mission_Type,
    COUNT(*)                                        AS Num_Missions,
    SUM(Is_Success)                                 AS Successes,
    SUM(Is_Failure)                                 AS Failures,
    SUM(Is_Operational)                             AS Still_Operational,
    ROUND(SUM(Is_Failure) / COUNT(*) * 100, 1)      AS Failure_Rate_Pct,
    ROUND((SUM(Is_Success) + SUM(Is_Operational))
        / COUNT(*) * 100, 1)                        AS Non_Failure_Rate_Pct
FROM missions_clean
GROUP BY Mission_Type
ORDER BY Failure_Rate_Pct DESC;


-- Risk breakdown by complexity score
SELECT
    Complexity_Score,
    COUNT(*)                                        AS Num_Missions,
    SUM(Is_Success)                                 AS Successes,
    SUM(Is_Failure)                                 AS Failures,
    SUM(Is_Operational)                             AS Still_Operational,
    ROUND(SUM(Is_Failure) / COUNT(*) * 100, 1)      AS Failure_Rate_Pct,
    ROUND((SUM(Is_Success) + SUM(Is_Operational))
        / COUNT(*) * 100, 1)                        AS Non_Failure_Rate_Pct,
    ROUND(AVG(Cost_Variance_Pct), 2)                AS Avg_Cost_Overrun_Pct,
    ROUND(AVG(Schedule_Variance_Months), 2)         AS Avg_Schedule_Overrun_Months
FROM missions_clean
GROUP BY Complexity_Score
ORDER BY Complexity_Score;


-- Success rate by destination
SELECT
    Destination,
    COUNT(*)                                        AS Num_Missions,
    SUM(Is_Success)                                 AS Successes,
    SUM(Is_Failure)                                 AS Failures,
    SUM(Is_Operational)                             AS Still_Operational,
    ROUND(SUM(Is_Failure) / COUNT(*) * 100, 1)      AS Failure_Rate_Pct,
    ROUND((SUM(Is_Success) + SUM(Is_Operational))
        / COUNT(*) * 100, 1)                        AS Non_Failure_Rate_Pct,
    ROUND(AVG(Complexity_Score), 2)                 AS Avg_Complexity
FROM missions_clean
GROUP BY Destination
ORDER BY Failure_Rate_Pct DESC;


-- Individual mission risk profile
SELECT
    Mission,
    Initiative,
    Destination,
    Mission_Type,
    Success,
    Complexity_Score,
    Has_AKM,
    Has_Probe,
    Has_Cruise,
    Has_Aeroshield,
    Has_Lander,
    Num_Deployments,
    Num_Instruments,
    Cost_Variance_Pct,
    Schedule_Variance_Months
FROM missions_clean
ORDER BY Complexity_Score DESC, Cost_Variance_Pct DESC;

-- ============================================================
-- SECTION 5: MASS RISK ANALYSIS
-- ============================================================

-- Per mission mass overview
SELECT
    Mission,
    Initiative,
    Destination,
    Mission_Type,
    Success,
    Launch_Mass_kg,
    Dry_Mass_kg,
    Fuel_Mass_kg,
    Payload_Mass_kg,
    Bus_Mass_kg,
    Lander_Mass_kg,
    Instrument_Mass_kg,
    Complexity_Score,
    Cost_Variance_Pct,
    CASE
        WHEN Launch_Mass_kg > 0
        THEN ROUND(Fuel_Mass_kg / Launch_Mass_kg * 100, 2)
        ELSE NULL
    END                                             AS Fuel_Fraction_Pct,
    CASE
        WHEN Dry_Mass_kg > 0
        THEN ROUND(Payload_Mass_kg / Dry_Mass_kg * 100, 2)
        ELSE NULL
    END                                             AS Payload_Fraction_Pct
FROM missions_clean
WHERE Launch_Mass_kg IS NOT NULL
ORDER BY Launch_Mass_kg DESC;


-- Failure rate by launch mass category
SELECT
    CASE
        WHEN Launch_Mass_kg < 500   THEN '1 - Light    (<500 kg)'
        WHEN Launch_Mass_kg < 1000  THEN '2 - Medium   (500-1000 kg)'
        WHEN Launch_Mass_kg < 2000  THEN '3 - Heavy    (1000-2000 kg)'
        WHEN Launch_Mass_kg < 4000  THEN '4 - V.Heavy  (2000-4000 kg)'
        ELSE                             '5 - Super    (4000+ kg)'
    END                                             AS Mass_Category,
    COUNT(*)                                        AS Num_Missions,
    SUM(Is_Success)                                 AS Successes,
    SUM(Is_Failure)                                 AS Failures,
    SUM(Is_Operational)                             AS Still_Operational,
    ROUND(SUM(Is_Failure) / COUNT(*) * 100, 1)      AS Failure_Rate_Pct,
    ROUND((SUM(Is_Success) + SUM(Is_Operational))
        / COUNT(*) * 100, 1)                        AS Non_Failure_Rate_Pct,
    ROUND(AVG(Launch_Mass_kg), 0)                   AS Avg_Launch_Mass_kg,
    ROUND(AVG(Cost_Variance_Pct), 2)                AS Avg_Cost_Overrun_Pct,
    ROUND(AVG(Complexity_Score), 2)                 AS Avg_Complexity_Score
FROM missions_clean
WHERE Launch_Mass_kg IS NOT NULL
GROUP BY Mass_Category
ORDER BY Mass_Category;


-- Instrument mass vs risk
SELECT
    CASE
        WHEN Instrument_Mass_kg < 20    THEN '1 - Light Payload   (<20 kg)'
        WHEN Instrument_Mass_kg < 50    THEN '2 - Medium Payload  (20-50 kg)'
        WHEN Instrument_Mass_kg < 100   THEN '3 - Heavy Payload   (50-100 kg)'
        ELSE                                 '4 - V.Heavy Payload (100+ kg)'
    END                                             AS Instrument_Mass_Category,
    COUNT(*)                                        AS Num_Missions,
    SUM(Is_Success)                                 AS Successes,
    SUM(Is_Failure)                                 AS Failures,
    SUM(Is_Operational)                             AS Still_Operational,
    ROUND(SUM(Is_Failure) / COUNT(*) * 100, 1)      AS Failure_Rate_Pct,
    ROUND((SUM(Is_Success) + SUM(Is_Operational))
        / COUNT(*) * 100, 1)                        AS Non_Failure_Rate_Pct,
    ROUND(AVG(Instrument_Mass_kg), 2)               AS Avg_Instrument_Mass_kg,
    ROUND(AVG(Num_Instruments), 1)                  AS Avg_Num_Instruments,
    ROUND(AVG(Cost_Variance_Pct), 2)                AS Avg_Cost_Overrun_Pct
FROM missions_clean
WHERE Instrument_Mass_kg IS NOT NULL
GROUP BY Instrument_Mass_Category
ORDER BY Instrument_Mass_Category;


-- Fuel fraction vs risk per mission
SELECT
    Mission,
    Initiative,
    Destination,
    Mission_Type,
    Success,
    Launch_Mass_kg,
    Fuel_Mass_kg,
    ROUND(Fuel_Mass_kg / NULLIF(Launch_Mass_kg, 0) * 100, 2) AS Fuel_Fraction_Pct,
    CASE
        WHEN Fuel_Mass_kg / NULLIF(Launch_Mass_kg, 0) < 0.20 THEN '1 - Low Fuel    (<20%)'
        WHEN Fuel_Mass_kg / NULLIF(Launch_Mass_kg, 0) < 0.40 THEN '2 - Medium Fuel (20-40%)'
        WHEN Fuel_Mass_kg / NULLIF(Launch_Mass_kg, 0) < 0.60 THEN '3 - High Fuel   (40-60%)'
        ELSE                                                       '4 - V.High Fuel (60%+)'
    END                                             AS Fuel_Fraction_Category,
    Cost_Variance_Pct,
    Complexity_Score
FROM missions_clean
WHERE Launch_Mass_kg IS NOT NULL
  AND Fuel_Mass_kg IS NOT NULL
ORDER BY Fuel_Fraction_Pct DESC;


-- Mass vs cost overrun correlation
SELECT
    Mission,
    Launch_Mass_kg,
    Dry_Mass_kg,
    Proposed_Cost,
    Realized_Cost,
    Cost_Variance,
    Cost_Variance_Pct,
    Success,
    Complexity_Score
FROM missions_clean
WHERE Launch_Mass_kg IS NOT NULL
  AND Proposed_Cost IS NOT NULL
  AND Realized_Cost IS NOT NULL
ORDER BY Launch_Mass_kg DESC;


-- ============================================================
-- SECTION 6: POWER RISK ANALYSIS
-- ============================================================

-- Per mission power overview
SELECT
    Mission,
    Initiative,
    Destination,
    Mission_Type,
    Power_Source,
    Solar_Array_Type,
    Success,
    BOL_Power_W                                     AS Beginning_of_Life_Power_W,
    BOM_Power_W                                     AS Beginning_of_Mission_Power_W,
    BOS_Power_W                                     AS Beginning_of_Science_Power_W,
    Instrument_Power_W,
    Solar_Array_Area_m2,
    Num_Instruments,
    CASE
        WHEN BOL_Power_W > 0 AND BOM_Power_W IS NOT NULL
        THEN ROUND((BOL_Power_W - BOM_Power_W) / BOL_Power_W * 100, 2)
        ELSE NULL
    END                                             AS Power_Degradation_Pct,
    CASE
        WHEN BOM_Power_W > 0 AND Instrument_Power_W IS NOT NULL
        THEN ROUND(Instrument_Power_W / BOM_Power_W * 100, 2)
        ELSE NULL
    END                                             AS Instrument_Power_Fraction_Pct,
    Cost_Variance_Pct,
    Complexity_Score
FROM missions_clean
WHERE BOL_Power_W IS NOT NULL
   OR Instrument_Power_W IS NOT NULL
ORDER BY BOL_Power_W DESC;


-- Failure rate by power category
SELECT
    CASE
        WHEN BOL_Power_W < 500   THEN '1 - Low Power    (<500 W)'
        WHEN BOL_Power_W < 1000  THEN '2 - Medium Power (500-1000 W)'
        WHEN BOL_Power_W < 2000  THEN '3 - High Power   (1000-2000 W)'
        ELSE                          '4 - V.High Power (2000+ W)'
    END                                             AS Power_Category,
    COUNT(*)                                        AS Num_Missions,
    SUM(Is_Success)                                 AS Successes,
    SUM(Is_Failure)                                 AS Failures,
    SUM(Is_Operational)                             AS Still_Operational,
    ROUND(SUM(Is_Failure) / COUNT(*) * 100, 1)      AS Failure_Rate_Pct,
    ROUND((SUM(Is_Success) + SUM(Is_Operational))
        / COUNT(*) * 100, 1)                        AS Non_Failure_Rate_Pct,
    ROUND(AVG(BOL_Power_W), 0)                      AS Avg_BOL_Power_W,
    ROUND(AVG(Instrument_Power_W), 0)               AS Avg_Instrument_Power_W,
    ROUND(AVG(Cost_Variance_Pct), 2)                AS Avg_Cost_Overrun_Pct,
    ROUND(AVG(Complexity_Score), 2)                 AS Avg_Complexity_Score
FROM missions_clean
WHERE BOL_Power_W IS NOT NULL
GROUP BY Power_Category
ORDER BY Power_Category;


-- Power source risk comparison (RTG vs Solar Array)
SELECT
    Power_Source,
    COUNT(*)                                        AS Num_Missions,
    SUM(Is_Success)                                 AS Successes,
    SUM(Is_Failure)                                 AS Failures,
    SUM(Is_Operational)                             AS Still_Operational,
    ROUND(SUM(Is_Failure) / COUNT(*) * 100, 1)      AS Failure_Rate_Pct,
    ROUND((SUM(Is_Success) + SUM(Is_Operational))
        / COUNT(*) * 100, 1)                        AS Non_Failure_Rate_Pct,
    ROUND(AVG(Cost_Variance_Pct), 2)                AS Avg_Cost_Overrun_Pct,
    ROUND(AVG(Complexity_Score), 2)                 AS Avg_Complexity_Score,
    ROUND(AVG(Launch_Mass_kg), 0)                   AS Avg_Launch_Mass_kg,
    ROUND(AVG(Mission_Duration_Yrs), 2)             AS Avg_Mission_Duration_Yrs
FROM missions_clean
WHERE Power_Source IS NOT NULL
GROUP BY Power_Source
ORDER BY Failure_Rate_Pct DESC;


-- Instrument power demand vs risk
SELECT
    CASE
        WHEN Instrument_Power_W < 50    THEN '1 - Low    (<50 W)'
        WHEN Instrument_Power_W < 150   THEN '2 - Medium (50-150 W)'
        WHEN Instrument_Power_W < 300   THEN '3 - High   (150-300 W)'
        ELSE                                 '4 - V.High (300+ W)'
    END                                             AS Instrument_Power_Category,
    COUNT(*)                                        AS Num_Missions,
    SUM(Is_Success)                                 AS Successes,
    SUM(Is_Failure)                                 AS Failures,
    SUM(Is_Operational)                             AS Still_Operational,
    ROUND(SUM(Is_Failure) / COUNT(*) * 100, 1)      AS Failure_Rate_Pct,
    ROUND((SUM(Is_Success) + SUM(Is_Operational))
        / COUNT(*) * 100, 1)                        AS Non_Failure_Rate_Pct,
    ROUND(AVG(Instrument_Power_W), 0)               AS Avg_Instrument_Power_W,
    ROUND(AVG(Num_Instruments), 1)                  AS Avg_Num_Instruments,
    ROUND(AVG(Cost_Variance_Pct), 2)                AS Avg_Cost_Overrun_Pct,
    ROUND(AVG(Solar_Array_Area_m2), 2)              AS Avg_Solar_Array_Area_m2
FROM missions_clean
WHERE Instrument_Power_W IS NOT NULL
GROUP BY Instrument_Power_Category
ORDER BY Instrument_Power_Category;


-- Power degradation vs risk
SELECT
    Mission,
    Destination,
    Mission_Type,
    Power_Source,
    Success,
    BOL_Power_W,
    BOM_Power_W,
    ROUND((BOL_Power_W - BOM_Power_W) / NULLIF(BOL_Power_W, 0) * 100, 2) AS Power_Degradation_Pct,
    CASE
        WHEN (BOL_Power_W - BOM_Power_W) / NULLIF(BOL_Power_W, 0) < 0.10 THEN '1 - Minimal  (<10%)'
        WHEN (BOL_Power_W - BOM_Power_W) / NULLIF(BOL_Power_W, 0) < 0.30 THEN '2 - Moderate (10-30%)'
        WHEN (BOL_Power_W - BOM_Power_W) / NULLIF(BOL_Power_W, 0) < 0.50 THEN '3 - High     (30-50%)'
        ELSE                                                                    '4 - Severe   (50%+)'
    END                                             AS Degradation_Category,
    Solar_Array_Area_m2,
    Cost_Variance_Pct,
    Complexity_Score
FROM missions_clean
WHERE BOL_Power_W IS NOT NULL
  AND BOM_Power_W IS NOT NULL
ORDER BY Power_Degradation_Pct DESC;

